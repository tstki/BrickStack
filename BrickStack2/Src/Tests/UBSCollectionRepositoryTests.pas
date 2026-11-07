unit UBSCollectionRepositoryTests;

interface

uses
  TestFramework;

type
  TUserCollectionRepositoryTests = class(TTestCase)
  published
    procedure ListsOnlyCollectionsOwnedByTheUser;
    procedure DoesNotReturnAnotherUsersCollectionByID;
    procedure CreatesPrivateCollectionsForTheAuthenticatedOwner;
    procedure RejectsInvalidAndDuplicateCollectionNames;
    procedure RenamesOnlyTheOwnersCollection;
    procedure RejectsRenameToAnExistingCollectionName;
    procedure ListsSetListsOnlyInsideTheOwnersCollection;
    procedure CreatesAndUpdatesOnlyOwnerSetLists;
    procedure AddsUpdatesAndRemovesOnlyOwnerSets;
    procedure RemovingASetListRemovesItsSets;
    procedure AddsAndUpdatesOnlyOwnerLooseParts;
    procedure RemovingAPartListRemovesItsLooseParts;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  UBSAdminBootstrap,
  UBSCollectionRepository,
  UBSDatabaseBootstrap;

function NewTestDirectory: string;
begin
  var Guid: TGUID;
  CreateGUID(Guid);
  Result := TPath.Combine(TPath.GetTempPath,
    'BrickStack2-' + GUIDToString(Guid));
  TDirectory.CreateDirectory(Result);
end;

procedure CreateTestUsers(const ADatabaseFile: string; out AOwnerID, AOtherID: Integer);
begin
  EnsureInitialAdmin(ADatabaseFile);
  var Accounts := ListUserAccounts(ADatabaseFile);
  AOwnerID := Accounts[0].ID;
  var TemporaryPassword: string;
  var Account := CreateUserAccount(ADatabaseFile, 'collection-owner',
    'Collection Owner', TemporaryPassword);
  AOtherID := Account.ID;
end;

procedure TUserCollectionRepositoryTests.ListsOnlyCollectionsOwnedByTheUser;
begin
  var TestDirectory := NewTestDirectory;
  var DatabaseFile := TPath.Combine(TestDirectory, 'BrickStack.db');
  try
    InitializeBrickStackDatabase(DatabaseFile);
    var OwnerID: Integer;
    var OtherID: Integer;
    CreateTestUsers(DatabaseFile, OwnerID, OtherID);
    Check(OwnerID <> OtherID);
    var Repository := TUserCollectionRepository.Create(DatabaseFile);
    try
      Repository.CreateForUser(OwnerID, 'Owner collection');
      Repository.CreateForUser(OtherID, 'Other collection');
      var Collections := Repository.ListForUser(OwnerID);
      CheckEquals(1, Length(Collections));
      CheckEquals('Owner collection', Collections[0].Name);
      Check(not Collections[0].IsPublic,
        'Collections must be private unless explicitly published');
      var OtherCollections := Repository.ListForUser(OtherID);
      CheckEquals(1, Length(OtherCollections));
      CheckEquals('Other collection', OtherCollections[0].Name);
    finally
      Repository.Free;
    end;
  finally
    TDirectory.Delete(TestDirectory, True);
  end;
end;

procedure TUserCollectionRepositoryTests.DoesNotReturnAnotherUsersCollectionByID;
begin
  var TestDirectory := NewTestDirectory;
  var DatabaseFile := TPath.Combine(TestDirectory, 'BrickStack.db');
  try
    InitializeBrickStackDatabase(DatabaseFile);
    var OwnerID: Integer;
    var OtherID: Integer;
    CreateTestUsers(DatabaseFile, OwnerID, OtherID);
    var Repository := TUserCollectionRepository.Create(DatabaseFile);
    try
      var Collection := Repository.CreateForUser(OwnerID, 'Private collection');
      var FoundCollection: TUserCollection;
      Check(not Repository.TryGetForUser(OtherID, Collection.ID,
        FoundCollection),
        'A different user must not read the collection by manipulating its ID');
      CheckEquals(0, FoundCollection.ID);
      Check(not Repository.TryGetForUser(OwnerID, Collection.ID + 1,
        FoundCollection),
        'A nonexistent collection must not be returned');
      Check(Repository.TryGetForUser(OwnerID, Collection.ID, FoundCollection),
        'The owner should be able to read their collection');
      CheckEquals(Collection.Name, FoundCollection.Name);
    finally
      Repository.Free;
    end;
  finally
    TDirectory.Delete(TestDirectory, True);
  end;
