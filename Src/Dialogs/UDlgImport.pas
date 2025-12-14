unit UDlgImport;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  UConfig, USetList, Vcl.Imaging.pngimage, Vcl.ExtCtrls, System.ImageList,
  Vcl.ImgList;

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
    CbxLocalCollection: TComboBox;
    Label2: TLabel;
    BtnSelectFile: TButton;
    ImageList32: TImageList;
    procedure BtnOKClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure OnChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ImgOpenClick(Sender: TObject);
  private
    { Private declarations }
    FConfig: TConfig;
    FSetListObjectList: TSetListObjectList;
    function FDoImportByRebrickableAPI: Integer;
    function FDoImportByRebrickableCSV: Integer;
    procedure FUpdateUI;
    procedure FFillLocalCollection;
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
  FireDAC.Stan.Param,
  UStrings,
  System.JSON,
  StrUtils,
  Math,
  FireDAC.Comp.Client, Data.DB, USqLiteConnection, UFrmMain, System.Types;

const
  // Import types
  cIMPORTREBRICKABLECSV = 0;
  cIMPORTREBRICKABLEAPI = 1;
  //cIMPORTFROMBRICKLINKXML = 2; // Unsure on the format for now
  //cIMPORTBRICKSETBSSETS = 3;   //
  //cIMPORTBRICKOWLORDER = 4;    //
  //cIMPORTBRICKLINKORDER = 5;   //

  // Merge mode:
  cIMPORTMERGE = 0;
  cIMPORTAPPEND = 1;
  cIMPORTOVERWRITE = 2;

procedure TDlgImport.FormCreate(Sender: TObject);
begin
  inherited;

  CbxImportOptions.Items.BeginUpdate;
  try
    CbxImportOptions.Items.Clear;
    CbxImportOptions.Items.Add(StrNameRebrickableCSV);
    CbxImportOptions.Items.Add(StrNameRebrickableAPI);
    CbxImportOptions.ItemIndex := 0;
  finally
    CbxImportOptions.Items.EndUpdate;
  end;

  CbxImportLocalOptions.Items.BeginUpdate;
  try
    CbxImportLocalOptions.Items.Clear;
    CbxImportLocalOptions.Items.Add(StrImportOptionMerge);
    CbxImportLocalOptions.Items.Add(StrImportOptionAppend);
    CbxImportLocalOptions.Items.Add(StrImportOptionOverwrite);
    CbxImportLocalOptions.ItemIndex := 0;
  finally
    CbxImportLocalOptions.Items.EndUpdate;
  end;

  EditCollectionName.Text := StrNewCollectionName;
end;

procedure TDlgImport.FFillLocalCollection;
begin
  CbxLocalCollection.Items.BeginUpdate;
  try
    CbxLocalCollection.Clear;
    CbxLocalCollection.AddItem(' - ' + StrNewCollection, TObject(0));

    var SqlConnection := FrmMain.AcquireConnection;
    var FDQuery := TFDQuery.Create(nil);
    try
      FDQuery.Connection := SqlConnection;

      FDQuery.SQL.Text := 'SELECT ID, Name, ExternalID, ExternalType from BSSetLists order by Name;';
      FDQuery.Open;

      while not FDQuery.Eof do begin
        var ID := FDQuery.FieldByName('ID').AsInteger;
        var Name := FDQuery.FieldByName('Name').AsString;
        //var ExternalID := FDQuery.FieldByName('ExternalID').AsString;
        //var ExternalType := FDQuery.FieldByName('ExternalType').AsInteger;

        CbxLocalCollection.AddItem(Name, TObject(ID));
        FDQuery.Next; // Move to the next row
      end;

      //read query result
    finally
      FDQuery.Free;
      FrmMain.ReleaseConnection(SqlConnection);
    end;

    CbxLocalCollection.ItemIndex := 0;
  finally
    CbxLocalCollection.Items.EndUpdate;
  end;
end;

