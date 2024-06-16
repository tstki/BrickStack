unit USet;

interface

uses
  System.Classes, Generics.Collections;

type
  // Filled with: {{baseUrl}}/api/v3/users/:user_token/setlists/:list_id/sets/?page_size=20
  TSetObject = class(TObject)
  private
    { Private declarations }
    // Set details
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
    FNote: String;                //ms.Notes from MySets ms'+

    //FLoaded: Boolean; // Not saved. Used to indicate whether the collection content was loaded into this object yet (for performance)
  public
    { Public declarations }
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

  TSetObjectList = TObjectList<TSetObject>;

implementation

end.
