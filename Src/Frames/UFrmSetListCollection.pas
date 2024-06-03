unit UFrmSetListCollection;

interface

uses
  Winapi.Windows, System.Classes,
  Vcl.Graphics, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.Menus, Vcl.ComCtrls,
  Vcl.ToolWin, Vcl.ActnMan, Vcl.ActnCtrls, System.Actions, Vcl.ActnList,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
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
    ActOpenCollection: TAction;
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
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure LvSetListsColumnRightClick(Sender: TObject; Column: TListColumn; Point: TPoint);
    procedure ActEditSetListExecute(Sender: TObject);
    procedure ActImportExecute(Sender: TObject);
    procedure ActExportExecute(Sender: TObject);
    procedure CbxFilterChange(Sender: TObject);
    procedure LvCollectionsDblClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ActOpenCollectionExecute(Sender: TObject);
    procedure ActDeleteSetListExecute(Sender: TObject);
    procedure ActAddSetListExecute(Sender: TObject);
    procedure LvSetListsChange(Sender: TObject; Item: TListItem; Change: TItemChange);
    procedure FormResize(Sender: TObject);
  private
    { Private declarations }
    //FIdHttp: TIdHttp;
    FIdHttp: TIdHttp;
    FConfig: TConfig;
    FSetLists: TSetLists;
    FSqlConnection: TFDConnection;
    procedure RebuildListView;
    function FGetSelectedObject: TSetList;
  public
    { Public declarations }
    property IdHttp: TIdHttp read FIdHttp write FIdHttp;
    property Config: TConfig read FConfig write FConfig;
  end;

const
  // External Type filters
  cETFALL = 0;
  cETFLOCAL = 1;       // So, not actually external
  cETFREBRICKABLE = 2; // Imported from Rebrickable
  //cETF...  // Imported from other places
  //cETFSETS =
  //cETF

implementation

{$R *.dfm}

uses
  StrUtils, SysUtils, Dialogs, UITypes, Math,
  UFrmMain, UStrings,
  UDlgSetList, UDlgImport;

procedure TFrmSetListCollection.RebuildListView;
begin
  LvSetLists.items.BeginUpdate;
  try
    LvSetLists.Items.Clear;
    LvSetLists.SmallImages := ImageList16;

    for var SetList in FSetLists do begin
      // Add items to the list view
      var Item := LvSetLists.Items.Add;
      Item.Caption := SetList.Name;
      Item.SubItems.Add(IfThen(SetList.UseInCollection, 'Yes', 'No'));
      Item.ImageIndex := 0;
      Item.Data := SetList;
    end;
  finally
    LvSetLists.items.EndUpdate;
  end;
end;

procedure TFrmSetListCollection.FormCreate(Sender: TObject);
begin
//
end;

procedure TFrmSetListCollection.FormResize(Sender: TObject);
begin
// If size < X, hide filter, show hamburger menu, hide buttons
end;

procedure TFrmSetListCollection.FormShow(Sender: TObject);
begin
  Width := 450;
  //read size from config as well

  FSetLists := TSetLists.Create;  // Do not load from file, get from database.

  CbxFilter.Items.Clear;
  CbxFilter.Items.Add('All');
  CbxFilter.Items.Add('Created locally');
  CbxFilter.Items.Add('Imported from Rebrickable');
  //CbxFilter.Items.Add('Imported from ...');
  //CbxFilter.Items.Add('Has sets');
  //CbxFilter.Items.Add('Has no sets');

  //Perform query, get possible custom tags for setlistcollections
  //And custom tags from setlists type:
  //CbxFilter.Items.Add('Custom tag 1');
  //CbxFilter.Items.Add('Custom tag 2');
  //CbxFilter.Items.Add('Custom tag 3');
  CbxFilter.ItemIndex := 0;

  FSqlConnection := FrmMain.AcquireConnection; // Kept until end of form
  var FDQuery := TFDQuery.Create(nil);
  try
    // Set up the query
    FDQuery.Connection := FSqlConnection;
    FDQuery.SQL.Text := 'SELECT id, name, description, useincollection, externalid, externaltype, sortindex FROM mysetlists';
    FSetLists.LoadFromSql(FDQuery);
  finally
    FDQuery.Free;
  end;

  if FSetLists.Count > 0 then
    RebuildListView;
end;

procedure TFrmSetListCollection.LvSetListsChange(Sender: TObject; Item: TListItem; Change: TItemChange);
begin
// Check selection. Enable/disable actions as needed.
end;

procedure TFrmSetListCollection.LvSetListsColumnRightClick(Sender: TObject; Column: TListColumn; Point: TPoint);
begin
// Show context menu to show/hide columns
end;

procedure TFrmSetListCollection.LvCollectionsDblClick(Sender: TObject);
begin
//Double click - open
end;

procedure TFrmSetListCollection.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FrmMain.ReleaseConnection(FSqlConnection);
  Action := caFree;
end;

procedure TFrmSetListCollection.ActExportExecute(Sender: TObject);
begin
// choose to export all, or only selection
// option to overwrite data at host
end;

