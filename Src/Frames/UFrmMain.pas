unit UFrmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, Vcl.Graphics, Vcl.Forms,
  Vcl.Controls, Vcl.Menus, Vcl.StdCtrls, Vcl.Dialogs, Vcl.Buttons,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.StdActns, Vcl.ActnList, Vcl.ToolWin, Vcl.ImgList,
  System.SysUtils, System.Classes, System.ImageList, System.Actions,
  USqLiteConnection,
  FireDAC.Comp.Client,
  UDlgUpdateDatabase, UITypes,
  UConfig, UImageCache, UPostMessage;

type
  TFrmMain = class(TForm)
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    FileNewItem: TMenuItem;
    FileOpenItem: TMenuItem;
    FileCloseItem: TMenuItem;
    Window1: TMenuItem;
    Help1: TMenuItem;
    N1: TMenuItem;
    FileExitItem: TMenuItem;
    WindowCascadeItem: TMenuItem;
    WindowTileItem: TMenuItem;
    WindowArrangeItem: TMenuItem;
    HelpAboutItem: TMenuItem;
    OpenDialog: TOpenDialog;
    FileSaveItem: TMenuItem;
    FileSaveAsItem: TMenuItem;
    Edit1: TMenuItem;
    CutItem: TMenuItem;
    CopyItem: TMenuItem;
    PasteItem: TMenuItem;
    WindowMinimizeItem: TMenuItem;
    StatusBar: TStatusBar;
    ActionList1: TActionList;
    EditCut1: TEditCut;
    EditCopy1: TEditCopy;
    EditPaste1: TEditPaste;
    FileNew1: TAction;
    FileSave1: TAction;
    FileExit1: TAction;
    FileOpen1: TAction;
    FileSaveAs1: TAction;
    WindowCascade1: TWindowCascade;
    WindowTileHorizontal1: TWindowTileHorizontal;
    WindowArrangeAll1: TWindowArrange;
    WindowMinimizeAll1: TWindowMinimizeAll;
    ActAbout: TAction;
    FileClose1: TWindowClose;
    WindowTileVertical1: TWindowTileVertical;
    WindowTileItem2: TMenuItem;
    ToolBar2: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton9: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    ToolButton10: TToolButton;
    ToolButton11: TToolButton;
    ImageList16: TImageList;
    ActConfig1: TMenuItem;
    ActConfig: TAction;
    N2: TMenuItem;
    ActImport: TAction;
    ActExport: TAction;
    Import1: TMenuItem;
    N3: TMenuItem;
    ActCollection: TAction;
    N4: TMenuItem;
    YourCollection1: TMenuItem;
    ImageList32: TImageList;
    ActAuthenticate: TAction;
    Database1: TMenuItem;
    Search1: TMenuItem;
    ActSearch: TAction;
    ActHelp: TAction;
    Help2: TMenuItem;
    ActUpdateDatabase: TAction;
    Export2: TMenuItem;
    Updatedatabase1: TMenuItem;
    N5: TMenuItem;
    N6: TMenuItem;
    procedure FileOpen1Execute(Sender: TObject);
    procedure ActAboutExecute(Sender: TObject);
    procedure FileExit1Execute(Sender: TObject);
    procedure ActConfigExecute(Sender: TObject);
    procedure ActCollectionExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ActAuthenticateExecute(Sender: TObject);
    procedure ActSearchExecute(Sender: TObject);
    procedure ActHelpExecute(Sender: TObject);
    procedure WMShowSet(var Msg: TMessage); message WM_SHOW_SET;
    procedure WMShowPartsList(var Msg: TMessage); message WM_SHOW_PARTSLIST;
    procedure WMEditPartsList(var Msg: TMessage); message WM_EDIT_PARTSLIST;
    procedure WMShowSetList(var Msg: TMessage); message WM_SHOW_SETLIST;
    procedure WMOpenExternal(var Msg: TMessage); message WM_OPEN_EXTERNAL;
    procedure WMShowSearch(var Msg: TMessage); message WM_SHOW_SEARCH;
    procedure WMShowCollection(var Msg: TMessage); message WM_SHOW_COLLECTION;
    procedure WMUpdateSetList(var Msg: TMessage); message WM_UPDATE_SETLIST;
    procedure WMUpdateCollection(var Msg: TMessage); message WM_UPDATE_COLLECTION;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure ActUpdateDatabaseExecute(Sender: TObject);
  private
    { Private declarations }
    FConfig: TConfig;
    FImageCache: TImageCache;
    FConnectionPool: TFDConnectionPool;
    function FFindMDIChildByClass(AFormClass: TFormClass): TForm;
    procedure FUpdateMDIChild(AFormClass: TFormClass; BSSetListID: Integer);
    function FCreateMDIChild(AFormClass: TFormClass; const Title: string; AllowMultiple: Boolean): TForm;
    function CtrlShiftPressed: Boolean;
    function FCheckDatabaseVersion(): TUpdateMode;
    procedure FUpdateUI;
    function FDoUpdateDatabase(UpdateMode: TUpdateMode): String;
  public
    { Public declarations }
    //class procedure ShowSetList();
    //class procedure AddToSet();
    function AcquireConnection: TFDConnection; inline;
    procedure ReleaseConnection(Conn: TFDConnection); inline;
    class procedure ShowSetWindow(const set_num: String);
    class procedure ShowPartsWindow(const set_num: String);
    class procedure EditPartsWindow(const set_num: String; const BSSetID: Integer);
    class procedure ShowSetListWindow(const BSSetListID: Integer);
    class procedure OpenExternal(ObjectType: Integer; const ObjectID: String);
    class procedure ShowSearchWindow;
    class procedure ShowCollectionWindow;
    class procedure UpdateSetsByCollectionID(BSSetListID: Integer);
    class procedure UpdateCollectionsByID(BSSetListID: Integer);
  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.dfm}

