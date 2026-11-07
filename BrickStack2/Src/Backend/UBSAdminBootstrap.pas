unit UBSAdminBootstrap;

interface

uses
  System.SysUtils;

type
  TAuthenticatedUser = record
    ID: Integer;
    UserName: string;
    DisplayName: string;
    Role: Integer;
    TotpEnabled: Boolean;
  end;

  TManagedAccount = record
    ID: Integer;
    UserName: string;
    DisplayName: string;
    Role: Integer;
    IsEnabled: Boolean;
    MustChangePassword: Boolean;
  end;
  TManagedAccounts = array of TManagedAccount;

const
  cRoleGlobalAdmin = 0;
  cRoleUser = 1;

type
  EAccountConflict = class(Exception);

procedure EnsureInitialAdmin(const ADatabaseFileName: string);
function CreateUserAccount(const ADatabaseFileName, AUserName, ADisplayName: string; out ATemporaryPassword: string): TManagedAccount;
function ListUserAccounts(const ADatabaseFileName: string): TManagedAccounts;
function IsInitialAdminPasswordChangeRequired(const ADatabaseFileName: string): Boolean;
function ReplaceInitialAdminPassword(const ADatabaseFileName, AUserName, ACurrentPassword, ANewPassword: string): Boolean;
function ReplaceRequiredUserPassword(const ADatabaseFileName, AUserName, ACurrentPassword, ANewPassword: string): Boolean;
function AuthenticateAndCreateSession(const ADatabaseFileName, AUserName,
  APassword: string; out AUser: TAuthenticatedUser;
  out ASessionToken: string): Boolean; overload;
function AuthenticateAndCreateSession(const ADatabaseFileName, AUserName,
  APassword, ATotpCode, ARecoveryCode: string; out AUser: TAuthenticatedUser;
  out ASessionToken: string; out ATotpRequired: Boolean): Boolean; overload;
function TryGetSessionUser(const ADatabaseFileName, ASessionToken: string; out AUser: TAuthenticatedUser): Boolean;
function StartTotpEnrollment(const ADatabaseFileName, ASessionToken: string; out ASecret, AProvisioningUri: string): Boolean;
function ConfirmTotpEnrollment(const ADatabaseFileName, ASessionToken, ACode: string; out ARecoveryCodes: TArray<string>): Boolean;
procedure RevokeSession(const ADatabaseFileName, ASessionToken: string);

implementation

uses
  Winapi.Windows,
  System.Classes,
  System.IOUtils,
  System.Hash,
  System.DateUtils,
  System.RegularExpressions,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  UBSTotp;

const
  cInitialAdminName = 'Admin';
  cInitialAdminPassword = 'Admin';
  cPasswordAlgorithm = 'PBKDF2-HMAC-SHA256-600000';
  cPasswordIterations = 600000;
  cSaltLength = 16;
  cHashLength = 32;
  cMinimumPasswordLength = 12;
  cMaximumPasswordLength = 128;
  cSessionLifetimeSeconds = 43200;
  cLoginWindowSeconds = 900;
  cMaximumLoginFailures = 5;
  cLoginLockSeconds = 900;
  cTotpEnrollmentLifetimeSeconds = 600;
  cRecoveryCodeCount = 10;
  cBCryptHmacFlag = $00000008;
  cBCryptUseSystemPreferredRng = $00000002;
  cBCryptSHA256Algorithm = 'SHA256';

type
  TBcryptOpenAlgorithmProvider = function(out Algorithm: Pointer;
    AlgorithmID, AImplementation: PWideChar; Flags: ULONG): LongInt; stdcall;
  TBcryptDeriveKeyPBKDF2 = function(Algorithm: Pointer; Password: PByte;
    PasswordLength: ULONG; Salt: PByte; SaltLength: ULONG;
    Iterations: UInt64; DerivedKey: PByte; DerivedKeyLength,
    Flags: ULONG): LongInt; stdcall;
  TBcryptGenRandom = function(Algorithm: Pointer; Buffer: PByte;
    BufferLength, Flags: ULONG): LongInt; stdcall;
  TBcryptCloseAlgorithmProvider = function(Algorithm: Pointer;
    Flags: ULONG): LongInt; stdcall;

