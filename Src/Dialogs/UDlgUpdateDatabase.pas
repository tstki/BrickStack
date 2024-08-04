unit UDlgUpdateDatabase;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  FireDAC.Comp.Client,
  UConfig, Vcl.ExtCtrls;

type
  TDlgUpdateDatabase = class(TForm)
    BtnOK: TButton;
    BtnCancel: TButton;
    Memo2: TMemo;
    BtnDownloadFiles: TButton;
    BtnCreateDB: TButton;
    BtnExtractFiles: TButton;
    BtnImportCSV: TButton;
    BtnCleanupImport: TButton;
    Timer1: TTimer;
    PCDBWizard: TPageControl;
    TsTables: TTabSheet;
    LvResults: TListView;
    LblProgress: TLabel;
    TsStart: TTabSheet;
    Memo1: TMemo;
    TsResults: TTabSheet;
    ListView2: TListView;
    LblResults: TLabel;
    procedure BtnDownloadFilesClick(Sender: TObject);
    procedure BtnCreateDBClick(Sender: TObject);
    procedure BtnExtractFilesClick(Sender: TObject);
    procedure BtnImportCSVClick(Sender: TObject);
    procedure BtnCleanupImportClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure BtnOKClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure BtnCancelClick(Sender: TObject);
  private
    { Private declarations }
    FConfig: TConfig;
    FCurrentStep: Integer;
    procedure FDoCreateDatabaseAndTables;
    procedure FDoDownloadFiles;    
    procedure FDoImportCSV;
    procedure FDoExtractFiles;
    procedure FDoCleanup;
    procedure FStartDownload(const URL, FileName: string; ProgressRow: TListItem);
    procedure FImportCSV(SqlConnection: TFDConnection; const FileName, TableName: String; TableLabel: TListItem);
    procedure FRunCommandAsync(const Command: string; TableLabel: TListItem);
  public
    { Public declarations }
    property Config: TConfig read FConfig write FConfig;
  end;

implementation

{$R *.dfm}

uses
  USqLiteConnection, Data.DB,
  System.IOUtils,
  Threading,
  StrUtils,
  Net.HttpClient, Net.URLClient, Net.HttpClientComponent,
  UFrmMain, UStrings, UDownloadThread,
  ZLib,
  Winapi.ShellAPI,
  System.RegularExpressions;

