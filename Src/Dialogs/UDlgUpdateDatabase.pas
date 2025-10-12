unit UDlgUpdateDatabase;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  FireDAC.Comp.Client,
  USQLUpdate,
  UConfig, Vcl.ExtCtrls;

type
  TUpdateMode = ( // Update modes:
                  umNONE = 0,      // Version already latest
                  umNOUPDATE = 1,  // Version incompatible, please manualy upgrade
                  umNEW = 2,       // No DB found, creating.
                  umUPDATE = 3,    // Older version found, updating.
                  umIMPORTCSV = 4  // Update base data from csv
                );

  // These should always match ImportFileNames below.
  TImportTableIDs = ( itTHEMES = 0,
                      itCOLORS = 1,
                      itPARTCATEGORIES = 2,
                      itPARTS = 3,
                      itPART_RELATIONSHIPS = 4,
                      itELEMENTS = 5,
                      itSETS = 6,
                      itMINIFIGS = 7,
                      itINVENTORIES = 8,
                      itINVENTORY_PARTS = 9,
                      itINVENTORY_SETS = 10,
                      itINVENTORY_MINIFIGS = 11);

  TDlgUpdateDatabase = class(TForm)
    BtnOK: TButton;
    BtnCancel: TButton;
    TimerCheckForNextStep: TTimer;
    PCDBWizard: TPageControl;
    TsTables: TTabSheet;
    LvResults: TListView;
    LblProgress: TLabel;
    TsStart: TTabSheet;
    Memo1: TMemo;
    TsResults: TTabSheet;
    ListView2: TListView;
    LblResults: TLabel;
    TsUpdate: TTabSheet;
    Memo3: TMemo;
    ChkDoNotRemind: TCheckBox;
    TsReImport: TTabSheet;
    Memo2: TMemo;
    procedure TimerCheckForNextStepTimer(Sender: TObject);
    procedure BtnOKClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure BtnCancelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    FConfig: TConfig;
    FCurrentStep: Integer;
    FUpdateMode: TUpdateMode;
    function FStepMaxCount(Step: Integer): Integer;
    function FGetNextStep(): Integer;
    procedure FDoNextStep;
    procedure FDoCreateDatabaseAndTables(const TableAndSQL: array of TTableSQL);
    procedure FDoDownloadFiles;
    procedure FStartDownload(const URL, FileName: string; ProgressRow: TListItem);
    procedure FDoImportCSV;
    procedure FDoExtractFiles;
    procedure FDoCleanup;
  public
    class function CurrentDBVersion: Integer;
    class function MinDBVersion: Integer;
    { Public declarations }
    property Config: TConfig read FConfig write FConfig;
    property UpdateMode: TUpdateMode read FUpdateMode write FUpdateMode;
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
  UBSSQL,
  URBCSV,
  //URBSQL_Drop,
  URBSQL_Tables,
  URBSQL_Indexes,
  ZLib,
  UITypes,
  Winapi.ShellAPI,
  System.RegularExpressions;

const
  // Wizard steps:
  stepStart = 0;
  stepDownload = 1;
  stepExtract = 2;
  stepValidate = 3;
  stepBS_DBTables = 4;
  stepRB_DBTables = 5;
  stepBS_DBIndexes = 6;
  stepRB_DBIndexes = 7;
  stepImport = 8;
  stepCleanup = 9;
  stepFinished = 10;

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

class function TDlgUpdateDatabase.CurrentDBVersion: Integer;
begin
  Result := DBVersion;
end;

class function TDlgUpdateDatabase.MinDBVersion: Integer;
begin
  Result := dbMINVERSION;
end;

procedure TDlgUpdateDatabase.FormCreate(Sender: TObject);
begin
  ChkDoNotRemind.Visible := False;
end;

procedure TDlgUpdateDatabase.FormShow(Sender: TObject);
begin
  FCurrentStep := 0;
  PCDBWizard.TabIndex := 0;

  for var I := 0 to PCDBWizard.PageCount-1 do
    PCDBWizard.Pages[I].TabVisible := False;

  //run query, check database version.
  var DbasePath := FConfig.DbasePath;
  if not FileExists(DbasePath) then begin
    // New database! Run from start
    PCDBWizard.ActivePage := TsStart;
  end else begin
    // Database exists, run version check.
    PCDBWizard.ActivePage := TsUpdate;
  end;

  //TsReImport
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
  ForceDirectories(TPath.GetDirectoryName(FConfig.ImportPath));

  LvResults.Clear;
  LvResults.Items.BeginUpdate;
  try
    for var FileToDownload in DownloadFiles do begin
      var FileName := TPath.GetFileName(FileToDownload);
      var Item := LvResults.Items.Add;
      Item.Caption := '0';
      Item.SubItems.Add(FileName);
      Item.SubItems.Add('n/a');     //todo get the old data time (register somewhere in a dbase)
      Item.SubItems.Add(FormatDateTime('YYYYMMDD', Now));

      var LocalFileName := TPath.Combine(IncludeTrailingPathDelimiter(FConfig.ImportPath), FileName);
      FStartDownload(FileToDownload, LocalFileName, Item);

      // Sleep a little between additions so we don't get Errors, and add errorhandling to the downloadthread.
      Sleep(100);
    end;
  finally
    LvResults.Items.EndUpdate;
  end;

  //start timer that checks whether progress is complete to 100%
  // once progress done, enable next button.
  TimerCheckForNextStep.Enabled := True;