procedure TFrmSetListCollection.ActImportExecute(Sender: TObject);
begin
  var DlgImport := TDlgImport.Create(Self);
  try
    DlgImport.Config := FConfig;
    DlgImport.SetLists := FSetLists;
    DlgImport.IdHttp := FIdHttp;
    if DlgImport.ShowModal = mrOK then begin
      //FSetLists.SaveToFile(True);
      FSetLists.SaveToSQL(FSqlConnection);
      RebuildListView;
    end;
  finally
    DlgImport.Free;
  end;
end;

function TFrmSetListCollection.FGetSelectedObject: TSetList;
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
//apply new filter
end;

procedure TFrmSetListCollection.ActOpenCollectionExecute(Sender: TObject);
begin
  var SetList := FGetSelectedObject;
  if (SetList <> nil) and (SetList.ID <> 0) then
    TFrmMain.ShowSetListWindow(SetList.ID);
end;

procedure TFrmSetListCollection.ActAddSetListExecute(Sender: TObject);
begin
  var SetList := TSetList.Create;
  var DlgEdit := TDlgSetList.Create(Self);
  DlgEdit.SetList := SetList;
  try
    if DlgEdit.ShowModal = mrOK then begin
      FSetLists.Add(SetList);

      var FDQuery := TFDQuery.Create(nil);
      var FDTransaction1 := TFDTransaction.Create(nil);
      FDTransaction1.Connection := FSqlConnection;
      try
        FDTransaction1.StartTransaction;
        try
          // Set up the query
          FDQuery.Connection := FSqlConnection;
          FDQuery.SQL.Text := 'INSERT INTO mysetlists (NAME, DESCRIPTION, USEINCOLLECTION, EXTERNALTYPE, SORTINDEX)' +
                              'VALUES (:NAME, :DESCRIPTION, :USEINCOLLECTION, :EXTERNALTYPE, :SORTINDEX);';

          var Params := FDQuery.Params;
          Params.ParamByName('name').AsString := SetList.Name;
          Params.ParamByName('description').AsString := SetList.Description;
          Params.ParamByName('useincollection').asInteger := IfThen(SetList.UseInCollection, 1, 0);
          Params.ParamByName('externaltype').asInteger := SetList.ExternalType;
          Params.ParamByName('sortindex').asInteger := SetList.SortIndex;
          // id/externalid/externaltype can't be changed by the user.
          // add imageindex later
          FDQuery.ExecSQL;
          Params.Clear;

          // Get the new ID
          FDQuery.SQL.Text := 'SELECT MAX(id) FROM mysetlists';
          FDQuery.Open;

          try
            FDQuery.First;
            if not FDQuery.EOF then
              SetList.ID := FDQuery.Fields[0].AsInteger;
          finally
            FDQuery.Close;
          end;

          FDTransaction1.Commit;
        except
          FDTransaction1.Rollback;
        end;
      finally
        FDQuery.Free;
        FDTransaction1.Free;
      end;

      SetList.Dirty := False;

      RebuildListView;
    end else
      SetList.Free;
  finally
    DlgEdit.Free;
  end;
end;

procedure TFrmSetListCollection.ActEditSetListExecute(Sender: TObject);
begin
  var SetList := FGetSelectedObject;
  if (SetList <> nil) and (SetList.ID <> 0) then begin
    var DlgEdit := TDlgSetList.Create(Self);
    DlgEdit.SetList := SetList;
    try
      if DlgEdit.ShowModal = mrOK then begin
        var FDQuery := TFDQuery.Create(nil);
        try
          // Set up the query
          FDQuery.Connection := FSqlConnection;
          FDQuery.SQL.Text := 'UPDATE MySetLists set name=:name, description=:description, useincollection=:useincollection, sortindex=:sortindex where id=:id';

          var Params := FDQuery.Params;
          Params.ParamByName('name').AsString := SetList.Name;
          Params.ParamByName('description').AsString := SetList.Description;
          Params.ParamByName('useincollection').asInteger := IfThen(SetList.UseInCollection, 1, 0);
          Params.ParamByName('sortindex').asInteger := SetList.SortIndex;
          Params.ParamByName('id').asInteger := SetList.ID;

          // id/externalid/externaltype can't be changed by the user.
          // add imageindex later

          FDQuery.ExecSQL;
        finally
          FDQuery.Free;
        end;

        SetList.Dirty := False;

        RebuildListView;
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
      FDQuery.Connection := FSqlConnection;
      FDQuery.SQL.Text := 'DELETE FROM MySetLists where id=:id';

      var Params := FDQuery.Params;
      Params.ParamByName('id').asInteger := SetList.ID;

      FDQuery.ExecSQL;
      SetList.DoDelete := True;
    finally
      FDQuery.Free;
    end;

    // Also delete it from memory
    for var I:=0 to FSetLists.Count-1 do begin
      var IDxSetList := FSetLists[I];
      if SetList.ID = IdxSetList.ID then begin
        FSetLists.Delete(I);
        break;
      end;
    end;

    RebuildListView;
  end;
end;

end.
