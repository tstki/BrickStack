unit UBSCollectionRepository;

interface

uses
  System.SysUtils;

type
  TUserCollection = record
    ID: Integer;
    Name: string;
    IsPublic: Boolean;
  end;
  TUserCollections = TArray<TUserCollection>;

  TUserSetList = record
    ID: Integer;
    CollectionID: Integer;
    Name: string;
    Description: string;
    UseInCollection: Boolean;
    SortIndex: Integer;
  end;
  TUserSetLists = TArray<TUserSetList>;

  TCollectionSet = record
    ID: Integer;
    SetListID: Integer;
    SetNumber: string;
    Built: Boolean;
    HaveSpareParts: Boolean;
    Notes: string;
  end;
  TCollectionSets = TArray<TCollectionSet>;

  ECollectionConflict = class(Exception);
  ECollectionItemNotFound = class(Exception);

  TUserCollectionRepository = class
  private
    FDatabaseFileName: string;
  public
    constructor Create(const ADatabaseFileName: string);
    function ListForUser(AUserID: Integer): TUserCollections;
    function TryGetForUser(AUserID, ACollectionID: Integer;
      out ACollection: TUserCollection): Boolean;
    function CreateForUser(AUserID: Integer; const AName: string): TUserCollection;
    function RenameForUser(AUserID, ACollectionID: Integer;
      const AName: string; out ACollection: TUserCollection): Boolean;
    function ListSetListsForUser(AUserID, ACollectionID: Integer): TUserSetLists;
    function TryGetSetListForUser(AUserID, ASetListID: Integer;
      out ASetList: TUserSetList): Boolean;
    function CreateSetListForUser(AUserID, ACollectionID: Integer;
      const AName, ADescription: string;
      AUseInCollection: Boolean): TUserSetList;
    function UpdateSetListForUser(AUserID, ASetListID: Integer;
      const AName, ADescription: string; AUseInCollection: Boolean): Boolean;
    function DeleteSetListForUser(AUserID, ASetListID: Integer): Boolean;
    function ListSetsForUser(AUserID, ASetListID: Integer): TCollectionSets;
    function TryGetSetForUser(AUserID, ASetID: Integer;
      out ASet: TCollectionSet): Boolean;
    function CreateSetForUser(AUserID, ASetListID: Integer;
      const ASetNumber: string; ABuilt, AHaveSpareParts: Boolean;
      const ANotes: string): TCollectionSet;
    function UpdateSetForUser(AUserID, ASetID: Integer;
      ABuilt, AHaveSpareParts: Boolean; const ANotes: string): Boolean;
    function DeleteSetForUser(AUserID, ASetID: Integer): Boolean;
  end;

implementation

uses
  System.IOUtils,
  System.Generics.Collections,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param;

constructor TUserCollectionRepository.Create(const ADatabaseFileName: string);
begin
  inherited Create;
  if ADatabaseFileName.Trim = '' then
    raise EArgumentException.Create('A BrickStack database path is required.');
  FDatabaseFileName := TPath.GetFullPath(ADatabaseFileName);
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

procedure ValidateUserID(AUserID: Integer);
begin
  if AUserID < 1 then
    raise EArgumentOutOfRangeException.Create('A valid user ID is required.');
end;

procedure ValidateRecordID(AID: Integer; const AName: string);
begin
  if AID < 1 then
    raise EArgumentOutOfRangeException.Create('A valid ' + AName + ' is required.');
end;

procedure ValidateSetListFields(const AName, ADescription: string);
begin
  if (AName.Trim = '') or (Length(AName.Trim) > 100) then
    raise EArgumentException.Create(
      'Set list name must contain between 1 and 100 characters.');
  if Length(ADescription) > 1000 then
    raise EArgumentException.Create('Set list description is too long.');
end;

procedure ValidateSetFields(const ASetNumber, ANotes: string);
begin
  if (ASetNumber.Trim = '') or (Length(ASetNumber.Trim) > 100) then
    raise EArgumentException.Create('A valid set number is required.');
  if Length(ANotes) > 2000 then
    raise EArgumentException.Create('Set notes are too long.');
end;

