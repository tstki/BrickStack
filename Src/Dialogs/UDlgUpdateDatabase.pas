unit UDlgUpdateDatabase;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  FireDAC.Comp.Client, UImportThread,
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
    procedure FStartDownload(const URL, FileName: string; ProgressRow: TListItem);
    procedure FDoImportCSV;
    procedure FStartImport(const FileName: string; ImportTableID: TImportTableIDs; ProgressRow: TListItem);
    procedure FDoExtractFiles;
    procedure FDoCleanup;
//    procedure FImportBatchCSV(SqlConnection: TFDConnection; const FileName, TableName: String; TableLabel: TListItem);
//    procedure FDoImportCSVAsync(const Command: String; TableLabel: TListItem);
//    procedure FRunCommandAsync(const Command: string; TableLabel: TListItem);
//    procedure FDoImortFiles;
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
  UFrmMain, UStrings,
  UDownloadThread,
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

  // The first line has column names, so: "--skip 1"
  ImportDataCmd: array[0..11] of String = (
    'sqlite3 .\dbase\BrickStack.db -cmd ".mode csv" -cmd ".import --skip 1 .\import\inventories.csv inventories" ".quit"',
    'sqlite3 .\dbase\BrickStack.db -cmd ".mode csv" -cmd ".import --skip 1 .\import\inventory_parts.csv inventory_parts" ".quit"',
    'sqlite3 .\dbase\BrickStack.db -cmd ".mode csv" -cmd ".import --skip 1 .\import\inventory_minifigs.csv inventory_minifigs" ".quit"',
    'sqlite3 .\dbase\BrickStack.db -cmd ".mode csv" -cmd ".import --skip 1 .\import\inventory_sets.csv inventory_sets" ".quit"',
    'sqlite3 .\dbase\BrickStack.db -cmd ".mode csv" -cmd ".import --skip 1 .\import\part_categories.csv part_categories" ".quit"',
    'sqlite3 .\dbase\BrickStack.db -cmd ".mode csv" -cmd ".import --skip 1 .\import\parts.csv parts" ".quit"',
    'sqlite3 .\dbase\BrickStack.db -cmd ".mode csv" -cmd ".import --skip 1 .\import\colors.csv colors" ".quit"',
    'sqlite3 .\dbase\BrickStack.db -cmd ".mode csv" -cmd ".import --skip 1 .\import\minifigs.csv minifigs" ".quit"',
    'sqlite3 .\dbase\BrickStack.db -cmd ".mode csv" -cmd ".import --skip 1 .\import\sets.csv sets" ".quit"',
    'sqlite3 .\dbase\BrickStack.db -cmd ".mode csv" -cmd ".import --skip 1 .\import\part_relationships.csv part_relationships" ".quit"',
    'sqlite3 .\dbase\BrickStack.db -cmd ".mode csv" -cmd ".import --skip 1 .\import\elements.csv elements" ".quit"',
    'sqlite3 .\dbase\BrickStack.db -cmd ".mode csv" -cmd ".import --skip 1 .\import\themes.csv themes" ".quit"'
    );

