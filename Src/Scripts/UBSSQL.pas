unit UBSSQL;

// BrickStack table creation scripts

interface

uses
  USQLUpdate, SysUtils;

const
  // Database version and changes:
  dbVERSION = 2; // Also see below! and update the insert query!
  dbMINVERSION = 2;
  //Note: SQLite doesn't seem to define text length, but making sure these are defined properly anyway in case we ever switch to a different DB sys.
  // At that time we'd set the minimumversion though.

  DBUpdateQueries: array[0..1] of String = (
    // 0: Initial version
    // 0 -> 1: Parts.part_num int -> text(20), .name(200) -> 250, table BSDBPartsInventory, index BSDBVersions
    '',
    // 1 -> 2: Themes.name text(40) -> text(42), DBSets.quantity -> removed, BSDBPartsInventory remade
    ''
  );

  //2D Array: TableName, SQL
  BS_CreateTables: array[0..5] of TTableSQL = (
    (TableName: 'BSSetLists';
      SQL: 'CREATE TABLE IF NOT EXISTS BSSetLists (' +
      '	ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,' +
      '	Name TEXT(128),' +
      '	Description TEXT(1024),' +
      '	UseInCollection INTEGER,' +
      '	SortIndex INTEGER,' +
      '	ExternalID INTEGER,' +  //-- external site's unique ID of your imported set list
      '	ExternalType INTEGER);' //-- rebrickable / bricklink / other
    ),
    (TableName: 'BSSets';
      SQL: 'CREATE TABLE IF NOT EXISTS BSSets (' +
      '	ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,' +
      '	BSSetListID INTEGER,' +
      '	set_num TEXT(20) NOT NULL,' + // -- link to rebrickable sets table
      '	Built INTEGER,' +
      '	HaveSpareParts INTEGER,' +
      '	Notes TEXT(1024));'
    ),
    (TableName: 'BSCustomTags';
      SQL: 'CREATE TABLE IF NOT EXISTS BSCustomTags (' +
      '	ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,' +
      '	LinkedID INTEGER,' +   // -- ID of the setlist/set
      '	CustomType INTEGER,' + // -- 1/2 = setlist/sets
      '	Value TEXT(128));'
    ),
    (TableName: 'BSDBVersions';
      SQL: 'CREATE TABLE IF NOT EXISTS BSDBVersions (' +
      '	ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,' +
      '	DBVersion INTEGER,' +   // Database structure version
      '	DBDateTime TEXT(14));'  // Date of import
    ),
    (TableName: 'BSDBVersions insert';
      SQL: 'INSERT INTO BSDBVersions (DBVersion, DBDateTime) values (:DBVersion, :DBDateTime);' // See: dbVERSION above - this array needs to be constant, so using params. See: FExecSQLAndUpdateProgress
    ),
    (TableName: 'BSDBPartsInventory';
      SQL: 'CREATE TABLE IF NOT EXISTS BSDBPartsInventory (' +
      ' ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,' + // You may own multiple of the same set, this way you can link to it's unique inventory
      ' BSSetID INTEGER,' +      // Link to the BSSet for update/delete
      ' InventoryID INTEGER,' +  // These 4 items are used to link to the inventory_parts
      ' Part_num TEXT(20),' +    // ^
      ' color_id INTEGER,' +     // ^
      ' is_spare INTEGER,' +     // ^
      ' quantity INTEGER);'      // How many do you have
    )
  );

  BS_CreateIndexes: array[0..4] of TTableSQL  = (
    (TableName: 'BSSetLists';
      SQL: 'CREATE INDEX IF NOT EXISTS BSSetLists_ID_IDX ON BSSetLists (ID);' +
           'CREATE INDEX IF NOT EXISTS BSSetLists_EXTERNALID_IDX ON BSSetLists (EXTERNALID);'),
    (TableName: 'BSSets';
      SQL: 'CREATE INDEX IF NOT EXISTS BSSets_ID_IDX ON BSSets (ID);' +
           'CREATE INDEX IF NOT EXISTS BSSets_set_num_IDX ON BSSets (set_num);' +
           'CREATE INDEX IF NOT EXISTS BSSets_BSSetListID_IDX ON BSSets (BSSetListID)'),
    (TableName: 'BSCustomTags';
      SQL: 'CREATE INDEX IF NOT EXISTS BSCustomTags_ID_IDX ON BSCustomTags (ID);' +
           'CREATE INDEX IF NOT EXISTS BSCustomTags_LinkedID_IDX ON BSCustomTags (LinkedID);'),
    (TableName: 'BSDBVersions';
      SQL: 'CREATE INDEX IF NOT EXISTS DBVersions_ID_IDX ON BSDBVersions (ID);'),
    (TableName: 'BSDBPartsInventory';
      SQL: 'CREATE INDEX IF NOT EXISTS BSDBVersions_ID_IDX ON BSDBPartsInventory (ID);' +
           'CREATE INDEX IF NOT EXISTS BSDBVersions_Part_num_IDX ON BSDBPartsInventory (Part_num);' +
           'CREATE INDEX IF NOT EXISTS BSDBPartsInventory_InventoryID_IDX ON BSDBPartsInventory (InventoryID,Part_num,color_id,is_spare);' +
           'CREATE INDEX IF NOT EXISTS BSDBPartsInventory_BSSetID_IDX ON BSDBPartsInventory (BSSetID);')
  );

implementation

end.