unit USearchResult;

interface

uses
  FireDAC.Comp.Client,
  UPart, USet, USetList, //UMinifig,
  System.Classes, Generics.Collections;

type
  //Search what / View External types:
  TSearchWhat = ( cSEARCHTYPESET = 0,
                  cSEARCHTYPEPART = 1,
                  cSEARCHTYPEMINIFIG = 2    // Not used yet
                );

  TSearchBy = ( //cNUMBERORNAME = 0,
                cNUMBER = 0,
                cNAME = 2
              );

  TSearchStyle = ( // Search style for others
                   cSearchAll = 0,        // "%SearchText%" // May find a lot more unrelated stuff
                   // Search style for sets
                   cSearchPrefix = 1,     // "SearchText%" // Also gets all versions// Search style for sets:
                   cSearchSuffix = 2,     // "%SearchText" and "%Searchtext-1" // Find parts of sets
                   cSearchExact = 3       // "SearchText"
                 );

  // Or through SQL
  TSearchResult = class(TObject)
  private
    { Private declarations }
    FSearchType: TSearchWhat;
    //searchtype
    //own list
    //input fields

    // List of results, filled based on searchtype
    FSetObjectList: TSetObjectList;
    //FParts: TPartObjectList;
    //FMinifigs: TMinifigureObjectList;
  public
    constructor Create;
    destructor Destroy; override;
    { Public declarations }
    procedure Clear;
    procedure LoadFromQuery(FDQuery: TFDQuery; IncludeBSSetID, SearchedInOwnedSets: Boolean);
    property SearchType: TSearchWhat read FSearchType write FSearchType;
    property SetObjectList: TSetObjectList read FSetObjectList;
  end;

implementation

uses
  FireDAC.Stan.Param,
  SysUtils, IniFiles, UFrmMain, USqLiteConnection, Data.DB,
  UStrings;

constructor TSearchResult.Create;
begin
  inherited;

  FSetObjectList := TSetObjectList.Create;
end;

destructor TSearchResult.Destroy;
begin
  FSetObjectList.Free;

  inherited;
end;

procedure TSearchResult.Clear;
begin
  FSetObjectList.Clear;
end;

procedure TSearchResult.LoadFromQuery(FDQuery: TFDQuery; IncludeBSSetID, SearchedInOwnedSets: Boolean);
begin
  if FSearchType = cSEARCHTYPESET then
    FSetObjectList.LoadFromQuery(FDQuery, IncludeBSSetID, SearchedInOwnedSets);
end;

end.
