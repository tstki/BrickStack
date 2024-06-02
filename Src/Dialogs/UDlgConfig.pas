unit UDlgConfig;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  IdHttp, UConfig, System.Actions, Vcl.ActnList, Vcl.ExtCtrls;

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
    TsCustomSetTags: TTabSheet;
    Label9: TLabel;
    CbxViewPartDefault: TComboBox;
    CbxViewSetDefault: TComboBox;
    Label10: TLabel;
    Label11: TLabel;
    LblLocalLogsPath: TLabel;
    EditLocalLogsPath: TEdit;
    BtnSelectEditLocalLogsPath: TButton;
    TsBackup: TTabSheet;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    TsWindows: TTabSheet;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label20: TLabel;
    EditDbasePath: TEdit;
    Button1: TButton;
    Label21: TLabel;
    EditImportPath: TEdit;
    Button2: TButton;
    Label22: TLabel;
    EditExportPath: TEdit;
    Button3: TButton;
    LvCollections: TListView;
    Edit4: TEdit;
    Label23: TLabel;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Label24: TLabel;
    Button7: TButton;
    LblCacheFolderSize: TLabel;
    Label26: TLabel;
    EditAuthenticationToken: TEdit;
    BtnLogin: TButton;
    ChkRememberAuthenticationToken: TCheckBox;
    ActionList1: TActionList;
    ActLogin: TAction;
    ActAPIInfo: TAction;
    ActSelectLocalCacheFolder: TAction;
    ActClearLocalCache: TAction;
    ActSelectLogsFolder: TAction;
    ActDBasePath: TAction;
    ActSelectImportFolder: TAction;
    ActSelectExportFolder: TAction;
    ActCreateTag: TAction;
    ActEditTag: TAction;
    ActDeleteTag: TAction;
    TsCustomSetListTags: TTabSheet;
    Label27: TLabel;
    Label28: TLabel;
    Edit1: TEdit;
    Button8: TButton;
    ListView1: TListView;
    Button9: TButton;
    Button10: TButton;
    procedure BtnOKClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure TreeView1Change(Sender: TObject; Node: TTreeNode);
    procedure ActLoginExecute(Sender: TObject);
    procedure ActAPIInfoExecute(Sender: TObject);
    procedure ActSelectLocalCacheFolderExecute(Sender: TObject);
    procedure ActClearLocalCacheExecute(Sender: TObject);
    procedure ActSelectLogsFolderExecute(Sender: TObject);
    procedure ActDBasePathExecute(Sender: TObject);
    procedure ActSelectImportFolderExecute(Sender: TObject);
    procedure ActSelectExportFolderExecute(Sender: TObject);
    procedure ActCreateTagExecute(Sender: TObject);
    procedure ActEditTagExecute(Sender: TObject);
    procedure ActDeleteTagExecute(Sender: TObject);
    procedure EditRebrickableAPIKeyChange(Sender: TObject);
    procedure EditRebrickableBaseUrlChange(Sender: TObject);
    procedure EditLocalImageCachePathChange(Sender: TObject);
  private
    { Private declarations }
    FIdHttp: TIdHttp;
    FConfig: TConfig;
    procedure FSetConfig(Config: TConfig);
    procedure FSelectPathAndUpdateEdit(EditField: TEdit; Pickfolder: Boolean);
    procedure FUpdateUI;
    procedure FUpdateCacheFolderSize;
  public
    { Public declarations }
    property IdHttp: TIdHttp read FIdHttp write FIdHttp;
    property Config: TConfig read FConfig write FSetConfig;
  end;

implementation

{$R *.dfm}

