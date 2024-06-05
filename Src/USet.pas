unit USet;

interface

uses
  System.Classes, Generics.Collections;

type
  // Filled with: {{baseUrl}}/api/v3/users/:user_token/setlists/:list_id/sets/?page_size=20
  TSetObject = class(TObject)
  private
    { Private declarations }
//    FListID: Integer; // We know the listID, so this one is kinda pointless
    FQuantity: String;
    FIncludeSpares: Boolean;

    // Set details
    FSetNum: String;
    FSetName: String;
    FSetYear: Integer;
    FSetThemeID: Integer;
    FSetNumParts: Integer;
    FSetImgUrl: String;
    FSetUrl: String;
    FSetLastModified: String;

    //FSortKey: Integer;  // Use later for manual sort order.
    //FIcon: Integer;     // Make the collection stand out more.
    FLoaded: Boolean; // Not saved. Used to indicate whether the collection content was loaded into this object yet (for performance)
    //
  public
    { Public declarations }
//    property Name: String read FName write FName;
//    property Description: String read FDescription write FDescription;
//    property UseInCollection: Boolean read FUseInCollection write FUseInCollection;
//    property RebrickableID: Integer read FRebrickableID write FRebrickableID;
//    property Loaded: Boolean read FLoaded write FLoaded;
  end;



implementation

end.
