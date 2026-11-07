unit UBSRebrickableCatalogRepository;

interface

type
  TCatalogSet = record
    SetNumber: string;
    Name: string;
    Year: Integer;
    ThemeID: Integer;
    ThemeName: string;
    PartCount: Integer;
    ImageURL: string;
  end;

  TCatalogPart = record
    PartNumber: string;
    Name: string;
    CategoryID: Integer;
    CategoryName: string;
    Material: string;
  end;

  TCatalogSetPage = record
    Items: TArray<TCatalogSet>;
    NextCursor: string;
    HasMore: Boolean;
  end;

  TCatalogPartPage = record
    Items: TArray<TCatalogPart>;
    NextCursor: string;
    HasMore: Boolean;
  end;

  TCatalogTheme = record
    ID: Integer;
    Name: string;
    ParentID: Integer;
    HasParent: Boolean;
  end;

  TCatalogColor = record
    ID: Integer;
    Name: string;
    RGB: string;
    IsTransparent: Boolean;
  end;

  TCatalogPartCategory = record
    ID: Integer;
    Name: string;
  end;

  TCatalogSummary = record
    SetCount: Integer;
    PartCount: Integer;
    ThemeCount: Integer;
  end;

  TCatalogInventoryPart = record
    PartNumber: string;
    Name: string;
    ColorID: Integer;
    ColorName: string;
    RGB: string;
    Quantity: Integer;
    IsSpare: Boolean;
    ImageURL: string;
  end;

  TCatalogInventoryPage = record
    SetNumber: string;
    InventoryID: Integer;
    Version: Integer;
    Items: TArray<TCatalogInventoryPart>;
    NextCursor: string;
    HasMore: Boolean;
  end;

  TRebrickableCatalogRepository = class
  private
    FDatabaseFileName: string;
  public
    constructor Create(const ADatabaseFileName: string);
    function SearchSets(const ASearchText: string; AThemeID, AYear, APageSize: Integer; const AAfter: string): TCatalogSetPage;
    function TryGetSet(const ASetNumber: string; out ASet: TCatalogSet): Boolean;
    function SearchParts(const ASearchText: string; ACategoryID, AColorID, APageSize: Integer; const AAfter: string): TCatalogPartPage;
    function TryGetPart(const APartNumber: string; out APart: TCatalogPart): Boolean;
    function TryGetColor(AColorID: Integer; out AColor: TCatalogColor): Boolean;
    function GetThemes: TArray<TCatalogTheme>;
    function GetColors: TArray<TCatalogColor>;
    function GetPartCategories: TArray<TCatalogPartCategory>;
    function GetSummary: TCatalogSummary;
    function TryGetSetInventory(const ASetNumber: string; AVersion, APageSize: Integer; const AAfter: string; out APage: TCatalogInventoryPage): Boolean;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param;

const
  cDefaultPageSize = 25;
  cMaximumPageSize = 100;
  cMaximumSearchLength = 100;
  cMaximumCursorLength = 64;
  cMaximumInventoryCursorLength = 96;

constructor TRebrickableCatalogRepository.Create(const ADatabaseFileName: string);
begin
  inherited Create;
  if ADatabaseFileName.Trim = '' then
    raise EArgumentException.Create('A catalog database path is required.');
  FDatabaseFileName := TPath.GetFullPath(ADatabaseFileName);
end;

function NewReadOnlyConnection(const ADatabaseFileName: string): TFDConnection;
begin
  if not TFile.Exists(ADatabaseFileName) then
    raise EFileNotFoundException.CreateFmt(
      'The Rebrickable catalog database "%s" does not exist.',
      [ADatabaseFileName]);
  Result := TFDConnection.Create(nil);
  try
    Result.LoginPrompt := False;
    Result.DriverName := 'SQLite';
    Result.Params.Database := ADatabaseFileName;
    Result.Params.Values['OpenMode'] := 'ReadOnly';
    Result.Connected := True;
  except
    Result.Free;
    raise;
  end;
end;

function NewQuery(AConnection: TFDConnection): TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := AConnection;
end;