uses
  IOUtils,  // Used for cache dir size
  ShellAPI, // Needed for ShellExecute
  UStrings,
  UDlgLogin;

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

    ChildNode := TreeView1.Items.AddChild(RootNode, 'Custom set list tags');
    ChildNode.Data := Pointer(TsCustomSetListTags);

    ChildNode := TreeView1.Items.AddChild(RootNode, 'Custom set tags');
    ChildNode.Data := Pointer(TsCustomSetTags);

    ChildNode := TreeView1.Items.AddChild(RootNode, 'Backup');
    ChildNode.Data := Pointer(TsBackup);

    ChildNode := TreeView1.Items.AddChild(RootNode, 'Windows');
    ChildNode.Data := Pointer(TsWindows);

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
  FUpdateCacheFolderSize;

  FUpdateUI;
end;

procedure TDlgConfig.FUpdateCacheFolderSize;

  function GetFolderSize(const Folder: String): Int64;
  begin
    Result := 0;
    var FileList := TDirectory.GetFiles(Folder, '*.*', TSearchOption.soAllDirectories);

    for var FileName in FileList do
      Result := Result + TFile.GetSize(FileName);
  end;

begin
  if DirectoryExists(FConfig.LocalImageCachePath) then begin
    var FolderSize := GetFolderSize(FConfig.LocalImageCachePath);
    var FolderSizeMB := FolderSize / (1024 * 1024);  // Convert bytes to MB
    LblCacheFolderSize.Caption := Format('%.2f MB', [FolderSizeMB]);
  end else begin
    LblCacheFolderSize.Caption := '...';
  end;
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

  // Authentication
  EditRebrickableAPIKey.Text := Config.RebrickableAPIKey;
  EditRebrickableBaseUrl.Text := Config.RebrickableBaseUrl;
  EditAuthenticationToken.Text := Config.AuthenticationToken;
  ChkRememberAuthenticationToken.Checked := Config.RememberAuthenticationToken;

  // External
  EditViewRebrickableUrl.Text := Config.ViewRebrickableUrl;
  EditViewBrickLinkUrl.Text := Config.ViewBrickLinkUrl;
  EditViewBrickOwlUrl.Text := Config.ViewBrickOwlUrl;
  EditViewBrickSetUrl.Text := Config.ViewBrickSetUrl;
  EditViewLDrawUrl.Text := Config.ViewLDrawUrl;
  CbxViewSetDefault.ItemIndex := FGetItemIndexByValue(CbxViewSetDefault, Config.DefaultViewSetOpenType);
  CbxViewPartDefault.ItemIndex := FGetItemIndexByValue(CbxViewPartDefault, Config.DefaultViewPartOpenType);

  // Local
  EditLocalImageCachePath.Text := Config.LocalImageCachePath;
  EditLocalLogsPath.Text := Config.LocalLogsPath;
  EditDbasePath.Text := Config.DbasePath;
  EditImportPath.Text := Config.ImportPath;
  EditExportPath.Text := Config.ExportPath;

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
  // Authentication
  Config.RebrickableAPIKey := EditRebrickableAPIKey.Text;
  Config.RebrickableBaseUrl := EditRebrickableBaseUrl.Text;
  Config.AuthenticationToken := EditAuthenticationToken.Text;
  Config.RememberAuthenticationToken := ChkRememberAuthenticationToken.Checked;

  // External
  Config.ViewRebrickableUrl := EditViewRebrickableUrl.Text;
  Config.ViewBrickLinkUrl := EditViewBrickLinkUrl.Text;
  Config.ViewBrickOwlUrl := EditViewBrickOwlUrl.Text;
  Config.ViewBrickSetUrl := EditViewBrickSetUrl.Text;
  Config.ViewLDrawUrl := EditViewLDrawUrl.Text;
  Config.DefaultViewSetOpenType := Integer(CbxViewSetDefault.Items.Objects[CbxViewSetDefault.ItemIndex]);
  Config.DefaultViewPartOpenType := Integer(CbxViewPartDefault.Items.Objects[CbxViewPartDefault.ItemIndex]);

  // Local
  Config.LocalImageCachePath := EditLocalImageCachePath.Text;
  Config.LocalLogsPath := EditLocalLogsPath.Text;
  Config.DbasePath := EditDbasePath.Text;
  Config.ImportPath := EditImportPath.Text;
  Config.ExportPath := EditExportPath.Text;

  ModalResult := mrOK;
