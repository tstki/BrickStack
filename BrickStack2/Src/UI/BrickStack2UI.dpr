program BrickStack2UI;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  UBrickStack2Server in '..\UBrickStack2Server.pas',
  UBSUIWebModule in 'UBSUIWebModule.pas';

begin
  try
    RunWebBrokerServer(TUIWebModule, 8080, 'BrickStack2 UI');
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, E.ClassName + ': ' + E.Message);
      Halt(1);
    end;
  end;
end.
