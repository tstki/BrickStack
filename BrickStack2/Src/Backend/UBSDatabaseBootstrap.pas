unit UBSDatabaseBootstrap;

interface

procedure InitializeDatabases;
procedure InitializeBrickStackDatabase(const AFileName: string);

implementation

uses
  System.Classes,
  System.Hash,
  System.IOUtils,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.RegularExpressions,
  System.SysUtils,
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.Stan.Def,
  FireDAC.Stan.Param,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  ZLib,
  UBSAdminBootstrap;

const
  cDatabaseDirectory = 'DBase';
  cBrickStackDatabase = 'BrickStack.db';
  cCatalogDatabase = 'rb.db';
  cCatalogArchive = 'rb.db.gz';
  cCatalogChecksum = 'rb.db.sha256';
  cCatalogArchiveUrl =
    'https://github.com/ojuuji/rb.db/releases/download/latest/rb.db.gz';
  cCatalogChecksumUrl =
    'https://github.com/ojuuji/rb.db/releases/download/latest/rb.db.sha256';
  cBrickStackSchemaVersion = 4;

var
  GSQLiteDriverLink: TFDPhysSQLiteDriverLink;

procedure LogDatabaseMessage(const AMessage: string);
begin
  Writeln(FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now),
    ' [BrickStack2 backend] ', AMessage);
end;

function NewConnection(const AFileName: string): TFDConnection;
begin
  Result := TFDConnection.Create(nil);
  try
    Result.LoginPrompt := False;
    Result.DriverName := 'SQLite';
    Result.Params.Database := AFileName;
    Result.Params.Values['ForeignKeys'] := 'Yes';
    Result.Connected := True;
  except
    Result.Free;
    raise;
  end;
end;

procedure ValidateDatabaseIntegrity(const AFileName: string);
begin
  var Connection := NewConnection(AFileName);
  try
    var Query := TFDQuery.Create(nil);
    try
      Query.Connection := Connection;
      Query.SQL.Text := 'PRAGMA quick_check';
      Query.Open;
      var HasResult := False;
      while not Query.Eof do begin
        HasResult := True;
        if not SameText(Query.Fields[0].AsString, 'ok') then
          raise Exception.CreateFmt(
            'Database integrity check failed for "%s".', [AFileName]);
        Query.Next;
      end;
      if not HasResult then
        raise Exception.CreateFmt(
          'Database integrity check returned no result for "%s".',
          [AFileName]);
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

procedure ValidateCatalogDatabase(const AFileName: string);
begin
  ValidateDatabaseIntegrity(AFileName);
  var Connection := NewConnection(AFileName);
  try
    var Query := TFDQuery.Create(nil);
    try
      Query.Connection := Connection;
      Query.SQL.Text :=
        'SELECT name FROM sqlite_master WHERE type = ''table'' ' +
        'AND name IN (''sets'', ''parts'')';
      Query.Open;
      var HasSets := False;
      var HasParts := False;
      while not Query.Eof do begin
        if SameText(Query.Fields[0].AsString, 'sets') then
          HasSets := True
        else if SameText(Query.Fields[0].AsString, 'parts') then
          HasParts := True;
        Query.Next;
      end;
      if not (HasSets and HasParts) then
        raise Exception.CreateFmt(
          'The Rebrickable database "%s" is missing required tables.',
          [AFileName]);
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

function DownloadFile(const AUrl, AFileName: string): Integer;
begin
  LogDatabaseMessage('Downloading ' + TPath.GetFileName(AFileName) + '.');
  var Client := THTTPClient.Create;
  try
    Client.ConnectionTimeout := 15000;
    Client.ResponseTimeout := 120000;
    var Stream := TFileStream.Create(AFileName, fmCreate);
    try
      var Response := Client.Get(AUrl, Stream);
      Result := Response.StatusCode;
      LogDatabaseMessage(Format('Download of %s finished with HTTP %d.',
        [TPath.GetFileName(AFileName), Result]));
    finally
      Stream.Free;
    end;
  finally
    Client.Free;
  end;
end;

function GetSHA256(const AFileName: string): string;
begin
  var Hash := THashSHA2.Create(SHA256);
  var Stream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    Result := THash.DigestAsString(Hash.GetHashBytes(Stream));
  finally
    Stream.Free;
  end;
end;

