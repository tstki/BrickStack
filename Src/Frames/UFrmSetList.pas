unit UFrmSetList;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Actions, Vcl.ActnList,
  FireDAC.Comp.Client, FireDAC.Stan.Def, FireDAC.Stan.Async, FireDAC.DApt,
  FireDAC.Stan.Param, FireDAC.Stan.Pool, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef, FireDAC.UI.Intf, FireDAC.VCLUI.Wait,
  UConfig, USetList, Vcl.StdCtrls, Vcl.Imaging.pngimage, Vcl.ExtCtrls, Vcl.ComCtrls,
  Generics.Collections, USet, System.ImageList, Vcl.ImgList, Vcl.Menus;

type
  TFrmSetList = class(TForm)
    Panel1: TPanel;
    LblFilter: TLabel;
    CbxFilter: TComboBox;
    LvSets: TListView;
    PopupMenu1: TPopupMenu;
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
    ImgFind: TImage;
    ImgEdit: TImage;
    ImgDelete: TImage;
    ImgImport: TImage;
    ImgExport: TImage;
    ActSearch: TAction;
    ActImport: TAction;
    ActExport: TAction;
    ActViewSet: TAction;
    ImgView: TImage;
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
    procedure LvSetsClick(Sender: TObject);
    procedure LvSetsMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure LvSetsDblClick(Sender: TObject);
    procedure LvSetsChange(Sender: TObject; Item: TListItem; Change: TItemChange);
    procedure LvSetsColumnClick(Sender: TObject; Column: TListColumn);
  private
    { Private declarations }
    FSetListObject: TSetListObject;
    FSetObjectListList: TSetObjectListList;
    FOwnsSetList: Boolean;
    FConfig: TConfig;
    FBSSetListID: Integer;
    FLvSetsLastClickPos: TPoint;
    FSortColumn: Integer;
    FSortDesc: Boolean;
    procedure FSetConfig(Config: TConfig);
    procedure FSetBSSetListObject(SetListObject: TSetListObject; OwnsObject: Boolean);
    procedure FSetBSSetListID(BSSetListID: Integer);
    function FGetSelectedObject: TObject;
    function FGetSelectedSetNum: String;
    function FGetSelectedBSSetID: Integer;
    procedure FUpdateStatusBar;
    function FGetSetObjByItemIndex(ItemIndex: Integer): TObject;
    function FGetVisibleRowCount: Integer;
    procedure FHandleClickType(Sender: TObject; DoubleClick: Boolean);
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
  UFrmMain, UDlgAddToSetList, UStrings;

const //CbxFilter
  fltALL = 0;
  fltQUANTITY = 1;
  fltBUILT = 2;
  fltNOTBUILT = 3;
  fltSPAREPARTS = 4;
  fltNOSPAREPARTS = 5;
  //custom tag

  colNAME = 0;
  colBSID = 1;
  colSETNUM = 2;
  colQTY = 3;
  colBUILD = 4;
  colSPARES = 5;
  colNOTE = 6;

procedure TFrmSetList.FormCreate(Sender: TObject);
begin
  inherited;

  FSetObjectListList := TSetObjectListList.Create;
end;

procedure TFrmSetList.FormDestroy(Sender: TObject);
begin
  if FOwnsSetList then
    FSetListObject.Free;
  FSetObjectListList.Free;

  inherited;
end;

procedure TFrmSetList.FormShow(Sender: TObject);
begin
  inherited;

  LvSets.SmallImages := ImageList16;

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

  FUpdateUI(nil);
end;

procedure TFrmSetList.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
  inherited;
end;

procedure TFrmSetList.FSetConfig(Config: TConfig);
begin
  FConfig := Config;
end;

procedure TFrmSetList.ActDeleteSetExecute(Sender: TObject);
begin
  var Obj := FGetSelectedObject;
  if Obj.ClassType = TSetObjectList then begin
    // Ask user if they are sure they want to delete all the sets in one go.
    //ReloadAndRefresh;
    //TFrmMain.UpdateCollectionsByID(FBSSetListID);
