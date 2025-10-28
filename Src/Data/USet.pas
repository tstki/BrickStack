unit USet;

interface

uses
  FireDAC.Comp.Client,
  System.Classes, Generics.Collections;

type
  // Can be filled with: {{baseUrl}}/api/v3/users/:user_token/setlists/:list_id/sets/?page_size=20
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
    FHaveSpareParts: Integer;     //ms.HaveSpareParts,
    FBuilt: Integer;              //ms.Built,
    FNote: String;                //ms.Notes from BSSets ms'+
    //FLoaded: Boolean; // Not saved. Used to indicate whether the collection content was loaded into this object yet (for performance)
  public
    procedure ReadFromQuery(FDQuery: TFDQuery; IncludeBSSetID: Boolean);

    { Public declarations }
    property BSSetID: Integer read FBSSetID write FBSSetID;
    property SetNum: String read FSetNum write FSetNum;
    property SetName: String read FSetName write FSetName;
    property SetYear: Integer read FSetYear write FSetYear;
//    property SetThemeID: Integer read FSetThemeID write FSetThemeID;
    property SetThemeName: String read FSetThemeName write FSetThemeName;
    property SetNumParts: Integer read FSetNumParts write FSetNumParts;
    property SetImgUrl: String read FSetImgUrl write FSetImgUrl;
    property HaveSpareParts: Integer read FHaveSpareParts write FHaveSpareParts;
    property Built: Integer read FBuilt write FBuilt;
    property Note: String read FNote write FNote;
  end;

  //todo: convert these to TDictionary Later.
  TSetObjectList = class(TObjectList<TSetObject>)
  private
    function FGetFirstObject: TSetObject;
    function FGetQuantity: Integer;
    function FGetBuilt: Integer;
    function FGetHaveSpareParts: Integer;
    function FGetSetNum: String;
    function FGetSetName: String;
    function FGetSetYear: Integer;
    //function FGetSetThemeID: Integer;
    function FGetSetThemeName: String;
    function FGetSetNumParts: Integer;
    function FGetSetImgUrl: String;
  public
    procedure AddFromQuery(FDQuery: TFDQuery; IncludeBSSetID: Boolean);
    procedure LoadFromQuery(FDQuery: TFDQuery; IncludeBSSetID: Boolean);
    //procedure LoadFromExternal;
    //procedure LoadFromFile;
    //procedure SaveToFile(ReWrite: Boolean);
    //procedure SaveToSQL(SqlConnection: TFDConnection);

    // Calculated properties:
    property Quantity: Integer read FGetQuantity;
    property Built: Integer read FGetBuilt;
    property HaveSpareParts: Integer read FGetHaveSpareParts;

    // Obtained from the first child object:
    property SetNum: String read FGetSetNum;
    property SetName: String read FGetSetName;
    property SetYear: Integer read FGetSetYear;
//    property SetThemeID: Integer read FGetSetThemeID;
    property SetThemeName: String read FGetSetThemeName;
    property SetNumParts: Integer read FGetSetNumParts;
    property SetImgUrl: String read FGetSetImgUrl;
  end;

  //todo: convert these to TDictionary Later.
  TSetObjectListList = class(TObjectList<TSetObjectList>)
  private
    function FGetQuantity: Integer;
    function FGetBuilt: Integer;
    function FGetHaveSpareParts: Integer;
  public
    function FindListBySetNum(const cSetNum: String): TSetObjectList;
    procedure LoadFromQuery(FDQuery: TFDQuery);
    //procedure LoadFromExternal;
    //procedure LoadFromFile;
    //procedure SaveToFile(ReWrite: Boolean);
    //procedure SaveToSQL(SqlConnection: TFDConnection);

    // Calculated properties:
    property Quantity: Integer read FGetQuantity;
    property Built: Integer read FGetBuilt;
    property HaveSpareParts: Integer read FGetHaveSpareParts;
  end;

implementation

uses
  Math, SysUtils;

/// TSetObject

procedure TSetObject.ReadFromQuery(FDQuery: TFDQuery; IncludeBSSetID: Boolean);
begin
  if IncludeBSSetID then begin
    Self.BSSetID := FDQuery.FieldByName('id').AsInteger;
    Self.HaveSpareParts := FDQuery.FieldByName('havespareparts').AsInteger;
    Self.Built := FDQuery.FieldByName('built').AsInteger;
    //Self.Note := FDQuery.FieldByName('note').AsString;
  end;
  Self.SetNum := FDQuery.FieldByName('set_num').AsString;
  Self.SetName := FDQuery.FieldByName('name').AsString;
  Self.SetYear := FDQuery.FieldByName('year').AsInteger;
  //Self.SetThemeID := FDQuery.FieldByName('theme_id').AsString;
  //Self.SetThemeName := FDQuery.FieldByName('name_1').AsString;
  Self.SetNumParts := FDQuery.FieldByName('num_parts').AsInteger;
  Self.SetImgUrl := FDQuery.FieldByName('img_url').AsString;
