unit UBSAdminBootstrapTests;

interface

uses
  TestFramework;

type
  TAdminBootstrapTests = class(TTestCase)
  published
    procedure CreatesHashedInitialAdminOnlyOnce;
    procedure ReplacesInitialPasswordAndDisablesBootstrap;
    procedure CreatesAndRevokesAuthenticatedSession;
    procedure RejectsExpiredSession;
    procedure ThrottlesFailedLoginsWithoutExtendingLockout;
    procedure EnforcesTotpAndSingleUseRecoveryCodes;
    procedure ExpiresAndRateLimitsTotpEnrollment;
    procedure ProvisionsUserWithOneTimePasswordAndRequiredChange;
  end;

implementation

uses
  System.IOUtils,
  System.DateUtils,
  System.Hash,
  System.SysUtils,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  UBSAdminBootstrap,
  UBSDatabaseBootstrap,
  UBSTotp;

function NewTestDirectory: string;
begin
  var Guid: TGUID;
  CreateGUID(Guid);
  Result := TPath.Combine(TPath.GetTempPath,
    'BrickStack2-' + GUIDToString(Guid));
  TDirectory.CreateDirectory(Result);
end;

function TestTotpCode(const ASecret: string; AUnixTime: Int64): string;
const
  cAlphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
begin
  var Key: TBytes := nil;
  var Buffer: Cardinal := 0;
  var BitsInBuffer := 0;
  for var I := 1 to Length(ASecret) do begin
    var Digit := Pos(ASecret[I], cAlphabet) - 1;
    Buffer := (Buffer shl 5) or Cardinal(Digit);
    Inc(BitsInBuffer, 5);
    if BitsInBuffer >= 8 then begin
      Dec(BitsInBuffer, 8);
      SetLength(Key, Length(Key) + 1);
      Key[High(Key)] := Byte((Buffer shr BitsInBuffer) and $FF);
    end;
  end;
  var Counter := AUnixTime div 30;
  var Data: TBytes;
  SetLength(Data, 8);
  for var I := 0 to 7 do
    Data[7 - I] := Byte((UInt64(Counter) shr (I * 8)) and $FF);
  var Digest := THashSHA1.GetHMACAsBytes(Data, Key);
  var Offset := Digest[High(Digest)] and $0F;
  var Code := (Cardinal(Digest[Offset]) and $7F) shl 24 or
    (Cardinal(Digest[Offset + 1]) shl 16) or
    (Cardinal(Digest[Offset + 2]) shl 8) or
    Cardinal(Digest[Offset + 3]);
  Result := Format('%.6d', [Code mod 1000000]);
end;

procedure TAdminBootstrapTests.CreatesHashedInitialAdminOnlyOnce;
begin
  var TestDirectory := NewTestDirectory;
  var DatabaseFile := TPath.Combine(TestDirectory, 'BrickStack.db');
  try
    InitializeBrickStackDatabase(DatabaseFile);
    EnsureInitialAdmin(DatabaseFile);
    EnsureInitialAdmin(DatabaseFile);
    Check(IsInitialAdminPasswordChangeRequired(DatabaseFile));

    var Connection := TFDConnection.Create(nil);
    try
      Connection.LoginPrompt := False;
      Connection.DriverName := 'SQLite';
      Connection.Params.Database := DatabaseFile;
      Connection.Connected := True;
      var Query := TFDQuery.Create(nil);
      try
        Query.Connection := Connection;
        Query.SQL.Text :=
          'SELECT UserName, PasswordHash, PasswordSalt, PasswordAlgorithm, ' +
          'MustChangePassword, (SELECT COUNT(*) FROM BSUsers) AS UserCount ' +
          'FROM BSUsers WHERE UserName = ''Admin''';
        Query.Open;
        Check(not Query.Eof, 'The initial administrator was not created');
        CheckEquals('Admin', Query.FieldByName('UserName').AsString);
        Check(Query.FieldByName('PasswordHash').AsString <> 'Admin',
          'The initial password must never be stored in plaintext');
        CheckEquals(64, Length(Query.FieldByName('PasswordHash').AsString));
        CheckEquals(32, Length(Query.FieldByName('PasswordSalt').AsString));
        CheckEquals('PBKDF2-HMAC-SHA256-600000',
          Query.FieldByName('PasswordAlgorithm').AsString);
        CheckEquals(1, Query.FieldByName('MustChangePassword').AsInteger);
        CheckEquals(1, Query.FieldByName('UserCount').AsInteger);
      finally
        Query.Free;
      end;
    finally
      Connection.Free;
    end;
  finally
    TDirectory.Delete(TestDirectory, True);
  end;
