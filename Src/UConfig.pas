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
    property DefaultViewSetOpenType: Integer read FDefaultViewSetOpenType write FDefaultViewSetOpenType;
    property DefaultViewPartOpenType: Integer read FDefaultViewPartOpenType write FDefaultViewPartOpenType;
  end;

const
  // Open Types for links to external sites:
  cOTNONE = 0;        // None selected yet
  cOTREBRICKABLE = 1; // Parts and sets
  cOTBRICKLINK = 1;   //
  cOTBRICKOWL = 2;    //
  cOTBRICKSET = 3;    // Sets
  cOTLDRAW = 4;       // Parts
  cOTCUSTOM = 5;      // Parts and sets (probably)

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
    IniFile.WriteInteger(StrRebrickableIniSection, 'DefaultViewSetOpenType', FDefaultViewSetOpenType);
    IniFile.WriteInteger(StrRebrickableIniSection, 'FDefaultViewPartOpenType', FDefaultViewPartOpenType);
  finally
    IniFile.Free;
  end;
end;

end.
