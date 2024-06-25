unit UDlgAddToSetList;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TDlgAddToSetList = class(TForm)
    Label2: TLabel;
    CbxSetList: TComboBox;
    BtnCancel: TButton;
    BtnOK: TButton;
    Label1: TLabel;
    EditAmount: TEdit;
    ChkBuilt: TCheckBox;
    ChkSpareParts: TCheckBox;
    MemoNote: TMemo;
    Label3: TLabel;
    LblMaxNote: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure MemoNoteKeyPress(Sender: TObject; var Key: Char);
    procedure MemoNoteChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}

procedure TDlgAddToSetList.FormCreate(Sender: TObject);
begin
  inherited;
  //
end;

procedure TDlgAddToSetList.FormDestroy(Sender: TObject);
begin
  //
  inherited;
end;

procedure TDlgAddToSetList.FormShow(Sender: TObject);
begin
//query setlistnames
//fill pulldown
end;

procedure TDlgAddToSetList.MemoNoteChange(Sender: TObject);
begin
//update LblMaxNote with max character count.
// database limit is 1024 chars
end;

procedure TDlgAddToSetList.MemoNoteKeyPress(Sender: TObject; var Key: Char);
begin
  // check if input allowed or limited
end;

end.