end;

procedure TAdminBootstrapTests.ReplacesInitialPasswordAndDisablesBootstrap;
begin
  var TestDirectory := NewTestDirectory;
  var DatabaseFile := TPath.Combine(TestDirectory, 'BrickStack.db');
  try
    InitializeBrickStackDatabase(DatabaseFile);
    EnsureInitialAdmin(DatabaseFile);

    Check(not ReplaceInitialAdminPassword(DatabaseFile, 'other', 'Admin',
      'A-long-new-password'));
    Check(not ReplaceInitialAdminPassword(DatabaseFile, 'Admin', 'wrong',
      'A-long-new-password'));
    var RejectedShortPassword := False;
    try
      ReplaceInitialAdminPassword(DatabaseFile, 'Admin', 'Admin', 'short');
    except
      on E: EArgumentException do
        RejectedShortPassword := True;
    end;
    Check(RejectedShortPassword,
      'A too-short replacement password should be rejected');

    Check(ReplaceInitialAdminPassword(DatabaseFile, 'Admin', 'Admin',
      'A-long-new-password'));
    Check(not IsInitialAdminPasswordChangeRequired(DatabaseFile));
    EnsureInitialAdmin(DatabaseFile);
    Check(not IsInitialAdminPasswordChangeRequired(DatabaseFile));
    Check(not ReplaceInitialAdminPassword(DatabaseFile, 'Admin', 'Admin',
      'Another-long-password'));
  finally
    TDirectory.Delete(TestDirectory, True);
  end;
end;

procedure TAdminBootstrapTests.CreatesAndRevokesAuthenticatedSession;
begin
  var TestDirectory := NewTestDirectory;
  var DatabaseFile := TPath.Combine(TestDirectory, 'BrickStack.db');
  try
    InitializeBrickStackDatabase(DatabaseFile);
    EnsureInitialAdmin(DatabaseFile);
    var User: TAuthenticatedUser;
    var SessionToken: string;
    Check(not AuthenticateAndCreateSession(DatabaseFile, 'Admin', 'Admin',
      User, SessionToken),
      'An account requiring password replacement must not sign in');
    Check(ReplaceInitialAdminPassword(DatabaseFile, 'Admin', 'Admin',
      'A-long-new-password'));
    Check(AuthenticateAndCreateSession(DatabaseFile, 'Admin',
      'A-long-new-password', User, SessionToken),
      'The enabled account should sign in after password replacement');
    CheckEquals('Admin', User.UserName);
    CheckEquals(64, Length(SessionToken));
    Check(TryGetSessionUser(DatabaseFile, SessionToken, User),
      'The new session should resolve to its account');

    var Connection := TFDConnection.Create(nil);
    try
      Connection.LoginPrompt := False;
      Connection.DriverName := 'SQLite';
      Connection.Params.Database := DatabaseFile;
      Connection.Connected := True;
      var Query := TFDQuery.Create(nil);
      try
        Query.Connection := Connection;
        Query.SQL.Text :=
          'SELECT COUNT(*) FROM BSSessions WHERE SessionHash = :SessionHash';
        Query.ParamByName('SessionHash').AsString := SessionToken;
        Query.Open;
        CheckEquals(0, Query.Fields[0].AsInteger,
          'The raw session token must not be stored in the database');
      finally
        Query.Free;
      end;
    finally
      Connection.Free;
    end;

    RevokeSession(DatabaseFile, SessionToken);
    Check(not TryGetSessionUser(DatabaseFile, SessionToken, User),
      'A revoked session must no longer authenticate');
  finally
    TDirectory.Delete(TestDirectory, True);
  end;