end;

procedure TDlgUpdateDatabase.FDoCreateDatabaseAndTables(const TableAndSQL: array of TTableSQL);

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
        Item.SubItems.Add('Running');
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
        Item.SubItems[1] := IfThen(ExecResult, 'Created', 'Error');
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

          for var I := Low(TableAndSQL) to High(TableAndSQL) do begin
            var TableName := TableAndSQL[i].tablename;
            var Sql := TableAndSQL[i].sql;
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
  LvResults.Clear;
  LvResults.Items.BeginUpdate;
  try
    for var FileToDownload in DownloadFiles do begin
      var FileName := TPath.GetFileName(FileToDownload);
      var Item := LvResults.Items.Add;
      Item.Caption := '0';
      Item.SubItems.Add(FileName);
      Item.SubItems.Add('Extracting');
      Item.SubItems.Add(FormatDateTime('YYYYMMDD', Now));

      try
        var LocalFileName := TPath.Combine(IncludeTrailingPathDelimiter(FConfig.ImportPath), FileName);
        var TargetExtractedFileName := TPath.ChangeExtension(LocalFileName, '');  // Just remove the .gz part
        if (TargetExtractedFileName.Length > 1) and TargetExtractedFileName.EndsWith('.') then
          SetLength(TargetExtractedFileName, Length(TargetExtractedFileName) - 1);
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
  TimerCheckForNextStep.Enabled := True;
end;

procedure TDlgUpdateDatabase.FDoImportCSV;

  procedure FRunCommandAsync(const Command: string; Item: TListItem);
  begin
    TTask.Run(
      procedure
      var
        StartInfo: TStartupInfo;
        ProcInfo: TProcessInformation;
        CmdLine: string;
        Success: Boolean;
        ExitCode: DWORD;
      begin
        ZeroMemory(@StartInfo, SizeOf(StartInfo));
        ZeroMemory(@ProcInfo, SizeOf(ProcInfo));
        StartInfo.cb := SizeOf(StartInfo);
        CmdLine := 'cmd.exe /C ' + Command;
        Success := False;

        var WorkingDir := ExtractFilePath(Application.ExeName);
        if CreateProcess(nil, PChar(CmdLine), nil, nil, False, CREATE_NO_WINDOW, nil, PChar(WorkingDir), StartInfo, ProcInfo) then begin
          WaitForSingleObject(ProcInfo.hProcess, INFINITE);
          GetExitCodeProcess(ProcInfo.hProcess, ExitCode);
          CloseHandle(ProcInfo.hProcess);
          CloseHandle(ProcInfo.hThread);
          Success := (ExitCode = 0);
        end;

        TThread.Queue(nil,
          procedure
          begin
            if Success then begin
              Item.Caption := '100';
              Item.SubItems[1] := 'Done';
            end else begin
              Item.SubItems[1] := 'Error: ' + IntToStr(ExitCode);
            end;
          end
        );
      end
    );
  end;

const
  sqliteCSVImportString = 'sqlite3 .\dbase\BrickStack.db -cmd ".mode csv" -cmd ".import --skip 1 .\import\%s.csv %s" ".quit"';
begin
  LvResults.Clear;
  LvResults.Items.BeginUpdate;
  try
    for var FileName in ImportTableNames do begin
      var Item := LvResults.Items.Add;
      Item.Caption := '0';
      Item.SubItems.Add(FileName);
      Item.SubItems.Add('Importing');
      Item.SubItems.Add(FormatDateTime('YYYYMMDD', Now));

      FRunCommandAsync(Format(sqliteCSVImportString, [FileName, FileName]), Item);
    end;
  finally
    LvResults.Items.EndUpdate;
  end;

  //start timer that checks whether progress is complete to 100%
  // once progress done, enable next button.
  TimerCheckForNextStep.Enabled := True;
end;

procedure TDlgUpdateDatabase.FDoCleanup;
begin
  LvResults.Clear;
  LvResults.Items.BeginUpdate;
  try
    for var FileName in DownloadFileNames do begin
      var Item := LvResults.Items.Add;
      Item.Caption := '0';
      Item.SubItems.Add(FileName);
      Item.SubItems.Add('Deleting');
      Item.SubItems.Add(FormatDateTime('YYYYMMDD', Now));

      var Deleted := 0;
      var FilePath := TPath.Combine(IncludeTrailingPathDelimiter(FConfig.ImportPath), FileName);
      var ExtractedFile := TPath.ChangeExtension(FilePath, '');
      if (ExtractedFile.Length > 1) and ExtractedFile.EndsWith('.') then
        SetLength(ExtractedFile, Length(ExtractedFile) - 1);

      try
        if TFile.Exists(FilePath) then begin
