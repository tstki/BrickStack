unit UDlgSetList;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TDlgSetList = class(TForm)
    LblName: TLabel;
    EditName: TEdit;
    LblDescription: TLabel;
    MemoDescription: TMemo;
    ChkUseInBuildCalc: TCheckBox;
    BtnCancel: TButton;
    BtnOK: TButton;
    procedure BtnCancelClick(Sender: TObject);
    procedure BtnOKClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DlgSetList: TDlgSetList;

implementation

{$R *.dfm}

procedure TDlgSetList.BtnCancelClick(Sender: TObject);
begin
//
end;

procedure TDlgSetList.BtnOKClick(Sender: TObject);
begin
//
end;

end.
