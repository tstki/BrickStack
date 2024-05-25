unit UDlgViewExternal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

const
  //View External types:
  cTYPESET = 0;
  cTYPEPART = 1;
  //cTYPEMINIFIG = 2; //Not used yet

type
  TDlgViewExternal = class(TForm)
    Label1: TLabel;
    LblSetOrPartCap: TLabel;
    Label3: TLabel;
    BtnOK: TButton;
    BtnCancel: TButton;
    CbxOpenWhere: TComboBox;
    ChkOpenWhereNewDefault: TCheckBox;
    LblSetOfPartNumber: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BtnOKClick(Sender: TObject);
  private
    { Private declarations }
    //Itemtype set/part
    //set/part_num
    //FConfig
    FPartOrSet: Integer;
    FPartOrSetNumber: String;
  public
    { Public declarations }
    property PartOrSet: Integer read FPartOrSet write FPartOrSet;
    property PartOrSetNumber: String read FPartOrSetNumber write FPartOrSetNumber;
  end;

implementation

{$R *.dfm}

procedure TDlgViewExternal.FormCreate(Sender: TObject);
begin
  //fill CbxOpenWhere
//
end;

procedure TDlgViewExternal.FormDestroy(Sender: TObject);
begin
//
end;

procedure TDlgViewExternal.BtnOKClick(Sender: TObject);
begin
//
end;

end.