const
  // Wizard steps:
  stepStart = 0;
  stepDatabase = 1;
  stepDownload = 2;
  stepExtract = 3;
  stepImport = 4;
  stepCleanup = 5;

  // When downloading, param may be "?1721891280.3014483" - which is the unix timetamp and time fraction, but it's optional.
  DownloadFiles: array[0..11] of String = (
    'https://cdn.rebrickable.com/media/downloads/themes.csv.gz',
    'https://cdn.rebrickable.com/media/downloads/colors.csv.gz',
    'https://cdn.rebrickable.com/media/downloads/part_categories.csv.gz',
    'https://cdn.rebrickable.com/media/downloads/parts.csv.gz',
    'https://cdn.rebrickable.com/media/downloads/part_relationships.csv.gz',
    'https://cdn.rebrickable.com/media/downloads/elements.csv.gz',
    'https://cdn.rebrickable.com/media/downloads/sets.csv.gz',
    'https://cdn.rebrickable.com/media/downloads/minifigs.csv.gz',
    'https://cdn.rebrickable.com/media/downloads/inventories.csv.gz',
    'https://cdn.rebrickable.com/media/downloads/inventory_parts.csv.gz',
    'https://cdn.rebrickable.com/media/downloads/inventory_sets.csv.gz',
    'https://cdn.rebrickable.com/media/downloads/inventory_minifigs.csv.gz');

  ImportFileNames: array[0..11] of String = (
    'themes.csv',
    'colors.csv',
    'part_categories.csv',
    'parts.csv',
    'part_relationships.csv',
    'elements.csv',
    'sets.csv',
    'minifigs.csv',
    'inventories.csv',
    'inventory_parts.csv',
    'inventory_sets.csv',
    'inventory_minifigs.csv');

  //2D Array: TableName, SQL
  CreateTableSQL: array[0..15, 0..1] of String = (
    ('BSSetLists', 'CREATE TABLE IF NOT EXISTS BSSetLists (' +
                    '	ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,' +
                    '	Name TEXT(128),' +
                    '	Description TEXT(1024),' +
                    '	UseInCollection INTEGER,' +
                    '	SortIndex INTEGER,' +
                    '	ExternalID INTEGER,' + //-- external site's unique ID of your imported set list
                    '	ExternalType INTEGER);' + //-- rebrickable / bricklink / other
                    'CREATE INDEX IF NOT EXISTS BSSetLists_ID_IDX ON BSSetLists (ID);' +
                    'CREATE INDEX IF NOT EXISTS BSSetLists_EXTERNALID_IDX ON BSSetLists (EXTERNALID);'),
    ('BSSets', 'CREATE TABLE IF NOT EXISTS BSSets (' +
                '	ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,' +
                '	BSSetListID INTEGER,' +
                '	set_num TEXT(20) NOT NULL,' + // -- link to rebrickable sets table
                '	Built INTEGER,' +
                '	Quantity INTEGER,' +
                '	HaveSpareParts INTEGER,' +
                '	Notes TEXT(1024));' +
                'CREATE INDEX IF NOT EXISTS BSSets_ID_IDX ON BSSets (ID);' +
                'CREATE INDEX IF NOT EXISTS BSSets_set_num_IDX ON BSSets (set_num);' +
                'CREATE INDEX IF NOT EXISTS BSSets_BSSetListID_IDX ON BSSets (BSSetListID)'),
    ('BSCustomTags', 'CREATE TABLE IF NOT EXISTS BSCustomTags (' +
                      '	ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,' +
                      '	LinkedID INTEGER,' + // -- ID of the setlist/set
                      '	CustomType INTEGER,' + // -- 1/2 = setlist/sets
                      '	Value TEXT(128));' +
                      'CREATE INDEX IF NOT EXISTS BSCustomTags_ID_IDX ON BSCustomTags (ID);' +
                      'CREATE INDEX IF NOT EXISTS BSCustomTags_LinkedID_IDX ON BSCustomTags (LinkedID);'),
    ('BSDBVersions', 'CREATE TABLE IF NOT EXISTS BSDBVersions (' +
                      '	ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,' +
                      '	DBVersion INTEGER,' +       // Database structure version
                      '	DRebrickableCSV INTEGER);' +  // Date of import
                      'CREATE INDEX IF NOT EXISTS DBVersions_ID_IDX ON BSCustomTags (ID);'),
    ('Inventories', 'CREATE TABLE IF NOT EXISTS inventories (' +
                    '	id INTEGER NOT NULL PRIMARY KEY,' +
                    '	version INTEGER,' +
                    '	set_num TEXT(20));' +
                    'CREATE INDEX IF NOT EXISTS Inventories_id_IDX ON inventories (id);' +
                    'CREATE INDEX IF NOT EXISTS Inventories_set_num_IDX ON inventories (set_num);'),
    ('Inventory_parts', 'CREATE TABLE IF NOT EXISTS inventory_parts (' +
                        '	inventory_id INTEGER,' +
                        '	part_num TEXT(20),' +
                        '	color_id INTEGER,' +
                        '	quantity INTEGER,' +
                        '	is_spare INTEGER,' +
                        '	img_url TEXT(256));' +
                        'CREATE INDEX IF NOT EXISTS inventory_parts_inventory_id_IDX ON inventory_parts (inventory_id);' +
                        'CREATE INDEX IF NOT EXISTS inventory_parts_color_id_IDX ON inventory_parts (color_id);'),
    ('Inventory_minifigs', 'CREATE TABLE IF NOT EXISTS inventory_minifigs (' +
                            '	inventory_id INTEGER,' +
                            '	fig_num TEXT(20),' +
                            '	quantity INTEGER);' +
                            'CREATE INDEX IF NOT EXISTS inventory_minifigs_inventory_id_IDX ON inventory_minifigs (inventory_id);'),
    ('Inventory_sets', 'CREATE TABLE IF NOT EXISTS inventory_sets (' +
                      '	inventory_id INTEGER,' +
                      '	set_num TEXT(20),' +
                      '	quantity INTEGER);' +
                      'CREATE INDEX IF NOT EXISTS inventory_sets_inventory_id_IDX ON inventory_sets (inventory_id);' +
                      'CREATE INDEX IF NOT EXISTS inventory_sets_set_num_IDX ON inventory_sets (set_num);'),
    ('Part_categories', 'CREATE TABLE IF NOT EXISTS part_categories (' +
                        '	id INTEGER NOT NULL PRIMARY KEY,' +
                        '	name TEXT(200));' +
                        'CREATE INDEX IF NOT EXISTS part_categories_id_IDX ON part_categories (id);'),
    ('Parts', 'CREATE TABLE IF NOT EXISTS parts (' +
              '	part_num INTEGER NOT NULL PRIMARY KEY,' +
              '	name TEXT(200),' +
              '	part_cat_id INTEGER,' +
              '	part_material TEXT(20));' +
              'CREATE INDEX IF NOT EXISTS parts_part_num_IDX ON parts (part_num);' +
              'CREATE INDEX IF NOT EXISTS parts_part_cat_id_IDX ON parts (part_cat_id);'),
    ('Colors', 'CREATE TABLE IF NOT EXISTS colors (' +
              '	id INTEGER NOT NULL PRIMARY KEY,' +
                '	name TEXT(200),' +
                '	rgb TEXT(6),' +
                '	is_trans INTEGER);' +
                'CREATE INDEX IF NOT EXISTS colors_id_IDX ON colors (id);'),
    ('Part_relationships', 'CREATE TABLE IF NOT EXISTS part_relationships (' +
                            '	rel_type TEXT(1),' +
                            '	child_part_num TEXT(20),' +
                            '	parent_part_num TEXT(20));' +
                            'CREATE INDEX IF NOT EXISTS part_relationships_child_part_num_IDX ON part_relationships (child_part_num);' +
                            'CREATE INDEX IF NOT EXISTS part_relationships_parent_part_num_IDX ON part_relationships (parent_part_num);'),
    ('Elements', 'CREATE TABLE IF NOT EXISTS elements (' +
                  '	element_id TEXT(10) NOT NULL PRIMARY KEY,' +
                  '	npart_num TEXT(200),' +
                  '	color_id INTEGER,' +
                  '	design_id INTEGER);' +
                  'CREATE INDEX IF NOT EXISTS elements_element_id_IDX ON elements (element_id);' +
                  'CREATE INDEX IF NOT EXISTS elements_npart_num_IDX ON elements (npart_num);' +
                  'CREATE INDEX IF NOT EXISTS elements_color_id_IDX ON elements (color_id);' +
                  'CREATE INDEX IF NOT EXISTS elements_design_id_IDX ON elements (design_id);'),
    ('Minifigs', 'CREATE TABLE IF NOT EXISTS minifigs (' +
                  '	fig_num TEXT(20) NOT NULL PRIMARY KEY,' +
                  '	name TEXT(256),' +
                  '	num_parts INTEGER,' +
                  '	img_url TEXT(256));' +
                  'CREATE INDEX IF NOT EXISTS minifigs_fig_num_IDX ON minifigs (fig_num);'),
    ('Sets', 'CREATE TABLE IF NOT EXISTS sets (' +
              '	set_num TEXT(20) NOT NULL PRIMARY KEY,' +
              '	name TEXT(256),' +
              '	year INTEGER,' +
              '	theme_id INTEGER,' +
              '	num_parts INTEGER,' +
              '	img_url TEXT(256));' +
              'CREATE INDEX IF NOT EXISTS sets_set_num_IDX ON sets (set_num);' +
              'CREATE INDEX IF NOT EXISTS sets_theme_id_IDX ON sets (theme_id);'),
    ('Themes', 'CREATE TABLE IF NOT EXISTS themes (' +
                '	id INTEGER NOT NULL PRIMARY KEY,' +
                '	name TEXT(40),' +
                '	parent_id INTEGER);' +
                'CREATE INDEX IF NOT EXISTS themes_id_IDX ON themes (id);' +
                'CREATE INDEX IF NOT EXISTS themes_parent_id_IDX ON themes (parent_id);')
  );



