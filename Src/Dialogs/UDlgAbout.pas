unit UDlgAbout;

interface

uses Winapi.Windows, System.Classes, Vcl.Graphics, Vcl.Forms, Vcl.Controls,
  Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls;

type
  TDlgAbout = class(TForm)
    Panel1: TPanel;
    BtnOK: TButton;
    ProgramIcon: TImage;
    LblProductName: TLabel;
    LblVersion: TLabel;
    LblCopyright: TLabel;
    LblComments: TLabel;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DlgAbout: TDlgAbout;

implementation

uses
  SysUtils, UStrings;

{$R *.dfm}

procedure TDlgAbout.FormCreate(Sender: TObject);

  function FGetAppVersion: string;
  var
    VerValueSize: DWORD;
    VerInfo: Pointer;
    VerValue: PVSFixedFileInfo;
    Dummy: DWORD;
  begin
    // Get size of version information
    var VerInfoSize := GetFileVersionInfoSize(PChar(ParamStr(0)), Dummy);
    if VerInfoSize = 0 then
      Exit('');

    // Allocate memory for version information
    GetMem(VerInfo, VerInfoSize);
    try
      // Retrieve version information
      if GetFileVersionInfo(PChar(ParamStr(0)), 0, VerInfoSize, VerInfo) then begin
        // Query version information
        if VerQueryValue(VerInfo, '\', Pointer(VerValue), VerValueSize) then begin
          // Format version information
          Result := IntToStr(VerValue.dwFileVersionMS shr 16) + '.' +
                    IntToStr(VerValue.dwFileVersionMS and $FFFF) + '.' +
                    IntToStr(VerValue.dwFileVersionLS shr 16) + '.' +
                    IntToStr(VerValue.dwFileVersionLS and $FFFF);
        end;
      end;
    finally
      FreeMem(VerInfo);
    end;
  end;

begin
  LblVersion.Caption := LblVersion.Caption + ': ' + FGetAppVersion;
  LblProductName.Caption := StrAboutProductName;
  LblCopyright.Caption := StrAboutCopyright;
  LblComments.Caption := StrAboutComment;
end;

end.
 