function NormalizePageSize(APageSize: Integer): Integer; forward;
procedure ValidateOptionalID(AID: Integer; const AName: string); forward;

function TRebrickableCatalogRepository.GetSummary: TCatalogSummary;
begin
  var Connection := NewReadOnlyConnection(FDatabaseFileName);
  try
    var Query := NewQuery(Connection);
    try
      Query.SQL.Text :=
        'SELECT (SELECT COUNT(*) FROM sets) AS set_count, ' +
        '(SELECT COUNT(*) FROM parts) AS part_count, ' +
        '(SELECT COUNT(*) FROM themes) AS theme_count';
      Query.Open;
      Result.SetCount := Query.FieldByName('set_count').AsInteger;
      Result.PartCount := Query.FieldByName('part_count').AsInteger;
      Result.ThemeCount := Query.FieldByName('theme_count').AsInteger;
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

function TRebrickableCatalogRepository.TryGetSetInventory(const ASetNumber: string;
  AVersion, APageSize: Integer; const AAfter: string;
  out APage: TCatalogInventoryPage): Boolean;
begin
  if ASetNumber.Trim = '' then
    raise EArgumentException.Create('Set number is required.');
  if Length(ASetNumber) > cMaximumCursorLength then
    raise EArgumentOutOfRangeException.Create('Set number is too long.');
  ValidateOptionalID(AVersion, 'Inventory version');
  if (Length(AAfter) > cMaximumInventoryCursorLength) then
    raise EArgumentOutOfRangeException.Create(
      'Inventory pagination cursor is too long.');

  var CursorPartNumber := '';
  var CursorColorID := 0;
  var CursorIsSpare := 0;
  if AAfter <> '' then begin
    var CursorPosition := Pos('~', AAfter);
    var CursorSecondPosition := Pos('~', Copy(AAfter, CursorPosition + 1, MaxInt));
    if (CursorPosition < 2) or (CursorSecondPosition = 0) then
      raise EArgumentException.Create('Inventory pagination cursor is invalid.');
    Inc(CursorSecondPosition, CursorPosition);
    if Pos('~', Copy(AAfter, CursorSecondPosition + 1, MaxInt)) > 0 then
      raise EArgumentException.Create('Inventory pagination cursor is invalid.');

    CursorPartNumber := Copy(AAfter, 1, CursorPosition - 1);
    for var C in CursorPartNumber do
      if not CharInSet(C, ['0'..'9', 'A'..'Z', 'a'..'z', '.', '-']) then
        raise EArgumentException.Create(
          'Inventory pagination cursor is invalid.');
    if not TryStrToInt(Copy(AAfter, CursorPosition + 1,
      CursorSecondPosition - CursorPosition - 1), CursorColorID) or
      (CursorColorID < 0) then
      raise EArgumentException.Create('Inventory pagination cursor is invalid.');
    if not TryStrToInt(Copy(AAfter, CursorSecondPosition + 1, MaxInt),
      CursorIsSpare) or not (CursorIsSpare in [0, 1]) then
      raise EArgumentException.Create('Inventory pagination cursor is invalid.');
  end;

  var PageSize := NormalizePageSize(APageSize);
  APage := Default(TCatalogInventoryPage);
  APage.SetNumber := ASetNumber.Trim;
  var Connection := NewReadOnlyConnection(FDatabaseFileName);
  try
    var InventoryID: Integer;
    var InventoryVersion: Integer;
    var Query := NewQuery(Connection);
    try
      Query.SQL.Text :=
        'SELECT id, version FROM inventories WHERE set_num = :SetNumber';
      if AVersion > 0 then
        Query.SQL.Add('AND version = :Version')
      else
        Query.SQL.Add('ORDER BY version DESC LIMIT 1');
      if AVersion > 0 then
        Query.ParamByName('Version').AsInteger := AVersion;
      Query.ParamByName('SetNumber').AsString := APage.SetNumber;
      Query.Open;
      Result := not Query.Eof;
      if not Result then
        Exit;
      InventoryID := Query.FieldByName('id').AsInteger;
      InventoryVersion := Query.FieldByName('version').AsInteger;
      APage.InventoryID := InventoryID;
      APage.Version := InventoryVersion;
    finally
      Query.Free;
    end;

    Query := NewQuery(Connection);
    try
      Query.SQL.Text :=
        'SELECT ip.part_num, p.name, ip.color_id, c.name AS color_name, ' +
        'c.rgb, ip.quantity, ip.is_spare, ip.img_url ' +
        'FROM inventory_parts ip ' +
        'JOIN parts p ON p.part_num = ip.part_num ' +
        'JOIN colors c ON c.id = ip.color_id ' +
        'WHERE ip.inventory_id = :InventoryID';
      if AAfter <> '' then
        Query.SQL.Add(
          'AND (ip.part_num > :AfterPartNumber ' +
          'OR (ip.part_num = :AfterPartNumber AND ip.color_id > :AfterColorID) ' +
          'OR (ip.part_num = :AfterPartNumber AND ip.color_id = :AfterColorID ' +
          'AND ip.is_spare > :AfterIsSpare))');
      Query.SQL.Add('ORDER BY ip.part_num, ip.color_id, ip.is_spare LIMIT :Limit');
      Query.ParamByName('InventoryID').AsInteger := InventoryID;
      if AAfter <> '' then begin
        Query.ParamByName('AfterPartNumber').AsString := CursorPartNumber;
        Query.ParamByName('AfterColorID').AsInteger := CursorColorID;
        Query.ParamByName('AfterIsSpare').AsInteger := CursorIsSpare;
      end;
      Query.ParamByName('Limit').AsInteger := PageSize + 1;
      Query.Open;

      var ItemCount := 0;
      while not Query.Eof do begin
        if ItemCount = PageSize then begin
          APage.HasMore := True;
          Break;
        end;
        SetLength(APage.Items, ItemCount + 1);
        APage.Items[ItemCount].PartNumber :=
          Query.FieldByName('part_num').AsString;
        APage.Items[ItemCount].Name := Query.FieldByName('name').AsString;
        APage.Items[ItemCount].ColorID :=
          Query.FieldByName('color_id').AsInteger;
        APage.Items[ItemCount].ColorName :=
          Query.FieldByName('color_name').AsString;
        APage.Items[ItemCount].RGB := Query.FieldByName('rgb').AsString;
        APage.Items[ItemCount].Quantity :=
          Query.FieldByName('quantity').AsInteger;
        APage.Items[ItemCount].IsSpare :=
          Query.FieldByName('is_spare').AsInteger <> 0;
        APage.Items[ItemCount].ImageURL :=
          Query.FieldByName('img_url').AsString;
        Inc(ItemCount);
        Query.Next;
      end;
      if APage.HasMore and (ItemCount > 0) then
        APage.NextCursor := Format('%s~%d~%d',
          [APage.Items[ItemCount - 1].PartNumber,
          APage.Items[ItemCount - 1].ColorID,
          Ord(APage.Items[ItemCount - 1].IsSpare)]);
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

