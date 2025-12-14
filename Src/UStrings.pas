unit UStrings;

interface

// Try to keep all labels in one place, so it'll be easier to add translations later.

const
  // Language defines:
  lnEnglish = 0;
  lnDutch = 1;
  lnGerman = 2;
  lnFrench = 3;
  lnSpanish = 4;

  // Constants, links, version info
  StrAboutProductName = 'BrickStack';
  StrAboutCopyright = 'MIT license, Copyright 2025. Thomas. H.';
  StrAboutComment1 = 'Open source, See: bitbucket.org/tstki/brickstack' + #10 + 'Icons by Fatcow';
  StrAboutComment2 = 'Database by: https://github.com/ojuuji/rb.db';

  // Configuration
  StrRebrickableAPIInfo = 'https://rebrickable.com/api/';
  StrIniFileName = 'BrickStack.ini';
  StrCollectionsFileName = 'Collections.ini';
  StrDefaultCachePath = 'Cache\';
  StrDefaultLogPath = 'Logs\';
  StrDBaseName = 'BrickStack.db';
  StrDefaultdDBasePath = 'DBase\' + StrDbaseName;
  StrDefaultImportPath = 'Import\';
  StrDefaultExportPath = 'Export\';

  // Config - ini sections
  StrApplicationIniSection = 'Application';
  StrLocalIniSection = 'Local';
  StrBackupIniSection = 'Backup';
  StrHotkeyIniSection = 'Hotkeys';
  StrAuthenticationIniSection = 'Authentication';
  StrExternalIniSection = 'External';
  StrWindowsIniSection = 'Windows';
  StrSearchWindowIniSection = 'SearchWindow';
  StrCollectionWindowIniSection = 'CollectionWindow';
  StrSetListWindowIniSection = 'SetListWindow';
  StrSetWindowIniSection = 'SetWindow';
  StrSetPartsWindowIniSection = 'SetPartsWindow';

  // Dialog and frame labels
  StrSetListFrameTitle = 'Collection - set lists';
  StrPartListFrameTitle = 'Part list';
  StrSearchFrameTitle = 'Search';
  StrFrmSetTitle = 'Lego set: %s - %s';
  StrMax = 'Max: %d';
  StrAddSetTo = 'Add set ''%s'' to:';
  StrEditSetTo = 'Edit set ''%s'' (%d):';
  StrSelectFile = 'Select a file';
  StrNewCollectionName = 'New collection';
  StrYouHaveSetsCollections = 'You have %d sets across %d setlists.';
  StrYes = 'Yes';
  StrNo = 'No';
  StrSetList = 'Setlist';

  // Setlist filter
  StrSetListFillterShowAll = 'All';
  StrSetListFillterShowLocal = 'Created locally';
  StrSetListFillterShowRebrickable = 'Imported from Rebrickable';
  StrSetListFillterShowSets = 'Has sets';
  StrSetListFillterShowNoSets = 'Has no sets';

  StrSetListFillterQuantity = 'Quantity 2 or more';
  StrSetListFillterBuilt = 'Built';
  StrSetListFillterNotBuilt = 'Not built';
  StrSetListFillterSpareParts = 'Have spare parts';
  StrSetListFillterNoSpareParts = 'No spare parts';

  // Search areas
  StrYourCollections = 'All owned';
  StrDatabase = 'Database';
  StrYourSets = 'Sets (Owned)';
  StrDatabaseSets = 'Sets (Database)';
  StrYourParts = 'Parts (Owned)';
  StrDatabaseParts = 'Parts (Database)';
  StrYourMinifigs = 'Minifigs (Owned)';
  StrDatabaseMinifigs = 'Minifigs (Database)';

  // Parts sort
  StrPartSortByColor = 'Color';
  StrPartSortByHue = 'Hue';
  StrPartSortByPart = 'Part';
  StrPartSortByCategory = 'Category';
  StrPartSortByPrice = 'Price';
  StrPartSortByQuantity = 'Quantity';

  // Setlist Types (External type)

  // Search style
  StrSearchAll = '% text %';
  StrSearchPrefix = 'prefix %';
  StrSearchSuffix = '% suffix';
  StrSearchExact = 'Exact';

  StrSearchNumber = 'Number';
  StrSearchName = 'Name';

  StrSearchSets = 'Sets';
  StrSearchMinifigs = 'Minifigures';
  StrSearchParts = 'Parts';
  StrAny = 'Any';
  StrNewCollection = 'New collection';

  // Option labels
  StrNameRebrickableAPI = 'Rebrickable API';
  StrNameRebrickableCSV = 'Rebrickable CSV (4 columns)';
  StrNameBrickLinkXML = 'BrickLink XML';
  StrImportOptionMerge = 'Merge with local by ID';
  StrImportOptionAppend = 'Keep local and append new';
  StrImportOptionOverwrite = 'Clear local and add new';
  StrExportRemoteAppend = 'Append';
  StrExportRemoteSubtract = 'Subtract';
  StrExportRemoteReplace = 'Replace';
  StrExportRemoteDeleteAll = 'Delete all';

  StrOTNone = 'Request on open'; // Only used by DlgConfig
  StrOTRebrickable = 'Rebrickable';
  StrOTBrickLink = 'BrickLink';
  StrOTBrickOwl = 'BrickOwl';
  StrOTBrickSet = 'BrickSet';
  StrOTLDraw = 'LDraw';
  //StrOTCustom = 'Custom (Link)';

  StrActViewSet = 'View set(s)';
  StrActViewExternal = 'View externally';
  StrActEditDetails = 'Edit details';
  StrActViewParts = 'View parts inventory';
  StrActEditParts = 'Edit parts';

  // Export
  StrExportCSVFilter = 'CSV Files (*.csv)|*.CSV|All Files (*.*)|*.*';
  StrExportXMLFilter = 'XML Files (*.xml)|*.XML|All Files (*.*)|*.*';
  StrExportCSVFileType = 'csv';
  StrExportXMLileType = 'xml';
  StrSaveAsTitle = 'Save As';
  StrFileExistsWarning = 'File "%s" already exists, do you want to overwrite it?';

  // Message strings
  StrMsgSureDelete = 'Are you sure you wish to delete "%s"(ID: %d)? This action can''t be undone and will also delete all parts and sets registered within.';
  StrMsgSureRemoveFromList = 'Are you sure you wish to remove set "%s" (num: %s)? This action can''t be undone.';
  StrMsgDataBaseUpdateComplete = 'Database update / creation complete.' + #13#10 + 'If you need information, please use the help menu.' + #13#10#13#10 + 'Good luck!';
  StrMsgDatabaseIsUpToDate = 'Your database structure is up to date.';
  StrMsgDatabaseUnableToUpDate = 'Your database structure is beyond the minimum version to update. Please create a backup and remove the database manually, then restart the application.';
  StrMsgSetPartsToZero = 'Are you sure you wish to set the quantity of all parts to "zero"?';
  StrMsgInvertPartsSelection = 'Are you sure you wish to invert the "complete / zero" of all parts?';
  StrMsgSetPartsToComplete = 'Are you sure you wish to set the quantity of all part to "complete"?';
  StrMsgImportCount = '%d rows imported';

  // Error strings
  StrErrNoResult = 'No result';
  StrErrAPIKeyNotSet = 'API key not set, please see configuration first.';
  StrErrTokenNotSet = 'Missing authentication token, please login first.';
  StrErrFileNotFound = 'File not found or no longer accessible. (%s)';
  StrErrMergeUnavailableForRebrickableCSVImport = '"Merge by ID" is unavailable for Rebrickable CSV imports. Please select another option.';
  StrErrImportFailed = 'Import failed';

implementation

end.
