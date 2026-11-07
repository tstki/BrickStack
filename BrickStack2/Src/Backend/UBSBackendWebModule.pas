unit UBSBackendWebModule;

interface

uses
  System.Classes,
  Web.HTTPApp;

type
  TBackendWebModule = class(TCustomWebDispatcher)
  private
    procedure HandleRequest(Sender: TObject; Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

uses
  System.IOUtils,
  System.JSON,
  System.SysUtils,
  System.StrUtils,
  UBrickStack2Server,
  UBSDemoData,
  UBSAdminBootstrap,
  UBSCollectionRepository,
  UBSRebrickableCatalogRepository;

const
  cDefaultCatalogPageSize = 25;
  cMaximumCatalogPageSize = 100;
  cMaximumCatalogQueryLength = 4096;

type
  TCollectionItemsRoute = (cirNone, cirCollectionSetLists, cirSetList,
    cirSetListSets, cirCollectionSet);

function JsonString(const AValue: string): TJSONValue;
begin
  Result := TJSONString.Create(AValue);
end;

procedure AddSetJson(AObject: TJSONObject; const ASet: TCatalogSet);
begin
  AObject.AddPair('setNumber', JsonString(ASet.SetNumber));
  AObject.AddPair('name', JsonString(ASet.Name));
  AObject.AddPair('year', TJSONNumber.Create(ASet.Year));
  AObject.AddPair('themeId', TJSONNumber.Create(ASet.ThemeID));
  AObject.AddPair('themeName', JsonString(ASet.ThemeName));
  AObject.AddPair('partCount', TJSONNumber.Create(ASet.PartCount));
  AObject.AddPair('imageUrl', JsonString(ASet.ImageURL));
end;

procedure AddPartJson(AObject: TJSONObject; const APart: TCatalogPart);
begin
  AObject.AddPair('partNumber', JsonString(APart.PartNumber));
  AObject.AddPair('name', JsonString(APart.Name));
  AObject.AddPair('categoryId', TJSONNumber.Create(APart.CategoryID));
  AObject.AddPair('categoryName', JsonString(APart.CategoryName));
  AObject.AddPair('material', JsonString(APart.Material));
end;

function SetPageJson(const APage: TCatalogSetPage): string;
begin
  var Root := TJSONObject.Create;
  try
    var Items := TJSONArray.Create;
    for var Value in APage.Items do begin
      var Item := TJSONObject.Create;
      AddSetJson(Item, Value);
      Items.AddElement(Item);
    end;
    Root.AddPair('items', Items);
    Root.AddPair('nextCursor', JsonString(APage.NextCursor));
    Root.AddPair('hasMore', TJSONBool.Create(APage.HasMore));
    Result := Root.ToJSON;
  finally
    Root.Free;
  end;
end;

function PartPageJson(const APage: TCatalogPartPage): string;
begin
  var Root := TJSONObject.Create;
  try
    var Items := TJSONArray.Create;
    for var Value in APage.Items do begin
      var Item := TJSONObject.Create;
      AddPartJson(Item, Value);
      Items.AddElement(Item);
    end;
    Root.AddPair('items', Items);
    Root.AddPair('nextCursor', JsonString(APage.NextCursor));
    Root.AddPair('hasMore', TJSONBool.Create(APage.HasMore));
    Result := Root.ToJSON;
  finally
    Root.Free;
  end;
end;

function InventoryPageJson(const APage: TCatalogInventoryPage): string;
begin
  var Root := TJSONObject.Create;
  try
    var Items := TJSONArray.Create;
    for var Value in APage.Items do begin
      var Item := TJSONObject.Create;
      Item.AddPair('partNumber', JsonString(Value.PartNumber));
      Item.AddPair('name', JsonString(Value.Name));
      Item.AddPair('colorId', TJSONNumber.Create(Value.ColorID));
      Item.AddPair('colorName', JsonString(Value.ColorName));
      Item.AddPair('rgb', JsonString(Value.RGB));
      Item.AddPair('quantity', TJSONNumber.Create(Value.Quantity));
      Item.AddPair('isSpare', TJSONBool.Create(Value.IsSpare));
      Item.AddPair('imageUrl', JsonString(Value.ImageURL));
      Items.AddElement(Item);
    end;
    Root.AddPair('setNumber', JsonString(APage.SetNumber));
    Root.AddPair('inventoryId', TJSONNumber.Create(APage.InventoryID));
    Root.AddPair('version', TJSONNumber.Create(APage.Version));
    Root.AddPair('items', Items);
    Root.AddPair('nextCursor', JsonString(APage.NextCursor));
    Root.AddPair('hasMore', TJSONBool.Create(APage.HasMore));
    Result := Root.ToJSON;
  finally
    Root.Free;
  end;
end;

function ReadOptionalInteger(Request: TWebRequest; const AName: string; ADefault: Integer): Integer;
begin
  var Text := Request.QueryFields.Values[AName].Trim;
  if Text = '' then
    Exit(ADefault);
  if not TryStrToInt(Text, Result) then
    raise EArgumentException.CreateFmt('Query parameter "%s" must be an integer.',
      [AName]);
  if Result < 0 then
    raise EArgumentException.CreateFmt('Query parameter "%s" cannot be negative.',
      [AName]);
end;

function ReadPageSize(Request: TWebRequest): Integer;
begin
  var Text := Request.QueryFields.Values['pageSize'].Trim;
  if Text = '' then
    Exit(cDefaultCatalogPageSize);
  if not TryStrToInt(Text, Result) or
    (Result < 1) or (Result > cMaximumCatalogPageSize) then
    raise EArgumentException.CreateFmt(
      'Query parameter "pageSize" must be between 1 and %d.',
      [cMaximumCatalogPageSize]);
end;

function RouteIdentifier(const APath, APrefix: string; out AIdentifier: string): Boolean;
begin
  Result := StartsText(APrefix, APath);
  if not Result then
    Exit;
  AIdentifier := Copy(APath, Length(APrefix) + 1, MaxInt);
  Result := (AIdentifier <> '') and (AIdentifier <> '.') and
    (AIdentifier <> '..') and (Pos('/', AIdentifier) = 0);
  if Result then
    for var C in AIdentifier do
      if not CharInSet(C, ['0'..'9', 'A'..'Z', 'a'..'z', '.', '-', '_']) then
        Exit(False);
end;

function TryParsePathID(const APath, APrefix, ASuffix: string;
  out AID: Integer): Boolean;
begin
  AID := 0;
  Result := StartsText(APrefix, APath) and EndsText(ASuffix, APath) and
    (Length(APath) > Length(APrefix) + Length(ASuffix));
  if not Result then
    Exit;
  var IDText := Copy(APath, Length(APrefix) + 1,
    Length(APath) - Length(APrefix) - Length(ASuffix));
  for var C in IDText do
    if not CharInSet(C, ['0'..'9']) then
      Exit(False);
  if not TryStrToInt(IDText, AID) then
    Exit(False);
  Result := AID > 0;
end;

function ParseCollectionItemsRoute(const APath: string;
  out AID: Integer): TCollectionItemsRoute;
begin
  AID := 0;
  if TryParsePathID(APath, '/api/collections/', '/set-lists', AID) then
    Exit(cirCollectionSetLists);
  if TryParsePathID(APath, '/api/set-lists/', '/sets', AID) then
    Exit(cirSetListSets);
  if TryParsePathID(APath, '/api/set-lists/', '', AID) then
    Exit(cirSetList);
  if TryParsePathID(APath, '/api/collection-sets/', '', AID) then
    Exit(cirCollectionSet);
  Result := cirNone;
end;

procedure AddSetListJson(AObject: TJSONObject; const ASetList: TUserSetList);
begin
  AObject.AddPair('id', TJSONNumber.Create(ASetList.ID));
  AObject.AddPair('collectionId', TJSONNumber.Create(ASetList.CollectionID));
  AObject.AddPair('name', JsonString(ASetList.Name));
  AObject.AddPair('description', JsonString(ASetList.Description));
  AObject.AddPair('useInCollection', TJSONBool.Create(ASetList.UseInCollection));
  AObject.AddPair('sortIndex', TJSONNumber.Create(ASetList.SortIndex));
end;

procedure AddCollectionSetJson(AObject: TJSONObject; const ASet: TCollectionSet);
begin
  AObject.AddPair('id', TJSONNumber.Create(ASet.ID));
  AObject.AddPair('setListId', TJSONNumber.Create(ASet.SetListID));
  AObject.AddPair('setNumber', JsonString(ASet.SetNumber));
  AObject.AddPair('built', TJSONBool.Create(ASet.Built));
  AObject.AddPair('haveSpareParts', TJSONBool.Create(ASet.HaveSpareParts));
  AObject.AddPair('notes', JsonString(ASet.Notes));
end;

function SetInventoryRouteIdentifier(const APath: string; out ASetNumber: string): Boolean;
const
  cSetsPrefix = '/api/catalog/sets/';
  cInventorySuffix = '/inventory';
begin
  Result := StartsText(cSetsPrefix, APath) and
    (Length(APath) > Length(cSetsPrefix) + Length(cInventorySuffix)) and
    SameText(Copy(APath, Length(APath) - Length(cInventorySuffix) + 1,
      Length(cInventorySuffix)), cInventorySuffix);
  if not Result then
    Exit;
  var Identifier := Copy(APath, Length(cSetsPrefix) + 1,
    Length(APath) - Length(cSetsPrefix) - Length(cInventorySuffix));
  Result := RouteIdentifier(cSetsPrefix + Identifier, cSetsPrefix,
    ASetNumber);
end;

function CatalogDatabaseFileName: string;
begin
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), 'DBase\rb.db');
end;