{
  First launch and updater steps
    Detect current state of database
      If no database - create it
      If database exists, check versions.
        If version is old - update table columns if needed.
        If no data, start downloader. Mandatory, because we can't work without updating.
      If data exists, check version.
        Show date of current data, and "current date" of data found online.
          Show color (green <= 7 days), (yellow <= 30 days), (red <= 6 months)
          User can choose to update.
    Updating data:
      Start thread for each file
      Get progress
      Once all data is downloaded next step is unpacking each file, and importing to database.
      Show progress per file / total.
      Once all files imported, show status page at the end.
}

procedure TDlgUpdateDatabase.FormShow(Sender: TObject);
begin
  FCurrentStep := 0;
  PCDBWizard.TabIndex := 0;

  for var I := 0 to PCDBWizard.PageCount-1 do
    PCDBWizard.Pages[I].TabVisible := False;
  PCDBWizard.ActivePage := TsStart;
end;

procedure TDlgUpdateDatabase.FStartDownload(const URL, FileName: string; ProgressRow: TListItem);
begin
  var DownloadThread := TDownloadThread.Create(URL, FileName,
    procedure(Progress: Integer)
    begin
      ProgressRow.Caption := IntToStr(Progress);
    end);
  DownloadThread.Start;
end;

procedure TDlgUpdateDatabase.FDoDownloadFiles;
begin
  FCurrentStep := stepDownload;
  ForceDirectories(TPath.GetDirectoryName(FConfig.ImportPath));

  LvResults.Clear;
  LvResults.Items.BeginUpdate;
  try
    for var FileToDownload in DownloadFiles do begin
      var FileName := TPath.GetFileName(FileToDownload);
      var Item := LvResults.Items.Add;
      Item.Caption := '0';
      Item.SubItems.Add(FileName);
      Item.SubItems.Add('20240423');
      Item.SubItems.Add('20240728');

      var LocalFileName := TPath.Combine(IncludeTrailingPathDelimiter(FConfig.ImportPath), FileName);
      FStartDownload(FileToDownload, LocalFileName, Item);

      // Sleep a little between additions so we don't get Errors, and add errorhandling to the downloadthread.
      Sleep(10);
    end;
  finally
    LvResults.Items.EndUpdate;
  end;

  //start timer that checks whether progress is complete to 100%
  // once progress done, enable next button.
  Timer1.Enabled := True;
