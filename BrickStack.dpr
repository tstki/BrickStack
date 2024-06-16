program BrickStack;

uses
  Forms,
  UFrmMain in 'Src\Frames\UFrmMain.pas' {UFrmMain},
  UFrmChild in 'Src\Frames\UFrmChild.pas' {MDIChild},
  UFrmSetListCollection in 'Src\Frames\UFrmSetListCollection.pas' {FrmSetListCollection},
  UFrmSetList in 'Src\Frames\UFrmSetList.pas' {FrmSetList},
  UFrmSearch in 'Src\Frames\UFrmSearch.pas' {FrmSearch},
  UFrmSet in 'Src\Frames\UFrmSet.pas' {FrmSet},
  UDlgLogin in 'Src\Dialogs\UDlgLogin.pas' {DlgLogin},
  UDlgImport in 'Src\Dialogs\UDlgImport.pas' {DlgImport},
  UDlgAbout in 'Src\Dialogs\UDlgAbout.pas' {DlgAbout},
  UDlgConfig in 'Src\Dialogs\UDlgConfig.pas' {DlgConfig},
  UDlgSetList in 'Src\Dialogs\UDlgSetList.pas' {DlgSetList},
  UDlgHelp in 'Src\Dialogs\UDlgHelp.pas' {DlgHelp},
  UDlgTest in 'Src\Dialogs\UDlgTest.pas' {DlgTest},
  UDlgViewExternal in 'Src\Dialogs\UDlgViewExternal.pas' {DlgViewExternal},
  URebrickableJson in 'Src\URebrickableJson.pas',
  UStrings in 'Src\UStrings.pas',
  UConfig in 'Src\UConfig.pas',
  USetList in 'Src\USetList.pas',
  USet in 'Src\USet.pas',
  UImageCache in 'Src\UImageCache.pas',
  UPostMessage in 'Src\UPostMessage.pas',
  USqLiteConnection in 'Src\USqLiteConnection.pas',
  UGetImageThread in 'Src\UGetImageThread.pas',
  USqlThread in 'Src\USqlThread.pas',
  UDlgAddToSetList in 'Src\Dialogs\UDlgAddToSetList.pas' {DlgAddToSetList};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
