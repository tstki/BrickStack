unit UBSDatabaseBootstrapTests;

interface

uses
  TestFramework;

type
  TDatabaseBootstrapTests = class(TTestCase)
  published
    procedure CreatesAndReopensBrickStackSchema;
    procedure UpgradesVersionZeroDatabase;
    procedure UpgradesVersionOneDatabasePreservingUsers;
    procedure UpgradesVersionThreeDatabase;
    procedure RejectsIncompatibleVersionZeroDatabase;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  FireDAC.Comp.Client,
  UBSAdminBootstrap,
  UBSDatabaseBootstrap;

function NewTestDirectory: string;
begin
  var Guid: TGUID;
  CreateGUID(Guid);
  Result := TPath.Combine(TPath.GetTempPath,
    'BrickStack2-' + GUIDToString(Guid));
  TDirectory.CreateDirectory(Result);
end;

procedure TDatabaseBootstrapTests.CreatesAndReopensBrickStackSchema;
begin
  var TestDirectory := NewTestDirectory;
  var DatabaseFile := TPath.Combine(TestDirectory, 'BrickStack.db');
  try
    InitializeBrickStackDatabase(DatabaseFile);
    InitializeBrickStackDatabase(DatabaseFile);

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
          'SELECT COUNT(*) FROM sqlite_master WHERE type = ''table'' ' +
          'AND name NOT LIKE ''sqlite_%''';
        Query.Open;
        var TableCount := Query.Fields[0].AsInteger;
        CheckEquals(14, TableCount,
          'Fresh database should contain the version and user-data tables');

        Query.Close;
        Query.SQL.Text := 'SELECT COUNT(*) FROM BSSchemaVersions WHERE Version = 4';
        Query.Open;
        CheckEquals(1, Query.Fields[0].AsInteger,
          'Fresh schema should be recorded once');
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

procedure TDatabaseBootstrapTests.UpgradesVersionZeroDatabase;
begin
  var TestDirectory := NewTestDirectory;
  var DatabaseFile := TPath.Combine(TestDirectory, 'BrickStack.db');
  try
    var Connection := TFDConnection.Create(nil);
    try
      Connection.LoginPrompt := False;
      Connection.DriverName := 'SQLite';
      Connection.Params.Database := DatabaseFile;
      Connection.Connected := True;
    finally
      Connection.Free;
    end;

    InitializeBrickStackDatabase(DatabaseFile);

    Connection := TFDConnection.Create(nil);
    try
      Connection.LoginPrompt := False;
      Connection.DriverName := 'SQLite';
      Connection.Params.Database := DatabaseFile;
      Connection.Connected := True;
      var Query := TFDQuery.Create(nil);
      try
        Query.Connection := Connection;
        Query.SQL.Text := 'SELECT MAX(Version) FROM BSSchemaVersions';
        Query.Open;
        CheckEquals(4, Query.Fields[0].AsInteger,
          'An unversioned database should migrate to the current version');
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

procedure TDatabaseBootstrapTests.UpgradesVersionOneDatabasePreservingUsers;
begin
  var TestDirectory := NewTestDirectory;
  var DatabaseFile := TPath.Combine(TestDirectory, 'BrickStack.db');
  try
    InitializeBrickStackDatabase(DatabaseFile);
    EnsureInitialAdmin(DatabaseFile);

    var Query: TFDQuery;
    var Connection := TFDConnection.Create(nil);
    try
      Connection.LoginPrompt := False;
      Connection.DriverName := 'SQLite';
      Connection.Params.Database := DatabaseFile;
      Connection.Connected := True;
      Query := TFDQuery.Create(nil);
      try
        Query.Connection := Connection;
        Query.SQL.Text := 'DROP TABLE BSLoginFailures';
        Query.ExecSQL;
        Query.SQL.Text := 'DROP TABLE BSRecoveryCodes';
        Query.ExecSQL;
        Query.SQL.Text := 'DROP TABLE BSUserTotp';
        Query.ExecSQL;
        Query.SQL.Text := 'DROP TABLE BSSessions';
        Query.ExecSQL;
        Query.SQL.Text := 'DROP INDEX BSUsers_UserName_CI_IDX';
        Query.ExecSQL;
        Query.SQL.Text := 'DELETE FROM BSSchemaVersions';
        Query.ExecSQL;
        Query.SQL.Text :=
          'INSERT INTO BSSchemaVersions (Version) VALUES (1)';
        Query.ExecSQL;
      finally
        Query.Free;
      end;
    finally
      Connection.Free;
    end;

    InitializeBrickStackDatabase(DatabaseFile);
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
          'SELECT (SELECT MAX(Version) FROM BSSchemaVersions), ' +
          '(SELECT COUNT(*) FROM BSUsers WHERE UserName = ''Admin''), ' +
          '(SELECT COUNT(*) FROM sqlite_master WHERE type = ''table'' ' +
          'AND name IN (''BSSessions'', ''BSLoginFailures'', ' +
          '''BSUserTotp'', ''BSRecoveryCodes''))';
        Query.Open;
        CheckEquals(4, Query.Fields[0].AsInteger,
          'Version one should migrate to current schema');
        CheckEquals(1, Query.Fields[1].AsInteger,
          'The user table must be preserved during migration');
        CheckEquals(4, Query.Fields[2].AsInteger,
          'The authentication and second-factor tables should be added');
        Query.Close;
        Query.SQL.Text :=
          'SELECT COUNT(*) FROM sqlite_master WHERE type = ''index'' ' +
          'AND name = ''BSUsers_UserName_CI_IDX''';
        Query.Open;
        CheckEquals(1, Query.Fields[0].AsInteger,
          'Version three should add case-insensitive username uniqueness');
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

