unit UFrmSetList;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Actions, Vcl.ActnList,
  FireDAC.Comp.Client, FireDAC.Stan.Def, FireDAC.Stan.Async, FireDAC.DApt,
  FireDAC.Stan.Param, FireDAC.Stan.Pool, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef, FireDAC.UI.Intf, FireDAC.VCLUI.Wait,
  UConfig, USetList, Vcl.StdCtrls, Vcl.Imaging.pngimage, Vcl.ExtCtrls, Vcl.ComCtrls,
  Generics.Collections, USet, System.ImageList, Vcl.ImgList, Vcl.Menus;

type
  TFrmSetList = class(TForm)
    Panel1: TPanel;
    LblFilter: TLabel;
    CbxFilter: TComboBox;
    LvSets: TListView;
    PopupMenu1: TPopupMenu;
    test1: TMenuItem;
    Edit1: TMenuItem;
    ActDeleteSetList1: TMenuItem;
    sub1: TMenuItem;
    ag11: TMenuItem;
    ag21: TMenuItem;
    ag31: TMenuItem;
    ActionList1: TActionList;
    ActDeleteSet: TAction;
    ActEditSet: TAction;
    ImageList16: TImageList;
    ActViewExternal: TAction;
    Viewexternally1: TMenuItem;
    ActViewPartsList: TAction;
    Viewpartslist1: TMenuItem;
    StatusBar1: TStatusBar;
    ImgFind: TImage;
    ImgEdit: TImage;
    ImgDelete: TImage;
    ImgImport: TImage;
    ImgExport: TImage;
    ActSearch: TAction;
    ActImport: TAction;
    ActExport: TAction;
    ActViewSet: TAction;
    ImgView: TImage;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure CbxFilterChange(Sender: TObject);
    procedure ActDeleteSetExecute(Sender: TObject);
    procedure ActEditSetExecute(Sender: TObject);
    procedure ActViewSetExecute(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ActViewExternalExecute(Sender: TObject);
    procedure ActViewPartsListExecute(Sender: TObject);
    procedure ActImportExecute(Sender: TObject);
    procedure ActExportExecute(Sender: TObject);
    procedure ActSearchExecute(Sender: TObject);
    procedure LvSetsDrawItem(Sender: TCustomListView; Item: TListItem; Rect: TRect; State: TOwnerDrawState);
    procedure LvSetsData(Sender: TObject; Item: TListItem);
    procedure LvSetsClick(Sender: TObject);
  private
    { Private declarations }
    FSetListObject: TSetListObject;
    FSetObjectListList: TSetObjectListList;
    FOwnsSetList: Boolean;
    FConfig: TConfig;
    FBSSetListID: Integer;
    procedure FSetConfig(Config: TConfig);
    procedure FSetBSSetListObject(SetListObject: TSetListObject; OwnsObject: Boolean);
    procedure FSetBSSetListID(BSSetListID: Integer);
    function FGetSelectedObject: TSetObjectList;
    procedure FUpdateStatusBar;
  public
    { Public declarations }
    procedure ReloadAndRefresh;
    property SetListObject: TSetListObject read FSetListObject write FSetListObject;
    property BSSetListID: Integer read FBSSetListID write FSetBSSetListID;
    property Config: TConfig read FConfig write FSetConfig;
  end;

implementation

{$R *.dfm}

uses
  StrUtils,
  Math,
  Data.DB,
  USqLiteConnection,
  UITypes,
  UFrmMain, UStrings;

const //CbxFilter
  fltALL = 0;
  fltQUANTITY = 1;
  fltBUILT = 2;
  fltNOTBUILT = 3;
  fltSPAREPARTS = 4;
  fltNOSPAREPARTS = 5;
  //custom tag

procedure TFrmSetList.FormCreate(Sender: TObject);
begin
  inherited;

  FSetObjectListList := TSetObjectListList.Create;
end;

procedure TFrmSetList.FormDestroy(Sender: TObject);
begin
  if FOwnsSetList then
    FSetListObject.Free;
  FSetObjectListList.Free;

  inherited;
end;

procedure TFrmSetList.FormShow(Sender: TObject);
begin
  inherited;

  LvSets.SmallImages := ImageList16;

  CbxFilter.Items.Clear;
  CbxFilter.Items.Add(StrSetListFillterShowAll);
  CbxFilter.Items.Add(StrSetListFillterQuantity);
  CbxFilter.Items.Add(StrSetListFillterBuilt);
  CbxFilter.Items.Add(StrSetListFillterNotBuilt);
  CbxFilter.Items.Add(StrSetListFillterSpareParts);
  CbxFilter.Items.Add(StrSetListFillterNoSpareParts);

  //Perform query, get possible custom tags for setlistcollections
  //And custom tags from setlists type:
  //CbxFilter.Items.Add('Custom tag 1');
  //CbxFilter.Items.Add('Custom tag 2');
  //CbxFilter.Items.Add('Custom tag 3');
  CbxFilter.ItemIndex := 0;
end;

procedure TFrmSetList.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
  inherited;
end;

procedure TFrmSetList.FSetConfig(Config: TConfig);
begin
  FConfig := Config;
end;

procedure TFrmSetList.ActDeleteSetExecute(Sender: TObject);
begin
  var SetObject := FGetSelectedObject;
  if (SetObject <> nil) and (SetObject.SetNum <> '') and
     (MessageDlg(Format(StrMsgSureRemoveFromList, [SetObject.SetName, SetObject.SetNum]), mtConfirmation, mbYesNo, 0) = mrYes) then begin

    var SqlConnection := FrmMain.AcquireConnection;
    var FDQuery := TFDQuery.Create(nil);
    try
      FDQuery.Connection := SqlConnection;

      FDQuery.SQL.Text := 'DELETE FROM BSSets WHERE ID=:ID';

      var Params := FDQuery.Params;
      //todo: temporarily disabled.
//      Params.ParamByName('ID').asInteger := SetObject.BSSetID;
//      FDQuery.ExecSQL;
    finally
      FDQuery.Free;
      FrmMain.ReleaseConnection(SqlConnection);
    end;
  end;

  ReloadAndRefresh;

//todo:
//check if there's a details dialog open that needs to be closed or cleared

  //TFrmMain.UpdateSetsByCollectionID(BSSetListID: Integer);
  TFrmMain.UpdateCollectionsByID(FBSSetListID);
end;

procedure TFrmSetList.ActEditSetExecute(Sender: TObject);
begin
//todo: do addToSetList dialog.
//set mode add or update.

//update query

//update table
end;

procedure TFrmSetList.ActExportExecute(Sender: TObject);
begin
//
end;

procedure TFrmSetList.ActSearchExecute(Sender: TObject);
begin
//TFrmMain.ActSearch
end;

procedure TFrmSetList.ActImportExecute(Sender: TObject);
begin
//
end;

procedure TFrmSetList.ActViewSetExecute(Sender: TObject);
begin
  var SetObject := FGetSelectedObject;
  if (SetObject <> nil) and (SetObject.SetNum <> '') then
    TFrmMain.ShowSetWindow(SetObject.SetNum);
end;

procedure TFrmSetList.ActViewExternalExecute(Sender: TObject);
begin
  var SetObject := FGetSelectedObject;
  if (SetObject <> nil) and (SetObject.SetNum <> '') then
    TFrmMain.OpenExternal(cTYPESET, SetObject.SetNum);
end;

procedure TFrmSetList.ActViewPartsListExecute(Sender: TObject);
begin
  var SetObject := FGetSelectedObject;
  if (SetObject <> nil) and (SetObject.SetNum <> '') then
    TFrmMain.ShowPartsWindow(SetObject.SetNum);
end;

procedure TFrmSetList.CbxFilterChange(Sender: TObject);
begin
  ReloadAndRefresh;
end;

procedure TFrmSetList.ReloadAndRefresh();

  function FIfThen(Input, IfTrue, IfFalse: Boolean): Boolean;
  begin
    if Input then
      Result := IfTrue
    else
      Result := IfFalse;
  end;

begin
  FSetObjectListList.Clear;

  Self.Caption := 'Sets in - ' + FSetlistObject.Name;

  var FDQuery := TFDQuery.Create(nil);
  try
    // Set up the query
    var SqlConnection := FrmMain.AcquireConnection;
    try
      FDQuery.Connection := SqlConnection;
      FDQuery.SQL.Text := 'SELECT	ms.ID, s.name, s.set_num, s."year", s.num_parts, s.img_url, t.name, ms.Built, ms.HaveSpareParts, ms.Notes' +
                          ' from BSSets ms' +
                          ' left join sets s on s.set_num = ms.set_num' +
                          ' left join themes t on t.id = s.theme_id' +
                          ' where ms.BSSetListID = :BSSetListID';

      if CbxFilter.ItemIndex = fltQUANTITY then begin
        FDQuery.SQL.Text := FDQuery.SQL.Text + ' AND s.set_num IN ('+
                                               ' SELECT s2.set_num' +
                                               ' FROM BSSets ms2' +
                                               ' LEFT JOIN sets s2 ON s2.set_num = ms2.set_num' +
                                               ' WHERE ms2.BSSetListID IN (:BSSetListID)' +
                                               ' GROUP BY s2.set_num' +
                                               ' HAVING COUNT(*) > 1);'
      end else if CbxFilter.ItemIndex = fltBUILT then begin
        FDQuery.SQL.Text := FDQuery.SQL.Text + ' and built = 1';
      end else if CbxFilter.ItemIndex = fltNOTBUILT then begin
        FDQuery.SQL.Text := FDQuery.SQL.Text + ' and built = 0';
      end else if CbxFilter.ItemIndex = fltSPAREPARTS then begin
        FDQuery.SQL.Text := FDQuery.SQL.Text + ' and havespareparts = 1';
      end else if CbxFilter.ItemIndex = fltNOSPAREPARTS then begin
        FDQuery.SQL.Text := FDQuery.SQL.Text + ' and havespareparts = 0';
      end;
       // Else, no filter.

      var Params := FDQuery.Params;
      Params.ParamByName('BSSetListID').asInteger := FSetListObject.ID;

      // use : TSetObjectListList.LoadFromQuery
      FSetObjectListList.LoadFromQuery(FDQuery);

      LvSets.Items.Count := FSetObjectListList.Count;
(*
      FDQuery.Open;
      if FDQuery.RecordCount > 0 then begin
        //sets fields.
      end else if FSetListObject.ExternalID <> 0 then begin
        // Imported from external
        if FSetListObject.ExternalType = cETREBRICKABLE then begin
          //Import from rebrickable
            // Filled with: {{baseUrl}}/api/v3/users/:user_token/setlists/:list_id/sets/?page_size=20
          //insert into database, call the above code again.
        end;
      end; // Else, it's just an empty list, nothing to do.
*)
    finally
      FrmMain.ReleaseConnection(SqlConnection);
    end;
  finally
    FDQuery.Free;
  end;

  LvSets.Invalidate;

  FUpdateStatusBar;
end;

procedure TFrmSetList.FUpdateStatusBar;
begin
  StatusBar1.Panels.BeginUpdate;
  try
    StatusBar1.Panels[0].Text := 'Total sets: ' + IntToStr(FSetObjectListList.Quantity);
  finally
    StatusBar1.Panels.EndUpdate;
  end;
end;

procedure TFrmSetList.LvSetsClick(Sender: TObject);
begin
  //todo, check: did we click the image?
  //Insert or remove the sub objects.
end;

procedure TFrmSetList.LvSetsData(Sender: TObject; Item: TListItem);
begin
  inherited;
  //todo: Also for sorting

  var obj := FSetObjectListList[Item.Index];
  Item.Data := Obj;
  Item.ImageIndex := 0;
  Item.Caption := Obj.SetName;
  Item.SubItems.Add(Obj.SetNum);
  Item.SubItems.Add(IntToStr(Obj.Quantity));
  Item.SubItems.Add(IntToStr(Obj.Built));
  Item.SubItems.Add(IntToStr(Obj.HaveSpareParts));
//    Item.SubItems.Add(Obj.Note);
  //SetObject.SetYear := FDQuery.FieldByName('year').AsInteger;
  //SetObject.SetThemeName := FDQuery.FieldByName('name_1').AsString;
  //SetObject.SetNumParts := FDQuery.FieldByName('num_parts').AsInteger;
  //SetObject.SetImgUrl := FDQuery.FieldByName('img_url').AsString;
end;

procedure TFrmSetList.LvSetsDrawItem(Sender: TCustomListView; Item: TListItem; Rect: TRect; State: TOwnerDrawState);
//const
//  ICON_SPACING = 2;
begin
  inherited;

  //not used atm - is this even needed?

{  // Choose the icon index for this item (change as needed, example: always index 0)
  var IconIndex := 0;

  // Set icon position
  var IconX := Rect.Left + 2; // A small margin from item left
  ImageList16.Draw(LvSets.Canvas, IconX, Rect.Top + (Rect.Height - ImageList16.Height) div 2, IconIndex, True);

  // Set text start X position after icon
  var TextX := IconX + ImageList16.Width + ICON_SPACING;

  // Draw the item caption (move it to the right)
  LvSets.Canvas.TextOut(TextX, Rect.Top + (Rect.Height - LvSets.Canvas.TextHeight(Item.Caption)) div 2, Item.Caption);     }
end;

procedure TFrmSetList.FSetBSSetListObject(SetListObject: TSetListObject; OwnsObject: Boolean);
begin
  if FOwnsSetList then
    FSetListObject.Free;
  FOwnsSetList := OwnsObject;
  FSetListObject := SetListObject;

  ReloadAndRefresh;
end;

function TFrmSetList.FGetSelectedObject: TSetObjectList;
begin
  Result := nil;

  for var Item in LvSets.Items do begin
    if Item.Selected then begin
      Result := Item.Data;
      Break;
    end;
  end;
end;

procedure TFrmSetList.FSetBSSetListID(BSSetListID: Integer);
begin
  BSSetListID := BSSetListID;

  var SetListObject := TSetListObject.Create;
  SetListObject.LoadByID(BSSetListID);

  FSetBSSetListObject(SetListObject, True);
end;

end.
