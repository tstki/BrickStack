unit USearchResult;

interface

uses
  FireDAC.Comp.Client,
  System.Classes, Generics.Collections;

type
  //Search what / View External types:
  TSearchWhat = ( cSEARCHTYPESET = 0,
                  cSEARCHTYPEPART = 1,
                  cSEARCHTYPEMINIFIG = 2    // Not used yet
                );

  TSearchBy = ( //cNUMORNAME = 0,
                cNUMBER = 0,
                cNAME = 2
              );

  TSearchStyle = ( // Searech style for others
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
    FID: Integer;
    //searchtype
    //own list
    //input fields

    // List of results, filled based on searchtype
    //FSets: TSetListObjectList;
    //FParts: TPartObjectList;
    //FMinifigs: TMinifigureObjectList;
  public
    { Public declarations }
    property ID: Integer read FID write FID;
  end;

implementation

uses
  FireDAC.Stan.Param,
  SysUtils, IniFiles, UFrmMain, USqLiteConnection, Data.DB,
  UStrings;

//procedure TSearchResult.LoadByID(ID: Integer);
//begin
//
//end;


end.