procedure SendCatalogJson(Response: TWebResponse; const AContent: string);
begin
  Response.StatusCode := 200;
  Response.ContentType := 'application/json; charset=utf-8';
  Response.Content := AContent;
end;

procedure SendJsonError(Response: TWebResponse; AStatusCode: Integer; const AErrorCode: string);
var
  ErrorObject: TJSONObject;
begin
  ErrorObject := TJSONObject.Create;
  try
    ErrorObject.AddPair('error', AErrorCode);
    SendCatalogJson(Response, ErrorObject.ToJSON);
    Response.StatusCode := AStatusCode;
  finally
    ErrorObject.Free;
  end;
end;

function BrickStackDatabaseFileName: string;
begin
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)),
    'DBase\BrickStack.db');
end;

function IsLoopbackRequest(Request: TWebRequest): Boolean;
begin
  Result := SameText(Request.RemoteAddr, '127.0.0.1') or
    SameText(Request.RemoteAddr, '::1') or
    SameText(Request.RemoteAddr, '::ffff:127.0.0.1');
end;

function BootstrapJsonField(const AObject: TJSONObject; const AName: string): string;
begin
  var Value := AObject.GetValue(AName);
  if not (Value is TJSONString) then
    raise EArgumentException.CreateFmt('JSON field "%s" is required.',
      [AName]);
  Result := Value.Value;
end;

