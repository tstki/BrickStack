unit UDlgLogin;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  IdHttp, UConfig;

type
  TDlgLogin = class(TForm)
    LblUsername: TLabel;
    EditUsername: TEdit;
    LblRebrickableBaseUrl: TLabel;
    EditPassword: TEdit;
    BtnOK: TButton;
    BtnCancel: TButton;
    ChkStoreAuthenticationToken: TCheckBox;
    LblHeader: TLabel;
    StoreAuthenticationTokenWarning: TLabel;
    procedure BtnOKClick(Sender: TObject);
    procedure EditChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    FIdHttp: TIdHttp;
//    FConfig: TConfig;
    FRebrickableAPIKey: String;
    FRebrickableBaseUrl: String;
    FAuthenticationToken: String;
    FRememberAuthenticationToken: Boolean;
    procedure FUpdateUI;
  public
    { Public declarations }
    property IdHttp: TIdHttp read FIdHttp write FIdHttp;
//    property Config: TConfig read FConfig write FConfig;
    property RebrickableAPIKey: String read FRebrickableAPIKey write FRebrickableAPIKey;
    property RebrickableBaseUrl: String read FRebrickableBaseUrl write FRebrickableBaseUrl;
    property AuthenticationToken: String read FAuthenticationToken write FAuthenticationToken;
    property RememberAuthenticationToken: Boolean read FRememberAuthenticationToken write FRememberAuthenticationToken;

  end;

var
  DlgLogin: TDlgLogin;

implementation

{$R *.dfm}

uses
  IdSSL, IdSSLOpenSSL, IdSSLOpenSSLHeaders,
  UStrings,
  System.JSON,
  StrUtils;

procedure TDlgLogin.FormCreate(Sender: TObject);
begin
//
end;

procedure TDlgLogin.FormShow(Sender: TObject);
begin
  FUpdateUI;
end;

procedure TDlgLogin.BtnOKClick(Sender: TObject);
begin
  // Obtain a token for user actions such as import/export
  var ApiKey := FRebrickableAPIKey;

  // API key is mandatory
  if ApiKey = '' then begin
    ShowMessage(StrErrAPIKeyNotSet);
    Modalresult := mrCancel;
    Exit;
  end;

  var BaseUrl := FRebrickableBaseUrl;
  var EndPoint := '/api/v3/users/_token/';

  FIdHttp.Request.CustomHeaders.Clear;
  FIdHttp.Request.CustomHeaders.AddValue('Authorization', 'key ' + ApiKey);

  try
    var Params := TStringList.Create;
    try
      // Set authentication:
      Params.Add('username=' + EditUsername.Text);
      Params.Add('password=' + EditPassword.Text);

      FIdHttp.Request.ContentType := 'application/x-www-form-urlencoded';
      var ResponseContent := FIdHttp.Post(BaseUrl + EndPoint, Params);

      // Attempt to parse the response:
      if ResponseContent <> '' then begin
        var JSONObject := TJSONObject.ParseJSONValue(ResponseContent) as TJSONObject;

        var ResultToken := '';
        JSONObject.TryGetValue<string>('user_token', ResultToken);
        if ResultToken <> '' then begin
          FAuthenticationToken := ResultToken;
          FRememberAuthenticationToken := ChkStoreAuthenticationToken.Checked;
          ModalResult := mrOk;
        end else begin
          var Detail := '';
          JSONObject.TryGetValue<string>('detail', Detail);
          ShowMessage(Detail);
          ModalResult := mrNone;
        end;
      end else begin
        ShowMessage(StrErrNoResult);
        ModalResult := mrNone;
      end;
    finally
      Params.Free;
    end;
  except on e:exception do
    begin
      // show error if any
      var idErr := IdSSLOpenSSLHeaders.WhichFailedToLoad();
      ShowMessage(IfThen(idErr <> '', idErr, e.Message));
      Modalresult := mrNone;
    end
  end;
end;

procedure TDlgLogin.FUpdateUI;
begin
  BtnOk.Enabled := (EditUsername.Text <> '') and (EditPassword.Text <> '');
end;

procedure TDlgLogin.EditChange(Sender: TObject);
begin
  FUpdateUI;
end;

end.
