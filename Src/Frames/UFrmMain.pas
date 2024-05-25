unit UFrmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, Vcl.Graphics, Vcl.Forms,
  Vcl.Controls, Vcl.Menus, Vcl.StdCtrls, Vcl.Dialogs, Vcl.Buttons,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.StdActns, Vcl.ActnList, Vcl.ToolWin, Vcl.ImgList,
  System.SysUtils, System.Classes, System.ImageList, System.Actions,
  IdHttp,
  UConfig, UImageCache, UPostMessage;

type
  TFrmMain = class(TForm)
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    FileNewItem: TMenuItem;
    FileOpenItem: TMenuItem;
    FileCloseItem: TMenuItem;
    Window1: TMenuItem;
    Help1: TMenuItem;
    N1: TMenuItem;
    FileExitItem: TMenuItem;
    WindowCascadeItem: TMenuItem;
    WindowTileItem: TMenuItem;
    WindowArrangeItem: TMenuItem;
    HelpAboutItem: TMenuItem;
    OpenDialog: TOpenDialog;
    FileSaveItem: TMenuItem;
    FileSaveAsItem: TMenuItem;
    Edit1: TMenuItem;
    CutItem: TMenuItem;
    CopyItem: TMenuItem;
    PasteItem: TMenuItem;
    WindowMinimizeItem: TMenuItem;
    StatusBar: TStatusBar;
    ActionList1: TActionList;
    EditCut1: TEditCut;
    EditCopy1: TEditCopy;
    EditPaste1: TEditPaste;
    FileNew1: TAction;
    FileSave1: TAction;
    FileExit1: TAction;
    FileOpen1: TAction;
    FileSaveAs1: TAction;
    WindowCascade1: TWindowCascade;
    WindowTileHorizontal1: TWindowTileHorizontal;
    WindowArrangeAll1: TWindowArrange;
    WindowMinimizeAll1: TWindowMinimizeAll;
    ActAbout: TAction;
    FileClose1: TWindowClose;
    WindowTileVertical1: TWindowTileVertical;
    WindowTileItem2: TMenuItem;
    ToolBar2: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton9: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    ToolButton10: TToolButton;
    ToolButton11: TToolButton;
    ImageList16: TImageList;
    PrintDialog1: TPrintDialog;
    ActConfig1: TMenuItem;
    ActConfig: TAction;
    N2: TMenuItem;
    ActImport: TAction;
    ActExport: TAction;
    Import1: TMenuItem;
    Export1: TMenuItem;
    N3: TMenuItem;
    ActCollection: TAction;
    N4: TMenuItem;
    YourCollection1: TMenuItem;
    ImageList32: TImageList;
    ActAuthenticate: TAction;
    ActAuthenticate1: TMenuItem;
    Database1: TMenuItem;
    Search1: TMenuItem;
    ActSearch: TAction;
    ActHelp: TAction;
    Help2: TMenuItem;
    procedure FileOpen1Execute(Sender: TObject);
    procedure ActAboutExecute(Sender: TObject);
    procedure FileExit1Execute(Sender: TObject);
    procedure ActConfigExecute(Sender: TObject);
    procedure ActCollectionExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ActAuthenticateExecute(Sender: TObject);
    procedure ActSearchExecute(Sender: TObject);
    procedure ActHelpExecute(Sender: TObject);
    procedure WMShowSet(var Msg: TMessage); message WM_SHOW_SET;
  private
    { Private declarations }
    FConfig: TConfig;
    FIdHttp: TIdHttp;
    FImageCache: TImageCache;
    function FCreateMDIChild(AFormClass: TFormClass; const Title: string; AllowMultiple: Boolean): TForm;
//    procedure CreateMDIChild(const Name: string);
  public
    { Public declarations }
    //class procedure ShowSetList();
    //class procedure AddToSet();
    class procedure ShowSetWindow(const set_num: String);
  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.dfm}

uses
  IdSSL, IdSSLOpenSSL, IdSSLOpenSSLHeaders,
  UFrmChild, UFrmSetListCollection, UFrmSearch, UFrmSet,
  UDlgAbout, UDlgConfig, UDlgTest, UDlgLogin, UDlgHelp,
  UStrings;

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  FConfig := TConfig.Create;
  FConfig.Load;

  var fp := ExtractFilePath(ParamStr(0));
  IdOpenSSLSetLibPath(fp);

  FIdHttp := TIdHttp.Create(nil);

  var SSLHandler := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  SSLHandler.SSLOptions.SSLVersions := [sslvTLSv1_2];
  FIdHttp.IOHandler := SSLHandler;

  FImageCache := TImageCache.Create;
  FImageCache.Config := FConfig;
end;