function GetPasswordHash(const APassword: string; const ASalt: TBytes): TBytes;
begin
  var LibraryHandle := LoadLibrary('bcrypt.dll');
  if LibraryHandle = 0 then
    RaiseLastOSError;
  try
    var OpenProvider: TBcryptOpenAlgorithmProvider := TBcryptOpenAlgorithmProvider(GetProcAddress(LibraryHandle, 'BCryptOpenAlgorithmProvider'));
    var DeriveKey: TBcryptDeriveKeyPBKDF2 := TBcryptDeriveKeyPBKDF2(GetProcAddress(LibraryHandle, 'BCryptDeriveKeyPBKDF2'));
    var CloseProvider: TBcryptCloseAlgorithmProvider := TBcryptCloseAlgorithmProvider(GetProcAddress(LibraryHandle, 'BCryptCloseAlgorithmProvider'));
    if not (Assigned(OpenProvider) and Assigned(DeriveKey) and
      Assigned(CloseProvider)) then
      raise Exception.Create('Windows password hashing is unavailable.');

    var Algorithm: Pointer := nil;
    var Status: LongInt := OpenProvider(Algorithm, PWideChar(cBCryptSHA256Algorithm), nil, cBCryptHmacFlag);
    if Status < 0 then
      raise Exception.CreateFmt(
        'Windows password hashing provider failed (0x%.8x).',
        [Cardinal(Status)]);
    try
      var PasswordBytes := TEncoding.UTF8.GetBytes(APassword);
      SetLength(Result, cHashLength);
      if Length(PasswordBytes) = 0 then
        Status := DeriveKey(Algorithm, nil, 0, @ASalt[0], Length(ASalt),
          cPasswordIterations, @Result[0], Length(Result), 0)
      else
        Status := DeriveKey(Algorithm, @PasswordBytes[0],
          Length(PasswordBytes), @ASalt[0], Length(ASalt),
          cPasswordIterations, @Result[0], Length(Result), 0);
      if Status < 0 then
        raise Exception.CreateFmt(
          'Windows password hashing failed (0x%.8x).', [Cardinal(Status)]);
    finally
      CloseProvider(Algorithm, 0);
    end;
  finally
    FreeLibrary(LibraryHandle);
  end;
end;

function GenerateRandomBytes(ALength: Integer): TBytes;
begin
  var LibraryHandle := LoadLibrary('bcrypt.dll');
  if LibraryHandle = 0 then
    RaiseLastOSError;
  try
    var GenerateRandom: TBcryptGenRandom := TBcryptGenRandom(GetProcAddress(LibraryHandle, 'BCryptGenRandom'));
    if not Assigned(GenerateRandom) then
      raise Exception.Create('Windows secure random generator is unavailable.');
    SetLength(Result, ALength);
    var Status: LongInt := GenerateRandom(nil, @Result[0], Length(Result), cBCryptUseSystemPreferredRng);
    if Status < 0 then
      raise Exception.CreateFmt(
        'Windows secure random generation failed (0x%.8x).',
        [Cardinal(Status)]);
  finally
    FreeLibrary(LibraryHandle);
  end;
end;

function GenerateSalt: TBytes;
begin
  Result := GenerateRandomBytes(cSaltLength);
end;

function BytesToHex(const ABytes: TBytes): string;
begin
  Result := '';
  for var I := 0 to High(ABytes) do
    Result := Result + IntToHex(ABytes[I], 2);
end;

function HexToBytes(const AHex: string): TBytes;
begin
  if (Length(AHex) = 0) or Odd(Length(AHex)) then
    raise EArgumentException.Create('Stored password data is invalid.');
  SetLength(Result, Length(AHex) div 2);
  for var I := 0 to High(Result) do begin
    var Value: Integer;
    if not TryStrToInt('$' + Copy(AHex, I * 2 + 1, 2), Value) then
      raise EArgumentException.Create('Stored password data is invalid.');
    Result[I] := Byte(Value);
  end;
end;

function ConstantTimeEquals(const ALeft, ARight: TBytes): Boolean;
begin
  if Length(ALeft) <> Length(ARight) then
    Exit(False);
  var Difference: Byte := 0;
  for var I := 0 to High(ALeft) do
    Difference := Difference or (ALeft[I] xor ARight[I]);
  Result := Difference = 0;
end;

function IsPasswordValid(const APassword, AHash, ASalt, AAlgorithm: string): Boolean;
begin
  Result := False;
  if not SameText(AAlgorithm, cPasswordAlgorithm) then
    Exit;
  var SaltBytes := HexToBytes(ASalt);
  var ExpectedHash := HexToBytes(AHash);
  var ActualHash := GetPasswordHash(APassword, SaltBytes);
  Result := ConstantTimeEquals(ExpectedHash, ActualHash);
end;

function NewConnection(const ADatabaseFileName: string): TFDConnection;
begin
  Result := TFDConnection.Create(nil);
  try
    Result.LoginPrompt := False;
    Result.DriverName := 'SQLite';
    Result.Params.Database := ADatabaseFileName;
    Result.Params.Values['ForeignKeys'] := 'Yes';
    Result.Connected := True;
  except
    Result.Free;
    raise;
  end;
end;

function CurrentUnixTime: Int64;
begin
  Result := DateTimeToUnix(Now);
end;

function SHA256Hex(const AValue: string): string;
begin
  var Hash := THashSHA2.Create(SHA256);
  var Stream := TStringStream.Create(AValue, TEncoding.UTF8);
  try
    Result := THash.DigestAsString(Hash.GetHashBytes(Stream));
  finally
    Stream.Free;
  end;
end;

