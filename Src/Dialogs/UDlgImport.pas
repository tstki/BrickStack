unit UDlgImport;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  UConfig, USetList, Vcl.Imaging.pngimage, Vcl.ExtCtrls;

type
  TDlgImport = class(TForm)
    CbxImportOptions: TComboBox;
    Label1: TLabel;
    CbxImportLocalOptions: TComboBox;
    LblImportLocalOptions: TLabel;
    BtnCancel: TButton;
    BtnOK: TButton;
    LblCollectionName: TLabel;
    EditCollectionName: TEdit;
    EditImportFilepath: TEdit;
    LblImportFilepath: TLabel;
    ImgOpen: TImage;
    procedure BtnOKClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure OnChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ImgOpenClick(Sender: TObject);
  private
    { Private declarations }
    FConfig: TConfig;
    FSetListObjectList: TSetListObjectList;
    procedure FDoImportByRebrickableAPI;
    procedure FDoImportByRebrickableCSV;
    procedure FUpdateUI;
  public
    { Public declarations }
    property Config: TConfig read FConfig write FConfig;
    property SetListObjectList: TSetListObjectList read FSetListObjectList write FSetListObjectList;
  end;

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
  Net.HttpClientComponent,
  UStrings,
  System.JSON,
  StrUtils;

const
  cIMPORTREBRICKABLEAPI = 0;
  cIMPORTREBRICKABLECSV = 1;
  //cIMPORTFROMBRICKLINKXML = 2; // Unsure on the format for now
  //cIMPORTBRICKSETMYSETS = 3;   //
  //cIMPORTBRICKOWLORDER = 4;    //
  //cIMPORTBRICKLINKORDER = 5;   //

  cIMPORTMERGE = 0;
  cIMPORTAPPEND = 1;
  cIMPORTOVERWRITE = 2;

procedure TDlgImport.FormCreate(Sender: TObject);
begin
  inherited;

  CbxImportOptions.Items.Clear;
  CbxImportOptions.Items.Add(StrNameRebrickableAPI);
  CbxImportOptions.Items.Add(StrNameRebrickableCSV);
  CbxImportOptions.ItemIndex := 0;

  CbxImportLocalOptions.Items.Clear;
  CbxImportLocalOptions.Items.Add(StrImportOptionMerge);
  CbxImportLocalOptions.Items.Add(StrImportOptionAppend);
  CbxImportLocalOptions.Items.Add(StrImportOptionOverwrite);
  CbxImportLocalOptions.ItemIndex := 0;

  EditCollectionName.Text := StrNewCollectionName;
end;

procedure TDlgImport.FormShow(Sender: TObject);
begin
  inherited;
  FUpdateUI;
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

procedure TDlgImport.FUpdateUI;
begin
  LblImportFilepath.Enabled := CbxImportOptions.ItemIndex = cIMPORTREBRICKABLECSV;
  EditImportFilepath.Enabled := CbxImportOptions.ItemIndex = cIMPORTREBRICKABLECSV;
  EditCollectionName.Enabled := CbxImportOptions.ItemIndex = cIMPORTREBRICKABLECSV;
  LblCollectionName.Enabled := CbxImportOptions.ItemIndex = cIMPORTREBRICKABLECSV;

  BtnOK.Enabled := ((Length(EditImportFilepath.Text) > 0) and (Length(EditCollectionName.Text) > 0)) or
                   (CbxImportOptions.ItemIndex = cIMPORTREBRICKABLEAPI);
end;

procedure TDlgImport.ImgOpenClick(Sender: TObject);
begin
  var OpenDialog := TFileOpenDialog.Create(nil);
  try
    OpenDialog.Title := StrSelectFile;
    OpenDialog.DefaultFolder := GetCurrentDir;
    if OpenDialog.Execute then
      EditImportFilepath.Text := OpenDialog.FileName;
  finally
    OpenDialog.Free;
  end;
end;

procedure TDlgImport.OnChange(Sender: TObject);
begin
  FUpdateUI;
end;

