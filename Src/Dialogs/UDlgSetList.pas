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
    FSetListObject: TSetListObject;
    procedure FUpdateUI;
  public
    { Public declarations }
    property SetListObject: TSetListObject read FSetListObject write FSetListObject;
  end;

implementation

{$R *.dfm}

procedure TDlgSetList.BtnOKClick(Sender: TObject);
begin
  FSetListObject.Name := EditName.Text;
  FSetListObject.Description := MemoDescription.Text;
  FSetListObject.UseInCollection := ChkUseInBuildCalc.Checked;
  FSetListObject.SortIndex := StrToIntDef(EditSortIndex.Text, 0);
  FSetListObject.Dirty := True;
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

  EditID.Text := FIntToStrNoZero(FSetListObject.ID);
  EditName.Text := FSetListObject.Name;
  EditExternalID.Text := FIntToStrNoZero(FSetListObject.ExternalID);
  EditExternalType.Text := '';
  MemoDescription.Text := FSetListObject.Description;
  ChkUseInBuildCalc.Checked := FSetListObject.UseInCollection;
  EditSortIndex.Text := IntToStr(FSetListObject.SortIndex);
  //Image1: TImage; show the image by index has to match the UFrmSetListCollection, or we should figure out a different way to do this

  FUpdateUI;
end;

end.