end;

procedure TDlgUpdateDatabase.FDoCreateDatabaseAndTables;

  function FExecSQLAndUpdateProgress(Query: TFDQuery; const Name, QueryText: String): Boolean;
  begin
    var ExecResult := False;
    var Item: TListItem;

    var SQLTask := TTask.Run(procedure
    begin
      TThread.Queue(nil, procedure
      begin
        // Update main UI
        Item := LvResults.Items.Add;
        Item.Caption := '0';
        Item.SubItems.Add(Name);
        Item.SubItems.Add('Updating');
        Item.SubItems.Add(FormatDateTime('YYYYMMDD', Now));
      end);

      // Background task
      try
        Query.SQL.Text := QueryText;
        Query.ExecSQL;
        ExecResult := True;
      except
        ExecResult := False;
      end;

      TThread.Queue(nil, procedure
      begin
        // Update main UI
        Item.SubItems[1] := IfThen(ExecResult, 'Updated', 'Error');
        Item.Caption := '100';
      end);
    end);

    while not (SQLTask.Status in [TTaskStatus.Completed, TTaskStatus.Exception, TTaskStatus.Canceled]) do
    begin
      //Wait for the task to finish before starting the next step.
      Sleep(100);
    end;

    Result := ExecResult;
  end;

begin
  // Make sure the DBase path exists - CreateDatabaseAndTables does not create the folder.
  ForceDirectories(TPath.GetDirectoryName(FConfig.DbasePath));

  LvResults.Clear;

  // Create the connection component
  var SqlConnection := FrmMain.AcquireConnection;
  try
    // Set up connection parameters
    SqlConnection.DriverName := 'SQLite';
    SqlConnection.Params.Database := FConfig.DbasePath;
    SqlConnection.Params.Add('LockingMode=Normal');
    SqlConnection.Params.Add('Synchronous=Full');

    // Open the connection and create the database file
    SqlConnection.Connected := True;

    // Create the query component
    var FDQuery := TFDQuery.Create(nil);
    try
      FDQuery.Connection := SqlConnection;

      FDQuery.Connection.StartTransaction;
      //FDQuery.Transaction.StartTransaction;
      try
        try

          // In chunks so we can show progress:
          // Create brickstack base tables:

          //select id from version.
          //if not found, insert
          //if found, use id
          //update by id, set version = current dbversion, DRebrickableCSV = 0;

          for var I := Low(CreateTableSQL) to High(CreateTableSQL) do begin
            var TableName := CreateTableSQL[i][0];
            var Sql := CreateTableSQL[i][1];
            {var QResult :=} FExecSQLAndUpdateProgress(FDQuery, TableName, Sql);

            //if not result then
            //add to error log
          end;

        except
          FDQuery.Connection.Rollback;
        end;
      finally
        FDQuery.Connection.Commit;
      end;
    finally
      FDQuery.Free;
    end;
  finally
    FrmMain.ReleaseConnection(SqlConnection);
  end;