function HandleBootstrapRequest(Request: TWebRequest; Response: TWebResponse): Boolean;
const
  cStatusPath = '/api/auth/bootstrap/status';
  cChangePasswordPath = '/api/auth/bootstrap/password';
  cMaximumBodyLength = 4096;
  procedure AddAuthenticatedUserJson(AObject: TJSONObject; const AUser: TAuthenticatedUser);
  begin
    AObject.AddPair('id', TJSONNumber.Create(AUser.ID));
    AObject.AddPair('username', TJSONString.Create(AUser.UserName));
    AObject.AddPair('displayName', TJSONString.Create(AUser.DisplayName));
    AObject.AddPair('role', TJSONNumber.Create(AUser.Role));
    AObject.AddPair('totpEnabled', TJSONBool.Create(AUser.TotpEnabled));
  end;

  function OptionalJsonField(const AObject: TJSONObject; const AName: string): string;
  begin
    var Value := AObject.GetValue(AName);
    if Value = nil then
      Exit('');
    if not (Value is TJSONString) then
      raise EArgumentException.CreateFmt('JSON field "%s" must be a string.',
        [AName]);
    Result := Value.Value;
  end;

  function HandleAuthenticationRequest(Request: TWebRequest; Response: TWebResponse): Boolean;
  const
    cLoginPath = '/api/auth/login';
    cPasswordPath = '/api/auth/password';
    cSessionPath = '/api/auth/session';
    cLogoutPath = '/api/auth/logout';
    cTotpEnrollStartPath = '/api/auth/totp/enroll/start';
    cTotpEnrollConfirmPath = '/api/auth/totp/enroll/confirm';
    cCookieName = 'BSSESSION';
    cMaximumBodyLength = 4096;
  begin
    Result := SameText(Request.PathInfo, cLoginPath) or
      SameText(Request.PathInfo, cPasswordPath) or
      SameText(Request.PathInfo, cSessionPath) or
      SameText(Request.PathInfo, cLogoutPath) or
      SameText(Request.PathInfo, cTotpEnrollStartPath) or
      SameText(Request.PathInfo, cTotpEnrollConfirmPath);
    if not Result then
      Exit;

    if not IsLoopbackRequest(Request) then begin
      SendJsonError(Response, 403, 'loopback_only');
      Exit;
    end;
    Response.SetCustomHeader('Cache-Control', 'no-store');

    if SameText(Request.PathInfo, cSessionPath) then begin
      if not SameText(Request.Method, 'GET') then begin
        SendJsonError(Response, 405, 'method_not_allowed');
        Exit;
      end;
      var SessionToken := Request.CookieFields.Values[cCookieName];
      var User: TAuthenticatedUser;
      var SessionRoot := TJSONObject.Create;
      try
        if TryGetSessionUser(BrickStackDatabaseFileName, SessionToken, User) then begin
          SessionRoot.AddPair('authenticated', TJSONBool.Create(True));
          SessionRoot.AddPair('user', TJSONObject.Create);
          AddAuthenticatedUserJson(TJSONObject(SessionRoot.GetValue('user')), User);
        end else
          SessionRoot.AddPair('authenticated', TJSONBool.Create(False));
        SendCatalogJson(Response, SessionRoot.ToJSON);
      finally
        SessionRoot.Free;
      end;
      Exit;
    end;

    if not SameText(Request.Method, 'POST') then begin
      SendJsonError(Response, 405, 'method_not_allowed');
      Exit;
    end;
    if Request.GetFieldByName('X-BrickStack-Request') <> '1' then begin
      SendJsonError(Response, 403, 'csrf_check_failed');
      Exit;
    end;

    if SameText(Request.PathInfo, cLogoutPath) then begin
      var LogoutSessionToken := Request.CookieFields.Values[cCookieName];
      RevokeSession(BrickStackDatabaseFileName, LogoutSessionToken);
      Response.SetCustomHeader('Set-Cookie',
        cCookieName + '=; Path=/; HttpOnly; SameSite=Strict; Max-Age=0');
      SendCatalogJson(Response, '{"status":"signed_out"}');
      Exit;
    end;

    if (TEncoding.UTF8.GetByteCount(Request.Content) > cMaximumBodyLength) or
      not StartsText('application/json', Request.ContentType) then begin
      SendJsonError(Response, 400, 'invalid_request');
      Exit;
    end;
    var Parsed: TJSONValue;
    try
      Parsed := TJSONObject.ParseJSONValue(Request.Content);
    except
      on Exception do begin
        SendJsonError(Response, 400, 'invalid_request');
        Exit;
      end;
    end;
    try
      try
        if not (Parsed is TJSONObject) then begin
          SendJsonError(Response, 400, 'invalid_request');
          Exit;
        end;
        var Body := TJSONObject(Parsed);
        if SameText(Request.PathInfo, cPasswordPath) then begin
          if ReplaceRequiredUserPassword(BrickStackDatabaseFileName,
            BootstrapJsonField(Body, 'username'),
            BootstrapJsonField(Body, 'currentPassword'),
            BootstrapJsonField(Body, 'newPassword')) then
            SendCatalogJson(Response, '{"status":"password_changed"}')
          else
            SendJsonError(Response, 401, 'invalid_credentials');
          Exit;
        end;
        if SameText(Request.PathInfo, cTotpEnrollStartPath) then begin
          var EnrollmentSessionToken := Request.CookieFields.Values[cCookieName];
          var TotpSecret: string;
          var ProvisioningUri: string;
          if not StartTotpEnrollment(BrickStackDatabaseFileName,
            EnrollmentSessionToken, TotpSecret, ProvisioningUri) then begin
            SendJsonError(Response, 403, 'totp_enrollment_unavailable');
            Exit;
          end;
          var EnrollmentRoot := TJSONObject.Create;
          try
            EnrollmentRoot.AddPair('secret', JsonString(TotpSecret));
            EnrollmentRoot.AddPair('provisioningUri', JsonString(ProvisioningUri));
            Response.SetCustomHeader('Cache-Control', 'no-store');
            Response.SetCustomHeader('Pragma', 'no-cache');
            SendCatalogJson(Response, EnrollmentRoot.ToJSON);
          finally
            EnrollmentRoot.Free;
          end;
          Exit;
        end;
        if SameText(Request.PathInfo, cTotpEnrollConfirmPath) then begin
          var ConfirmSessionToken := Request.CookieFields.Values[cCookieName];
          var RecoveryCodes: TArray<string>;
          if not ConfirmTotpEnrollment(BrickStackDatabaseFileName,
            ConfirmSessionToken, BootstrapJsonField(Body, 'code'), RecoveryCodes) then begin
            SendJsonError(Response, 400, 'invalid_totp_code');
            Exit;
          end;
          var RecoveryRoot := TJSONObject.Create;
          try
            var RecoveryCodeArray := TJSONArray.Create;
            for var Code in RecoveryCodes do
              RecoveryCodeArray.AddElement(JsonString(Code));
            RecoveryRoot.AddPair('recoveryCodes', RecoveryCodeArray);
            Response.SetCustomHeader('Cache-Control', 'no-store');
            Response.SetCustomHeader('Pragma', 'no-cache');
            SendCatalogJson(Response, RecoveryRoot.ToJSON);
          finally
            RecoveryRoot.Free;
          end;
          Exit;
        end;
        var AuthenticatedUser: TAuthenticatedUser;
        var LoginSessionToken: string;
        var TotpRequired: Boolean;
        if not AuthenticateAndCreateSession(BrickStackDatabaseFileName,
          BootstrapJsonField(Body, 'username'),
          BootstrapJsonField(Body, 'password'),
          OptionalJsonField(Body, 'totpCode'),
          OptionalJsonField(Body, 'recoveryCode'),
          AuthenticatedUser, LoginSessionToken, TotpRequired) then begin
          if TotpRequired then begin
            var ChallengeRoot := TJSONObject.Create;
            try
              ChallengeRoot.AddPair('authenticated', TJSONBool.Create(False));
              ChallengeRoot.AddPair('totpRequired', TJSONBool.Create(True));
              Response.SetCustomHeader('Cache-Control', 'no-store');
              SendCatalogJson(Response, ChallengeRoot.ToJSON);
            finally
              ChallengeRoot.Free;
            end;
          end else
            SendJsonError(Response, 401, 'invalid_credentials');
          Exit;
        end;

        Response.SetCustomHeader('Set-Cookie',
          cCookieName + '=' + LoginSessionToken +
          '; Path=/; HttpOnly; SameSite=Strict; Max-Age=43200');
        var AuthenticatedRoot := TJSONObject.Create;
        try
          AuthenticatedRoot.AddPair('authenticated', TJSONBool.Create(True));
          AuthenticatedRoot.AddPair('user', TJSONObject.Create);
          AddAuthenticatedUserJson(TJSONObject(AuthenticatedRoot.GetValue('user')), AuthenticatedUser);
          SendCatalogJson(Response, AuthenticatedRoot.ToJSON);
        finally
          AuthenticatedRoot.Free;
        end;
      except
        on E: EArgumentException do
          SendJsonError(Response, 400, 'invalid_request');
      end;
    finally
      Parsed.Free;
    end;
  end;

begin
  Result := SameText(Request.PathInfo, cStatusPath) or
    SameText(Request.PathInfo, cChangePasswordPath) or
    SameText(Request.PathInfo, '/api/auth/password') or
    SameText(Request.PathInfo, '/api/auth/login') or
    SameText(Request.PathInfo, '/api/auth/session') or
    SameText(Request.PathInfo, '/api/auth/logout') or
    SameText(Request.PathInfo, '/api/auth/totp/enroll/start') or
    SameText(Request.PathInfo, '/api/auth/totp/enroll/confirm');
  if not Result then
    Exit;

  if not IsLoopbackRequest(Request) then begin
    SendJsonError(Response, 403, 'loopback_only');
    Exit;
  end;
  if not (SameText(Request.PathInfo, cStatusPath) or
    SameText(Request.PathInfo, cChangePasswordPath)) then begin
    HandleAuthenticationRequest(Request, Response);
    Exit;
  end;
  if SameText(Request.PathInfo, cStatusPath) then begin
    if not SameText(Request.Method, 'GET') then begin
      SendJsonError(Response, 405, 'method_not_allowed');
      Exit;
    end;
    if IsInitialAdminPasswordChangeRequired(BrickStackDatabaseFileName) then
      SendCatalogJson(Response, '{"required":true}')
    else
      SendCatalogJson(Response, '{"required":false}');
    Exit;
  end;

  if not SameText(Request.Method, 'POST') then begin
    SendJsonError(Response, 405, 'method_not_allowed');
    Exit;
  end;
  if Request.GetFieldByName('X-BrickStack-Request') <> '1' then begin
    SendJsonError(Response, 403, 'csrf_check_failed');
    Exit;
  end;
  if (TEncoding.UTF8.GetByteCount(Request.Content) > cMaximumBodyLength) or
    not StartsText('application/json', Request.ContentType) then begin
    SendJsonError(Response, 400, 'invalid_request');
    Exit;
  end;

  var Parsed: TJSONValue;
  try
    Parsed := TJSONObject.ParseJSONValue(Request.Content);
  except
    on Exception do begin
      SendJsonError(Response, 400, 'invalid_request');
      Exit;
    end;
  end;
  try
    if not (Parsed is TJSONObject) then begin
      SendJsonError(Response, 400, 'invalid_request');
      Exit;
    end;
    var Body := TJSONObject(Parsed);
    try
      if ReplaceInitialAdminPassword(BrickStackDatabaseFileName,
        BootstrapJsonField(Body, 'username'),
        BootstrapJsonField(Body, 'currentPassword'),
        BootstrapJsonField(Body, 'newPassword')) then
        SendCatalogJson(Response, '{"status":"password_changed"}')
      else
        SendJsonError(Response, 401, 'invalid_bootstrap_credentials');
    except
      on E: EArgumentException do
        SendJsonError(Response, 400, 'invalid_request');
    end;
  finally
    Parsed.Free;
  end;