function NormalizePageSize(APageSize: Integer): Integer;
begin
  if APageSize <= 0 then
    Exit(cDefaultPageSize);
  Result := APageSize;
  if Result > cMaximumPageSize then
    Result := cMaximumPageSize;
end;

procedure ValidateSearchText(const ASearchText: string);
begin
  if Length(ASearchText) > cMaximumSearchLength then
    raise EArgumentOutOfRangeException.CreateFmt(
      'Search text cannot exceed %d characters.', [cMaximumSearchLength]);
end;

procedure ValidateCursor(const ACursor: string);
begin
  if Length(ACursor) > cMaximumCursorLength then
    raise EArgumentOutOfRangeException.CreateFmt(
      'Pagination cursor cannot exceed %d characters.',
      [cMaximumCursorLength]);
  for var C in ACursor do
    if not CharInSet(C, ['0'..'9', 'A'..'Z', 'a'..'z', '.', '-']) then
      raise EArgumentException.Create('Pagination cursor is invalid.');
end;

procedure ValidateOptionalID(AID: Integer; const AName: string);
begin
  if AID < 0 then
    raise EArgumentOutOfRangeException.Create(AName + ' cannot be negative.');
end;

function ReadCatalogSet(AQuery: TFDQuery): TCatalogSet;
begin
  Result.SetNumber := AQuery.FieldByName('set_num').AsString;
  Result.Name := AQuery.FieldByName('name').AsString;
  Result.Year := AQuery.FieldByName('year').AsInteger;
  Result.ThemeID := AQuery.FieldByName('theme_id').AsInteger;
  Result.ThemeName := AQuery.FieldByName('theme_name').AsString;
  Result.PartCount := AQuery.FieldByName('num_parts').AsInteger;
  Result.ImageURL := AQuery.FieldByName('img_url').AsString;