end;

procedure TDlgUpdateDatabase.FDoExtractFiles;

  procedure FDecompressGZFile(const SourceFileName, DestFileName: string);
  begin
    var SourceStream := TFileStream.Create(SourceFileName, fmOpenRead);
    try
      var DecompressionStream := TDecompressionStream.Create(SourceStream, 31); // 31 bit wide window = gzip only mode. Don't ask, it just works.
      try
        var DestStream := TFileStream.Create(DestFileName, fmCreate);
        try
          DestStream.CopyFrom(DecompressionStream, 0);
        finally
          DestStream.Free;
        end;
      finally
        DecompressionStream.Free;
      end;
    finally
      SourceStream.Free;
    end;
  end;

begin
  FCurrentStep := stepExtract;

  LvResults.Clear;
  LvResults.Items.BeginUpdate;
  try
    for var FileToDownload in DownloadFiles do begin
      var FileName := TPath.GetFileName(FileToDownload);
      var Item := LvResults.Items.Add;
      Item.Caption := '0';
      Item.SubItems.Add(FileName);
      Item.SubItems.Add('Updating');
      Item.SubItems.Add('20240728');

      try
        var LocalFileName := TPath.Combine(IncludeTrailingPathDelimiter(FConfig.ImportPath), FileName);
        //FStartDownload(FileToDownload, LocalFileName, Item);
        var TargetExtractedFileName := TPath.ChangeExtension(LocalFileName, '');  // Just remove the .gz part
        FDecompressGZFile(LocalFileName, TargetExtractedFileName);

        Item.Caption := '100';
        Item.SubItems[1] := 'Extracted';
      except
        Item.SubItems[1] := 'Error';
      end;
    end;
  finally
    LvResults.Items.EndUpdate;
  end;
