unit UFrmSetListCollection;

interface

uses
  Winapi.Windows, System.Classes,
  Vcl.Graphics, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.Menus, Vcl.ComCtrls,
  Vcl.ToolWin, Vcl.ActnMan, Vcl.ActnCtrls, System.Actions, Vcl.ActnList,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  UConfig, Vcl.PlatformDefaultStyleActnCtrls, System.ImageList, Vcl.ImgList,
  Vcl.Imaging.pngimage, Vcl.ExtCtrls,
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
    procedure LvSetListsColumnRightClick(Sender: TObject; Column: TListColumn;
      Point: TPoint);
    procedure ActEditSetListExecute(Sender: TObject);
    procedure ActImportExecute(Sender: TObject);
    procedure ActExportExecute(Sender: TObject);
    procedure CbxFilterChange(Sender: TObject);
    procedure LvCollectionsDblClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ActOpenCollectionExecute(Sender: TObject);
    procedure ActDeleteSetListExecute(Sender: TObject);
    procedure ActAddSetListExecute(Sender: TObject);
    procedure LvSetListsChange(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    procedure FormResize(Sender: TObject);
  private
    { Private declarations }
    //FIdHttp: TIdHttp;
    FIdHttp: TIdHttp;
    FConfig: TConfig;
    FSetLists: TSetLists;
    procedure RebuildListView;
    function FGetSelectedObject: TSetList;
  public
    { Public declarations }
    property IdHttp: TIdHttp read FIdHttp write FIdHttp;
    property Config: TConfig read FConfig write FConfig;
  end;

implementation

{$R *.dfm}

uses
  StrUtils, SysUtils, Dialogs, UITypes,
  UStrings,
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
  FSetLists := TSetLists.Create;
  FSetLists.LoadFromFile;

  CbxFilter.Items.Clear;
  CbxFilter.Items.Add('All');
  CbxFilter.Items.Add('Created locally');
  CbxFilter.Items.Add('Imported from Rebrickable');
  //CbxFilter.Items.Add('Imported from ...');
  //CbxFilter.Items.Add('Has sets');
  //CbxFilter.Items.Add('Has no sets');
  //CbxFilter.Items.Add('Custom tag 1');
  //CbxFilter.Items.Add('Custom tag 1');
  //CbxFilter.Items.Add('Custom tag 1');
  CbxFilter.ItemIndex := 0;

  if FSetLists.Count > 0 then
    RebuildListView;
end;

procedure TFrmSetListCollection.FormResize(Sender: TObject);
begin
// If size < X, hide filter, show hamburger menu, hide buttons
end;

procedure TFrmSetListCollection.FormShow(Sender: TObject);
begin
  Width := 450;
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
  Action := caFree;
end;

procedure TFrmSetListCollection.ActAddSetListExecute(Sender: TObject);
begin
//
end;

procedure TFrmSetListCollection.ActDeleteSetListExecute(Sender: TObject);
begin
  var SetList := FGetSelectedObject;
  if (SetList <> nil) and (MessageDlg(Format(StrMsgSureDelete, [SetList.Name]), mtConfirmation, mbYesNo, 0) = mrYes) then begin
    //delete from list
    //save
  end;
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
      RebuildListView;
      FSetLists.SaveToFile(True);
    end;
  finally
    DlgImport.Free;
  end;
end;

function TFrmSetListCollection.FGetSelectedObject: TSetList;
begin
  Result := nil;

  for var Item in LvSetLists.Items do begin
    if Item.Selected then
      Result := Item.Data;
  end;
end;

procedure TFrmSetListCollection.ActOpenCollectionExecute(Sender: TObject);
begin
//Open the set dialog and show sets
//UFrmSetList
  //TFrmMain.ShowXWindow();

{
var
  MsgData: PCustomMessageData;
begin
  New(MsgData);
  MsgData^.MessageText := 'Hello from SubDialog';
  PostMessage(MainForm.Handle, WM_MY_CUSTOM_MESSAGE, WPARAM(MsgData), 0);
}
end;

procedure TFrmSetListCollection.ActEditSetListExecute(Sender: TObject);
begin
  var SetList := FGetSelectedObject;
  var DlgEdit := TDlgSetList.Create(Self);
//  DlgEdit.ViewOnly := False;
//  DlgEdit.SetList := SetList;
  try
    if DlgEdit.ShowModal = mrOK then begin
      // read
      // save

      // update list
    end;
  finally
    DlgEdit.Free;
  end;
end;

procedure TFrmSetListCollection.CbxFilterChange(Sender: TObject);
begin
//
end;

end.
