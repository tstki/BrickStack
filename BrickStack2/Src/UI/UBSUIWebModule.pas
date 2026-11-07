unit UBSUIWebModule;

interface

uses
  System.Classes,
  Web.HTTPApp;

type
  TUIWebModule = class(TCustomWebDispatcher)
  private
    procedure HandleRequest(Sender: TObject; Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    function WebAssetPath(const AFileName: string): string;
    procedure SendAsset(Response: TWebResponse; const AFileName, AContentType: string);
    procedure SendBackendData(Request: TWebRequest; Response: TWebResponse);
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

uses
  UBrickStack2Server,
  System.IOUtils,
  System.SysUtils,
  System.StrUtils,
  IdException,
  IdHTTP;

const
  cBackendDemoUrl = 'http://127.0.0.1:8081/api/demo';
  cBackendCatalogUrl = 'http://127.0.0.1:8081';

function IsNumericIDRoute(const APath, APrefix, ASuffix: string): Boolean;
begin
  Result := StartsText(APrefix, APath) and EndsText(ASuffix, APath) and
    (Length(APath) > Length(APrefix) + Length(ASuffix));
  if not Result then
    Exit;
  var IDText := Copy(APath, Length(APrefix) + 1,
    Length(APath) - Length(APrefix) - Length(ASuffix));
  for var C in IDText do
    if not CharInSet(C, ['0'..'9']) then
      Exit(False);
  var ID: Integer;
  if not TryStrToInt(IDText, ID) then
    Exit(False);
  Result := ID > 0;
end;

function IsCollectionItemsRoute(const APath: string): Boolean;
begin
  Result := IsNumericIDRoute(APath, '/api/collections/', '/set-lists') or
    IsNumericIDRoute(APath, '/api/set-lists/', '/sets') or
    IsNumericIDRoute(APath, '/api/set-lists/', '') or
    IsNumericIDRoute(APath, '/api/collection-sets/', '');
end;

function IsCollectionUserDataRoute(const APath: string): Boolean;
begin
  Result := SameText(APath, '/api/collections') or
    IsNumericIDRoute(APath, '/api/collections/', '') or
    IsCollectionItemsRoute(APath);
end;

function IsAllowedBackendRoute(const APath: string): Boolean;
const
  cSetsPrefix = '/api/catalog/sets/';
  cCollectionsPrefix = '/api/collections/';
  cInventorySuffix = '/inventory';
begin
  Result := SameText(APath, '/api/demo') or
    SameText(APath, '/api/auth/login') or
    SameText(APath, '/api/auth/password') or
    SameText(APath, '/api/auth/session') or
    SameText(APath, '/api/auth/logout') or
    SameText(APath, '/api/auth/totp/enroll/start') or
    SameText(APath, '/api/auth/totp/enroll/confirm') or
    SameText(APath, '/api/auth/bootstrap/status') or
    SameText(APath, '/api/auth/bootstrap/password') or
    SameText(APath, '/api/admin/users') or
    SameText(APath, '/api/collections') or
    SameText(APath, '/api/catalog/summary') or
    SameText(APath, '/api/catalog/sets') or
    SameText(APath, '/api/catalog/parts') or
    SameText(APath, '/api/catalog/themes') or
    SameText(APath, '/api/catalog/colors') or
    SameText(APath, '/api/catalog/part-categories');
  if Result then
    Exit;
  if IsCollectionItemsRoute(APath) then begin
    Result := True;
    Exit;
  end;

  var Identifier: string;
  if StartsText(cCollectionsPrefix, APath) then begin
    Identifier := Copy(APath, Length(cCollectionsPrefix) + 1, MaxInt);
    if Identifier = '' then
      Exit(False);
    for var C in Identifier do
      if not CharInSet(C, ['0'..'9']) then
        Exit(False);
    var CollectionID: Integer;
    Result := TryStrToInt(Identifier, CollectionID);
    if not Result then
      Exit;
    Result := CollectionID > 0;
    Exit;
  end;

  if StartsText(cSetsPrefix, APath) and EndsText(cInventorySuffix, APath) then begin
    Identifier := Copy(APath, Length(cSetsPrefix) + 1,
      Length(APath) - Length(cSetsPrefix) - Length(cInventorySuffix));
    if (Identifier = '') or (Identifier = '.') or (Identifier = '..') then
      Exit(False);
    for var C in Identifier do
      if not CharInSet(C, ['0'..'9', 'A'..'Z', 'a'..'z', '.', '-', '_']) then
        Exit(False);
    Exit(True);
  end;

  var Prefix: string;
  if StartsText('/api/catalog/sets/', APath) then
    Prefix := '/api/catalog/sets/'
  else if StartsText('/api/catalog/parts/', APath) then
    Prefix := '/api/catalog/parts/'
  else
    Exit(False);
  Identifier := Copy(APath, Length(Prefix) + 1, MaxInt);
  Result := (Identifier <> '') and (Identifier <> '.') and
    (Identifier <> '..');
  for var C in Identifier do
    if not CharInSet(C, ['0'..'9', 'A'..'Z', 'a'..'z', '.', '-', '_']) then
      Exit(False);
end;

function IsLoopbackClient(const ARemoteAddress: string): Boolean;
begin
  Result := SameText(ARemoteAddress, '127.0.0.1') or
    SameText(ARemoteAddress, '::1') or
    SameText(ARemoteAddress, '::ffff:127.0.0.1');
end;

constructor TUIWebModule.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  var Action := Actions.Add;
  Action.Name := 'Dispatch';
  Action.Default := True;
  Action.OnAction := HandleRequest;
end;

function TUIWebModule.WebAssetPath(const AFileName: string): string;
begin
  var LProjectRoot := TPath.GetFullPath(
    TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\..'));
  Result := TPath.Combine(TPath.Combine(LProjectRoot, 'Src\UI\Web'), AFileName);
end;

procedure TUIWebModule.SendAsset(Response: TWebResponse; const AFileName, AContentType: string);
begin
  if not TFile.Exists(WebAssetPath(AFileName)) then begin
    LogServerMessage('BrickStack2 UI',
      'UI asset missing: ' + AFileName + ' -> 500');
    Response.StatusCode := 500;
    Response.ContentType := 'text/plain; charset=utf-8';
    Response.Content := 'UI asset is missing: ' + AFileName;
    Exit;
  end;

  Response.ContentType := AContentType;
  Response.Content := TFile.ReadAllText(WebAssetPath(AFileName), TEncoding.UTF8);
  LogServerMessage('BrickStack2 UI',
    'Served ' + AFileName + ' -> 200');
end;

procedure TUIWebModule.SendBackendData(Request: TWebRequest; Response: TWebResponse);
begin
  if not IsAllowedBackendRoute(Request.PathInfo) then begin
    Response.StatusCode := 404;
    Response.ContentType := 'application/json; charset=utf-8';
    Response.Content := '{"error":"not_found"}';
    Exit;
  end;
  if (Length(Request.Query) > 4096) or
    (Pos(#13, Request.Query) > 0) or (Pos(#10, Request.Query) > 0) then begin
    Response.StatusCode := 400;
    Response.ContentType := 'application/json; charset=utf-8';
    Response.Content := '{"error":"invalid_request"}';
    Exit;
  end;
  if (SameText(Request.Method, 'POST') or SameText(Request.Method, 'PUT')) and
    ((TEncoding.UTF8.GetByteCount(Request.Content) > 4096) or
      not StartsText('application/json', Request.ContentType)) then begin
    Response.StatusCode := 400;
    Response.ContentType := 'application/json; charset=utf-8';
    Response.Content := '{"error":"invalid_request"}';
    Exit;
  end;
  var IsCollectionRoute := IsCollectionUserDataRoute(Request.PathInfo);
  var IsAuthRoute := StartsText('/api/auth/', Request.PathInfo) or
    SameText(Request.PathInfo, '/api/admin/users') or
    IsCollectionRoute;
  if IsAuthRoute then
    Response.SetCustomHeader('Cache-Control', 'no-store');
  if IsAuthRoute and
    (SameText(Request.Method, 'POST') or SameText(Request.Method, 'PUT') or
     SameText(Request.Method, 'DELETE')) and
    (Request.GetFieldByName('X-BrickStack-Request') <> '1') then begin
    Response.StatusCode := 403;
    Response.ContentType := 'application/json; charset=utf-8';
    Response.Content := '{"error":"csrf_check_failed"}';
    Exit;
  end;

  var BackendUrl: string;
  if SameText(Request.PathInfo, '/api/demo') then
    BackendUrl := cBackendDemoUrl
  else
    BackendUrl := cBackendCatalogUrl + Request.PathInfo;
  if Request.Query <> '' then
    BackendUrl := BackendUrl + '?' + Request.Query;

  var Client := TIdHTTP.Create(nil);
  try
    Client.ConnectTimeout := 1000;
    Client.ReadTimeout := 3000;
    if SameText(Request.PathInfo, '/api/auth/login') or
        SameText(Request.PathInfo, '/api/auth/bootstrap/password') or
        SameText(Request.PathInfo, '/api/auth/password') or
        SameText(Request.PathInfo, '/api/auth/totp/enroll/confirm') or
        (SameText(Request.PathInfo, '/api/admin/users') and
         SameText(Request.Method, 'POST')) then
      Client.ReadTimeout := 30000;
    try
      LogServerMessage('BrickStack2 UI',
        Request.Method + ' ' + Request.PathInfo +
        ' -> forwarding request to backend.');
      if IsAuthRoute then begin
        Client.Request.CustomHeaders.Values['Cookie'] :=
          Request.GetFieldByName('Cookie');
        Client.Request.CustomHeaders.Values['X-BrickStack-Request'] :=
          Request.GetFieldByName('X-BrickStack-Request');
      end;
      Response.ContentType := 'application/json; charset=utf-8';
      if SameText(Request.Method, 'POST') or
        SameText(Request.Method, 'PUT') then begin
        Client.Request.ContentType := 'application/json; charset=utf-8';
        var RequestBody := TStringStream.Create(Request.Content, TEncoding.UTF8);
        try
          if SameText(Request.Method, 'POST') then
            Response.Content := Client.Post(BackendUrl, RequestBody)
          else
            Response.Content := Client.Put(BackendUrl, RequestBody);
        finally
          RequestBody.Free;
        end;
      end else if SameText(Request.Method, 'DELETE') then
        Response.Content := Client.Delete(BackendUrl)
      else
        Response.Content := Client.Get(BackendUrl);
      if IsAuthRoute then begin
        var SetCookie := Client.Response.RawHeaders.Values['Set-Cookie'];
        if SetCookie <> '' then
          Response.SetCustomHeader('Set-Cookie', SetCookie);
      end;
      LogServerMessage('BrickStack2 UI',
        Request.Method + ' ' + Request.PathInfo +
        ' <- backend returned 200.');
    except
      on E: EIdHTTPProtocolException do begin
        Response.StatusCode := E.ErrorCode;
        Response.ContentType := 'application/json; charset=utf-8';
        case E.ErrorCode of
          400:
            if SameText(Request.PathInfo,
              '/api/auth/totp/enroll/confirm') then
              Response.Content := '{"error":"invalid_totp_code"}'
            else
              Response.Content := '{"error":"invalid_request"}';
          401:
            if SameText(Request.PathInfo, '/api/admin/users') or
              IsCollectionRoute then
              Response.Content := '{"error":"authentication_required"}'
            else if SameText(Request.PathInfo, '/api/auth/login') or
              SameText(Request.PathInfo, '/api/auth/password') then
              Response.Content := '{"error":"invalid_credentials"}'
            else
              Response.Content := '{"error":"invalid_bootstrap_credentials"}';
          403:
            if SameText(Request.PathInfo, '/api/admin/users') then
              Response.Content := '{"error":"forbidden"}'
            else if IsCollectionRoute and
              (Request.GetFieldByName('X-BrickStack-Request') = '1') then
              Response.Content := '{"error":"forbidden"}'
            else if SameText(Request.PathInfo,
              '/api/auth/totp/enroll/start') then
              Response.Content := '{"error":"totp_enrollment_unavailable"}'
            else if SameText(Request.Method, 'POST') and IsAuthRoute then
              Response.Content := '{"error":"csrf_check_failed"}'
            else
              Response.Content := '{"error":"loopback_only"}';
          404: Response.Content := '{"error":"not_found"}';
          405: Response.Content := '{"error":"method_not_allowed"}';
          409:
            if IsCollectionRoute then
              Response.Content := '{"error":"collection_name_unavailable"}'
            else
              Response.Content := '{"error":"username_unavailable"}';
        else
          Response.Content := '{"error":"backend_error"}';
        end;
        LogServerMessage('BrickStack2 UI',
          Request.Method + ' ' + Request.PathInfo +
          ' <- backend returned HTTP ' +
          IntToStr(E.ErrorCode) + '.');
      end;
      on E: EIdException do begin
        LogServerMessage('BrickStack2 UI',
          Request.Method + ' ' + Request.PathInfo +
          ' <- backend request failed (' + E.ClassName + '): ' + E.Message +
          ' -> 502.');
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

procedure TUIWebModule.HandleRequest(Sender: TObject; Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
begin
  Handled := True;

  var IsAllowedCollectionPost := SameText(Request.Method, 'POST') and
    (IsNumericIDRoute(Request.PathInfo, '/api/collections/', '/set-lists') or
     IsNumericIDRoute(Request.PathInfo, '/api/set-lists/', '/sets'));
  var IsAllowedCollectionPut := SameText(Request.Method, 'PUT') and
    (IsNumericIDRoute(Request.PathInfo, '/api/collections/', '') or
     IsNumericIDRoute(Request.PathInfo, '/api/set-lists/', '') or
     IsNumericIDRoute(Request.PathInfo, '/api/collection-sets/', ''));
  var IsAllowedCollectionDelete := SameText(Request.Method, 'DELETE') and
    (IsNumericIDRoute(Request.PathInfo, '/api/set-lists/', '') or
     IsNumericIDRoute(Request.PathInfo, '/api/collection-sets/', ''));
  if not SameText(Request.Method, 'GET') and
    not (SameText(Request.Method, 'POST') and
      (SameText(Request.PathInfo, '/api/auth/bootstrap/password') or
       SameText(Request.PathInfo, '/api/auth/login') or
       SameText(Request.PathInfo, '/api/auth/password') or
       SameText(Request.PathInfo, '/api/auth/totp/enroll/start') or
       SameText(Request.PathInfo, '/api/auth/totp/enroll/confirm') or
       SameText(Request.PathInfo, '/api/auth/logout') or
       (SameText(Request.PathInfo, '/api/collections') and
        SameText(Request.Method, 'POST')) or
       (SameText(Request.PathInfo, '/api/admin/users') and
        SameText(Request.Method, 'POST')))) and
    not IsAllowedCollectionPost and not IsAllowedCollectionPut and
    not IsAllowedCollectionDelete then begin
    LogServerMessage('BrickStack2 UI',
      Request.Method + ' ' + Request.PathInfo + ' -> 405');
    Response.StatusCode := 405;
    Response.ContentType := 'application/json; charset=utf-8';
    Response.Content := '{"error":"method_not_allowed"}';
    Exit;
  end;

  if (Request.PathInfo = '') or SameText(Request.PathInfo, '/') then begin
    SendAsset(Response, 'index.html', 'text/html; charset=utf-8');
    Exit;
  end;

  if SameText(Request.PathInfo, '/app.css') then begin
    SendAsset(Response, 'app.css', 'text/css; charset=utf-8');
    Exit;
  end;

  if SameText(Request.PathInfo, '/app.js') then begin
    SendAsset(Response, 'app.js', 'text/javascript; charset=utf-8');
    Exit;
  end;

  if SameText(Request.PathInfo, '/health') then begin
    Response.ContentType := 'application/json; charset=utf-8';
    Response.Content := '{"status":"ok","service":"ui"}';
    LogServerMessage('BrickStack2 UI', 'GET /health -> 200');
    Exit;
  end;

  if SameText(Request.PathInfo, '/api/demo') then begin
    SendBackendData(Request, Response);
    Exit;
  end;

  if StartsText('/api/auth/', Request.PathInfo) then begin
    if not IsLoopbackClient(Request.RemoteAddr) then begin
      Response.StatusCode := 403;
      Response.ContentType := 'application/json; charset=utf-8';
      Response.Content := '{"error":"loopback_only"}';
      Exit;
    end;
    SendBackendData(Request, Response);
    Exit;
  end;

  if SameText(Request.PathInfo, '/api/admin/users') then begin
    if not IsLoopbackClient(Request.RemoteAddr) then begin
      Response.StatusCode := 403;
      Response.ContentType := 'application/json; charset=utf-8';
      Response.Content := '{"error":"loopback_only"}';
      Exit;
    end;
    SendBackendData(Request, Response);
    Exit;
  end;

  if IsCollectionUserDataRoute(Request.PathInfo) then begin
    if not IsLoopbackClient(Request.RemoteAddr) then begin
      Response.StatusCode := 403;
      Response.ContentType := 'application/json; charset=utf-8';
      Response.Content := '{"error":"loopback_only"}';
      Exit;
    end;
    SendBackendData(Request, Response);
    Exit;
  end;

  if StartsText('/api/catalog/', Request.PathInfo) then begin
    SendBackendData(Request, Response);
    Exit;
  end;

  LogServerMessage('BrickStack2 UI',
    Request.Method + ' ' + Request.PathInfo + ' -> 404');
  Response.StatusCode := 404;
  Response.ContentType := 'application/json; charset=utf-8';
  Response.Content := '{"error":"not_found"}';
end;

end.
