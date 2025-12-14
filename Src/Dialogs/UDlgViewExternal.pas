unit UDlgViewExternal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  UConfig,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TDlgViewExternal = class(TForm)
    Label1: TLabel;
    LblSetOrPartCap: TLabel;
    Label3: TLabel;
    BtnOK: TButton;
    BtnCancel: TButton;
    CbxOpenType: TComboBox;
    ChkOpenWhereNewDefault: TCheckBox;
    LblSetOfPartNumber: TLabel;
    procedure BtnOKClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    FPartOrSet: TViewExternalType;
    FPartOrSetNumber: String;
    FOpenType: TExternalOpenType;
    FCheckState: Boolean;
  public
    { Public declarations }
    property PartOrSet: TViewExternalType read FPartOrSet write FPartOrSet;
    property PartOrSetNumber: String read FPartOrSetNumber write FPartOrSetNumber;
    property OpenType: TExternalOpenType read FOpenType;
    property CheckState: Boolean read FCheckState;
  end;

implementation

{$R *.dfm}

uses
  UStrings;

procedure TDlgViewExternal.FormShow(Sender: TObject);
begin
  CbxOpenType.Clear;
  CbxOpenType.AddItem(StrOTRebrickable, TObject(cOTREBRICKABLE));
  CbxOpenType.AddItem(StrOTBrickLink, TObject(cOTBRICKLINK));
  CbxOpenType.AddItem(StrOTBrickOwl, TObject(cOTBRICKOWL));
  if FPartOrSet = cTYPESET then
    CbxOpenType.AddItem(StrOTBrickSet, TObject(cOTBRICKSET))
  else
    CbxOpenType.AddItem(StrOTLDraw, TObject(cOTLDRAW));
  //CbxOpenType.AddItem(StrOTCustom, TObject(cOTCUSTOM)); // Not implemented yet
  CbxOpenType.ItemIndex := 0;

  Self.Caption := Self.Caption + ': ' + FPartOrSetNumber;
  LblSetOfPartNumber.Caption := FPartOrSetNumber;
end;

procedure TDlgViewExternal.BtnOKClick(Sender: TObject);
begin
  FOpenType := TExternalOpenType(CbxOpenType.Items.Objects[CbxOpenType.ItemIndex]);
  FCheckState := ChkOpenWhereNewDefault.Checked;
end;

end.
