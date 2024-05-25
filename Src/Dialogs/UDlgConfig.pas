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
    LblRebrickableAPIKey: TLabel;
    EditRebrickableAPIKey: TEdit;
    EditRebrickableBaseUrl: TEdit;
    LblRebrickableBaseUrl: TLabel;
    BtnRebrickableAPIInfo: TButton;
    TreeView1: TTreeView;
    LblLocalImageCachePath: TLabel;
    EditLocalImageCachePath: TEdit;
    BtnSelectLocalImageCachePath: TButton;
    procedure BtnOKClick(Sender: TObject);
    procedure BtnRebrickableAPIInfoClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure BtnSelectLocalImageCachePathClick(Sender: TObject);
  private
    { Private declarations }
    FConfig: TConfig;
    procedure FSetConfig(Config: TConfig);
  public
    { Public declarations }
    property Config: TConfig read FConfig write FSetConfig;
  end;

var
  DlgConfig: TDlgConfig;
implementation

{$R *.dfm}

uses
  UStrings,
  ShellAPI; // Needed for ShellExecute

procedure PopulateTreeView(TreeView: TTreeView);
var
  RootNode, ChildNode: TTreeNode;
begin
  // Clear existing nodes
  TreeView.Items.Clear;

  // Add root node
  RootNode := TreeView.Items.Add(nil, 'Root');

  // Add child nodes
  ChildNode := TreeView.Items.AddChild(RootNode, 'Child 1');
  // Optionally, you can continue adding child nodes to ChildNode if needed
  TreeView.Items.AddChild(ChildNode, 'Grandchild 1');
  TreeView.Items.AddChild(ChildNode, 'Grandchild 2');

  ChildNode := TreeView.Items.AddChild(RootNode, 'Child 2');
  // Add more child nodes as needed

  // Expand the tree view to show all nodes
  TreeView.FullExpand;
end;

procedure TDlgConfig.FormCreate(Sender: TObject);
begin
//
end;

procedure TDlgConfig.FormShow(Sender: TObject);
begin
//
end;

procedure TDlgConfig.FSetConfig(Config: TConfig);
begin
  FConfig := Config;

  EditRebrickableAPIKey.Text := Config.RebrickableAPIKey;
  EditRebrickableBaseUrl.Text := Config.RebrickableBaseUrl;
  EditLocalImageCachePath.Text := Config.LocalImageCachePath;
end;

procedure TDlgConfig.BtnOKClick(Sender: TObject);
begin
  Config.RebrickableAPIKey := EditRebrickableAPIKey.Text;
  Config.RebrickableBaseUrl := EditRebrickableBaseUrl.Text;
  Config.LocalImageCachePath := EditLocalImageCachePath.Text;
  ModalResult := mrOK;
end;

procedure TDlgConfig.BtnRebrickableAPIInfoClick(Sender: TObject);
begin
  ShellExecute(0, 'open', PChar(StrRebrickableAPIInfo), nil, nil, SW_SHOWNORMAL);
end;

procedure TDlgConfig.BtnSelectLocalImageCachePathClick(Sender: TObject);
begin
  var FileOpenDialog := TFileOpenDialog.Create(nil);
  try
    FileOpenDialog.Options := [fdoPickFolders];
    if EditLocalImageCachePath.Text <> '' then
      FileOpenDialog.DefaultFolder := EditLocalImageCachePath.Text
    else
      FileOpenDialog.DefaultFolder := 'C:\';
    if FileOpenDialog.Execute then
      EditLocalImageCachePath.Text := FileOpenDialog.FileName;
  finally
    FileOpenDialog.Free;
  end;
end;

end.
