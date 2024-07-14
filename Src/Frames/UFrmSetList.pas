unit UFrmSetList;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Actions, Vcl.ActnList,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  FireDAC.Comp.Client, FireDAC.Stan.Def, FireDAC.Stan.Async, FireDAC.DApt,
  FireDAC.Stan.Param, FireDAC.Stan.Pool, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef, FireDAC.UI.Intf, FireDAC.VCLUI.Wait,
  UConfig, USetList, Vcl.StdCtrls, Vcl.Imaging.pngimage, Vcl.ExtCtrls, Vcl.ComCtrls,
  Generics.Collections, USet, System.ImageList, Vcl.ImgList, Vcl.Menus;

type
  TFrmSetList = class(TForm)
    Panel1: TPanel;
    Image1: TImage;
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
    ActDeleteSetList: TAction;
    ActEditSetList: TAction;
    ActOpenCollection: TAction;
    ImageList16: TImageList;
    ActViewExternal: TAction;
    Viewexternally1: TMenuItem;
    ActViewPartsList: TAction;
    Viewpartslist1: TMenuItem;
    StatusBar1: TStatusBar;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure CbxFilterChange(Sender: TObject);
    procedure ActDeleteSetListExecute(Sender: TObject);
    procedure ActEditSetListExecute(Sender: TObject);
    procedure ActOpenCollectionExecute(Sender: TObject);
  private
    { Private declarations }
    FSetListObject: TSetListObject;
    FSetObjects: TSetObjectList;
    FOwnsSetList: Boolean;
    FIdHttp: TIdHttp;
    FConfig: TConfig;
    procedure FSetConfig(Config: TConfig);
    procedure FSetSetListObject(SetListObject: TSetListObject; OwnsObject: Boolean);
    procedure FSetSetListID(SetSetListID: Integer);
    procedure FRebuildTable;
    function FGetSelectedObject: TSetObject;
    procedure FReloadAndRefresh;
  public
    { Public declarations }
    property SetListObject: TSetListObject read FSetListObject write FSetListObject;
    property SetListID: Integer write FSetSetListID;
    property IdHttp: TIdHttp read FIdHttp write FIdHttp;
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
  fltQuantity = 0;
  fltBuilt = 1;
  fltSpareParts = 2;

procedure TFrmSetList.FormCreate(Sender: TObject);
begin
  inherited;

  FSetObjects := TSetObjectList.Create;
end;

procedure TFrmSetList.FormDestroy(Sender: TObject);
begin
  if FOwnsSetList then
    FSetListObject.Free;
  FSetObjects.Free;

  inherited;
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

procedure TFrmSetList.FRebuildTable();
begin
  LvSets.Items.BeginUpdate;
  LvSets.Clear;

  for var Obj in FSetObjects do begin
    var ListItem := LvSets.Items.Add;
    ListItem.Data := Obj;
    ListItem.Caption := Obj.SetName;
    ListItem.SubItems.Add(Obj.SetNum);
    ListItem.SubItems.Add(Obj.Quantity);
    ListItem.SubItems.Add(IfThen(Obj.Built, 'Yes', '-'));
    ListItem.SubItems.Add(IfThen(Obj.IncludeSpares, 'Yes', '-'));
    ListItem.SubItems.Add(Obj.Note);
    //SetObject.SetYear := FDQuery.FieldByName('year').AsInteger;
    //SetObject.SetThemeName := FDQuery.FieldByName('name_1').AsString;
    //SetObject.SetNumParts := FDQuery.FieldByName('num_parts').AsInteger;
    //SetObject.SetImgUrl := FDQuery.FieldByName('img_url').AsString;
  end;

  LvSets.Items.EndUpdate;
end;

procedure TFrmSetList.ActDeleteSetListExecute(Sender: TObject);
begin
  var SetObject := FGetSelectedObject;
  if (SetObject <> nil) and (SetObject.SetNum <> '') and
     (MessageDlg(Format(StrMsgSureRemoveFromList, [SetObject.SetName, SetObject.SetNum]), mtConfirmation, mbYesNo, 0) = mrYes) then begin

    var SqlConnection := FrmMain.AcquireConnection;
    var FDQuery := TFDQuery.Create(nil);
    try
      FDQuery.Connection := SqlConnection;

      FDQuery.SQL.Text := 'DELETE FROM MySets WHERE ID=:ID';

      var Params := FDQuery.Params;
      Params.ParamByName('ID').asInteger := SetObject.MySetID;
      FDQuery.ExecSQL;
    finally
      FDQuery.Free;
      FrmMain.ReleaseConnection(SqlConnection);
    end;
  end;

  FReloadAndRefresh;

