unit UPostMessage;

interface

uses
  Windows, Messages;

type
  TShowSetData = record
    Set_num: String;
  end;
  PShowSetData = ^TShowSetData;

  TShowSetListData = record
    SetList: Integer;
  end;
  PShowSetListData = ^TShowSetListData;

const
  WM_SHOW_SET = WM_USER + 1;
  WM_SHOW_SETLIST = WM_USER + 2;

implementation

end.