end;

procedure TAdminBootstrapTests.RejectsExpiredSession;
begin
  var TestDirectory := NewTestDirectory;
  var DatabaseFile := TPath.Combine(TestDirectory, 'BrickStack.db');
  try
    InitializeBrickStackDatabase(DatabaseFile);
    EnsureInitialAdmin(DatabaseFile);
    Check(ReplaceInitialAdminPassword(DatabaseFile, 'Admin', 'Admin',
      'A-long-new-password'), 'The initial admin password should be replaced');
    var User: TAuthenticatedUser;
    var SessionToken: string;
    Check(AuthenticateAndCreateSession(DatabaseFile, 'Admin',
      'A-long-new-password', User, SessionToken),
      'The updated admin password should authenticate');
    Check(TryGetSessionUser(DatabaseFile, SessionToken, User),
      'A newly issued session should authenticate');

    var Connection := TFDConnection.Create(nil);
    try
      Connection.LoginPrompt := False;
      Connection.DriverName := 'SQLite';
      Connection.Params.Database := DatabaseFile;
      Connection.Connected := True;
      var Query := TFDQuery.Create(nil);
      try
        Query.Connection := Connection;
        Query.SQL.Text := 'UPDATE BSSessions SET ExpiresAt = 0';
        Query.ExecSQL;
      finally
        Query.Free;
      end;
    finally
      Connection.Free;
    end;

    Check(not TryGetSessionUser(DatabaseFile, SessionToken, User),
      'An expired session must not authenticate');
  finally
    TDirectory.Delete(TestDirectory, True);
  end;
end;

procedure TAdminBootstrapTests.ThrottlesFailedLoginsWithoutExtendingLockout;
begin
  var TestDirectory := NewTestDirectory;
  var DatabaseFile := TPath.Combine(TestDirectory, 'BrickStack.db');
  try
    InitializeBrickStackDatabase(DatabaseFile);
    EnsureInitialAdmin(DatabaseFile);
    Check(ReplaceInitialAdminPassword(DatabaseFile, 'Admin', 'Admin',
      'A-long-new-password'));

    var User: TAuthenticatedUser;
    var SessionToken: string;
    for var I := 1 to 5 do
      Check(not AuthenticateAndCreateSession(DatabaseFile, 'Admin',
        'incorrect-password', User, SessionToken),
        'An incorrect password must not create an authenticated session');

    var Connection := TFDConnection.Create(nil);
    var Query: TFDQuery;
    var FailureCount: Integer;
    var LockedUntil: Int64;
    try
      Connection.LoginPrompt := False;
      Connection.DriverName := 'SQLite';
      Connection.Params.Database := DatabaseFile;
      Connection.Connected := True;
      Query := TFDQuery.Create(nil);
      try
        Query.Connection := Connection;
        Query.SQL.Text :=
          'SELECT FailureCount, LockedUntil FROM BSLoginFailures';
        Query.Open;
        Check(not Query.Eof, 'Failed logins should be recorded');
        FailureCount := Query.FieldByName('FailureCount').AsInteger;
        LockedUntil := Query.FieldByName('LockedUntil').AsLargeInt;
        CheckEquals(5, FailureCount);
        Check(LockedUntil > 0, 'The threshold should lock the account');
      finally
        Query.Free;
      end;
    finally
      Connection.Free;
    end;

    Check(not AuthenticateAndCreateSession(DatabaseFile, 'Admin',
      'A-long-new-password', User, SessionToken),
      'A correct password must not bypass an active lockout');

    Connection := TFDConnection.Create(nil);
    try
      Connection.LoginPrompt := False;
      Connection.DriverName := 'SQLite';
      Connection.Params.Database := DatabaseFile;
      Connection.Connected := True;
      Query := TFDQuery.Create(nil);
      try
        Query.Connection := Connection;
        Query.SQL.Text :=
          'SELECT FailureCount, LockedUntil FROM BSLoginFailures';
        Query.Open;
        CheckEquals(FailureCount, Query.FieldByName('FailureCount').AsInteger,
          'Attempts during lockout must not increase the failure count');
        Check(LockedUntil = Query.FieldByName('LockedUntil').AsLargeInt,
          'Attempts during lockout must not extend the lockout');
      finally
        Query.Free;
      end;
    finally
      Connection.Free;
    end;
  finally
    TDirectory.Delete(TestDirectory, True);
  end;