end;

procedure TUserCollectionRepositoryTests.CreatesPrivateCollectionsForTheAuthenticatedOwner;
begin
  var TestDirectory := NewTestDirectory;
  var DatabaseFile := TPath.Combine(TestDirectory, 'BrickStack.db');
  try
    InitializeBrickStackDatabase(DatabaseFile);
    var OwnerID: Integer;
    var OtherID: Integer;
    CreateTestUsers(DatabaseFile, OwnerID, OtherID);
    var Repository := TUserCollectionRepository.Create(DatabaseFile);
    try
      var OwnerCollection := Repository.CreateForUser(OwnerID, 'My collection');
      var OtherCollection := Repository.CreateForUser(OtherID, 'My collection');
      Check(OwnerCollection.ID <> OtherCollection.ID);
      Check(not OwnerCollection.IsPublic);
      Check(not OtherCollection.IsPublic);
    finally
      Repository.Free;
    end;
  finally
    TDirectory.Delete(TestDirectory, True);
  end;
end;

procedure TUserCollectionRepositoryTests.RejectsInvalidAndDuplicateCollectionNames;
begin
  var TestDirectory := NewTestDirectory;
  var DatabaseFile := TPath.Combine(TestDirectory, 'BrickStack.db');
  try
    InitializeBrickStackDatabase(DatabaseFile);
    var OwnerID: Integer;
    var OtherID: Integer;
    CreateTestUsers(DatabaseFile, OwnerID, OtherID);
    var Repository := TUserCollectionRepository.Create(DatabaseFile);
    try
      Repository.CreateForUser(OwnerID, 'Unique');
      var DuplicateRejected := False;
      try
        Repository.CreateForUser(OwnerID, 'Unique');
      except
        on E: ECollectionConflict do
          DuplicateRejected := True;
      end;
      Check(DuplicateRejected,
        'A user cannot create duplicate collection names');
      var InvalidNameRejected := False;
      try
        Repository.CreateForUser(OwnerID, '  ');
      except
        on E: EArgumentException do
          InvalidNameRejected := True;
      end;
      Check(InvalidNameRejected, 'An empty collection name must be rejected');
    finally
      Repository.Free;
    end;
  finally
    TDirectory.Delete(TestDirectory, True);
  end;
end;

procedure TUserCollectionRepositoryTests.RenamesOnlyTheOwnersCollection;
begin
  var TestDirectory := NewTestDirectory;
  var DatabaseFile := TPath.Combine(TestDirectory, 'BrickStack.db');
  try
    InitializeBrickStackDatabase(DatabaseFile);
    var OwnerID: Integer;
    var OtherID: Integer;
    CreateTestUsers(DatabaseFile, OwnerID, OtherID);
    var Repository := TUserCollectionRepository.Create(DatabaseFile);
    try
      var Collection := Repository.CreateForUser(OwnerID, 'Original name');
      var RenamedCollection: TUserCollection;
      Check(not Repository.RenameForUser(OtherID, Collection.ID,
        'Stolen name', RenamedCollection),
        'Another user must not rename this collection by manipulating its ID');
      Check(Repository.TryGetForUser(OwnerID, Collection.ID,
        RenamedCollection));
      CheckEquals('Original name', RenamedCollection.Name);
      Check(Repository.RenameForUser(OwnerID, Collection.ID,
        'Updated name', RenamedCollection),
        'The owner should be able to rename their collection');
      CheckEquals('Updated name', RenamedCollection.Name);
      Check(not RenamedCollection.IsPublic,
        'Renaming must not change the collection sharing state');
      var InvalidNameRejected := False;
      try
        Repository.RenameForUser(OwnerID, Collection.ID, '  ',
          RenamedCollection);
      except
        on E: EArgumentException do
          InvalidNameRejected := True;
      end;
      Check(InvalidNameRejected, 'An empty renamed collection name must be rejected');
    finally
      Repository.Free;
    end;
  finally
    TDirectory.Delete(TestDirectory, True);
  end;