uses
  ShellAPI, IOUtils, Themes, Styles, System.DateUtils,
  UFrmChild, UFrmSetListCollection, UFrmSearch, UFrmSet, UFrmSetList, UFrmParts,
  UDlgAbout, UDlgConfig, UDlgTest, UDlgLogin, UDlgHelp, UDlgViewExternal,
  UStrings;

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  inherited;

  FConfig := TConfig.Create;
  FConfig.Load;

  TStyleManager.SetStyle(FConfig.VisualStyle);

  FImageCache := TImageCache.Create;
  FImageCache.Config := FConfig;

  if FConfig.DBasePath <> '' then
    FConnectionPool := TFDConnectionPool.Create(FConfig.DBasePath)
  else
    FConnectionPool := TFDConnectionPool.Create(ExtractFilePath(ParamStr(0)) + '\Dbase\Brickstack.db');
end;

procedure TFrmMain.FormDestroy(Sender: TObject);
begin
  FImageCache.Free;
  try
    FConfig.Save(csWINDOWPOSITIONS);
  finally
    FConfig.Free;
  end;

  inherited;
end;

procedure TFrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  // First, reset which windows were open
  FConfig.ResetFramesOpenOnLoad;

  // Remember open windows and size
  for var I := 0 to MDIChildCount-1 do begin
    var Child := MDIChildren[I];
    if Child.ClassType = TFrmSetListCollection then begin
      FConfig.FrmSetListCollection.OpenOnLoad := '1';
      FConfig.FrmSetListCollection.GetFormDimensions(Child);
    end else if Child.ClassType = TFrmSetList then begin
      FConfig.FrmSetList.OpenOnLoad := IntToStr(TFrmSetList(Child).BSSetListID);
      FConfig.FrmSetList.GetFormDimensions(Child);
    end else if Child.ClassType = TFrmSet then begin
      FConfig.FrmSet.OpenOnLoad := TFrmSet(Child).SetNum;
      FConfig.FrmSet.GetFormDimensions(Child);
    end else if Child.ClassType = TFrmParts then begin
      FConfig.FrmParts.OpenOnLoad := TFrmParts(Child).SetNum;
      FConfig.FrmParts.GetFormDimensions(Child);
    end else if Child.ClassType = TFrmSearch then begin
      FConfig.FrmSearch.OpenOnLoad := '1';
      FConfig.FrmSearch.GetFormDimensions(Child);
    end;
  end;

  inherited;
end;

function TFrmMain.CtrlShiftPressed: Boolean;
begin
  Result := (GetKeyState(VK_CONTROL) < 0) and (GetKeyState(VK_SHIFT) < 0);
end;

