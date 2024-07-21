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

    // Window states (move to separate class object later) - no need to save this every time after all
    FReOpenWindowsAfterRestart: Boolean;
{    FFrmSetListCollectionWasOpen: Boolean;
    FFrmSetWasOpen: String;
    FFrmSetListWasOpen: Integer;
    FFrmPartsWasOpen: String;
    FFrmSearchWasOpen: Boolean; }

    FFrmSetListCollection: TClientFormStorage;
    FFrmSetList: TClientFormStorage;
    FFrmSet: TClientFormStorage;
    FFrmParts: TClientFormStorage;
    FFrmSearch: TClientFormStorage;

  public
    { Public declarations }
    constructor Create;
    destructor Destroy; override;
    procedure Save;
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

  //View External types:
  cTYPESET = 0;
  cTYPEPART = 1;
  //cTYPEMINIFIG = 2; //Not used yet

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

procedure TConfig.Save;
begin
  var FilePath := ExtractFilePath(ParamStr(0));
  var IniFile := TIniFile.Create(FilePath + StrIniFileName);
  try
    IniFile.WriteString(StrRebrickableIniSection, 'RebrickableAPIKey', FRebrickableAPIKey);
    IniFile.WriteString(StrRebrickableIniSection, 'RebrickableBaseUrl', FRebrickableBaseUrl);
    IniFile.WriteString(StrRebrickableIniSection, 'AuthenticationToken', IfThen(FRememberAuthenticationToken, FAuthenticationToken, ''));
    IniFile.WriteBool(StrRebrickableIniSection, 'RememberAuthenticationToken', FRememberAuthenticationToken);

    IniFile.WriteString(StrRebrickableIniSection, 'ViewRebrickableUrl', FViewRebrickableUrl);
    IniFile.WriteString(StrRebrickableIniSection, 'ViewBrickLinkUrl', FViewBrickLinkUrl);
    IniFile.WriteString(StrRebrickableIniSection, 'ViewBrickOwlUrl', FViewBrickOwlUrl);
    IniFile.WriteString(StrRebrickableIniSection, 'ViewBrickSetUrl', FViewBrickSetUrl);
    IniFile.WriteString(StrRebrickableIniSection, 'ViewLDrawUrl', FViewLDrawUrl);

    IniFile.WriteInteger(StrRebrickableIniSection, 'DefaultViewSetOpenType', FDefaultViewSetOpenType);
    IniFile.WriteInteger(StrRebrickableIniSection, 'DefaultViewPartOpenType', FDefaultViewPartOpenType);

    IniFile.WriteString(StrRebrickableIniSection, 'LocalImageCachePath', FLocalImageCachePath);
    IniFile.WriteString(StrRebrickableIniSection, 'LocalLogsPath', FLocalLogsPath);
    IniFile.WriteString(StrRebrickableIniSection, 'DbasePath', FDbasePath);
    IniFile.WriteString(StrRebrickableIniSection, 'ImportPath', FImportPath);
    IniFile.WriteString(StrRebrickableIniSection, 'ExportPath', FExportPath);

    // Frame size/open states
    IniFile.WriteBool(StrRebrickableIniSection, 'ReOpenWindowsAfterRestart', FReOpenWindowsAfterRestart);
    FFrmSetListCollection.Save(IniFile, StrRebrickableIniSection, 'FrmSetListCollection');
    FFrmSetList.Save(IniFile, StrRebrickableIniSection, 'FrmSetList');
    FFrmSet.Save(IniFile, StrRebrickableIniSection, 'FrmSet');
    FFrmParts.Save(IniFile, StrRebrickableIniSection, 'FrmParts');
    FFrmSearch.Save(IniFile, StrRebrickableIniSection, 'FrmSearch');
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
    FRebrickableAPIKey := IniFile.ReadString(StrRebrickableIniSection, 'RebrickableAPIKey', '');
    FRebrickableBaseUrl := IniFile.ReadString(StrRebrickableIniSection, 'RebrickableBaseUrl', 'https://rebrickable.com/');
    FAuthenticationToken := IniFile.ReadString(StrRebrickableIniSection, 'AuthenticationToken', '');
    FRememberAuthenticationToken := IniFile.ReadBool(StrRebrickableIniSection, 'RememberAuthenticationToken', False);

    FViewRebrickableUrl := IniFile.ReadString(StrRebrickableIniSection, 'ViewRebrickableUrl', 'https://rebrickable.com/');
    FViewBrickLinkUrl := IniFile.ReadString(StrRebrickableIniSection, 'ViewBrickLinkUrl', 'https://www.bricklink.com/');
    FViewBrickOwlUrl := IniFile.ReadString(StrRebrickableIniSection, 'ViewBrickOwlUrl', 'https://www.brickowl.com/');
    FViewBrickSetUrl := IniFile.ReadString(StrRebrickableIniSection, 'ViewBrickSetUrl', 'https://www.brickset.com/');
    FViewLDrawUrl := IniFile.ReadString(StrRebrickableIniSection, 'ViewLDrawUrl', 'https://library.ldraw.org/');

    FDefaultViewSetOpenType := IniFile.ReadInteger(StrRebrickableIniSection, 'DefaultViewSetOpenType', cOTNONE);
    FDefaultViewPartOpenType := IniFile.ReadInteger(StrRebrickableIniSection, 'DefaultViewPartOpenType', cOTNONE);

    FLocalImageCachePath := ReadStringWithDefaultPath(StrRebrickableIniSection, 'LocalImageCachePath', FilePath, StrDefaultCachePath, IniFile);
    FLocalLogsPath := ReadStringWithDefaultPath(StrRebrickableIniSection, 'LocalLogsPath', FilePath, StrDefaultLogPath, IniFile);
    FDbasePath := ReadStringWithDefaultPath(StrRebrickableIniSection, 'DbasePath', FilePath, StrDefaultdDbasePath, IniFile);
    FImportPath := ReadStringWithDefaultPath(StrRebrickableIniSection, 'ImportPath', FilePath, StrDefaultImportPath, IniFile);
    FExportPath := ReadStringWithDefaultPath(StrRebrickableIniSection, 'ExportPath', FilePath, StrDefaultExportPath, IniFile);

    // Frame size/open states
    FReOpenWindowsAfterRestart := IniFile.ReadBool(StrRebrickableIniSection, 'ReOpenWindowsAfterRestart', False);
    FFrmSetListCollection.Load(IniFile, StrRebrickableIniSection, 'FrmSetListCollection');
    FFrmSetList.Load(IniFile, StrRebrickableIniSection, 'FrmSetList');
    FFrmSet.Load(IniFile, StrRebrickableIniSection, 'FrmSet');
    FFrmParts.Load(IniFile, StrRebrickableIniSection, 'FrmParts');
    FFrmSearch.Load(IniFile, StrRebrickableIniSection, 'FrmSearch');
  finally
    IniFile.Free;
  end;
end;

end.
