unit UDlgViewExternal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
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
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BtnOKClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    FPartOrSet: Integer;
    FPartOrSetNumber: String;
    FOpenType: Integer;
    FCheckState: Boolean;
  public
    { Public declarations }
    property PartOrSet: Integer read FPartOrSet write FPartOrSet;
    property PartOrSetNumber: String read FPartOrSetNumber write FPartOrSetNumber;
    property OpenType: Integer read FOpenType;
    property CheckState: Boolean read FCheckState;
  end;

implementation

{$R *.dfm}

uses
  UConfig,
  UStrings;

procedure TDlgViewExternal.FormCreate(Sender: TObject);
begin
//
end;

procedure TDlgViewExternal.FormDestroy(Sender: TObject);
begin
//
end;

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
  FOpenType := Integer(CbxOpenType.Items.Objects[CbxOpenType.ItemIndex]);
  FCheckState := ChkOpenWhereNewDefault.Checked;
end;

end.