end;

procedure TAdminBootstrapTests.EnforcesTotpAndSingleUseRecoveryCodes;
begin
  var NowUnix: Int64;
  Check(TryVerifyTotpCode('GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ',
    '287082', 59, NowUnix),
    'The RFC 6238 SHA-1 test vector should verify');
  Check(not TryVerifyTotpCode('GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ',
    '287083', 59, NowUnix),
    'An incorrect RFC 6238 code should not verify');
  CheckEquals('A-TEST-SECRET', UnprotectTotpSecret(
    ProtectTotpSecret('A-TEST-SECRET')),
    'DPAPI must round-trip the authenticator secret');

  var TestDirectory := NewTestDirectory;
  var DatabaseFile := TPath.Combine(TestDirectory, 'BrickStack.db');
  try
    InitializeBrickStackDatabase(DatabaseFile);
    EnsureInitialAdmin(DatabaseFile);
    Check(ReplaceInitialAdminPassword(DatabaseFile, 'Admin', 'Admin',
      'A-long-new-password'));
    var User: TAuthenticatedUser;
    var SessionToken: string;
    Check(AuthenticateAndCreateSession(DatabaseFile, 'Admin',
      'A-long-new-password', User, SessionToken));
    Check(not User.TotpEnabled, 'TOTP should be off before enrollment');

    var Secret: string;
    var ProvisioningUri: string;
    Check(StartTotpEnrollment(DatabaseFile, SessionToken, Secret,
      ProvisioningUri), 'The admin should be able to start TOTP enrollment');
    CheckEquals(32, Length(Secret), 'The secret should be a 20-byte Base32 value');
    Check(Pos('otpauth://totp/BrickStack%3AAdmin?secret=', ProvisioningUri) = 1,
      'Enrollment should produce a standard authenticator URI');

    NowUnix := DateTimeToUnix(Now);
    var EnrollmentCode := TestTotpCode(Secret, NowUnix);
    var Code := TestTotpCode(Secret, NowUnix + 30);
    var RecoveryCodes: TArray<string>;
    Check(ConfirmTotpEnrollment(DatabaseFile, SessionToken, EnrollmentCode,
      RecoveryCodes),
      'A valid code should confirm authenticator enrollment');
    CheckEquals(10, Length(RecoveryCodes),
      'Enrollment should return ten recovery codes once');
    var ReusedRecoveryCode := RecoveryCodes[0];
    Check(not ConfirmTotpEnrollment(DatabaseFile, SessionToken, EnrollmentCode,
      RecoveryCodes),
      'A second confirmation must not return another set of recovery codes');
    Check(TryGetSessionUser(DatabaseFile, SessionToken, User),
      'The enrollment session should remain valid');
    Check(User.TotpEnabled, 'The enrolled factor should be reflected in profile');

    var Required: Boolean;
    Check(not AuthenticateAndCreateSession(DatabaseFile, 'Admin',
      'A-long-new-password', '', '', User, SessionToken, Required),
      'Password-only sign-in should stop at the factor challenge');
    Check(Required,
      'A Global Admin with an enrolled factor must complete the second step');
    Check(AuthenticateAndCreateSession(DatabaseFile, 'Admin',
      'A-long-new-password', Code, '', User, SessionToken, Required),
      'The newly generated TOTP should complete sign-in');
    Check(not Required, 'A complete sign-in must not return a factor challenge');
    Check(User.TotpEnabled, 'The authenticated profile should retain TOTP state');
    Check(not AuthenticateAndCreateSession(DatabaseFile, 'Admin',
      'A-long-new-password', Code, '', User, SessionToken, Required),
      'A TOTP counter must not be accepted a second time');

    Check(AuthenticateAndCreateSession(DatabaseFile, 'Admin',
      'A-long-new-password', '', ReusedRecoveryCode, User, SessionToken,
      Required), 'A recovery code should permit one sign-in');
    Check(not AuthenticateAndCreateSession(DatabaseFile, 'Admin',
      'A-long-new-password', '', ReusedRecoveryCode, User, SessionToken,
      Required), 'A recovery code must be consumed after use');

    var Connection := TFDConnection.Create(nil);
    try
      Connection.LoginPrompt := False;
      Connection.DriverName := 'SQLite';
      Connection.Params.Database := DatabaseFile;
      Connection.Connected := True;
      var Query := TFDQuery.Create(nil);
      try
        Query.Connection := Connection;
        Query.SQL.Text :=
          'SELECT SecretProtected FROM BSUserTotp WHERE UserID = :UserID';
        Query.ParamByName('UserID').AsInteger := User.ID;
        Query.Open;
        Check(not Query.Eof, 'The enrolled factor record should exist');
        Check(Query.Fields[0].AsString <> Secret,
          'The TOTP secret must be encrypted at rest');
        Query.Close;
        Query.SQL.Text :=
          'SELECT COUNT(*) FROM BSRecoveryCodes WHERE UserID = :UserID ' +
          'AND CodeHash = :CodeHash';
        Query.ParamByName('UserID').AsInteger := User.ID;
        Query.ParamByName('CodeHash').AsString :=
          RecoveryCodeHash(ReusedRecoveryCode);
        Query.Open;
        CheckEquals(0, Query.Fields[0].AsInteger,
          'A used recovery code must be removed');
      finally
        Query.Free;
      end;
    finally
      Connection.Free;
    end;
  finally
    TDirectory.Delete(TestDirectory, True);
  end;
