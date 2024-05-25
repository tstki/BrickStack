unit UDlgHelp;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls;

type
  TDlgHelp = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TreeView1: TTreeView;
    BtnOK: TButton;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DlgHelp: TDlgHelp;

implementation

{$R *.dfm}

end.