end;

function HandleAccountManagementRequest(Request: TWebRequest; Response: TWebResponse): Boolean;
const
  cUsersPath = '/api/admin/users';
  cCookieName = 'BSSESSION';
  cMaximumBodyLength = 4096;
begin
  Result := SameText(Request.PathInfo, cUsersPath);
  if not Result then
    Exit;

  if not IsLoopbackRequest(Request) then begin
    SendJsonError(Response, 403, 'loopback_only');
    Exit;
  end;
  if not SameText(Request.Method, 'GET') and
    not SameText(Request.Method, 'POST') then begin
    SendJsonError(Response, 405, 'method_not_allowed');
    Exit;
  end;
  var SessionToken := Request.CookieFields.Values[cCookieName];
  var User: TAuthenticatedUser;
  if not TryGetSessionUser(BrickStackDatabaseFileName, SessionToken, User) then begin
    SendJsonError(Response, 401, 'authentication_required');
    Exit;
  end;
  if (User.Role <> cRoleGlobalAdmin) or not User.TotpEnabled then begin
    SendJsonError(Response, 403, 'forbidden');
    Exit;
  end;
  if SameText(Request.Method, 'POST') and
    (Request.GetFieldByName('X-BrickStack-Request') <> '1') then begin
    SendJsonError(Response, 403, 'csrf_check_failed');
    Exit;
  end;

  if SameText(Request.Method, 'GET') then begin
    var Accounts := ListUserAccounts(BrickStackDatabaseFileName);
    var Root := TJSONObject.Create;
    try
      var UserArray := TJSONArray.Create;
      for var Account in Accounts do begin
        var UserObject := TJSONObject.Create;
        UserObject.AddPair('id', TJSONNumber.Create(Account.ID));
        UserObject.AddPair('username', JsonString(Account.UserName));
        UserObject.AddPair('displayName', JsonString(Account.DisplayName));
        UserObject.AddPair('role', TJSONNumber.Create(Account.Role));
        UserObject.AddPair('enabled', TJSONBool.Create(Account.IsEnabled));
        UserObject.AddPair('mustChangePassword',
          TJSONBool.Create(Account.MustChangePassword));
        UserArray.AddElement(UserObject);
      end;
      Root.AddPair('users', UserArray);
      Root.AddPair('total', TJSONNumber.Create(Length(Accounts)));
      Response.SetCustomHeader('Cache-Control', 'no-store');
      SendCatalogJson(Response, Root.ToJSON);
    finally
      Root.Free;
    end;
    LogServerMessage('BrickStack2 audit',
      Format('Global Admin %d viewed the user account list (%d accounts).',
        [User.ID, Length(Accounts)]));
    Exit;
  end;

  if (TEncoding.UTF8.GetByteCount(Request.Content) > cMaximumBodyLength) or
    not StartsText('application/json', Request.ContentType) then begin
    SendJsonError(Response, 400, 'invalid_request');
    Exit;
  end;
  var Parsed: TJSONValue;
  try
    Parsed := TJSONObject.ParseJSONValue(Request.Content);
  except
    on Exception do begin
      SendJsonError(Response, 400, 'invalid_request');
      Exit;
    end;
  end;
  try
    if not (Parsed is TJSONObject) then begin
      SendJsonError(Response, 400, 'invalid_request');
      Exit;
    end;
    var Body := TJSONObject(Parsed);
    if Body.GetValue('role') <> nil then begin
      SendJsonError(Response, 400, 'invalid_request');
      Exit;
    end;
    var TemporaryPassword: string;
    var Account: TManagedAccount;
    try
      Account := CreateUserAccount(BrickStackDatabaseFileName,
        BootstrapJsonField(Body, 'username'),
        BootstrapJsonField(Body, 'displayName'), TemporaryPassword);
    except
      on E: EAccountConflict do begin
        SendJsonError(Response, 409, 'username_unavailable');
        Exit;
      end;
    end;
    var Root := TJSONObject.Create;
    try
      var UserObject := TJSONObject.Create;
      UserObject.AddPair('id', TJSONNumber.Create(Account.ID));
      UserObject.AddPair('username', JsonString(Account.UserName));
      UserObject.AddPair('displayName', JsonString(Account.DisplayName));
      UserObject.AddPair('role', TJSONNumber.Create(Account.Role));
      UserObject.AddPair('enabled', TJSONBool.Create(Account.IsEnabled));
      UserObject.AddPair('mustChangePassword',
        TJSONBool.Create(Account.MustChangePassword));
      Root.AddPair('user', UserObject);
      Root.AddPair('temporaryPassword', JsonString(TemporaryPassword));
      Response.SetCustomHeader('Cache-Control', 'no-store');
      Response.SetCustomHeader('Pragma', 'no-cache');
      SendCatalogJson(Response, Root.ToJSON);
    finally
      Root.Free;
    end;
    LogServerMessage('BrickStack2 audit',
      Format('Global Admin %d provisioned user %d.',
        [User.ID, Account.ID]));
  finally
    Parsed.Free;
  end;
end;

function HandleCollectionItemsRequest(Request: TWebRequest;
  Response: TWebResponse): Boolean;
const
  cMaximumBodyLength = 4096;
  cCookieName = 'BSSESSION';