procedure TDlgImport.FormShow(Sender: TObject);
begin
  inherited;

  FFillLocalCollection;
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
  var CollectionID := 0;
  if CbxLocalCollection.ItemIndex > 0 then
    CollectionID := Integer(CbxLocalCollection.Items.Objects[CbxLocalCollection.ItemIndex]);

  LblImportFilepath.Enabled := CbxImportOptions.ItemIndex = cIMPORTREBRICKABLECSV;
  EditImportFilepath.Enabled := CbxImportOptions.ItemIndex = cIMPORTREBRICKABLECSV;
  BtnSelectFile.Enabled := CbxImportOptions.ItemIndex = cIMPORTREBRICKABLECSV;

  if CbxImportOptions.ItemIndex = cIMPORTREBRICKABLECSV then begin
    BtnOK.Enabled := ((CollectionID > 0) or (Length(EditImportFilepath.Text) > 0)) and
                     (CbxImportLocalOptions.ItemIndex <> cIMPORTMERGE) and
                     (Length(EditCollectionName.Text) > 0);
  end else
    BtnOK.Enabled := CollectionID > 0;

  EditCollectionName.Enabled := CollectionID <= 0;
  LblCollectionName.Enabled := CollectionID <= 0;
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

function TDlgImport.FDoImportByRebrickableCSV: Integer;
begin
  Result := 0;

  if CbxImportLocalOptions.ItemIndex = cIMPORTMERGE then begin
    ShowMessage(StrErrMergeUnavailableForRebrickableCSVImport);
    ModalResult := mrNone;
    Exit;
  end else if not FileExists(EditImportFilepath.Text) then begin
    ShowMessage(Format(StrErrFileNotFound, [EditImportFilepath.Text]));
    ModalResult := mrNone;
    Exit;
  end;

  {//Example Import CSV:
  Set Number,Quantity,Includes Spares,Inventory ID
  76039-1,1,True,3961
  44013-1,1,True,4097
  6203-1,1,True,11731}

  var CollectionID := 0;
  if CbxLocalCollection.ItemIndex > 0 then
    CollectionID := Integer(CbxLocalCollection.Items.Objects[CbxLocalCollection.ItemIndex]);

  var SqlConnection := FrmMain.AcquireConnection;
  var FDQuery := TFDQuery.Create(nil);
  var FDTransaction := TFDTransaction.Create(nil);
  try
    FDTransaction.Connection := SqlConnection;
    FDQuery.Connection := SqlConnection;

    if CollectionID = 0 then begin
      //create new collection first.
      FDTransaction.StartTransaction;
      try
        // Set up the query
        FDQuery.Connection := SqlConnection;
        FDQuery.SQL.Text := 'INSERT INTO BSSetLists (NAME, DESCRIPTION, USEINCOLLECTION, EXTERNALTYPE, SORTINDEX)' +
                            'VALUES (:NAME, :DESCRIPTION, :USEINCOLLECTION, :EXTERNALTYPE, :SORTINDEX);';

        var Params := FDQuery.Params;
        Params.ParamByName('name').AsString := EditCollectionName.Text;
        Params.ParamByName('description').AsString := '';
        Params.ParamByName('useincollection').asInteger := 1;
        Params.ParamByName('externaltype').asInteger := Integer(cETNONE);
        Params.ParamByName('sortindex').asInteger := 0;
        // id/externalid/externaltype can't be changed by the user.
        // add imageindex later
        // custom tags are a separate action, not done here.

        FDQuery.ExecSQL;
        Params.Clear;

        // Get the new ID
        FDQuery.SQL.Text := 'SELECT MAX(id) FROM BSSetLists';
        FDQuery.Open;

        try
          FDQuery.First;
          if not FDQuery.EOF then
            CollectionID := FDQuery.Fields[0].AsInteger;
        finally
          FDQuery.Close;
        end;

        FDTransaction.Commit;
      except
        FDTransaction.Rollback;
      end;
    end else begin
      var MergeMode := CbxImportLocalOptions.ItemIndex;

      if MergeMode = cIMPORTOVERWRITE then begin
        //  cIMPORTOVERWRITE = 2;
          // Delete existing by CollectionID , then insert new stuff
      end; //else if MergeMode = cIMPORTAPPEND
        // Just insert new stuff into CollectionID
    end;

    var SL := TStringList.Create;
    SL.LoadFromFile(EditImportFilepath.Text);
    if SL.Count > 0 then begin
      // If first line looks like a header, skip it
      var StartIndex := 0;
      if SL.Count > 0 then begin
        if StartsText('Set Number', SL[0]) or StartsText('Set Number', SL[0]) then
          StartIndex := 1;
      end;

      FDTransaction.StartTransaction;
      try
        // Prepare insert SQL with parameters. InventoryID column assumed to exist.
        FDQuery.SQL.Text := 'INSERT INTO BSSets (BSSetListID, set_num, Built, HaveSpareParts, Notes) ' + //todo: InventoryVersion
                            'VALUES (:BSSetListID, :SetNum, :Built, :HaveSpareParts, :Notes)'; //:InventoryVersion

        for var I := StartIndex to SL.Count - 1 do begin
          var Line := SL[I];
          if Trim(Line) = '' then
            Continue;

          //var InventoryVersion := 1;
          var HaveSpares := 0;

          var SplitStr := Line.Split([',']);
          var SplitStrLen := Length(SplitStr);
          if SplitStrLen < 2 then
            Continue // skip malformed rows
          else if Length(SplitStr) > 2 then begin
            var S := LowerCase(Trim(SplitStr[2]));
            if (S = 'true') or (S = '1') or (S = 'yes') then
              HaveSpares := 1;
          end;
          {if Length(SplitStr) > 3 then begin
            InventoryVersion := StrToIntDef(Trim(SplitStr[3]), 0);
          end;}

          //todo: do we even need havespareparts - since we do parts per set now.

          var SetNum := Trim(SplitStr[0]);
          var Quantity := StrToIntDef(Trim(SplitStr[1]), 1);

          for var Q := 1 to Max(1, Quantity) do begin
            FDQuery.Params.Clear;
            FDQuery.Params.CreateParam(ftInteger, 'BSSetListID', ptInput).AsInteger := CollectionID;
            FDQuery.Params.CreateParam(ftString, 'SetNum', ptInput).AsString := SetNum;
            FDQuery.Params.CreateParam(ftInteger, 'Built', ptInput).AsInteger := 1;
            FDQuery.Params.CreateParam(ftInteger, 'HaveSpareParts', ptInput).AsInteger := HaveSpares;
