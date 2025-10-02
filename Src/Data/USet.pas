unit USet;

interface

uses
  FireDAC.Comp.Client,
  System.Classes, Generics.Collections;

type
  // Filled with: {{baseUrl}}/api/v3/users/:user_token/setlists/:list_id/sets/?page_size=20
  TSetObject = class(TObject)
  private
    { Private declarations }
    // Set details
    FBSSetID: Integer;            //ms.ID
    FSetNum: String;              //s.set_num,
    FSetName: String;             //s.name,
    FSetYear: Integer;            //s."year",
//    FSetThemeID: Integer;
    FSetThemeName: String;        //t.name,
    FSetNumParts: Integer;        //s.num_parts,
    FSetImgUrl: String;           //s.img_url,
    FQuantity: String;            //ms.Quantity,
    FIncludeSpares: Boolean;      //ms.HaveSpareParts,
    FBuilt: Boolean;              //ms.Built,
    FNote: String;                //ms.Notes from BSSets ms'+

    //FLoaded: Boolean; // Not saved. Used to indicate whether the collection content was loaded into this object yet (for performance)
  public
    procedure LoadFromQuery(FDQuery: TFDQuery);

    { Public declarations }
    property BSSetID: Integer read FBSSetID write FBSSetID;
    property SetNum: String read FSetNum write FSetNum;
    property SetName: String read FSetName write FSetName;
    property SetYear: Integer read FSetYear write FSetYear;
//    property SetThemeID: Integer read FSetThemeID write FSetThemeID;
    property SetThemeName: String read FSetThemeName write FSetThemeName;
    property SetNumParts: Integer read FSetNumParts write FSetNumParts;
    property SetImgUrl: String read FSetImgUrl write FSetImgUrl;
    property Quantity: String read FQuantity write FQuantity;
    property IncludeSpares: Boolean read FIncludeSpares write FIncludeSpares;
    property Built: Boolean read FBuilt write FBuilt;
    property Note: String read FNote write FNote;
  end;

  TSetObjectList = class(TObjectList<TSetObject>)
  public
    procedure LoadFromQuery(FDQuery: TFDQuery);
    //procedure LoadFromExternal;
    //procedure LoadFromFile;
    //procedure SaveToFile(ReWrite: Boolean);
    //procedure SaveToSQL(SqlConnection: TFDConnection);
  end;

implementation

procedure TSetObject.LoadFromQuery(FDQuery: TFDQuery);
begin
  Self.SetNum := FDQuery.FieldByName('set_num').AsString;
  Self.SetName := FDQuery.FieldByName('name').AsString;
  Self.SetYear := FDQuery.FieldByName('year').AsInteger;
  //Self.SetThemeID := FDQuery.FieldByName('theme_id').AsString;
  //Self.SetThemeName := FDQuery.FieldByName('name_1').AsString;
  Self.SetNumParts := FDQuery.FieldByName('num_parts').AsInteger;
  Self.SetImgUrl := FDQuery.FieldByName('img_url').AsString;
  //Self.Quantity := FDQuery.FieldByName('name_1').AsString;
  //Self.IncludeSpares := FDQuery.FieldByName('includespares').AsString;
  //Self.Built := FDQuery.FieldByName('built').AsString;
  //Self.Note := FDQuery.FieldByName('note').AsString;
end;

procedure TSetObjectList.LoadFromQuery(FDQuery: TFDQuery);
begin
  FDQuery.Open;

  while not FDQuery.Eof do begin
    var SetObject := TSetObject.Create;
    SetObject.LoadFromQuery(FDQuery);

    Self.Add(SetObject);

    FDQuery.Next;
  end;
end;

end.
