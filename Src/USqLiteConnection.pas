unit USqLiteConnection;

interface

uses
  System.Generics.Collections, System.SyncObjs,
  SqlExpr, DBXSQLite, //SQLiteTable3, SQLite3, SQLite3Conn, SQLDB;
  FireDAC.Comp.Client, FireDAC.Stan.Def, FireDAC.Stan.Async, FireDAC.DApt,
  FireDAC.Stan.Pool, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef, FireDAC.UI.Intf, FireDAC.VCLUI.Wait,
  SysUtils, Classes, Generics.Collections;

type
  TFDConnectionPool = class
  private
    FPool: TList<TFDConnection>;
    FLock: TCriticalSection;
    FMaxPoolSize: Integer;
    FDBPath: String;
    function FCreateNewConnection: TFDConnection;
  public
    constructor Create(DBPath: String);
    destructor Destroy; override;
    function AcquireConnection: TFDConnection;
    procedure ReleaseConnection(Connection: TFDConnection);
  end;

implementation

const
  cMAXPOOLSIZE = 10;

constructor TFDConnectionPool.Create(DBPath: String);
begin
  inherited Create;
  // sqlite3_config(SQLITE_CONFIG_SERIALIZED);
  FMaxPoolSize := cMAXPOOLSIZE;
  FPool := TList<TFDConnection>.Create;
  FLock := TCriticalSection.Create;
  FDBPath := DBPath;
end;

destructor TFDConnectionPool.Destroy;
var
  Conn: TFDConnection;
begin
  for Conn in FPool do
    Conn.Free;
  FPool.Free;
  FLock.Free;
  inherited Destroy;
end;

function TFDConnectionPool.FCreateNewConnection: TFDConnection;
begin
  Result := TFDConnection.Create(nil);
  // Set up your connection parameters here
  Result.DriverName := 'SQLite';
  Result.Params.Database := FDBPath;
  Result.LoginPrompt := False;
  Result.Connected := True;
end;

function TFDConnectionPool.AcquireConnection: TFDConnection;
begin
  FLock.Enter;
  try
    if FPool.Count > 0 then begin
      Result := FPool.Last;
      FPool.Delete(FPool.Count - 1);
    end else if FPool.Count < FMaxPoolSize then
      Result := FCreateNewConnection
    else
      raise Exception.Create('Connection pool limit reached');
  finally
    FLock.Leave;
  end;
end;

procedure TFDConnectionPool.ReleaseConnection(Connection: TFDConnection);
begin
  FLock.Enter;
  try
    FPool.Add(Connection);
  finally
    FLock.Leave;
  end;
end;

end.