procedure EnsureInitialAdmin(const ADatabaseFileName: string);
begin
  if not TFile.Exists(ADatabaseFileName) then
    raise EFileNotFoundException.Create(
      'The BrickStack database is unavailable.');
  var Connection := NewConnection(ADatabaseFileName);
  try
    var Query := TFDQuery.Create(nil);
    try
      Query.Connection := Connection;
      Query.SQL.Text := 'SELECT COUNT(*) FROM BSUsers';
      Query.Open;
      if Query.Fields[0].AsInteger <> 0 then
        Exit;
      Query.Close;

      var Salt := GenerateSalt;
      var Hash := GetPasswordHash(cInitialAdminPassword, Salt);
      Connection.StartTransaction;
      try
        Query.SQL.Text :=
          'INSERT OR IGNORE INTO BSUsers (UserName, DisplayName, PasswordHash, ' +
          'PasswordSalt, PasswordAlgorithm, Role, IsEnabled, ' +
          'MustChangePassword) ' +
          'SELECT :UserName, :DisplayName, :PasswordHash, :PasswordSalt, ' +
          ':PasswordAlgorithm, :Role, 1, 1 ' +
          'WHERE NOT EXISTS (SELECT 1 FROM BSUsers)';
        Query.ParamByName('UserName').AsString := cInitialAdminName;
        Query.ParamByName('DisplayName').AsString := cInitialAdminName;
        Query.ParamByName('PasswordHash').AsString := BytesToHex(Hash);
        Query.ParamByName('PasswordSalt').AsString := BytesToHex(Salt);
        Query.ParamByName('PasswordAlgorithm').AsString := cPasswordAlgorithm;
        Query.ParamByName('Role').AsInteger := cRoleGlobalAdmin;
        Query.ExecSQL;
        Connection.Commit;
      except
        Connection.Rollback;
        raise;
      end;
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

function CreateUserAccount(const ADatabaseFileName, AUserName, ADisplayName: string; out ATemporaryPassword: string): TManagedAccount;
begin
  Result.ID := 0;
  Result.UserName := '';
  Result.DisplayName := '';
  Result.Role := cRoleUser;
  Result.IsEnabled := False;
  Result.MustChangePassword := True;
  ATemporaryPassword := '';

  var UserName := AUserName.Trim;
  var DisplayName := ADisplayName.Trim;
  if not TRegEx.IsMatch(UserName, '^[A-Za-z0-9][A-Za-z0-9._-]{2,63}$') then
    raise EArgumentException.Create(
      'Username must be 3-64 letters, digits, dots, underscores or hyphens.');
  if (Length(DisplayName) = 0) or (Length(DisplayName) > 80) then
    raise EArgumentException.Create(
      'Display name must contain between 1 and 80 characters.');
  for var C in DisplayName do
    if (Ord(C) < 32) or (Ord(C) = 127) then
      raise EArgumentException.Create(
        'Display name cannot contain control characters.');
  if not TFile.Exists(ADatabaseFileName) then
    raise EFileNotFoundException.Create(
      'The BrickStack database is unavailable.');

  ATemporaryPassword := BytesToHex(GenerateRandomBytes(32));
  var Salt := GenerateSalt;
  var PasswordHash := GetPasswordHash(ATemporaryPassword, Salt);
  var Connection := NewConnection(ADatabaseFileName);
  try
    var Query := TFDQuery.Create(nil);
    try
      Query.Connection := Connection;
      Connection.StartTransaction;
      try
        Query.SQL.Text :=
          'SELECT COUNT(*) FROM BSUsers ' +
          'WHERE UserName = :UserName COLLATE NOCASE';
        Query.ParamByName('UserName').AsString := UserName;
        Query.Open;
        if Query.Fields[0].AsInteger <> 0 then
          raise EAccountConflict.Create('The username is already in use.');
        Query.Close;

        Query.SQL.Text :=
          'INSERT INTO BSUsers (UserName, DisplayName, PasswordHash, ' +
          'PasswordSalt, PasswordAlgorithm, Role, IsEnabled, ' +
          'MustChangePassword) ' +
          'VALUES (:UserName, :DisplayName, :PasswordHash, :PasswordSalt, ' +
          ':PasswordAlgorithm, :Role, 1, 1)';
        Query.ParamByName('UserName').AsString := UserName;
        Query.ParamByName('DisplayName').AsString := DisplayName;
        Query.ParamByName('PasswordHash').AsString := BytesToHex(PasswordHash);
        Query.ParamByName('PasswordSalt').AsString := BytesToHex(Salt);
        Query.ParamByName('PasswordAlgorithm').AsString := cPasswordAlgorithm;
        Query.ParamByName('Role').AsInteger := cRoleUser;
        Query.ExecSQL;
        if Query.RowsAffected <> 1 then
          raise EAccountConflict.Create('The username is already in use.');

        Query.SQL.Text :=
          'SELECT ID FROM BSUsers WHERE UserName = :UserName COLLATE NOCASE';
        Query.ParamByName('UserName').AsString := UserName;
        Query.Open;
        Result.ID := Query.FieldByName('ID').AsInteger;
        Query.Close;
        Result.UserName := UserName;
        Result.DisplayName := DisplayName;
        Result.IsEnabled := True;
        Result.MustChangePassword := True;
        Connection.Commit;
      except
        Connection.Rollback;
        ATemporaryPassword := '';
        raise;
      end;
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

