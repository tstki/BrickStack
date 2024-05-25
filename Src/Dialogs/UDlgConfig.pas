unit UDlgConfig;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  UConfig;

type
  TDlgConfig = class(TForm)
    BtnCancel: TButton;
    BtnOK: TButton;
    TreeView1: TTreeView;
    PCConfig: TPageControl;
    TsAuthentication: TTabSheet;
    TsExternal: TTabSheet;
    TsLocal: TTabSheet;
    LblLocalImageCachePath: TLabel;
    EditLocalImageCachePath: TEdit;
    BtnSelectLocalImageCachePath: TButton;
    LblRebrickableAPIKey: TLabel;
    LblRebrickableBaseUrl: TLabel;
    EditRebrickableAPIKey: TEdit;
    EditRebrickableBaseUrl: TEdit;
    BtnRebrickableAPIInfo: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    EditViewRebrickableUrl: TEdit;
    EditViewBrickLinkUrl: TEdit;
    Label5: TLabel;
    EditViewBrickOwlUrl: TEdit;
    Label6: TLabel;
    EditViewBrickSetUrl: TEdit;
    Label7: TLabel;
    Label8: TLabel;
    EditViewLDrawUrl: TEdit;
    TsCustomTags: TTabSheet;
    Label9: TLabel;
    CbxViewPartDefault: TComboBox;
    CbxViewSetDefault: TComboBox;
    Label10: TLabel;
    Label11: TLabel;
    LblLocalLogsPath: TLabel;
    EditLocalLogsPath: TEdit;
    BtnSelectEditLocalLogsPath: TButton;
    procedure BtnOKClick(Sender: TObject);
    procedure BtnRebrickableAPIInfoClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure BtnSelectLocalImageCachePathClick(Sender: TObject);
    procedure TreeView1Change(Sender: TObject; Node: TTreeNode);
    procedure BtnSelectEditLocalLogsPathClick(Sender: TObject);
  private
    { Private declarations }
    FConfig: TConfig;
    procedure FSetConfig(Config: TConfig);
    procedure FSelectPathAndUpdateEdit(EditField: TEdit);
  public
    { Public declarations }
    property Config: TConfig read FConfig write FSetConfig;
  end;

implementation

{$R *.dfm}

uses
  UStrings,
  ShellAPI; // Needed for ShellExecute

procedure TDlgConfig.FormCreate(Sender: TObject);

  procedure FFillPulldown(CbxOpenType: TComboBox; PartOrSet: Integer);
  begin
    CbxOpenType.Clear;
    CbxOpenType.AddItem(StrOTNone, TObject(cOTNONE));
    CbxOpenType.AddItem(StrOTRebrickable, TObject(cOTREBRICKABLE));
    CbxOpenType.AddItem(StrOTBrickLink, TObject(cOTBRICKLINK));
    CbxOpenType.AddItem(StrOTBrickOwl, TObject(cOTBRICKOWL));
    if PartOrSet = cTYPESET then
      CbxOpenType.AddItem(StrOTBrickSet, TObject(cOTBRICKSET))
    else
      CbxOpenType.AddItem(StrOTLDraw, TObject(cOTLDRAW));
    //CbxOpenType.AddItem(StrOTCustom, TObject(cOTCUSTOM)); // Not implemented yet
  end;

begin
  //PCConfig.TabHeight := 0; doesnt work - figure out how to hide the tab headers later.

  FFillPulldown(CbxViewSetDefault, cTYPESET);
  FFillPulldown(CbxViewPartDefault, cTYPEPART);
end;

procedure TDlgConfig.FormShow(Sender: TObject);

  procedure PopulateTreeView();
  var
    RootNode, ChildNode: TTreeNode;
  begin
    // Clear existing nodes
    TreeView1.Items.Clear;

    // Add root node
    RootNode := TreeView1.Items.Add(nil, 'Settings');
    RootNode.Data := Pointer(TsAuthentication);

    // Add child nodes
    ChildNode := TreeView1.Items.AddChild(RootNode, 'Authentication');
    ChildNode.Data := Pointer(TsAuthentication);

    ChildNode := TreeView1.Items.AddChild(RootNode, 'Extrnal');
    ChildNode.Data := Pointer(TsExternal);

    ChildNode := TreeView1.Items.AddChild(RootNode, 'Local');
    ChildNode.Data := Pointer(TsLocal);

    ChildNode := TreeView1.Items.AddChild(RootNode, 'Custom tags');
    ChildNode.Data := Pointer(TsCustomTags);

    // Optionally, you can continue adding child nodes to ChildNode if needed
    //TreeView.Items.AddChild(ChildNode, 'Grandchild 1');
    //TreeView.Items.AddChild(ChildNode, 'Grandchild 2');

    //ChildNode := TreeView.Items.AddChild(RootNode, 'Child 2');
    // Add more child nodes as needed

    // Expand the tree view to show all nodes
    TreeView1.FullExpand;
  end;