//    if (SetObject <> nil) and (SetObject.SetNum <> '') and
//       (MessageDlg(Format(StrMsgSureRemoveFromList, [SetObject.SetName, SetObject.SetNum]), mtConfirmation, mbYesNo, 0) = mrYes) then begin
//        FDQuery.SQL.Text := 'DELETE FROM BSSets WHERE SET_NUM=:SETNUM';
  end else begin
    var SetObject := TSetObject(Obj);

    if (SetObject <> nil) and (SetObject.SetNum <> '') and
       (MessageDlg(Format(StrMsgSureRemoveFromList, [SetObject.SetName, SetObject.SetNum]), mtConfirmation, mbYesNo, 0) = mrYes) then begin

      var SqlConnection := FrmMain.AcquireConnection;
      var FDQuery := TFDQuery.Create(nil);
      try
        FDQuery.Connection := SqlConnection;

        FDQuery.SQL.Text := 'DELETE FROM BSSets WHERE ID=:ID';

        var Params := FDQuery.Params;
        //todo: temporarily disabled.
        Params.ParamByName('ID').asInteger := SetObject.BSSetID;
        FDQuery.ExecSQL;
      finally
        FDQuery.Free;
        FrmMain.ReleaseConnection(SqlConnection);
      end;

      ReloadAndRefresh;
      TFrmMain.UpdateCollectionsByID(FBSSetListID);
    end;
  end;


//todo:
//check if there's a details dialog open that needs to be closed or cleared

  //TFrmMain.UpdateSetsByCollectionID(BSSetListID: Integer);
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

function TFrmSetList.FGetSelectedBSSetID: Integer;
begin
  var Obj := FGetSelectedObject;
  if (Obj <> nil) and (Obj.ClassType = TSetObject) then begin
    var SetObject := TSetObject(Obj);
    Result := SetObject.BSSetID;
  end else begin
    var SetObjectList := TSetObjectList(Obj);
    if SetObjectList.Count = 1 then
      Result := SetObjectList[0].BSSetID
    else
      Result := 0;
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

  Self.Caption := 'Sets in - ' + FSetlistObject.Name;
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

      if CbxFilter.ItemIndex = fltQUANTITY then begin
        FDQuery.SQL.Text := FDQuery.SQL.Text + ' AND s.set_num IN ('+
                                               ' SELECT s2.set_num' +
                                               ' FROM BSSets ms2' +
                                               ' LEFT JOIN sets s2 ON s2.set_num = ms2.set_num' +
                                               ' WHERE ms2.BSSetListID IN (:BSSetListID)' +
                                               ' GROUP BY s2.set_num' +
                                               ' HAVING COUNT(*) > 1);'
      end else if CbxFilter.ItemIndex = fltBUILT then begin
        FDQuery.SQL.Text := FDQuery.SQL.Text + ' and built = 1';
      end else if CbxFilter.ItemIndex = fltNOTBUILT then begin
        FDQuery.SQL.Text := FDQuery.SQL.Text + ' and built = 0';
      end else if CbxFilter.ItemIndex = fltSPAREPARTS then begin
        FDQuery.SQL.Text := FDQuery.SQL.Text + ' and havespareparts = 1';
      end else if CbxFilter.ItemIndex = fltNOSPAREPARTS then begin
        FDQuery.SQL.Text := FDQuery.SQL.Text + ' and havespareparts = 0';
      end;
      // Else, no filter.

      case FSortColumn of
        colNAME:
          FDQuery.SQL.Text := FDQuery.SQL.Text + ' ORDER BY s.name';
        colBSID:
          FDQuery.SQL.Text := FDQuery.SQL.Text + ' ORDER BY ms.id';
        //colQTY: //todo
          //FDQuery.SQL.Text := FDQuery.SQL.Text + ' ORDER BY qty';
        colBUILD:
          FDQuery.SQL.Text := FDQuery.SQL.Text + ' ORDER BY ms.Built';
        colSPARES:
          FDQuery.SQL.Text := FDQuery.SQL.Text + ' ORDER BY ms.HaveSpareParts';
        colNOTE:
          FDQuery.SQL.Text := FDQuery.SQL.Text + ' ORDER BY ms.Notes';
        else //colSETNUM:
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