function SetListFromQuery(AQuery: TFDQuery): TUserSetList;
begin
  Result.ID := AQuery.FieldByName('ID').AsInteger;
  Result.CollectionID := AQuery.FieldByName('CollectionID').AsInteger;
  Result.Name := AQuery.FieldByName('Name').AsString;
  Result.Description := AQuery.FieldByName('Description').AsString;
  Result.UseInCollection := AQuery.FieldByName('UseInCollection').AsInteger <> 0;
  Result.SortIndex := AQuery.FieldByName('SortIndex').AsInteger;
end;

function CollectionSetFromQuery(AQuery: TFDQuery): TCollectionSet;
begin
  Result.ID := AQuery.FieldByName('ID').AsInteger;
  Result.SetListID := AQuery.FieldByName('BSSetListID').AsInteger;
  Result.SetNumber := AQuery.FieldByName('set_num').AsString;
  Result.Built := AQuery.FieldByName('Built').AsInteger <> 0;
  Result.HaveSpareParts := AQuery.FieldByName('HaveSpareParts').AsInteger <> 0;
  Result.Notes := AQuery.FieldByName('Notes').AsString;
end;

function TUserCollectionRepository.ListForUser(AUserID: Integer): TUserCollections;
begin
  ValidateUserID(AUserID);
  var Collections := TList<TUserCollection>.Create;
  try
    var Connection := NewConnection(FDatabaseFileName);
    try
      var Query := TFDQuery.Create(nil);
      try
        Query.Connection := Connection;
        Query.SQL.Text :=
          'SELECT ID, Name, IsPublic FROM BSCollections ' +
          'WHERE UserID = :UserID ORDER BY ID';
        Query.ParamByName('UserID').AsInteger := AUserID;
        Query.Open;
        while not Query.Eof do begin
          var Collection: TUserCollection;
          Collection.ID := Query.FieldByName('ID').AsInteger;
          Collection.Name := Query.FieldByName('Name').AsString;
          Collection.IsPublic := Query.FieldByName('IsPublic').AsInteger <> 0;
          Collections.Add(Collection);
          Query.Next;
        end;
        Result := Collections.ToArray;
      finally
        Query.Free;
      end;
    finally
      Connection.Free;
    end;
  finally
    Collections.Free;
  end;
end;

function TUserCollectionRepository.TryGetForUser(AUserID, ACollectionID: Integer;
  out ACollection: TUserCollection): Boolean;
begin
  ValidateUserID(AUserID);
  if ACollectionID < 1 then
    raise EArgumentOutOfRangeException.Create(
      'A valid collection ID is required.');
  ACollection := Default(TUserCollection);
  var Connection := NewConnection(FDatabaseFileName);
  try
    var Query := TFDQuery.Create(nil);
    try
      Query.Connection := Connection;
      Query.SQL.Text :=
        'SELECT ID, Name, IsPublic FROM BSCollections ' +
        'WHERE ID = :CollectionID AND UserID = :UserID';
      Query.ParamByName('CollectionID').AsInteger := ACollectionID;
      Query.ParamByName('UserID').AsInteger := AUserID;
      Query.Open;
      Result := not Query.Eof;
      if Result then begin
        ACollection.ID := Query.FieldByName('ID').AsInteger;
        ACollection.Name := Query.FieldByName('Name').AsString;
        ACollection.IsPublic := Query.FieldByName('IsPublic').AsInteger <> 0;
      end;
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

function TUserCollectionRepository.CreateForUser(AUserID: Integer;
  const AName: string): TUserCollection;
