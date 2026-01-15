unit UFrmSetList;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Actions, Vcl.ActnList,
  FireDAC.Comp.Client, FireDAC.Stan.Def, FireDAC.Stan.Async, FireDAC.DApt,
  FireDAC.Stan.Param, FireDAC.Stan.Pool, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef, FireDAC.UI.Intf, FireDAC.VCLUI.Wait,
  UConfig, USetList, Vcl.StdCtrls, Vcl.Imaging.pngimage, Vcl.ExtCtrls, Vcl.ComCtrls,
  Generics.Collections, USet, System.ImageList, Vcl.ImgList, Vcl.Menus,
  UConst,
  Vcl.Buttons;

type
  TFrmSetList = class(TForm)
    Panel1: TPanel;
    LblFilter: TLabel;
    CbxFilter: TComboBox;
    LvSets: TListView;
    PopupMenu1: TPopupMenu;
    PopupMenu2: TPopupMenu;
    test1: TMenuItem;
    Edit1: TMenuItem;
    ActDeleteSetList1: TMenuItem;
    sub1: TMenuItem;
    ag11: TMenuItem;
    ag21: TMenuItem;
    ag31: TMenuItem;
    ActionList1: TActionList;
    ActDeleteSet: TAction;
    ActEditSet: TAction;
    ImageList16: TImageList;
    ActViewExternal: TAction;
    Viewexternally1: TMenuItem;
    ActViewPartsList: TAction;
    Viewpartslist1: TMenuItem;
    StatusBar1: TStatusBar;
    ActSearch: TAction;
    ActImport: TAction;
    ActExport: TAction;
    ActViewSet: TAction;
    ActEditOwnedParts: TAction;
    Editownedparts1: TMenuItem;
    ImageList32: TImageList;
    Button2: TButton;
    Button3: TButton;
    Button1: TButton;
    Button4: TButton;
    Button5: TButton;
    ActColumnShowName: TAction;
    ActColumnShowBSID: TAction;
    ActColumnShowSetNum: TAction;
    ActColumnShowQty: TAction;
    ActColumnShowBuilt: TAction;
    ActColumnShowSpares: TAction;
    ActColumnShowNote: TAction;
    ActColMoveLeft: TAction;
    ActColMoveRight: TAction;
    MnuColName: TMenuItem;
    Moveleft1: TMenuItem;
    Moveright1: TMenuItem;
    N1: TMenuItem;
    MnuShowName: TMenuItem;
    MnuShowBSID: TMenuItem;
    MnuShowSetNum: TMenuItem;
    MnuShowQuantity: TMenuItem;
    MnuShowBuilt: TMenuItem;
    MnuShowSpares: TMenuItem;
    MnuShowNote: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure CbxFilterChange(Sender: TObject);
    procedure ActDeleteSetExecute(Sender: TObject);
    procedure ActEditSetExecute(Sender: TObject);
    procedure ActViewSetExecute(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ActViewExternalExecute(Sender: TObject);
    procedure ActViewPartsListExecute(Sender: TObject);
    procedure ActImportExecute(Sender: TObject);
    procedure ActExportExecute(Sender: TObject);
    procedure ActSearchExecute(Sender: TObject);
    procedure LvSetsData(Sender: TObject; Item: TListItem);
    procedure LvSetsMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure LvSetsDragOver(Sender: TObject; Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
    procedure LvSetsDragDrop(Sender: TObject; Source: TObject; X, Y: Integer);
    procedure LvSetsDblClick(Sender: TObject);
    procedure LvSetsChange(Sender: TObject; Item: TListItem; Change: TItemChange);
    procedure LvSetsColumnClick(Sender: TObject; Column: TListColumn);
    procedure LvSetsColumnRightClick(Sender: TObject; Column: TListColumn; Point: TPoint);
    procedure PopupMenu2ItemClick(Sender: TObject);
    procedure ActEditOwnedPartsExecute(Sender: TObject);
    procedure LvSetsMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure LvSetsContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure ActColumnShowNameExecute(Sender: TObject);
    procedure ActColumnShowBSIDExecute(Sender: TObject);
    procedure ActColumnShowSetNumExecute(Sender: TObject);
    procedure ActColumnShowQtyExecute(Sender: TObject);
    procedure ActColumnShowBuiltExecute(Sender: TObject);
    procedure ActColumnShowSparesExecute(Sender: TObject);
    procedure ActColumnShowNoteExecute(Sender: TObject);
    procedure ActColMoveLeftExecute(Sender: TObject);
    procedure ActColMoveRightExecute(Sender: TObject);
  private
    { Private declarations }
    FSetListObject: TSetListObject;
    FSetObjectListList: TSetObjectListList;
    FOwnsSetList: Boolean;
    FConfig: TConfig;
    FBSSetListID: Integer;
    FLvSetsLastClickPos: TPoint;
    FSortColumn: TSetListColumns;
    FSortDesc: Boolean;
    FIgnoreNextContextPopup: Boolean;
    FLastColumnIdxClicked: Integer;
    procedure FSetConfig(Config: TConfig);
    procedure FTryAddColumn(const ColID: TSetListColumns);
    procedure FSetBSSetListObject(SetListObject: TSetListObject; OwnsObject: Boolean);
    procedure FSetBSSetListID(BSSetListID: Integer);
    function FGetSelectedObject: TObject;
    function FGetSelectedSetNum: String;
    procedure FUpdateStatusBar;
    function FGetSetObjByItemIndex(ItemIndex: Integer): TObject;
    function FGetVisibleRowCount: Integer;
    procedure FHandleClick(CellAction: TCellAction; Sender: TObject);
    function FGetDefaultColumnWidth(const ColID: TSetListColumns): Integer;
    function FGetDefaultColumnName(const ColID: TSetListColumns): String;
    function FGetColumnIndexByTag(const ColID: TSetListColumns): Integer;
    procedure FToggleColumnByID(const ColID: TSetListColumns);
    function FGetColumnIndexByCoordinate(const Point: TPoint): Integer;
    procedure FMoveColumn(MoveLeft: Boolean);
    procedure FUpdateUI(Item: TListItem);
  public
    { Public declarations }
    procedure ReloadAndRefresh;
    property SetListObject: TSetListObject read FSetListObject write FSetListObject;
    property BSSetListID: Integer read FBSSetListID write FSetBSSetListID;
    property Config: TConfig read FConfig write FSetConfig;
  end;

implementation

{$R *.dfm}

uses
  Types,
  StrUtils,
  Math,
  TypInfo,
  Data.DB,
  USqLiteConnection,
  UITypes,
  UFrmMain, UDlgAddToSetList, UStrings, UDragData;

procedure TFrmSetList.FormCreate(Sender: TObject);
begin
  inherited;

  FSetObjectListList := TSetObjectListList.Create;
end;

procedure TFrmSetList.FormDestroy(Sender: TObject);
begin
  // Capture current widths from visual columns into the config so widths are preserved.
  for var I := 0 to LvSets.Columns.Count - 1 do
    FConfig.WSetListColumns.Values[IntToStr(LvSets.Columns[I].Tag)] := IntToStr(LvSets.Columns[I].Width);
  FConfig.Save(csSETLISTWINDOWFILTERS);

  if FOwnsSetList then
    FSetListObject.Free;
  FSetObjectListList.Free;

  inherited;
end;

procedure TFrmSetList.FormShow(Sender: TObject);
begin
  inherited;

  LvSets.SmallImages := ImageList16;

  // Enable dragging from this listview so other forms can accept dropped sets
  LvSets.DragMode := dmAutomatic;
  // Accept drops from search grid
  LvSets.OnDragOver := LvSetsDragOver;
  LvSets.OnDragDrop := LvSetsDragDrop;

  CbxFilter.Items.BeginUpdate;
  try
    CbxFilter.Items.Clear;
    CbxFilter.Items.Add(StrSetListFillterShowAll);
    CbxFilter.Items.Add(StrSetListFillterQuantity);
    CbxFilter.Items.Add(StrSetListFillterBuilt);
    CbxFilter.Items.Add(StrSetListFillterNotBuilt);
    CbxFilter.Items.Add(StrSetListFillterSpareParts);
    CbxFilter.Items.Add(StrSetListFillterNoSpareParts);

    //Perform query, get possible custom tags for setlistcollections
    //And custom tags from setlists type:
    //CbxFilter.Items.Add('Custom tag 1');
    //CbxFilter.Items.Add('Custom tag 2');
    //CbxFilter.Items.Add('Custom tag 3');
    CbxFilter.ItemIndex := 0;
  finally
    CbxFilter.Items.EndUpdate;
  end;
  FUpdateUI(nil);
end;

procedure TFrmSetList.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
  inherited;
end;

function TFrmSetList.FGetDefaultColumnWidth(const ColID: TSetListColumns): Integer;
begin
  case ColID of
    slcolNAME:
      Result := 250;
    slcolSETNUM:
      Result := 75;
    slcolQTY:
      Result := 40;
    slcolNOTE:
      Result := 150;
    //slcolBSID:
    //slcolBUILD:
    //slcolSPARES:
    else
      Result := 50;
  end;
end;

function TFrmSetList.FGetDefaultColumnName(const ColID: TSetListColumns): String;
begin
  case ColID of
    slcolNAME:
      Result := 'Name';
    slcolBSID:
      Result := 'BSID';
    slcolSETNUM:
      Result := 'Set_num';
    slcolQTY:
      Result := 'Qty';
    slcolBUILD:
      Result := 'Built';
    slcolSPARES:
      Result := 'Spares';
    slcolNOTE:
      Result := 'Note';
    else
      Result := 'Unknown';
  end;
end;

procedure TFrmSetList.FTryAddColumn(const ColID: TSetListColumns);
begin
  // Note: Caller should handle begin/endupdate
  if FConfig.WSetListColumns.Values[IntToStr(Integer(ColID))] <> '' then begin
    var Col := LvSets.Columns.Add;
    Col.Caption := FGetDefaultColumnName(ColID);
    Col.Width := StrToIntDef(FConfig.WSetListColumns.Values[IntToStr(Integer(ColID))], 50);
    Col.Tag := Integer(ColID);
  end;
end;

procedure TFrmSetList.FSetConfig(Config: TConfig);
begin
  FConfig := Config;

  // load default columns if needed
  if FConfig.WSetListColumns.Count = 0 then begin
    FConfig.WSetListColumns.Values[IntToStr(Integer(slcolNAME))] := IntToStr(FGetDefaultColumnWidth(slcolNAME));
    FConfig.WSetListColumns.Values[IntToStr(Integer(slcolBSID))] := IntToStr(FGetDefaultColumnWidth(slcolBSID));
    FConfig.WSetListColumns.Values[IntToStr(Integer(slcolSETNUM))] := IntToStr(FGetDefaultColumnWidth(slcolSETNUM));
    FConfig.WSetListColumns.Values[IntToStr(Integer(slcolQTY))] := IntToStr(FGetDefaultColumnWidth(slcolQTY));
    FConfig.WSetListColumns.Values[IntToStr(Integer(slcolBUILD))] := IntToStr(FGetDefaultColumnWidth(slcolBUILD));
    FConfig.WSetListColumns.Values[IntToStr(Integer(slcolSPARES))] := IntToStr(FGetDefaultColumnWidth(slcolSPARES));
    FConfig.WSetListColumns.Values[IntToStr(Integer(slcolNOTE))] := IntToStr(FGetDefaultColumnWidth(slcolNOTE));
  end;

  LvSets.Columns.BeginUpdate;
  try
    LvSets.Columns.Clear;
    // Only adds the columns if they are wanted by the user
    for var I:=0 to FConfig.WSetListColumns.Count-1 do begin
      var Name := FConfig.WSetListColumns.Names[I];
      FTryAddColumn(TSetListColumns(StrToIntDef(Name, 0)));
    end;
  finally
    LvSets.Columns.EndUpdate;
  end;

  MnuShowName.Checked := (FGetColumnIndexByTag(slcolNAME) >= 0);
  MnuShowBSID.Checked := (FGetColumnIndexByTag(slcolBSID) >= 0);
  MnuShowSetNum.Checked := (FGetColumnIndexByTag(slcolSETNUM) >= 0);
  MnuShowQuantity.Checked := (FGetColumnIndexByTag(slcolQTY) >= 0);
  MnuShowBuilt.Checked := (FGetColumnIndexByTag(slcolBUILD) >= 0);
  MnuShowSpares.Checked := (FGetColumnIndexByTag(slcolSPARES) >= 0);
  MnuShowNote.Checked := (FGetColumnIndexByTag(slcolNOTE) >= 0);
end;

procedure TFrmSetList.ActDeleteSetExecute(Sender: TObject);
var
  BSSetID, Quantity: Integer;
  SetName, SetNum: String;
begin
  var Obj := FGetSelectedObject;
  if (Obj <> nil) and (Obj.ClassType = TSetObject) then begin
    var SetObject := TSetObject(Obj);
    SetNum := SetObject.SetNum;
    BSSetID := SetObject.BSSetID;
    Quantity := 1;
    SetName := SetObject.SetName;
  end else if Obj.ClassType = TSetObjectList then begin
    var SetObjectList := TSetObjectList(Obj);
    BSSetID := 0;
    var Note := '';
    if SetObjectList.Quantity > 1 then
      //Item.ImageIndex := IfThen(SetObjectList.Expanded, 11, 10)
    else begin // Quantity = 1
      BSSetID := SetObjectList[0].BSSetID;
      Note := SetObjectList[0].Note;
      SetName := SetObjectList[0].SetName;
      SetNum := SetObjectList[0].SetNum;
    end;

    Quantity := SetObjectList.Quantity;
  end else begin
    Quantity := 0;  // Should not happen
    BSSetID := 0;   //
  end;

  if Quantity = 1 then begin
    if MessageDlg(Format(StrMsgSureRemoveFromList, [SetName, SetNum]), mtConfirmation, mbYesNo, 0) <> mrYes then
      Exit;

    var SqlConnection := FrmMain.AcquireConnection;
    var FDQuery := TFDQuery.Create(nil);
    try
      FDQuery.Connection := SqlConnection;

      FDQuery.SQL.Text := 'DELETE FROM BSSets WHERE ID=:ID';

      var Params := FDQuery.Params;
      //todo: temporarily disabled.
      Params.ParamByName('ID').asInteger := BSSetID;
      FDQuery.ExecSQL;
    finally
      FDQuery.Free;
      FrmMain.ReleaseConnection(SqlConnection);
    end;

    ReloadAndRefresh;
    TFrmMain.UpdateCollectionsByID(FBSSetListID);
  end else begin
    // Ask user if they are sure they want to delete all the sets in one go.
    //ReloadAndRefresh;
    //TFrmMain.UpdateCollectionsByID(FBSSetListID);
//    if (SetObject <> nil) and (SetObject.SetNum <> '') and
//       (MessageDlg(Format(StrMsgSureRemoveFromList, [SetObject.SetName, SetObject.SetNum]), mtConfirmation, mbYesNo, 0) = mrYes) then begin
//        FDQuery.SQL.Text := 'DELETE FROM BSSets WHERE SET_NUM=:SETNUM';
  end;

//  delete * from BSDBPartsInventory where BSSetID = :BSSetID;
// Params.ParamByName('ID').asInteger := := SetObject.BSSetID

//todo:
//check if there's a details or parts dialog open that needs to be closed or cleared

  //TFrmMain.UpdateSetsByCollectionID(BSSetListID: Integer);
end;

procedure TFrmSetList.ActEditOwnedPartsExecute(Sender: TObject);
var
  BSSetID: Integer;
  SetNum: String;
begin
  var Obj := FGetSelectedObject;
  if (Obj <> nil) and (Obj.ClassType = TSetObject) then begin
    var SetObject := TSetObject(Obj);
    SetNum := SetObject.SetNum;
    BSSetID := SetObject.BSSetID;
  end else begin
    var SetObjectList := TSetObjectList(Obj);
    if SetObjectList.Count = 1 then begin
      SetNum := SetObjectList[0].SetNum;
      BSSetID := SetObjectList[0].BSSetID;
    end else
      BSSetID := 0;
  end;

  // Cant edit without an ID
  if BSSetID <> 0 then
    TFrmMain.EditPartsWindow(SetNum, BSSetID);
end;

procedure TFrmSetList.ActEditSetExecute(Sender: TObject);
var
  BSSetID: Integer;
  SetNum: String;
begin
  var Obj := FGetSelectedObject;
  if (Obj <> nil) and (Obj.ClassType = TSetObject) then begin
    var SetObject := TSetObject(Obj);
    SetNum := SetObject.SetNum;
    BSSetID := SetObject.BSSetID;
  end else begin
    var SetObjectList := TSetObjectList(Obj);
    if SetObjectList.Count = 1 then begin
      SetNum := SetObjectList[0].SetNum;
      BSSetID := SetObjectList[0].BSSetID;
    end else
      BSSetID := 0;
  end;

  // Cant edit without an ID
  if BSSetID <> 0 then begin
    var DlgAddToSetList := TDlgAddToSetList.Create(Self);
    try
      DlgAddToSetList.BSSetID := BSSetID; // Edit
      DlgAddToSetList.BSSetListID := FBSSetListID;
      DlgAddToSetList.SetNum := SetNum;
      if DlgAddToSetList.ShowModal = mrOK then begin
        // DlgAddToSetList handles OK
      end;
    finally
      DlgAddToSetList.Free;
    end;
  end;
end;

procedure TFrmSetList.ActExportExecute(Sender: TObject);
begin
//
end;

procedure TFrmSetList.ActSearchExecute(Sender: TObject);
begin
//TFrmMain.ActSearch
end;

procedure TFrmSetList.ActImportExecute(Sender: TObject);
begin
//
end;

function TFrmSetList.FGetSelectedSetNum: String;
begin
  var Obj := FGetSelectedObject;
  if (Obj <> nil) and (Obj.ClassType = TSetObject) then begin
    var SetObject := TSetObject(Obj);
    Result := SetObject.SetNum;
  end else begin
    var SetObjectList := TSetObjectList(Obj);
    Result := SetObjectList[0].SetNum;
  end;
end;

procedure TFrmSetList.ActViewSetExecute(Sender: TObject);
begin
  var SetNum := FGetSelectedSetNum;
  if SetNum <> '' then
    TFrmMain.ShowSetWindow(SetNum);
end;

procedure TFrmSetList.ActViewExternalExecute(Sender: TObject);
begin
  var SetNum := FGetSelectedSetNum;
  if SetNum <> '' then
    TFrmMain.OpenExternal(cTYPESET, SetNum);
end;

procedure TFrmSetList.ActViewPartsListExecute(Sender: TObject);
begin
  var SetNum := FGetSelectedSetNum;
  if SetNum <> '' then
    TFrmMain.ShowPartsWindow(SetNum);
end;

procedure TFrmSetList.CbxFilterChange(Sender: TObject);
begin
  ReloadAndRefresh;
end;

procedure TFrmSetList.ReloadAndRefresh();

  function FIfThen(Input, IfTrue, IfFalse: Boolean): Boolean;
  begin
    if Input then
      Result := IfTrue
    else
      Result := IfFalse;
  end;

begin
  FSetObjectListList.Clear;

  Self.Caption := StrSetList + ' - ' + FSetlistObject.Name;
//todo: remember the list of currently expanded setObjectList items so we can re-expand them after the update.
  var FDQuery := TFDQuery.Create(nil);
  try
    // Set up the query
    var SqlConnection := FrmMain.AcquireConnection;
    try
      FDQuery.Connection := SqlConnection;
      FDQuery.SQL.Text := 'SELECT	ms.ID, s.name, s.set_num, s."year", s.num_parts, s.img_url, t.name, ms.Built, ms.HaveSpareParts, ms.Notes' +
                          ' from BSSets ms' +
                          ' left join sets s on s.set_num = ms.set_num' +
                          ' left join themes t on t.id = s.theme_id' +
                          ' where ms.BSSetListID = :BSSetListID';

      if CbxFilter.ItemIndex = Integer(fltQUANTITY) then begin
        FDQuery.SQL.Text := FDQuery.SQL.Text + ' AND s.set_num IN ('+
                                               ' SELECT s2.set_num' +
                                               ' FROM BSSets ms2' +
                                               ' LEFT JOIN sets s2 ON s2.set_num = ms2.set_num' +
                                               ' WHERE ms2.BSSetListID IN (:BSSetListID)' +
                                               ' GROUP BY s2.set_num' +
                                               ' HAVING COUNT(*) > 1);'
      end else if CbxFilter.ItemIndex = Integer(fltBUILT) then begin
        FDQuery.SQL.Text := FDQuery.SQL.Text + ' and built = 1';
      end else if CbxFilter.ItemIndex = Integer(fltNOTBUILT) then begin
        FDQuery.SQL.Text := FDQuery.SQL.Text + ' and built = 0';
      end else if CbxFilter.ItemIndex = Integer(fltSPAREPARTS) then begin
        FDQuery.SQL.Text := FDQuery.SQL.Text + ' and havespareparts = 1';
      end else if CbxFilter.ItemIndex = Integer(fltNOSPAREPARTS) then begin
        FDQuery.SQL.Text := FDQuery.SQL.Text + ' and havespareparts = 0';
      end;
      // Else, no filter.

      case FSortColumn of
        slcolNAME:
          FDQuery.SQL.Text := FDQuery.SQL.Text + ' ORDER BY s.name';
        slcolBSID:
          FDQuery.SQL.Text := FDQuery.SQL.Text + ' ORDER BY ms.id';
        //slcolQTY: //todo
          //FDQuery.SQL.Text := FDQuery.SQL.Text + ' ORDER BY qty';
        slcolBUILD:
          FDQuery.SQL.Text := FDQuery.SQL.Text + ' ORDER BY ms.Built';
        slcolSPARES:
          FDQuery.SQL.Text := FDQuery.SQL.Text + ' ORDER BY ms.HaveSpareParts';
        slcolNOTE:
          FDQuery.SQL.Text := FDQuery.SQL.Text + ' ORDER BY ms.Notes';
        else //slcolSETNUM:
          FDQuery.SQL.Text := FDQuery.SQL.Text + ' ORDER BY s.set_num';
      end;

      if FSortDesc then
        FDQuery.SQL.Text := FDQuery.SQL.Text + ' DESC'
      else
        FDQuery.SQL.Text := FDQuery.SQL.Text + ' ASC';

      var Params := FDQuery.Params;
      Params.ParamByName('BSSetListID').asInteger := FSetListObject.ID;

      // use : TSetObjectListList.LoadFromQuery
      FSetObjectListList.LoadFromQuery(FDQuery);

      LvSets.Items.Count := FSetObjectListList.Count;
(*
      FDQuery.Open;
      if FDQuery.RecordCount > 0 then begin
        //sets fields.
      end else if FSetListObject.ExternalID <> 0 then begin
        // Imported from external
        if FSetListObject.ExternalType = cETREBRICKABLE then begin
          //Import from rebrickable
            // Filled with: {{baseUrl}}/api/v3/users/:user_token/setlists/:list_id/sets/?page_size=20
          //insert into database, call the above code again.
        end;
      end; // Else, it's just an empty list, nothing to do.
*)
    finally
      FrmMain.ReleaseConnection(SqlConnection);
    end;
  finally
    FDQuery.Free;
  end;

  LvSets.Invalidate;

  FUpdateStatusBar;
end;

function TFrmSetList.FGetVisibleRowCount: Integer;
begin
  Result := 0;
  for var I := 0 to FSetObjectListList.Count - 1 do begin
    Inc(Result); // Count parent row
    var Obj := FSetObjectListList[I];
    if Obj.Expanded then
      Inc(Result, Obj.Quantity); // Count children only if expanded
  end;
end;

procedure TFrmSetList.FUpdateStatusBar;
begin
  StatusBar1.Panels.BeginUpdate;
  try
    StatusBar1.Panels[0].Text := 'Total sets: ' + IntToStr(FSetObjectListList.Quantity);
  finally
    StatusBar1.Panels.EndUpdate;
  end;
end;

procedure TFrmSetList.LvSetsMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FLvSetsLastClickPos := Point(X, Y);
end;

procedure TFrmSetList.LvSetsMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbRight then
    FHandleClick(caRightClick, Sender)
  else if Button = mbLeft then
    FHandleClick(caLeftClick, Sender);
end;

procedure TFrmSetList.LvSetsDragOver(Sender: TObject; Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
begin
  // Only accept drops from the search grid (TDrawGrid) if drag data exists
  if Source is TCustomControl then begin
    Accept := (DraggedBSSetIDs.Count > 0) or (DraggedSetNums.Count > 0);
  end else
    Accept := False;
end;

procedure TFrmSetList.LvSetsDragDrop(Sender: TObject; Source: TObject; X, Y: Integer);
var
  I: Integer;
begin
  // Only handle drops from the search grid (via UDragData)
  if not (Source is TCustomControl) then
    Exit;

  if ((DraggedBSSetIDs.Count = 0) and (DraggedSetNums.Count = 0)) then
    Exit;

  var SqlConnection := FrmMain.AcquireConnection;
  var FDQuery := TFDQuery.Create(nil);
  var FDTrans := TFDTransaction.Create(nil);
  try
    FDQuery.Connection := SqlConnection;
    FDTrans.Connection := SqlConnection;
    FDTrans.StartTransaction;
    try
      // Insert any BSSetIDs by resolving to set_num
      for I := 0 to DraggedBSSetIDs.Count - 1 do begin
        FDQuery.SQL.Text := 'SELECT set_num FROM BSSets WHERE ID = :ID';
        FDQuery.Params.Clear;
        FDQuery.Params.CreateParam(ftInteger, 'ID', ptInput).AsInteger := DraggedBSSetIDs[I];
        FDQuery.Open;
        if not FDQuery.Eof then begin
          var SetNum := FDQuery.Fields[0].AsString;
          FDQuery.Close;

          FDQuery.SQL.Text := 'INSERT INTO BSSets (BSSetListID, set_num, Built, HaveSpareParts) VALUES(:BSSetListID, :SetNum, 0, 0)';
          FDQuery.Params.Clear;
          FDQuery.Params.CreateParam(ftInteger, 'BSSetListID', ptInput).AsInteger := FBSSetListID;
          FDQuery.Params.CreateParam(ftString, 'SetNum', ptInput).AsString := SetNum;
          FDQuery.ExecSQL;
        end else
          FDQuery.Close;
      end;

      // Insert any plain SetNums
      for I := 0 to DraggedSetNums.Count - 1 do begin
        FDQuery.SQL.Text := 'INSERT INTO BSSets (BSSetListID, set_num, Built, HaveSpareParts) VALUES(:BSSetListID, :SetNum, 0, 0)';
        FDQuery.Params.Clear;
        FDQuery.Params.CreateParam(ftInteger, 'BSSetListID', ptInput).AsInteger := FBSSetListID;
        FDQuery.Params.CreateParam(ftString, 'SetNum', ptInput).AsString := DraggedSetNums[I];
        FDQuery.ExecSQL;
      end;

      FDTrans.Commit;
    except
      FDTrans.Rollback;
      raise;
    end;
  finally
    FDQuery.Free;
    FDTrans.Free;
    FrmMain.ReleaseConnection(SqlConnection);
  end;

  ClearDragData;

  // Refresh the view
  ReloadAndRefresh;
  TFrmMain.UpdateCollectionsByID(FBSSetListID);
end;

procedure TFrmSetList.FHandleClick(CellAction: TCellAction; Sender: TObject);
var
  ImageRect: TRect;
begin
  //todo, check: did we click the image?
  //Insert or remove the sub objects.

  //handle doubleclick here.

  var Item := LvSets.GetItemAt(FLvSetsLastClickPos.X, FLvSetsLastClickPos.Y);
  if Item = nil then
    Exit;

  var ItemRect := Item.DisplayRect(drBounds);
  ImageRect.Left := ItemRect.Left + 2; // small left margin
  ImageRect.Top := ItemRect.Top + (ItemRect.Height - 16) div 2;
  ImageRect.Right := ImageRect.Left + 16;
  ImageRect.Bottom := ImageRect.Top + 16;

  if PtInRect(ImageRect, FLvSetsLastClickPos) then begin
    // Ignore doubleclick here.
    if CellAction = caDoubleClick then
      Exit;

    // Toggle or set a different image index for the clicked item
    if Item.Data <> nil then begin
      var Obj := TObject(Item.Data);
      if Obj.ClassType = TSetObjectList then begin
        var SetObjectList := TSetObjectList(Obj);
        if SetObjectList.Quantity > 1 then begin
          SetObjectList.Expanded := not SetObjectList.Expanded;

          LvSets.Items.Count := FGetVisibleRowCount;
          LvSets.Invalidate; // force redraw
        end;
      end;
    end;
  end else if CellAction = caDoubleClick then begin
    case FConfig.SetListDoubleClickAction of
      caVIEWEXTERNAL:
        ActViewExternal.Execute;
      caEDITDETAILS:
        ActEditSet.Execute;
      caVIEWPARTS:
        ActViewPartsList.Execute;
      caEDITPARTS:
        ActEditOwnedParts.Execute;
      else // caVIEW
        ActViewSet.Execute;
    end;
  end;
end;

procedure TFrmSetList.FUpdateUI(Item: TListItem);
begin
  //Disable actions that cant be executed based on selection.
  var BSSetID := 0;
  var SetNum := '';

  if Item <> nil then begin
    var Obj := TObject(Item.Data);
    if Obj.ClassType = TSetObjectList then begin
      var SetObjectList := TSetObjectList(Obj);
      if SetObjectList.Count = 1 then
        BSSetID := SetObjectList[0].BSSetID;
      SetNum := SetObjectList.SetNum;
    end else begin
      var SetObject := TSetObject(Obj);
      BSSetID := SetObject.BSSetID;
      SetNum := SetObject.SetNum;
    end;
  end;

  ActDeleteSet.Enabled := BSSetID <> 0;  // todo : delete multiple implemented later
  ActEditSet.Enabled := BSSetID <> 0;
  ActViewExternal.Enabled := SetNum <> '';
  ActViewPartsList.Enabled := SetNum <> '';
  ActEditOwnedParts.Enabled := BSSetID <> 0;
  ActSearch.Enabled := SetNum <> '';
  ActImport.Enabled := True;
  ActExport.Enabled := True;
  ActViewSet.Enabled := SetNum <> '';
  Sub1.Enabled := False; // Not available until implemented

  // Disable ability to disable columns if only 1 column is left.
  var ColCount := LvSets.Columns.Count;
  ActColumnShowName.Enabled := (ColCount > 1) or (FGetColumnIndexByTag(slcolNAME) < 0);
  ActColumnShowBSID.Enabled := (ColCount > 1) or (FGetColumnIndexByTag(slcolBSID) < 0);
  ActColumnShowSetNum.Enabled := (ColCount > 1) or (FGetColumnIndexByTag(slcolSETNUM) < 0);
  ActColumnShowQty.Enabled := (ColCount > 1) or (FGetColumnIndexByTag(slcolQTY) < 0);
  ActColumnShowBuilt.Enabled := (ColCount > 1) or (FGetColumnIndexByTag(slcolBUILD) < 0);
  ActColumnShowSpares.Enabled := (ColCount > 1) or (FGetColumnIndexByTag(slcolSPARES) < 0);
  ActColumnShowNote.Enabled := (ColCount > 1) or (FGetColumnIndexByTag(slcolNOTE) < 0);

  // Restrict the ability to move columns left/right
  ActColMoveLeft.Enabled := (ColCount > 1) and (FLastColumnIdxClicked > 0);
  ActColMoveRight.Enabled := (ColCount > 1) and (FLastColumnIdxClicked < LvSets.Columns.Count-1);
end;

procedure TFrmSetList.LvSetsChange(Sender: TObject; Item: TListItem; Change: TItemChange);
begin
  FUpdateUI(Item);
end;

procedure TFrmSetList.LvSetsColumnClick(Sender: TObject; Column: TListColumn);
begin
  if FSortColumn = TSetListColumns(Column.Index) then
    FSortDesc := not FSortDesc;
  FSortColumn := TSetListColumns(Column.Index);

  //todo: Update column names back to their default and show (^) / (v) behind the name if it is being sorted.

  ReloadAndRefresh;
end;

procedure TFrmSetList.LvSetsColumnRightClick(Sender: TObject; Column: TListColumn; Point: TPoint);
begin
  FIgnoreNextContextPopup := True;

  var ScreenPt := LvSets.ClientToScreen(Point);
  //todo. store clicked column header, so we can move left/right

  MnuColName.Caption := '';
  var ColIdx := FGetColumnIndexByCoordinate(Point);
  if ColIdx >= 0 then begin
    FLastColumnIdxClicked := ColIdx;
    MnuColName.Caption := LvSets.Columns[ColIdx].Caption;

    FUpdateUI(LvSets.Selected);
    PopupMenu2.Popup(ScreenPt.X, ScreenPt.Y);
  end;
end;

procedure TFrmSetList.PopupMenu2ItemClick(Sender: TObject);
begin
  if Assigned(Sender) and (Sender is TMenuItem) then
    ShowMessage(Format('Clicked: %s', [TMenuItem(Sender).Caption]));
end;

function TFrmSetList.FGetColumnIndexByCoordinate(const Point: TPoint): Integer;
begin
  Result := -1;

  if LvSets.Columns.Count = 0 then
    Exit;

  // Adjust X by horizontal scroll position so client X maps to column content X
  var ScrollPos := GetScrollPos(LvSets.Handle, SB_HORZ);
  var ContentX := Point.X + ScrollPos;

  var Acc := 0;
  for var I := 0 to LvSets.Columns.Count - 1 do begin
    var W := LvSets.Columns[I].Width;
    if (ContentX >= Acc) and (ContentX < Acc + W) then begin
      Result := I;
      Exit;
    end;
    Inc(Acc, W);
  end;

  if ContentX >= Acc then
    Result := LvSets.Columns.Count - 1;
end;

procedure TFrmSetList.LvSetsContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
begin
  if FIgnoreNextContextPopup then begin
    FIgnoreNextContextPopup := False;
    Handled := True;
    Exit;
  end;

  var ScreenPt := LvSets.ClientToScreen(MousePos);
  PopupMenu1.Popup(ScreenPt.X, ScreenPt.Y);

  Handled := True; // prevent default popup
end;

function TFrmSetList.FGetColumnIndexByTag(const ColID: TSetListColumns): Integer;
begin
  Result := -1;

  for var I:=0 to FConfig.WSetListColumns.Count-1 do begin
    if TSetListColumns(StrToIntDef(FConfig.WSetListColumns.KeyNames[I], -1)) = ColID then begin
      Result := I;
      Exit;
    end;
  end;
end;

procedure TFrmSetList.FToggleColumnByID(const ColID: TSetListColumns);
begin
  LvSets.Columns.BeginUpdate;
  try
    var Idx := FGetColumnIndexByTag(ColID);
    if Idx >= 0 then begin
      FConfig.WSetListColumns.Delete(Idx);
      LvSets.Columns.Delete(Idx);
    end else begin
      FConfig.WSetListColumns.Values[IntToStr(Integer(ColID))] := IntToStr(FGetDefaultColumnWidth(ColID));
      FTryAddColumn(ColID);
    end;
    LvSets.Invalidate;
  finally
    LvSets.Columns.EndUpdate;
  end;

  FUpdateUI(LvSets.Selected);
end;

procedure TFrmSetList.FMoveColumn(MoveLeft: Boolean);
var
  MaxIdx, NewIndex: Integer;
begin
  // Capture current widths from visual columns into the config so widths are preserved.
  for var I := 0 to LvSets.Columns.Count - 1 do
    FConfig.WSetListColumns.Values[IntToStr(LvSets.Columns[I].Tag)] := IntToStr(LvSets.Columns[I].Width);

  if MoveLeft then begin
    MaxIdx := FConfig.WSetListColumns.Count;
    NewIndex := FLastColumnIdxClicked - 1;
  end else begin
    MaxIdx := FConfig.WSetListColumns.Count - 1;
    NewIndex := FLastColumnIdxClicked + 1;
  end;

  // Update stored order
  if (FLastColumnIdxClicked >= 0) and (FLastColumnIdxClicked < MaxIdx) then
    FConfig.WSetListColumns.Move(FLastColumnIdxClicked, NewIndex)
  else
    Exit;

  // Rebuild visual columns from the config order
  LvSets.Columns.BeginUpdate;
  try
    LvSets.Columns.Clear;
    for var I := 0 to FConfig.WSetListColumns.Count - 1 do begin
      var Name := FConfig.WSetListColumns.Names[I];
      FTryAddColumn(TSetListColumns(StrToIntDef(Name, 0)));
    end;
  finally
    LvSets.Columns.EndUpdate;
  end;

  LvSets.Invalidate;
  FUpdateUI(LvSets.Selected);
end;

procedure TFrmSetList.ActColMoveLeftExecute(Sender: TObject);
begin
  if (FConfig = nil) or (FLastColumnIdxClicked <= 0) then
    Exit;
  FMoveColumn(True);
end;

procedure TFrmSetList.ActColMoveRightExecute(Sender: TObject);
begin
  if (FConfig = nil) or (FLastColumnIdxClicked < 0) then
    Exit;
  FMoveColumn(False);
end;

procedure TFrmSetList.ActColumnShowBSIDExecute(Sender: TObject);
begin
  FToggleColumnByID(slcolBSID);
  MnuShowBSID.Checked := not MnuShowBSID.Checked;
end;

procedure TFrmSetList.ActColumnShowBuiltExecute(Sender: TObject);
begin
  FToggleColumnByID(slcolBUILD);
  MnuShowBuilt.Checked := not MnuShowBuilt.Checked;
end;

procedure TFrmSetList.ActColumnShowNameExecute(Sender: TObject);
begin
  FToggleColumnByID(slcolNAME);
  MnuShowName.Checked := not MnuShowName.Checked;
end;

procedure TFrmSetList.ActColumnShowNoteExecute(Sender: TObject);
begin
  FToggleColumnByID(slcolNOTE);
  MnuShowNote.Checked := not MnuShowNote.Checked;
end;

procedure TFrmSetList.ActColumnShowQtyExecute(Sender: TObject);
begin
  FToggleColumnByID(slcolQTY);
  MnuShowQuantity.Checked := not MnuShowQuantity.Checked;
end;

procedure TFrmSetList.ActColumnShowSetNumExecute(Sender: TObject);
begin
  FToggleColumnByID(slcolSETNUM);
  MnuShowSetNum.Checked := not MnuShowSetNum.Checked;
end;

procedure TFrmSetList.ActColumnShowSparesExecute(Sender: TObject);
begin
  FToggleColumnByID(slcolSPARES);
  MnuShowSpares.Checked := not MnuShowSpares.Checked;
end;

procedure TFrmSetList.LvSetsDblClick(Sender: TObject);
begin
  FHandleClick(caDoubleClick, Sender);
end;

function TFrmSetList.FGetSetObjByItemIndex(ItemIndex: Integer): TObject;
begin
  // Flattened row traversal
  var CurPos := 0; // Current 'virtual' index in the listview rows

  for var I := 0 to FSetObjectListList.Count - 1 do begin
    var Obj := FSetObjectListList[i];
    if CurPos = ItemIndex then begin
      Result := Obj;
      Exit;
    end;
    Inc(CurPos);

    if Obj.Expanded then begin
      // Loop through children if expanded
      for var ChildIdx := 0 to Obj.Quantity - 1 do begin
        if CurPos = ItemIndex then begin
          // Optionally: return a reference to the child, or the parent and a child index
          Result := Obj[ChildIdx];
          Exit;
        end;
        Inc(CurPos);
      end;
    end;
  end;

  Result := nil; // Fallback, not found
end;

procedure TFrmSetList.LvSetsData(Sender: TObject; Item: TListItem);

  function FGetSetObjectListValueByTag(const Obj: TSetObjectList; Tag: Integer): String;
  begin
    Result := '';

    case Tag of
      Integer(slcolNAME):
        Result := Obj.SetName;
      Integer(slcolBSID):
      begin
        if Obj.Quantity = 1 then begin
          var BSSetID := Obj[0].BSSetID;
          if BSSetID > 0 then
            Result := IntToStr(BSSetID);
        end;
      end;
      Integer(slcolSETNUM):
        Result := Obj.SetNum;
      Integer(slcolQTY):
        Result := IntToStr(Obj.Quantity);
      Integer(slcolBUILD):
        Result := IntToStr(Obj.Built);
      Integer(slcolSPARES):
        Result := IntToStr(Obj.HaveSpareParts);
      Integer(slcolNOTE):
      begin
        if Obj.Quantity = 1 then
          Result := Obj[0].Note;
      end;
      else
        Result := '';
    end;
  end;

  function FGetSetObjectValueByTag(const Obj: TSetObject; Tag: Integer): String;
  begin
    case Tag of
      Integer(slcolNAME):
        Result := Obj.SetName;
      Integer(slcolBSID):
        Result := IntToStr(Obj.BSSetID);
      Integer(slcolSETNUM):
        Result := Obj.SetNum;
      Integer(slcolQTY):
        Result := '1';
      Integer(slcolBUILD):
        Result := IntToStr(Obj.Built);
      Integer(slcolSPARES):
        Result := IntToStr(Obj.HaveSpareParts);
      Integer(slcolNOTE):
        Result := Obj.Note;
      else
        Result := '';
    end;
  end;

begin
  inherited;
  if (FConfig = nil) or (FConfig.WSetListColumns = nil) then
    Exit;

  //todo: Also for sorting

  var Obj := FGetSetObjByItemIndex(Item.Index);
  if Obj <> nil then begin
  //todo, create a base object that houses the variables both bits of code need, so we dont need double code here

    var IsFirst := True;

    for var I:=0 to FConfig.WSetListColumns.Count-1 do begin
      Item.Data := Obj;

      var Name := FConfig.WSetListColumns.Names[I];
      var Value := '';

      if Obj.ClassType = TSetObjectList then begin
        var SetObjectList := TSetObjectList(Obj);
        Value := FGetSetObjectListValueByTag(SetObjectList, StrToIntDef(Name, 0));
        if SetObjectList.Quantity > 1 then
          Item.ImageIndex := IfThen(SetObjectList.Expanded, 11, 10)
        else begin // Quantity = 1
          Item.ImageIndex := 9;
        end;
      end else begin
        var SetObject := TSetObject(Obj);
        Value := '  ' + FGetSetObjectValueByTag(SetObject, StrToIntDef(Name, 0));
        Item.ImageIndex := 9;
      end;

      if IsFirst then begin
        Item.Caption := Value;
        IsFirst := False;
      end else
        Item.SubItems.Add(Value);
    end;

    //var Obj := FSetObjectListList[Item.Index]; // calculate item by open/selected
  //    Item.SubItems.Add(Obj.Note);
    //SetObject.SetYear := FDQuery.FieldByName('year').AsInteger;
    //SetObject.SetThemeName := FDQuery.FieldByName('name_1').AsString;
    //SetObject.SetNumParts := FDQuery.FieldByName('num_parts').AsInteger;
    //SetObject.SetImgUrl := FDQuery.FieldByName('img_url').AsString;
  end;
end;

procedure TFrmSetList.FSetBSSetListObject(SetListObject: TSetListObject; OwnsObject: Boolean);
begin
  if FOwnsSetList then
    FSetListObject.Free;
  FOwnsSetList := OwnsObject;
  FSetListObject := SetListObject;

  ReloadAndRefresh;
end;

function TFrmSetList.FGetSelectedObject: TObject;
begin
  Result := nil;

  for var Item in LvSets.Items do begin
    if Item.Selected then begin
      Result := Item.Data;
      Break;
    end;
  end;
end;

procedure TFrmSetList.FSetBSSetListID(BSSetListID: Integer);
begin
  FBSSetListID := BSSetListID;

  var SetListObject := TSetListObject.Create;
  SetListObject.LoadByID(BSSetListID);

  FSetBSSetListObject(SetListObject, True);
end;

end.
