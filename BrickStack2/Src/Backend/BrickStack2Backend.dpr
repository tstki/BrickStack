program BrickStack2Backend;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  FireDAC.Comp.Client,
  FireDAC.DApt,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.Async,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  UBrickStack2Server in '..\UBrickStack2Server.pas',
  UBSDemoData in 'UBSDemoData.pas',
  UBSDatabaseBootstrap in 'UBSDatabaseBootstrap.pas',
  UBSAdminBootstrap in 'UBSAdminBootstrap.pas',
  UBSCollectionRepository in 'UBSCollectionRepository.pas',
  UBSTotp in 'UBSTotp.pas',
  UBSBackendWebModule in 'UBSBackendWebModule.pas';

begin
  try
    LogServerMessage('BrickStack2 backend', 'Starting backend service.');
    InitializeDatabases;
    RunWebBrokerServer(TBackendWebModule, 8081, 'BrickStack2 backend');
  except
    on E: Exception do
    begin
      LogServerMessage('BrickStack2 backend',
        'Startup failed (' + E.ClassName + '): ' + E.Message);
      Writeln(ErrOutput, E.ClassName + ': ' + E.Message);
      Halt(1);
    end;
  end;
end.