function ReadExpectedSHA256(const AFileName: string): string;
begin
  var Contents := Trim(TFile.ReadAllText(AFileName, TEncoding.ASCII));
  Result := Copy(Contents, 1, 64);
  if (Length(Result) <> 64) or
    not TRegEx.IsMatch(Result, '^[0-9a-fA-F]{64}$') then
    raise Exception.Create('The Rebrickable checksum file is invalid.');
end;

procedure DecompressGZip(const ASourceFile, ADestinationFile: string);
begin
  var SourceStream := TFileStream.Create(ASourceFile, fmOpenRead or fmShareDenyWrite);
  try
    var DecompressionStream := TDecompressionStream.Create(SourceStream, 31);
    try
      var DestinationStream := TFileStream.Create(ADestinationFile, fmCreate);
      try
        DestinationStream.CopyFrom(DecompressionStream, 0);
      finally
        DestinationStream.Free;
      end;
    finally
      DecompressionStream.Free;
    end;
  finally
    SourceStream.Free;
  end;
end;

procedure EnsureCatalogDatabase(const ADirectory: string);
begin
  var CatalogFile := TPath.Combine(ADirectory, cCatalogDatabase);
  if TFile.Exists(CatalogFile) then begin
    LogDatabaseMessage('Found DBase\' + cCatalogDatabase + '; validating it.');
    ValidateCatalogDatabase(CatalogFile);
    LogDatabaseMessage(
      'Existing Rebrickable catalog passed integrity and schema checks.');
    Exit;
  end;

  LogDatabaseMessage(
    'Rebrickable catalog is missing; downloading the published database and checksum.');
  var WorkDirectory := TPath.Combine(ADirectory,
    'rb-download-' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(WorkDirectory);
  try
    var ArchiveFile := TPath.Combine(WorkDirectory, cCatalogArchive);
    var ChecksumFile := TPath.Combine(WorkDirectory, cCatalogChecksum);
    var CandidateFile := TPath.Combine(WorkDirectory, cCatalogDatabase);

    var StatusCode := DownloadFile(cCatalogArchiveUrl, ArchiveFile);
    if StatusCode <> 200 then
      raise Exception.CreateFmt(
        'Downloading the Rebrickable database archive failed (HTTP %d).',
        [StatusCode]);
    LogDatabaseMessage(Format('Downloaded %s (%s).', [cCatalogArchive,
        FormatFloat('#,##0', TFile.GetSize(ArchiveFile)) + ' bytes']));
    if TFile.GetSize(ArchiveFile) = 0 then
      raise Exception.Create('The Rebrickable database archive is empty.');

    LogDatabaseMessage('Downloading Rebrickable SHA-256 sidecar.');
    StatusCode := DownloadFile(cCatalogChecksumUrl, ChecksumFile);
    if StatusCode <> 200 then
      raise Exception.CreateFmt(
        'Downloading the Rebrickable checksum failed (HTTP %d).',
        [StatusCode]);

    LogDatabaseMessage('Decompressing Rebrickable catalog to a staging file.');
    var ExpectedHash := ReadExpectedSHA256(ChecksumFile);
    DecompressGZip(ArchiveFile, CandidateFile);
    LogDatabaseMessage('Verifying the decompressed catalog SHA-256.');
    if not SameText(GetSHA256(CandidateFile), ExpectedHash) then
      raise Exception.Create(
        'The Rebrickable database failed SHA-256 verification.');
    LogDatabaseMessage(
      'Catalog checksum passed; validating SQLite integrity and required tables.');
    ValidateCatalogDatabase(CandidateFile);
    LogDatabaseMessage('Catalog validation passed; installing DBase\' +
      cCatalogDatabase + '.');
    TFile.Move(CandidateFile, CatalogFile);
    LogDatabaseMessage('Rebrickable catalog installed successfully.');
  finally
    TDirectory.Delete(WorkDirectory, True);
  end;
end;

procedure ValidateBrickStackSchema(const AConnection: TFDConnection); forward;

procedure CreateBrickStackSchema(const AConnection: TFDConnection);
const
  cSchemaSQL: array[0..17] of string = (
    'CREATE TABLE IF NOT EXISTS BSUsers (' +
      'ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,' +
      'UserName TEXT NOT NULL UNIQUE,' +
      'DisplayName TEXT NOT NULL,' +
      'PasswordHash TEXT NOT NULL,' +
      'PasswordSalt TEXT NOT NULL,' +
      'PasswordAlgorithm TEXT NOT NULL,' +
      'Role INTEGER NOT NULL,' +
      'IsEnabled INTEGER NOT NULL DEFAULT 1,' +
      'MustChangePassword INTEGER NOT NULL DEFAULT 1,' +
      'CreatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)',
    'CREATE TABLE IF NOT EXISTS BSUserSettings (' +
      'UserID INTEGER NOT NULL,' +
      'SettingName TEXT NOT NULL,' +
      'SettingValue TEXT,' +
      'PRIMARY KEY (UserID, SettingName),' +
      'FOREIGN KEY (UserID) REFERENCES BSUsers(ID) ON DELETE CASCADE)',
    'CREATE TABLE IF NOT EXISTS BSCollections (' +
      'ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,' +
      'UserID INTEGER NOT NULL,' +
      'Name TEXT NOT NULL,' +
      'IsPublic INTEGER NOT NULL DEFAULT 0,' +
      'CreatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,' +
      'UNIQUE (UserID, Name),' +
      'FOREIGN KEY (UserID) REFERENCES BSUsers(ID) ON DELETE CASCADE)',
    'CREATE TABLE IF NOT EXISTS BSSetLists (' +
      'ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,' +
      'CollectionID INTEGER NOT NULL,' +
      'Name TEXT,' +
      'Description TEXT,' +
      'UseInCollection INTEGER,' +
      'SortIndex INTEGER,' +
      'ExternalID INTEGER,' +
      'ExternalType INTEGER,' +
      'FOREIGN KEY (CollectionID) REFERENCES BSCollections(ID) ON DELETE CASCADE)',
    'CREATE TABLE IF NOT EXISTS BSSets (' +
      'ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,' +
      'BSSetListID INTEGER NOT NULL,' +
      'set_num TEXT NOT NULL,' +
      'Built INTEGER,' +
      'HaveSpareParts INTEGER,' +
      'Notes TEXT,' +
      'FOREIGN KEY (BSSetListID) REFERENCES BSSetLists(ID) ON DELETE CASCADE)',
    'CREATE TABLE IF NOT EXISTS BSCustomTags (' +
      'ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,' +
      'LinkedID INTEGER,' +
      'CustomType INTEGER,' +
      'Value TEXT)',
    'CREATE TABLE IF NOT EXISTS BSDBPartsInventory (' +
      'ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,' +
      'BSSetID INTEGER NOT NULL,' +
      'InventoryID INTEGER,' +
      'Part_num TEXT,' +
      'color_id INTEGER,' +
      'is_spare INTEGER,' +
      'quantity INTEGER,' +
      'FOREIGN KEY (BSSetID) REFERENCES BSSets(ID) ON DELETE CASCADE)',
    'CREATE TABLE IF NOT EXISTS BSPartLists (' +
      'ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,' +
      'CollectionID INTEGER NOT NULL,' +
      'Name TEXT NOT NULL,' +
      'SortIndex INTEGER,' +
      'UNIQUE (CollectionID, Name),' +
      'FOREIGN KEY (CollectionID) REFERENCES BSCollections(ID) ON DELETE CASCADE)',
    'CREATE TABLE IF NOT EXISTS BSLooseParts (' +
      'ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,' +
      'BSPartListID INTEGER NOT NULL,' +
      'Part_num TEXT NOT NULL,' +
      'color_id INTEGER NOT NULL,' +
      'quantity INTEGER NOT NULL DEFAULT 0,' +
      'FOREIGN KEY (BSPartListID) REFERENCES BSPartLists(ID) ON DELETE CASCADE)',
    'CREATE TABLE IF NOT EXISTS BSSchemaVersions (' +
      'Version INTEGER NOT NULL PRIMARY KEY,' +
      'AppliedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)',
    'CREATE INDEX IF NOT EXISTS BSSetLists_CollectionID_IDX ON BSSetLists (CollectionID)',
    'CREATE INDEX IF NOT EXISTS BSSets_SetListID_IDX ON BSSets (BSSetListID)',
    'CREATE UNIQUE INDEX IF NOT EXISTS BSUsers_UserName_CI_IDX ON BSUsers (UserName COLLATE NOCASE)',
    'CREATE TABLE IF NOT EXISTS BSSessions (' +
      'SessionHash TEXT NOT NULL PRIMARY KEY,' +
      'UserID INTEGER NOT NULL,' +
      'CreatedAt INTEGER NOT NULL,' +
      'ExpiresAt INTEGER NOT NULL,' +
      'FOREIGN KEY (UserID) REFERENCES BSUsers(ID) ON DELETE CASCADE)',
    'CREATE INDEX IF NOT EXISTS BSSessions_UserID_IDX ON BSSessions (UserID)',
    'CREATE TABLE IF NOT EXISTS BSLoginFailures (' +
      'UserID INTEGER NOT NULL PRIMARY KEY,' +
      'FailureCount INTEGER NOT NULL,' +
      'WindowStartedAt INTEGER NOT NULL,' +
      'LockedUntil INTEGER NOT NULL DEFAULT 0,' +
      'FOREIGN KEY (UserID) REFERENCES BSUsers(ID) ON DELETE CASCADE)',
    'CREATE TABLE IF NOT EXISTS BSUserTotp (' +
      'UserID INTEGER NOT NULL PRIMARY KEY,' +
      'SecretProtected TEXT,' +
      'EnabledAt INTEGER,' +
      'LastCounter INTEGER NOT NULL DEFAULT -1,' +
      'PendingSecretProtected TEXT,' +
      'PendingExpiresAt INTEGER,' +
      'FOREIGN KEY (UserID) REFERENCES BSUsers(ID) ON DELETE CASCADE)',
    'CREATE TABLE IF NOT EXISTS BSRecoveryCodes (' +
      'UserID INTEGER NOT NULL,' +
      'CodeHash TEXT NOT NULL,' +
      'CreatedAt INTEGER NOT NULL,' +
      'PRIMARY KEY (UserID, CodeHash),' +
      'FOREIGN KEY (UserID) REFERENCES BSUsers(ID) ON DELETE CASCADE)'
  );
var
  I: Integer;
  Query: TFDQuery;
begin
  LogDatabaseMessage('Creating BrickStack database schema version ' +
    IntToStr(cBrickStackSchemaVersion) + '.');
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := AConnection;
    AConnection.StartTransaction;
    try
      for I := Low(cSchemaSQL) to High(cSchemaSQL) do begin
        Query.SQL.Text := cSchemaSQL[I];
        Query.ExecSQL;
      end;
      Query.SQL.Text :=
        'INSERT INTO BSSchemaVersions (Version) VALUES (:Version)';
      Query.ParamByName('Version').AsInteger := cBrickStackSchemaVersion;
      Query.ExecSQL;
      ValidateBrickStackSchema(AConnection);
      AConnection.Commit;
    except
      AConnection.Rollback;
      raise;
    end;
  finally
    Query.Free;
  end;
end;

procedure MigrateBrickStackVersionOne(const AConnection: TFDConnection);
begin
  LogDatabaseMessage('Applying BrickStack database migration from version 1.');
  var Query := TFDQuery.Create(nil);
  try
    Query.Connection := AConnection;
    AConnection.StartTransaction;
    try
      Query.SQL.Text :=
        'CREATE TABLE BSSessions (' +
        'SessionHash TEXT NOT NULL PRIMARY KEY,' +
        'UserID INTEGER NOT NULL,' +
        'CreatedAt INTEGER NOT NULL,' +
        'ExpiresAt INTEGER NOT NULL,' +
        'FOREIGN KEY (UserID) REFERENCES BSUsers(ID) ON DELETE CASCADE)';
      Query.ExecSQL;
      Query.SQL.Text :=
        'CREATE INDEX BSSessions_UserID_IDX ON BSSessions (UserID)';
      Query.ExecSQL;
      Query.SQL.Text :=
        'CREATE TABLE BSLoginFailures (' +
        'UserID INTEGER NOT NULL PRIMARY KEY,' +
        'FailureCount INTEGER NOT NULL,' +
        'WindowStartedAt INTEGER NOT NULL,' +
        'LockedUntil INTEGER NOT NULL DEFAULT 0,' +
        'FOREIGN KEY (UserID) REFERENCES BSUsers(ID) ON DELETE CASCADE)';
      Query.ExecSQL;
      Query.SQL.Text :=
        'INSERT INTO BSSchemaVersions (Version) VALUES (:Version)';
      Query.ParamByName('Version').AsInteger := 2;
      Query.ExecSQL;
      AConnection.Commit;
    except
      AConnection.Rollback;
      raise;
    end;
  finally
    Query.Free;
  end;
end;

procedure MigrateBrickStackVersionTwo(const AConnection: TFDConnection);
begin
  LogDatabaseMessage('Applying BrickStack database migration from version 2.');
  var Query := TFDQuery.Create(nil);
  try
    Query.Connection := AConnection;
    AConnection.StartTransaction;
    try
      Query.SQL.Text :=
        'CREATE UNIQUE INDEX BSUsers_UserName_CI_IDX ' +
        'ON BSUsers (UserName COLLATE NOCASE)';
      Query.ExecSQL;
      Query.SQL.Text :=
        'INSERT INTO BSSchemaVersions (Version) VALUES (:Version)';
      Query.ParamByName('Version').AsInteger := 3;
      Query.ExecSQL;
      AConnection.Commit;
    except
      AConnection.Rollback;
      raise;
    end;
  finally
    Query.Free;
  end;
end;

procedure MigrateBrickStackVersionThree(const AConnection: TFDConnection);
begin
  LogDatabaseMessage('Applying BrickStack database migration from version 3.');
  var Query := TFDQuery.Create(nil);
  try
    Query.Connection := AConnection;
    AConnection.StartTransaction;
    try
      Query.SQL.Text :=
        'CREATE TABLE BSUserTotp (' +
        'UserID INTEGER NOT NULL PRIMARY KEY,' +
        'SecretProtected TEXT,' +
        'EnabledAt INTEGER,' +
        'LastCounter INTEGER NOT NULL DEFAULT -1,' +
        'PendingSecretProtected TEXT,' +
        'PendingExpiresAt INTEGER,' +
        'FOREIGN KEY (UserID) REFERENCES BSUsers(ID) ON DELETE CASCADE)';
      Query.ExecSQL;
      Query.SQL.Text :=
        'CREATE TABLE BSRecoveryCodes (' +
        'UserID INTEGER NOT NULL,' +
        'CodeHash TEXT NOT NULL,' +
        'CreatedAt INTEGER NOT NULL,' +
        'PRIMARY KEY (UserID, CodeHash),' +
        'FOREIGN KEY (UserID) REFERENCES BSUsers(ID) ON DELETE CASCADE)';
      Query.ExecSQL;
      Query.SQL.Text :=
        'INSERT INTO BSSchemaVersions (Version) VALUES (:Version)';
      Query.ParamByName('Version').AsInteger := 4;
      Query.ExecSQL;
      ValidateBrickStackSchema(AConnection);
      AConnection.Commit;
    except
      AConnection.Rollback;
      raise;
    end;
  finally
    Query.Free;
  end;
end;

procedure ValidateBrickStackSchema(const AConnection: TFDConnection);
const
  cRequiredColumns: array[0..13] of string = (
    'BSUsers|ID|UserName|DisplayName|PasswordHash|PasswordSalt|' +
      'PasswordAlgorithm|Role|IsEnabled|MustChangePassword|CreatedAt',
    'BSUserSettings|UserID|SettingName|SettingValue',
    'BSCollections|ID|UserID|Name|IsPublic|CreatedAt',
    'BSSetLists|ID|CollectionID|Name|Description|UseInCollection|' +
      'SortIndex|ExternalID|ExternalType',
    'BSSets|ID|BSSetListID|set_num|Built|HaveSpareParts|Notes',
    'BSCustomTags|ID|LinkedID|CustomType|Value',
    'BSDBPartsInventory|ID|BSSetID|InventoryID|Part_num|color_id|' +
      'is_spare|quantity',
    'BSPartLists|ID|CollectionID|Name|SortIndex',
    'BSLooseParts|ID|BSPartListID|Part_num|color_id|quantity',
    'BSSchemaVersions|Version|AppliedAt',
    'BSSessions|SessionHash|UserID|CreatedAt|ExpiresAt',
    'BSLoginFailures|UserID|FailureCount|WindowStartedAt|LockedUntil',
    'BSUserTotp|UserID|SecretProtected|EnabledAt|LastCounter|' +
      'PendingSecretProtected|PendingExpiresAt',
    'BSRecoveryCodes|UserID|CodeHash|CreatedAt'
  );
var
  Query: TFDQuery;
  Required: TStringList;
  I: Integer;
  ColumnIndex: Integer;
  TableName: string;
begin
  Required := TStringList.Create;
  try
    Required.StrictDelimiter := True;
    Required.Delimiter := '|';
    Query := TFDQuery.Create(nil);
    try
      Query.Connection := AConnection;
      for I := Low(cRequiredColumns) to High(cRequiredColumns) do begin
        Required.Clear;
        Required.Text := StringReplace(cRequiredColumns[I], '|', sLineBreak,
          [rfReplaceAll]);
        TableName := Required[0];
        Required.Delete(0);
        Query.SQL.Text := Format('PRAGMA table_info("%s")', [TableName]);
        Query.Open;
        while not Query.Eof do begin
          ColumnIndex := Required.IndexOf(Query.FieldByName('name').AsString);
          if ColumnIndex >= 0 then
            Required.Delete(ColumnIndex);
          Query.Next;
        end;
        Query.Close;
        if Required.Count > 0 then
          raise Exception.CreateFmt(
            'The BrickStack database is missing columns from table "%s"; ' +
            'its version-zero schema is not supported for automatic startup.',
            [TableName]);
      end;
    finally
      Query.Free;
    end;
  finally
    Required.Free;
  end;
end;

procedure InitializeBrickStackDatabase(const AFileName: string);
begin
  ForceDirectories(TPath.GetDirectoryName(AFileName));
  if TFile.Exists(AFileName) then
    LogDatabaseMessage('Checking existing DBase\' + cBrickStackDatabase + '.')
  else
    LogDatabaseMessage('Creating DBase\' + cBrickStackDatabase + '.');
  var Connection := NewConnection(AFileName);
  try
    var Query := TFDQuery.Create(nil);
    try
      Query.Connection := Connection;
      Query.SQL.Text :=
        'SELECT COUNT(*) FROM sqlite_master WHERE type = ''table'' ' +
        'AND name = ''BSSchemaVersions''';
      Query.Open;
      if Query.Fields[0].AsInteger = 0 then begin
        Query.Close;
        CreateBrickStackSchema(Connection);
      end else begin
        Query.Close;
        Query.SQL.Text := 'SELECT MAX(Version) FROM BSSchemaVersions';
        Query.Open;
        var SchemaVersion := Query.Fields[0].AsInteger;
        if SchemaVersion > cBrickStackSchemaVersion then
          raise Exception.CreateFmt(
            'BrickStack database schema version %d is newer than supported version %d.',
            [SchemaVersion, cBrickStackSchemaVersion]);
        if SchemaVersion = 0 then begin
          LogDatabaseMessage(
            'Applying BrickStack database migration from version 0.');
          Query.Close;
          CreateBrickStackSchema(Connection);
          SchemaVersion := cBrickStackSchemaVersion;
        end else if SchemaVersion = 1 then begin
          Query.Close;
          MigrateBrickStackVersionOne(Connection);
          SchemaVersion := 2;
        end;
        if SchemaVersion = 2 then begin
          Query.Close;
          MigrateBrickStackVersionTwo(Connection);
          SchemaVersion := 3;
        end;
        if SchemaVersion = 3 then begin
          Query.Close;
          MigrateBrickStackVersionThree(Connection);
          SchemaVersion := 4;
        end else if SchemaVersion < cBrickStackSchemaVersion then
          raise Exception.CreateFmt(
            'No migration is available from BrickStack database schema version %d.',
            [SchemaVersion]);
        if SchemaVersion = cBrickStackSchemaVersion then
          LogDatabaseMessage('BrickStack database schema is current.');
      end;
      Query.Close;
      ValidateBrickStackSchema(Connection);
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
  ValidateDatabaseIntegrity(AFileName);
  LogDatabaseMessage('BrickStack database integrity and schema checks passed.');
end;

procedure InitializeDatabases;
begin
  var DatabaseDirectory := TPath.Combine(ExtractFilePath(ParamStr(0)),
    cDatabaseDirectory);
  LogDatabaseMessage('Initializing databases in ' + DatabaseDirectory + '.');
  ForceDirectories(DatabaseDirectory);

  EnsureCatalogDatabase(DatabaseDirectory);
  InitializeBrickStackDatabase(
    TPath.Combine(DatabaseDirectory, cBrickStackDatabase));
  EnsureInitialAdmin(TPath.Combine(DatabaseDirectory, cBrickStackDatabase));
  LogDatabaseMessage('Database initialization complete.');
end;

initialization
  GSQLiteDriverLink := TFDPhysSQLiteDriverLink.Create(nil);

finalization
  GSQLiteDriverLink.Free;

end.