function TFrmMain.FCheckDatabaseVersion(): TUpdateMode;

  function FQueryVersion(Query: TFDQuery): Integer;
  begin
    Result := 0;

    Query.SQL.Text := 'SELECT MAX(dbversion) AS version' +
                      ' FROM BSDBVersions';
    try
      Query.Open; // Open the query to retrieve data

      try
        Query.First; // Move to the first row of the dataset

        if not Query.EOF then
          Result := StrToIntDef(Query.FieldByName('version').AsString, 0);
      finally
        Query.Close; // Close the query when done
      end;
    except
      //
    end;
  end;

begin
  if not FileExists(FConfig.DbasePath) then
    Result := umNEW
  else begin
    Result := umNONE;

    var SqlConnection := AcquireConnection;
    var FDQuery := TFDQuery.Create(nil);
    try
      FDQuery.Connection := SqlConnection;
      var DBVersion := FQueryVersion(FDQuery);
      if DBVersion < TDlgUpdateDatabase.MinDBVersion then
        Result := umNOUPDATE
      else if FQueryVersion(FDQuery) < TDlgUpdateDatabase.CurrentDBVersion then
        Result := umUPDATE;
    finally
      FDQuery.Free;
      FrmMain.ReleaseConnection(SqlConnection);
    end;
  end;
end;

function TFrmMain.FDoUpdateDatabase(UpdateMode: TUpdateMode): String;
begin
  Result := '';
  case UpdateMode of
    umNONE:
      Result := StrMsgDatabaseIsUpToDate;
    umNOUPDATE:
    begin
      //Todo: Instead of letting the user do this - move the database to a subfolder.
      //Then, do umNEW (rename to umNEWUPDATE)
      //Then copy the BS database tables to the new database.
      Result := StrMsgDatabaseUnableToUpDate;
    end;
    umNEW, umUPDATE:
    begin
      var DlgUpdateDatabase := TDlgUpdateDatabase.Create(Self);
      try
        DlgUpdateDatabase.UpdateMode := UpdateMode;
        DlgUpdateDatabase.Config := FConfig;
        DlgUpdateDatabase.ShowModal;
        FUpdateUI;
      finally
        DlgUpdateDatabase.Free;
      end;
    end;
  end;
end;

procedure TFrmMain.ActUpdateDatabaseExecute(Sender: TObject);
begin
  var UpdateMode := FCheckDatabaseVersion;

  // If structure is fine, check when the last rebrickable CSV import happened
  if UpdateMode = umNONE then begin
    var ImportDate: TDateTime := 0;

    var SqlConnection := AcquireConnection;
    var FDQuery := TFDQuery.Create(nil);
    try
      FDQuery.Connection := SqlConnection;
      try
        FDQuery.SQL.Text := 'SELECT MAX(DBDateTime) AS D FROM BSDBVersions';
        try
          FDQuery.Open;
          if not FDQuery.EOF then begin
            var vStr := Trim(FDQuery.FieldByName('D').AsString);
            if vStr <> '' then begin
              // Expect format: yyyymmdd,hhnnss
              var commaPos := Pos(',', vStr);
              if commaPos > 0 then begin
                var datePart := Copy(vStr, 1, commaPos-1);
                var timePart := Copy(vStr, commaPos+1, MaxInt);
                if (Length(datePart) >= 8) and (Length(timePart) >= 6) then begin
                  var y := StrToIntDef(Copy(datePart,1,4), 0);
                  var m := StrToIntDef(Copy(datePart,5,2), 0);
                  var d := StrToIntDef(Copy(datePart,7,2), 0);
                  var hh := StrToIntDef(Copy(timePart,1,2), 0);
                  var nn := StrToIntDef(Copy(timePart,3,2), 0);
                  var ss := StrToIntDef(Copy(timePart,5,2), 0);
                  try
                    ImportDate := EncodeDateTime(y, m, d, hh, nn, ss, 0);
                  except
                    ImportDate := 0;
                  end;
                end;
              end;
            end;
          end;
        except
          // If any error reading the value, treat as never imported
          ImportDate := 0;
        end;
      finally
        FDQuery.Close;
      end;
    finally
      FDQuery.Free;
      FrmMain.ReleaseConnection(SqlConnection);
    end;

    var NeedPrompt := (ImportDate = 0) or (DaysBetween(Now, ImportDate) >= 7);
    if NeedPrompt then begin
      var MsgDate := 'Never';
      if ImportDate <> 0 then
        MsgDate := DateTimeToStr(ImportDate);

      if MessageDlg(Format('Latest import: %s'#13#10#13#10 + 'Download a fresh database now?',
          [MsgDate]), mtConfirmation, [mbYes, mbNo], 0) = mrYes then begin
        var UpdateResult := FDoUpdateDatabase(umUPDATE);
        if UpdateResult <> '' then
          ShowMessage(UpdateResult);
      end;
      Exit;
    end else begin
      // recent enough, nothing to do
      ShowMessage(StrMsgDatabaseIsUpToDate);
      Exit;
    end;
  end;

  // For other cases delegate to existing updater handling
  var UpdateResult := FDoUpdateDatabase(UpdateMode);
  if UpdateResult <> '' then
    ShowMessage(UpdateResult);