end;

procedure TAdminBootstrapTests.ExpiresAndRateLimitsTotpEnrollment;
begin
  var TestDirectory := NewTestDirectory;
  var DatabaseFile := TPath.Combine(TestDirectory, 'BrickStack.db');
  try
    InitializeBrickStackDatabase(DatabaseFile);
    EnsureInitialAdmin(DatabaseFile);
    Check(ReplaceInitialAdminPassword(DatabaseFile, 'Admin', 'Admin',
      'A-long-new-password'));
    var User: TAuthenticatedUser;
    var SessionToken: string;
    Check(AuthenticateAndCreateSession(DatabaseFile, 'Admin',
      'A-long-new-password', User, SessionToken));
    var Secret: string;
    var ProvisioningUri: string;
    Check(StartTotpEnrollment(DatabaseFile, SessionToken, Secret,
      ProvisioningUri));

    var Connection := TFDConnection.Create(nil);
    var Query: TFDQuery;
    try
      Connection.LoginPrompt := False;
      Connection.DriverName := 'SQLite';
      Connection.Params.Database := DatabaseFile;
      Connection.Connected := True;
      Query := TFDQuery.Create(nil);
      try
        Query.Connection := Connection;
        Query.SQL.Text := 'UPDATE BSUserTotp SET PendingExpiresAt = 0';
        Query.ExecSQL;
      finally
        Query.Free;
      end;
    finally
      Connection.Free;
    end;

    var RecoveryCodes: TArray<string>;
    Check(not ConfirmTotpEnrollment(DatabaseFile, SessionToken, '000000',
      RecoveryCodes), 'An expired enrollment must not be confirmed');
    Check(StartTotpEnrollment(DatabaseFile, SessionToken, Secret,
      ProvisioningUri));
    var NowUnix := DateTimeToUnix(Now);
    var MatchedCounter: Int64;
    var CodeValue := 0;
    var Code: string;
    var CandidateIsValid: Boolean;
    repeat
      Code := IntToStr(CodeValue);
      while Length(Code) < 6 do
        Code := '0' + Code;
      CandidateIsValid :=
        TryVerifyTotpCode(Secret, Code, NowUnix - 30, MatchedCounter) or
        TryVerifyTotpCode(Secret, Code, NowUnix, MatchedCounter) or
        TryVerifyTotpCode(Secret, Code, NowUnix + 30, MatchedCounter);
      if CandidateIsValid then
        Inc(CodeValue);
    until not CandidateIsValid;

    for var I := 1 to 5 do
      Check(not ConfirmTotpEnrollment(DatabaseFile, SessionToken, Code,
        RecoveryCodes), 'An invalid enrollment code must be rejected');
    Check(not ConfirmTotpEnrollment(DatabaseFile, SessionToken,
      TestTotpCode(Secret, NowUnix), RecoveryCodes),
      'An active factor lockout must reject even a correct code');

    Connection := TFDConnection.Create(nil);
    try
      Connection.LoginPrompt := False;
      Connection.DriverName := 'SQLite';
      Connection.Params.Database := DatabaseFile;
      Connection.Connected := True;
      Query := TFDQuery.Create(nil);
      try
        Query.Connection := Connection;
        Query.SQL.Text :=
          'SELECT FailureCount, LockedUntil FROM BSLoginFailures';
        Query.Open;
        Check(not Query.Eof);
        var FailureCount := Query.FieldByName('FailureCount').AsInteger;
        var LockedUntil := Query.FieldByName('LockedUntil').AsLargeInt;
        CheckEquals(5, FailureCount);
        Check(LockedUntil > NowUnix);
      finally
        Query.Free;
      end;
    finally
      Connection.Free;
    end;
  finally
    TDirectory.Delete(TestDirectory, True);
  end;