begin
  var RecordID: Integer;
  var Route := ParseCollectionItemsRoute(Request.PathInfo, RecordID);
  Result := Route <> cirNone;
  if not Result then
    Exit;

  if not IsLoopbackRequest(Request) then begin
    SendJsonError(Response, 403, 'loopback_only');
    Exit;
  end;
  var MethodAllowed :=
    ((Route = cirCollectionSetLists) and
      (SameText(Request.Method, 'GET') or SameText(Request.Method, 'POST'))) or
    ((Route = cirSetList) and
      (SameText(Request.Method, 'GET') or SameText(Request.Method, 'PUT') or
       SameText(Request.Method, 'DELETE'))) or
    ((Route = cirSetListSets) and
      (SameText(Request.Method, 'GET') or SameText(Request.Method, 'POST'))) or
    ((Route = cirCollectionSet) and
      (SameText(Request.Method, 'GET') or SameText(Request.Method, 'PUT') or
       SameText(Request.Method, 'DELETE')));
  if not MethodAllowed then begin
    SendJsonError(Response, 405, 'method_not_allowed');
    Exit;
  end;

  var SessionToken := Request.CookieFields.Values[cCookieName];
  var User: TAuthenticatedUser;
  if not TryGetSessionUser(BrickStackDatabaseFileName, SessionToken, User) then begin
    SendJsonError(Response, 401, 'authentication_required');
    Exit;
  end;
  if not (User.Role in [cRoleGlobalAdmin, cRoleUser]) then begin
    SendJsonError(Response, 403, 'forbidden');
    Exit;
  end;
  if Request.Query <> '' then begin
    SendJsonError(Response, 400, 'invalid_request');
    Exit;
  end;
  var IsMutation := SameText(Request.Method, 'POST') or
    SameText(Request.Method, 'PUT') or SameText(Request.Method, 'DELETE');
  if IsMutation and
    (Request.GetFieldByName('X-BrickStack-Request') <> '1') then begin
    SendJsonError(Response, 403, 'csrf_check_failed');
    Exit;
  end;
  Response.SetCustomHeader('Cache-Control', 'no-store');

  var Repository := TUserCollectionRepository.Create(
    BrickStackDatabaseFileName);
  try
    if SameText(Request.Method, 'GET') then begin
      if Route = cirCollectionSetLists then begin
        var Collection: TUserCollection;
        if not Repository.TryGetForUser(User.ID, RecordID, Collection) or
          (Collection.ID <> RecordID) then begin
          SendJsonError(Response, 404, 'not_found');
          Exit;
        end;
        var SetLists := Repository.ListSetListsForUser(User.ID, RecordID);
        var Root := TJSONObject.Create;
        try
          var Items := TJSONArray.Create;
          for var SetList in SetLists do begin
            var Item := TJSONObject.Create;
            AddSetListJson(Item, SetList);
            Items.AddElement(Item);
          end;
          Root.AddPair('setLists', Items);
          SendCatalogJson(Response, Root.ToJSON);
        finally
          Root.Free;
        end;
        Exit;
      end;
      if Route = cirSetList then begin
        var SetList: TUserSetList;
        if not Repository.TryGetSetListForUser(User.ID, RecordID, SetList) or
          (SetList.ID <> RecordID) then begin
          SendJsonError(Response, 404, 'not_found');
          Exit;
        end;
        var Item := TJSONObject.Create;
        try
          AddSetListJson(Item, SetList);
          SendCatalogJson(Response, Item.ToJSON);
        finally
          Item.Free;
        end;
        Exit;
      end;
      if Route = cirSetListSets then begin
        var SetList: TUserSetList;
        if not Repository.TryGetSetListForUser(User.ID, RecordID, SetList) or
          (SetList.ID <> RecordID) then begin
          SendJsonError(Response, 404, 'not_found');
          Exit;
        end;
        var Sets := Repository.ListSetsForUser(User.ID, RecordID);
        var Root := TJSONObject.Create;
        try
          var Items := TJSONArray.Create;
          for var CollectionSet in Sets do begin
            var Item := TJSONObject.Create;
            AddCollectionSetJson(Item, CollectionSet);
            Items.AddElement(Item);
          end;
          Root.AddPair('sets', Items);
          SendCatalogJson(Response, Root.ToJSON);
        finally
          Root.Free;
        end;
        Exit;
      end;
      var CollectionSet: TCollectionSet;
      if not Repository.TryGetSetForUser(User.ID, RecordID, CollectionSet) then begin
        SendJsonError(Response, 404, 'not_found');
        Exit;
      end;
      var Item := TJSONObject.Create;
      try
        AddCollectionSetJson(Item, CollectionSet);
        SendCatalogJson(Response, Item.ToJSON);
      finally
        Item.Free;
      end;
      Exit;
    end;

    if SameText(Request.Method, 'DELETE') then begin
      var Deleted := False;
      if Route = cirSetList then
        Deleted := Repository.DeleteSetListForUser(User.ID, RecordID)
      else if Route = cirCollectionSet then
        Deleted := Repository.DeleteSetForUser(User.ID, RecordID);
      if not Deleted then begin
        SendJsonError(Response, 404, 'not_found');
        Exit;
      end;
      SendCatalogJson(Response, '{"deleted":true}');
      Exit;
    end;

    if (TEncoding.UTF8.GetByteCount(Request.Content) > cMaximumBodyLength) or
      not StartsText('application/json', Request.ContentType) then begin
      SendJsonError(Response, 400, 'invalid_request');
      Exit;
    end;
    var Parsed: TJSONValue;
    try
      Parsed := TJSONObject.ParseJSONValue(Request.Content);
    except
      on Exception do begin
        SendJsonError(Response, 400, 'invalid_request');
        Exit;
      end;
    end;
    try
      if not (Parsed is TJSONObject) then begin
        SendJsonError(Response, 400, 'invalid_request');
        Exit;
      end;
      var Body := TJSONObject(Parsed);
      if Route in [cirCollectionSetLists, cirSetList] then begin
        if (Body.Count <> 3) or
          not (Body.GetValue('name') is TJSONString) or
          not (Body.GetValue('description') is TJSONString) or
          not (Body.GetValue('useInCollection') is TJSONBool) then begin
          SendJsonError(Response, 400, 'invalid_request');
          Exit;
        end;
        var Name := Body.GetValue('name').Value;
        var Description := Body.GetValue('description').Value;
        var UseInCollection := TJSONBool(
          Body.GetValue('useInCollection')).AsBoolean;
        try
          var SetList: TUserSetList;
          if Route = cirCollectionSetLists then
            SetList := Repository.CreateSetListForUser(User.ID, RecordID,
              Name, Description, UseInCollection)
          else begin
            if not Repository.UpdateSetListForUser(User.ID, RecordID,
              Name, Description, UseInCollection) then begin
              SendJsonError(Response, 404, 'not_found');
              Exit;
            end;
            if not Repository.TryGetSetListForUser(User.ID, RecordID,
              SetList) then begin
              SendJsonError(Response, 404, 'not_found');
              Exit;
            end;
          end;
          var SetListObject := TJSONObject.Create;
          try
            AddSetListJson(SetListObject, SetList);
            SendCatalogJson(Response, SetListObject.ToJSON);
            if Route = cirCollectionSetLists then
              Response.StatusCode := 201;
          finally
            SetListObject.Free;
          end;
        except
          on E: ECollectionItemNotFound do begin
            SendJsonError(Response, 404, 'not_found');
            Exit;
          end;
          on E: EArgumentException do begin
            SendJsonError(Response, 400, 'invalid_request');
            Exit;
          end;
        end;
        Exit;
      end;

      var SetNumber: string;
      var Built: Boolean;
      var HaveSpareParts: Boolean;
      var Notes: string;
      var CatalogSet: TCatalogSet;
      if Route = cirSetListSets then begin
        if (Body.Count <> 4) or
          not (Body.GetValue('setNumber') is TJSONString) or
          not (Body.GetValue('built') is TJSONBool) or
          not (Body.GetValue('haveSpareParts') is TJSONBool) or
          not (Body.GetValue('notes') is TJSONString) then begin
          SendJsonError(Response, 400, 'invalid_request');
          Exit;
        end;
        SetNumber := Body.GetValue('setNumber').Value;
        Built := TJSONBool(Body.GetValue('built')).AsBoolean;
        HaveSpareParts :=
          TJSONBool(Body.GetValue('haveSpareParts')).AsBoolean;
        Notes := Body.GetValue('notes').Value;
        var OwnedSetList: TUserSetList;
        if not Repository.TryGetSetListForUser(User.ID, RecordID,
          OwnedSetList) or (OwnedSetList.ID <> RecordID) then begin
          SendJsonError(Response, 404, 'not_found');
          Exit;
        end;
        var CatalogRepository := TRebrickableCatalogRepository.Create(
          CatalogDatabaseFileName);
        try
          if not CatalogRepository.TryGetSet(SetNumber, CatalogSet) then begin
            SendJsonError(Response, 404, 'not_found');
            Exit;
          end;
        finally
          CatalogRepository.Free;
        end;
        try
          var CollectionSet := Repository.CreateSetForUser(User.ID, RecordID,
            CatalogSet.SetNumber, Built, HaveSpareParts, Notes);
          var SetObject := TJSONObject.Create;
          try
            AddCollectionSetJson(SetObject, CollectionSet);
            SendCatalogJson(Response, SetObject.ToJSON);
            Response.StatusCode := 201;
          finally
            SetObject.Free;
          end;
        except
          on E: ECollectionItemNotFound do begin
            SendJsonError(Response, 404, 'not_found');
            Exit;
          end;
          on E: EArgumentException do begin
            SendJsonError(Response, 400, 'invalid_request');
            Exit;
          end;
        end;
        Exit;
      end;

      if (Body.Count <> 3) or
        not (Body.GetValue('built') is TJSONBool) or
        not (Body.GetValue('haveSpareParts') is TJSONBool) or
        not (Body.GetValue('notes') is TJSONString) then begin
        SendJsonError(Response, 400, 'invalid_request');
        Exit;
      end;
      Built := TJSONBool(Body.GetValue('built')).AsBoolean;
      HaveSpareParts :=
        TJSONBool(Body.GetValue('haveSpareParts')).AsBoolean;
      Notes := Body.GetValue('notes').Value;
      try
        if not Repository.UpdateSetForUser(User.ID, RecordID, Built,
          HaveSpareParts, Notes) then begin
          SendJsonError(Response, 404, 'not_found');
          Exit;
        end;
        var CollectionSet: TCollectionSet;
        if not Repository.TryGetSetForUser(User.ID, RecordID, CollectionSet) then begin
          SendJsonError(Response, 404, 'not_found');
          Exit;
        end;
        var SetObject := TJSONObject.Create;
        try
          AddCollectionSetJson(SetObject, CollectionSet);
          SendCatalogJson(Response, SetObject.ToJSON);
        finally
          SetObject.Free;
        end;
      except
        on E: EArgumentException do
          SendJsonError(Response, 400, 'invalid_request');
      end;
    finally
      Parsed.Free;
    end;
  finally
    Repository.Free;
  end;