end;

procedure TFrmMain.FormShow(Sender: TObject);
begin
  inherited;

  // Check whether we can show dialogs.
  FUpdateUI;

  // Database validation on startup
  var UpdateMode := FCheckDatabaseVersion;
  var UpdateResult := FDoUpdateDatabase(UpdateMode);
  if SameText(UpdateResult, StrMsgDatabaseUnableToUpDate) then begin
    ShowMessage(UpdateResult);
    Exit;
  end;// else
  //ActCheckDatabaseImportVersions;  // Based on setting, see how often we need to check for import versions.

  // Check if the user created the database //todo: and if version matches miminum version.
  if FileExists(FConfig.DbasePath) then begin
    // Restore previously open child windows
    if FConfig.ReOpenWindowsAfterRestart and ActCollection.Enabled then begin
      // Skip if both Ctrl and Shift are pressed, so we can reset window positions.
      if CtrlShiftPressed then
        FConfig.ResetFramesOpenOnLoad
      else begin
        if StrToIntDef(FConfig.FrmSetListCollection.OpenOnLoad, 0) <> 0 then
          ShowCollectionWindow;
        if StrToIntDef(FConfig.FrmSetList.OpenOnLoad, 0) > 0 then
          ShowSetListWindow(StrToInt(FConfig.FrmSetList.OpenOnLoad)); // Already checked to be valid
        if FConfig.FrmSet.OpenOnLoad <> '' then
          ShowSetWindow(FConfig.FrmSet.OpenOnLoad);
        if FConfig.FrmParts.OpenOnLoad <> '' then
          ShowPartsWindow(FConfig.FrmParts.OpenOnLoad);
        //if FConfig.FrmEditParts.OpenOnLoad <> '' then //todo
          //ShowPartsWindow(FConfig.FrmEditParts.OpenOnLoad);
        if StrToIntDef(FConfig.FrmSearch.OpenOnLoad, 0) <> 0 then
          ShowSearchWindow;
      end;
    end;
  end;
end;

procedure TFrmMain.FUpdateUI;
begin
  // Don't allow dialogs that require the database if there is no database.
  var DbasePath := FConfig.DbasePath;
  ActCollection.Enabled := FileExists(DbasePath);
  ActSearch.Enabled := ActCollection.Enabled;
  FileOpen1.Enabled := ActCollection.Enabled;

end;

procedure TFrmMain.WMShowSearch(var Msg: TMessage);
begin
  {var Child := }FCreateMDIChild(TFrmSearch, StrSearchFrameTitle, False);
{  try
    if Assigned(Child) then begin
      //Do stuff
    end;
  finally
    //
  end;}
end;

procedure TFrmMain.WMShowCollection(var Msg: TMessage);
begin
  {var Child := }FCreateMDIChild(TFrmSetListCollection, StrSetListFrameTitle, False);
{  try
    if Assigned(Child) then begin
      //Do stuff
    end;
  finally
    //
  end;}
end;

procedure TFrmMain.WMShowSet(var Msg: TMessage);
begin
  var MsgData := PShowSetData(Msg.WParam);
  try
    if Assigned(MsgData) then begin
      var Child := FCreateMDIChild(TFrmSet, StrSetListFrameTitle, False); // Set to true if we want to allow multiple windows.
      if Assigned(Child) then begin
        var FrmSet := TFrmSet(Child);
        FrmSet.ImageCache := FImageCache;
        FrmSet.LoadSet(MsgData.Set_num); // - multithreaded load
      end;
    end;
  finally
    Dispose(MsgData); // Don't forget to free the allocated memory
  end;
end;

