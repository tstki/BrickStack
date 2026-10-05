unit UBrickStack2Server;

interface

uses
  System.Classes;

procedure RunWebBrokerServer(AWebModuleClass: TComponentClass; APort: Word;
  const AServiceName: string);

implementation

uses
  Winapi.Windows,
  System.SyncObjs,
  System.SysUtils,
  IdHTTPWebBrokerBridge,
  IdSocketHandle,
  Web.WebReq;

var
  GStopEvent: TEvent;

function HandleConsoleControl(ControlType: DWORD): BOOL; stdcall;
begin
  Result := ControlType in [CTRL_C_EVENT, CTRL_BREAK_EVENT, CTRL_CLOSE_EVENT];
  if Result and Assigned(GStopEvent) then
    GStopEvent.SetEvent;
end;

procedure RunWebBrokerServer(AWebModuleClass: TComponentClass; APort: Word;
  const AServiceName: string);
var
  Server: TIdHTTPWebBrokerBridge;
  Binding: TIdSocketHandle;
  HandlerRegistered: Boolean;
begin
  WebRequestHandler.WebModuleClass := AWebModuleClass;

  GStopEvent := TEvent.Create(nil, True, False, '');
  HandlerRegistered := False;
  try
    if not SetConsoleCtrlHandler(@HandleConsoleControl, True) then
      RaiseLastOSError;
    HandlerRegistered := True;

    Server := TIdHTTPWebBrokerBridge.Create(nil);
    try
      Server.Bindings.Clear;
      Binding := Server.Bindings.Add;
      Binding.IP := '127.0.0.1';
      Binding.Port := APort;
      Server.Active := True;

      Writeln(AServiceName + ' listening on http://127.0.0.1:' + IntToStr(APort));
      Writeln('Press Ctrl+C to stop this service.');
      GStopEvent.WaitFor(INFINITE);
    finally
      Server.Free;
    end;
  finally
    if HandlerRegistered then
      SetConsoleCtrlHandler(@HandleConsoleControl, False);
    FreeAndNil(GStopEvent);
  end;
end;

end.
