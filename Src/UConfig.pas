unit UConfig;

interface

uses
  System.Classes;

type
  TConfig = class(TObject)
  private
    { Private declarations }
    FRebrickableAPIKey: String;
    FRebrickableBaseUrl: String;
    FAuthenticationToken: String;           // Only saved if,
    FRememberAuthenticationToken: Boolean;  // is true
    FLocalImageCachePath: String;
    FViewRebrickableUrl: String;
    FViewBrickLinkUrl: String;
    FViewBrickOwlUrl: String;
    FViewBrickSetUrl: String;
    FViewLDrawUrl: String;
    FDefaultViewSetOpenType: Integer;
    FDefaultViewPartOpenType: Integer;
  public
    { Public declarations }
    procedure Load;
    procedure Save;
    property RebrickableAPIKey: String read FRebrickableAPIKey write FRebrickableAPIKey;
    property RebrickableBaseUrl: String read FRebrickableBaseUrl write FRebrickableBaseUrl;
    property AuthenticationToken: String read FAuthenticationToken write FAuthenticationToken;
    property RememberAuthenticationToken: Boolean read FRememberAuthenticationToken write FRememberAuthenticationToken;
    property LocalImageCachePath: String read FLocalImageCachePath write FLocalImageCachePath;
    property ViewRebrickableUrl: String read FViewRebrickableUrl write FViewRebrickableUrl;
    property ViewBrickLinkUrl: String read FViewBrickLinkUrl write FViewBrickLinkUrl;
    property ViewBrickOwlUrl: String read FViewBrickOwlUrl write FViewBrickOwlUrl;
    property ViewBrickSetUrl: String read FViewBrickSetUrl write FViewBrickSetUrl;
    property ViewLDrawUrl: String read FViewLDrawUrl write FViewLDrawUrl;
    property DefaultViewSetOpenType: Integer read FDefaultViewSetOpenType write FDefaultViewSetOpenType;
    property DefaultViewPartOpenType: Integer read FDefaultViewPartOpenType write FDefaultViewPartOpenType;
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
  StrUtils, SysUtils, IniFiles,
  UStrings;

procedure TConfig.Load;
begin
  var FilePath := ExtractFilePath(ParamStr(0));
  var IniFile := TIniFile.Create(FilePath + StrIniFileName);
  try
    FRebrickableAPIKey := IniFile.ReadString(StrRebrickableIniSection, 'RebrickableAPIKey', '');
    FRebrickableBaseUrl := IniFile.ReadString(StrRebrickableIniSection, 'RebrickableBaseUrl', 'https://rebrickable.com/');
    FAuthenticationToken := IniFile.ReadString(StrRebrickableIniSection, 'AuthenticationToken', '');
    FRememberAuthenticationToken := IniFile.ReadBool(StrRebrickableIniSection, 'RememberAuthenticationToken', False);
    FLocalImageCachePath := IniFile.ReadString(StrRebrickableIniSection, 'LocalImageCachePath', '');
    if FLocalImageCachePath = '' then
      FLocalImageCachePath := FilePath + StrDefaultCachePath;

    FViewRebrickableUrl := IniFile.ReadString(StrRebrickableIniSection, 'ViewRebrickableUrl', 'https://rebrickable.com/');
    FViewBrickLinkUrl := IniFile.ReadString(StrRebrickableIniSection, 'ViewBrickLinkUrl', 'https://www.bricklink.com/');
    FViewBrickOwlUrl := IniFile.ReadString(StrRebrickableIniSection, 'ViewBrickOwlUrl', 'https://www.brickowl.com/');
    FViewBrickSetUrl := IniFile.ReadString(StrRebrickableIniSection, 'ViewBrickSetUrl', 'https://www.brickset.com/');
    FViewLDrawUrl := IniFile.ReadString(StrRebrickableIniSection, 'ViewLDrawUrl', 'https://library.ldraw.org/');

    FDefaultViewSetOpenType := IniFile.ReadInteger(StrRebrickableIniSection, 'DefaultViewSetOpenType', cOTNONE);
    FDefaultViewPartOpenType := IniFile.ReadInteger(StrRebrickableIniSection, 'DefaultViewPartOpenType', cOTNONE);
  finally
    IniFile.Free;
  end;
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
    IniFile.WriteString(StrRebrickableIniSection, 'LocalImageCachePath', FLocalImageCachePath);

    IniFile.WriteString(StrRebrickableIniSection, 'ViewRebrickableUrl', FViewRebrickableUrl);
    IniFile.WriteString(StrRebrickableIniSection, 'ViewBrickLinkUrl', FViewBrickLinkUrl);
    IniFile.WriteString(StrRebrickableIniSection, 'ViewBrickOwlUrl', FViewBrickOwlUrl);
    IniFile.WriteString(StrRebrickableIniSection, 'ViewBrickSetUrl', FViewBrickSetUrl);
    IniFile.WriteString(StrRebrickableIniSection, 'ViewLDrawUrl', FViewLDrawUrl);

    IniFile.WriteInteger(StrRebrickableIniSection, 'DefaultViewSetOpenType', FDefaultViewSetOpenType);
    IniFile.WriteInteger(StrRebrickableIniSection, 'DefaultViewPartOpenType', FDefaultViewPartOpenType);
  finally
    IniFile.Free;
  end;
end;

end.