procedure TFrmMain.WMShowPartsList(var Msg: TMessage);
begin
  var MsgData := PShowPartsData(Msg.WParam);
  try
    if Assigned(MsgData) then begin
      var Child := FCreateMDIChild(TFrmParts, StrPartListFrameTitle, False); // Set to true if we want to allow multiple windows.
      if Assigned(Child) then begin
        var FrmParts := TFrmParts(Child);
        FrmParts.ImageCache := FImageCache;
        FrmParts.PartsMode := caView;
        FrmParts.LoadPartsBySet(MsgData.Set_num, False); // - multithreaded load
      end;
    end;
  finally
    Dispose(MsgData); // Don't forget to free the allocated memory
  end;
end;

procedure TFrmMain.WMEditPartsList(var Msg: TMessage);
begin
  var MsgData := PEditPartsData(Msg.WParam);
  try
    if Assigned(MsgData) then begin
      var Child := FCreateMDIChild(TFrmParts, StrPartListFrameTitle, False); // Set to true if we want to allow multiple windows.
      if Assigned(Child) then begin
        var FrmParts := TFrmParts(Child);
        FrmParts.ImageCache := FImageCache;
        FrmParts.PartsMode := caEdit;
        FrmParts.LoadPartsBySet(MsgData.Set_num, False); // - multithreaded load
        FrmParts.LoadPartCountByID(MsgData.BSSetID);
      end;
    end;
  finally
    Dispose(MsgData); // Don't forget to free the allocated memory
  end;
end;

procedure TFrmMain.WMShowSetList(var Msg: TMessage);
begin
  var MsgData := PShowOrUpdateSetListData(Msg.WParam);
  try
    if Assigned(MsgData) then begin
      var Child := FCreateMDIChild(TFrmSetList, StrSetListFrameTitle, False); // Set to true if we want to allow multiple windows.
      if Assigned(Child) then begin
        var FrmSetList := TFrmSetList(Child);
        //FrmSetList.ImageCache := FImageCache;
        FrmSetList.BSSetListID := MsgData.BSSetListID; // - multithreaded load
      end;
    end;
  finally
    Dispose(MsgData); // Don't forget to free the allocated memory
  end;
end;

procedure TFrmMain.WMOpenExternal(var Msg: TMessage);

  function EnsureEndsWith(const S: string; const Ch: Char): string;
  begin
    if (S <> '') and (S[Length(S)] = Ch) then
      Result := S
    else
      Result := S + Ch;
  end;

