unit UFrmSetList;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Actions, Vcl.ActnList,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  FireDAC.Comp.Client, FireDAC.Stan.Def, FireDAC.Stan.Async, FireDAC.DApt,
  FireDAC.Stan.Param, FireDAC.Stan.Pool, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef, FireDAC.UI.Intf, FireDAC.VCLUI.Wait,
  UConfig, USetList, Vcl.StdCtrls, Vcl.Imaging.pngimage, Vcl.ExtCtrls, Vcl.ComCtrls,
  Generics.Collections, USet;

type
  TFrmSetList = class(TForm)
    Panel1: TPanel;
    Image1: TImage;
    LblFilter: TLabel;
    CbxFilter: TComboBox;
    ActionList1: TActionList;
    LvSets: TListView;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure LvSetsDblClick(Sender: TObject);
    procedure CbxFilterChange(Sender: TObject);
  private
    { Private declarations }
    FSetListObject: TSetListObject;
    FSetObjects: TSetObjectList;
    FOwnsSetList: Boolean;
    FIdHttp: TIdHttp;
    FConfig: TConfig;
    procedure FSetConfig(Config: TConfig);
    procedure FSetSetListObject(SetListObject: TSetListObject; OwnsObject: Boolean);
    procedure FSetSetListID(SetSetListID: Integer);
    procedure FRebuildTable;
    function FGetSelectedObject: TSetObject;
  public
    { Public declarations }
    property SetListObject: TSetListObject read FSetListObject write FSetListObject;
    property SetListID: Integer write FSetSetListID;
    property IdHttp: TIdHttp read FIdHttp write FIdHttp;
    property Config: TConfig read FConfig write FSetConfig;
  end;

implementation

{$R *.dfm}

uses
  StrUtils,
  USqLiteConnection,
  UFrmMain;

procedure TFrmSetList.FormCreate(Sender: TObject);
begin
  inherited;

  FSetObjects := TSetObjectList.Create;
end;

procedure TFrmSetList.FormDestroy(Sender: TObject);
begin
  if FOwnsSetList then
    FSetListObject.Free;
  FSetObjects.Free;

  inherited;
end;

procedure TFrmSetList.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
  inherited;
end;

procedure TFrmSetList.FSetConfig(Config: TConfig);
begin
  FConfig := Config;
end;

procedure TFrmSetList.FRebuildTable();
begin
  LvSets.Items.BeginUpdate;
  LvSets.Clear;

  for var Obj in FSetObjects do begin
    var ListItem := LvSets.Items.Add;
    ListItem.Data := Obj;
    ListItem.Caption := Obj.SetName;
    ListItem.SubItems.Add(Obj.SetNum);
    ListItem.SubItems.Add(Obj.Quantity);
    ListItem.SubItems.Add(IfThen(Obj.Built, 'Yes', ''));
    ListItem.SubItems.Add(IfThen(Obj.IncludeSpares, 'Yes', ''));
    ListItem.SubItems.Add(Obj.Note);
    //SetObject.SetYear := FDQuery.FieldByName('year').AsInteger;
    //SetObject.SetThemeName := FDQuery.FieldByName('name_1').AsString;
    //SetObject.SetNumParts := FDQuery.FieldByName('num_parts').AsInteger;
    //SetObject.SetImgUrl := FDQuery.FieldByName('img_url').AsString;
  end;

  LvSets.Items.EndUpdate;
end;

procedure TFrmSetList.CbxFilterChange(Sender: TObject);
begin
  FRebuildTable;
end;

procedure TFrmSetList.FSetSetListObject(SetListObject: TSetListObject; OwnsObject: Boolean);

  function FIfThen(Input, IfTrue, IfFalse: Boolean): Boolean;
  begin
    if Input then
      Result := IfTrue
    else
      Result := IfFalse;
  end;

begin
  if FOwnsSetList then
    FSetListObject.Free;
  FOwnsSetList := OwnsObject;
  FSetListObject := SetListObject;

  FSetObjects.Clear;

  Self.Caption := 'Sets in - ' + FSetlistObject.Name;

  var FDQuery := TFDQuery.Create(nil);
  try
    // Set up the query
    var SqlConnection := FrmMain.AcquireConnection;
    try
      FDQuery.Connection := SqlConnection;
      FDQuery.SQL.Text := 'SELECT	s.name, s.set_num, s."year", s.num_parts, s.img_url, t.name, ms.Built, ms.Quantity, ms.HaveSpareParts, ms.Notes from MySets ms'+
                          ' left join sets s on s.set_num = ms.set_num'+
                          ' left join themes t on t.id = s.theme_id'+
                          ' where ms.MySetListID = :MySetListID';

      var Params := FDQuery.Params;
      Params.ParamByName('MySetListID').asInteger := FSetListObject.ID;

      FDQuery.Open;
      if FDQuery.RecordCount > 0 then begin
        // process results
        try
          FDQuery.First;

          while not FDQuery.EOF do begin
            var SetObject := TSetObject.Create;
            SetObject.SetName := FDQuery.FieldByName('name').AsString;
            SetObject.SetNum := FDQuery.FieldByName('set_num').AsString;
            SetObject.SetYear := FDQuery.FieldByName('year').AsInteger;
            SetObject.SetThemeName := FDQuery.FieldByName('name_1').AsString;
            SetObject.SetNumParts := FDQuery.FieldByName('num_parts').AsInteger;
            SetObject.SetImgUrl := FDQuery.FieldByName('img_url').AsString;
            SetObject.Quantity := FDQuery.FieldByName('Quantity').AsString;
            SetObject.IncludeSpares := FIfThen(SameText(FDQuery.FieldByName('HaveSpareParts').AsString, 't'), true, false);
            SetObject.Built := FIfThen(SameText(FDQuery.FieldByName('Built').AsString, 't'), true, false);
            SetObject.Note := FDQuery.FieldByName('Notes').AsString;

            FSetObjects.Add(SetObject);

            FDQuery.Next;
          end;
        finally
          FDQuery.Close;
        end;

        //sets fields.
      end else if FSetListObject.ExternalID <> 0 then begin
        // Imported from external
        if FSetListObject.ExternalType = cETREBRICKABLE then begin
          //Import from rebrickable
            // Filled with: {{baseUrl}}/api/v3/users/:user_token/setlists/:list_id/sets/?page_size=20
          //insert into database, call the above code again.
        end;
      end; // Else, it's just an empty list, nothing to do.
    finally
      FrmMain.ReleaseConnection(SqlConnection);
    end;
  finally
    FDQuery.Free;
  end;

  FRebuildTable;
end;

function TFrmSetList.FGetSelectedObject: TSetObject;
begin
  Result := nil;

  for var Item in LvSets.Items do begin
    if Item.Selected then begin
      Result := Item.Data;
      Break;
    end;
  end;
end;

procedure TFrmSetList.LvSetsDblClick(Sender: TObject);
begin
  var SetObject := FGetSelectedObject;
  if (SetObject <> nil) and (SetObject.SetNum <> '') then
    TFrmMain.ShowSetWindow(SetObject.SetNum);
end;

procedure TFrmSetList.FSetSetListID(SetSetListID: Integer);
begin
  var SetListObject := TSetListObject.Create;
  SetListObject.LoadByID(SetSetListID);

  FSetSetListObject(SetListObject, True);
end;

end.