end;

function ReadCatalogPart(AQuery: TFDQuery): TCatalogPart;
begin
  Result.PartNumber := AQuery.FieldByName('part_num').AsString;
  Result.Name := AQuery.FieldByName('name').AsString;
  Result.CategoryID := AQuery.FieldByName('part_cat_id').AsInteger;
  Result.CategoryName := AQuery.FieldByName('category_name').AsString;
  Result.Material := AQuery.FieldByName('part_material').AsString;
end;

function TRebrickableCatalogRepository.SearchSets(const ASearchText: string; AThemeID, AYear, APageSize: Integer; const AAfter: string): TCatalogSetPage;
begin
  ValidateSearchText(ASearchText);
  ValidateOptionalID(AThemeID, 'Theme ID');
  ValidateOptionalID(AYear, 'Year');
  ValidateCursor(AAfter);
  var PageSize := NormalizePageSize(APageSize);
  Result.Items := nil;
  Result.NextCursor := '';
  Result.HasMore := False;

  var Connection := NewReadOnlyConnection(FDatabaseFileName);
  try
    var Query := NewQuery(Connection);
    try
      Query.SQL.Text :=
        'SELECT s.set_num, s.name, s.year, s.theme_id, t.name AS theme_name, ' +
        's.num_parts, s.img_url ' +
        'FROM sets s JOIN themes t ON t.id = s.theme_id ' +
        'WHERE 1 = 1';
      if ASearchText.Trim <> '' then
        Query.SQL.Add(
          'AND (instr(lower(s.name), lower(:SearchText)) > 0 ' +
          'OR instr(lower(s.set_num), lower(:SearchText)) > 0)');
      if AThemeID > 0 then
        Query.SQL.Add('AND s.theme_id = :ThemeID');
      if AYear > 0 then
        Query.SQL.Add('AND s.year = :Year');
      if AAfter <> '' then
        Query.SQL.Add('AND s.set_num > :After');
      Query.SQL.Add('ORDER BY s.set_num LIMIT :Limit');

      if ASearchText.Trim <> '' then
        Query.ParamByName('SearchText').AsString := ASearchText.Trim;
      if AThemeID > 0 then
        Query.ParamByName('ThemeID').AsInteger := AThemeID;
      if AYear > 0 then
        Query.ParamByName('Year').AsInteger := AYear;
      if AAfter <> '' then
        Query.ParamByName('After').AsString := AAfter;
      Query.ParamByName('Limit').AsInteger := PageSize + 1;
      Query.Open;

      var ItemCount := 0;
      while not Query.Eof do begin
        if ItemCount = PageSize then begin
          Result.HasMore := True;
          Break;
        end;
        SetLength(Result.Items, ItemCount + 1);
        Result.Items[ItemCount] := ReadCatalogSet(Query);
        Inc(ItemCount);
        Query.Next;
      end;
      if Result.HasMore and (ItemCount > 0) then
        Result.NextCursor := Result.Items[ItemCount - 1].SetNumber;
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