{
  First launch and updater steps
    Detect current state of database
      If no database - then create it (sqlite will be distributed with the zip, but we should detect if it exists anyway)
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
      Item.SubItems.Add('probably old');     //todo get the old data time (register somewhere in a dbase)
      Item.SubItems.Add(FormatDateTime('YYYYMMDD', Now));

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
      Item.SubItems.Add(FormatDateTime('YYYYMMDD', Now));

      try
        var LocalFileName := TPath.Combine(IncludeTrailingPathDelimiter(FConfig.ImportPath), FileName);
        var TargetExtractedFileName := TPath.ChangeExtension(LocalFileName, '');  // Just remove the .gz part
        FDecompressGZFile(LocalFileName, TargetExtractedFileName);

        //todo: show better progress?

        Item.Caption := '100';
        Item.SubItems[1] := 'Extracted';
      except
        Item.SubItems[1] := 'Error';
      end;
    end;
  finally
    LvResults.Items.EndUpdate;
  end;

  //start timer that checks whether progress is complete to 100%
  // once progress done, enable next button.
  Timer1.Enabled := True;
end;

procedure TDlgUpdateDatabase.FStartImport(const FileName: string; ImportTableID: TImportTableIDs; ProgressRow: TListItem);
begin
  var ImportThread := TImportThread.Create(FileName, ImportTableID,
    procedure(Progress: Integer)
    begin
      ProgressRow.Caption := IntToStr(Progress);
    end);
  ImportThread.Start;
end;

{procedure RunCommandAsync(const Command: string; const OnFinished: TProc);
begin
  TTask.Run(
    procedure
    var
      StartInfo: TStartupInfo;
      ProcInfo: TProcessInformation;
      CmdLine: string;
    begin
      ZeroMemory(@StartInfo, SizeOf(StartInfo));
      StartInfo.cb := SizeOf(StartInfo);

      CmdLine := 'cmd.exe /C ' + Command;

      if CreateProcess(nil, PChar(CmdLine), nil, nil, False,
                       CREATE_NO_WINDOW, nil, nil, StartInfo, ProcInfo) then
      begin
        WaitForSingleObject(ProcInfo.hProcess, INFINITE);

        CloseHandle(ProcInfo.hProcess);
        CloseHandle(ProcInfo.hThread);
      end
      else
        RaiseLastOSError;

      // Callback in main thread after process finishes
      if Assigned(OnFinished) then
        TThread.Queue(nil,
          procedure
          begin
            OnFinished();
          end
        );
    end
  );
end;

// Example usage
begin
  RunCommandAsync('echo Hello > C:\Temp\async_test.txt',
    procedure
    begin
      // This runs in main thread after process finishes
      Writeln('Command finished!');
    end
  );

  Writeln('Main UI still responsive...');
end.}

procedure TDlgUpdateDatabase.FDoImportCSV;

  procedure FRunCommandAndWait(const Command: string);
  var
    StartInfo: TStartupInfo;
    ProcInfo: TProcessInformation;
  begin
    ZeroMemory(@StartInfo, SizeOf(StartInfo));
    StartInfo.cb := SizeOf(StartInfo);

    var CmdLine := 'cmd.exe /C ' + Command;

    if CreateProcess(nil, PChar(CmdLine), nil, nil, False, CREATE_NO_WINDOW, nil, nil, StartInfo, ProcInfo) then begin
      WaitForSingleObject(ProcInfo.hProcess, INFINITE);
      CloseHandle(ProcInfo.hProcess);
      CloseHandle(ProcInfo.hThread);
    end else
      RaiseLastOSError;
  end;

const
  sqliteCSVImportString = 'sqlite3 .\dbase\BrickStack.db -cmd ".mode csv" -cmd ".import --skip 1 .\import\%s.csv %s" ".quit"';
begin
  FCurrentStep := stepImport;

  //todo: Truncate these tables first.
  
  LvResults.Clear;
  LvResults.Items.BeginUpdate;
  try
    for var FileName in ImportTableNames do begin
      var Item := LvResults.Items.Add;
      Item.Caption := '0';
      Item.SubItems.Add(FileName);
      Item.SubItems.Add('Importing');
      Item.SubItems.Add(FormatDateTime('YYYYMMDD', Now));

      try
        FRunCommandAndWait(Format(sqliteCSVImportString, [FileName, FileName]));
        //TParallel.run();
//{
        TParallel.For(0, High(ImportTableNames),
          procedure(I: Integer)
          begin
            // INSERT into same SQLite connection
//            FRunCommandAndWait(Format(sqliteCSVImportString, [ImportTableNames[I], ImportTableNames[I]]));
          end
        );//}
        //

        Item.Caption := '100';
        Item.SubItems[1] := 'Done';
      except
        Item.SubItems[1] := 'Error';
      end;
    end;
  finally
    LvResults.Items.EndUpdate;
  end;


//Command line option:
//ImportDataCmd[I]


//sql option
 {
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
            {var QResult :=} {FExecSQLAndUpdateProgress(FDQuery, TableName, Sql);

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


//---------------------
                    {
  LvResults.Clear;

  for var ImportTableID := Low(TImportTableIDs) to High(TImportTableIDs) do begin
    var FileToImport := ImportFileNames[Integer(ImportTableID)];

    var Item := LvResults.Items.Add;
    Item.Caption := '0';
    Item.SubItems.Add(FileToImport);
    Item.SubItems.Add('Importing');
    Item.SubItems.Add(FormatDateTime('YYYYMMDD', Now));

    try
      var LocalFileName := TPath.Combine(IncludeTrailingPathDelimiter(FConfig.ImportPath), FileToImport);
      FStartImport(LocalFileName, ImportTableID, Item);

      Item.Caption := '100';
      Item.SubItems[1] := 'Imported';
    except
      Item.SubItems[1] := 'Error';
    end;

    //just one for now:
    Exit; //todo remove this

    // Sleep a little between additions so we don't get Errors, and add errorhandling to the downloadthread.
    Sleep(10);
  end;

  //start timer that checks whether progress is complete to 100%
  // once progress done, enable next button.
  Timer1.Enabled := True;  }
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
      if FIsStepDone then begin
        Timer1.Enabled := False;
        BtnDownloadFilesClick(Sender);
      end;
    stepDownload:
      if FIsStepDone then begin
        Timer1.Enabled := False;
        BtnExtractFilesClick(Sender);
      end;
    stepExtract:
      if FIsStepDone then begin
        Timer1.Enabled := False;
        BtnImportCSVClick(Sender);
      end;
    stepImport:
      if FIsStepDone then begin
        Timer1.Enabled := False;
        BtnCleanupImportClick(Sender);
      end;
    stepCleanup:
      if FIsStepDone then begin
        Timer1.Enabled := False;
        // show results and disable timer
        //todo: or FUpdateCancelled.
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
