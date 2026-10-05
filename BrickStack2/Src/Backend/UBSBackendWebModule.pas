unit UBSBackendWebModule;

interface

uses
  System.Classes,
  Web.HTTPApp;

type
  TBackendWebModule = class(TCustomWebDispatcher)
  private
    procedure HandleRequest(Sender: TObject; Request: TWebRequest;
      Response: TWebResponse; var Handled: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

uses
  System.SysUtils,
  UBSDemoData;

constructor TBackendWebModule.Create(AOwner: TComponent);
var
  Action: TWebActionItem;
begin
  inherited Create(AOwner);
  Action := Actions.Add;
  Action.Name := 'Dispatch';
  Action.Default := True;
  Action.OnAction := HandleRequest;
end;

procedure TBackendWebModule.HandleRequest(Sender: TObject; Request: TWebRequest;
  Response: TWebResponse; var Handled: Boolean);
begin
  Handled := True;
  if not SameText(Request.Method, 'GET') then
  begin
    Response.StatusCode := 405;
    Response.ContentType := 'application/json; charset=utf-8';
    Response.Content := '{"error":"method_not_allowed"}';
    Exit;
  end;

  if SameText(Request.PathInfo, '/health') then
  begin
    Response.ContentType := 'application/json; charset=utf-8';
    Response.Content := '{"status":"ok","service":"backend"}';
    Exit;
  end;

  if SameText(Request.PathInfo, '/api/demo') then
  begin
    Response.ContentType := 'application/json; charset=utf-8';
    Response.Content := BuildDemoJson;
    Exit;
  end;

  Response.StatusCode := 404;
  Response.ContentType := 'application/json; charset=utf-8';
  Response.Content := '{"error":"not_found"}';
end;

end.