end;

procedure TUserCollectionRepositoryTests.RejectsRenameToAnExistingCollectionName;
begin
  var TestDirectory := NewTestDirectory;
  var DatabaseFile := TPath.Combine(TestDirectory, 'BrickStack.db');
  try
    InitializeBrickStackDatabase(DatabaseFile);
    var OwnerID: Integer;
    var OtherID: Integer;
    CreateTestUsers(DatabaseFile, OwnerID, OtherID);
    var Repository := TUserCollectionRepository.Create(DatabaseFile);
    try
      var FirstCollection := Repository.CreateForUser(OwnerID, 'First');
      Repository.CreateForUser(OwnerID, 'Second');
      var RenamedCollection: TUserCollection;
      var ConflictRejected := False;
      try
        Repository.RenameForUser(OwnerID, FirstCollection.ID, 'Second',
          RenamedCollection);
      except
        on E: ECollectionConflict do
          ConflictRejected := True;
      end;
      Check(ConflictRejected,
        'A rename must not bypass the per-user collection name constraint');
      Check(not Repository.RenameForUser(OwnerID, FirstCollection.ID + 100,
        'Missing', RenamedCollection),
        'A nonexistent collection must not be renamed');
    finally
      Repository.Free;
    end;
  finally
    TDirectory.Delete(TestDirectory, True);
  end;
end;

procedure TUserCollectionRepositoryTests.ListsSetListsOnlyInsideTheOwnersCollection;
begin
  var TestDirectory := NewTestDirectory;
  var DatabaseFile := TPath.Combine(TestDirectory, 'BrickStack.db');
  try
    InitializeBrickStackDatabase(DatabaseFile);
    var OwnerID: Integer;
    var OtherID: Integer;
    CreateTestUsers(DatabaseFile, OwnerID, OtherID);
    var Repository := TUserCollectionRepository.Create(DatabaseFile);
    try
      var OwnerCollection := Repository.CreateForUser(OwnerID,
        'Set list owner collection');
      var OtherCollection := Repository.CreateForUser(OtherID,
        'Set list other collection');
      var OwnerSetList := Repository.CreateSetListForUser(OwnerID,
        OwnerCollection.ID, 'Owner list', 'Owner description', True);
      Repository.CreateSetListForUser(OtherID, OtherCollection.ID,
        'Other list', '', False);
      var OwnerSetLists := Repository.ListSetListsForUser(OwnerID,
        OwnerCollection.ID);
      CheckEquals(1, Length(OwnerSetLists));
      CheckEquals(OwnerSetList.ID, OwnerSetLists[0].ID);
      Check(OwnerSetLists[0].UseInCollection);
      CheckEquals('Owner description', OwnerSetLists[0].Description);
      CheckEquals(0, Length(Repository.ListSetListsForUser(OwnerID,
        OtherCollection.ID)));
      var InvalidNameRejected := False;
      try
        Repository.CreateSetListForUser(OwnerID, OwnerCollection.ID,
          '  ', '', False);
      except
        on E: EArgumentException do
          InvalidNameRejected := True;
      end;
      Check(InvalidNameRejected, 'An empty set-list name must be rejected');
      var FoundSetList: TUserSetList;
      Check(not Repository.TryGetSetListForUser(OtherID, OwnerSetList.ID,
        FoundSetList),
        'A different user must not read a set list by manipulating its ID');
      Check(Repository.TryGetSetListForUser(OwnerID, OwnerSetList.ID,
        FoundSetList));
      CheckEquals(OwnerCollection.ID, FoundSetList.CollectionID);
    finally
      Repository.Free;
    end;
  finally
    TDirectory.Delete(TestDirectory, True);
  end;
