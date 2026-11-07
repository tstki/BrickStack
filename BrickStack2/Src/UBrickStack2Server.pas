unit UBrickStack2Server;

interface

uses
  System.Classes;

procedure RunWebBrokerServer(AWebModuleClass: TComponentClass; APort: Word; const AServiceName: string);
procedure LogServerMessage(const AServiceName, AMessage: string);

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
  GLogLock: TCriticalSection;

procedure LogServerMessage(const AServiceName, AMessage: string);
begin
  GLogLock.Enter;
  try
    Writeln(FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now), ' [',
      AServiceName, '] ', AMessage);
  finally
    GLogLock.Leave;
  end;
end;

function HandleConsoleControl(ControlType: DWORD): BOOL; stdcall;
begin
  Result := ControlType in [CTRL_BREAK_EVENT, CTRL_CLOSE_EVENT];
  if Result and Assigned(GStopEvent) then
    GStopEvent.SetEvent;
end;

procedure RunWebBrokerServer(AWebModuleClass: TComponentClass; APort: Word; const AServiceName: string);
begin
  WebRequestHandler.WebModuleClass := AWebModuleClass;
  LogServerMessage(AServiceName, 'Starting WebBroker listener.');

  GStopEvent := TEvent.Create(nil, True, False, '');
  var HandlerRegistered := False;
  try
    if not SetConsoleCtrlHandler(@HandleConsoleControl, True) then
      RaiseLastOSError;
    HandlerRegistered := True;

    var Server := TIdHTTPWebBrokerBridge.Create(nil);
    try
      Server.Bindings.Clear;
      var Binding := Server.Bindings.Add;
      Binding.IP := '127.0.0.1';
      Binding.Port := APort;
      Server.Active := True;

      LogServerMessage(AServiceName, 'Listening on http://127.0.0.1:' +
        IntToStr(APort) + '. Press Ctrl+Break to stop.');
      GStopEvent.WaitFor(INFINITE);
      LogServerMessage(AServiceName, 'Shutdown requested; stopping listener.');
    finally
      Server.Free;
      LogServerMessage(AServiceName, 'Listener stopped.');
    end;
  finally
    if HandlerRegistered then
      SetConsoleCtrlHandler(@HandleConsoleControl, False);
    FreeAndNil(GStopEvent);
  end;
end;

initialization
  GLogLock := TCriticalSection.Create;

finalization
  GLogLock.Free;

end.