end;

function HandleCollectionRequest(Request: TWebRequest; Response: TWebResponse): Boolean;
const
  cCollectionsPath = '/api/collections';
  cCollectionPathPrefix = '/api/collections/';
  cCookieName = 'BSSESSION';
  cMaximumBodyLength = 4096;
begin
  Result := SameText(Request.PathInfo, cCollectionsPath) or
    StartsText(cCollectionPathPrefix, Request.PathInfo);
  if not Result then
    Exit;

  if not IsLoopbackRequest(Request) then begin
    SendJsonError(Response, 403, 'loopback_only');
    Exit;
  end;
  if not SameText(Request.Method, 'GET') and
    not SameText(Request.Method, 'POST') and
    not SameText(Request.Method, 'PUT') then begin
    SendJsonError(Response, 405, 'method_not_allowed');
    Exit;
  end;
  if SameText(Request.Method, 'POST') and
    not SameText(Request.PathInfo, cCollectionsPath) then begin
    SendJsonError(Response, 405, 'method_not_allowed');
    Exit;
  end;
  if SameText(Request.Method, 'PUT') and
    (not StartsText(cCollectionPathPrefix, Request.PathInfo) or
      SameText(Request.PathInfo, cCollectionsPath)) then begin
    SendJsonError(Response, 405, 'method_not_allowed');
    Exit;
  end;

  var SessionToken := Request.CookieFields.Values[cCookieName];
  var User: TAuthenticatedUser;
  if not TryGetSessionUser(BrickStackDatabaseFileName, SessionToken, User) then begin
    SendJsonError(Response, 401, 'authentication_required');
    Exit;
  end;
  if Request.Query <> '' then begin
    SendJsonError(Response, 400, 'invalid_request');
    Exit;
  end;
  if not (User.Role in [cRoleGlobalAdmin, cRoleUser]) then begin
    SendJsonError(Response, 403, 'forbidden');
    Exit;
  end;
  if (SameText(Request.Method, 'POST') or SameText(Request.Method, 'PUT')) and
    (Request.GetFieldByName('X-BrickStack-Request') <> '1') then begin
    SendJsonError(Response, 403, 'csrf_check_failed');
    Exit;
  end;

  Response.SetCustomHeader('Cache-Control', 'no-store');
  var Repository := TUserCollectionRepository.Create(
    BrickStackDatabaseFileName);
  try
    if SameText(Request.Method, 'GET') then begin
      if SameText(Request.PathInfo, cCollectionsPath) then begin
        var Collections := Repository.ListForUser(User.ID);
        var Root := TJSONObject.Create;
        try
          var CollectionArray := TJSONArray.Create;
          for var Collection in Collections do begin
            var Item := TJSONObject.Create;
            Item.AddPair('id', TJSONNumber.Create(Collection.ID));
            Item.AddPair('name', JsonString(Collection.Name));
            Item.AddPair('isPublic', TJSONBool.Create(Collection.IsPublic));
            CollectionArray.AddElement(Item);
          end;
          Root.AddPair('collections', CollectionArray);
          SendCatalogJson(Response, Root.ToJSON);
        finally
          Root.Free;
        end;
        Exit;
      end;

      var CollectionIDText := Copy(Request.PathInfo,
        Length(cCollectionPathPrefix) + 1, MaxInt);
      var CollectionID: Integer;
      if not TryStrToInt(CollectionIDText, CollectionID) or
        (CollectionID < 1) then begin
        SendJsonError(Response, 404, 'not_found');
        Exit;
      end;
      var OwnedCollection: TUserCollection;
      if not Repository.TryGetForUser(User.ID, CollectionID, OwnedCollection) then begin
        SendJsonError(Response, 404, 'not_found');
        Exit;
      end;
      var CollectionObject := TJSONObject.Create;
      try
        CollectionObject.AddPair('id', TJSONNumber.Create(OwnedCollection.ID));
        CollectionObject.AddPair('name', JsonString(OwnedCollection.Name));
        CollectionObject.AddPair('isPublic', TJSONBool.Create(OwnedCollection.IsPublic));
        SendCatalogJson(Response, CollectionObject.ToJSON);
      finally
        CollectionObject.Free;
      end;
      Exit;
    end;

    if (TEncoding.UTF8.GetByteCount(Request.Content) > cMaximumBodyLength) or
      not StartsText('application/json', Request.ContentType) then begin
      SendJsonError(Response, 400, 'invalid_request');
      Exit;
    end;
    var Parsed: TJSONValue;
    try
      Parsed := TJSONObject.ParseJSONValue(Request.Content);
    except
      on Exception do begin
        SendJsonError(Response, 400, 'invalid_request');
        Exit;
      end;
    end;
    try
      if not (Parsed is TJSONObject) then begin
        SendJsonError(Response, 400, 'invalid_request');
        Exit;
      end;
      var Body := TJSONObject(Parsed);
      if SameText(Request.Method, 'PUT') then begin
        if Body.Count <> 1 then begin
          SendJsonError(Response, 400, 'invalid_request');
          Exit;
        end;
        var CollectionIDText := Copy(Request.PathInfo,
          Length(cCollectionPathPrefix) + 1, MaxInt);
        var CollectionID: Integer;
        if not TryStrToInt(CollectionIDText, CollectionID) or
          (CollectionID < 1) then begin
          SendJsonError(Response, 404, 'not_found');
          Exit;
        end;
        var NameValue := Body.GetValue('name');
        if not (NameValue is TJSONString) then begin
          SendJsonError(Response, 400, 'invalid_request');
          Exit;
        end;
        var RenamedCollection: TUserCollection;
        try
          if not Repository.RenameForUser(User.ID, CollectionID,
            NameValue.Value, RenamedCollection) then begin
            SendJsonError(Response, 404, 'not_found');
            Exit;
          end;
        except
          on E: ECollectionConflict do begin
            SendJsonError(Response, 409, 'collection_name_unavailable');
            Exit;
          end;
          on E: EArgumentException do begin
            SendJsonError(Response, 400, 'invalid_request');
            Exit;
          end;
        end;
        var CollectionObject := TJSONObject.Create;
        try
          CollectionObject.AddPair('id', TJSONNumber.Create(RenamedCollection.ID));
          CollectionObject.AddPair('name', JsonString(RenamedCollection.Name));
          CollectionObject.AddPair('isPublic', TJSONBool.Create(RenamedCollection.IsPublic));
          SendCatalogJson(Response, CollectionObject.ToJSON);
        finally
          CollectionObject.Free;
        end;
        Exit;
      end;
      if (Body.GetValue('userId') <> nil) or
        (Body.GetValue('ownerId') <> nil) then begin
        SendJsonError(Response, 400, 'invalid_request');
        Exit;
      end;
      var NameValue := Body.GetValue('name');
      if not (NameValue is TJSONString) then begin
        SendJsonError(Response, 400, 'invalid_request');
        Exit;
      end;
      var NewCollection: TUserCollection;
      try
        NewCollection := Repository.CreateForUser(User.ID, NameValue.Value);
      except
        on E: ECollectionConflict do begin
          SendJsonError(Response, 409, 'collection_name_unavailable');
          Exit;
        end;
        on E: EArgumentException do begin
          SendJsonError(Response, 400, 'invalid_request');
          Exit;
        end;
      end;
      var CollectionObject := TJSONObject.Create;
      try
        CollectionObject.AddPair('id', TJSONNumber.Create(NewCollection.ID));
        CollectionObject.AddPair('name', JsonString(NewCollection.Name));
        CollectionObject.AddPair('isPublic', TJSONBool.Create(NewCollection.IsPublic));
        SendCatalogJson(Response, CollectionObject.ToJSON);
        Response.StatusCode := 201;
      finally
        CollectionObject.Free;
      end;
    finally
      Parsed.Free;
    end;
  finally
    Repository.Free;
  end;
