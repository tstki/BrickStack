unit UFrmSetListCollection;

interface

uses
  Winapi.Windows, System.Classes,
  Vcl.Graphics, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.Menus, Vcl.ComCtrls,
  Vcl.ToolWin, Vcl.ActnMan, Vcl.ActnCtrls, System.Actions, Vcl.ActnList,
  UConfig, Vcl.PlatformDefaultStyleActnCtrls, System.ImageList, Vcl.ImgList,
  Vcl.Imaging.pngimage, Vcl.ExtCtrls, UConst,
  FireDAC.Comp.Client, FireDAC.Stan.Def, FireDAC.Stan.Async, FireDAC.DApt,
  FireDAC.Stan.Param, FireDAC.Stan.Pool, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef, FireDAC.UI.Intf, FireDAC.VCLUI.Wait,
  USetList, USet, System.Generics.Collections;

type
  TFrmSetListCollection = class(TForm)
    ActionList1: TActionList;
    LvSetLists: TListView;
    ImageList16: TImageList;
    PopupMenu1: TPopupMenu;
    PopupMenu2: TPopupMenu;
    ActAddSetList: TAction;
    ActDeleteSetList: TAction;
    ActEditSetList: TAction;
    ActImport: TAction;
    ActExport: TAction;
    test1: TMenuItem;
    sub1: TMenuItem;
    ag11: TMenuItem;
    ag21: TMenuItem;
    ag31: TMenuItem;
    ActViewCollection: TAction;
    MnuDeleteSetList: TMenuItem;
    Import1: TMenuItem;
    Export1: TMenuItem;
    Panel1: TPanel;
    CbxFilter: TComboBox;
    LblFilter: TLabel;
    StatusBar1: TStatusBar;
    ActViewPartsInCollection: TAction;
    ActViewPartsInCollection1: TMenuItem;
    Button2: TButton;
    ImageList32: TImageList;
    Button1: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    ActMoveSets: TAction;
    Movesetstoothersetlist1: TMenuItem;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure LvSetListsColumnRightClick(Sender: TObject; Column: TListColumn; Point: TPoint);
    procedure ActEditSetListExecute(Sender: TObject);
    procedure ActImportExecute(Sender: TObject);
    procedure ActExportExecute(Sender: TObject);
    procedure CbxFilterChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ActViewCollectionExecute(Sender: TObject);
    procedure ActDeleteSetListExecute(Sender: TObject);
    procedure ActAddSetListExecute(Sender: TObject);
    procedure LvSetListsChange(Sender: TObject; Item: TListItem; Change: TItemChange);
    procedure FormResize(Sender: TObject);
    procedure RebuildBySQL();
    procedure LvSetListsData(Sender: TObject; Item: TListItem);
    procedure LvSetListsColumnClick(Sender: TObject; Column: TListColumn);
    procedure ActMoveSetsExecute(Sender: TObject);
    procedure LvSetListsDragOver(Sender: TObject; Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
    procedure LvSetListsDragDrop(Sender: TObject; Source: TObject; X, Y: Integer);
    procedure LvSetListsAdvancedCustomDrawItem(Sender: TCustomListView; Item: TListItem; State: TCustomDrawState; Stage: TCustomDrawStage; var DefaultDraw: Boolean);
    procedure PopupMenu2ItemClick(Sender: TObject);
    procedure LvSetListsDblClick(Sender: TObject);
  private
    { Private declarations }
    FConfig: TConfig;
    FSetListObjectList: TSetListObjectList;
    FSortColumn: TSetListCollectionColumns;
    FSortDesc: Boolean;
//    FPrevSelectedIndex: Integer;
    FIsDragHighlighting: Boolean;
    FDragHoverIndex: Integer;
    procedure FSetConfig(Config: TConfig);
    function FGetSelectedObject: TSetListObject;
    function FCreateSetListInDbase(SetListObject: TSetListObject; FDQuery: TFDQuery; SqlConnection: TFDConnection): Integer;
    procedure FRebuildStatusBar;
    procedure FUpdateUI;
  public
    { Public declarations }
    property Config: TConfig read FConfig write FSetConfig;
  end;

const
  // Size of ID batches when performing parameterized updates
  CHUNK_SIZE = 50;

  //cETF...  // Imported from other places
  //cETFSETS =
  //cETF

implementation

{$R *.dfm}

uses
  StrUtils, SysUtils, Dialogs, UITypes, Math,
  UBrickLinkXMLIntf,
  UFrmMain, UStrings, USqLiteConnection, Data.DB,
  UDlgSetList, UDlgExport, UDlgImport, UDragData;

procedure TFrmSetListCollection.FRebuildStatusBar;
begin
  var TotalSetCount := 0;

  for var SetListObject in FSetListObjectList do
    TotalSetCount := TotalSetCount + SetListObject.SetCount;

  StatusBar1.Panels.BeginUpdate;
  try
    StatusBar1.Panels[0].Text := Format(StrYouHaveSetsCollections, [TotalSetCount, FSetListObjectList.Count]);
  finally
    StatusBar1.Panels.EndUpdate;
  end;
end;

procedure TFrmSetListCollection.FormResize(Sender: TObject);
begin
  inherited;
  // If size < X, hide filter, show hamburger menu, hide buttons
end;

procedure TFrmSetListCollection.FormShow(Sender: TObject);
begin
  inherited;

  // Research this more later - mdi child anchors are weird.
  Width := 450;

  LvSetLists.SmallImages := ImageList16;

  // Accept drops from other listviews (sets)
  LvSetLists.OnDragOver := LvSetListsDragOver;
  LvSetLists.OnDragDrop := LvSetListsDragDrop;
  // Custom draw to allow non-destructive hover highlighting during drag (draw after default paint)
  LvSetLists.OnAdvancedCustomDrawItem := LvSetListsAdvancedCustomDrawItem;

  // Initialize hover state
  FDragHoverIndex := -1;
  FIsDragHighlighting := False;

  CbxFilter.Items.BeginUpdate;
  try
    CbxFilter.Items.Clear;
    CbxFilter.Items.Add(StrSetListFillterShowAll);
    CbxFilter.Items.Add(StrSetListFillterShowLocal);
    CbxFilter.Items.Add(StrSetListFillterShowRebrickable);
    CbxFilter.Items.Add(StrSetListFillterShowSets);
    CbxFilter.Items.Add(StrSetListFillterShowNoSets);
    //CbxFilter.Items.Add('Imported from ...');
    //Perform query, get possible custom tags for setlistcollections
    //And custom tags from setlists type:
    //CbxFilter.Items.Add('Custom tag 1');
    //CbxFilter.Items.Add('Custom tag 2');
    //CbxFilter.Items.Add('Custom tag 3');
    CbxFilter.ItemIndex := 0;
  finally
    CbxFilter.Items.EndUpdate;
  end;

  FSetListObjectList := TSetListObjectList.Create;  // Do not load from file, get from database.
  RebuildBySQL;

  CbxFilter.DropDownWidth := Round(CbxFilter.DropDownWidth * 1.5);

  FUpdateUI;
end;

procedure TFrmSetListCollection.FSetConfig(Config: TConfig);
begin
  FConfig := Config;
end;

procedure TFrmSetListCollection.RebuildBySQL();
begin
  FSetListObjectList.Clear;

  //todo remember any "open" items
  //suppord drag n drop of sets to this dialog

  var SqlConnection := FrmMain.AcquireConnection;
  var FDQuery := TFDQuery.Create(nil);
  try
    // Set up the query
    FDQuery.Connection := SqlConnection;
    FDQuery.SQL.Text := 'SELECT id, name, description, useincollection, externalid, externaltype, sortindex,'+
                        ' (select count(*) FROM BSSets s WHERE s.BSSetListID = m.ID) AS SetCount' +
                        ' FROM BSSetLists m';

    if CbxFilter.ItemIndex = Integer(cETFLOCAL) then
      FDQuery.SQL.Text := FDQuery.SQL.Text + ' WHERE ExternalID IS NULL'
    else if CbxFilter.ItemIndex = Integer(cETFREBRICKABLE) then
      FDQuery.SQL.Text := FDQuery.SQL.Text + ' WHERE ExternalID IS NOT NULL'
    else if CbxFilter.ItemIndex = Integer(cETFHASSETS) then
      FDQuery.SQL.Text := FDQuery.SQL.Text + ' WHERE SetCount <> 0'
    else if CbxFilter.ItemIndex = Integer(cETFNOSETS) then
      FDQuery.SQL.Text := FDQuery.SQL.Text + ' WHERE SetCount = 0';
    // Else, no filter.

    //order by "last column that was clicked" //todo remember in settings.
    case FSortColumn of
      colNAME:
        FDQuery.SQL.Text := FDQuery.SQL.Text + ' ORDER BY name';
      colSETS:
        FDQuery.SQL.Text := FDQuery.SQL.Text + ' ORDER BY SetCount';
      colUSEINBUILD:
        FDQuery.SQL.Text := FDQuery.SQL.Text + ' ORDER BY useincollection';
      else //colSORTINDEX:
        FDQuery.SQL.Text := FDQuery.SQL.Text + ' ORDER BY SortIndex';
    end;

    if FSortDesc then
      FDQuery.SQL.Text := FDQuery.SQL.Text + ' DESC'
    else
      FDQuery.SQL.Text := FDQuery.SQL.Text + ' ASC';

    FSetListObjectList.LoadFromQuery(FDQuery);

    LvSetLists.Items.Count := FSetListObjectList.Count;
    LvSetLists.Invalidate;
  finally
    FDQuery.Free;
    FrmMain.ReleaseConnection(SqlConnection);
  end;

  FRebuildStatusBar;
end;

procedure TFrmSetListCollection.FUpdateUI;
begin
  var Obj := FGetSelectedObject;

  ActAddSetList.Enabled := True;
  ActDeleteSetList.Enabled := Obj <> nil;
  ActEditSetList.Enabled := Obj <> nil;
  ActImport.Enabled := True;
  ActExport.Enabled := Obj <> nil;
  ActViewCollection.Enabled := Obj <> nil;
end;

procedure TFrmSetListCollection.LvSetListsChange(Sender: TObject; Item: TListItem; Change: TItemChange);
begin
  inherited;

  FUpdateUI;
end;

procedure TFrmSetListCollection.LvSetListsColumnClick(Sender: TObject; Column: TListColumn);
begin
  if FSortColumn = TSetListCollectionColumns(Column.Index) then
    FSortDesc := not FSortDesc;
  FSortColumn := TSetListCollectionColumns(Column.Index);

  //todo: Update column names back to their default and show (^) / (v) behind the name if it is being sorted.

  RebuildBySQL;
end;

procedure TFrmSetListCollection.LvSetListsDragOver(Sender: TObject; Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
var
  TargetItem: TListItem;
begin
  // Only accept drags when mouse is over a real item with data.
  // Support drags from `TListView` (internal move) or from the search grid (TDrawGrid) via `UDragData`.
  TargetItem := LvSetLists.GetItemAt(X, Y);
  if TargetItem = nil then
    Accept := False
  else begin
    if (Source is TListView) then
      Accept := TargetItem.Data <> nil
    else if (Source is TCustomControl) then // e.g. TDrawGrid from search
      Accept := ((DraggedBSSetIDs.Count > 0) or (DraggedSetNums.Count > 0)) and (TargetItem.Data <> nil)
    else
      Accept := False;
  end;

  // Non-destructive visual feedback: set hover index and invalidate to paint
  if TargetItem <> nil then begin
    if FDragHoverIndex <> TargetItem.Index then begin
      FDragHoverIndex := TargetItem.Index;
      LvSetLists.Invalidate;
    end;
    FIsDragHighlighting := True;
  end else if FDragHoverIndex <> -1 then begin
    FDragHoverIndex := -1;
    FIsDragHighlighting := False;
    LvSetLists.Invalidate;
  end;
end;

procedure TFrmSetListCollection.LvSetListsDragDrop(Sender: TObject; Source: TObject; X, Y: Integer);
var
  SrcItem: TListItem;
  IDs: TList<Integer>;
  I: Integer;
begin
  // Two supported sources:
  // 1) Drag from another TListView (moving owned BSSets) - original behavior
  // 2) Drag from the search grid (TDrawGrid) - add set(s) to the target setlist using DraggedSetNums/DraggedBSSetIDs

  var TargetItem := LvSetLists.GetItemAt(X, Y);
  if TargetItem = nil then
    TargetItem := LvSetLists.Selected;
  if TargetItem = nil then
    Exit;

  var TargetSetList := TSetListObject(TargetItem.Data);
  if (TargetSetList = nil) or (TargetSetList.ID = 0) then
    Exit;

  if Source is TListView then begin
    var SourceLV := TListView(Source);
    IDs := TList<Integer>.Create;
    try
      for SrcItem in SourceLV.Items do begin
        if SrcItem.Selected and (SrcItem.Data <> nil) then begin
          var Obj := TObject(SrcItem.Data);
          if Obj is TSetObject then begin
            var SetObj := TSetObject(Obj);
            if SetObj.BSSetID <> 0 then
              IDs.Add(SetObj.BSSetID);
          end else if Obj is TSetObjectList then begin
            var SetObjList := TSetObjectList(Obj);
            for I := 0 to SetObjList.Count - 1 do
              if SetObjList[I].BSSetID <> 0 then
                IDs.Add(SetObjList[I].BSSetID);
          end;
        end;
      end;

      if IDs.Count = 0 then
        Exit;

      var SqlConnection := FrmMain.AcquireConnection;
      var FDQuery := TFDQuery.Create(nil);
      var FDTrans := TFDTransaction.Create(nil);
      try
        FDQuery.Connection := SqlConnection;
        FDTrans.Connection := SqlConnection;
        FDTrans.StartTransaction;
        try
          // Batch the IDs into chunks and update each chunk using parameters
          var TotalIDs := IDs.Count;
          var StartIdx := 0;

          while StartIdx < TotalIDs do begin
            var EndIdx := Min(StartIdx + CHUNK_SIZE - 1, TotalIDs - 1);
            var ParamNames := '';

            // Prepare parameter list and SQL IN clause
            FDQuery.Params.Clear;
            // NewID param
            FDQuery.Params.CreateParam(ftInteger, 'NewID', ptInput).AsInteger := TargetSetList.ID;

            var ParamIndex := 0;
            for I := StartIdx to EndIdx do begin
              var PName := 'ID' + IntToStr(ParamIndex);
              if ParamNames <> '' then
                ParamNames := ParamNames + ',';
              ParamNames := ParamNames + ':' + PName;

              FDQuery.Params.CreateParam(ftInteger, PName, ptInput).AsInteger := IDs[I];
              Inc(ParamIndex);
            end;

            if ParamNames <> '' then begin
              FDQuery.SQL.Text := 'UPDATE BSSets SET BSSetListID = :NewID WHERE ID IN (' + ParamNames + ')';
              FDQuery.ExecSQL;
            end;

            StartIdx := EndIdx + 1;
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

      // Refresh UI
      RebuildBySQL;
      if Assigned(FrmMain) then
        TFrmMain.UpdateCollectionsByID(TargetSetList.ID);
    finally
      IDs.Free;
    end;
  end else if Source is TCustomControl then begin
    // Drag coming from search grid: use DraggedSetNums / DraggedBSSetIDs
    if (DraggedBSSetIDs.Count = 0) and (DraggedSetNums.Count = 0) then
      Exit;

    var SqlConnection2 := FrmMain.AcquireConnection;
    var FDQuery2 := TFDQuery.Create(nil);
    var FDTrans2 := TFDTransaction.Create(nil);
    try
      FDQuery2.Connection := SqlConnection2;
      FDTrans2.Connection := SqlConnection2;
      FDTrans2.StartTransaction;
      try
        // Insert any BSSetIDs (if provided) as moved/duplicate entries using their set_num
        for I := 0 to DraggedBSSetIDs.Count - 1 do begin
          // Get set_num for BSSetID
          FDQuery2.SQL.Text := 'SELECT set_num FROM BSSets WHERE ID = :ID';
          FDQuery2.Params.Clear;
          FDQuery2.Params.CreateParam(ftInteger, 'ID', ptInput).AsInteger := DraggedBSSetIDs[I];
          FDQuery2.Open;
          if not FDQuery2.Eof then begin
            var SetNum := FDQuery2.Fields[0].AsString;
            FDQuery2.Close;

            FDQuery2.SQL.Text := 'INSERT INTO BSSets (BSSetListID, set_num, Built, HaveSpareParts) VALUES(:BSSetListID, :SetNum, 0, 0)';
            FDQuery2.Params.Clear;
            FDQuery2.Params.CreateParam(ftInteger, 'BSSetListID', ptInput).AsInteger := TargetSetList.ID;
            FDQuery2.Params.CreateParam(ftString, 'SetNum', ptInput).AsString := SetNum;
            FDQuery2.ExecSQL;
          end else
            FDQuery2.Close;
        end;

        // Insert any plain SetNums
        for I := 0 to DraggedSetNums.Count - 1 do begin
          FDQuery2.SQL.Text := 'INSERT INTO BSSets (BSSetListID, set_num, Built, HaveSpareParts) VALUES(:BSSetListID, :SetNum, 0, 0)';
          FDQuery2.Params.Clear;
          FDQuery2.Params.CreateParam(ftInteger, 'BSSetListID', ptInput).AsInteger := TargetSetList.ID;
          FDQuery2.Params.CreateParam(ftString, 'SetNum', ptInput).AsString := DraggedSetNums[I];
          FDQuery2.ExecSQL;
        end;

        FDTrans2.Commit;
      except
        FDTrans2.Rollback;
        raise;
      end;
    finally
      FDQuery2.Free;
      FDTrans2.Free;
      FrmMain.ReleaseConnection(SqlConnection2);
    end;

    // Refresh UI
    RebuildBySQL;
    if Assigned(FrmMain) then
      TFrmMain.UpdateCollectionsByID(TargetSetList.ID);

    ClearDragData;
  end;

  // Clear hover highlight
  if FIsDragHighlighting or (FDragHoverIndex <> -1) then begin
    FIsDragHighlighting := False;
    FDragHoverIndex := -1;
    LvSetLists.Invalidate;
  end;
end;

procedure TFrmSetListCollection.LvSetListsColumnRightClick(Sender: TObject; Column: TListColumn; Point: TPoint);
begin
  // Don't call inherited so default popup for the list header isn't shown.

  // Clear any existing runtime items
  while PopupMenu2.Items.Count > 0 do
    PopupMenu2.Items[0].Free;

  // Add 3 dummy items at runtime
  for var I := 1 to 3 do begin
    var MI := TMenuItem.Create(PopupMenu2);
    MI.Caption := Format('Dummy %d', [I]);
    MI.OnClick := PopupMenu2ItemClick;
    PopupMenu2.Items.Add(MI);
  end;

  // Show the popup at the header click screen coordinates
  var ScreenPt := LvSetLists.ClientToScreen(Point);
  PopupMenu2.Popup(ScreenPt.X, ScreenPt.Y);
end;

procedure TFrmSetListCollection.PopupMenu2ItemClick(Sender: TObject);
begin
  if Assigned(Sender) and (Sender is TMenuItem) then
    ShowMessage(Format('Clicked: %s', [TMenuItem(Sender).Caption]));
end;

procedure TFrmSetListCollection.LvSetListsAdvancedCustomDrawItem(Sender: TCustomListView; Item: TListItem; State: TCustomDrawState; Stage: TCustomDrawStage; var DefaultDraw: Boolean);
begin
  // Draw the highlight border after the item has been painted so it is always visible
  if (Stage = cdPostPaint) and FIsDragHighlighting and (FDragHoverIndex = Item.Index) then begin
    var R := Item.DisplayRect(drBounds);
    // inset the rect slightly so the border doesn't touch the control edges
    InflateRect(R, -2, -1);

    with Sender.Canvas do begin
      var OldBrushStyle := Brush.Style;
      var OldBrushColor := Brush.Color;
      var OldPenColor := Pen.Color;
      var OldPenWidth := Pen.Width;

      Brush.Style := bsClear; // don't fill, only draw the border
      Pen.Color := clHighlight;
      Pen.Width := 2;

      Rectangle(R.Left, R.Top, R.Right, R.Bottom);

      // restore canvas state
      Brush.Style := OldBrushStyle;
      Brush.Color := OldBrushColor;
      Pen.Color := OldPenColor;
      Pen.Width := OldPenWidth;
    end;
  end;

  DefaultDraw := True;
end;

procedure TFrmSetListCollection.LvSetListsData(Sender: TObject; Item: TListItem);
begin
  inherited;

  var Obj := FSetListObjectList[Item.Index];
  if Obj <> nil then begin
    Item.Caption := Obj.Name;
    Item.SubItems.Add(IntToStr(Obj.SetCount));
    Item.SubItems.Add(IfThen(Obj.UseInCollection, 'Yes', 'No'));
    Item.SubItems.Add(IntToStr(Obj.SortIndex));
    Item.ImageIndex := 0;
    Item.Data := Obj;
  end;
end;

procedure TFrmSetListCollection.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
  inherited;
end;

procedure TFrmSetListCollection.ActExportExecute(Sender: TObject);
begin
  var SetList := FGetSelectedObject;
  if (SetList <> nil) and (SetList.ID <> 0) then begin
    var DlgExport := TDlgExport.Create(Self);
    try
      DlgExport.ExportType := etSETLIST;
      DlgExport.ExportID := SetList.ID.ToString;
      DlgExport.ExportName := SetList.Name;

      //.config
      //.stuff

      DlgExport.ShowModal;
    finally
      DlgExport.Free;
    end;
  end;
end;

procedure TFrmSetListCollection.ActImportExecute(Sender: TObject);
begin
  var DlgImport := TDlgImport.Create(Self);
  try
    DlgImport.Config := FConfig;
    DlgImport.SetListObjectList := FSetListObjectList;
    if DlgImport.ShowModal = mrOK then begin
      var SqlConnection := FrmMain.AcquireConnection;
      try
        FSetListObjectList.SaveToSQL(SqlConnection);
      finally
        FrmMain.ReleaseConnection(SqlConnection);
      end;
      RebuildBySQL;
    end;
  finally
    DlgImport.Free;
  end;
end;

procedure TFrmSetListCollection.ActMoveSetsExecute(Sender: TObject);
begin
  // todo: show dialog where to move sets to
  //move the sets to the selected
end;

function TFrmSetListCollection.FGetSelectedObject: TSetListObject;
begin
  Result := nil;

  for var Item in LvSetLists.Items do begin
    if Item.Selected then begin
      Result := Item.Data;
      Break;
    end;
  end;
end;

procedure TFrmSetListCollection.CbxFilterChange(Sender: TObject);
begin
  RebuildBySQL;
end;

procedure TFrmSetListCollection.LvSetListsDblClick(Sender: TObject);
begin
  case FConfig.CollectionListDoubleClickAction of
    caEDITDETAILS:
      ActEditSetList.Execute;
    else // caVIEW
      ActViewCollection.Execute;
  end;
end;

procedure TFrmSetListCollection.ActViewCollectionExecute(Sender: TObject);
begin
  var SetList := FGetSelectedObject;
  if (SetList <> nil) and (SetList.ID <> 0) then
    TFrmMain.ShowSetListWindow(SetList.ID);
end;

// Create the setlist in the database and return the ID that was created.
function TFrmSetListCollection.FCreateSetListInDbase(SetListObject: TSetListObject; FDQuery: TFDQuery; SqlConnection: TFDConnection): Integer;
begin
//todo, move this to USetList perhaps?
  Result := 0;

  var FDTransaction := TFDTransaction.Create(nil);
  try
    FDTransaction.Connection := SqlConnection;
    FDTransaction.StartTransaction;
    try
      // Set up the query
      FDQuery.Connection := SqlConnection;
      FDQuery.SQL.Text := 'INSERT INTO BSSetLists (NAME, DESCRIPTION, USEINCOLLECTION, EXTERNALTYPE, SORTINDEX)' +
                          'VALUES (:NAME, :DESCRIPTION, :USEINCOLLECTION, :EXTERNALTYPE, :SORTINDEX);';

      var Params := FDQuery.Params;
      Params.ParamByName('name').AsString := SetListObject.Name;
      Params.ParamByName('description').AsString := SetListObject.Description;
      Params.ParamByName('useincollection').asInteger := IfThen(SetListObject.UseInCollection, 1, 0);
      Params.ParamByName('externaltype').asInteger := SetListObject.ExternalType;
      Params.ParamByName('sortindex').asInteger := SetListObject.SortIndex;
      // id/externalid/externaltype can't be changed by the user.
      // add imageindex later
      // custom tags are a separate action, not done here.

      FDQuery.ExecSQL;
      //Params.Clear;

      // Get the new ID
      FDQuery.SQL.Text := 'SELECT MAX(id) FROM BSSetLists';
      FDQuery.Open;

      try
        FDQuery.First;
        if not FDQuery.EOF then
          Result := FDQuery.Fields[0].AsInteger;
      finally
        FDQuery.Close;
      end;

      FDTransaction.Commit;
    except
      FDTransaction.Rollback;
    end;
  finally
    FDTransaction.Free;
  end;
end;

procedure TFrmSetListCollection.ActAddSetListExecute(Sender: TObject);
begin
  var SetListObject := TSetListObject.Create;
  var DlgEdit := TDlgSetList.Create(Self);
  DlgEdit.SetListObject := SetListObject;
  try
    if DlgEdit.ShowModal = mrOK then begin
      FSetListObjectList.Add(SetListObject);

      var FDQuery := TFDQuery.Create(nil);
      var SqlConnection := FrmMain.AcquireConnection;
      try
        SetListObject.ID := FCreateSetListInDbase(SetListObject, FDQuery, SqlConnection);
      finally
        FDQuery.Free;
        FrmMain.ReleaseConnection(SqlConnection);
      end;

      SetListObject.Dirty := False;

      RebuildBySQL;
    end else
      SetListObject.Free;
  finally
    DlgEdit.Free;
  end;
end;

procedure TFrmSetListCollection.ActEditSetListExecute(Sender: TObject);
begin
  var SetListObject := FGetSelectedObject;
  if (SetListObject <> nil) and (SetListObject.ID <> 0) then begin
    var DlgEdit := TDlgSetList.Create(Self);
    DlgEdit.SetListObject := SetListObject;
    try
      if DlgEdit.ShowModal = mrOK then begin
        var FDQuery := TFDQuery.Create(nil);
        var SqlConnection := FrmMain.AcquireConnection;
        try
          // Set up the query
          FDQuery.Connection := SqlConnection;
          FDQuery.SQL.Text := 'UPDATE BSSetLists set name=:name, description=:description, useincollection=:useincollection, sortindex=:sortindex where id=:id';

          var Params := FDQuery.Params;
          Params.ParamByName('name').AsString := SetListObject.Name;
          Params.ParamByName('description').AsString := SetListObject.Description;
          Params.ParamByName('useincollection').asInteger := IfThen(SetListObject.UseInCollection, 1, 0);
          Params.ParamByName('sortindex').asInteger := SetListObject.SortIndex;
          Params.ParamByName('id').asInteger := SetListObject.ID;

          // id/externalid/externaltype can't be changed by the user.
          // add imageindex later

          FDQuery.ExecSQL;
        finally
          FrmMain.ReleaseConnection(SqlConnection);
          FDQuery.Free;
        end;

        SetListObject.Dirty := False;

        RebuildBySQL;
      end;
    finally
      DlgEdit.Free;
    end;
  end;
end;

procedure TFrmSetListCollection.ActDeleteSetListExecute(Sender: TObject);
begin
  var SetList := FGetSelectedObject;
  if (SetList <> nil) and (SetList.ID <> 0) and (MessageDlg(Format(StrMsgSureDelete, [SetList.Name, SetList.ID]), mtConfirmation, mbYesNo, 0) = mrYes) then begin
    var FDQuery := TFDQuery.Create(nil);
    try
      // Set up the query
      var SqlConnection := FrmMain.AcquireConnection;
      try
        FDQuery.Connection := SqlConnection;
        FDQuery.SQL.Text := 'DELETE FROM BSSetLists where id=:id';

        var Params := FDQuery.Params;
        Params.ParamByName('id').asInteger := SetList.ID;

        FDQuery.ExecSQL;
        SetList.DoDelete := True;
      finally
        FrmMain.ReleaseConnection(SqlConnection);
      end;
    finally
      FDQuery.Free;
    end;

    // Also delete it from memory
    for var I:=0 to FSetListObjectList.Count-1 do begin
      var IDxSetList := FSetListObjectList[I];
      if SetList.ID = IdxSetList.ID then begin
        FSetListObjectList.Delete(I);
        Break;
      end;
    end;

    RebuildBySQL;
  end;
end;

end.