end;

procedure TAdminBootstrapTests.ProvisionsUserWithOneTimePasswordAndRequiredChange;
begin
  var TestDirectory := NewTestDirectory;
  var DatabaseFile := TPath.Combine(TestDirectory, 'BrickStack.db');
  try
    InitializeBrickStackDatabase(DatabaseFile);
    EnsureInitialAdmin(DatabaseFile);

    var TemporaryPassword: string;
    var Account := CreateUserAccount(DatabaseFile, 'alice.user', 'Alice User',
      TemporaryPassword);
    Check(Account.ID > 0, 'The provisioned account should have an ID');
    CheckEquals('alice.user', Account.UserName);
    CheckEquals('Alice User', Account.DisplayName);
    CheckEquals(cRoleUser, Account.Role,
      'Provisioning must create an ordinary user only');
    Check(Account.IsEnabled, 'The provisioned account should be enabled');
    Check(Account.MustChangePassword,
      'The one-time temporary password must be replaced');
    CheckEquals(64, Length(TemporaryPassword),
      'The temporary password should have 256 bits of random entropy');
    var User: TAuthenticatedUser;
    var SessionToken: string;
    Check(not AuthenticateAndCreateSession(DatabaseFile, Account.UserName,
      TemporaryPassword, User, SessionToken),
      'An invited user must change the temporary password before sign-in');
    Check(ReplaceRequiredUserPassword(DatabaseFile, Account.UserName,
      TemporaryPassword, 'A-permanent-user-password'));
    Check(AuthenticateAndCreateSession(DatabaseFile, 'ALICE.USER',
      'A-permanent-user-password', User, SessionToken),
      'The user should authenticate after replacing the temporary password');
    CheckEquals(Account.ID, User.ID);

    var Accounts := ListUserAccounts(DatabaseFile);
    CheckEquals(2, Length(Accounts),
      'The account list should include the admin and provisioned user');
    CheckEquals('Admin', Accounts[0].UserName);
    CheckEquals('alice.user', Accounts[1].UserName);
    Check(not Accounts[1].MustChangePassword,
      'The account list should reflect completed password replacement');

    var DuplicateRejected := False;
    var DuplicatePassword: string;
    try
      CreateUserAccount(DatabaseFile, 'ALICE.USER', 'Duplicate',
        DuplicatePassword);
    except
      on E: EAccountConflict do
        DuplicateRejected := True;
    end;
    Check(DuplicateRejected,
      'Usernames must be unique regardless of letter case');
    CheckEquals('', DuplicatePassword,
      'A failed provisioning request must not return a temporary password');
  finally
    TDirectory.Delete(TestDirectory, True);
  end;
end;

initialization
  RegisterTest(TAdminBootstrapTests.Suite);

end.