begin
  var MsgData := POpenExternalData(Msg.WParam);

  var OpenType := cOTNONE;
  if (MsgData.ObjectType = cTYPESET) and (FConfig.DefaultViewSetOpenType <> cOTNONE) then begin
    OpenType := FConfig.DefaultViewSetOpenType;
  end else if (MsgData.ObjectType = cTYPEPART) and (FConfig.DefaultViewPartOpenType <> cOTNONE) then begin
    OpenType := FConfig.DefaultViewPartOpenType;
  end else begin // No default, ask the user what to use
    var Dlg := TDlgViewExternal.Create(Self);
    try
      Dlg.PartOrSet := MsgData.ObjectType;
      Dlg.PartOrSetNumber := MsgData.ObjectID;
      if Dlg.ShowModal = mrOk then begin
        OpenType := Dlg.OpenType;
        if Dlg.CheckState then begin
          if MsgData.ObjectType = cTYPESET then
            FConfig.DefaultViewSetOpenType := OpenType
          else
            FConfig.DefaultViewPartOpenType := OpenType;
          FConfig.Save(csCONFIGDIALOG);
        end;
      end;
    finally
      Dlg.Free;
    end;
  end;

  //Add soap call to API to get the external_id -> {{baseUrl}}/api/v3/lego/parts/:part_num/
  // Save it in the database?
  //Example response:
  (*
  {
    "part_num": "3001pr0043",
    "name": "Brick 2 x 4 with Smile and Frown Print on Opposite Sides",
    "part_cat_id": 11,
    "year_from": 1981,
    "year_to": 2009,
    "part_url": "https://rebrickable.com/parts/3001pr0043/brick-2-x-4-with-smile-and-frown-print-on-opposite-sides/",
    "part_img_url": "https://cdn.rebrickable.com/media/parts/elements/80141.jpg",
    "prints": [],
    "molds": [],
    "alternates": [],
    "external_ids": {
        "BrickLink": [
            "3001pe1"
        ],
        "BrickOwl": [
            "57647"
        ],
        "Brickset": [
            "80141"
        ],
        "LDraw": [
            "3001pe1"
        ],
        "LEGO": [
            "80141"
        ]
    },
    "print_of": "3001"
}
  *)

  var OpenLink := '';
  case OpenType of
    cOTREBRICKABLE:
    begin
      if FConfig.ViewRebrickableUrl = '' then
        Exit;
      OpenLink := EnsureEndsWith(FConfig.ViewRebrickableUrl, '/');
      if MsgData.ObjectType = cTYPESET then
        OpenLink := OpenLink + 'sets/' + MsgData.ObjectID
      else
        OpenLink := OpenLink + 'parts/' + MsgData.ObjectID;
    end;
    cOTBRICKLINK:
    begin
      if FConfig.ViewBrickLinkUrl = '' then
        Exit;
      OpenLink := EnsureEndsWith(FConfig.ViewBrickLinkUrl, '/');
      if MsgData.ObjectType = cTYPESET then
        OpenLink := OpenLink + 'v2/search.page?q=' + MsgData.ObjectID
      else
        OpenLink := OpenLink + 'v2/catalog/catalogitem.page?P=' + MsgData.ObjectID;
    end;
    cOTBRICKOWL:
    begin
      if FConfig.ViewBrickOwlUrl = '' then
        Exit;
      OpenLink := EnsureEndsWith(FConfig.ViewBrickOwlUrl, '/');
      if MsgData.ObjectType = cTYPESET then
        OpenLink := OpenLink + 'search/catalog?query=' + MsgData.ObjectID
      else
        OpenLink := OpenLink + 'search/catalog/' + MsgData.ObjectID;
    end;
    cOTBRICKSET:
    begin
      if FConfig.ViewBrickSetUrl = '' then
        Exit;
      OpenLink := EnsureEndsWith(FConfig.ViewBrickSetUrl, '/') + 'sets/' + MsgData.ObjectID;
    end;
    cOTLDRAW:
    begin
      if FConfig.ViewLDrawUrl = '' then
        Exit;
      OpenLink := EnsureEndsWith(FConfig.ViewLDrawUrl, '/') + 'search/part?s=' + MsgData.ObjectID;
    end;
    cOTCUSTOM:
    begin
      // Not implemented yet
    end;
  end;

  if OpenLink <> '' then begin
    // Include utm_source?
    ShellExecute(0, 'open', PChar(OpenLink), nil, nil, SW_SHOWNORMAL);
  end;
end;

procedure TFrmMain.WMUpdateSetList(var Msg: TMessage);
begin
  var MsgData := PShowOrUpdateSetListData(Msg.WParam);
  try
    if Assigned(MsgData) then begin
      FUpdateMDIChild(TFrmSetList, MsgData.BSSetListID);
      FUpdateMDIChild(TFrmSetListCollection, MsgData.BSSetListID);
    end;
  finally
    Dispose(MsgData); // Don't forget to free the allocated memory
  end;
end;

procedure TFrmMain.WMUpdateCollection(var Msg: TMessage);
begin
  var MsgData := PShowOrUpdateSetListData(Msg.WParam);
  try
    if Assigned(MsgData) then begin
      FUpdateMDIChild(TFrmSetList, MsgData.BSSetListID);
      FUpdateMDIChild(TFrmSetListCollection, MsgData.BSSetListID);
    end;
  finally
    Dispose(MsgData); // Don't forget to free the allocated memory
  end;
end;

function TFrmMain.AcquireConnection: TFDConnection;
begin
  Result := FConnectionPool.AcquireConnection;
end;

procedure TFrmMain.ReleaseConnection(Conn: TFDConnection);
begin
  Conn.Close;
  FConnectionPool.ReleaseConnection(Conn);
end;

class procedure TFrmMain.ShowSearchWindow();
begin
  PostMessage(FrmMain.Handle, WM_SHOW_SEARCH, 0, 0);
end;

class procedure TFrmMain.ShowCollectionWindow();
begin
  PostMessage(FrmMain.Handle, WM_SHOW_COLLECTION, 0, 0);
end;

class procedure TFrmMain.UpdateSetsByCollectionID(BSSetListID: Integer);
  // Tell set windows and collection windows to update because a set was added or removed from a collection.
  // May be called from Search(add) / sets(add/remove)
var
  PostData: PShowOrUpdateSetListData;