procedure TFrmMain.FormDestroy(Sender: TObject);
begin
  FImageCache.Free;
  FIdHttp.Free;
  try
    FConfig.Save;
  finally
    FConfig.Free;
  end;
end;

procedure TFrmMain.WMShowSet(var Msg: TMessage);
var
  MsgData: PShowSetData;
begin
  MsgData := PShowSetData(Msg.WParam);
  try
    if Assigned(MsgData) then begin
      var Form := FCreateMDIChild(TFrmSet, StrSetListFrameTitle, False); // Set to true if we want to allow multiple set windows.
      if Assigned(Form) then begin
        var FrmSet := TFrmSet(Form);
        FrmSet.LoadSet(MsgData.Set_num); // - multithreaded load
      end;
    end;
  finally
    Dispose(MsgData); // Don't forget to free the allocated memory
  end;
end;

class procedure TFrmMain.ShowSetWindow(const set_num: String);
var
  PostData: PShowSetData;
begin
  New(PostData);
  PostData^.Set_num := set_num;
  PostMessage(FrmMain.Handle, WM_SHOW_SET, WPARAM(PostData), 0);
end;

procedure TFrmMain.ActAuthenticateExecute(Sender: TObject);
begin
  var DlgLogin := TDlgLogin.Create(Self);
  try
    DlgLogin.Config := FConfig;
    DlgLogin.IdHttp := FIdHttp;
    if DlgLogin.ShowModal = mrOk then begin
      // Store token
      FConfig.Save;
    end;
  finally
    DlgLogin.Free;
  end;
end;

procedure TFrmMain.ActCollectionExecute(Sender: TObject);
begin
  FCreateMDIChild(TFrmSetListCollection, StrSetListFrameTitle, False);
end;

//
//  FCreateMDIChild(TFrmSetList, StrSetListFrameTitle, False);

function TFrmMain.FCreateMDIChild(AFormClass: TFormClass; const Title: string; AllowMultiple: Boolean): TForm;
begin
  if not AllowMultiple then begin
    // Check whether there's already a window open.
    for var I := 0 to MDIChildCount-1 do begin
      var Child := MDIChildren[I];
      if Child.ClassType = AFormClass then begin
        // Bring to the front instead of creating a new one.
        Child.BringToFront;
        Child.SetFocus;
        Result := Child;
        Exit;
      end;
    end;
  end;

  var Child := AFormClass.Create(Application);
  try
    if AFormClass = TFrmSetListCollection then begin
      var FrmSetListCollection := TFrmSetListCollection(Child);
      FrmSetListCollection.IdHttp := FIdHttp;
      FrmSetListCollection.Config := FConfig;
    end else if AFormClass = TFrmSet then begin
      var FrmSet := TFrmSet(Child);
      FrmSet.IdHttp := FIdHttp;
      FrmSet.Config := FConfig;
      FrmSet.ImageCache := FImageCache;
    end;

    Child.Caption := Title;
    Result := Child;
  finally
    //
  end;
end;

procedure TFrmMain.ActSearchExecute(Sender: TObject);
begin
  var Child := TFrmSearch.Create(Application);
  try
    Child.IdHttp := FIdHttp;
    Child.ImageCache := FImageCache;
    //Child.Config := FConfig;
    Child.Caption := StrSearchFrameTitle;
  finally
    //
  end;
end;

procedure TFrmMain.ActConfigExecute(Sender: TObject);
begin
  var DlgConfig := TDlgConfig.Create(Self);
  DlgConfig.Config := FConfig;
  try
    DlgConfig.ShowModal;
  finally
    FConfig.Save;
    DlgConfig.Free;
  end;
end;

procedure TFrmMain.ActHelpExecute(Sender: TObject);
begin
  var DlgHelp := TDlgHelp.Create(Self);
  try
    DlgHelp.ShowModal;
  finally
    DlgHelp.Free;
  end;
end;

procedure TFrmMain.FileOpen1Execute(Sender: TObject);
begin
//  if OpenDialog.Execute then
//    CreateMDIChild(OpenDialog.FileName);
end;

procedure TFrmMain.ActAboutExecute(Sender: TObject);
begin
  // Show the test dialog instead if Ctrl+Shift are held down.
  if (GetKeyState(VK_CONTROL) < 0) and (GetKeyState(VK_SHIFT) < 0) then begin
    var DlgTest := TDlgTest.Create(Self);
    try
      DlgTest.Config := FConfig;
      DlgTest.IdHttp := FIdHttp;
      DlgTest.ShowModal;
    finally
      DlgTest.Free;
    end;
  end else begin
    var DlgAbout := TDlgAbout.Create(Self);
    try
      DlgAbout.ShowModal;
    finally
      DlgAbout.Free;
    end;
  end;
end;

procedure TFrmMain.FileExit1Execute(Sender: TObject);
begin
  Close;
end;

end.