begin
  ValidateUserID(AUserID);
  var Name := AName.Trim;
  if (Name = '') or (Length(Name) > 100) then
    raise EArgumentException.Create(
      'Collection name must contain between 1 and 100 characters.');
  var Connection := NewConnection(FDatabaseFileName);
  try
    var Query := TFDQuery.Create(nil);
    try
      Query.Connection := Connection;
      Query.SQL.Text :=
        'INSERT INTO BSCollections (UserID, Name) ' +
        'VALUES (:UserID, :Name) ' +
        'ON CONFLICT(UserID, Name) DO NOTHING';
      Query.ParamByName('UserID').AsInteger := AUserID;
      Query.ParamByName('Name').AsString := Name;
      Query.ExecSQL;
      if Query.RowsAffected <> 1 then
        raise ECollectionConflict.Create('A collection with this name already exists.');
      Query.SQL.Text :=
        'SELECT ID, Name, IsPublic FROM BSCollections ' +
        'WHERE ID = last_insert_rowid() AND UserID = :UserID';
      Query.ParamByName('UserID').AsInteger := AUserID;
      Query.Open;
      if Query.Eof then
        raise Exception.Create('The created collection could not be read.');
      Result.ID := Query.FieldByName('ID').AsInteger;
      Result.Name := Query.FieldByName('Name').AsString;
      Result.IsPublic := Query.FieldByName('IsPublic').AsInteger <> 0;
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

function TUserCollectionRepository.RenameForUser(AUserID, ACollectionID: Integer;
  const AName: string; out ACollection: TUserCollection): Boolean;
begin
  ValidateUserID(AUserID);
  if ACollectionID < 1 then
    raise EArgumentOutOfRangeException.Create(
      'A valid collection ID is required.');
  var Name := AName.Trim;
  if (Name = '') or (Length(Name) > 100) then
    raise EArgumentException.Create(
      'Collection name must contain between 1 and 100 characters.');

  ACollection := Default(TUserCollection);
  var Connection := NewConnection(FDatabaseFileName);
  try
    var Query := TFDQuery.Create(nil);
    try
      Query.Connection := Connection;
      Query.SQL.Text :=
        'UPDATE OR IGNORE BSCollections SET Name = :Name ' +
        'WHERE ID = :CollectionID AND UserID = :UserID';
      Query.ParamByName('Name').AsString := Name;
      Query.ParamByName('CollectionID').AsInteger := ACollectionID;
      Query.ParamByName('UserID').AsInteger := AUserID;
      Query.ExecSQL;
      Query.SQL.Text :=
        'SELECT ID, Name, IsPublic FROM BSCollections ' +
        'WHERE ID = :CollectionID AND UserID = :UserID';
      Query.ParamByName('CollectionID').AsInteger := ACollectionID;
      Query.ParamByName('UserID').AsInteger := AUserID;
      Query.Open;
      Result := not Query.Eof;
      if Result then begin
        ACollection.ID := Query.FieldByName('ID').AsInteger;
        ACollection.Name := Query.FieldByName('Name').AsString;
        ACollection.IsPublic := Query.FieldByName('IsPublic').AsInteger <> 0;
        if ACollection.Name <> Name then
          raise ECollectionConflict.Create(
            'A collection with this name already exists.');
      end;
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

function TUserCollectionRepository.ListSetListsForUser(AUserID,
  ACollectionID: Integer): TUserSetLists;
begin
  ValidateUserID(AUserID);
  ValidateRecordID(ACollectionID, 'collection ID');
  var SetLists := TList<TUserSetList>.Create;
  try
    var Connection := NewConnection(FDatabaseFileName);
    try
      var Query := TFDQuery.Create(nil);
      try
        Query.Connection := Connection;
        Query.SQL.Text :=
          'SELECT sl.ID, sl.CollectionID, sl.Name, sl.Description, ' +
          'sl.UseInCollection, sl.SortIndex FROM BSSetLists sl ' +
          'INNER JOIN BSCollections c ON c.ID = sl.CollectionID ' +
          'WHERE sl.CollectionID = :CollectionID AND c.UserID = :UserID ' +
          'ORDER BY sl.SortIndex, sl.ID';
        Query.ParamByName('CollectionID').AsInteger := ACollectionID;
        Query.ParamByName('UserID').AsInteger := AUserID;
        Query.Open;
        while not Query.Eof do begin
          SetLists.Add(SetListFromQuery(Query));
          Query.Next;
        end;
        Result := SetLists.ToArray;
      finally
        Query.Free;
      end;
    finally
      Connection.Free;
    end;
  finally
    SetLists.Free;
  end;
end;

