unit UDownloadThread;

interface

uses
  Classes, SysUtils, Threading;

type
  TDownloadThread = class(TThread)
  private
    FURL: string;
    FFileName: string;
    FProgress: Integer;
    FOnProgress: TProc<Integer>;
    procedure FDoProgress(const Sender: TObject; AContentLength, AReadCount: Int64; var AAbort: Boolean);
    procedure FUpdateProgress;
  protected
    procedure Execute; override;
  public
    constructor Create(const URL, FileName: string; OnProgress: TProc<Integer>);
  end;

implementation

uses
  Net.HttpClient, Net.URLClient, Net.HttpClientComponent;

constructor TDownloadThread.Create(const URL, FileName: string; OnProgress: TProc<Integer>);
begin
  inherited Create(True);
  FURL := URL;
  FFileName := FileName;
  FOnProgress := OnProgress;
  FreeOnTerminate := True;
end;

procedure TDownloadThread.FDoProgress(const Sender: TObject; AContentLength, AReadCount: Int64; var AAbort: Boolean);
begin
  if AContentLength > 0 then
    FProgress := (AReadCount * 100) div AContentLength
  else
    FProgress := 0;
  Synchronize(FUpdateProgress);
end;

procedure TDownloadThread.FUpdateProgress;
begin
  if Assigned(FOnProgress) then
    FOnProgress(FProgress);
end;

procedure TDownloadThread.Execute;
var
  HttpClient: THttpClient;
  Response: IHTTPResponse;
  FileStream: TFileStream;
begin
  HttpClient := THttpClient.Create;
  try
    HttpClient.OnReceiveData := FDoProgress;
    FileStream := TFileStream.Create(FFileName, fmCreate);
    try
      Response := HttpClient.Get(FURL, FileStream);
    finally
      FileStream.Free;
    end;
  finally
    HttpClient.Free;
  end;
end;

end.
