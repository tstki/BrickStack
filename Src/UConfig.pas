unit UConfig;

interface

uses
  System.Classes, Forms, IniFiles;

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
    FDefaultViewSetOpenType: Integer;
    FDefaultViewPartOpenType: Integer;
    FDbasePath: String;
    FImportPath: String;
    FExportPath: String;
    FVisualStyle: String;
    FSearchListDoubleClickAction: Integer;
    FCollectionListDoubleClickAction: Integer;
    FSetListDoubleClickAction: Integer;
    FPartsListDoubleClickAction: Integer;

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
    procedure Save(Section: Integer);
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
    property DefaultViewSetOpenType: Integer read FDefaultViewSetOpenType write FDefaultViewSetOpenType;
    property DefaultViewPartOpenType: Integer read FDefaultViewPartOpenType write FDefaultViewPartOpenType;
    property DbasePath: String read FDbasePath write FDbasePath;
    property ImportPath: String read FImportPath write FImportPath;
    property ExportPath: String read FExportPath write FExportPath;
    property VisualStyle: String read FVisualStyle write FVisualStyle;
    property SearchListDoubleClickAction: Integer read FSearchListDoubleClickAction write FSearchListDoubleClickAction;
    property CollectionListDoubleClickAction: Integer read FCollectionListDoubleClickAction write FCollectionListDoubleClickAction;
    property SetListDoubleClickAction: Integer read FSetListDoubleClickAction write FSetListDoubleClickAction;
    property PartsListDoubleClickAction: Integer read FPartsListDoubleClickAction write FPartsListDoubleClickAction;

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

const
  // Open Types for links to external sites:
  cOTNONE = 0;        // None selected yet
  cOTREBRICKABLE = 1; // Parts and sets
  cOTBRICKLINK = 2;   //
  cOTBRICKOWL = 3;    //
  cOTBRICKSET = 4;    // Sets
  cOTLDRAW = 5;       // Parts
  cOTCUSTOM = 6;      // Parts and sets (probably)

  // Doubleclick action windows
  cACTIONSEARCH = 0;
  cACTIONCOLLECTION = 1;
  cACTIONSETLIST = 2;
  cACTIONPARTS = 3; // Only view parts, not edit parts.

  caVIEW = 0;
  caVIEWEXTERNAL = 1;
  caEDITDETAILS = 2;
  caVIEWPARTS = 3;
  caEDITPARTS = 4;

  //View External types:
  cTYPESET = 0;
  cTYPEPART = 1;
  //cTYPEMINIFIG = 2; //Not used yet

  //Config sections - used for saving specific sections instead of "everything"
  csALL = 0;
  csCONFIGDIALOG = 1;
  csWINDOWPOSITIONS = 2;
  csPARTSWINDOWFILTERS = 3;

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

procedure TConfig.Save(Section: Integer);
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
      IniFile.WriteInteger(StrExternalIniSection, 'DefaultViewSetOpenType', FDefaultViewSetOpenType);
      IniFile.WriteInteger(StrExternalIniSection, 'DefaultViewPartOpenType', FDefaultViewPartOpenType);

      IniFile.WriteString(StrLocalIniSection, 'LocalImageCachePath', FLocalImageCachePath);
      IniFile.WriteString(StrLocalIniSection, 'LocalLogsPath', FLocalLogsPath);
      IniFile.WriteString(StrLocalIniSection, 'DbasePath', FDbasePath);
      IniFile.WriteString(StrLocalIniSection, 'ImportPath', FImportPath);
      IniFile.WriteString(StrLocalIniSection, 'ExportPath', FExportPath);

      IniFile.WriteString(StrApplicationIniSection, 'VisualStyle', FVisualStyle);
      IniFile.WriteBool(StrWindowsIniSection, 'ReOpenWindowsAfterRestart', FReOpenWindowsAfterRestart);

      IniFile.WriteInteger(StrSearchWindowIniSection, 'SearchListDoubleClickAction', FSearchListDoubleClickAction);
      IniFile.WriteInteger(StrSearchWindowIniSection, 'SearchLimit', FSearchLimit);

      IniFile.WriteInteger(StrCollectionWindowIniSection, 'CollectionListDoubleClickAction', FCollectionListDoubleClickAction);
      IniFile.WriteInteger(StrSetlistWindowIniSection, 'SetListDoubleClickAction', FSetListDoubleClickAction);
      IniFile.WriteInteger(StrSetPartsWindowIniSection, 'PartsListDoubleClickAction', FPartsListDoubleClickAction);

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
    FDefaultViewSetOpenType := IniFile.ReadInteger(StrExternalIniSection, 'DefaultViewSetOpenType', cOTNONE);
    FDefaultViewPartOpenType := IniFile.ReadInteger(StrExternalIniSection, 'DefaultViewPartOpenType', cOTNONE);

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

    FSearchListDoubleClickAction := IniFile.ReadInteger(StrSearchWindowIniSection, 'SearchListDoubleClickAction', caVIEW);
    FSearchLimit := IniFile.ReadInteger(StrSearchWindowIniSection, 'SearchLimit', 4);

    FCollectionListDoubleClickAction := IniFile.ReadInteger(StrCollectionWindowIniSection, 'CollectionListDoubleClickAction', caVIEW);
    FSetListDoubleClickAction := IniFile.ReadInteger(StrSetlistWindowIniSection, 'SetListDoubleClickAction', caVIEW);
    FPartsListDoubleClickAction := IniFile.ReadInteger(StrSetlistWindowIniSection, 'PartListDoubleClickAction', caVIEWEXTERNAL);

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