end;

/// TSetObjectList

procedure TSetObjectList.AddFromQuery(FDQuery: TFDQuery; IncludeBSSetID: Boolean);
begin
  var SetObject := TSetObject.Create;
  SetObject.ReadFromQuery(FDQuery, IncludeBSSetID);

  Self.Add(SetObject);
end;

procedure TSetObjectList.LoadFromQuery(FDQuery: TFDQuery; IncludeBSSetID: Boolean);
begin
  FDQuery.Open;

  while not FDQuery.Eof do begin
    var SetObject := TSetObject.Create;
    SetObject.ReadFromQuery(FDQuery, IncludeBSSetID);
    Self.Add(SetObject);
    FDQuery.Next;
  end;
end;

function TSetObjectList.FGetQuantity: Integer;
begin
  Result := Self.Count;
end;

function TSetObjectList.FGetBuilt: Integer;
begin
  Result := 0;
  for var Obj in Self do
    Result := Result + Obj.Built;
end;

function TSetObjectList.FGetHaveSpareParts: Integer;
begin
  Result := 0;
  for var Obj in Self do
    Result := Result + Obj.FHaveSpareParts;
end;

function TSetObjectList.FGetFirstObject: TSetObject;
begin
 if Self.Count > 0 then
   Result := Self[0]
 else
   Result := nil;
end;

function TSetObjectList.FGetSetNum: String;
begin
  var Obj := FGetFirstObject;
  if Obj <> nil then
    Result := Obj.SetNum
  else
    Result := '';
end;

function TSetObjectList.FGetSetName: String;
begin
  var Obj := FGetFirstObject;
  if Obj <> nil then
    Result := Obj.SetName
  else
    Result := '';
end;

function TSetObjectList.FGetSetYear: Integer;
begin
  var Obj := FGetFirstObject;
  if Obj <> nil then
    Result := Obj.SetYear
  else
    Result := 0;
end;
{
function TSetObjectList.FGetSetThemeID: Integer;
begin
  var Obj := FGetFirstObject;
  if Obj <> nil then
    Result := Obj.SetThemeID
  else
    Result := 0;
end;}

function TSetObjectList.FGetSetThemeName: String;
begin
  var Obj := FGetFirstObject;
  if Obj <> nil then
    Result := Obj.SetThemeName
  else
    Result := '';
end;

function TSetObjectList.FGetSetNumParts: Integer;
begin
  var Obj := FGetFirstObject;
  if Obj <> nil then
    Result := Obj.SetNumParts
  else
    Result := 0;
end;

function TSetObjectList.FGetSetImgUrl: String;
begin
  var Obj := FGetFirstObject;
  if Obj <> nil then
    Result := Obj.SetImgUrl
  else
    Result := '';
end;

/// TSetObjectListList

function TSetObjectListList.FindListBySetNum(const cSetNum: String): TSetObjectList;
begin
  Result := nil;

  for var Obj in Self do begin
    if SameText(Obj.SetNum, cSetNum) then begin
      Result := Obj;
      Exit;
    end;
  end;
end;

procedure TSetObjectListList.LoadFromQuery(FDQuery: TFDQuery);
begin
  FDQuery.Open;

  while not FDQuery.Eof do begin
    var SetNum := FDQuery.FieldByName('set_num').AsString;
    var SetObjectList := Self.FindListBySetNum(SetNum);
    if SetObjectList = nil then begin
      SetObjectList := TSetObjectList.Create;
      SetObjectList.AddFromQuery(FDQuery, True);
      Self.Add(SetObjectList);
    end else
      SetObjectList.AddFromQuery(FDQuery, True);

    FDQuery.Next;
  end;
end;

function TSetObjectListList.FGetQuantity: Integer;
begin
  Result := 0;
  for var Obj in Self do
    Result := Result + Obj.Quantity;
end;

function TSetObjectListList.FGetBuilt: Integer;
begin
  Result := 0;
  for var Obj in Self do
    Result := Result + Obj.Built;
end;

function TSetObjectListList.FGetHaveSpareParts: Integer;
begin
  Result := 0;
  for var Obj in Self do
    Result := Result + Obj.HaveSpareParts;
end;

end.