//            FDQuery.Params.CreateParam(ftInteger, 'InventoryVersion', ptInput).AsInteger := InventoryVersion;
            FDQuery.Params.CreateParam(ftString, 'Notes', ptInput).AsString := '';

            FDQuery.ExecSQL;
            Inc(Result);
          end;
        end;

        FDTransaction.Commit;
      except
        on E: Exception do begin
          FDTransaction.Rollback;
          ShowMessage(Format('%s: %s', [StrErrImportFailed, E.Message]));
          ModalResult := mrNone;
          Result := 0;
          Exit;
        end;
      end;
    end;
  finally
    FDQuery.Free;
    FDTransaction.Free;
    FrmMain.ReleaseConnection(SqlConnection);
  end;
end;

function TDlgImport.FDoImportByRebrickableAPI: Integer;
begin
  Result := 0;
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
            //SetList.ID; // Local ID is created by the DBase.
            SetListObject.Name := ResultName;
            SetListObject.Description := ''; // Not supported by API, or needs a separate call.
            SetListObject.UseInCollection := ResultBuildable;
            SetListObject.ExternalID := StrToIntDef(ResultID, 0);
            SetListObject.ExternalType := Integer(cETREBRICKABLE);
            SetListObject.Dirty := True;
            SetListObjectList.Add(SetListObject);

            Inc(Result);

            // TSetListObjectList.SaveToSQL - handles the database side creation. See UFrmSetListCollection
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
var
  TotalImported: Integer;
begin
  if CbxImportOptions.ItemIndex = cIMPORTREBRICKABLEAPI then
    TotalImported := FDoImportByRebrickableAPI
  else
    TotalImported := FDoImportByRebrickableCSV;

  ShowMessage(Format(StrMsgImportCount, [TotalImported]));
end;

end.