end;

function HandleCatalogRequest(Request: TWebRequest; Response: TWebResponse): Boolean;
begin
  var Path := Request.PathInfo;
  var Identifier: string;
  Result := StartsText('/api/catalog/', Path);
  if not Result then
    Exit;
  if Length(Request.Query) > cMaximumCatalogQueryLength then
    raise EArgumentException.Create('Catalog query string is too long.');

  var Repository := TRebrickableCatalogRepository.Create(CatalogDatabaseFileName);
  try
    if SameText(Path, '/api/catalog/summary') then begin
      var Summary := Repository.GetSummary;
      var SummaryObject := TJSONObject.Create;
      try
        SummaryObject.AddPair('sets', TJSONNumber.Create(Summary.SetCount));
        SummaryObject.AddPair('parts', TJSONNumber.Create(Summary.PartCount));
        SummaryObject.AddPair('themes', TJSONNumber.Create(Summary.ThemeCount));
        SendCatalogJson(Response, SummaryObject.ToJSON);
      finally
        SummaryObject.Free;
      end;
    end else if SameText(Path, '/api/catalog/sets') then begin
      var SearchText := Request.QueryFields.Values['q'];
      var ThemeID := ReadOptionalInteger(Request, 'themeId', 0);
      var Year := ReadOptionalInteger(Request, 'year', 0);
      var PageSize := ReadPageSize(Request);
      var Cursor := Request.QueryFields.Values['cursor'];
      var SetPage := Repository.SearchSets(SearchText, ThemeID, Year, PageSize, Cursor);
      SendCatalogJson(Response, SetPageJson(SetPage));
    end else if SetInventoryRouteIdentifier(Path, Identifier) then begin
      var PageSize := ReadPageSize(Request);
      var InventoryVersion := ReadOptionalInteger(Request, 'version', 0);
      var Cursor := Request.QueryFields.Values['cursor'];
      var InventoryPage: TCatalogInventoryPage;
      if Repository.TryGetSetInventory(Identifier, InventoryVersion, PageSize,
        Cursor, InventoryPage) then
        SendCatalogJson(Response, InventoryPageJson(InventoryPage))
      else
        SendJsonError(Response, 404, 'inventory_not_found');
    end else if RouteIdentifier(Path, '/api/catalog/sets/', Identifier) then begin
      var CatalogSet: TCatalogSet;
      if Repository.TryGetSet(Identifier, CatalogSet) then begin
        var Item := TJSONObject.Create;
        try
          AddSetJson(Item, CatalogSet);
          SendCatalogJson(Response, Item.ToJSON);
        finally
          Item.Free;
        end;
      end else
        SendJsonError(Response, 404, 'not_found');
    end else if SameText(Path, '/api/catalog/parts') then begin
      var SearchText := Request.QueryFields.Values['q'];
      var CategoryID := ReadOptionalInteger(Request, 'categoryId', 0);
      var ColorID := ReadOptionalInteger(Request, 'colorId', 0);
      var PageSize := ReadPageSize(Request);
      var Cursor := Request.QueryFields.Values['cursor'];
      var PartPage := Repository.SearchParts(SearchText, CategoryID, ColorID,
        PageSize, Cursor);
      SendCatalogJson(Response, PartPageJson(PartPage));
    end else if RouteIdentifier(Path, '/api/catalog/parts/', Identifier) then begin
      var CatalogPart: TCatalogPart;
      if Repository.TryGetPart(Identifier, CatalogPart) then begin
        var Item := TJSONObject.Create;
        try
          AddPartJson(Item, CatalogPart);
          SendCatalogJson(Response, Item.ToJSON);
        finally
          Item.Free;
        end;
      end else
        SendJsonError(Response, 404, 'not_found');
    end else if SameText(Path, '/api/catalog/themes') then begin
      var Themes := Repository.GetThemes;
      var Root := TJSONArray.Create;
      try
        for var Theme in Themes do begin
          var Item := TJSONObject.Create;
          Item.AddPair('id', TJSONNumber.Create(Theme.ID));
          Item.AddPair('name', JsonString(Theme.Name));
          if Theme.HasParent then
            Item.AddPair('parentId', TJSONNumber.Create(Theme.ParentID))
          else
            Item.AddPair('parentId', TJSONNull.Create);
          Root.AddElement(Item);
        end;
        SendCatalogJson(Response, Root.ToJSON);
      finally
        Root.Free;
      end;
    end else if SameText(Path, '/api/catalog/colors') then begin
      var Colors := Repository.GetColors;
      var Root := TJSONArray.Create;
      try
        for var Color in Colors do begin
          var Item := TJSONObject.Create;
          Item.AddPair('id', TJSONNumber.Create(Color.ID));
          Item.AddPair('name', JsonString(Color.Name));
          Item.AddPair('rgb', JsonString(Color.RGB));
          Item.AddPair('isTransparent', TJSONBool.Create(Color.IsTransparent));
          Root.AddElement(Item);
        end;
        SendCatalogJson(Response, Root.ToJSON);
      finally
        Root.Free;
      end;
    end else if SameText(Path, '/api/catalog/part-categories') then begin
      var Categories := Repository.GetPartCategories;
      var Root := TJSONArray.Create;
      try
        for var Category in Categories do begin
          var Item := TJSONObject.Create;
          Item.AddPair('id', TJSONNumber.Create(Category.ID));
          Item.AddPair('name', JsonString(Category.Name));
          Root.AddElement(Item);
        end;
        SendCatalogJson(Response, Root.ToJSON);
      finally
        Root.Free;
      end;
    end else
      SendJsonError(Response, 404, 'not_found');
  finally
    Repository.Free;
  end;