//          TFile.Delete(FilePath);
          Inc(Deleted);
        end;

        if TFile.Exists(ExtractedFile) then begin
//          TFile.Delete(ExtractedFile);
          Inc(Deleted);
        end;
      except
        //
      end;

      if Deleted > 0 then
        Item.SubItems[1] := Format('Deleted %d/2', [Deleted])
      else
        Item.SubItems[1] := 'Not found';
      Item.Caption := '100';
    end;
  finally
    LvResults.Items.EndUpdate;
  end;

  // Start timer to check for completion and enable next step
  TimerCheckForNextStep.Enabled := True;
end;

function TDlgUpdateDatabase.FGetNextStep(): Integer;
begin
  Result := FCurrentStep + 1;
end;

procedure TDlgUpdateDatabase.FDoNextStep;
begin
//  var StepAtStartOfFunction := FCurrentStep;
//  FCurrentStep := FGetNextStep;

  case FCurrentStep of
    //stepStart:        FCurrentStep := FGetNextStep;
    stepDownload:     FDoDownloadFiles;
    stepExtract:      FDoExtractFiles;
    stepValidate:
    begin
      //todo: ensure CSV files have the required number of columns
      // otherwise, show error
      //FCurrentStep := FGetNextStep;
    end;
    stepBS_DBTables:  FDoCreateDatabaseAndTables(BS_CreateTables); //Result := High(BS_CreateTables) + 2; // +2 because of BSDBVersions
    stepRB_DBTables:  FDoCreateDatabaseAndTables(RB_CreateTablesAndTriggers); //Result := High(RB_CreateTablesAndTriggers) + 1;
    stepBS_DBIndexes: FDoCreateDatabaseAndTables(BS_CreateIndexes); //Result := High(BS_CreateIndexes) + 1;
    stepRB_DBIndexes: FDoCreateDatabaseAndTables(RB_CreateIndexes); //Result := High(RB_CreateIndexes) + 1;
    stepImport:       FDoImportCSV;
    stepCleanup:      FDoCleanup;
    stepFinished:
    begin
      MessageDlg(StrMsgDataBaseUpdateComplete, mtInformation, [mbOK], 0);
      ModalResult := mrOk;
    end;
  end;
        {
  var ASyncTask := TTask.Run(procedure
  begin
    // Background task
    try
      FDoCreateDatabaseAndTables();
    except
      //
    end;
  end);   }

end;

function TDlgUpdateDatabase.FStepMaxCount(Step: Integer): Integer;
begin
  case FCurrentStep of
    stepStart:        Result := 0;
    stepDownload:     Result := High(DownloadFileNames) + 1;
    stepExtract:      Result := High(DownloadFiles) + 1;
    stepValidate:     Result := High(DownloadFiles) + 1;
    stepBS_DBTables:  Result := High(BS_CreateTables) + 1;
    stepRB_DBTables:  Result := High(RB_CreateTablesAndTriggers) + 1;
    stepBS_DBIndexes: Result := High(BS_CreateIndexes) + 1;
    stepRB_DBIndexes: Result := High(RB_CreateIndexes) + 1;
    stepImport:       Result := High(DownloadFiles) + 1;
    stepCleanup:      Result := High(DownloadFiles) + 1;
    stepFinished:     Result := 0;
    else begin
      Result := 0;
    end;
  end;
end;

procedure TDlgUpdateDatabase.TimerCheckForNextStepTimer(Sender: TObject);

  function FIsStepDone(): Boolean;
  begin
    var AmountDone := 0;
    for var LvItem in LvResults.Items do begin
      if StrToIntDef(LvItem.Caption, 0) = 100 then
        Inc(AmountDone);
    end;

    Result := AmountDone = FStepMaxCount(FCurrentStep);
  end;

begin
  // Check whether all downloads are finished, if so, disable timer and start the next step
  //  LblDownloadState.Caption := Format('In progress (%d/%d)', [Done, ListView1.Items.Count]);
  TimerCheckForNextStep.Enabled := False;
  try
    if FIsStepDone then begin
      FCurrentStep := FGetNextStep;
      FDoNextStep;
    end;
  finally
    TimerCheckForNextStep.Enabled := True;
  end;
end;

procedure TDlgUpdateDatabase.BtnOKClick(Sender: TObject);
begin
  BtnOK.Enabled := False;
  BtnCancel.Enabled := False;
  BtnOK.Caption := 'Next';
  LblProgress.Caption := 'Creating database tables';

  PCDBWizard.ActivePage := TsTables;

  FCurrentStep := stepStart;
  TimerCheckForNextStep.Enabled := True;

  FDoNextStep;
end;

procedure TDlgUpdateDatabase.BtnCancelClick(Sender: TObject);
begin
  //todo: cancel and close everything. make sure all tasks are ended before closing
  // or at least halted somehow.
  ModalResult := mrCancel;
end;

end.