begin
  New(PostData);
  try
    PostData^.BSSetListID := BSSetListID;
    if not PostMessage(FrmMain.Handle, WM_UPDATE_SETLIST, WPARAM(PostData), 0) then
      Dispose(PostData);
  except
    Dispose(PostData);
  end;
end;

class procedure TFrmMain.UpdateCollectionsByID(BSSetListID: Integer);
  // Tell collection windows to update because a set was added or removed from a collection.
  // May be called from Search(add) / sets(add/remove)
var
  PostData: PShowOrUpdateSetListData;
begin
  New(PostData);
  try
    PostData^.BSSetListID := BSSetListID;
    if not PostMessage(FrmMain.Handle, WM_UPDATE_COLLECTION, WPARAM(PostData), 0) then
      Dispose(PostData);
  except
    Dispose(PostData);
  end;
end;

class procedure TFrmMain.ShowSetWindow(const set_num: String);
var
  PostData: PShowSetData;
begin
  New(PostData);
  try
    PostData^.Set_num := set_num;
    if not PostMessage(FrmMain.Handle, WM_SHOW_SET, WPARAM(PostData), 0) then
      Dispose(PostData);
  except
    Dispose(PostData);
  end;
end;

class procedure TFrmMain.ShowPartsWindow(const set_num: String);
var
  PostData: PShowPartsData;
begin
  New(PostData);
  try
    PostData^.Set_num := set_num;
    if not PostMessage(FrmMain.Handle, WM_SHOW_PARTSLIST, WPARAM(PostData), 0) then
      Dispose(PostData);
  except
    Dispose(PostData);
  end;
end;

class procedure TFrmMain.EditPartsWindow(const set_num: String; const BSSetID: Integer);
var
  PostData: PEditPartsData;
begin
  New(PostData);
  try
    PostData^.set_num := set_num;
    PostData^.BSSetID := BSSetID;
    if not PostMessage(FrmMain.Handle, WM_EDIT_PARTSLIST, WPARAM(PostData), 0) then
      Dispose(PostData);
  except
    Dispose(PostData);
  end;
end;

class procedure TFrmMain.ShowSetListWindow(const BSSetListID: Integer);
var
  PostData: PShowOrUpdateSetListData;
begin
  New(PostData);
  try
    PostData^.BSSetListID := BSSetListID;
    if not PostMessage(FrmMain.Handle, WM_SHOW_SETLIST, WPARAM(PostData), 0) then
      Dispose(PostData);
  except
    Dispose(PostData);
  end;
end;

// May be set_num or part_num
class procedure TFrmMain.OpenExternal(ObjectType: Integer; const ObjectID: String);
var
  PostData: POpenExternalData;
begin
  New(PostData);
  try
    PostData^.ObjectType := ObjectType;
    PostData^.ObjectID := ObjectID;
    if not PostMessage(FrmMain.Handle, WM_OPEN_EXTERNAL, WPARAM(PostData), 0) then
      Dispose(PostData);
  except
    Dispose(PostData);
  end;
end;

procedure TFrmMain.ActAuthenticateExecute(Sender: TObject);
begin
  //Keep this available when we "need" the authenticationToken for user actions that need the token.
  var DlgLogin := TDlgLogin.Create(Self);
  try
    if DlgLogin.ShowModal = mrOk then begin
      FConfig.AuthenticationToken := DlgLogin.AuthenticationToken;
      FConfig.RememberAuthenticationToken := DlgLogin.RememberAuthenticationToken;

      // Store token
      FConfig.Save(csCONFIGDIALOG);
    end;
  finally
    DlgLogin.Free;
  end;
end;

procedure TFrmMain.ActCollectionExecute(Sender: TObject);
begin
  ShowCollectionWindow;
end;

function TFrmMain.FFindMDIChildByClass(AFormClass: TFormClass): TForm;
begin
  Result := nil;

  // Check whether there's already a window open.
  for var I := 0 to MDIChildCount-1 do begin
    var Child := MDIChildren[I];
    if Child.ClassType = AFormClass then begin
      Result := Child;
      Exit;
    end;
  end;
end;

procedure TFrmMain.FUpdateMDIChild(AFormClass: TFormClass; BSSetListID: Integer);
begin
  var Child := FFindMDIChildByClass(AFormClass); //todo: we can have more than 1 child of the same class, check them all
  if Child <> nil then begin
    if AFormClass = TFrmSetListCollection then begin
      var FrmSetListCollection := TFrmSetListCollection(Child);
      FrmSetListCollection.RebuildBySQL; //BSSetListID //todo: fine tune what to update instead of the whole dialog.
    end else if AFormClass = TFrmSetList then begin
      var FrmSetList := TFrmSetList(Child);
      FrmSetList.ReloadAndRefresh; //BSSetListID
    end;
  end;
