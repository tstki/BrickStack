unit UFrmSetList;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Actions, Vcl.ActnList,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  UConfig, USetList, Vcl.StdCtrls, Vcl.Imaging.pngimage, Vcl.ExtCtrls, Vcl.ComCtrls;

type
  TFrmSetList = class(TForm)
    Panel1: TPanel;
    Image1: TImage;
    LblFilter: TLabel;
    CbxFilter: TComboBox;
    ActionList1: TActionList;
    ScrollBox1: TScrollBox;
    LvCollections: TListView;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FSetList: TSetList;
    FIdHttp: TIdHttp;
    FConfig: TConfig;
    procedure FSetConfig(Config: TConfig);
    procedure FSetSetList(SetList: TSetList);
  public
    { Public declarations }
    property SetList: TSetList read FSetList write FSetList;
    property IdHttp: TIdHttp read FIdHttp write FIdHttp;
    property Config: TConfig read FConfig write FSetConfig;
  end;

implementation

{$R *.dfm}

uses
  SqlExpr;

procedure TFrmSetList.FormCreate(Sender: TObject);
begin
//
end;

procedure TFrmSetList.FormDestroy(Sender: TObject);
begin
//
end;

procedure TFrmSetList.FormShow(Sender: TObject);
begin
//  Self.Caption := Self.Caption + '';
end;

procedure TFrmSetList.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TFrmSetList.FSetConfig(Config: TConfig);
begin
  FConfig := Config;
end;

procedure TFrmSetList.FSetSetList(SetList: TSetList);
begin
  FSetList := SetList;

{  if not FSetList.Loaded then begin
    // Attempt to load from disk
    // If that does not exist, it's new and was never fetched.

    //System.Data.SqlExpr

    if not FSetList.Loaded and (FSetList.RebrickableID <> 0) then begin
      // Load from site
    end;

    // Fill scrollbox
  end;
  }
end;

end.
