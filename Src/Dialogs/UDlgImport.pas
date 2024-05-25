unit UDlgImport;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  IdHttp, UConfig, USetList;

type
  TDlgImport = class(TForm)
    CbxImportOptions: TComboBox;
    Label1: TLabel;
    CbxImportLocalOptions: TComboBox;
    Label2: TLabel;
    BtnCancel: TButton;
    BtnOK: TButton;
    procedure BtnOKClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    FIdHttp: TIdHttp;
    FConfig: TConfig;
    FSetLists: TSetLists;
  public
    { Public declarations }
    property IdHttp: TIdHttp read FIdHttp write FIdHttp;
    property Config: TConfig read FConfig write FConfig;
    property SetLists: TSetLists read FSetLists write FSetLists;
  end;

var
  DlgImport: TDlgImport;

implementation

{$R *.dfm}

(*
Example response:

{
  "count": 20,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1234,
      "is_buildable": true,
      "name": "name1",
      "num_sets": 22
    },
    {
      "id": 1235,
      "is_buildable": true,
      "name": "name2",
      "num_sets": 96
    },
    {
      "id": 1236,
      "is_buildable": true,
      "name": "name3",
      "num_sets": 34
    }
  ]
}
*)
uses
  IdSSL, IdSSLOpenSSL, IdSSLOpenSSLHeaders,
  UStrings,
  System.JSON,
  StrUtils;

const
  cIMPORTMERGE = 0;
  cIMPORTAPPEND = 1;
  cIMPORTOVERWRITE = 2;

procedure TDlgImport.FormCreate(Sender: TObject);
begin
  CbxImportOptions.Items.Clear;
  CbxImportOptions.Items.Add(StrNameRebrickable);
  //CbxImportOptions.Items.Add('Other');
  CbxImportOptions.ItemIndex := 0;

  CbxImportLocalOptions.Items.Clear;
  CbxImportLocalOptions.Items.Add(StrImportOptionMerge);
  CbxImportLocalOptions.Items.Add(StrImportOptionAppend);
  CbxImportLocalOptions.Items.Add(StrImportOptionOverwrite);
  CbxImportLocalOptions.ItemIndex := 0;
end;

{
http response codes for rebrickable:
200	Success
201	Successfully created item
204	Item deleted successfully
400	Something was wrong with the format of your request
401	Unauthorized - your API key is invalid
403	Forbidden - you do not have access to operate on the requested item(s)
404	Item not found
429	Request throttled - slow down!
}

procedure TDlgImport.BtnOKClick(Sender: TObject);
begin
  // Obtain a token for user actions such as import/export

  //Option: also fetch all sets in each setlist right away
  //Option (heavy load) also obtain all parts in each set - might not be the best idea

  // API key is mandatory
  if FConfig.RebrickableAPIKey = '' then begin
    ShowMessage(StrErrAPIKeyNotSet);
    Modalresult := mrNone;
    Exit;
  end else if FConfig.AuthenticationToken = '' then begin
    ShowMessage(StrErrTokenNotSet);
    Modalresult := mrNone;
    Exit;
  end;

  //{{baseUrl}}/api/v3/users/:user_token/setlists/?page=1&page_size=20
  var ApiKey := FConfig.RebrickableAPIKey;
  var BaseUrl := FConfig.RebrickableBaseUrl;
  var EndPoint := '/api/v3/users/' + FConfig.AuthenticationToken + '/setlists/?page=1&page_size=20';

  FIdHttp.Request.CustomHeaders.Clear;
  FIdHttp.Request.CustomHeaders.AddValue('Authorization', 'key 1' + ApiKey);

  try
    var Params := TStringList.Create;
    try
      var ResponseContent := FIdHttp.Get(BaseUrl + EndPoint);

      // Attempt to parse the response:
      if (IdHTTP.ResponseCode = 200) and (ResponseContent <> '') then begin
        var JSONObject := TJSONObject.ParseJSONValue(ResponseContent) as TJSONObject;

        var ResultCount := '';
        JSONObject.TryGetValue<string>('count', ResultCount);
        if ResultCount <> '' then begin

          if CbxImportLocalOptions.ItemIndex = cIMPORTOVERWRITE then begin
            // clear the current collection list
            SetLists.Clear;
          end;

          var ResultsArray: TJSONArray;
          JSONObject.TryGetValue<TJSonArray>('results', ResultsArray);
          for var Item in ResultsArray do begin
            var ResultID := '';
            Item.TryGetValue<string>('id', ResultID);
            var ResultBuildable := false;
            Item.TryGetValue<boolean>('is_buildable', ResultBuildable);
            var ResultName := '';
            Item.TryGetValue<string>('name', ResultName);

            var Found := False;

            if CbxImportLocalOptions.ItemIndex = cIMPORTMERGE then begin
              // Lookup by ID
              for var SetList in SetLists do begin
                if (SetList.RebrickableID > 0) and
                   (SetList.RebrickableID = StrToIntDef(ResultID, 0)) then begin
                  SetList.Name := ResultName;
                  SetList.UseInCollection := ResultBuildable;
                  Found := True;
                end;
              end;
            end;

            if not Found then begin
              // Insert new item
              var SetList := TSetList.Create;
              SetList.Name := ResultName;
              SetList.Description := ''; // Not supported by API, or needs a separate call.
              SetList.UseInCollection := ResultBuildable;
              SetList.RebrickableID := StrToIntDef(ResultID, 0);
              SetLists.Add(SetList);
            end;
          end;

          // (default is 100 items per page)
          //  "next": null,
          // if next is not null
          // call the api again for the next page
          // re-run the above code after a delay of 1 second.

          ModalResult := mrOk;
        end else begin // Something went wrong
          var Detail := '';
          JSONObject.TryGetValue<string>('detail', Detail);
          ShowMessage(Detail);
          ModalResult := mrNone;
        end;
      end else begin
        ShowMessage(Format('%s (%d)', [StrErrNoResult, IdHTTP.ResponseCode]));
        ModalResult := mrNone;
      end;
    finally
      Params.Free;
    end;
  except on e:exception do
    begin
      // show error if any
      var idErr := IdSSLOpenSSLHeaders.WhichFailedToLoad();
      var Msg := IfThen(idErr <> '', idErr, e.Message);
      ShowMessage(Format('%s (%d)', [Msg, IdHTTP.ResponseCode]));
      Modalresult := mrNone;
    end
  end;
end;

end.
