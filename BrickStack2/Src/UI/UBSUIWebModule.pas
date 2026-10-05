unit UBSUIWebModule;

interface

uses
  System.Classes,
  Web.HTTPApp;

type
  TUIWebModule = class(TCustomWebDispatcher)
  private
    procedure HandleRequest(Sender: TObject; Request: TWebRequest;
      Response: TWebResponse; var Handled: Boolean);
    function WebAssetPath(const AFileName: string): string;
    procedure SendAsset(Response: TWebResponse; const AFileName,
      AContentType: string);
    procedure SendBackendData(Response: TWebResponse);
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  IdException,
  IdHTTP;

const
  cBackendDemoUrl = 'http://127.0.0.1:8081/api/demo';

constructor TUIWebModule.Create(AOwner: TComponent);
var
  Action: TWebActionItem;
begin
  inherited Create(AOwner);
  Action := Actions.Add;
  Action.Name := 'Dispatch';
  Action.Default := True;
  Action.OnAction := HandleRequest;
end;

function TUIWebModule.WebAssetPath(const AFileName: string): string;
var
  LProjectRoot: string;
begin
  LProjectRoot := TPath.GetFullPath(
    TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\..'));
  Result := TPath.Combine(TPath.Combine(LProjectRoot, 'Src\UI\Web'), AFileName);
end;

procedure TUIWebModule.SendAsset(Response: TWebResponse;
  const AFileName, AContentType: string);
begin
  if not TFile.Exists(WebAssetPath(AFileName)) then
  begin
    Response.StatusCode := 500;
    Response.ContentType := 'text/plain; charset=utf-8';
    Response.Content := 'UI asset is missing: ' + AFileName;
    Exit;
  end;

  Response.ContentType := AContentType;
  Response.Content := TFile.ReadAllText(WebAssetPath(AFileName), TEncoding.UTF8);
end;

procedure TUIWebModule.SendBackendData(Response: TWebResponse);
var
  Client: TIdHTTP;
begin
  Client := TIdHTTP.Create(nil);
  try
    Client.ConnectTimeout := 1000;
    Client.ReadTimeout := 3000;
    try
      Response.ContentType := 'application/json; charset=utf-8';
      Response.Content := Client.Get(cBackendDemoUrl);
    except
      on E: EIdException do
      begin
        Writeln(ErrOutput, 'Backend request failed: ' + E.Message);
        Response.StatusCode := 502;
        Response.ContentType := 'application/json; charset=utf-8';
        Response.Content :=
          '{"error":"backend_unavailable","message":"The BrickStack2 backend could not be reached."}';
      end;
    end;
  finally
    Client.Free;
  end;
end;

procedure TUIWebModule.HandleRequest(Sender: TObject; Request: TWebRequest;
  Response: TWebResponse; var Handled: Boolean);
begin
  Handled := True;

  if not SameText(Request.Method, 'GET') then
  begin
    Response.StatusCode := 405;
    Response.ContentType := 'application/json; charset=utf-8';
    Response.Content := '{"error":"method_not_allowed"}';
    Exit;
  end;

  if (Request.PathInfo = '') or SameText(Request.PathInfo, '/') then
  begin
    SendAsset(Response, 'index.html', 'text/html; charset=utf-8');
    Exit;
  end;

  if SameText(Request.PathInfo, '/app.css') then
  begin
    SendAsset(Response, 'app.css', 'text/css; charset=utf-8');
    Exit;
  end;

  if SameText(Request.PathInfo, '/app.js') then
  begin
    SendAsset(Response, 'app.js', 'text/javascript; charset=utf-8');
    Exit;
  end;

  if SameText(Request.PathInfo, '/health') then
  begin
    Response.ContentType := 'application/json; charset=utf-8';
    Response.Content := '{"status":"ok","service":"ui"}';
    Exit;
  end;

  if SameText(Request.PathInfo, '/api/demo') then
  begin
    SendBackendData(Response);
    Exit;
  end;

  Response.StatusCode := 404;
  Response.ContentType := 'application/json; charset=utf-8';
  Response.Content := '{"error":"not_found"}';
end;

end.