procedure TDlgImport.FDoImportByRebrickableCSV;
begin
  if CbxImportLocalOptions.ItemIndex = cIMPORTMERGE then begin
    ShowMessage(StrErrMergeUnavailableForRebrickableCSVImport);
    Exit;
  end else if not FileExists(EditImportFilepath.Text) then begin
    ShowMessage(Format(StrErrFileNotFound, [EditImportFilepath.Text]));
    Exit;
  end;

  {//Example Import CSV:
  Set Number,Quantity,Includes Spares,Inventory ID
  76039-1,1,True,3961
  44013-1,1,True,4097
  6203-1,1,True,11731}

  //'SELECT id FROM MysetLists WHERE name = :name'
  //If result, use result
  //If no result, insert into


  var SL := TStringList.Create;
  SL.LoadFromFile(EditImportFilepath.Text);
  if SL.Count > 0 then begin
    for var Item in SL do begin
      var SplitStr := Item.Split([',']);

      if Length(SplitStr) < 4 then begin
        // Skipping row - dont forget to alert user.
        Continue;
      end;

      //determine collectionID
      //create if needed

      //var MySetListID := selected;
      //var Set_num := SplitStr[0];
      //var built := false;
      //var quantity := SplitStr[1];
      //var havespareparts := SplitStr[2];
      //var notes := '';

//      ShowMessage(SplitStr);
    end;
  end;


//TODO
//find list by name.
//If not found, create new one and use that as ID
//otherwise use the found ID
  //Check to make sure the listname the user entered does not exist yet, or ask to import there anyway.
//  cIMPORTAPPEND = 1; //
//  cIMPORTOVERWRITE = 2; // Delete the items that are in this list


  //load CSV into TStringList, then go split and nextfield
  //Create new database entry for new setlist collection.
  //Import rows to database.
  //Report any errors with the CSV.
end;

procedure TDlgImport.FDoImportByRebrickableAPI;
begin
  // Check token, if not available - request login. Obtain a token for user actions such as import/export

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

  var StatusCode := 0;
  var HttpClient := TNetHttpClient.Create(nil);
  try
    HttpClient.CustomHeaders['Authorization'] := 'key ' + ApiKey;

    //var Params := TStringList.Create;
    var ResponseContent := HttpClient.Get(BaseUrl + EndPoint);
    StatusCode := ResponseContent.StatusCode;
    var ResponseContentString := ResponseContent.ContentAsString();

    // Attempt to parse the response:
    if (StatusCode = 200) and (ResponseContentString <> '') then begin
      var JSONObject := TJSONObject.ParseJSONValue(ResponseContentString) as TJSONObject;

      var ResultCount := '';
      JSONObject.TryGetValue<string>('count', ResultCount);
      if ResultCount <> '' then begin

        if CbxImportLocalOptions.ItemIndex = cIMPORTOVERWRITE then begin
          // clear the current collection list
          SetListObjectList.Clear;
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
            for var SetListObject in SetListObjectList do begin
              if (SetListObject.ExternalID > 0) and
                 (SetListObject.ExternalID = StrToIntDef(ResultID, 0)) then begin
                SetListObject.Name := ResultName;
                SetListObject.UseInCollection := ResultBuildable;
                Found := True;
              end;
            end;
          end;

          if not Found then begin
            // Insert new item
            var SetListObject := TSetListObject.Create;
            //SetList.ID;
            SetListObject.Name := ResultName;
            SetListObject.Description := ''; // Not supported by API, or needs a separate call.
            SetListObject.UseInCollection := ResultBuildable;
            SetListObject.ExternalID := StrToIntDef(ResultID, 0);
            SetListObject.ExternalType := cETREBRICKABLE;
            SetListObjectList.Add(SetListObject);
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
      ShowMessage(Format('%s (%d)', [StrErrNoResult, ResponseContent.StatusCode]));
      ModalResult := mrNone;
    end;
  except on e:exception do
    begin
      // show error if any
      var Msg := e.Message;
      ShowMessage(Format('%s (%d)', [Msg, StatusCode]));
      Modalresult := mrNone;
    end
  end;
end;

procedure TDlgImport.BtnOKClick(Sender: TObject);
begin
  if CbxImportOptions.ItemIndex = cIMPORTREBRICKABLEAPI then
    FDoImportByRebrickableAPI
  else
    FDoImportByRebrickableCSV;
end;

end.