end;

procedure TUserCollectionRepositoryTests.CreatesAndUpdatesOnlyOwnerSetLists;
begin
  var TestDirectory := NewTestDirectory;
  var DatabaseFile := TPath.Combine(TestDirectory, 'BrickStack.db');
  try
    InitializeBrickStackDatabase(DatabaseFile);
    var OwnerID: Integer;
    var OtherID: Integer;
    CreateTestUsers(DatabaseFile, OwnerID, OtherID);
    var Repository := TUserCollectionRepository.Create(DatabaseFile);
    try
      var OwnerCollection := Repository.CreateForUser(OwnerID,
        'Owner list update collection');
      var OwnerSetList := Repository.CreateSetListForUser(OwnerID,
        OwnerCollection.ID, 'Original list', '', False);
      var UpdatedByOther := Repository.UpdateSetListForUser(OtherID,
        OwnerSetList.ID, 'Stolen list', 'forbidden', True);
      Check(not UpdatedByOther,
        'A different user must not update a set list by manipulating its ID');
      var UpdatedByOwner := Repository.UpdateSetListForUser(OwnerID,
        OwnerSetList.ID, 'Updated list', 'Updated description', True);
      Check(UpdatedByOwner, 'The owner should be able to update their set list');
      var FoundSetList: TUserSetList;
      Check(Repository.TryGetSetListForUser(OwnerID, OwnerSetList.ID,
        FoundSetList));
      CheckEquals('Updated list', FoundSetList.Name);
      CheckEquals('Updated description', FoundSetList.Description);
      Check(FoundSetList.UseInCollection);
      Check(not Repository.DeleteSetListForUser(OtherID, OwnerSetList.ID),
        'A different user must not remove a set list by manipulating its ID');
      Check(Repository.DeleteSetListForUser(OwnerID, OwnerSetList.ID),
        'The owner should be able to remove their set list');
    finally
      Repository.Free;
    end;
  finally
    TDirectory.Delete(TestDirectory, True);
  end;
end;

procedure TUserCollectionRepositoryTests.AddsUpdatesAndRemovesOnlyOwnerSets;
begin
  var TestDirectory := NewTestDirectory;
  var DatabaseFile := TPath.Combine(TestDirectory, 'BrickStack.db');
  try
    InitializeBrickStackDatabase(DatabaseFile);
    var OwnerID: Integer;
    var OtherID: Integer;
    CreateTestUsers(DatabaseFile, OwnerID, OtherID);
    var Repository := TUserCollectionRepository.Create(DatabaseFile);
    try
      var OwnerCollection := Repository.CreateForUser(OwnerID,
        'Owner set collection');
      var OwnerSetList := Repository.CreateSetListForUser(OwnerID,
        OwnerCollection.ID, 'Owner set list', '', True);
      var OtherCollection := Repository.CreateForUser(OtherID,
        'Other set collection');
      var OtherSetList := Repository.CreateSetListForUser(OtherID,
        OtherCollection.ID, 'Other set list', '', False);
      var OwnerSet := Repository.CreateSetForUser(OwnerID,
        OwnerSetList.ID, '4200-1', False, False, 'Needs building');
      CheckEquals(1, Length(Repository.ListSetsForUser(OwnerID,
        OwnerSetList.ID)));
      CheckEquals(0, Length(Repository.ListSetsForUser(OtherID,
        OwnerSetList.ID)));
      var FoundSet: TCollectionSet;
      Check(not Repository.TryGetSetForUser(OtherID, OwnerSet.ID, FoundSet),
        'A different user must not read a set by manipulating its ID');
      Check(not Repository.UpdateSetForUser(OtherID, OwnerSet.ID,
        True, True, 'stolen'),
        'A different user must not update a set by manipulating its ID');
      Check(not Repository.DeleteSetForUser(OtherID, OwnerSet.ID),
        'A different user must not remove a set by manipulating its ID');
      Check(Repository.TryGetSetForUser(OwnerID, OwnerSet.ID, FoundSet));
      CheckEquals('Needs building', FoundSet.Notes);
      Check(Repository.UpdateSetForUser(OwnerID, OwnerSet.ID,
        True, True, 'Built and checked'));
      Check(Repository.TryGetSetForUser(OwnerID, OwnerSet.ID, FoundSet));
      Check(FoundSet.Built);
      Check(FoundSet.HaveSpareParts);
      CheckEquals('Built and checked', FoundSet.Notes);
      var LongNotesRejected := False;
      try
        Repository.UpdateSetForUser(OwnerID, OwnerSet.ID, True, True,
          StringOfChar('x', 2001));
      except
        on E: EArgumentException do
          LongNotesRejected := True;
      end;
      Check(LongNotesRejected, 'Overlong set notes must be rejected');
      CheckEquals(0, Length(Repository.ListSetsForUser(OtherID,
        OtherSetList.ID)));
      Check(Repository.DeleteSetForUser(OwnerID, OwnerSet.ID));
      Check(not Repository.TryGetSetForUser(OwnerID, OwnerSet.ID, FoundSet));
    finally
      Repository.Free;
    end;
  finally
    TDirectory.Delete(TestDirectory, True);
  end;