procedure TDatabaseBootstrapTests.UpgradesVersionThreeDatabase;
begin
  var TestDirectory := NewTestDirectory;
  var DatabaseFile := TPath.Combine(TestDirectory, 'BrickStack.db');
  try
    InitializeBrickStackDatabase(DatabaseFile);
    EnsureInitialAdmin(DatabaseFile);

    var Query: TFDQuery;
    var Connection := TFDConnection.Create(nil);
    try
      Connection.LoginPrompt := False;
      Connection.DriverName := 'SQLite';
      Connection.Params.Database := DatabaseFile;
      Connection.Connected := True;
      Query := TFDQuery.Create(nil);
      try
        Query.Connection := Connection;
        Query.SQL.Text := 'DROP TABLE BSRecoveryCodes';
        Query.ExecSQL;
        Query.SQL.Text := 'DROP TABLE BSUserTotp';
        Query.ExecSQL;
        Query.SQL.Text := 'DELETE FROM BSSchemaVersions';
        Query.ExecSQL;
        Query.SQL.Text :=
          'INSERT INTO BSSchemaVersions (Version) VALUES (3)';
        Query.ExecSQL;
      finally
        Query.Free;
      end;
    finally
      Connection.Free;
    end;

    InitializeBrickStackDatabase(DatabaseFile);
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
          'SELECT (SELECT MAX(Version) FROM BSSchemaVersions), ' +
          '(SELECT COUNT(*) FROM BSUsers WHERE UserName = ''Admin''), ' +
          '(SELECT COUNT(*) FROM sqlite_master WHERE type = ''table'' ' +
          'AND name IN (''BSUserTotp'', ''BSRecoveryCodes''))';
        Query.Open;
        CheckEquals(4, Query.Fields[0].AsInteger);
        CheckEquals(1, Query.Fields[1].AsInteger);
        CheckEquals(2, Query.Fields[2].AsInteger);
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

procedure TDatabaseBootstrapTests.RejectsIncompatibleVersionZeroDatabase;
begin
  var TestDirectory := NewTestDirectory;
  var DatabaseFile := TPath.Combine(TestDirectory, 'BrickStack.db');
  var Rejected := False;
  try
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
        Query.SQL.Text := 'CREATE TABLE BSSetLists (ID INTEGER PRIMARY KEY)';
        Query.ExecSQL;
      finally
        Query.Free;
      end;
    finally
      Connection.Free;
    end;

    try
      InitializeBrickStackDatabase(DatabaseFile);
    except
      on Exception do
        Rejected := True;
    end;
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
          'SELECT COUNT(*) FROM sqlite_master WHERE type = ''table'' ' +
          'AND name = ''BSUsers''';
        Query.Open;
        CheckEquals(0, Query.Fields[0].AsInteger,
          'A failed version-zero migration must not leave partial BS2 tables');
      finally
        Query.Free;
      end;
    finally
      Connection.Free;
    end;
    Check(Rejected,
      'An incompatible pre-versioned schema must fail without being adopted');
  finally
    TDirectory.Delete(TestDirectory, True);
  end;
end;

initialization
  RegisterTest(TDatabaseBootstrapTests.Suite);

end.
