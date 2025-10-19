unit UFrmSetListCollection;

interface

uses
  Winapi.Windows, System.Classes,
  Vcl.Graphics, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.Menus, Vcl.ComCtrls,
  Vcl.ToolWin, Vcl.ActnMan, Vcl.ActnCtrls, System.Actions, Vcl.ActnList,
  UConfig, Vcl.PlatformDefaultStyleActnCtrls, System.ImageList, Vcl.ImgList,
  Vcl.Imaging.pngimage, Vcl.ExtCtrls,
  FireDAC.Comp.Client, FireDAC.Stan.Def, FireDAC.Stan.Async, FireDAC.DApt,
  FireDAC.Stan.Param, FireDAC.Stan.Pool, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef, FireDAC.UI.Intf, FireDAC.VCLUI.Wait,
  USetList;

type
  TFrmSetListCollection = class(TForm)
    ActionList1: TActionList;
    LvSetLists: TListView;
    ImageList16: TImageList;
    PopupMenu1: TPopupMenu;
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
    Edit1: TMenuItem;
    ActDeleteSetList1: TMenuItem;
    Import1: TMenuItem;
    Export1: TMenuItem;
    Panel1: TPanel;
    ImgOpen: TImage;
    CbxFilter: TComboBox;
    LblFilter: TLabel;
    ImgEdit: TImage;
    ImgAdd: TImage;
    ImgDelete: TImage;
    ImgImport: TImage;
    ImgExport: TImage;
    StatusBar1: TStatusBar;
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
  private
    { Private declarations }
    FConfig: TConfig;
    FSetListObjectList: TSetListObjectList;
    function FGetSelectedObject: TSetListObject;
    function FCreateSetListInDbase(SetListObject: TSetListObject; FDQuery: TFDQuery; SqlConnection: TFDConnection): Integer;
    procedure FRebuildListView;
  public
    { Public declarations }
    property Config: TConfig read FConfig write FConfig;
  end;

const
  // External Type filters
  cETFALL = 0;
  cETFLOCAL = 1;       // So, not actually external
  cETFREBRICKABLE = 2; // Imported from Rebrickable
  cETFHASSETS = 3;
  cETFNOSETS = 4;

  //cETF...  // Imported from other places
  //cETFSETS =
  //cETF

implementation

{$R *.dfm}

uses
  StrUtils, SysUtils, Dialogs, UITypes, Math,
  UBrickLinkXMLIntf,
  UFrmMain, UStrings, USqLiteConnection, Data.DB,
  UDlgSetList, UDlgExport, UDlgImport;

procedure TFrmSetListCollection.FRebuildListView;
begin
  var TotalSetCount := 0;

  LvSetLists.items.BeginUpdate;
  try
    LvSetLists.Items.Clear;
    LvSetLists.SmallImages := ImageList16;

    for var SetListObject in FSetListObjectList do begin

      // Check filter.
      if CbxFilter.ItemIndex = cETFLOCAL then begin
        if SetListObject.ExternalID <> 0 then
          Continue;
      end else if CbxFilter.ItemIndex = cETFREBRICKABLE then begin
        if SetListObject.ExternalID = 0 then
          Continue;
      end else if CbxFilter.ItemIndex = cETFHASSETS then begin
        if SetListObject.SetCount = 0 then
          Continue;
      end else if CbxFilter.ItemIndex = cETFNOSETS then begin
        if SetListObject.SetCount <> 0 then
          Continue;
      end; // Else, no filter.


      // Add items to the list view
      var Item := LvSetLists.Items.Add;
      Item.Caption := SetListObject.Name;
      Item.SubItems.Add(IntToStr(SetListObject.SetCount));
      Item.SubItems.Add(IfThen(SetListObject.UseInCollection, StrYes, StrNo));
      Item.ImageIndex := 0;
      Item.Data := SetListObject;

      TotalSetCount := TotalSetCount + SetListObject.SetCount;
    end;

    StatusBar1.Panels.BeginUpdate;
    try
      StatusBar1.Panels[0].Text := Format(StrYouHaveSetsCollections, [TotalSetCount, FSetListObjectList.Count]);
    finally
      StatusBar1.Panels.EndUpdate;
    end;
  finally
    LvSetLists.items.EndUpdate;
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
end;

procedure TFrmSetListCollection.RebuildBySQL();
begin
  FSetListObjectList.Clear;

  var SqlConnection := FrmMain.AcquireConnection;
  var FDQuery := TFDQuery.Create(nil);
  try
    // Set up the query
    FDQuery.Connection := SqlConnection;
    FDQuery.SQL.Text := 'SELECT id, name, description, useincollection, externalid, externaltype, sortindex,'+
                        ' (select sum(quantity) FROM BSSets s WHERE s.BSSetListID = m.ID) AS SetCount' +
                        ' FROM BSSetLists m';
    FSetListObjectList.LoadFromQuery(FDQuery);
  finally
    FDQuery.Free;
    FrmMain.ReleaseConnection(SqlConnection);
  end;

//  if FSetListObjectList.Count > 0 then
    FRebuildListView;
end;

procedure TFrmSetListCollection.LvSetListsChange(Sender: TObject; Item: TListItem; Change: TItemChange);
begin
  inherited;
// Check selection. Enable/disable actions as needed.
end;

procedure TFrmSetListCollection.LvSetListsColumnRightClick(Sender: TObject; Column: TListColumn; Point: TPoint);
begin
  inherited;
// Show context menu to show/hide columns
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
      FRebuildListView;
    end;
  finally
    DlgImport.Free;
  end;
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
  FRebuildListView;
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

      FRebuildListView;
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

        FRebuildListView;
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

    FRebuildListView;
  end;
end;

end.
