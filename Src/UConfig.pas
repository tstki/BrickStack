unit UConfig;

interface

uses
  System.Classes, Forms, IniFiles, UConst;

type
  TClientFormStorage = class(TObject)
  private
    FOpenOnLoad: String;
    FTop: Integer;
    FLeft: Integer;
    FWidth: Integer;
    FHeight: Integer;
    FDimensionsValid: Boolean; // Check before using tl/wh
    procedure Save(IniFile: TIniFile; const Section, Name: String);
    procedure Load(IniFile: TIniFile; const Section, Name: String);
  public
    property OpenOnLoad: String read FOpenOnLoad write FOpenOnLoad;
    property Top: Integer read FTop write FTop;
    property Left: Integer read FLeft write FLeft;
    property Width: Integer read FWidth write FWidth;
    property Height: Integer read FHeight write FHeight;
    procedure GetFormDimensions(const Form: TForm);
    function SetFormDimensions(Form: TForm): Boolean;
  end;

  TConfig = class(TObject)
  private
    { Private declarations }
    FRebrickableAPIKey: String;
    FRebrickableBaseUrl: String;
    FAuthenticationToken: String;           // Only saved if:
    FRememberAuthenticationToken: Boolean;  /// is true
    FLocalImageCachePath: String;
    FLocalLogsPath: String;
    FViewRebrickableUrl: String;
    FViewBrickLinkUrl: String;
    FViewBrickOwlUrl: String;
    FViewBrickSetUrl: String;
    FViewLDrawUrl: String;
    FDefaultViewSetOpenType: TExternalOpenType;
    FDefaultViewPartOpenType: TExternalOpenType;
    FDbasePath: String;
    FImportPath: String;
    FExportPath: String;
    FVisualStyle: String;
    FSearchListDoubleClickAction: TDoubleClickAction;
    FCollectionListDoubleClickAction: TDoubleClickAction;
    FSetListDoubleClickAction: TDoubleClickAction;
    FPartsListDoubleClickAction: TDoubleClickAction;

    // Parts window settings:
    FWPartsShowPartCount: Boolean;
    FWPartsShowPartnum: Boolean;
    FWPartsIncludeNonSpareParts: Boolean;
    FWPartsIncludeSpareParts: Boolean;
    FWPartsSortByCategory: Boolean;
    FWPartsSortByColor: Boolean;
    FWPartsSortByHue: Boolean;
    FWPartsSortByPart: Boolean;
    FWPartsSortByQuantity: Boolean;
    FWPartsSortAscending: Boolean;

    FPartIncrementClick: Integer;
    FPartIncrementShiftClick: Integer;
    FPartIncrementCtrlClick: Integer;
    FPartIncrementCtrlShiftClick: Integer;

    FSearchLimit: Integer;
    FWSearchGridSize: Integer;
    FWSearchShowNumber: Boolean;
    FWSearchShowYear: Boolean;
    FWSearchShowSetQuantity: Boolean;
    FWSearchShowCollectionID: Boolean;
    FWSearchShowPartCount: Boolean;
    FWSearchShowPartOrMinifigNumber: Boolean;
    FWSearchSortAscending: Boolean;
    FWSearchSortByName: Boolean;
    FWSearchSortByTheme: Boolean;
    FWSearchSortByNumber: Boolean;
    FWSearchSortByPartCount: Boolean;
    FWSearchSortByYear: Boolean;
    FWSearchOwnCollection: Boolean;
    FWSearchStyle: Integer;
    FWSearchWhat: Integer;
    FWSearchBy: Integer;

    // Window states
    FReOpenWindowsAfterRestart: Boolean;

    FFrmSetListCollection: TClientFormStorage;
    FFrmSetList: TClientFormStorage;
    FFrmSet: TClientFormStorage;
    FFrmParts: TClientFormStorage;
    FFrmSearch: TClientFormStorage;

  public
    { Public declarations }
    constructor Create;
    destructor Destroy; override;
    procedure Save(Section: TConfigSection);
    procedure Load;
    procedure ResetFramesOpenOnLoad;
    procedure ResetFramesDimensions;
    property RebrickableAPIKey: String read FRebrickableAPIKey write FRebrickableAPIKey;
    property RebrickableBaseUrl: String read FRebrickableBaseUrl write FRebrickableBaseUrl;
    property AuthenticationToken: String read FAuthenticationToken write FAuthenticationToken;
    property RememberAuthenticationToken: Boolean read FRememberAuthenticationToken write FRememberAuthenticationToken;
    property LocalImageCachePath: String read FLocalImageCachePath write FLocalImageCachePath;
    property LocalLogsPath: String read FLocalLogsPath write FLocalLogsPath;
    property ViewRebrickableUrl: String read FViewRebrickableUrl write FViewRebrickableUrl;
    property ViewBrickLinkUrl: String read FViewBrickLinkUrl write FViewBrickLinkUrl;
    property ViewBrickOwlUrl: String read FViewBrickOwlUrl write FViewBrickOwlUrl;
    property ViewBrickSetUrl: String read FViewBrickSetUrl write FViewBrickSetUrl;
    property ViewLDrawUrl: String read FViewLDrawUrl write FViewLDrawUrl;
    property DefaultViewSetOpenType: TExternalOpenType read FDefaultViewSetOpenType write FDefaultViewSetOpenType;
    property DefaultViewPartOpenType: TExternalOpenType read FDefaultViewPartOpenType write FDefaultViewPartOpenType;
    property DbasePath: String read FDbasePath write FDbasePath;
    property ImportPath: String read FImportPath write FImportPath;
    property ExportPath: String read FExportPath write FExportPath;
    property VisualStyle: String read FVisualStyle write FVisualStyle;
    property SearchListDoubleClickAction: TDoubleClickAction read FSearchListDoubleClickAction write FSearchListDoubleClickAction;
    property CollectionListDoubleClickAction: TDoubleClickAction read FCollectionListDoubleClickAction write FCollectionListDoubleClickAction;
    property SetListDoubleClickAction: TDoubleClickAction read FSetListDoubleClickAction write FSetListDoubleClickAction;
    property PartsListDoubleClickAction: TDoubleClickAction read FPartsListDoubleClickAction write FPartsListDoubleClickAction;

    property WPartsShowPartCount: Boolean read FWPartsShowPartCount write FWPartsShowPartCount;
    property WPartsShowPartnum: Boolean read FWPartsShowPartnum write FWPartsShowPartnum;
    property WPartsIncludeNonSpareParts: Boolean read FWPartsIncludeNonSpareParts write FWPartsIncludeNonSpareParts;
    property WPartsIncludeSpareParts: Boolean read FWPartsIncludeSpareParts write FWPartsIncludeSpareParts;
    property WPartsSortByCategory: Boolean read FWPartsSortByCategory write FWPartsSortByCategory;
    property WPartsSortByColor: Boolean read FWPartsSortByColor write FWPartsSortByColor;
    property WPartsSortByHue: Boolean read FWPartsSortByHue write FWPartsSortByHue;
    property WPartsSortByPart: Boolean read FWPartsSortByPart write FWPartsSortByPart;
    property WPartsSortByQuantity: Boolean read FWPartsSortByQuantity write FWPartsSortByQuantity;
    property WPartsSortAscending: Boolean read FWPartsSortAscending write FWPartsSortAscending;

    property PartIncrementClick: Integer read FPartIncrementClick write FPartIncrementClick;
    property PartIncrementShiftClick: Integer read FPartIncrementShiftClick write FPartIncrementShiftClick;
    property PartIncrementCtrlClick: Integer read FPartIncrementCtrlClick write FPartIncrementCtrlClick;
    property PartIncrementCtrlShiftClick: Integer read FPartIncrementCtrlShiftClick write FPartIncrementCtrlShiftClick;

    property SearchLimit: Integer read FSearchLimit write FSearchLimit;
    property WSearchGridSize: Integer read FWSearchGridSize write FWSearchGridSize;
    property WSearchShowYear: Boolean read FWSearchShowYear write FWSearchShowYear;
    property WSearchShowNumber: Boolean read FWSearchShowNumber write FWSearchShowNumber;
    property WSearchShowSetQuantity: Boolean read FWSearchShowSetQuantity write FWSearchShowSetQuantity;
    property WSearchShowCollectionID: Boolean read FWSearchShowCollectionID write FWSearchShowCollectionID;
    property WSearchShowPartCount: Boolean read FWSearchShowPartCount write FWSearchShowPartCount;
    property WSearchShowPartOrMinifigNumber: Boolean read FWSearchShowPartOrMinifigNumber write FWSearchShowPartOrMinifigNumber;
    property WSearchSortAscending: Boolean read FWSearchSortAscending write FWSearchSortAscending;
    property WSearchSortByTheme: Boolean read FWSearchSortByTheme write FWSearchSortByTheme;
    property WSearchSortByNumber: Boolean read FWSearchSortByNumber write FWSearchSortByNumber;
    property WSearchSortByPartCount: Boolean read FWSearchSortByPartCount write FWSearchSortByPartCount;
    property WSearchSortByName: Boolean read FWSearchSortByName write FWSearchSortByName;
    property WSearchSortByYear: Boolean read FWSearchSortByYear write FWSearchSortByYear;
    property WSearchOwnCollection: Boolean read FWSearchOwnCollection write FWSearchOwnCollection;
    property WSearchStyle: Integer read FWSearchStyle write FWSearchStyle;
    property WSearchWhat: Integer read FWSearchWhat write FWSearchWhat;
    property WSearchBy: Integer read FWSearchBy write FWSearchBy;

    property ReOpenWindowsAfterRestart: Boolean read FReOpenWindowsAfterRestart write FReOpenWindowsAfterRestart;
{    property FrmSetListCollectionWasOpen: Boolean read FFrmSetListCollectionWasOpen write FFrmSetListCollectionWasOpen;
    property FrmSetListWasOpen: Integer read FFrmSetListWasOpen write FFrmSetListWasOpen;
    property FrmSetWasOpen: String read FFrmSetWasOpen write FFrmSetWasOpen;
    property FrmPartsWasOpen: String read FFrmPartsWasOpen write FFrmPartsWasOpen;
    property FrmSearchWasOpen: Boolean read FFrmSearchWasOpen write FFrmSearchWasOpen;
}
    property FrmSetListCollection: TClientFormStorage read FFrmSetListCollection write FFrmSetListCollection;
    property FrmSetList: TClientFormStorage read FFrmSetList write FFrmSetList;
    property FrmSet: TClientFormStorage read FFrmSet write FFrmSet;
    property FrmParts: TClientFormStorage read FFrmParts write FFrmParts;
    property FrmSearch: TClientFormStorage read FFrmSearch write FFrmSearch;
  end;