function ListUserAccounts(const ADatabaseFileName: string): TManagedAccounts;
begin
  var Connection := NewConnection(ADatabaseFileName);
  try
    var Query := TFDQuery.Create(nil);
    try
      Query.Connection := Connection;
      Query.SQL.Text :=
        'SELECT ID, UserName, DisplayName, Role, IsEnabled, ' +
        'MustChangePassword FROM BSUsers ORDER BY UserName COLLATE NOCASE';
      Query.Open;
      SetLength(Result, 0);
      while not Query.Eof do begin
        var I := Length(Result);
        SetLength(Result, I + 1);
        Result[I].ID := Query.FieldByName('ID').AsInteger;
        Result[I].UserName := Query.FieldByName('UserName').AsString;
        Result[I].DisplayName := Query.FieldByName('DisplayName').AsString;
        Result[I].Role := Query.FieldByName('Role').AsInteger;
        Result[I].IsEnabled := Query.FieldByName('IsEnabled').AsInteger <> 0;
        Result[I].MustChangePassword :=
          Query.FieldByName('MustChangePassword').AsInteger <> 0;
        Query.Next;
      end;
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

function IsInitialAdminPasswordChangeRequired(const ADatabaseFileName: string): Boolean;
begin
  var Connection := NewConnection(ADatabaseFileName);
  try
    var Query := TFDQuery.Create(nil);
    try
      Query.Connection := Connection;
      Query.SQL.Text :=
        'SELECT MustChangePassword FROM BSUsers ' +
        'WHERE UserName = :UserName AND Role = :Role AND IsEnabled = 1';
      Query.ParamByName('UserName').AsString := cInitialAdminName;
      Query.ParamByName('Role').AsInteger := cRoleGlobalAdmin;
      Query.Open;
      Result := not Query.Eof and
        (Query.FieldByName('MustChangePassword').AsInteger <> 0);
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

function ReplaceRequiredPasswordInternal(const ADatabaseFileName, AUserName, ACurrentPassword, ANewPassword: string; AGlobalAdminOnly: Boolean): Boolean;
begin
  if (Length(ANewPassword) < cMinimumPasswordLength) or
    (Length(ANewPassword) > cMaximumPasswordLength) then
    raise EArgumentException.CreateFmt(
      'The replacement password must contain between %d and %d characters.',
      [cMinimumPasswordLength, cMaximumPasswordLength]);

  var Connection := NewConnection(ADatabaseFileName);
  try
    var Query := TFDQuery.Create(nil);
    try
      Query.Connection := Connection;
      Connection.StartTransaction;
      try
        Query.SQL.Text :=
          'SELECT ID, PasswordHash, PasswordSalt, PasswordAlgorithm ' +
          'FROM BSUsers WHERE UserName = :UserName COLLATE NOCASE ' +
          'AND IsEnabled = 1 AND MustChangePassword = 1';
        if AGlobalAdminOnly then
          Query.SQL.Add('AND Role = :Role');
        Query.ParamByName('UserName').AsString := AUserName.Trim;
        if AGlobalAdminOnly then
          Query.ParamByName('Role').AsInteger := cRoleGlobalAdmin;
        Query.Open;
        if Query.Eof then begin
          Connection.Commit;
          Exit(False);
        end;

        var UserID := Query.FieldByName('ID').AsInteger;
        var StoredHash := Query.FieldByName('PasswordHash').AsString;
        var StoredSalt := Query.FieldByName('PasswordSalt').AsString;
        var StoredAlgorithm := Query.FieldByName('PasswordAlgorithm').AsString;
        Query.Close;
        if not IsPasswordValid(ACurrentPassword, StoredHash, StoredSalt,
          StoredAlgorithm) then begin
          Connection.Commit;
          Exit(False);
        end;

        var NewSalt := GenerateSalt;
        var NewHash := GetPasswordHash(ANewPassword, NewSalt);
        Query.SQL.Text :=
          'UPDATE BSUsers SET PasswordHash = :PasswordHash, ' +
          'PasswordSalt = :PasswordSalt, PasswordAlgorithm = :Algorithm, ' +
          'MustChangePassword = 0 WHERE ID = :ID AND MustChangePassword = 1';
        Query.ParamByName('PasswordHash').AsString := BytesToHex(NewHash);
        Query.ParamByName('PasswordSalt').AsString := BytesToHex(NewSalt);
        Query.ParamByName('Algorithm').AsString := cPasswordAlgorithm;
        Query.ParamByName('ID').AsInteger := UserID;
        Query.ExecSQL;
        Result := Query.RowsAffected = 1;
        if Result then begin
          Query.SQL.Text :=
            'DELETE FROM BSLoginFailures WHERE UserID = :UserID';
          Query.ParamByName('UserID').AsInteger := UserID;
          Query.ExecSQL;
          Query.SQL.Text := 'DELETE FROM BSSessions WHERE UserID = :UserID';
          Query.ParamByName('UserID').AsInteger := UserID;
          Query.ExecSQL;
        end;
        Connection.Commit;
      except
        Connection.Rollback;
        raise;
      end;
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

function ReplaceInitialAdminPassword(const ADatabaseFileName, AUserName, ACurrentPassword, ANewPassword: string): Boolean;
begin
  if not SameText(AUserName.Trim, cInitialAdminName) then
    Exit(False);
  Result := ReplaceRequiredPasswordInternal(ADatabaseFileName, AUserName,
    ACurrentPassword, ANewPassword, True);
end;

function ReplaceRequiredUserPassword(const ADatabaseFileName, AUserName, ACurrentPassword, ANewPassword: string): Boolean;
begin
  Result := ReplaceRequiredPasswordInternal(ADatabaseFileName, AUserName,
    ACurrentPassword, ANewPassword, False);