function TUserCollectionRepository.TryGetSetListForUser(AUserID,
  ASetListID: Integer; out ASetList: TUserSetList): Boolean;
begin
  ValidateUserID(AUserID);
  ValidateRecordID(ASetListID, 'set list ID');
  ASetList := Default(TUserSetList);
  var Connection := NewConnection(FDatabaseFileName);
  try
    var Query := TFDQuery.Create(nil);
    try
      Query.Connection := Connection;
      Query.SQL.Text :=
        'SELECT sl.ID, sl.CollectionID, sl.Name, sl.Description, ' +
        'sl.UseInCollection, sl.SortIndex FROM BSSetLists sl ' +
        'INNER JOIN BSCollections c ON c.ID = sl.CollectionID ' +
        'WHERE sl.ID = :SetListID AND c.UserID = :UserID';
      Query.ParamByName('SetListID').AsInteger := ASetListID;
      Query.ParamByName('UserID').AsInteger := AUserID;
      Query.Open;
      Result := not Query.Eof;
      if Result then
        ASetList := SetListFromQuery(Query);
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

function TUserCollectionRepository.CreateSetListForUser(AUserID,
  ACollectionID: Integer; const AName, ADescription: string;
  AUseInCollection: Boolean): TUserSetList;
begin
  ValidateUserID(AUserID);
  ValidateRecordID(ACollectionID, 'collection ID');
  ValidateSetListFields(AName, ADescription);
  var Connection := NewConnection(FDatabaseFileName);
  try
    var Query := TFDQuery.Create(nil);
    try
      Query.Connection := Connection;
      Query.SQL.Text :=
        'INSERT INTO BSSetLists ' +
        '(CollectionID, Name, Description, UseInCollection, SortIndex) ' +
        'SELECT :InsertCollectionID, :Name, :Description, :UseInCollection, ' +
        'COALESCE((SELECT MAX(SortIndex) + 1 FROM BSSetLists ' +
        'WHERE CollectionID = :SortCollectionID), 0) ' +
        'WHERE EXISTS (SELECT 1 FROM BSCollections ' +
        'WHERE ID = :OwnerCollectionID AND UserID = :UserID)';
      Query.ParamByName('InsertCollectionID').AsInteger := ACollectionID;
      Query.ParamByName('SortCollectionID').AsInteger := ACollectionID;
      Query.ParamByName('OwnerCollectionID').AsInteger := ACollectionID;
      Query.ParamByName('Name').AsString := AName.Trim;
      Query.ParamByName('Description').AsString := ADescription;
      Query.ParamByName('UseInCollection').AsInteger := Ord(AUseInCollection);
      Query.ParamByName('UserID').AsInteger := AUserID;
      Query.ExecSQL;
      if Query.RowsAffected <> 1 then
        raise ECollectionItemNotFound.Create(
          'The requested collection was not found.');
      Query.SQL.Text :=
        'SELECT ID, CollectionID, Name, Description, UseInCollection, ' +
        'SortIndex FROM BSSetLists WHERE ID = last_insert_rowid()';
      Query.Open;
      if Query.Eof then
        raise Exception.Create('The created set list could not be read.');
      Result := SetListFromQuery(Query);
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

function TUserCollectionRepository.UpdateSetListForUser(AUserID,
  ASetListID: Integer; const AName, ADescription: string;
  AUseInCollection: Boolean): Boolean;
begin
  ValidateUserID(AUserID);
  ValidateRecordID(ASetListID, 'set list ID');
  ValidateSetListFields(AName, ADescription);
  var Connection := NewConnection(FDatabaseFileName);
  try
    var Query := TFDQuery.Create(nil);
    try
      Query.Connection := Connection;
      Query.SQL.Text :=
        'UPDATE BSSetLists SET Name = :Name, Description = :Description, ' +
        'UseInCollection = :UseInCollection WHERE ID = :SetListID ' +
        'AND EXISTS (SELECT 1 FROM BSCollections c ' +
        'WHERE c.ID = BSSetLists.CollectionID AND c.UserID = :UserID)';
      Query.ParamByName('Name').AsString := AName.Trim;
      Query.ParamByName('Description').AsString := ADescription;
      Query.ParamByName('UseInCollection').AsInteger := Ord(AUseInCollection);
      Query.ParamByName('SetListID').AsInteger := ASetListID;
      Query.ParamByName('UserID').AsInteger := AUserID;
      Query.ExecSQL;
      Result := Query.RowsAffected = 1;
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

