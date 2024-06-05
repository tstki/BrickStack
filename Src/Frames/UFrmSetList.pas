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
    FSetListObject: TSetListObject;
    FOwnsSetList: Boolean;
    FIdHttp: TIdHttp;
    FConfig: TConfig;
    procedure FSetConfig(Config: TConfig);
    procedure FSetSetListObject(SetListObject: TSetListObject; OwnsObject: Boolean);
    procedure FSetSetListID(SetSetListID: Integer);
  public
    { Public declarations }
    property SetListObject: TSetListObject read FSetListObject write FSetListObject;
    property SetListID: Integer write FSetSetListID;
    property IdHttp: TIdHttp read FIdHttp write FIdHttp;
    property Config: TConfig read FConfig write FSetConfig;
  end;

implementation

{$R *.dfm}

uses
  SqlExpr, UFrmMain;

procedure TFrmSetList.FormCreate(Sender: TObject);
begin
//
end;

procedure TFrmSetList.FormDestroy(Sender: TObject);
begin
  if FOwnsSetList then
    FSetListObject.Free;
end;

procedure TFrmSetList.FormShow(Sender: TObject);
begin
//
end;

procedure TFrmSetList.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TFrmSetList.FSetConfig(Config: TConfig);
begin
  FConfig := Config;
end;

procedure TFrmSetList.FSetSetListObject(SetListObject: TSetListObject; OwnsObject: Boolean);
begin
  if FOwnsSetList then
    FSetListObject.Free;
  FOwnsSetList := OwnsObject;

  FSetListObject := SetListObject;

  Self.Caption := 'Sets in - ' + FSetlistObject.Name;

  //do query by ID.

  // If no results, and type is rebrickable,
    // import from Rebrickable (if login available)
      // Insert into database right away
  //if results, load them

{
    var FDQuery := TFDQuery.Create(nil);
    try
      // Set up the query
      var SqlConnection := FrmMain.AcquireConnection;
      try
        FDQuery.Connection := SqlConnection;
        FDQuery.SQL.Text := 'DELETE FROM MySetLists where id=:id';

        var Params := FDQuery.Params;
        Params.ParamByName('id').asInteger := SetList.ID;

        FDQuery.ExecSQL;
        SetList.DoDelete := True;
      finally
        FrmMain.ReleaseConnection(SqlConnection);
      end;
    finally
      FDQuery.Free;
    end;
//}

  //SetList.Name

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

procedure TFrmSetList.FSetSetListID(SetSetListID: Integer);
begin
  var SetListObject := TSetListObject.Create;
  SetListObject.LoadByID(SetSetListID);

  FSetSetListObject(SetListObject, True);
end;

end.
