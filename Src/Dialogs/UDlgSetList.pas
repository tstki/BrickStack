unit UDlgSetList;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  USetList;

type
  TDlgSetList = class(TForm)
    LblName: TLabel;
    EditName: TEdit;
    LblDescription: TLabel;
    MemoDescription: TMemo;
    ChkUseInBuildCalc: TCheckBox;
    BtnCancel: TButton;
    BtnOK: TButton;
    Label1: TLabel;
    EditExternalID: TEdit;
    Label2: TLabel;
    EditExternalType: TEdit;
    Label3: TLabel;
    EditSortIndex: TEdit;
    Image1: TImage;
    Label4: TLabel;
    LblID: TLabel;
    EditID: TEdit;
    procedure BtnOKClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure OnChange(Sender: TObject);
  private
    { Private declarations }
    FSetList: TSetList;
    procedure FUpdateUI;
  public
    { Public declarations }
    property SetList: TSetList read FSetList write FSetList;
  end;

implementation

{$R *.dfm}

procedure TDlgSetList.BtnOKClick(Sender: TObject);
begin
  FSetList.Name := EditName.Text;
  FSetList.Description := MemoDescription.Text;
  FSetList.UseInCollection := ChkUseInBuildCalc.Checked;
  FSetList.SortIndex := StrToIntDef(EditSortIndex.Text, 0);
  FSetList.Dirty := True;
end;

procedure TDlgSetList.OnChange(Sender: TObject);
begin
  FUpdateUI;
end;

procedure TDlgSetList.FUpdateUI;
begin
  BtnOk.Enabled := (StrToIntDef(EditSortIndex.Text, -999) <> -999) and (EditName.Text <> '');
end;

procedure TDlgSetList.FormShow(Sender: TObject);

  function FIntToStrNoZero(Value: Integer): String;
  begin
    if Value = 0 then
      Result := ''
    else
      Result := IntToStr(Value);
  end;

begin
  EditName.SetFocus;

  EditID.Text := FIntToStrNoZero(FSetList.ID);
  EditName.Text := FSetList.Name;
  EditExternalID.Text := FIntToStrNoZero(FSetList.ExternalID);
  EditExternalType.Text := '';
  MemoDescription.Text := FSetList.Description;
  ChkUseInBuildCalc.Checked := FSetList.UseInCollection;
  EditSortIndex.Text := IntToStr(FSetList.SortIndex);
  //Image1: TImage; show the image by index has to match the UFrmSetListCollection, or we should figure out a different way to do this

  FUpdateUI;
end;

end.