implementation

uses
  StrUtils, SysUtils,
  UStrings;

// FormStorage
procedure TClientFormStorage.Save(IniFile: TIniFile; const Section, Name: String);
begin
  var Value := Format('%d,%d,%d,%d,%s', [FTop,FLeft,FWidth,FHeight,FOpenOnLoad]);
  IniFile.WriteString(Section, Name, Value);
end;

procedure TClientFormStorage.Load(IniFile: TIniFile; const Section, Name: String);
begin
  var Value := IniFile.ReadString(Section, Name, '');
  var SplitArray := Value.Split([',']);

  if Length(SplitArray) = 5 then begin
    FTop := StrToIntDef(SplitArray[0], 0);
    FLeft := StrToIntDef(SplitArray[1], 0);
    FWidth := StrToIntDef(SplitArray[2], 0);
    FHeight := StrToIntDef(SplitArray[3], 0);
    FOpenOnLoad := SplitArray[4];

    FDimensionsValid := ((FTop+FLeft+FWidth+FHeight) <> 0) and (FWidth > 20) and (FHeight > 20);
  end else
    FDimensionsValid := False;
end;

procedure TClientFormStorage.GetFormDimensions(const Form: TForm);
begin
  FTop := Form.Top;
  FLeft := Form.Left;
  FWidth := Form.Width;
  FHeight := Form.Height;
