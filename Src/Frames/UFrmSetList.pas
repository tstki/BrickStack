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
  private
    { Private declarations }
    FSetListObject: TSetListObject;
    FSetObjects: TSetObjectList;
    FOwnsSetList: Boolean;
    FConfig: TConfig;
    FSetListID: Integer;
    procedure FSetConfig(Config: TConfig);
    procedure FSetSetListObject(SetListObject: TSetListObject; OwnsObject: Boolean);
    procedure FSetSetListID(SetSetListID: Integer);
    procedure FRebuildTable;
    function FGetSelectedObject: TSetObject;
    procedure FReloadAndRefresh;
  public
    { Public declarations }
    property SetListObject: TSetListObject read FSetListObject write FSetListObject;
    property SetListID: Integer read FSetListID write FSetSetListID;
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

  FSetObjects := TSetObjectList.Create;
end;

procedure TFrmSetList.FormDestroy(Sender: TObject);
begin
  if FOwnsSetList then
    FSetListObject.Free;
  FSetObjects.Free;

  inherited;
end;

procedure TFrmSetList.FormShow(Sender: TObject);
begin
  inherited;

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

procedure TFrmSetList.FRebuildTable();
begin
  LvSets.Items.BeginUpdate;
  LvSets.Clear;

  for var Obj in FSetObjects do begin
    // Check filter.
    if CbxFilter.ItemIndex = fltQUANTITY then begin
      if StrToIntDef(Obj.Quantity, 0) <= 1 then
        Continue;
    end else if CbxFilter.ItemIndex = fltBUILT then begin
      if not Obj.Built then
        Continue;
    end else if CbxFilter.ItemIndex = fltNOTBUILT then begin
      if Obj.Built then
        Continue;
    end else if CbxFilter.ItemIndex = fltSPAREPARTS then begin
      if not Obj.IncludeSpares then
        Continue;
    end else if CbxFilter.ItemIndex = fltNOSPAREPARTS then begin
      if Obj.IncludeSpares then
        Continue;
    end; // Else, no filter.

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

procedure TFrmSetList.ActDeleteSetExecute(Sender: TObject);
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
  FSetListID := SetSetListID;

  var SetListObject := TSetListObject.Create;
  SetListObject.LoadByID(SetSetListID);

  FSetSetListObject(SetListObject, True);
end;

end.