procedure TFrmSetList.FHandleClickType(Sender: TObject; DoubleClick: Boolean);
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
  end else if DoubleClick then
    ActViewSetExecute(Self);
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
  ActSearch.Enabled := SetNum <> '';
  ActImport.Enabled := True;
  ActExport.Enabled := True;
  ActViewSet.Enabled := SetNum <> '';
  Sub1.Enabled := False; // Not available until implemented
end;

procedure TFrmSetList.LvSetsChange(Sender: TObject; Item: TListItem; Change: TItemChange);
begin
  FUpdateUI(Item);
end;

procedure TFrmSetList.LvSetsClick(Sender: TObject);
begin
  FHandleClickType(Sender, False);
end;

procedure TFrmSetList.LvSetsColumnClick(Sender: TObject; Column: TListColumn);
begin
  if FSortColumn = Column.Index then
    FSortDesc := not FSortDesc;
  FSortColumn := Column.Index;

  ReloadAndRefresh;
end;

procedure TFrmSetList.LvSetsDblClick(Sender: TObject);
begin
  FHandleClickType(Sender, True);
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
begin
  inherited;
  //todo: Also for sorting

  var Obj := FGetSetObjByItemIndex(Item.Index);
//todo, create a base object that houses the variables both bits of code need, so we dont need double code here
  Item.Data := Obj;
  if Obj.ClassType = TSetObjectList then begin
    var SetObjectList := TSetObjectList(Obj);
    var BSSetID := 0;
    var Note := '';
    if SetObjectList.Quantity > 1 then
      Item.ImageIndex := IfThen(SetObjectList.Expanded, 11, 10)
    else begin // Quantity = 1
      Item.ImageIndex := 9;
      BSSetID := SetObjectList[0].BSSetID;
      Note := SetObjectList[0].Note;
    end;
    Item.Caption := SetObjectList.SetName;
    if BSSetID > 0 then
      Item.SubItems.Add(IntToStr(BSSetID))
    else
      Item.SubItems.Add('');
    Item.SubItems.Add(SetObjectList.SetNum);
    Item.SubItems.Add(IntToStr(SetObjectList.Quantity));
    Item.SubItems.Add(IntToStr(SetObjectList.Built));
    Item.SubItems.Add(IntToStr(SetObjectList.HaveSpareParts));
    Item.SubItems.Add(Note);
  end else begin
    var SetObject := TSetObject(Obj);
    Item.ImageIndex := 9;
    Item.Caption := '  ' + SetObject.SetName;
    Item.SubItems.Add(IntToStr(SetObject.BSSetID));
    Item.SubItems.Add(SetObject.SetNum);
    Item.SubItems.Add('1');
    Item.SubItems.Add(IntToStr(SetObject.Built));
    Item.SubItems.Add(IntToStr(SetObject.HaveSpareParts));
    Item.SubItems.Add(SetObject.Note);
  end;

  //var Obj := FSetObjectListList[Item.Index]; // calculate item by open/selected
//    Item.SubItems.Add(Obj.Note);
  //SetObject.SetYear := FDQuery.FieldByName('year').AsInteger;
  //SetObject.SetThemeName := FDQuery.FieldByName('name_1').AsString;
  //SetObject.SetNumParts := FDQuery.FieldByName('num_parts').AsInteger;
  //SetObject.SetImgUrl := FDQuery.FieldByName('img_url').AsString;
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
