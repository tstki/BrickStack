program BrickStack2Backend;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  UBrickStack2Server in '..\UBrickStack2Server.pas',
  UBSDemoData in 'UBSDemoData.pas',
  UBSBackendWebModule in 'UBSBackendWebModule.pas';

begin
  try
    RunWebBrokerServer(TBackendWebModule, 8081, 'BrickStack2 backend');
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, E.ClassName + ': ' + E.Message);
      Halt(1);
    end;
  end;
end.