end;

procedure TUserCollectionRepositoryTests.RemovingASetListRemovesItsSets;
begin
  var TestDirectory := NewTestDirectory;
  var DatabaseFile := TPath.Combine(TestDirectory, 'BrickStack.db');
  try
    InitializeBrickStackDatabase(DatabaseFile);
    var OwnerID: Integer;
    var OtherID: Integer;
    CreateTestUsers(DatabaseFile, OwnerID, OtherID);
    Check(OtherID > 0);
    var Repository := TUserCollectionRepository.Create(DatabaseFile);
    try
      var Collection := Repository.CreateForUser(OwnerID,
        'Cascade collection');
      var SetList := Repository.CreateSetListForUser(OwnerID, Collection.ID,
        'Cascade list', '', False);
      var CollectionSet := Repository.CreateSetForUser(OwnerID, SetList.ID,
        '4200-1', False, False, '');
      Check(Repository.DeleteSetListForUser(OwnerID, SetList.ID));
      var FoundSet: TCollectionSet;
      Check(not Repository.TryGetSetForUser(OwnerID, CollectionSet.ID, FoundSet),
        'Removing a set list must remove its set items');
    finally
      Repository.Free;
    end;
  finally
    TDirectory.Delete(TestDirectory, True);
  end;
end;

procedure TUserCollectionRepositoryTests.AddsAndUpdatesOnlyOwnerLooseParts;
begin
  var TestDirectory := NewTestDirectory;
  var DatabaseFile := TPath.Combine(TestDirectory, 'BrickStack.db');
  try
    InitializeBrickStackDatabase(DatabaseFile);
    var OwnerID: Integer;
    var OtherID: Integer;
    CreateTestUsers(DatabaseFile, OwnerID, OtherID);
    var Repository := TUserCollectionRepository.Create(DatabaseFile);
    try
      var OwnerCollection := Repository.CreateForUser(OwnerID,
        'Loose part collection');
      var OwnerPartList := Repository.CreatePartListForUser(OwnerID,
        OwnerCollection.ID, 'Owner parts');
      var OtherCollection := Repository.CreateForUser(OtherID,
        'Other loose part collection');
      var OtherPartList := Repository.CreatePartListForUser(OtherID,
        OtherCollection.ID, 'Other parts');
      var LoosePart := Repository.AddLoosePartForUser(OwnerID,
        OwnerPartList.ID, '3001', 4, 2);
      CheckEquals(2, LoosePart.Quantity);
      LoosePart := Repository.AddLoosePartForUser(OwnerID, OwnerPartList.ID,
        '3001', 4, 3);
      CheckEquals(1, Length(Repository.ListLoosePartsForUser(OwnerID,
        OwnerPartList.ID)));
      CheckEquals(5, LoosePart.Quantity,
        'Adding an existing part and color should increase its quantity');
      CheckEquals(0, Length(Repository.ListLoosePartsForUser(OtherID,
        OwnerPartList.ID)));

      var FoundPart: TLoosePart;
      Check(not Repository.TryGetLoosePartForUser(OtherID, LoosePart.ID,
        FoundPart),
        'A different user must not read a loose part by manipulating its ID');
      Check(not Repository.SetLoosePartQuantityForUser(OtherID, LoosePart.ID,
        9), 'A different user must not change a loose-part quantity');
      Check(not Repository.DeleteLoosePartForUser(OtherID, LoosePart.ID),
        'A different user must not remove another user''s loose part');
      Check(Repository.SetLoosePartQuantityForUser(OwnerID, LoosePart.ID, 7));
      Check(Repository.TryGetLoosePartForUser(OwnerID, LoosePart.ID,
        FoundPart));
      CheckEquals(7, FoundPart.Quantity);
      CheckEquals(OwnerPartList.ID, FoundPart.PartListID);
      CheckEquals('3001', FoundPart.PartNumber);
      CheckEquals(4, FoundPart.ColorID);

      var InvalidQuantityRejected := False;
      try
        Repository.AddLoosePartForUser(OwnerID, OwnerPartList.ID, '3001', 4, 0);
      except
        on E: EArgumentException do
          InvalidQuantityRejected := True;
      end;
      Check(InvalidQuantityRejected, 'Zero quantity must be rejected');
      var FoundPartList: TUserPartList;
      Check(not Repository.TryGetPartListForUser(OtherID, OwnerPartList.ID,
        FoundPartList),
        'A different user must not read another user''s part list');

      var PartLists := Repository.ListPartListsForUser(OwnerID,
        OwnerCollection.ID);
      CheckEquals(1, Length(PartLists));
      Check(Repository.UpdatePartListForUser(OwnerID, OwnerPartList.ID,
        'Renamed parts'));
      Check(not Repository.UpdatePartListForUser(OtherID, OwnerPartList.ID,
        'Stolen parts'));
      Check(Repository.DeleteLoosePartForUser(OwnerID, LoosePart.ID));
      Check(not Repository.TryGetLoosePartForUser(OwnerID, LoosePart.ID,
        FoundPart));
      Check(not Repository.DeletePartListForUser(OwnerID, OtherPartList.ID),
        'A user must not remove another user''s part list');
    finally
      Repository.Free;
    end;
  finally
    TDirectory.Delete(TestDirectory, True);
  end;