end;
           {
procedure TDlgUpdateDatabase.FRunCommandAsync(const Command: String; TableLabel: TListItem);
begin
  TTask.Run(procedure
  var
    StartupInfo: TStartupInfo;
    ProcessInfo: TProcessInformation;
    Success: Boolean;
    ExitCode: DWORD;
    StatusMessage: string;
  begin
    // Initialize the STARTUPINFO structure
    ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
    StartupInfo.cb := SizeOf(StartupInfo);
    // Initialize the PROCESS_INFORMATION structure
    ZeroMemory(@ProcessInfo, SizeOf(ProcessInfo));
    // Execute the command
    Success := CreateProcess(nil, PChar(Command), nil, nil, False, 0, nil, nil, StartupInfo, ProcessInfo);
    if Success then begin
      // Wait until the process exits
      WaitForSingleObject(ProcessInfo.hProcess, INFINITE);
      // Get the exit code
      GetExitCodeProcess(ProcessInfo.hProcess, ExitCode);
      // Clean up
      CloseHandle(ProcessInfo.hProcess);
      CloseHandle(ProcessInfo.hThread);
      // Prepare the status message
      if ExitCode = 0 then
        StatusMessage := 'Imported'
      else
        StatusMessage := 'Error ' + IntToStr(ExitCode);
    end else
      StatusMessage := 'Failed';
    // Update the label on the main thread
    TThread.Synchronize(nil, procedure
    begin
      TableLabel.SubItems[1] := StatusMessage; // Update Label1 on the main form
    end);
  end);
end;      }

procedure TDlgUpdateDatabase.fRunCommandAsync(const Command: String; TableLabel: TListItem);
//begin
//  TTask.Run(procedure
  var
    StartupInfo: TStartupInfo;
    ProcessInfo: TProcessInformation;
    SecurityAttrs: TSecurityAttributes;
    ReadPipe, WritePipe: THandle;
//    Buffer: array[0..4095] of Char;
//    BytesRead: DWORD;
    OutputText: string;
    Success: Boolean;
    ExitCode: DWORD;
    StatusMessage: string;
  begin
    // Set up security attributes for the pipe
    ZeroMemory(@SecurityAttrs, SizeOf(SecurityAttrs));
    SecurityAttrs.nLength := SizeOf(SecurityAttrs);
    SecurityAttrs.bInheritHandle := True;

    // Create the pipe for reading
    if not CreatePipe(ReadPipe, WritePipe, @SecurityAttrs, 0) then
    begin
      StatusMessage := 'Failed to create pipe.';
      TThread.Synchronize(nil, procedure
      begin
        //Label1.Caption := StatusMessage;
      end);
      Exit;
    end;

    // Initialize the STARTUPINFO structure
    ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
    StartupInfo.cb := SizeOf(StartupInfo);
//    StartupInfo.hStdOutput := WritePipe;
//    StartupInfo.hStdError := WritePipe;
    StartupInfo.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
    StartupInfo.wShowWindow := SW_HIDE;

    // Initialize the PROCESS_INFORMATION structure
    ZeroMemory(@ProcessInfo, SizeOf(ProcessInfo));

    // Execute the command
    OutputText := '';
    Success := CreateProcess(nil, PChar(Command), nil, nil, True, 0, nil, nil, StartupInfo, ProcessInfo);

    if Success then begin
      CloseHandle(WritePipe);  // Close the write end of the pipe

      // Read the output from the pipe
      //todo: CRASHES
{      repeat
        if ReadFile(ReadPipe, Buffer, SizeOf(Buffer), BytesRead, nil) then
          OutputText := OutputText + String(Buffer);
      until BytesRead = 0;
}

      // Wait until the process exits
      WaitForSingleObject(ProcessInfo.hProcess, INFINITE);

      // Get the exit code
      GetExitCodeProcess(ProcessInfo.hProcess, ExitCode);

      // Clean up
      CloseHandle(ProcessInfo.hProcess);
      CloseHandle(ProcessInfo.hThread);
      CloseHandle(ReadPipe);

      // Prepare the status message
      if ExitCode = 0 then
        StatusMessage := 'Command executed successfully. Output: ' + OutputText
      else
        StatusMessage := 'Command failed with exit code ' + IntToStr(ExitCode) + '. Output: ' + OutputText;
    end else
      StatusMessage := 'Failed to execute command.';

    // Update the label on the main thread
    TThread.Synchronize(nil, procedure
    begin
      //Label1.Caption := StatusMessage;
    end);
