program BrickStack2UI;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  UBrickStack2Server in '..\UBrickStack2Server.pas',
  UBSUIWebModule in 'UBSUIWebModule.pas';

begin
  try
    LogServerMessage('BrickStack2 UI', 'Starting UI service.');
    RunWebBrokerServer(TUIWebModule, 8080, 'BrickStack2 UI');
  except
    on E: Exception do
    begin
      LogServerMessage('BrickStack2 UI',
        'Startup failed (' + E.ClassName + '): ' + E.Message);
      Writeln(ErrOutput, E.ClassName + ': ' + E.Message);
      Halt(1);
    end;
  end;
end.
