unit UDlgLogin;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  UConfig;

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
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    FRebrickableAPIKey: String;
    FRebrickableBaseUrl: String;
    FAuthenticationToken: String;
    FRememberAuthenticationToken: Boolean;
    procedure FUpdateUI;
  public
    { Public declarations }
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
  UStrings,
  System.JSON, Net.HttpClientComponent,
  StrUtils;

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

  const EndPoint = '/api/v3/users/_token/';

  try
    var HttpClient := TNetHttpClient.Create(nil);
    var Params := TStringList.Create;
    try
      // Set authentication:
      Params.Add('username=' + EditUsername.Text);
      Params.Add('password=' + EditPassword.Text);

      HttpClient.CustomHeaders['Authorization'] := 'key ' + ApiKey;

      var ResponseContent := HttpClient.Post(FRebrickableBaseUrl + EndPoint, Params);
      var ResponseAsString := ResponseContent.ContentAsString();

      // Attempt to parse the response:
      if ResponseAsString <> '' then begin
        var JSONObject := TJSONObject.ParseJSONValue(ResponseAsString) as TJSONObject;

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
      HttpClient.Free;
    end;
  except on e:Exception do
    begin
      // show error if any
{
    on E: ENetHTTPClientException do begin
      // Handle specific HTTP client exceptions
      ShowMessage('HTTP Client Exception: ' + E.Message);
      // Additional details from the exception
      if E.Response <> nil then begin
        ShowMessage('Response Status Code: ' + E.Response.StatusCode.ToString);
        ShowMessage('Response Content: ' + E.Response.ContentAsString());
      end;
    end;
    on E: Exception do begin
      // Handle other exceptions
      ShowMessage('General Exception: ' + E.Message);
    end;
}

      ShowMessage(e.Message);
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