function TRebrickableCatalogRepository.TryGetSet(const ASetNumber: string; out ASet: TCatalogSet): Boolean;
begin
  if ASetNumber.Trim = '' then
    raise EArgumentException.Create('Set number is required.');
  if Length(ASetNumber) > cMaximumCursorLength then
    raise EArgumentOutOfRangeException.Create('Set number is too long.');

  var Connection := NewReadOnlyConnection(FDatabaseFileName);
  try
    var Query := NewQuery(Connection);
    try
      Query.SQL.Text :=
        'SELECT s.set_num, s.name, s.year, s.theme_id, t.name AS theme_name, ' +
        's.num_parts, s.img_url ' +
        'FROM sets s JOIN themes t ON t.id = s.theme_id ' +
        'WHERE s.set_num = :SetNumber';
      Query.ParamByName('SetNumber').AsString := ASetNumber.Trim;
      Query.Open;
      Result := not Query.Eof;
      if Result then
        ASet := ReadCatalogSet(Query)
      else
        ASet := Default(TCatalogSet);
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

function TRebrickableCatalogRepository.SearchParts(const ASearchText: string;
  ACategoryID, AColorID, APageSize: Integer; const AAfter: string): TCatalogPartPage;
begin
  ValidateSearchText(ASearchText);
  ValidateOptionalID(ACategoryID, 'Part category ID');
  ValidateOptionalID(AColorID, 'Color ID');
  ValidateCursor(AAfter);
  var PageSize := NormalizePageSize(APageSize);
  Result.Items := nil;
  Result.NextCursor := '';
  Result.HasMore := False;

  var Connection := NewReadOnlyConnection(FDatabaseFileName);
  try
    var Query := NewQuery(Connection);
    try
      Query.SQL.Text :=
        'SELECT p.part_num, p.name, p.part_cat_id, ' +
        'c.name AS category_name, p.part_material ' +
        'FROM parts p JOIN part_categories c ON c.id = p.part_cat_id ' +
        'WHERE 1 = 1';
      if ASearchText.Trim <> '' then
        Query.SQL.Add(
          'AND (instr(lower(p.name), lower(:SearchText)) > 0 ' +
          'OR instr(lower(p.part_num), lower(:SearchText)) > 0)');
      if ACategoryID > 0 then
        Query.SQL.Add('AND p.part_cat_id = :CategoryID');
      if AColorID > 0 then
        Query.SQL.Add(
          'AND EXISTS (SELECT 1 FROM elements e ' +
          'WHERE e.part_num = p.part_num AND e.color_id = :ColorID)');
      if AAfter <> '' then
        Query.SQL.Add('AND p.part_num > :After');
      Query.SQL.Add('ORDER BY p.part_num LIMIT :Limit');

      if ASearchText.Trim <> '' then
        Query.ParamByName('SearchText').AsString := ASearchText.Trim;
      if ACategoryID > 0 then
        Query.ParamByName('CategoryID').AsInteger := ACategoryID;
      if AColorID > 0 then
        Query.ParamByName('ColorID').AsInteger := AColorID;
      if AAfter <> '' then
        Query.ParamByName('After').AsString := AAfter;
      Query.ParamByName('Limit').AsInteger := PageSize + 1;
      Query.Open;

      var ItemCount := 0;
      while not Query.Eof do begin
        if ItemCount = PageSize then begin
          Result.HasMore := True;
          Break;
        end;
        SetLength(Result.Items, ItemCount + 1);
        Result.Items[ItemCount] := ReadCatalogPart(Query);
        Inc(ItemCount);
        Query.Next;
      end;
      if Result.HasMore and (ItemCount > 0) then
        Result.NextCursor := Result.Items[ItemCount - 1].PartNumber;
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

function TRebrickableCatalogRepository.TryGetPart(const APartNumber: string; out APart: TCatalogPart): Boolean;
begin
  if APartNumber.Trim = '' then
    raise EArgumentException.Create('Part number is required.');
  if Length(APartNumber) > cMaximumCursorLength then
    raise EArgumentOutOfRangeException.Create('Part number is too long.');

  var Connection := NewReadOnlyConnection(FDatabaseFileName);
  try
    var Query := NewQuery(Connection);
    try
      Query.SQL.Text :=
        'SELECT p.part_num, p.name, p.part_cat_id, ' +
        'c.name AS category_name, p.part_material ' +
        'FROM parts p JOIN part_categories c ON c.id = p.part_cat_id ' +
        'WHERE p.part_num = :PartNumber';
      Query.ParamByName('PartNumber').AsString := APartNumber.Trim;
      Query.Open;
      Result := not Query.Eof;
      if Result then
        APart := ReadCatalogPart(Query)
      else
        APart := Default(TCatalogPart);
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