end;

function TClientFormStorage.SetFormDimensions(Form: TForm): Boolean;
begin
  if FDimensionsValid then begin
    Form.Top := FTop;
    Form.Left := FLeft;
    Form.Width := FWidth;
    Form.Height := FHeight;
    Result := True;
  end else
    Result := False;
end;

// Config
constructor TConfig.Create;
begin
  inherited;

  FrmSetListCollection := TClientFormStorage.Create;
  FrmSetList := TClientFormStorage.Create;
  FrmSet := TClientFormStorage.Create;
  FrmParts := TClientFormStorage.Create;
  FrmSearch := TClientFormStorage.Create;
end;

destructor TConfig.Destroy;
begin
  FrmSetListCollection.Free;
  FrmSetList.Free;
  FrmSet.Free;
  FrmParts.Free;
  FrmSearch.Free;

  inherited;
end;

procedure TConfig.ResetFramesOpenOnLoad;
begin
  FrmSetListCollection.OpenOnLoad := '';
  FrmSetList.OpenOnLoad := '';
  FrmSet.OpenOnLoad := '';
  FrmParts.OpenOnLoad := '';
  FrmSearch.OpenOnLoad := '';
end;

procedure TConfig.ResetFramesDimensions;
begin
  //
end;

procedure TConfig.Save(Section: TConfigSection);
begin
  var FilePath := ExtractFilePath(ParamStr(0));
  var IniFile := TIniFile.Create(FilePath + StrIniFileName);
  try
    if Section in [csALL, csCONFIGDIALOG] then begin
      IniFile.WriteString(StrAuthenticationIniSection, 'RebrickableAPIKey', FRebrickableAPIKey);
      IniFile.WriteString(StrAuthenticationIniSection, 'RebrickableBaseUrl', FRebrickableBaseUrl);
      IniFile.WriteString(StrAuthenticationIniSection, 'AuthenticationToken', IfThen(FRememberAuthenticationToken, FAuthenticationToken, ''));
      IniFile.WriteBool(StrAuthenticationIniSection, 'RememberAuthenticationToken', FRememberAuthenticationToken);

      IniFile.WriteString(StrExternalIniSection, 'ViewRebrickableUrl', FViewRebrickableUrl);
      IniFile.WriteString(StrExternalIniSection, 'ViewBrickLinkUrl', FViewBrickLinkUrl);
      IniFile.WriteString(StrExternalIniSection, 'ViewBrickOwlUrl', FViewBrickOwlUrl);
      IniFile.WriteString(StrExternalIniSection, 'ViewBrickSetUrl', FViewBrickSetUrl);
      IniFile.WriteString(StrExternalIniSection, 'ViewLDrawUrl', FViewLDrawUrl);
      IniFile.WriteInteger(StrExternalIniSection, 'DefaultViewSetOpenType', Integer(FDefaultViewSetOpenType));
      IniFile.WriteInteger(StrExternalIniSection, 'DefaultViewPartOpenType', Integer(FDefaultViewPartOpenType));

      IniFile.WriteString(StrLocalIniSection, 'LocalImageCachePath', FLocalImageCachePath);
      IniFile.WriteString(StrLocalIniSection, 'LocalLogsPath', FLocalLogsPath);
      IniFile.WriteString(StrLocalIniSection, 'DbasePath', FDbasePath);
      IniFile.WriteString(StrLocalIniSection, 'ImportPath', FImportPath);
      IniFile.WriteString(StrLocalIniSection, 'ExportPath', FExportPath);

      IniFile.WriteString(StrApplicationIniSection, 'VisualStyle', FVisualStyle);
      IniFile.WriteBool(StrWindowsIniSection, 'ReOpenWindowsAfterRestart', FReOpenWindowsAfterRestart);

      IniFile.WriteInteger(StrSearchWindowIniSection, 'SearchListDoubleClickAction', Integer(FSearchListDoubleClickAction));
      IniFile.WriteInteger(StrSearchWindowIniSection, 'SearchLimit', FSearchLimit);

      IniFile.WriteInteger(StrCollectionWindowIniSection, 'CollectionListDoubleClickAction', Integer(FCollectionListDoubleClickAction));
      IniFile.WriteInteger(StrSetlistWindowIniSection, 'SetListDoubleClickAction', Integer(FSetListDoubleClickAction));
      IniFile.WriteInteger(StrSetPartsWindowIniSection, 'PartsListDoubleClickAction', Integer(FPartsListDoubleClickAction));

      IniFile.WriteInteger(StrSetlistWindowIniSection, 'PartIncrementClick', FPartIncrementClick);
      IniFile.WriteInteger(StrSetlistWindowIniSection, 'PartIncrementShiftClick', FPartIncrementShiftClick);
      IniFile.WriteInteger(StrSetlistWindowIniSection, 'PartIncrementCtrlClick', FPartIncrementCtrlClick);
      IniFile.WriteInteger(StrSetlistWindowIniSection, 'PartIncrementCtrlShiftClick', FPartIncrementCtrlShiftClick);
    end;

    // Frame size/open states
    if Section in [csALL, csWINDOWPOSITIONS] then begin
      FFrmSetListCollection.Save(IniFile, StrCollectionWindowIniSection, 'FrmSetListCollection');
      FFrmSetList.Save(IniFile, StrSetListWindowIniSection, 'FrmSetList');
      FFrmSet.Save(IniFile, StrSetWindowIniSection, 'FrmSet');
      FFrmParts.Save(IniFile, StrSetPartsWindowIniSection, 'FrmParts');
      FFrmSearch.Save(IniFile, StrSearchWindowIniSection, 'FrmSearch');
    end;

    // Search window filters and sorting
    if Section in [csALL, csSEARCHWINDOWFILTERS] then begin
      IniFile.WriteInteger(StrSearchWindowIniSection, 'WSearchGridSize', FWSearchGridSize);
      IniFile.WriteBool(StrSearchWindowIniSection, 'WSearchSortAscending', FWSearchSortAscending);
      IniFile.WriteBool(StrSearchWindowIniSection, 'WSearchShowNumber', FWSearchShowNumber);
      IniFile.WriteBool(StrSearchWindowIniSection, 'WSearchShowYear', FWSearchShowYear);
      IniFile.WriteBool(StrSearchWindowIniSection, 'WSearchShowSetQuantity', FWSearchShowSetQuantity);
      IniFile.WriteBool(StrSearchWindowIniSection, 'WSearchShowCollectionID', FWSearchShowCollectionID);
      IniFile.WriteBool(StrSearchWindowIniSection, 'WSearchShowPartCount', FWSearchShowPartCount);
      IniFile.WriteBool(StrSearchWindowIniSection, 'WSearchShowPartOrMinifigNumber', FWSearchShowPartOrMinifigNumber);
      IniFile.WriteBool(StrSearchWindowIniSection, 'WSearchSortByTheme', FWSearchSortByTheme);
      IniFile.WriteBool(StrSearchWindowIniSection, 'WSearchSortByNumber', FWSearchSortByNumber);
      IniFile.WriteBool(StrSearchWindowIniSection, 'WSearchSortByPartCount', FWSearchSortByPartCount);
      IniFile.WriteBool(StrSearchWindowIniSection, 'WSearchSortByName', FWSearchSortByName);
      IniFile.WriteBool(StrSearchWindowIniSection, 'WSearchSortByYear', FWSearchSortByYear);
      IniFile.WriteBool(StrSearchWindowIniSection, 'WSearchOwnCollection', FWSearchOwnCollection);
      IniFile.WriteInteger(StrSearchWindowIniSection, 'WSearchStyle', FWSearchStyle);
      IniFile.WriteInteger(StrSearchWindowIniSection, 'WSearchWhat', FWSearchWhat);
      IniFile.WriteInteger(StrSearchWindowIniSection, 'WSearchBy', FWSearchBy);
    end;

    // Parts window filters and sorting
    if Section in [csALL, csPARTSWINDOWFILTERS] then begin
      IniFile.WriteBool(StrSetPartsWindowIniSection, 'WPartsShowPartCount', FWPartsShowPartCount);
      IniFile.WriteBool(StrSetPartsWindowIniSection, 'WPartsShowPartnum', FWPartsShowPartnum);
      IniFile.WriteBool(StrSetPartsWindowIniSection, 'WPartsIncludeNonSpareParts', FWPartsIncludeNonSpareParts);
      IniFile.WriteBool(StrSetPartsWindowIniSection, 'WPartsIncludeSpareParts', FWPartsIncludeSpareParts);
      IniFile.WriteBool(StrSetPartsWindowIniSection, 'WPartsSortByCategory', FWPartsSortByCategory);
      IniFile.WriteBool(StrSetPartsWindowIniSection, 'WPartsSortByColor', FWPartsSortByColor);
      IniFile.WriteBool(StrSetPartsWindowIniSection, 'WPartsSortByHue', FWPartsSortByHue);
      IniFile.WriteBool(StrSetPartsWindowIniSection, 'WPartsSortByPart', FWPartsSortByPart);
      IniFile.WriteBool(StrSetPartsWindowIniSection, 'WPartsSortByQuantity', FWPartsSortByQuantity);
      IniFile.WriteBool(StrSetPartsWindowIniSection, 'WPartsSortAscending', FWPartsSortAscending);
    end;
  finally
    IniFile.Free;
  end;
