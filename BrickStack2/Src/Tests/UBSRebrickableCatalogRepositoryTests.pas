unit UBSRebrickableCatalogRepositoryTests;

interface

uses
  TestFramework;

type
  TRebrickableCatalogRepositoryTests = class(TTestCase)
  published
    procedure SearchesSetsWithFiltersAndStablePagination;
    procedure CapsSearchPageSizeAtOneHundred;
    procedure TreatsSearchTextAsLiteral;
    procedure SearchesPartsByCategoryAndColor;
    procedure ReadsDetailsAndLookupLists;
    procedure ReadsCatalogSummaryCounts;
    procedure ReadsSetInventoryWithVersionedKeysetPagination;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  UBSRebrickableCatalogRepository;

procedure CreateFixtureCatalog(out ADirectory, ADatabaseFile: string);
begin
  ADirectory := TPath.Combine(TPath.GetTempPath,
    'BrickStack2CatalogTests-' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(ADirectory);
  ADatabaseFile := TPath.Combine(ADirectory, 'rb.db');
  var Connection := TFDConnection.Create(nil);
  try
    Connection.LoginPrompt := False;
    Connection.DriverName := 'SQLite';
    Connection.Params.Database := ADatabaseFile;
    Connection.Connected := True;
    var Query := TFDQuery.Create(nil);
    try
      Query.Connection := Connection;
      Query.SQL.Text :=
        'CREATE TABLE themes (id INTEGER PRIMARY KEY, name TEXT NOT NULL, ' +
        'parent_id INTEGER)';
      Query.ExecSQL;
      Query.SQL.Text :=
        'CREATE TABLE sets (set_num TEXT PRIMARY KEY, name TEXT NOT NULL, ' +
        'year INTEGER NOT NULL, theme_id INTEGER NOT NULL, ' +
        'num_parts INTEGER NOT NULL, img_url TEXT NOT NULL)';
      Query.ExecSQL;
      Query.SQL.Text :=
        'CREATE TABLE part_categories (id INTEGER PRIMARY KEY, name TEXT NOT NULL)';
      Query.ExecSQL;
      Query.SQL.Text :=
        'CREATE TABLE parts (part_num TEXT PRIMARY KEY, name TEXT NOT NULL, ' +
        'part_cat_id INTEGER NOT NULL, part_material TEXT NOT NULL)';
      Query.ExecSQL;
      Query.SQL.Text :=
        'CREATE TABLE colors (id INTEGER PRIMARY KEY, name TEXT NOT NULL, ' +
        'rgb TEXT NOT NULL, is_trans INTEGER NOT NULL)';
      Query.ExecSQL;
      Query.SQL.Text :=
        'CREATE TABLE elements (element_id INTEGER PRIMARY KEY, ' +
        'part_num TEXT NOT NULL, color_id INTEGER NOT NULL)';
      Query.ExecSQL;
      Query.SQL.Text :=
        'CREATE TABLE inventories (id INTEGER PRIMARY KEY, ' +
        'version INTEGER NOT NULL, set_num TEXT NOT NULL)';
      Query.ExecSQL;
      Query.SQL.Text :=
        'CREATE TABLE inventory_parts (inventory_id INTEGER NOT NULL, ' +
        'part_num TEXT NOT NULL, color_id INTEGER NOT NULL, ' +
        'quantity INTEGER NOT NULL, is_spare INTEGER NOT NULL, img_url TEXT)';
      Query.ExecSQL;

      Query.SQL.Text :=
        'INSERT INTO themes (id, name, parent_id) VALUES ' +
        '(1, ''Castle'', NULL), (2, ''Medieval'', 1), (3, ''Space'', NULL)';
      Query.ExecSQL;
      Query.SQL.Text :=
        'INSERT INTO sets (set_num, name, year, theme_id, num_parts, img_url) VALUES ' +
        '(''1001-1'', ''Castle Keep'', 2020, 1, 100, ''https://example.test/1001.jpg''), ' +
        '(''1002-1'', ''Castle Gate'', 2021, 2, 50, ''https://example.test/1002.jpg''), ' +
        '(''1003-1'', ''Space Rover'', 2022, 3, 75, ''https://example.test/1003.jpg'')';
      Query.ExecSQL;
      Query.SQL.Text :=
        'INSERT INTO part_categories (id, name) VALUES ' +
        '(1, ''Bricks''), (2, ''Plates'')';
      Query.ExecSQL;
      Query.SQL.Text :=
        'INSERT INTO parts (part_num, name, part_cat_id, part_material) VALUES ' +
        '(''3001'', ''Brick 2 x 4'', 1, ''Plastic''), ' +
        '(''3002'', ''Brick 2 x 2'', 1, ''Plastic''), ' +
        '(''3003'', ''Plate 2 x 4'', 2, ''Plastic'')';
      Query.ExecSQL;
      Query.SQL.Text :=
        'INSERT INTO colors (id, name, rgb, is_trans) VALUES ' +
        '(5, ''Red'', ''C91A09'', 0), (6, ''Blue'', ''0055BF'', 0)';
      Query.ExecSQL;
      Query.SQL.Text :=
        'INSERT INTO elements (element_id, part_num, color_id) VALUES ' +
        '(1, ''3001'', 5), (2, ''3001'', 6), (3, ''3002'', 6), (4, ''3003'', 5)';
      Query.ExecSQL;
      Query.SQL.Text :=
        'INSERT INTO inventories (id, version, set_num) VALUES ' +
        '(101, 1, ''1001-1''), (102, 2, ''1001-1'')';
      Query.ExecSQL;
      Query.SQL.Text :=
        'INSERT INTO inventory_parts ' +
        '(inventory_id, part_num, color_id, quantity, is_spare, img_url) VALUES ' +
        '(101, ''3001'', 5, 1, 0, ''https://example.test/old.jpg''), ' +
        '(102, ''3001'', 5, 2, 0, ''https://example.test/3001.jpg''), ' +
        '(102, ''3001'', 6, 1, 0, ''https://example.test/3001-blue.jpg''), ' +
        '(102, ''3002'', 6, 3, 1, ''https://example.test/3002.jpg''), ' +
        '(102, ''3003'', 5, 1, 0, ''https://example.test/3003.jpg'')';
      Query.ExecSQL;
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

procedure TRebrickableCatalogRepositoryTests.SearchesSetsWithFiltersAndStablePagination;
begin
  var Directory: string;
  var DatabaseFile: string;
  CreateFixtureCatalog(Directory, DatabaseFile);
  try
    var Repository := TRebrickableCatalogRepository.Create(DatabaseFile);
    try
      var Page := Repository.SearchSets('castle', 0, 0, 1, '');
      CheckEquals(1, Length(Page.Items));
      CheckEquals('1001-1', Page.Items[0].SetNumber);
      Check(Page.HasMore);
      CheckEquals('1001-1', Page.NextCursor);
      CheckEquals('Castle', Page.Items[0].ThemeName);

      Page := Repository.SearchSets('castle', 0, 0, 1, Page.NextCursor);
      CheckEquals(1, Length(Page.Items));
      CheckEquals('1002-1', Page.Items[0].SetNumber);
      Check(not Page.HasMore);
      CheckEquals('', Page.NextCursor);

      Page := Repository.SearchSets('', 2, 2021, 25, '');
      CheckEquals(1, Length(Page.Items));
      CheckEquals('1002-1', Page.Items[0].SetNumber);
    finally
      Repository.Free;
    end;
  finally
    TDirectory.Delete(Directory, True);
  end;
end;

procedure TRebrickableCatalogRepositoryTests.CapsSearchPageSizeAtOneHundred;
begin
  var Directory: string;
  var DatabaseFile: string;
  CreateFixtureCatalog(Directory, DatabaseFile);
  try
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
          'INSERT INTO sets (set_num, name, year, theme_id, num_parts, img_url) ' +
          'VALUES (:SetNumber, :Name, 2020, 1, 1, ''https://example.test/set.jpg'')';
        Query.ParamByName('SetNumber').DataType := ftString;
        Query.ParamByName('Name').DataType := ftString;
        Query.Prepare;
        for var I := 1 to 105 do begin
          Query.ParamByName('SetNumber').AsString :=
            Format('2000-%3.3d', [I]);
          Query.ParamByName('Name').AsString := 'Extra castle set';
          Query.ExecSQL;
        end;
      finally
        Query.Free;
      end;
    finally
      Connection.Free;
    end;

    var Repository := TRebrickableCatalogRepository.Create(DatabaseFile);
    try
      var Page := Repository.SearchSets('', 0, 0, 500, '');
      CheckEquals(100, Length(Page.Items));
      Check(Page.HasMore);
      CheckEquals(Page.Items[99].SetNumber, Page.NextCursor);
    finally
      Repository.Free;
    end;
  finally
    TDirectory.Delete(Directory, True);
  end;
end;

procedure TRebrickableCatalogRepositoryTests.TreatsSearchTextAsLiteral;
begin
  var Directory: string;
  var DatabaseFile: string;
  CreateFixtureCatalog(Directory, DatabaseFile);
  try
    var Repository := TRebrickableCatalogRepository.Create(DatabaseFile);
    try
      var Page := Repository.SearchSets(''' OR 1=1 --', 0, 0, 25, '');
      CheckEquals(0, Length(Page.Items),
        'Search operators must be treated as literal search text');
    finally
      Repository.Free;
    end;
  finally
    TDirectory.Delete(Directory, True);
  end;
end;

procedure TRebrickableCatalogRepositoryTests.SearchesPartsByCategoryAndColor;
begin
  var Directory: string;
  var DatabaseFile: string;
  CreateFixtureCatalog(Directory, DatabaseFile);
  try
    var Repository := TRebrickableCatalogRepository.Create(DatabaseFile);
    try
      var Page := Repository.SearchParts('brick', 1, 5, 25, '');
      CheckEquals(1, Length(Page.Items));
      CheckEquals('3001', Page.Items[0].PartNumber);
      CheckEquals('Bricks', Page.Items[0].CategoryName);
      CheckEquals('Plastic', Page.Items[0].Material);
    finally
      Repository.Free;
    end;
  finally
    TDirectory.Delete(Directory, True);
  end;
end;

procedure TRebrickableCatalogRepositoryTests.ReadsDetailsAndLookupLists;
begin
  var Directory: string;
  var DatabaseFile: string;
  CreateFixtureCatalog(Directory, DatabaseFile);
  try
    var Repository := TRebrickableCatalogRepository.Create(DatabaseFile);
    try
      var CatalogSet: TCatalogSet;
      Check(Repository.TryGetSet('1001-1', CatalogSet));
      CheckEquals('Castle Keep', CatalogSet.Name);
      CheckEquals(2020, CatalogSet.Year);
      Check(not Repository.TryGetSet('9999-1', CatalogSet));

      var CatalogPart: TCatalogPart;
      Check(Repository.TryGetPart('3003', CatalogPart));
      CheckEquals('Plate 2 x 4', CatalogPart.Name);
      Check(not Repository.TryGetPart('9999', CatalogPart));

      var Themes := Repository.GetThemes;
      CheckEquals(3, Length(Themes));
      CheckEquals(1, Themes[1].ParentID);
      Check(Themes[1].HasParent);

      var Colors := Repository.GetColors;
      CheckEquals(2, Length(Colors));
      CheckEquals('C91A09', Colors[1].RGB);

      var Categories := Repository.GetPartCategories;
      CheckEquals(2, Length(Categories));
      CheckEquals('Bricks', Categories[0].Name);
    finally
      Repository.Free;
    end;
  finally
    TDirectory.Delete(Directory, True);
  end;
end;

procedure TRebrickableCatalogRepositoryTests.ReadsCatalogSummaryCounts;
begin
  var Directory: string;
  var DatabaseFile: string;
  CreateFixtureCatalog(Directory, DatabaseFile);
  try
    var Repository := TRebrickableCatalogRepository.Create(DatabaseFile);
    try
      var Summary := Repository.GetSummary;
      CheckEquals(3, Summary.SetCount);
      CheckEquals(3, Summary.PartCount);
      CheckEquals(3, Summary.ThemeCount);
    finally
      Repository.Free;
    end;
  finally
    TDirectory.Delete(Directory, True);
  end;
end;

procedure TRebrickableCatalogRepositoryTests.ReadsSetInventoryWithVersionedKeysetPagination;
begin
  var Directory: string;
  var DatabaseFile: string;
  CreateFixtureCatalog(Directory, DatabaseFile);
  try
    var Repository := TRebrickableCatalogRepository.Create(DatabaseFile);
    try
      var Page: TCatalogInventoryPage;
      Check(Repository.TryGetSetInventory('1001-1', 0, 1, '', Page));
      CheckEquals(102, Page.InventoryID);
      CheckEquals(2, Page.Version);
      CheckEquals(1, Length(Page.Items));
      CheckEquals('3001', Page.Items[0].PartNumber);
      CheckEquals('Red', Page.Items[0].ColorName);
      CheckEquals(2, Page.Items[0].Quantity);
      Check(Page.HasMore);
      CheckEquals('3001~5~0', Page.NextCursor);

      var Version := Page.Version;
      var Cursor := Page.NextCursor;
      Check(Repository.TryGetSetInventory('1001-1', Version, 1,
        Cursor, Page));
      CheckEquals(1, Length(Page.Items));
      CheckEquals('3001', Page.Items[0].PartNumber);
      CheckEquals('Blue', Page.Items[0].ColorName);
      Check(Page.HasMore);

      Check(Repository.TryGetSetInventory('1001-1', 1, 25, '', Page));
      CheckEquals(1, Page.Version);
      CheckEquals(1, Length(Page.Items));
      CheckEquals(1, Page.Items[0].Quantity);
      Check(not Repository.TryGetSetInventory('1003-1', 0, 25, '', Page));
      var CursorRejected := False;
      try
        Repository.TryGetSetInventory('1001-1', 0, 25, 'invalid-cursor', Page);
      except
        on E: EArgumentException do
          CursorRejected := True;
      end;
      Check(CursorRejected, 'Malformed inventory cursors must be rejected.');
    finally
      Repository.Free;
    end;
  finally
    TDirectory.Delete(Directory, True);
  end;
end;

initialization
  RegisterTest(TRebrickableCatalogRepositoryTests.Suite);

end.