begin
  PopulateTreeView();
end;

procedure TDlgConfig.FSetConfig(Config: TConfig);

  function FGetItemIndexByValue(CbxOpenType: TComboBox; Value: Integer): Integer;
  begin
    for var I := 0 to CbxOpenType.Items.Count-1 do begin
      var ObjectValue := Integer(CbxOpenType.Items.Objects[I]);
      if ObjectValue = Value then begin
        Result := I;
        Exit;
      end;
    end;

    Result := 0;
  end;

begin
  FConfig := Config;

  EditRebrickableAPIKey.Text := Config.RebrickableAPIKey;
  EditRebrickableBaseUrl.Text := Config.RebrickableBaseUrl;
  EditLocalImageCachePath.Text := Config.LocalImageCachePath;
  EditLocalLogsPath.Text := Config.LocalLogsPath;

  EditViewRebrickableUrl.Text := Config.ViewRebrickableUrl;
  EditViewBrickLinkUrl.Text := Config.ViewBrickLinkUrl;
  EditViewBrickOwlUrl.Text := Config.ViewBrickOwlUrl;
  EditViewBrickSetUrl.Text := Config.ViewBrickSetUrl;
  EditViewLDrawUrl.Text := Config.ViewLDrawUrl;

  CbxViewSetDefault.ItemIndex := FGetItemIndexByValue(CbxViewSetDefault, Config.DefaultViewSetOpenType);
  CbxViewPartDefault.ItemIndex := FGetItemIndexByValue(CbxViewPartDefault, Config.DefaultViewPartOpenType);

  PCConfig.ActivePage := TsAuthentication;
end;

procedure TDlgConfig.TreeView1Change(Sender: TObject; Node: TTreeNode);
begin
  // Get selected object, update tab
  if Node.Data <> nil then
    PCConfig.ActivePage := Node.Data
end;

procedure TDlgConfig.BtnOKClick(Sender: TObject);
begin
  Config.RebrickableAPIKey := EditRebrickableAPIKey.Text;
  Config.RebrickableBaseUrl := EditRebrickableBaseUrl.Text;
  Config.LocalImageCachePath := EditLocalImageCachePath.Text;
  Config.LocalLogsPath := EditLocalLogsPath.Text;

  Config.ViewRebrickableUrl := EditViewRebrickableUrl.Text;
  Config.ViewBrickLinkUrl := EditViewBrickLinkUrl.Text;
  Config.ViewBrickOwlUrl := EditViewBrickOwlUrl.Text;
  Config.ViewBrickSetUrl := EditViewBrickSetUrl.Text;
  Config.ViewLDrawUrl := EditViewLDrawUrl.Text;

  Config.DefaultViewSetOpenType := Integer(CbxViewSetDefault.Items.Objects[CbxViewSetDefault.ItemIndex]);
  Config.DefaultViewPartOpenType := Integer(CbxViewPartDefault.Items.Objects[CbxViewPartDefault.ItemIndex]);

  ModalResult := mrOK;
end;

procedure TDlgConfig.BtnRebrickableAPIInfoClick(Sender: TObject);
begin
  ShellExecute(0, 'open', PChar(StrRebrickableAPIInfo), nil, nil, SW_SHOWNORMAL);
end;

procedure TDlgConfig.FSelectPathAndUpdateEdit(EditField: TEdit);
begin
  var FileOpenDialog := TFileOpenDialog.Create(nil);
  try
    FileOpenDialog.Options := [fdoPickFolders];
    if EditField.Text <> '' then
      FileOpenDialog.DefaultFolder := EditField.Text
    else
      FileOpenDialog.DefaultFolder := 'C:\';
    if FileOpenDialog.Execute then
      EditField.Text := FileOpenDialog.FileName;
  finally
    FileOpenDialog.Free;
  end;
end;

procedure TDlgConfig.BtnSelectLocalImageCachePathClick(Sender: TObject);
begin
  FSelectPathAndUpdateEdit(EditLocalImageCachePath);
end;

procedure TDlgConfig.BtnSelectEditLocalLogsPathClick(Sender: TObject);
begin
  FSelectPathAndUpdateEdit(EditLocalLogsPath);
end;

end.