end;

procedure TDlgConfig.FUpdateUI;
begin
  //BtnOK.Enabled :=
  //Check to make sure all folders are subfolders of the application's base path, if not, show a warning.

  ActLogin.Enabled := (EditRebrickableAPIKey.Text <> '') and (EditRebrickableBaseUrl.TExt <> '');
end;

procedure TDlgConfig.EditLocalImageCachePathChange(Sender: TObject);
begin
//
end;

procedure TDlgConfig.EditRebrickableAPIKeyChange(Sender: TObject);
begin
  FUpdateUI;
end;

procedure TDlgConfig.EditRebrickableBaseUrlChange(Sender: TObject);
begin
  FUpdateUI;
end;

procedure TDlgConfig.FSelectPathAndUpdateEdit(EditField: TEdit; Pickfolder: Boolean);
begin
  var FileOpenDialog := TFileOpenDialog.Create(nil);
  try
    if Pickfolder then
      FileOpenDialog.Options := [fdoPickFolders]
    else
      FileOpenDialog.Options := [];
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

procedure TDlgConfig.ActAPIInfoExecute(Sender: TObject);
begin
  ShellExecute(0, 'open', PChar(StrRebrickableAPIInfo), nil, nil, SW_SHOWNORMAL);
end;

procedure TDlgConfig.ActClearLocalCacheExecute(Sender: TObject);
begin
  //DANGER
  //if ShowMessage('This will delete all local imagae files, this can not be undone. Are you sure?') then
  //if DirectoryExists(FConfig.LocalImageCachePath) then begin
    // make SURE it's only files in a folder below brickstat - we dont want the user accidentally selecting c:\ or such.
    //find "cache" folder
    //find "media" folder under there
    //find "parts" and "sets" folder under there.
    //delete all .jpg files in subdirs
  //end;
end;

procedure TDlgConfig.ActCreateTagExecute(Sender: TObject);
begin
//
end;

procedure TDlgConfig.ActDeleteTagExecute(Sender: TObject);
begin
//
end;

procedure TDlgConfig.ActEditTagExecute(Sender: TObject);
begin
//
end;

procedure TDlgConfig.ActLoginExecute(Sender: TObject);
begin
  var DlgLogin := TDlgLogin.Create(Self);
  try
    DlgLogin.IdHttp := FIdHttp;
    DlgLogin.RebrickableAPIKey := EditRebrickableAPIKey.Text;
    DlgLogin.RebrickableBaseUrl := EditRebrickableBaseUrl.Text;
    if DlgLogin.ShowModal = mrOk then begin
      EditAuthenticationToken.Text := DlgLogin.AuthenticationToken;
      ChkRememberAuthenticationToken.Checked := DlgLogin.RememberAuthenticationToken;
    end;
  finally
    DlgLogin.Free;
  end;
end;

procedure TDlgConfig.ActDBasePathExecute(Sender: TObject);
begin
  FSelectPathAndUpdateEdit(EditDbasePath, False); // Pick file - add filter
end;

procedure TDlgConfig.ActSelectExportFolderExecute(Sender: TObject);
begin
  FSelectPathAndUpdateEdit(EditExportPath, True);
end;

procedure TDlgConfig.ActSelectImportFolderExecute(Sender: TObject);
begin
  FSelectPathAndUpdateEdit(EditImportPath, True);
end;

procedure TDlgConfig.ActSelectLocalCacheFolderExecute(Sender: TObject);
begin
  FSelectPathAndUpdateEdit(EditLocalImageCachePath, True);
  FUpdateCacheFolderSize;
end;

procedure TDlgConfig.ActSelectLogsFolderExecute(Sender: TObject);
begin
  FSelectPathAndUpdateEdit(EditLocalLogsPath, True);
end;

end.
