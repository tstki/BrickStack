unit UDlgExport;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TForm1 = class(TForm)
    Label1: TLabel;
    CbxExportOptions: TComboBox;
    BtnOK: TButton;
    BtnCancel: TButton;
    procedure BtnOKClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure CbxExportOptionsChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}

uses
  UStrings;

const
  etREBRICKABLEAPI = 0;
  etREBRICKABLECSV = 1;
  etBRICKLINKXML = 2;

procedure TForm1.FormCreate(Sender: TObject);
begin
  inherited;

  CbxExportOptions.Items.Clear;
  CbxExportOptions.Items.Add(StrNameRebrickableAPI);
  CbxExportOptions.Items.Add(StrNameRebrickableCSV);
  CbxExportOptions.Items.Add(StrNameBrickLinkXML);
  CbxExportOptions.ItemIndex := 0;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
//
end;

procedure TForm1.BtnOKClick(Sender: TObject);
begin
//
end;

procedure TForm1.CbxExportOptionsChange(Sender: TObject);
begin
//disable extra ui items if not available for something.
//show warning labels if needed
end;

end.
