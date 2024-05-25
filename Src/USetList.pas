unit USetList; //Rename unit to ULegoCollection because "TCollection is an existing object name"

interface

uses
  System.Classes, Generics.Collections;

type
  // Filled with: {{baseUrl}}/api/v3/users/:user_token/setlists/?page=1&page_size=20
  TSetList = class(TObject)
  private
    { Private declarations }
    FName: String;
    FDescription: String;
    FUseInCollection: Boolean;
    FRebrickableID: Integer;
    //FSortKey: Integer;  // Use later for manual sort order.
    //FIcon: Integer;     // Make the collection stand out more.
    FLoaded: Boolean; // Not saved. Used to indicate whether the collection content was loaded into this object yet (for performance)
    //
  public
    { Public declarations }
    property Name: String read FName write FName;
    property Description: String read FDescription write FDescription;
    property UseInCollection: Boolean read FUseInCollection write FUseInCollection;
    property RebrickableID: Integer read FRebrickableID write FRebrickableID;
    property Loaded: Boolean read FLoaded write FLoaded;
  end;

  // Move this to a separate unit later:
  TSetLists = class(TObjectList<TSetList>)
  public
    procedure LoadFromFile;
    procedure SaveToFile(ReWrite: Boolean);
  end;

implementation

uses
  SysUtils, IniFiles,
  UStrings;

procedure TSetLists.LoadFromFile;
begin
  var FilePath := ExtractFilePath(ParamStr(0));
  var IniFile := TIniFile.Create(FilePath + StrCollectionsFileName);
  try
    var Sections := TStringList.Create;
    IniFile.ReadSections(Sections);

    for var Section in Sections do begin
      var LegoCollection := TSetList.Create;
      LegoCollection.Name := Section;
      LegoCollection.Description := IniFile.ReadString(Section, 'Description', '');
      LegoCollection.UseInCollection := IniFile.ReadBool(Section, 'UseInCollection', False);
      LegoCollection.RebrickableID := IniFile.ReadInteger(Section, 'RebrickableID', 0);

      Self.Add(LegoCollection);
    end;
  finally
    IniFile.Free;
  end;
end;

procedure TSetLists.SaveToFile(ReWrite: Boolean);
begin
  var FilePath := ExtractFilePath(ParamStr(0));

  if ReWrite then begin
    //Delete file
  end;

  var IniFile := TIniFile.Create(FilePath + StrCollectionsFileName);
  try
    for var LegoCollection in Self do begin
      IniFile.WriteString(LegoCollection.Name, 'Description', LegoCollection.Description);
      IniFile.WriteBool(LegoCollection.Name, 'UseInCollection', LegoCollection.UseInCollection);
      IniFile.WriteInteger(LegoCollection.Name, 'RebrickableID', LegoCollection.RebrickableID);
    end;
  finally
    IniFile.Free;
  end;
end;

end.