end;

function AuthenticateAndCreateSession(const ADatabaseFileName, AUserName, APassword: string; out AUser: TAuthenticatedUser; out ASessionToken: string): Boolean;
begin
  var TotpRequired: Boolean;
  Result := AuthenticateAndCreateSession(ADatabaseFileName, AUserName,
    APassword, '', '', AUser, ASessionToken, TotpRequired);
end;

function AuthenticateAndCreateSession(const ADatabaseFileName, AUserName,
  APassword, ATotpCode, ARecoveryCode: string; out AUser: TAuthenticatedUser;
  out ASessionToken: string; out ATotpRequired: Boolean): Boolean;
var
  Connection: TFDConnection;
  Query: TFDQuery;
  PasswordHash: string;
  PasswordSalt: string;
  PasswordAlgorithm: string;
  ProtectedTotpSecret: string;
  UserID: Integer;
  UserEnabled: Boolean;
  MustChangePassword: Boolean;
  TotpEnabled: Boolean;
  PasswordValid: Boolean;
  FactorValid: Boolean;
  RecoveryCodeUsed: Boolean;
  FailureCount: Integer;
  WindowStartedAt: Int64;
  LockedUntil: Int64;
  NowUnix: Int64;
  MatchedCounter: Int64;
  RecoveryHash: string;
  Salt: TBytes;
  TokenBytes: TBytes;

  procedure RecordLoginFailure;
  begin
    if WindowStartedAt + cLoginWindowSeconds <= NowUnix then begin
      FailureCount := 0;
      WindowStartedAt := NowUnix;
    end;
    Inc(FailureCount);
    if FailureCount >= cMaximumLoginFailures then
      LockedUntil := NowUnix + cLoginLockSeconds;
    Connection.StartTransaction;
    try
      Query.SQL.Text :=
        'INSERT INTO BSLoginFailures ' +
        '(UserID, FailureCount, WindowStartedAt, LockedUntil) ' +
        'VALUES (:UserID, :FailureCount, :WindowStartedAt, :LockedUntil) ' +
        'ON CONFLICT(UserID) DO UPDATE SET ' +
        'FailureCount = excluded.FailureCount, ' +
        'WindowStartedAt = excluded.WindowStartedAt, ' +
        'LockedUntil = excluded.LockedUntil';
      Query.ParamByName('UserID').AsInteger := UserID;
      Query.ParamByName('FailureCount').AsInteger := FailureCount;
      Query.ParamByName('WindowStartedAt').AsLargeInt := WindowStartedAt;
      Query.ParamByName('LockedUntil').AsLargeInt := LockedUntil;
      Query.ExecSQL;
      Connection.Commit;
    except
      Connection.Rollback;
      raise;
    end;
  end;
