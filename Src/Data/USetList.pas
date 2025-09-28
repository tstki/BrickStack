unit USetList;

interface

uses
  FireDAC.Comp.Client,
  System.Classes, Generics.Collections;

const
  cETNONE = 0;
  cETREBRICKABLE = 1;

type
  // Can be filled with: {{baseUrl}}/api/v3/users/:user_token/setlists/?page=1&page_size=20
  // Or through SQL
  TSetListObject = class(TObject)
  private
    { Private declarations }
    FID: Integer;
    FName: String;
    FDescription: String;
    FUseInCollection: Boolean;
    FExternalID: Integer;
    FExternalType: Integer;
    FSortIndex: Integer;
    FSetCount: Integer;
    //FIconIndex: Integer; // Make the collection stand out more. // provide the user an icon from the imagelist
    FDirty: Boolean;    // Not saved // Item was modified and needs to update
    FDoDelete: Boolean; // Not saved // Item was deleted during import, remove it from the database on save.
  public
    { Public declarations }
    procedure LoadByID(ID: Integer);
    procedure LoadFromQuery(FDQuery: TFDQuery);
    property ID: Integer read FID write FID;
    property Name: String read FName write FName;
    property Description: String read FDescription write FDescription;
    property UseInCollection: Boolean read FUseInCollection write FUseInCollection;
    property ExternalID: Integer read FExternalID write FExternalID;
    property ExternalType: Integer read FExternalType write FExternalType;
    property SortIndex: Integer read FSortIndex write FSortIndex;
    property SetCount: Integer read FSetCount write FSetCount;
    property Dirty: Boolean read FDirty write FDirty;
    property DoDelete: Boolean read FDoDelete write FDoDelete;
  end;

  // Move this to a separate unit later:
  TSetListObjectList = class(TObjectList<TSetListObject>)
  public
    procedure LoadFromQuery(FDQuery: TFDQuery);
    procedure LoadFromExternal;
    //procedure LoadFromFile;
    //procedure SaveToFile(ReWrite: Boolean);
    procedure SaveToSQL(SqlConnection: TFDConnection);
  end;

implementation

uses
  FireDAC.Stan.Param,
  SysUtils, IniFiles, UFrmMain, USqLiteConnection, Data.DB,
  UStrings;

procedure TSetListObject.LoadByID(ID: Integer);
begin
  var SqlConnection := FrmMain.AcquireConnection; // Kept until end of form
  var FDQuery := TFDQuery.Create(nil);
  try
    FDQuery.Connection := SqlConnection;
    FDQuery.SQL.Text := 'SELECT id, name, description, useincollection, externalid, externaltype, sortindex,'+
                        ' (select sum(quantity) FROM BSSets s WHERE s.BSSetListID = m.ID) AS SetCount' +
                        ' FROM BSSetLists m WHERE ID=:ID';

    var Params := FDQuery.Params;
    Params.ParamByName('id').asInteger := ID;

    FDQuery.Open;

    Self.LoadFromQuery(FDQuery);
  finally
    FDQuery.Free;
    FrmMain.ReleaseConnection(SqlConnection);
  end;
end;

procedure TSetListObject.LoadFromQuery(FDQuery: TFDQuery);
begin
  Self.ID := FDQuery.FieldByName('id').AsInteger;
  Self.Name := FDQuery.FieldByName('name').AsString;
  Self.Description := FDQuery.FieldByName('description').AsString;
  Self.UseInCollection := FDQuery.FieldByName('useincollection').AsInteger > 0;
  Self.ExternalID := FDQuery.FieldByName('externalid').AsInteger;
  Self.ExternalType := FDQuery.FieldByName('externaltype').AsInteger;
  Self.SortIndex := FDQuery.FieldByName('sortindex').AsInteger;
  //Self.IconIndex := FDQuery.FieldByName('iconindex').AsInteger;
  if FDQuery.FieldByName('setcount').AsString <> '' then // Zero gives empty string
    Self.SetCount := FDQuery.FieldByName('setcount').AsInteger
  else
    Self.SetCount := 0;
  Self.FDirty := False;
  Self.DoDelete := False;
end;

// TSetListObjectList

procedure TSetListObjectList.LoadFromQuery(FDQuery: TFDQuery);
begin
  FDQuery.Open;

  while not FDQuery.Eof do begin
    var LegoCollection := TSetListObject.Create;
    LegoCollection.LoadFromQuery(FDQuery);

    Self.Add(LegoCollection);

    FDQuery.Next;
  end;
end;

procedure TSetListObjectList.LoadFromExternal();//FNetHttp
begin
//
end;

procedure TSetListObjectList.SaveToSQL(SqlConnection: TFDConnection);
begin
//todo: if dirty, do insert or update.
//Intended for a batch save after import

//start transaction?

  for var SetListObject in Self do begin
    if not SetListObject.FDirty then
      Continue;
    
    if SetListObject.FID <> 0 then begin
      if SetListObject.FDoDelete then begin
      //delete
      end else begin
      //update
      end;
    end else begin
      //insert
    end;
  end;

//commit transaction
end;

end.
