unit UPostMessage;

interface

uses
  Windows, Messages,
  UConfig;

type
  TShowSetData = record
    Set_num: String;
  end;
  PShowSetData = ^TShowSetData;

  TShowPartsData = record
    Set_num: String;
  end;
  PShowPartsData = ^TShowPartsData;

  TEditPartsData = record
    Set_num: String;
    BSSetID: Integer;
  end;
  PEditPartsData = ^TEditPartsData;

  TShowOrUpdateSetListData = record
    BSSetListID: Integer;
  end;
  PShowOrUpdateSetListData = ^TShowOrUpdateSetListData;

  TOpenExternalData = record
    ObjectType: TViewExternalType;
    ObjectID: String;
  end;
  POpenExternalData = ^TOpenExternalData;

const
  WM_SHOW_SET = WM_USER + 1;
  WM_SHOW_SETLIST = WM_USER + 2;
  WM_SHOW_PARTSLIST = WM_USER + 3;
  WM_EDIT_PARTSLIST = WM_USER + 4;
  WM_OPEN_EXTERNAL = WM_USER + 5;
  WM_SHOW_SEARCH = WM_USER + 6;
  WM_SHOW_COLLECTION = WM_USER + 7;
  WM_UPDATE_COLLECTION = WM_USER + 8;
  WM_UPDATE_SETLIST = WM_USER + 9;

implementation

end.