function TRebrickableCatalogRepository.GetThemes: TArray<TCatalogTheme>;
begin
  var Connection := NewReadOnlyConnection(FDatabaseFileName);
  try
    var Query := NewQuery(Connection);
    try
      Query.SQL.Text :=
        'SELECT id, name, parent_id FROM themes ORDER BY name, id';
      Query.Open;
      var ItemCount := 0;
      while not Query.Eof do begin
        SetLength(Result, ItemCount + 1);
        Result[ItemCount].ID := Query.FieldByName('id').AsInteger;
        Result[ItemCount].Name := Query.FieldByName('name').AsString;
        Result[ItemCount].HasParent :=
          not Query.FieldByName('parent_id').IsNull;
        if Result[ItemCount].HasParent then
          Result[ItemCount].ParentID :=
            Query.FieldByName('parent_id').AsInteger;
        Inc(ItemCount);
        Query.Next;
      end;
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

function TRebrickableCatalogRepository.GetColors: TArray<TCatalogColor>;
begin
  var Connection := NewReadOnlyConnection(FDatabaseFileName);
  try
    var Query := NewQuery(Connection);
    try
      Query.SQL.Text :=
        'SELECT id, name, rgb, is_trans FROM colors ORDER BY name, id';
      Query.Open;
      var ItemCount := 0;
      while not Query.Eof do begin
        SetLength(Result, ItemCount + 1);
        Result[ItemCount].ID := Query.FieldByName('id').AsInteger;
        Result[ItemCount].Name := Query.FieldByName('name').AsString;
        Result[ItemCount].RGB := Query.FieldByName('rgb').AsString;
        Result[ItemCount].IsTransparent :=
          Query.FieldByName('is_trans').AsInteger <> 0;
        Inc(ItemCount);
        Query.Next;
      end;
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

function TRebrickableCatalogRepository.TryGetColor(AColorID: Integer;
  out AColor: TCatalogColor): Boolean;
begin
  ValidateOptionalID(AColorID, 'Color ID');
  var Connection := NewReadOnlyConnection(FDatabaseFileName);
  try
    var Query := NewQuery(Connection);
    try
      Query.SQL.Text :=
        'SELECT id, name, rgb, is_trans FROM colors WHERE id = :ColorID';
      Query.ParamByName('ColorID').AsInteger := AColorID;
      Query.Open;
      Result := not Query.Eof;
      if Result then begin
        AColor.ID := Query.FieldByName('id').AsInteger;
        AColor.Name := Query.FieldByName('name').AsString;
        AColor.RGB := Query.FieldByName('rgb').AsString;
        AColor.IsTransparent :=
          Query.FieldByName('is_trans').AsInteger <> 0;
      end else
        AColor := Default(TCatalogColor);
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

function TRebrickableCatalogRepository.GetPartCategories: TArray<TCatalogPartCategory>;
begin
  var Connection := NewReadOnlyConnection(FDatabaseFileName);
  try
    var Query := NewQuery(Connection);
    try
      Query.SQL.Text :=
        'SELECT id, name FROM part_categories ORDER BY name, id';
      Query.Open;
      var ItemCount := 0;
      while not Query.Eof do begin
        SetLength(Result, ItemCount + 1);
        Result[ItemCount].ID := Query.FieldByName('id').AsInteger;
        Result[ItemCount].Name := Query.FieldByName('name').AsString;
        Inc(ItemCount);
        Query.Next;
      end;
    finally
      Query.Free;
    end;
  finally
    Connection.Free;
  end;
end;

end.
