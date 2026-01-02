unit USearchResult;

interface

uses
  FireDAC.Comp.Client,
  UPart, USet, USetList, UConst,
  System.Classes, Generics.Collections;

type
  // Or through SQL
  TSearchResult = class(TObject)
  private
    { Private declarations }
    FSearchType: TSearchWhat;  // Sets / Parts / Minifigs
    FSearchOwnCollection: Boolean; // Did we search our own collection or the database?

    //todo: Store all input fields, so we can remember "previous searches"
    // Dont store the actual results

    // List of results, filled based on searchtype
    FSetObjectList: TSetObjectList;
    FPartObjectList: TPartObjectList;
    //FMinifigs: TMinifigureObjectList;
  public
    constructor Create;
    destructor Destroy; override;
    { Public declarations }
    function Count: Integer;
    procedure Clear;
    procedure LoadFromQuery(FDQuery: TFDQuery; const SearchWhat: TSearchWhat; IncludeBSSetID, SearchedInOwnedSets: Boolean);
    property SearchType: TSearchWhat read FSearchType write FSearchType;
    property SearchOwnCollection: Boolean read FSearchOwnCollection write FSearchOwnCollection;
    property SetObjectList: TSetObjectList read FSetObjectList;
    property PartObjectList: TPartObjectList read FPartObjectList;
  end;

implementation

uses
  FireDAC.Stan.Param,
  SysUtils, IniFiles, UFrmMain, USqLiteConnection, Data.DB,
  UStrings;

constructor TSearchResult.Create;
begin
  inherited;

  FSearchType := cSEARCHTYPENOTHING;

  FSetObjectList := TSetObjectList.Create;
  FPartObjectList := TPartObjectList.Create;
end;

destructor TSearchResult.Destroy;
begin
  FSetObjectList.Free;
  FPartObjectList.Free;

  inherited;
end;

procedure TSearchResult.Clear;
begin
  FSetObjectList.Clear;
  FPartObjectList.Clear;
end;

function TSearchResult.Count;
begin
  if FSearchType = cSEARCHTYPESET then
    Result := FSetObjectList.Count
  else if FSearchType = cSEARCHTYPEPART then
    Result := FPartObjectList.Count
  else
    Result := 0;
end;

procedure TSearchResult.LoadFromQuery(FDQuery: TFDQuery; const SearchWhat: TSearchWhat; IncludeBSSetID, SearchedInOwnedSets: Boolean);
begin
  FSearchType := SearchWhat;
  FSetObjectList.Clear;
  FPartObjectList.Clear;

  if FSearchType = cSEARCHTYPESET then
    FSetObjectList.LoadFromQuery(FDQuery, IncludeBSSetID, SearchedInOwnedSets)
  else if FSearchType = cSEARCHTYPEPART then
    FPartObjectList.LoadFromQuery(FDQuery, False, IncludeBSSetID, SearchedInOwnedSets);
end;

end.
