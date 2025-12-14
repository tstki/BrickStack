program BrickStack;

uses
  Forms,
  UFrmMain in 'Src\Frames\UFrmMain.pas' {UFrmMain},
  UFrmChild in 'Src\Frames\UFrmChild.pas' {MDIChild},
  UFrmSetListCollection in 'Src\Frames\UFrmSetListCollection.pas' {FrmSetListCollection},
  UFrmSetList in 'Src\Frames\UFrmSetList.pas' {FrmSetList},
  UFrmSearch in 'Src\Frames\UFrmSearch.pas' {FrmSearch},
  UFrmSet in 'Src\Frames\UFrmSet.pas' {FrmSet},
  UFrmParts in 'Src\Frames\UFrmParts.pas' {FrmParts},
  UDlgLogin in 'Src\Dialogs\UDlgLogin.pas' {DlgLogin},
  UDlgImport in 'Src\Dialogs\UDlgImport.pas' {DlgImport},
  UDlgAbout in 'Src\Dialogs\UDlgAbout.pas' {DlgAbout},
  UDlgConfig in 'Src\Dialogs\UDlgConfig.pas' {DlgConfig},
  UDlgSetList in 'Src\Dialogs\UDlgSetList.pas' {DlgSetList},
  UDlgHelp in 'Src\Dialogs\UDlgHelp.pas' {DlgHelp},
  UDlgTest in 'Src\Dialogs\UDlgTest.pas' {DlgTest},
  UDlgViewExternal in 'Src\Dialogs\UDlgViewExternal.pas' {DlgViewExternal},
  UDlgAddToSetList in 'Src\Dialogs\UDlgAddToSetList.pas' {DlgAddToSetList},
  UDlgExport in 'Src\Dialogs\UDlgExport.pas' {DlgExport},
  UDlgUpdateDatabase in 'Src\Dialogs\UDlgUpdateDatabase.pas' {DlgUpdateDatabase},
  USetList in 'Src\Data\USetList.pas',
  USet in 'Src\Data\USet.pas',
  UPart in 'Src\Data\UPart.pas',
  UStrings in 'Src\UStrings.pas',
  UConfig in 'Src\UConfig.pas',
  UImageCache in 'Src\UImageCache.pas',
  UPostMessage in 'Src\UPostMessage.pas',
  URebrickableJson in 'Src\URebrickableJson.pas',
  UBrickLinkXMLIntf in 'Src\UBrickLinkXMLIntf.pas',
  USqLiteConnection in 'Src\USqLiteConnection.pas',
  USqlThread in 'Src\USqlThread.pas',
  UGetImageThread in 'Src\UGetImageThread.pas',
  UDownloadThread in 'Src\UDownloadThread.pas',
  Vcl.Themes,
  Vcl.Styles,
  UBSSQL in 'Src\Scripts\UBSSQL.pas',
  UDragData in 'Src\UDragData.pas',
  USearchResult in 'Src\Data\USearchResult.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.MainFormOnTaskBar := True;
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