end;

constructor TBackendWebModule.Create(AOwner: TComponent);
var
  Action: TWebActionItem;
begin
  inherited Create(AOwner);
  Action := Actions.Add;
  Action.Name := 'Dispatch';
  Action.Default := True;
  Action.OnAction := HandleRequest;
end;

procedure TBackendWebModule.HandleRequest(Sender: TObject; Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
begin
  Handled := True;
  var CollectionItemsID: Integer;
  var CollectionItemsRoute := ParseCollectionItemsRoute(Request.PathInfo,
    CollectionItemsID);
  var HasValidCollectionItemsID := CollectionItemsID > 0;
  var IsAllowedPost := SameText(Request.Method, 'POST') and
    (SameText(Request.PathInfo, '/api/auth/bootstrap/password') or
     SameText(Request.PathInfo, '/api/auth/login') or
     SameText(Request.PathInfo, '/api/auth/password') or
     SameText(Request.PathInfo, '/api/auth/totp/enroll/start') or
     SameText(Request.PathInfo, '/api/auth/totp/enroll/confirm') or
     SameText(Request.PathInfo, '/api/auth/logout') or
     SameText(Request.PathInfo, '/api/collections') or
     SameText(Request.PathInfo, '/api/admin/users') or
     (CollectionItemsRoute in [cirCollectionSetLists, cirSetListSets]) and
     HasValidCollectionItemsID);
  var IsAllowedPut := SameText(Request.Method, 'PUT') and
    (StartsText('/api/collections/', Request.PathInfo) or
     (CollectionItemsRoute = cirSetList) or
     (CollectionItemsRoute = cirCollectionSet)) and
    (not (CollectionItemsRoute in [cirSetList, cirCollectionSet]) or
      HasValidCollectionItemsID);
  var IsAllowedDelete := SameText(Request.Method, 'DELETE') and
    (CollectionItemsRoute in [cirSetList, cirCollectionSet]) and
    HasValidCollectionItemsID;
  if not SameText(Request.Method, 'GET') and not IsAllowedPost and
    not IsAllowedPut and not IsAllowedDelete then begin
    LogServerMessage('BrickStack2 backend',
      Request.Method + ' ' + Request.PathInfo + ' -> 405');
    Response.StatusCode := 405;
    Response.ContentType := 'application/json; charset=utf-8';
    Response.Content := '{"error":"method_not_allowed"}';
    Exit;
  end;

  if SameText(Request.PathInfo, '/health') then begin
    Response.ContentType := 'application/json; charset=utf-8';
    Response.Content := '{"status":"ok","service":"backend"}';
    LogServerMessage('BrickStack2 backend', 'GET /health -> 200');
    Exit;
  end;

  if SameText(Request.PathInfo, '/api/demo') then begin
    Response.ContentType := 'application/json; charset=utf-8';
    Response.Content := BuildDemoJson;
    LogServerMessage('BrickStack2 backend', 'GET /api/demo -> 200');
    Exit;
  end;

  try
    if HandleBootstrapRequest(Request, Response) then begin
      LogServerMessage('BrickStack2 backend',
        Request.Method + ' ' + Request.PathInfo + ' -> ' +
        IntToStr(Response.StatusCode));
      Exit;
    end;
    if HandleAccountManagementRequest(Request, Response) then begin
      LogServerMessage('BrickStack2 backend',
        Request.Method + ' ' + Request.PathInfo + ' -> ' +
        IntToStr(Response.StatusCode));
      Exit;
    end;
    if HandleCollectionItemsRequest(Request, Response) then begin
      LogServerMessage('BrickStack2 backend',
        Request.Method + ' ' + Request.PathInfo + ' -> ' +
        IntToStr(Response.StatusCode));
      Exit;
    end;
    if HandleCollectionRequest(Request, Response) then begin
      LogServerMessage('BrickStack2 backend',
        Request.Method + ' ' + Request.PathInfo + ' -> ' +
        IntToStr(Response.StatusCode));
      Exit;
    end;
    if HandleCatalogRequest(Request, Response) then begin
      LogServerMessage('BrickStack2 backend',
        'GET ' + Request.PathInfo + ' -> ' +
        IntToStr(Response.StatusCode));
      Exit;
    end;
  except
    on E: EArgumentException do begin
      SendJsonError(Response, 400, 'invalid_request');
      LogServerMessage('BrickStack2 backend',
        Request.Method + ' ' + Request.PathInfo + ' -> 400 (' +
        E.Message + ')');
      Exit;
    end;
    on E: Exception do begin
      SendJsonError(Response, 500, 'internal_error');
      LogServerMessage('BrickStack2 backend',
        'GET ' + Request.PathInfo + ' failed (' + E.ClassName + '): ' +
        E.Message);
      Exit;
    end;
  end;

  LogServerMessage('BrickStack2 backend',
    Request.Method + ' ' + Request.PathInfo + ' -> 404');
  Response.StatusCode := 404;
  Response.ContentType := 'application/json; charset=utf-8';
  Response.Content := '{"error":"not_found"}';
end;

end.
