unit UPostMessage;

interface

uses
  Windows, Messages;

type
  TShowSetData = record
    Set_num: String;
  end;
  PShowSetData = ^TShowSetData;

  TShowPartsData = record
    Set_num: String;
  end;
  PShowPartsData = ^TShowPartsData;

  TShowSetListData = record
    SetListID: Integer;
  end;
  PShowSetListData = ^TShowSetListData;

  TOpenExternalData = record
    ObjectType: Integer;
    ObjectID: String;
  end;
  POpenExternalData = ^TOpenExternalData;

const
  WM_SHOW_SET = WM_USER + 1;
  WM_SHOW_SETLIST = WM_USER + 2;
  WM_SHOW_PARTSLIST = WM_USER + 3;
  WM_OPEN_EXTERNAL = WM_USER + 4;

implementation

end.