//  end);
end;

procedure TDlgUpdateDatabase.FImportCSV(SqlConnection: TFDConnection; const FileName, TableName: String; TableLabel: TListItem);
begin
  //get
  var ExeName := Application.ExeName;
  var SQLitePath := TPath.Combine(IncludeTrailingPathDelimiter(TPath.GetDirectoryName(ExeName)), 'SQLite3.exe');
  var cmdToRun := Format('"%s" "%s" ".mode csv" ".import --skip 1 ''%s'' %s"', [SQLitePath, FConfig.DbasePath, FileName, TableName]);
  //'"E:\Projects\Delphi\BrickStack\Bin\Win64\Debug\SQLite3.exe" "E:\Projects\Delphi\BrickStack\Bin\Win64\Debug\DBase\BrickStack.db" ".mode csv" ".import --skip 1 ''E:\Projects\Delphi\BrickStack\Bin\Win64\Debug\Import\themes.csv'' themes"'
  //todo: how to insert single quote
//  var cmdToRun := 'sqlite3.exe .\dbase\BrickStack.db ".mode csv" ".import --skip 1 .\Import\themes.csv themes"';
  FRunCommandAsync(cmdToRun, TableLabel);

// Also works:
//  FRunCommandAsync('DoImport.bat', TableLabel);

// Works but causes ugly and sus dos box popup
//  ShellExecute(0, 'open', PChar('DoImport.bat'), nil, nil, SW_SHOWNORMAL);

  //WinExec(pansichar(cmdToRun), 0);

{
  WinExec Function:
    Although it is an older API, WinExec can be used for simple command execution. It’s not recommended for newer projects due to lack of control over the process.
  ShellExecute and ShellExecuteEx Functions:
    These are more powerful and versatile, used to run executables or open documents, URLs, and more. They provide more parameters to control the execution.
  CreateProcess Function:
    This function gives you extensive control over the newly created process, including its input/output streams, security attributes, and execution parameters.
  TProcess Component (from the System.SysUtils and System.Classes units):
    In more recent versions of Delphi, TProcess is a higher-level wrapper around the Windows API functions to create and control processes. It provides a more object-oriented approach.
}

  //SQLite3.exe ".\dbase\brickstack.db" ".mode csv" ".import --skip 1 '.\import\themes.csv' themes"
  //WinExec();
//  SqlConnection.ExecSQL(Format('IMPORT "%s" INTO %s;', [FileName, 'inventories']));
end;

procedure TDlgUpdateDatabase.FDoImportCSV;
begin
  FCurrentStep := stepImport;
  
  //todo: Truncate these tables first.

//use: ImportFileNames
{
  .import .\import\inventories.csv inventories
  .import .\import\inventory_parts.csv inventory_parts
  .import .\import\inventory_minifigs.csv inventory_minifigs
  .import .\import\inventory_sets.csv inventory_sets
  .import .\import\part_categories.csv part_categories
  .import .\import\parts.csv parts
  .import .\import\colors.csv colors
  .import .\import\minifigs.csv minifigs
  .import .\import\sets.csv sets
  .import .\import\part_relationships.csv part_relationships
  .import .\import\elements.csv elements
  .import .\import\themes.csv themes
}
  var SqlConnection := FrmMain.AcquireConnection;
  try
    // Set up connection parameters
    SqlConnection.DriverName := 'SQLite';
    SqlConnection.Params.Database := FConfig.DbasePath;
    SqlConnection.Params.Add('LockingMode=Normal');
    SqlConnection.Params.Add('Synchronous=Full');
    // Open the connection and create the database file

    SqlConnection.Connected := True;

    // do stuff