function TUserCollectionRepository.DeleteSetListForUser(AUserID,
  ASetListID: Integer): Boolean;
begin
  ValidateUserID(AUserID);
  ValidateRecordID(ASetListID, 'set list ID');
  var Connection := NewConnection(FDatabaseFileName);
  try
    var Query := TFDQuery.Create(nil);
    try
      Query.Connection := Connection;
      Query.SQL.Text :=
        'DELETE FROM BSSetLists WHERE ID = :SetListID ' +
        'AND EXISTS (SELECT 1 FROM BSCollections c ' +
        'WHERE c.ID = BSSetLists.CollectionID AND c.UserID = :UserID)';
      Query.ParamByName('SetListID').AsInteger := ASetListID;
      Query.ParamByName('UserID').AsInteger := AUserID;
      Query.ExecSQL;
      Result := Query.RowsAffected = 1;
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

function TUserCollectionRepository.ListSetsForUser(AUserID,
  ASetListID: Integer): TCollectionSets;
begin
  ValidateUserID(AUserID);
  ValidateRecordID(ASetListID, 'set list ID');
  var Sets := TList<TCollectionSet>.Create;
  try
    var Connection := NewConnection(FDatabaseFileName);
    try
      var Query := TFDQuery.Create(nil);
      try
        Query.Connection := Connection;
        Query.SQL.Text :=
          'SELECT s.ID, s.BSSetListID, s.set_num, s.Built, ' +
          's.HaveSpareParts, s.Notes FROM BSSets s ' +
          'INNER JOIN BSSetLists sl ON sl.ID = s.BSSetListID ' +
          'INNER JOIN BSCollections c ON c.ID = sl.CollectionID ' +
          'WHERE s.BSSetListID = :SetListID AND c.UserID = :UserID ' +
          'ORDER BY s.ID';
        Query.ParamByName('SetListID').AsInteger := ASetListID;
        Query.ParamByName('UserID').AsInteger := AUserID;
        Query.Open;
        while not Query.Eof do begin
          Sets.Add(CollectionSetFromQuery(Query));
          Query.Next;
        end;
        Result := Sets.ToArray;
      finally
        Query.Free;
      end;
    finally
      Connection.Free;
    end;
  finally
    Sets.Free;
  end;
end;

function TUserCollectionRepository.TryGetSetForUser(AUserID,
  ASetID: Integer; out ASet: TCollectionSet): Boolean;
begin
  ValidateUserID(AUserID);
  ValidateRecordID(ASetID, 'set ID');
  ASet := Default(TCollectionSet);
  var Connection := NewConnection(FDatabaseFileName);
  try
    var Query := TFDQuery.Create(nil);
    try
      Query.Connection := Connection;
      Query.SQL.Text :=
        'SELECT s.ID, s.BSSetListID, s.set_num, s.Built, ' +
        's.HaveSpareParts, s.Notes FROM BSSets s ' +
        'INNER JOIN BSSetLists sl ON sl.ID = s.BSSetListID ' +
        'INNER JOIN BSCollections c ON c.ID = sl.CollectionID ' +
        'WHERE s.ID = :SetID AND c.UserID = :UserID';
      Query.ParamByName('SetID').AsInteger := ASetID;
      Query.ParamByName('UserID').AsInteger := AUserID;
      Query.Open;
      Result := not Query.Eof;
      if Result then
        ASet := CollectionSetFromQuery(Query);
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

function TUserCollectionRepository.CreateSetForUser(AUserID,
  ASetListID: Integer; const ASetNumber: string; ABuilt,
  AHaveSpareParts: Boolean; const ANotes: string): TCollectionSet;