end;

procedure TConfig.Load;

  function ReadStringWithDefaultPath(const Section, Ident, FilePath, Default: String; IniFile: TIniFile): String;
  begin
    Result := IniFile.ReadString(Section, Ident, '');
    if Result = '' then
      Result := FilePath + Default;
  end;

begin
  var FilePath := ExtractFilePath(ParamStr(0));
  var IniFile := TIniFile.Create(FilePath + StrIniFileName);
  try
    FRebrickableAPIKey := IniFile.ReadString(StrAuthenticationIniSection, 'RebrickableAPIKey', '');
    FRebrickableBaseUrl := IniFile.ReadString(StrAuthenticationIniSection, 'RebrickableBaseUrl', 'https://rebrickable.com/');
    FAuthenticationToken := IniFile.ReadString(StrAuthenticationIniSection, 'AuthenticationToken', '');
    FRememberAuthenticationToken := IniFile.ReadBool(StrAuthenticationIniSection, 'RememberAuthenticationToken', False);

    FViewRebrickableUrl := IniFile.ReadString(StrExternalIniSection, 'ViewRebrickableUrl', 'https://rebrickable.com/');
    FViewBrickLinkUrl := IniFile.ReadString(StrExternalIniSection, 'ViewBrickLinkUrl', 'https://www.bricklink.com/');
    FViewBrickOwlUrl := IniFile.ReadString(StrExternalIniSection, 'ViewBrickOwlUrl', 'https://www.brickowl.com/');
    FViewBrickSetUrl := IniFile.ReadString(StrExternalIniSection, 'ViewBrickSetUrl', 'https://www.brickset.com/');
    FViewLDrawUrl := IniFile.ReadString(StrExternalIniSection, 'ViewLDrawUrl', 'https://library.ldraw.org/');
    FDefaultViewSetOpenType := TExternalOpenType(IniFile.ReadInteger(StrExternalIniSection, 'DefaultViewSetOpenType', Integer(cOTNONE)));
    FDefaultViewPartOpenType := TExternalOpenType(IniFile.ReadInteger(StrExternalIniSection, 'DefaultViewPartOpenType', Integer(cOTNONE)));

    FLocalImageCachePath := ReadStringWithDefaultPath(StrLocalIniSection, 'LocalImageCachePath', FilePath, StrDefaultCachePath, IniFile);
    FLocalLogsPath := ReadStringWithDefaultPath(StrLocalIniSection, 'LocalLogsPath', FilePath, StrDefaultLogPath, IniFile);
    FDbasePath := ReadStringWithDefaultPath(StrLocalIniSection, 'DbasePath', FilePath, StrDefaultdDbasePath, IniFile);
    FImportPath := ReadStringWithDefaultPath(StrLocalIniSection, 'ImportPath', FilePath, StrDefaultImportPath, IniFile);
    FExportPath := ReadStringWithDefaultPath(StrLocalIniSection, 'ExportPath', FilePath, StrDefaultExportPath, IniFile);

    FPartIncrementClick := IniFile.ReadInteger(StrExternalIniSection, 'PartIncrementClick', 1);
    FPartIncrementShiftClick := IniFile.ReadInteger(StrExternalIniSection, 'PartIncrementShiftClick', 10);
    FPartIncrementCtrlClick := IniFile.ReadInteger(StrExternalIniSection, 'PartIncrementCtrlClick', 50);
    FPartIncrementCtrlShiftClick := IniFile.ReadInteger(StrExternalIniSection, 'PartIncrementCtrlShiftClick', 100);

    // Frame size/open states
    FVisualStyle := IniFile.ReadString(StrApplicationIniSection, 'VisualStyle', 'Windows');
    FReOpenWindowsAfterRestart := IniFile.ReadBool(StrWindowsIniSection, 'ReOpenWindowsAfterRestart', False);

    FSearchListDoubleClickAction := TDoubleClickAction(IniFile.ReadInteger(StrSearchWindowIniSection, 'SearchListDoubleClickAction', Integer(caVIEW)));
    FSearchLimit := IniFile.ReadInteger(StrSearchWindowIniSection, 'SearchLimit', 4);
    FWSearchGridSize := IniFile.ReadInteger(StrSearchWindowIniSection, 'WSearchGridSize', 64);
    FWSearchShowNumber := IniFile.ReadBool(StrSetPartsWindowIniSection, 'WSearchShowNumber', True);
    FWSearchShowYear := IniFile.ReadBool(StrSetPartsWindowIniSection, 'WSearchShowYear', True);
    FWSearchShowSetQuantity := IniFile.ReadBool(StrSetPartsWindowIniSection, 'WSearchShowSetQuantity', True);
    FWSearchShowCollectionID := IniFile.ReadBool(StrSetPartsWindowIniSection, 'WSearchShowCollectionID', True);
    FWSearchShowPartCount := IniFile.ReadBool(StrSetPartsWindowIniSection, 'WSearchShowPartCount', True);
    FWSearchShowPartOrMinifigNumber := IniFile.ReadBool(StrSetPartsWindowIniSection, 'WSearchShowPartOrMinifigNumber', True);
    FWSearchSortAscending := IniFile.ReadBool(StrSetPartsWindowIniSection, 'WSearchSortAscending', False);
    FWSearchSortByTheme := IniFile.ReadBool(StrSetPartsWindowIniSection, 'WSearchSortByTheme', False);
    FWSearchSortByNumber := IniFile.ReadBool(StrSetPartsWindowIniSection, 'WSearchSortByNumber', False);
    FWSearchSortByPartCount := IniFile.ReadBool(StrSetPartsWindowIniSection, 'WSearchSortByPartCount', False);
    FWSearchSortByName := IniFile.ReadBool(StrSetPartsWindowIniSection, 'WSearchSortByName', False);
    FWSearchSortByYear := IniFile.ReadBool(StrSetPartsWindowIniSection, 'WSearchSortByYear', False);
    FWSearchOwnCollection := IniFile.ReadBool(StrSetPartsWindowIniSection, 'WSearchOwnCollection', False);
    FWSearchStyle := IniFile.ReadInteger(StrSearchWindowIniSection, 'WSearchStyle', Integer(cSEARCHPREFIX));
    FWSearchWhat := IniFile.ReadInteger(StrSearchWindowIniSection, 'WSearchWhat', Integer(cSEARCHTYPESET));
    FWSearchBy := IniFile.ReadInteger(StrSearchWindowIniSection, 'WSearchBy', Integer(cNUMBER));

    FCollectionListDoubleClickAction := TDoubleClickAction(IniFile.ReadInteger(StrCollectionWindowIniSection, 'CollectionListDoubleClickAction', Integer(caVIEW)));
    FSetListDoubleClickAction := TDoubleClickAction(IniFile.ReadInteger(StrSetlistWindowIniSection, 'SetListDoubleClickAction', Integer(caVIEW)));
    FPartsListDoubleClickAction := TDoubleClickAction(IniFile.ReadInteger(StrSetlistWindowIniSection, 'PartListDoubleClickAction', Integer(caVIEWEXTERNAL)));

    // Window positions
    FFrmSearch.Load(IniFile, StrSearchWindowIniSection, 'FrmSearch');
    FFrmSetListCollection.Load(IniFile, StrCollectionWindowIniSection, 'FrmSetListCollection');
    FFrmSetList.Load(IniFile, StrSetListWindowIniSection, 'FrmSetList');
    FFrmParts.Load(IniFile, StrSetPartsWindowIniSection, 'FrmParts');
    FFrmSet.Load(IniFile, StrSetWindowIniSection, 'FrmSet');

    // View parts window filters
    FWPartsShowPartCount := IniFile.ReadBool(StrSetPartsWindowIniSection, 'WPartsShowPartCount', True);
    FWPartsShowPartnum := IniFile.ReadBool(StrSetPartsWindowIniSection, 'WPartsShowPartnum', True);
    FWPartsIncludeNonSpareParts := IniFile.ReadBool(StrSetPartsWindowIniSection, 'WPartsIncludeNonSpareParts', True);
    FWPartsIncludeSpareParts := IniFile.ReadBool(StrSetPartsWindowIniSection, 'WPartsIncludeSpareParts', True);
    FWPartsSortByCategory := IniFile.ReadBool(StrSetPartsWindowIniSection, 'WPartsSortByCategory', False);
    FWPartsSortByColor := IniFile.ReadBool(StrSetPartsWindowIniSection, 'WPartsSortByColor', True);
    FWPartsSortByHue := IniFile.ReadBool(StrSetPartsWindowIniSection, 'WPartsSortByHue', False);
    FWPartsSortByPart := IniFile.ReadBool(StrSetPartsWindowIniSection, 'WPartsSortByPart', False);
    FWPartsSortByQuantity := IniFile.ReadBool(StrSetPartsWindowIniSection, 'WPartsSortByQuantity', False);
    FWPartsSortAscending := IniFile.ReadBool(StrSetPartsWindowIniSection, 'WPartsSortAscending', False);
  finally
    IniFile.Free;
  end;
end;

end.