end;

function TFrmMain.FCreateMDIChild(AFormClass: TFormClass; const Title: string; AllowMultiple: Boolean): TForm;
begin
  if not AllowMultiple then begin
    // Check whether there's already a window open.
    var Child := FFindMDIChildByClass(AFormClass);
    if Child <> nil then begin
      // Bring to the front instead of creating a new one.
      Child.BringToFront;
      Child.SetFocus;
      Result := Child;
      Exit;
    end;
  end;

  var Child := AFormClass.Create(Application);
  try
    if AFormClass = TFrmSetListCollection then begin
      var FrmSetListCollection := TFrmSetListCollection(Child);
      FrmSetListCollection.Config := FConfig;
      FrmSetListCollection.Caption := Title;
      if not FConfig.FrmSetListCollection.SetFormDimensions(FrmSetListCollection) then begin
        //Set default size
      end;
    end else if AFormClass = TFrmSetList then begin
      var FrmSetList := TFrmSetList(Child);
      FrmSetList.Config := FConfig;
      //FrmSetList.Caption := Title;
      //FrmSetList.FSetSetList();
      if not FConfig.FrmSetList.SetFormDimensions(FrmSetList) then begin
        //Set default size
      end;
    end else if AFormClass = TFrmSet then begin
      var FrmSet := TFrmSet(Child);
      FrmSet.Config := FConfig;
      FrmSet.ImageCache := FImageCache;
      FrmSet.Caption := Title;
      if not FConfig.FrmSet.SetFormDimensions(FrmSet) then begin
        //Set default size
      end;
    end else if AFormClass = TFrmParts then begin
      var FrmParts := TFrmParts(Child);
      FrmParts.Config := FConfig;
      FrmParts.ImageCache := FImageCache;
      FrmParts.PartsMode := caView;
      FrmParts.Caption := Title;
      if not FConfig.FrmParts.SetFormDimensions(FrmParts) then begin
        //Set default size
      end;
    end else if AFormClass = TFrmSearch then begin
      var FrmSearch := TFrmSearch(Child);
      FrmSearch.ImageCache := FImageCache;
      FrmSearch.Config := FConfig;
      FrmSearch.Caption := StrSearchFrameTitle;
      if not FConfig.FrmSearch.SetFormDimensions(FrmSearch) then begin
        //Set default size
      end;
    end;

    Result := Child;
  finally
    //
  end;
end;

procedure TFrmMain.ActSearchExecute(Sender: TObject);
begin
  ShowSearchWindow;
end;

procedure TFrmMain.ActConfigExecute(Sender: TObject);
begin
  var DlgConfig := TDlgConfig.Create(Self);
  DlgConfig.Config := FConfig;
  try
    if DlgConfig.ShowModal = mrOK then
      TStyleManager.SetStyle(FConfig.VisualStyle);
  finally
    FConfig.Save(csCONFIGDIALOG);
    DlgConfig.Free;
  end;
end;

procedure TFrmMain.ActHelpExecute(Sender: TObject);
begin
  var DlgHelp := TDlgHelp.Create(Self);
  try
    DlgHelp.ShowModal;
  finally
    DlgHelp.Free;
  end;
end;

procedure TFrmMain.FileOpen1Execute(Sender: TObject);
begin
  ShowCollectionWindow;
end;

procedure TFrmMain.ActAboutExecute(Sender: TObject);
begin
  // Show the test dialog instead if Ctrl+Shift are held down.
  if (GetKeyState(VK_CONTROL) < 0) and (GetKeyState(VK_SHIFT) < 0) then begin
    var DlgTest := TDlgTest.Create(Self);
    try
      DlgTest.Config := FConfig;
      DlgTest.ShowModal;
    finally
      DlgTest.Free;
    end;
  end else begin
    var DlgAbout := TDlgAbout.Create(Self);
    try
      DlgAbout.ShowModal;
    finally
      DlgAbout.Free;
    end;
  end;
end;

procedure TFrmMain.FileExit1Execute(Sender: TObject);
begin
  Close;
end;

end.