begin
  ValidateUserID(AUserID);
  ValidateRecordID(ASetListID, 'set list ID');
  ValidateSetFields(ASetNumber, ANotes);
  var Connection := NewConnection(FDatabaseFileName);
  try
    var Query := TFDQuery.Create(nil);
    try
      Query.Connection := Connection;
      Query.SQL.Text :=
        'INSERT INTO BSSets ' +
        '(BSSetListID, set_num, Built, HaveSpareParts, Notes) ' +
        'SELECT :InsertSetListID, :SetNumber, :Built, :HaveSpareParts, :Notes ' +
        'WHERE EXISTS (SELECT 1 FROM BSSetLists sl ' +
        'INNER JOIN BSCollections c ON c.ID = sl.CollectionID ' +
        'WHERE sl.ID = :OwnerSetListID AND c.UserID = :UserID)';
      Query.ParamByName('InsertSetListID').AsInteger := ASetListID;
      Query.ParamByName('OwnerSetListID').AsInteger := ASetListID;
      Query.ParamByName('SetNumber').AsString := ASetNumber.Trim;
      Query.ParamByName('Built').AsInteger := Ord(ABuilt);
      Query.ParamByName('HaveSpareParts').AsInteger := Ord(AHaveSpareParts);
      Query.ParamByName('Notes').AsString := ANotes;
      Query.ParamByName('UserID').AsInteger := AUserID;
      Query.ExecSQL;
      if Query.RowsAffected <> 1 then
        raise ECollectionItemNotFound.Create(
          'The requested set list was not found.');
      Query.SQL.Text :=
        'SELECT ID, BSSetListID, set_num, Built, HaveSpareParts, Notes ' +
        'FROM BSSets WHERE ID = last_insert_rowid()';
      Query.Open;
      if Query.Eof then
        raise Exception.Create('The created set could not be read.');
      Result := CollectionSetFromQuery(Query);
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

function TUserCollectionRepository.UpdateSetForUser(AUserID, ASetID: Integer;
  ABuilt, AHaveSpareParts: Boolean; const ANotes: string): Boolean;
begin
  ValidateUserID(AUserID);
  ValidateRecordID(ASetID, 'set ID');
  if Length(ANotes) > 2000 then
    raise EArgumentException.Create('Set notes are too long.');
  var Connection := NewConnection(FDatabaseFileName);
  try
    var Query := TFDQuery.Create(nil);
    try
      Query.Connection := Connection;
      Query.SQL.Text :=
        'UPDATE BSSets SET Built = :Built, HaveSpareParts = :HaveSpareParts, ' +
        'Notes = :Notes WHERE ID = :SetID AND EXISTS (' +
        'SELECT 1 FROM BSSetLists sl ' +
        'INNER JOIN BSCollections c ON c.ID = sl.CollectionID ' +
        'WHERE sl.ID = BSSets.BSSetListID AND c.UserID = :UserID)';
      Query.ParamByName('Built').AsInteger := Ord(ABuilt);
      Query.ParamByName('HaveSpareParts').AsInteger := Ord(AHaveSpareParts);
      Query.ParamByName('Notes').AsString := ANotes;
      Query.ParamByName('SetID').AsInteger := ASetID;
      Query.ParamByName('UserID').AsInteger := AUserID;
      Query.ExecSQL;
      Result := Query.RowsAffected = 1;
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

function TUserCollectionRepository.DeleteSetForUser(AUserID,
  ASetID: Integer): Boolean;
begin
  ValidateUserID(AUserID);
  ValidateRecordID(ASetID, 'set ID');
  var Connection := NewConnection(FDatabaseFileName);
  try
    var Query := TFDQuery.Create(nil);
    try
      Query.Connection := Connection;
      Query.SQL.Text :=
        'DELETE FROM BSSets WHERE ID = :SetID AND EXISTS (' +
        'SELECT 1 FROM BSSetLists sl ' +
        'INNER JOIN BSCollections c ON c.ID = sl.CollectionID ' +
        'WHERE sl.ID = BSSets.BSSetListID AND c.UserID = :UserID)';
      Query.ParamByName('SetID').AsInteger := ASetID;
      Query.ParamByName('UserID').AsInteger := AUserID;
      Query.ExecSQL;
      Result := Query.RowsAffected = 1;
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

end.
