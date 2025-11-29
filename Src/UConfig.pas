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
    FSearchAction: Integer;
    FSetListsAction: Integer;
    FSetsAction: Integer;

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
    property SearchAction: Integer read FSearchAction write FSearchAction;
    property SetListsAction: Integer read FSetListsAction write FSetListsAction;
    property SetsAction: Integer read FSetsAction write FSetsAction;

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
  cOTREBRICKABLE = 1; // Parts and sets            1
  cOTBRICKLINK = 2;   //
  cOTBRICKOWL = 3;    //
  cOTBRICKSET = 4;    // Sets
  cOTLDRAW = 5;       // Parts
  cOTCUSTOM = 6;      // Parts and sets (probably)

  // Doubleclick action windows
  cACTIONSEARCH = 0;
  cACTIONSETLISTS = 1;
  cACTIONSETS = 2;
  //cACTIONPARTS = 3; // Only view parts, not edit parts.

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

      IniFile.WriteString(StrWindowsIniSection, 'VisualStyle', FVisualStyle);

      IniFile.WriteInteger(StrActionIniSection, 'SearchAction', FSearchAction);
      IniFile.WriteInteger(StrActionIniSection, 'SetListsAction', FSetListsAction);
      IniFile.WriteInteger(StrActionIniSection, 'SetsAction', FSetsAction);
    end;

    // Frame size/open states
    if Section in [csALL, csWINDOWPOSITIONS] then begin
      IniFile.WriteBool(StrBrickStackIniSection, 'ReOpenWindowsAfterRestart', FReOpenWindowsAfterRestart);

      FFrmSetListCollection.Save(IniFile, StrBrickStackIniSection, 'FrmSetListCollection');
      FFrmSetList.Save(IniFile, StrBrickStackIniSection, 'FrmSetList');
      FFrmSet.Save(IniFile, StrBrickStackIniSection, 'FrmSet');
      FFrmParts.Save(IniFile, StrBrickStackIniSection, 'FrmParts');
      FFrmSearch.Save(IniFile, StrBrickStackIniSection, 'FrmSearch');
    end;

    // Parts window filters and sorting
    if Section in [csALL, csPARTSWINDOWFILTERS] then begin
      IniFile.WriteBool(StrViewSetPartsWindowIniSection, 'WPartsShowPartCount', FWPartsShowPartCount);
      IniFile.WriteBool(StrViewSetPartsWindowIniSection, 'WPartsShowPartnum', FWPartsShowPartnum);
      IniFile.WriteBool(StrViewSetPartsWindowIniSection, 'WPartsIncludeNonSpareParts', FWPartsIncludeNonSpareParts);
      IniFile.WriteBool(StrViewSetPartsWindowIniSection, 'WPartsIncludeSpareParts', FWPartsIncludeSpareParts);
      IniFile.WriteBool(StrViewSetPartsWindowIniSection, 'WPartsSortByCategory', FWPartsSortByCategory);
      IniFile.WriteBool(StrViewSetPartsWindowIniSection, 'WPartsSortByColor', FWPartsSortByColor);
      IniFile.WriteBool(StrViewSetPartsWindowIniSection, 'WPartsSortByHue', FWPartsSortByHue);
      IniFile.WriteBool(StrViewSetPartsWindowIniSection, 'WPartsSortByPart', FWPartsSortByPart);
      IniFile.WriteBool(StrViewSetPartsWindowIniSection, 'WPartsSortByQuantity', FWPartsSortByQuantity);
      IniFile.WriteBool(StrViewSetPartsWindowIniSection, 'WPartsSortAscending', FWPartsSortAscending);
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

    FVisualStyle := IniFile.ReadString(StrWindowsIniSection, 'VisualStyle', 'Windows');

    FSearchAction := IniFile.ReadInteger(StrActionIniSection, 'SearchAction', caVIEW);
    FSetListsAction := IniFile.ReadInteger(StrActionIniSection, 'SetListsAction', caVIEW);
    FSetsAction := IniFile.ReadInteger(StrActionIniSection, 'SetsAction', caVIEW);

    // Frame size/open states
    FReOpenWindowsAfterRestart := IniFile.ReadBool(StrBrickStackIniSection, 'ReOpenWindowsAfterRestart', False);
    FFrmSetListCollection.Load(IniFile, StrBrickStackIniSection, 'FrmSetListCollection');
    FFrmSetList.Load(IniFile, StrBrickStackIniSection, 'FrmSetList');
    FFrmSet.Load(IniFile, StrBrickStackIniSection, 'FrmSet');
    FFrmParts.Load(IniFile, StrBrickStackIniSection, 'FrmParts');
    FFrmSearch.Load(IniFile, StrBrickStackIniSection, 'FrmSearch');

    // View parts window filters
    FWPartsShowPartCount := IniFile.ReadBool(StrViewSetPartsWindowIniSection, 'WPartsShowPartCount', True);
    FWPartsShowPartnum := IniFile.ReadBool(StrViewSetPartsWindowIniSection, 'WPartsShowPartnum', True);
    FWPartsIncludeNonSpareParts := IniFile.ReadBool(StrViewSetPartsWindowIniSection, 'WPartsIncludeNonSpareParts', True);
    FWPartsIncludeSpareParts := IniFile.ReadBool(StrViewSetPartsWindowIniSection, 'WPartsIncludeSpareParts', True);
    FWPartsSortByCategory := IniFile.ReadBool(StrViewSetPartsWindowIniSection, 'WPartsSortByCategory', False);
    FWPartsSortByColor := IniFile.ReadBool(StrViewSetPartsWindowIniSection, 'WPartsSortByColor', True);
    FWPartsSortByHue := IniFile.ReadBool(StrViewSetPartsWindowIniSection, 'WPartsSortByHue', False);
    FWPartsSortByPart := IniFile.ReadBool(StrViewSetPartsWindowIniSection, 'WPartsSortByPart', False);
    FWPartsSortByQuantity := IniFile.ReadBool(StrViewSetPartsWindowIniSection, 'WPartsSortByQuantity', False);
    FWPartsSortAscending := IniFile.ReadBool(StrViewSetPartsWindowIniSection, 'WPartsSortAscending', False);
  finally
    IniFile.Free;
  end;
end;

end.
