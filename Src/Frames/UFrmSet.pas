unit UFrmSet;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Imaging.pngimage,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  Contnrs, UDelayedImage,
  SqlExpr, DBXSQLite, //SQLiteTable3, SQLite3;
  UConfig, UImageCache, Vcl.Menus, System.Actions, Vcl.ActnList, Vcl.Buttons,
  System.ImageList, Vcl.ImgList;

type
  TFrmSet = class(TForm)
    ImgSetImage: TImage;
    ImgViewSetExternal: TImage;
    LvTagData: TListView;
    ImgAdd: TImage;
    ImgRemove: TImage;
    ActionList1: TActionList;
    ActAddToSetList: TAction;
    ActRemoveFromSetList: TAction;
    ActViewSetExternal: TAction;
    ImgEdit: TImage;
    ActEditToSetList: TAction;
    ImgParts: TImage;
    ActViewParts: TAction;
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure ActAddToSetListExecute(Sender: TObject);
    procedure ActRemoveFromSetListExecute(Sender: TObject);
    procedure ActExportExecute(Sender: TObject);
    procedure ActViewSetExternalExecute(Sender: TObject);
    procedure ActToggleCheckboxModeExecute(Sender: TObject);
    procedure ActToggleIncludeSparePartsExecute(Sender: TObject);
    procedure ActToggleAscendingExecute(Sender: TObject);
    procedure ActSortByColorExecute(Sender: TObject);
    procedure ActSortByHueExecute(Sender: TObject);
    procedure ActSortByPartExecute(Sender: TObject);
    procedure ActSortByCategoryExecute(Sender: TObject);
    procedure ActSortByQuantityExecute(Sender: TObject);
    procedure ActViewPartExternalExecute(Sender: TObject);
    procedure ActEditToSetListExecute(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure ActViewPartsExecute(Sender: TObject);
  private
    { Private declarations }
    FIdHttp: TIdHttp;
    FConfig: TConfig;
    FImageCache: TImageCache;
//    FInventoryPanels: TObjectList;
    //FCurMaxCols: Integer;
    FSetNum: String;
//    FCheckboxMode: Boolean;
    procedure FHandleQueryAndHandleSetFields(Query: TSQLQuery);
    //procedure FHandleQueryAndHandleSetInventoryVersion(Query: TSQLQuery);
    //function FCreateNewResultPanel(Query: TSQLQuery; AOwner: TComponent; ParentControl: TWinControl; RowIndex, ColIndex: Integer): TPanel;
    procedure FOpenExternal(PartOrSet: Integer; PartOrSetNumber: String);
  public
    { Public declarations }
    property IdHttp: TIdHttp read FIdHttp write FIdHttp;
    property Config: TConfig read FConfig write FConfig;
    property ImageCache: TImageCache read FImageCache write FImageCache;
    procedure LoadSet(const set_num: String);
    property SetNum: String read FSetNum; // Read only
  end;

implementation

{$R *.dfm}

uses
  ShellAPI, Printers,
  Math, Diagnostics, Data.DB, StrUtils,
  UFrmMain, UDlgViewExternal, UDlgAddToSetList,
  UStrings;

procedure TFrmSet.FormDestroy(Sender: TObject);
begin
//  FInventoryPanels.Free;

  inherited;
end;

procedure TFrmSet.FormShow(Sender: TObject);
begin
//  var CurWidth := SbSetParts.ClientWidth;
//  var MinimumPanelWidth := PnlTemplateResult.Width;
//  FCurMaxCols := Floor(CurWidth/MinimumPanelWidth);
  inherited;
end;

procedure TFrmSet.FOpenExternal(PartOrSet: Integer; PartOrSetNumber: String);

  function EnsureEndsWith(const S: string; const Ch: Char): string;
  begin
    if (S <> '') and (S[Length(S)] = Ch) then
      Result := S
    else
      Result := S + Ch;
  end;

begin
  var OpenType := cOTNONE;
  if (PartOrSet = cTYPESET) and (FConfig.DefaultViewSetOpenType <> cOTNONE) then begin
    OpenType := FConfig.DefaultViewSetOpenType;
  end else if (PartOrSet = cTYPEPART) and (FConfig.DefaultViewPartOpenType <> cOTNONE) then begin
    OpenType := FConfig.DefaultViewPartOpenType;
  end else begin // No default, ask the user what to use
    var Dlg := TDlgViewExternal.Create(Self);
    try
      Dlg.PartOrSet := PartOrSet;
      Dlg.PartOrSetNumber := PartOrSetNumber;
      if Dlg.ShowModal = mrOk then begin
        OpenType := Dlg.OpenType;
        if Dlg.CheckState then begin
          if PartOrSet = cTYPESET then
            FConfig.DefaultViewSetOpenType := OpenType
          else
            FConfig.DefaultViewPartOpenType := OpenType;
          FConfig.Save;
        end;
      end;
    finally
      Dlg.Free;
    end;
  end;

  //Add soap call to API to get the external_id -> {{baseUrl}}/api/v3/lego/parts/:part_num/
  // Save it in the database?
  //Example response:
  (*
  {
    "part_num": "3001pr0043",
    "name": "Brick 2 x 4 with Smile and Frown Print on Opposite Sides",
    "part_cat_id": 11,
    "year_from": 1981,
    "year_to": 2009,
    "part_url": "https://rebrickable.com/parts/3001pr0043/brick-2-x-4-with-smile-and-frown-print-on-opposite-sides/",
    "part_img_url": "https://cdn.rebrickable.com/media/parts/elements/80141.jpg",
    "prints": [],
    "molds": [],
    "alternates": [],
    "external_ids": {
        "BrickLink": [
            "3001pe1"
        ],
        "BrickOwl": [
            "57647"
        ],
        "Brickset": [
            "80141"
        ],
        "LDraw": [
            "3001pe1"
        ],
        "LEGO": [
            "80141"
        ]
    },
    "print_of": "3001"
}
  *)

  var OpenLink := '';
  case OpenType of
    cOTREBRICKABLE:
    begin
      if FConfig.ViewRebrickableUrl = '' then
        Exit;
      OpenLink := EnsureEndsWith(FConfig.ViewRebrickableUrl, '/');
      if PartOrSet = cTYPESET then
        OpenLink := OpenLink + 'sets/' + PartOrSetNumber
      else
        OpenLink := OpenLink + 'parts/' + PartOrSetNumber;
    end;
    cOTBRICKLINK:
    begin
      if FConfig.ViewBrickLinkUrl = '' then
        Exit;
      OpenLink := EnsureEndsWith(FConfig.ViewBrickLinkUrl, '/');
      if PartOrSet = cTYPESET then
        OpenLink := OpenLink + 'v2/search.page?q=' + PartOrSetNumber
      else
        OpenLink := OpenLink + 'v2/catalog/catalogitem.page?P=' + PartOrSetNumber;
    end;
    cOTBRICKOWL:
    begin
      if FConfig.ViewBrickOwlUrl = '' then
        Exit;
      OpenLink := EnsureEndsWith(FConfig.ViewBrickOwlUrl, '/');
      if PartOrSet = cTYPESET then
        OpenLink := OpenLink + 'search/catalog?query=' + PartOrSetNumber
      else
        OpenLink := OpenLink + 'search/catalog/' + PartOrSetNumber;
    end;
    cOTBRICKSET:
    begin
      if FConfig.ViewBrickSetUrl = '' then
        Exit;
      OpenLink := EnsureEndsWith(FConfig.ViewBrickSetUrl, '/') + 'sets/' + PartOrSetNumber;
    end;
    cOTLDRAW:
    begin
      if FConfig.ViewLDrawUrl = '' then
        Exit;
      OpenLink := EnsureEndsWith(FConfig.ViewLDrawUrl, '/') + 'search/part?s=' + PartOrSetNumber;
    end;
    cOTCUSTOM:
    begin
      // Not implemented yet
    end;
  end;

  if OpenLink <> '' then begin
    // Include utm_source?
    ShellExecute(0, 'open', PChar(OpenLink), nil, nil, SW_SHOWNORMAL);
  end;
end;

procedure TFrmSet.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
  inherited;
end;

procedure TFrmSet.FHandleQueryAndHandleSetFields(Query: TSQLQuery);

  procedure FAddRow(const Caption, FieldName: String);
  begin
    try
      var SubValue := Query.FieldByName(FieldName).AsString;
      if SubValue <> '' then begin
        var Item := LvTagData.Items.Add();
        Item.Caption := Caption;
        Item.SubItems.Add(SubValue);
      end;
    except
      // NULL values may raise a not found.
    end;
  end;

begin
  var Url := Query.FieldByName('img_url').AsString;
  if Url <> '' then begin
    TThread.CreateAnonymousThread(
    procedure
    begin
      try
        var Picture := FImageCache.GetImage(Url);
        if Picture <> nil then begin
          ImgSetImage.Picture := Picture;

          TThread.Synchronize(nil,
          procedure
          begin
            // Update the UI in the main thread
            ImgSetImage.Invalidate;
          end);
        end;
      except
        // Handle exceptions here / delays.
        //Sleep(2000);
      end;
    end).Start;
  end;

  LvTagData.Items.BeginUpdate;
  try
    // Add year, category, part count, etc to table.
    FAddRow('Set num', 'set_num');
    FAddRow('Name', 'name');
    FAddRow('Released', 'year');
    FAddRow('Parts', 'num_parts');

    FAddRow('Main theme', 'name_1'); // name_1/2 because of sql
    FAddRow('Sub theme', 'name_2');  //
  finally
    LvTagData.Items.EndUpdate;
  end;

  // Seems the "fieldname as" does not work. See how to get the fieldnames or FieldDefs example:
  //  for var I := 0 to Query.FieldCount - 1 do
  //    ShowMessage(Query.Fields[I].FieldName);
end;

procedure TFrmSet.LoadSet(const set_num: String);

  procedure FQueryAndHandleSetFields(Query: TSQLQuery);
  begin
    Query.SQL.Text := 'SELECT s.set_num, s.name, s."year", s.num_parts, s.img_url, t.name AS theme, pt.name AS parenttheme' +
                      ' FROM sets s' +
                      ' LEFT JOIN themes t ON t.id = s.theme_id' +
                      ' LEFT JOIN themes pt ON pt.id = t.parent_id' +
                      ' WHERE s.set_num = :Param1';
    try
      // Always use params to prevent injection and allow sql to reuse queryplans
      var Params := Query.Params;
      Params.ParamByName('Param1').AsString := set_num;

      Query.Open; // Open the query to retrieve data
      try
        Query.First; // Move to the first row of the dataset

        if not Query.EOF then begin
          FHandleQueryAndHandleSetFields(Query);
          Self.Caption := Format(StrFrmSetTitle, [set_num, Query.FieldByName('name').AsString]);
        end;
      finally
        Query.Close; // Close the query when done
      end;
    except
      //
    end;
  end;
{
  procedure FQueryAndHandleSetInventoryVersion(Query: TSQLQuery);
  begin
    Query.SQL.Text := 'SELECT max(version) FROM inventories WHERE set_num = :Param1';
    try
      // Always use params to prevent injection and allow sql to reuse queryplans
      var Params := Query.Params;
      Params.ParamByName('Param1').AsString := set_num;

      Query.Open; // Open the query to retrieve data
      try
        Query.First; // Move to the first row of the dataset
        if not Query.EOF then
          FHandleQueryAndHandleSetInventoryVersion(Query);
      finally
        Query.Close; // Close the query when done
      end;
    except
      //
    end;
  end;

  procedure FQueryAndHandleSetPartsByVersion(Query: TSQLQuery; Version: String);
  begin
    var InventoryVersion := StrToIntDef(Version, 1);
    Query.SQL.Text := 'SELECT * FROM inventories' +
                      ' LEFT JOIN inventory_parts ip ON ip.inventory_id = inventories.id' +
                      ' LEFT JOIN colors c ON c.id = ip.color_id' +
                      ' WHERE set_num = :Param1' +
                      ' AND version = :Param2';
    try
      // Always use params to prevent injection and allow sql to reuse queryplans
      var Params := Query.Params;
      Params.ParamByName('Param1').AsString := set_num;
      Params.ParamByName('Param2').AsInteger := InventoryVersion;

      Query.Open; // Open the query to retrieve data
      try
        //var Stopwatch := TStopWatch.Create;
        //Stopwatch.Start;

        Query.First; // Move to the first row of the dataset

        var RowIndex := 0;
        var ColIndex := 0;
        var MaxCols := FCurMaxCols;

        // FInventoryPanels.Capacity := FDetermineQueryRowCount(Query); // Tried, did not have significant impact

        // Enable for tickcount performance testing:
        // Hide object, and show it when done - so we only draw once.
        while not Query.EOF do begin
          var ResultPanel := FCreateNewResultPanel(Query, SbSetParts, SbSetParts, RowIndex, ColIndex);
          ResultPanel.Visible := True;

          FInventoryPanels.Add(ResultPanel);

          Inc(ColIndex);
          if ColIndex >= MaxCols then begin
            Inc(RowIndex);
            ColIndex := 0;
          end;

          Query.Next; // Move to the next row
        end;

        //Stopwatch.Stop;
        //Enable for performance testing:
        //ShowMessage('Finished in: ' + IntToStr(Stopwatch.ElapsedMilliseconds) + 'ms');
      finally
        Query.Close; // Close the query when done
      end;
    except
      //
    end;
  end;      }

var
  Query: TSQLQuery;
begin
  // No point loading the same set as is already being shown.
  if set_num = FSetNum then
    Exit;

  FSetNum := set_num;
  Self.Caption := 'Lego set: ' + set_num; // + set name

  // Always assume version 1 is available. See: FHandleQueryAndHandleSetInventoryVersion
{  CbxInventoryVersion.Items.BeginUpdate;
  try
    CbxInventoryVersion.Clear;
    CbxInventoryVersion.Items.Add('1');
    CbxInventoryVersion.ItemIndex := 0;
  finally
    CbxInventoryVersion.Items.EndUpdate;
  end;   }

  //var Stopwatch := TStopWatch.Create;
  //Stopwatch.Start;
  try
    //SendMessage(SbSetParts.Handle, WM_SETREDRAW, 0, 0);
    try
      // Clean up the list before adding new results
//      for var I:=FInventoryPanels.Count-1 downto 0 do
//        FInventoryPanels.Delete(I);

      LvTagData.Clear;

      var FilePath := ExtractFilePath(ParamStr(0));
      var SQLConnection1 := TSqlConnection.Create(self);
      SQLConnection1.DriverName := 'SQLite';
      SQLConnection1.Params.Values['Database'] := FilePath + '\Dbase\Brickstack.db';
      SQLConnection1.Open;

      Query := TSQLQuery.Create(nil);
      try
        Query.SQLConnection := SQLConnection1;

        FQueryAndHandleSetFields(Query);
        //FQueryAndHandleSetInventoryVersion(Query);
        //FQueryAndHandleSetPartsByVersion(Query, CbxInventoryVersion.Text);
      finally
        Query.Free;
        SQLConnection1.Close;
        SQLConnection1.Free;
      end;
    finally
      //SendMessage(SbSetParts.Handle, WM_SETREDRAW, 1, 0);
      //RedrawWindow(SbSetParts.Handle, nil, 0, RDW_ERASE or RDW_INVALIDATE or RDW_FRAME or RDW_ALLCHILDREN);
    end;
  finally
    begin
      //Stopwatch.Stop;
      //Enable for performance testing:
      //ShowMessage('Finished in: ' + IntToStr(Stopwatch.ElapsedMilliseconds) + 'ms');
    end;
  end;  //}
end;

procedure TFrmSet.ActAddToSetListExecute(Sender: TObject);
begin
  var Dlg := TDlgAddToSetList.Create(Self);
  try
    if Dlg.ShowModal = mrOK then begin
      //Do add to MySets
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TFrmSet.ActRemoveFromSetListExecute(Sender: TObject);
begin
// Remove from setlist
end;

procedure TFrmSet.ActEditToSetListExecute(Sender: TObject);
begin
//
end;

procedure TFrmSet.ActExportExecute(Sender: TObject);
begin
// choose export format, and output list.
end;

procedure TFrmSet.ActSortByCategoryExecute(Sender: TObject);
begin
//
end;

procedure TFrmSet.ActSortByColorExecute(Sender: TObject);
begin
//
end;

procedure TFrmSet.ActSortByHueExecute(Sender: TObject);
begin
//
end;

procedure TFrmSet.ActSortByPartExecute(Sender: TObject);
begin
//
end;

procedure TFrmSet.ActSortByQuantityExecute(Sender: TObject);
begin
//
end;

procedure TFrmSet.ActToggleAscendingExecute(Sender: TObject);
begin
{
//  cPARTSORTBYCOLOR = 0;
  cPARTSORTBYHUE = 1;
  cPARTSORTBYPART = 2;
  cPARTSORTBYCATEGORY = 3;
  //cPARTSORTBYPRICE = 3; // No price info yet
  cPARTSORTBYQUANTITY = 4; }

{  CbxSortPartsBy.Clear;
  CbxSortPartsBy.Items.Add(StrPartSortByColor); //inventory_parts.color_id
  CbxSortPartsBy.Items.Add(StrPartSortByHue);   //colors.rgb?
  CbxSortPartsBy.Items.Add(StrPartSortByPart);  //inventory_parts.part_num
  CbxSortPartsBy.Items.Add(StrPartSortByCategory);  // parts.part_cat_id
  //CbxSortPartsBy.Items.Add(StrPartSortByPrice);   // See above
  CbxSortPartsBy.Items.Add(StrPartSortByQuantity);  //inventory_parts.quantity
  CbxSortPartsBy.ItemIndex := 0; }
end;

procedure TFrmSet.ActToggleCheckboxModeExecute(Sender: TObject);
begin
//  FCheckboxMode := not FCheckboxMode;
//  ActToggleCheckboxMode.Checked := FCheckboxMode;
{
  for var ResultPanel:TPanel in FInventoryPanels do begin
    for var i := 0 to ResultPanel.ControlCount - 1 do begin
      var Control := ResultPanel.Controls[i];
      if Control.ClassType = TCheckbox then begin
        var NewCheckbox := TCheckbox(Control);
        NewCheckbox.Visible := FCheckboxMode;
      end else if Control.ClassType = TLabel then begin
        var NewLabel := TLabel(Control);
        NewLabel.Visible := not FCheckboxMode;
      end else if Control.ClassType = TImage then begin
        var NewImage := TImage(Control);
        if NewImage.Name <> '' then
          NewImage.Visible := not FCheckboxMode;
      end;
    end;

    ResultPanel.Invalidate;
  end;   }
end;

procedure TFrmSet.ActToggleIncludeSparePartsExecute(Sender: TObject);
begin
//
end;

procedure TFrmSet.ActViewPartExternalExecute(Sender: TObject);

  function FGetPartNumByComponentName(ComponentName: String): String;
  begin
    //move this to a utility class / generic function
    Result := '';
    try
      var SplittedString := ComponentName.Split(['_']);
      if High(SplittedString) > 0 then
        Result := SplittedString[1];
    except
      // Log error.
    end;
  end;

begin
  // get partnum from sender
  FOpenExternal(cTYPEPART, FGetPartNumByComponentName(TImage(Sender).Name));
end;

procedure TFrmSet.ActViewPartsExecute(Sender: TObject);
begin
//Tell UFrmMain to Open UFrmParts
  TFrmMain.ShowPartsWindow(FSetNum);
end;

procedure TFrmSet.ActViewSetExternalExecute(Sender: TObject);
begin
  FOpenExternal(cTYPESET, FSetNum);
end;

procedure TFrmSet.Button1Click(Sender: TObject);
begin
//
end;

end.
