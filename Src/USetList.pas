unit USetList; //Rename unit to ULegoCollection because "TCollection is an existing object name"

interface

uses
  FireDAC.Comp.Client,// FireDAC.Stan.Def, FireDAC.Stan.Async, FireDAC.DApt,
  //FireDAC.Stan.Pool, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef, FireDAC.UI.Intf, FireDAC.VCLUI.Wait,
  System.Classes, Generics.Collections;

const
  cETNONE = 0;
  cETREBRICKABLE = 1;

type
  // Can be filled with: {{baseUrl}}/api/v3/users/:user_token/setlists/?page=1&page_size=20
  // Or through SQL
  TSetList = class(TObject)
  private
    { Private declarations }
    FID: Integer;
    FName: String;
    FDescription: String;
    FUseInCollection: Boolean;
    FExternalID: Integer;
    FExternalType: Integer;
    FSortIndex: Integer;
    //FIconIndex: Integer; // Make the collection stand out more. // provide the user an icon from the imagelist
    FDirty: Boolean;    // Not saved // Item was modified and needs to update
    FDoDelete: Boolean; // Not saved // Item was deleted during import, remove it from the database on save.
  public
    { Public declarations }
    property ID: Integer read FID write FID;
    property Name: String read FName write FName;
    property Description: String read FDescription write FDescription;
    property UseInCollection: Boolean read FUseInCollection write FUseInCollection;
    property ExternalID: Integer read FExternalID write FExternalID;
    property ExternalType: Integer read FExternalType write FExternalType;
    property SortIndex: Integer read FSortIndex write FSortIndex;
    property Dirty: Boolean read FDirty write FDirty;
    property DoDelete: Boolean read FDoDelete write FDoDelete;
  end;

  // Move this to a separate unit later:
  TSetLists = class(TObjectList<TSetList>)
  public
    procedure LoadFromSql(FDQuery: TFDQuery);
    procedure LoadFromExternal;
    //procedure LoadFromFile;
    //procedure SaveToFile(ReWrite: Boolean);
    procedure SaveToSQL(SqlConnection: TFDConnection);
  end;

implementation

uses
  SysUtils, IniFiles,
  UStrings;

procedure TSetLists.LoadFromSql(FDQuery: TFDQuery);
begin
  FDQuery.Open;

  while not FDQuery.Eof do begin
    var LegoCollection := TSetList.Create;
    
    LegoCollection.ID := FDQuery.FieldByName('id').AsInteger;
    LegoCollection.Name := FDQuery.FieldByName('name').AsString;
    LegoCollection.Description := FDQuery.FieldByName('description').AsString;
    LegoCollection.UseInCollection := FDQuery.FieldByName('useincollection').AsInteger > 0;
    LegoCollection.ExternalID := FDQuery.FieldByName('externalid').AsInteger;
    LegoCollection.ExternalType := FDQuery.FieldByName('externaltype').AsInteger;
    LegoCollection.SortIndex := FDQuery.FieldByName('sortindex').AsInteger;
    //LegoCollection.IconIndex := FDQuery.FieldByName('iconindex').AsInteger;
    LegoCollection.FDirty := False;
    LegoCollection.DoDelete := False;

    Self.Add(LegoCollection);

    FDQuery.Next;
  end;
end;

procedure TSetLists.LoadFromExternal();//FIdHttp
begin
//
end;

procedure TSetLists.SaveToSQL(SqlConnection: TFDConnection);
begin
//start transaction?

  for var SetList in Self do begin
    if not SetList.Dirty then
      Continue;
    
    if Setlist.ID <> 0 then begin
      if SetList.DoDelete then begin
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