begin
  Result := False;
  AUser.ID := 0;
  AUser.UserName := '';
  AUser.DisplayName := '';
  AUser.Role := 0;
  AUser.TotpEnabled := False;
  ASessionToken := '';
  ATotpRequired := False;
  if (AUserName.Trim = '') or (Length(AUserName) > 64) or
    (Length(APassword) = 0) or (Length(APassword) > cMaximumPasswordLength) then begin
    Salt := TBytes.Create(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    PasswordHash := BytesToHex(GetPasswordHash(APassword, Salt));
    Exit;
  end;

  Connection := NewConnection(ADatabaseFileName);
  try
    Query := TFDQuery.Create(nil);
    try
      Query.Connection := Connection;
      Query.SQL.Text :=
        'SELECT ID, UserName, DisplayName, PasswordHash, PasswordSalt, ' +
        'PasswordAlgorithm, Role, IsEnabled, MustChangePassword, ' +
        'CASE WHEN t.EnabledAt IS NOT NULL AND t.SecretProtected IS NOT NULL ' +
        'THEN 1 ELSE 0 END AS TotpEnabled, t.SecretProtected ' +
        'FROM BSUsers u LEFT JOIN BSUserTotp t ON t.UserID = u.ID ' +
        'WHERE u.UserName = :UserName COLLATE NOCASE';
      Query.ParamByName('UserName').AsString := AUserName.Trim;
      Query.Open;
      if Query.Eof then begin
        SetLength(Salt, cSaltLength);
        PasswordHash := BytesToHex(GetPasswordHash(APassword, Salt));
        Exit;
      end;

      UserID := Query.FieldByName('ID').AsInteger;
      AUser.ID := UserID;
      AUser.UserName := Query.FieldByName('UserName').AsString;
      AUser.DisplayName := Query.FieldByName('DisplayName').AsString;
      AUser.Role := Query.FieldByName('Role').AsInteger;
      PasswordHash := Query.FieldByName('PasswordHash').AsString;
      PasswordSalt := Query.FieldByName('PasswordSalt').AsString;
      PasswordAlgorithm := Query.FieldByName('PasswordAlgorithm').AsString;
      UserEnabled := Query.FieldByName('IsEnabled').AsInteger <> 0;
      MustChangePassword :=
        Query.FieldByName('MustChangePassword').AsInteger <> 0;
      TotpEnabled := Query.FieldByName('TotpEnabled').AsInteger <> 0;
      ProtectedTotpSecret := Query.FieldByName('SecretProtected').AsString;
      AUser.TotpEnabled := TotpEnabled;
      Query.Close;

      PasswordValid := IsPasswordValid(APassword, PasswordHash, PasswordSalt,
        PasswordAlgorithm);
      NowUnix := CurrentUnixTime;
      Query.SQL.Text :=
        'SELECT FailureCount, WindowStartedAt, LockedUntil ' +
        'FROM BSLoginFailures WHERE UserID = :UserID';
      Query.ParamByName('UserID').AsInteger := UserID;
      Query.Open;
      FailureCount := 0;
      WindowStartedAt := NowUnix;
      LockedUntil := 0;
      if not Query.Eof then begin
        FailureCount := Query.FieldByName('FailureCount').AsInteger;
        WindowStartedAt := Query.FieldByName('WindowStartedAt').AsLargeInt;
        LockedUntil := Query.FieldByName('LockedUntil').AsLargeInt;
      end;
      Query.Close;

      if LockedUntil > NowUnix then
        Exit(False);

      if not UserEnabled or MustChangePassword or not PasswordValid then begin
        RecordLoginFailure;
        Exit(False);
      end;

      if TotpEnabled and (ATotpCode.Trim = '') and
        (ARecoveryCode.Trim = '') then begin
        ATotpRequired := True;
        Exit(False);
      end;

      FactorValid := not TotpEnabled and (ATotpCode.Trim = '') and
        (ARecoveryCode.Trim = '');
      MatchedCounter := -1;
      RecoveryCodeUsed := False;
      if TotpEnabled and (ATotpCode.Trim <> '') and
        (ARecoveryCode.Trim = '') then begin
        FactorValid := TryVerifyTotpCode(
          UnprotectTotpSecret(ProtectedTotpSecret), ATotpCode.Trim, NowUnix,
          MatchedCounter);
      end else if TotpEnabled and (ARecoveryCode.Trim <> '') and
        (ATotpCode.Trim = '') and
        TRegEx.IsMatch(ARecoveryCode.Trim, '^[0-9A-Fa-f]{32}$') then begin
        RecoveryHash := RecoveryCodeHash(ARecoveryCode);
        RecoveryCodeUsed := True;
        FactorValid := True;
      end;

      if not FactorValid then begin
        RecordLoginFailure;
        Exit(False);
      end;

      TokenBytes := GenerateRandomBytes(32);
      ASessionToken := BytesToHex(TokenBytes);
      Connection.StartTransaction;
      try
        if TotpEnabled and RecoveryCodeUsed then begin
          Query.SQL.Text :=
            'DELETE FROM BSRecoveryCodes WHERE UserID = :UserID ' +
            'AND CodeHash = :CodeHash';
          Query.ParamByName('UserID').AsInteger := UserID;
          Query.ParamByName('CodeHash').AsString := RecoveryHash;
          Query.ExecSQL;
          if Query.RowsAffected <> 1 then begin
            Connection.Rollback;
            RecordLoginFailure;
            ASessionToken := '';
            Exit(False);
          end;
        end else if TotpEnabled then begin
          Query.SQL.Text :=
            'UPDATE BSUserTotp SET LastCounter = :Counter ' +
            'WHERE UserID = :UserID AND EnabledAt IS NOT NULL ' +
            'AND LastCounter < :Counter';
          Query.ParamByName('Counter').AsLargeInt := MatchedCounter;
          Query.ParamByName('UserID').AsInteger := UserID;
          Query.ExecSQL;
          if Query.RowsAffected <> 1 then begin
            Connection.Rollback;
            RecordLoginFailure;
            ASessionToken := '';
            Exit(False);
          end;
        end;
        Query.SQL.Text := 'DELETE FROM BSSessions WHERE ExpiresAt <= :Now';
        Query.ParamByName('Now').AsLargeInt := NowUnix;
        Query.ExecSQL;
        Query.SQL.Text := 'DELETE FROM BSLoginFailures WHERE UserID = :UserID';
        Query.ParamByName('UserID').AsInteger := UserID;
        Query.ExecSQL;
        Query.SQL.Text :=
          'INSERT INTO BSSessions (SessionHash, UserID, CreatedAt, ExpiresAt) ' +
          'VALUES (:SessionHash, :UserID, :CreatedAt, :ExpiresAt)';
        Query.ParamByName('SessionHash').AsString := SHA256Hex(ASessionToken);
        Query.ParamByName('UserID').AsInteger := UserID;
        Query.ParamByName('CreatedAt').AsLargeInt := NowUnix;
        Query.ParamByName('ExpiresAt').AsLargeInt :=
          NowUnix + cSessionLifetimeSeconds;
        Query.ExecSQL;
        Connection.Commit;
        Result := True;
      except
        Connection.Rollback;
        ASessionToken := '';
        raise;
      end;
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

function TryGetSessionUser(const ADatabaseFileName, ASessionToken: string; out AUser: TAuthenticatedUser): Boolean;
begin
  AUser.ID := 0;
  AUser.UserName := '';
  AUser.DisplayName := '';
  AUser.Role := 0;
  AUser.TotpEnabled := False;
  if (Length(ASessionToken) <> 64) or
    not TRegEx.IsMatch(ASessionToken, '^[0-9a-fA-F]{64}$') then
    Exit(False);
  var Connection := NewConnection(ADatabaseFileName);
  try
    var Query := TFDQuery.Create(nil);
    try
      Query.Connection := Connection;
      Query.SQL.Text :=
        'SELECT u.ID, u.UserName, u.DisplayName, u.Role, ' +
        'CASE WHEN t.EnabledAt IS NOT NULL AND t.SecretProtected IS NOT NULL ' +
        'THEN 1 ELSE 0 END AS TotpEnabled ' +
        'FROM BSSessions s JOIN BSUsers u ON u.ID = s.UserID ' +
        'LEFT JOIN BSUserTotp t ON t.UserID = u.ID ' +
        'WHERE s.SessionHash = :SessionHash AND s.ExpiresAt > :Now ' +
        'AND u.IsEnabled = 1 AND u.MustChangePassword = 0';
      Query.ParamByName('SessionHash').AsString := SHA256Hex(ASessionToken);
      Query.ParamByName('Now').AsLargeInt := CurrentUnixTime;
      Query.Open;
      Result := not Query.Eof;
      if Result then begin
        AUser.ID := Query.FieldByName('ID').AsInteger;
        AUser.UserName := Query.FieldByName('UserName').AsString;
        AUser.DisplayName := Query.FieldByName('DisplayName').AsString;
        AUser.Role := Query.FieldByName('Role').AsInteger;
        AUser.TotpEnabled := Query.FieldByName('TotpEnabled').AsInteger <> 0;
      end;
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

function StartTotpEnrollment(const ADatabaseFileName, ASessionToken: string; out ASecret, AProvisioningUri: string): Boolean;
begin
  Result := False;
  ASecret := '';
  AProvisioningUri := '';
  var User: TAuthenticatedUser;
  if not TryGetSessionUser(ADatabaseFileName, ASessionToken, User) then
    Exit;

  var Secret := GenerateTotpSecret;
  var ProtectedSecret := ProtectTotpSecret(Secret);
  var NowUnix := CurrentUnixTime;
  var Connection := NewConnection(ADatabaseFileName);
  try
    var Query := TFDQuery.Create(nil);
    try
      Query.Connection := Connection;
      Query.SQL.Text :=
        'INSERT INTO BSUserTotp ' +
        '(UserID, PendingSecretProtected, PendingExpiresAt) ' +
        'SELECT :UserID, :Secret, :ExpiresAt WHERE EXISTS (' +
        'SELECT 1 FROM BSSessions s JOIN BSUsers u ON u.ID = s.UserID ' +
        'WHERE s.SessionHash = :SessionHash AND s.ExpiresAt > :Now ' +
        'AND u.IsEnabled = 1 AND u.MustChangePassword = 0) ' +
        'ON CONFLICT(UserID) DO UPDATE SET ' +
        'PendingSecretProtected = excluded.PendingSecretProtected, ' +
        'PendingExpiresAt = excluded.PendingExpiresAt ' +
        'WHERE BSUserTotp.EnabledAt IS NULL';
      Query.ParamByName('UserID').AsInteger := User.ID;
      Query.ParamByName('Secret').AsString := ProtectedSecret;
      Query.ParamByName('ExpiresAt').AsLargeInt :=
        NowUnix + cTotpEnrollmentLifetimeSeconds;
      Query.ParamByName('SessionHash').AsString := SHA256Hex(ASessionToken);
      Query.ParamByName('Now').AsLargeInt := NowUnix;
      Query.ExecSQL;
      Result := Query.RowsAffected = 1;
      if Result then begin
        ASecret := Secret;
        AProvisioningUri := TotpProvisioningUri(User.UserName, Secret);
      end;
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

function ConfirmTotpEnrollment(const ADatabaseFileName, ASessionToken, ACode: string; out ARecoveryCodes: TArray<string>): Boolean;
var
  Connection: TFDConnection;
  Query: TFDQuery;
  ProtectedSecret: string;
  Secret: string;
  UserID: Integer;
  NowUnix: Int64;
  MatchedCounter: Int64;
  I: Integer;
  FailureCount: Integer;
  WindowStartedAt: Int64;
  LockedUntil: Int64;

  procedure RecordEnrollmentFailure;
  begin
    if WindowStartedAt + cLoginWindowSeconds <= NowUnix then begin
      FailureCount := 0;
      WindowStartedAt := NowUnix;
    end;
    Inc(FailureCount);
    if FailureCount >= cMaximumLoginFailures then
      LockedUntil := NowUnix + cLoginLockSeconds;
    Connection.StartTransaction;
    try
      Query.SQL.Text :=
        'INSERT INTO BSLoginFailures ' +
        '(UserID, FailureCount, WindowStartedAt, LockedUntil) ' +
        'VALUES (:UserID, :FailureCount, :WindowStartedAt, :LockedUntil) ' +
        'ON CONFLICT(UserID) DO UPDATE SET ' +
        'FailureCount = excluded.FailureCount, ' +
        'WindowStartedAt = excluded.WindowStartedAt, ' +
        'LockedUntil = excluded.LockedUntil';
      Query.ParamByName('UserID').AsInteger := UserID;
      Query.ParamByName('FailureCount').AsInteger := FailureCount;
      Query.ParamByName('WindowStartedAt').AsLargeInt := WindowStartedAt;
      Query.ParamByName('LockedUntil').AsLargeInt := LockedUntil;
      Query.ExecSQL;
      Connection.Commit;
    except
      Connection.Rollback;
      raise;
    end;
  end;
begin
  Result := False;
  ARecoveryCodes := nil;
  if (Length(ASessionToken) <> 64) or
    not TRegEx.IsMatch(ASessionToken, '^[0-9a-fA-F]{64}$') then
    Exit;
  NowUnix := CurrentUnixTime;
  Connection := NewConnection(ADatabaseFileName);
  try
    Query := TFDQuery.Create(nil);
    try
      Query.Connection := Connection;
      Query.SQL.Text :=
        'SELECT u.ID, t.PendingSecretProtected FROM BSSessions s ' +
        'JOIN BSUsers u ON u.ID = s.UserID ' +
        'JOIN BSUserTotp t ON t.UserID = u.ID ' +
        'WHERE s.SessionHash = :SessionHash AND s.ExpiresAt > :Now ' +
        'AND u.IsEnabled = 1 AND u.MustChangePassword = 0 ' +
        'AND t.EnabledAt IS NULL AND t.PendingExpiresAt > :Now';
      Query.ParamByName('SessionHash').AsString := SHA256Hex(ASessionToken);
      Query.ParamByName('Now').AsLargeInt := NowUnix;
      Query.Open;
      if Query.Eof then
        Exit;
      UserID := Query.FieldByName('ID').AsInteger;
      ProtectedSecret := Query.FieldByName('PendingSecretProtected').AsString;
      Query.Close;

      Query.SQL.Text :=
        'SELECT FailureCount, WindowStartedAt, LockedUntil ' +
        'FROM BSLoginFailures WHERE UserID = :UserID';
      Query.ParamByName('UserID').AsInteger := UserID;
      Query.Open;
      FailureCount := 0;
      WindowStartedAt := NowUnix;
      LockedUntil := 0;
      if not Query.Eof then begin
        FailureCount := Query.FieldByName('FailureCount').AsInteger;
        WindowStartedAt := Query.FieldByName('WindowStartedAt').AsLargeInt;
        LockedUntil := Query.FieldByName('LockedUntil').AsLargeInt;
      end;
      Query.Close;
      if LockedUntil > NowUnix then
        Exit;

      Secret := UnprotectTotpSecret(ProtectedSecret);
      if not TryVerifyTotpCode(Secret, ACode.Trim, NowUnix, MatchedCounter) then begin
        RecordEnrollmentFailure;
        Exit;
      end;

      SetLength(ARecoveryCodes, cRecoveryCodeCount);
      for I := 0 to High(ARecoveryCodes) do
        ARecoveryCodes[I] := GenerateRecoveryCode;
      Connection.StartTransaction;
      try
        Query.SQL.Text :=
          'UPDATE BSUserTotp SET SecretProtected = PendingSecretProtected, ' +
          'EnabledAt = :Now, LastCounter = :Counter, ' +
          'PendingSecretProtected = NULL, PendingExpiresAt = NULL ' +
          'WHERE UserID = :UserID AND EnabledAt IS NULL ' +
          'AND PendingExpiresAt > :Now';
        Query.ParamByName('Now').AsLargeInt := NowUnix;
        Query.ParamByName('Counter').AsLargeInt := MatchedCounter;
        Query.ParamByName('UserID').AsInteger := UserID;
        Query.ExecSQL;
        if Query.RowsAffected <> 1 then begin
          Connection.Rollback;
          ARecoveryCodes := nil;
          Exit(False);
        end;

        for I := 0 to High(ARecoveryCodes) do begin
          Query.SQL.Text :=
            'INSERT INTO BSRecoveryCodes (UserID, CodeHash, CreatedAt) ' +
            'VALUES (:UserID, :CodeHash, :CreatedAt)';
          Query.ParamByName('UserID').AsInteger := UserID;
          Query.ParamByName('CodeHash').AsString :=
            RecoveryCodeHash(ARecoveryCodes[I]);
          Query.ParamByName('CreatedAt').AsLargeInt := NowUnix;
          Query.ExecSQL;
        end;
        Query.SQL.Text :=
          'DELETE FROM BSLoginFailures WHERE UserID = :UserID';
        Query.ParamByName('UserID').AsInteger := UserID;
        Query.ExecSQL;
        Connection.Commit;
        Result := True;
      except
        Connection.Rollback;
        ARecoveryCodes := nil;
        raise;
      end;
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

procedure RevokeSession(const ADatabaseFileName, ASessionToken: string);
begin
  if (Length(ASessionToken) <> 64) or
    not TRegEx.IsMatch(ASessionToken, '^[0-9a-fA-F]{64}$') then
    Exit;
  var Connection := NewConnection(ADatabaseFileName);
  try
    var Query := TFDQuery.Create(nil);
    try
      Query.Connection := Connection;
      Query.SQL.Text := 'DELETE FROM BSSessions WHERE SessionHash = :Hash';
      Query.ParamByName('Hash').AsString := SHA256Hex(ASessionToken);
      Query.ExecSQL;
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

end.