//todo:
//check if there's a details dialog open that needs to be closed or cleared
end;

procedure TFrmSetList.ActEditSetListExecute(Sender: TObject);
begin
//do addToSetList dialog.
//set mode add or update.

//update query

//update table
end;

procedure TFrmSetList.ActOpenCollectionExecute(Sender: TObject);
begin
  var SetObject := FGetSelectedObject;
  if (SetObject <> nil) and (SetObject.SetNum <> '') then
    TFrmMain.ShowSetWindow(SetObject.SetNum);
end;

procedure TFrmSetList.CbxFilterChange(Sender: TObject);
begin
  FRebuildTable;
end;

procedure TFrmSetList.FReloadAndRefresh();

  function FIfThen(Input, IfTrue, IfFalse: Boolean): Boolean;
  begin
    if Input then
      Result := IfTrue
    else
      Result := IfFalse;
  end;

begin
  FSetObjects.Clear;

  Self.Caption := 'Sets in - ' + FSetlistObject.Name;

  var FDQuery := TFDQuery.Create(nil);
  try
    // Set up the query
    var SqlConnection := FrmMain.AcquireConnection;
    try
      FDQuery.Connection := SqlConnection;
      FDQuery.SQL.Text := 'SELECT	ms.ID, s.name, s.set_num, s."year", s.num_parts, s.img_url, t.name, ms.Built, ms.Quantity, ms.HaveSpareParts, ms.Notes from MySets ms'+
                          ' left join sets s on s.set_num = ms.set_num'+
                          ' left join themes t on t.id = s.theme_id'+
                          ' where ms.MySetListID = :MySetListID';

      var Params := FDQuery.Params;
      Params.ParamByName('MySetListID').asInteger := FSetListObject.ID;

      FDQuery.Open;
      if FDQuery.RecordCount > 0 then begin
        // process results
        try
          FDQuery.First;

          while not FDQuery.EOF do begin
            var SetObject := TSetObject.Create;
            SetObject.MySetID := FDQuery.FieldByName('id').AsInteger;
            SetObject.SetName := FDQuery.FieldByName('name').AsString;
            SetObject.SetNum := FDQuery.FieldByName('set_num').AsString;
            SetObject.SetYear := FDQuery.FieldByName('year').AsInteger;
            SetObject.SetThemeName := FDQuery.FieldByName('name_1').AsString;
            SetObject.SetNumParts := FDQuery.FieldByName('num_parts').AsInteger;
            SetObject.SetImgUrl := FDQuery.FieldByName('img_url').AsString;
            SetObject.Quantity := FDQuery.FieldByName('Quantity').AsString;
            SetObject.IncludeSpares := FIfThen(FDQuery.FieldByName('HaveSpareParts').AsInteger = 1, true, false);
            SetObject.Built := FIfThen(FDQuery.FieldByName('Built').AsInteger = 1, true, false);
            SetObject.Note := FDQuery.FieldByName('Notes').AsString;

            FSetObjects.Add(SetObject);

            FDQuery.Next;
          end;
        finally
          FDQuery.Close;
        end;

        //sets fields.
      end else if FSetListObject.ExternalID <> 0 then begin
        // Imported from external
        if FSetListObject.ExternalType = cETREBRICKABLE then begin
          //Import from rebrickable
            // Filled with: {{baseUrl}}/api/v3/users/:user_token/setlists/:list_id/sets/?page_size=20
          //insert into database, call the above code again.
        end;
      end; // Else, it's just an empty list, nothing to do.
    finally
      FrmMain.ReleaseConnection(SqlConnection);
    end;
  finally
    FDQuery.Free;
  end;

  FRebuildTable;
end;

procedure TFrmSetList.FSetSetListObject(SetListObject: TSetListObject; OwnsObject: Boolean);
begin
  if FOwnsSetList then
    FSetListObject.Free;
  FOwnsSetList := OwnsObject;
  FSetListObject := SetListObject;

  StatusBar1.Panels.BeginUpdate;
  try
    StatusBar1.Panels[0].Text := 'Total sets: ' + IntToStr(FSetListObject.SetCount);
  finally
    StatusBar1.Panels.EndUpdate;
  end;

  FReloadAndRefresh;
 end;

function TFrmSetList.FGetSelectedObject: TSetObject;
begin
  Result := nil;

  for var Item in LvSets.Items do begin
    if Item.Selected then begin
      Result := Item.Data;
      Break;
    end;
  end;
end;

procedure TFrmSetList.FSetSetListID(SetSetListID: Integer);
begin
  var SetListObject := TSetListObject.Create;
  SetListObject.LoadByID(SetSetListID);

  FSetSetListObject(SetListObject, True);
end;

end.