end;

procedure TUserCollectionRepositoryTests.RemovingAPartListRemovesItsLooseParts;
begin
  var TestDirectory := NewTestDirectory;
  var DatabaseFile := TPath.Combine(TestDirectory, 'BrickStack.db');
  try
    InitializeBrickStackDatabase(DatabaseFile);
    var OwnerID: Integer;
    var OtherID: Integer;
    CreateTestUsers(DatabaseFile, OwnerID, OtherID);
    var Repository := TUserCollectionRepository.Create(DatabaseFile);
    try
      var Collection := Repository.CreateForUser(OwnerID,
        'Loose-part cascade collection');
      var PartList := Repository.CreatePartListForUser(OwnerID,
        Collection.ID, 'Cascade parts');
      var Part := Repository.AddLoosePartForUser(OwnerID, PartList.ID,
        '3001', 4, 2);
      Check(Repository.DeletePartListForUser(OwnerID, PartList.ID));
      var FoundPart: TLoosePart;
      Check(not Repository.TryGetLoosePartForUser(OwnerID, Part.ID,
        FoundPart),
        'Removing a part list must remove its loose-part entries');
    finally
      Repository.Free;
    end;
  finally
    TDirectory.Delete(TestDirectory, True);
  end;
end;

initialization
  RegisterTest(TUserCollectionRepositoryTests.Suite);

end.
