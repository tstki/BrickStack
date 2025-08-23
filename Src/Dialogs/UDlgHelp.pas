unit UDlgHelp;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls;

type
  TDlgHelp = class(TForm)
    PCHelp: TPageControl;
    TsBasics: TTabSheet;
    TreeView1: TTreeView;
    BtnOK: TButton;
    TsCollections: TTabSheet;
    TsSearch: TTabSheet;
    Label1: TLabel;
    Memo1: TMemo;
    TsHelp: TTabSheet;
    Memo2: TMemo;
    Memo3: TMemo;
    Memo4: TMemo;
    procedure TreeView1Change(Sender: TObject; Node: TTreeNode);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DlgHelp: TDlgHelp;

implementation

{$R *.dfm}

procedure TDlgHelp.FormShow(Sender: TObject);

  procedure FPopulateTreeView();
  var
    RootNode, ChildNode: TTreeNode;
  begin
    // Clear existing nodes
    TreeView1.Items.Clear;

    // Add root node
    RootNode := TreeView1.Items.Add(nil, 'Help');
    RootNode.Data := Pointer(TsHelp);

    // Add child nodes
    ChildNode := TreeView1.Items.AddChild(RootNode, 'The basics');
    ChildNode.Data := Pointer(TsBasics);

    ChildNode := TreeView1.Items.AddChild(RootNode, 'The Collection');
    ChildNode.Data := Pointer(TsCollections);

    ChildNode := TreeView1.Items.AddChild(RootNode, 'Search');
    ChildNode.Data := Pointer(TsSearch);

    // Optionally, you can continue adding child nodes to ChildNode if needed
    //TreeView.Items.AddChild(ChildNode, 'Grandchild 1');
    //TreeView.Items.AddChild(ChildNode, 'Grandchild 2');

    //ChildNode := TreeView.Items.AddChild(RootNode, 'Child 2');
    // Add more child nodes as needed

    // Expand the tree view to show all nodes
    TreeView1.FullExpand;
  end;
begin
  FPopulateTreeView;

  for var I:=0 to PCHelp.PageCount-1 do
    PCHelp.Pages[I].TabVisible := False;
  PCHelp.ActivePage := PCHelp.Pages[0];

//  FUpdateUI;
end;

procedure TDlgHelp.TreeView1Change(Sender: TObject; Node: TTreeNode);
begin
  // Get selected object, update tab
  if Node.Data <> nil then
    PCHelp.ActivePage := Node.Data
end;

end.