//  AConnection.ExecSQL(Format('IMPORT "%s" INTO %s;', [ACSVFile, ATableName]));
    LvResults.Clear;

    for var FileToImport in ImportFileNames do begin
      var Item := LvResults.Items.Add;
      Item.Caption := '0';
      Item.SubItems.Add(FileToImport);
      Item.SubItems.Add('Updating');
      Item.SubItems.Add('currentdate'); //todo now - to string

      try
        var LocalFileName := TPath.Combine(IncludeTrailingPathDelimiter(FConfig.ImportPath), FileToImport);
        var TableName := ChangeFileExt(FileToImport, '');
        FImportCSV(SqlConnection, LocalFileName, TableName, Item);

        Item.Caption := '100';
        Item.SubItems[1] := 'Updated';
      except
        Item.SubItems[1] := 'Error';
      end;

      //just one for now:
//      exit;
    end;

  finally
    FrmMain.ReleaseConnection(SqlConnection);
  end;
end;

procedure TDlgUpdateDatabase.FDoCleanup;
begin
  FCurrentStep := stepCleanup;
//Delete ImportFileNames
//Delete ImportFileNames.gz
end;

procedure TDlgUpdateDatabase.Timer1Timer(Sender: TObject);

  function FIsStepDone(): Boolean;
  begin
    Result := False;

    var AmountDone := 0;
    for var LvItem in LvResults.Items do begin
      if StrToIntDef(LvItem.Caption, 0) = 100 then
        Inc(AmountDone);
    end;

    case FCurrentStep of
      stepDatabase:   Result := AmountDone = High(CreateTableSQL) + 1;
      stepDownload:   Result := AmountDone = High(DownloadFiles) + 1;
      stepExtract:    Result := AmountDone = High(DownloadFiles) + 1;
      stepImport:     Result := AmountDone = High(DownloadFiles) + 1;
      stepCleanup:    Result := AmountDone = High(DownloadFiles) + 1;
    end;
  end;

begin
  // Check whether all downloads are finished, if so, disable timer and start the next step
  //  LblDownloadState.Caption := Format('In progress (%d/%d)', [Done, ListView1.Items.Count]);
  case FCurrentStep of
    stepDatabase:
    begin
      if FIsStepDone then
        BtnDownloadFilesClick(Sender);
    end;
    stepDownload:
    begin
      if FIsStepDone then
        BtnExtractFilesClick(Sender);
    end;
    stepExtract:
    begin
//      if FIsStepDone then
//        BtnImportCSVClick(Sender);
    end;
    stepImport:
    begin
      if FIsStepDone then
        BtnCleanupImportClick(Sender);
    end;
    stepCleanup:
    begin
      // show results and disable timer
      //todo: or FUpdateCancelled.
      if FIsStepDone then
        Timer1.Enabled := False;
    end;
    //stepStart:
      // Should not happen.
  end;
end;

procedure TDlgUpdateDatabase.BtnOKClick(Sender: TObject);
begin
  BtnOK.Enabled := False;
  BtnOK.Caption := 'Next';
  LblProgress.Caption := 'Creating database tables';

  PCDBWizard.ActivePage := TsTables;

  FCurrentStep := 1;
  Timer1.Enabled := True;

  var SQLTask := TTask.Run(procedure
  begin
    // Background task
    try
      BtnCreateDBClick(Sender);
    except
      //
    end;
  end);
end;

procedure TDlgUpdateDatabase.BtnCreateDBClick(Sender: TObject);
begin
  FDoCreateDatabaseAndTables;
end;

procedure TDlgUpdateDatabase.BtnDownloadFilesClick(Sender: TObject);
begin
  FDoDownloadFiles;
end;

procedure TDlgUpdateDatabase.BtnImportCSVClick(Sender: TObject);
begin
  FDoImportCSV;
end;

procedure TDlgUpdateDatabase.BtnExtractFilesClick(Sender: TObject);
begin
  FDoExtractFiles;
end;

procedure TDlgUpdateDatabase.BtnCancelClick(Sender: TObject);
begin
  //todo: cancel and close everything. make sure all tasks are ended before closing
  ModalResult := mrCancel;
end;

procedure TDlgUpdateDatabase.BtnCleanupImportClick(Sender: TObject);
begin
  FDoCleanup;
end;

end.
