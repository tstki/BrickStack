unit UFrmSet;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Imaging.pngimage,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  Contnrs,
  SqlExpr, DBXSQLite, //SQLiteTable3, SQLite3;
  UConfig, UImageCache;

type
  TFrmSet = class(TForm)
    ImgSetImage: TImage;
    SbSetParts: TScrollBox;
    PnlTemplateResult: TPanel;
    ImgTemplatePartImage: TImage;
    ImgTemplateShowPart: TImage;
    LblTemplateName: TLabel;
    CbxTemplateCheck: TCheckBox;
    ImgViewSetExternal: TImage;
    LvTagData: TListView;
    LblExtra: TLabel;
    CbxInventoryVersion: TComboBox;
    Label1: TLabel;
    Button1: TButton;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    Label2: TLabel;
    CbxSortPartsBy: TComboBox;
    TmrRefresh: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure SbSetPartsResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure TmrRefreshTimer(Sender: TObject);
    procedure ImgViewSetExternalClick(Sender: TObject);
    procedure ImgTemplateShowPartClick(Sender: TObject);
  private
    { Private declarations }
    FIdHttp: TIdHttp;
    FConfig: TConfig;
    FImageCache: TImageCache;
    FInventoryPanels: TObjectList;
    FCurMaxCols: Integer;
    FSetNum: String;
    procedure FHandleQueryAndHandleSetFields(Query: TSQLQuery);
    procedure FHandleQueryAndHandleSetInventoryVersion(Query: TSQLQuery);
    function FCreateNewResultPanel(Query: TSQLQuery; AOwner: TComponent; ParentControl: TWinControl; RowIndex, ColIndex: Integer): TPanel;
    procedure FOpenExternal(PartOrSet: Integer; PartOrSetNumber: String);
  public
    { Public declarations }
    property IdHttp: TIdHttp read FIdHttp write FIdHttp;
    property Config: TConfig read FConfig write FConfig;
    property ImageCache: TImageCache read FImageCache write FImageCache;
    procedure LoadSet(const set_num: String);
  end;

implementation

{$R *.dfm}

uses
  ShellAPI,
  Math, Diagnostics, Data.DB, StrUtils,
  UDlgViewExternal,
  UStrings;

const
  cPARTSORTBYCOLOR = 0;
  cPARTSORTBYHUE = 1;
  cPARTSORTBYPART = 2;
  cPARTSORTBYCATEGORY = 3;
  //cPARTSORTBYPRICE = 3; // No price info yet
  cPARTSORTBYQUANTITY = 4;

procedure TFrmSet.FormCreate(Sender: TObject);
begin
  FInventoryPanels := TObjectList.Create;
  FInventoryPanels.OwnsObjects := True;

  SbSetParts.UseWheelForScrolling := True;

  CbxSortPartsBy.Clear;
  CbxSortPartsBy.Items.Add(StrPartSortByColor); //inventory_parts.color_id
  CbxSortPartsBy.Items.Add(StrPartSortByHue);   //colors.rgb?
  CbxSortPartsBy.Items.Add(StrPartSortByPart);  //inventory_parts.part_num
  CbxSortPartsBy.Items.Add(StrPartSortByCategory);  // parts.part_cat_id
  //CbxSortPartsBy.Items.Add(StrPartSortByPrice); // See above
  CbxSortPartsBy.Items.Add(StrPartSortByQuantity);  //inventory_parts.quantity
  CbxSortPartsBy.ItemIndex := 0;
end;

procedure TFrmSet.FormDestroy(Sender: TObject);
begin
  FInventoryPanels.Free;
end;

procedure TFrmSet.FormShow(Sender: TObject);
begin
  var CurWidth := SbSetParts.ClientWidth;
  var MinimumPanelWidth := PnlTemplateResult.Width;
  FCurMaxCols := Floor(CurWidth/MinimumPanelWidth);
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

  var OpenLink := '';
  case OpenType of
    cOTREBRICKABLE:
    begin
      OpenLink := EnsureEndsWith(FConfig.ViewRebrickableUrl, '/');
      if PartOrSet = cTYPESET then
        OpenLink := OpenLink + 'sets/' + PartOrSetNumber
      else
        OpenLink := OpenLink + 'parts/' + PartOrSetNumber;
    end;
    cOTBRICKLINK:
    begin
      OpenLink := EnsureEndsWith(FConfig.ViewBrickLinkUrl, '/');
      if PartOrSet = cTYPESET then
        OpenLink := OpenLink + 'v2/search.page?q=' + PartOrSetNumber
      else
        OpenLink := OpenLink + 'v2/catalog/catalogitem.page?P=' + PartOrSetNumber;
    end;
    cOTBRICKOWL:
    begin
      OpenLink := EnsureEndsWith(FConfig.ViewBrickOwlUrl, '/');
      if PartOrSet = cTYPESET then
        OpenLink := OpenLink + 'search/catalog?query=' + PartOrSetNumber
      else
        OpenLink := OpenLink + 'search/catalog/' + PartOrSetNumber;
    end;
    cOTBRICKSET:
    begin
      OpenLink := EnsureEndsWith(FConfig.ViewBrickSetUrl, '/') + 'sets/' + PartOrSetNumber;
    end;
    cOTLDRAW:
    begin
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

procedure TFrmSet.ImgViewSetExternalClick(Sender: TObject);
begin
  FOpenExternal(cTYPESET, FSetNum);
end;

procedure TFrmSet.ImgTemplateShowPartClick(Sender: TObject);

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
  // get setnumfrom sender
  FOpenExternal(cTYPEPART, FGetPartNumByComponentName(TImage(Sender).Name));
end;

procedure TFrmSet.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
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
    // Queue loading the image async
    TThread.Queue(nil,
      procedure
      begin
        try
          var Picture := ImageCache.GetImage(URL);
          if Picture <> nil then
            ImgSetImage.Picture := Picture;
        except
          // Handle exceptions here / delays.
        end;
      end);
  end;

  LvTagData.Items.BeginUpdate;
  try
    // Add year, category, part count, etc to table.
    FAddRow('Set num', 'set_num');
    FAddRow('Name', 'name');
    FAddRow('Released', 'year');
    FAddRow('Parts', 'num_parts');

    FAddRow('Main theme', 'name_1'); // Broken?
    FAddRow('Sub theme', 'name_2');  // Broken?
  finally
    LvTagData.Items.EndUpdate;
  end;

  // Seems the "fieldname as" does not work. See:
  //  for var I := 0 to Query.FieldCount - 1 do
  //    ShowMessage(Query.Fields[I].FieldName);
end;

procedure TFrmSet.FHandleQueryAndHandleSetInventoryVersion(Query: TSQLQuery);
begin
  var MaxVersion := Query.FieldByName('Column0').AsInteger;
  if MaxVersion > 1 then begin
    for var I := 2 to MaxVersion do
      CbxInventoryVersion.Items.Add(I.ToString);
  end;
end;

function TFrmSet.FCreateNewResultPanel(Query: TSQLQuery; AOwner: TComponent; ParentControl: TWinControl; RowIndex, ColIndex: Integer): TPanel;
begin
  Result := TPanel.Create(AOwner);
  Result.Width := PnlTemplateResult.Width;
  Result.Height := PnlTemplateResult.Height;
  Result.Top := 0 + PnlTemplateResult.Height * RowIndex;
  Result.Left := 0 + PnlTemplateResult.Width * ColIndex;

  for var i := 0 to PnlTemplateResult.ControlCount - 1 do begin
    var Control := PnlTemplateResult.Controls[i].ClassType.Create;

    //TComponent(Control).Name;

    // Copy other properties as needed
    if Control.ClassType = TLabel then begin
      var TemplateLabel := TLabel(PnlTemplateResult.Controls[i]);
      var NewLabel := TLabel.Create(Result);

      NewLabel.Parent := Result;
      NewLabel.Top := TemplateLabel.Top;
      NewLabel.Left := TemplateLabel.Left;
      NewLabel.Width := TemplateLabel.Width;
      NewLabel.Height := TemplateLabel.Height;

      if SameText(TemplateLabel.Name, 'LblExtra') then
        NewLabel.Caption := IfThen(SameText(Query.FieldByName('is_spare').AsString, 't'), 'spare', '')
      else if SameText(TemplateLabel.Name, 'LblTemplateName') then
        NewLabel.Caption := Query.FieldByName('quantity').AsString + 'x ' + Query.FieldByName('part_num').AsString
      //else if SameText(TemplateLabel.Name, 'LblTemplateColor') then
        //NewLabel.Caption := Query.FieldByName('color').AsString
      else
        NewLabel.Caption := TemplateLabel.Caption;

    end else if Control.ClassType = TImage then begin
      var TemplateImage := TImage(PnlTemplateResult.Controls[i]);
      var NewImage := TImage.Create(Result);

      NewImage.Parent := Result;
      NewImage.Top := TemplateImage.Top;
      NewImage.Left := TemplateImage.Left;
      NewImage.Width := TemplateImage.Width;
      NewImage.Height := TemplateImage.Height;

      // Downloaded images are HUGE, make sure to scale them down so they look better:
      NewImage.Stretch := True;
      NewImage.Proportional := True;
      if Assigned(TemplateImage.OnClick) then begin
        NewImage.OnClick := TemplateImage.OnClick;
        //NewImage.Tag := // If we had an ID, this would be a good place to use it
        NewImage.Name := TemplateImage.Name + '_' + StringReplace(Query.FieldByName('part_num').AsString, '-', '_', [rfReplaceAll]);
      end;

      if SameText(TemplateImage.Name, 'ImgTemplatePartImage') then begin
        var url := Query.FieldByName('img_url').AsString;
        if url <> '' then begin
          // Queue loading the image async
          TThread.Queue(nil,
            procedure
            begin
              try
                var Picture := ImageCache.GetImage(URL);
                if Picture <> nil then
                  NewImage.Picture := Picture;
              except
                // Handle exceptions here / delays.
              end;
            end);
        end;
      end else
        NewImage.Picture := TemplateImage.Picture;
    end;
    //end else if Control is TButton then begin
      //TButton(Control).OnClick := TButton(PnlTemplateResult.Controls[i]).OnClick; // Copy event handlers
    //end else if Control is TEdit then begin
      //TEdit(Control).Text := TEdit(PnlTemplateResult.Controls[i]).Text; // Copy text
    //end;
    // Add handling for other control types as needed
  end;
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
        Query.First; // Move to the first row of the dataset

        var RowIndex := 0;
        var ColIndex := 0;
        var MaxCols := FCurMaxCols;

        while not Query.EOF do begin
          var ResultPanel := FCreateNewResultPanel(Query, SbSetParts, SbSetParts, RowIndex, ColIndex);
          ResultPanel.Parent := SbSetParts;

          FInventoryPanels.Add(ResultPanel);

          Inc(ColIndex);
          if ColIndex >= MaxCols then begin
            Inc(RowIndex);
            ColIndex := 0;
          end;

          Query.Next; // Move to the next row
        end;
      finally
        Query.Close; // Close the query when done
      end;
    except
      //
    end;
  end;

var
  Query: TSQLQuery;
begin
  FSetNum := set_num;
  Self.Caption := 'Lego set: ' + set_num; // + set name

  // Always assume version 1 is available.
  CbxInventoryVersion.Clear;
  CbxInventoryVersion.Items.Add('1');
  CbxInventoryVersion.ItemIndex := 0;

  // Clean up the list before adding new results
  for var I:=FInventoryPanels.Count-1 downto 0 do
    FInventoryPanels.Delete(I);

  LvTagData.Clear;

  //var Stopwatch := TStopWatch.Create;
  //Stopwatch.Start;
  try
    var FilePath := ExtractFilePath(ParamStr(0));

    var SQLConnection1 := TSqlConnection.Create(self);
    SQLConnection1.DriverName := 'SQLite';
    SQLConnection1.Params.Values['Database'] := FilePath + '\Dbase\Brickstack.db';
    SQLConnection1.Open;


    Query := TSQLQuery.Create(nil);
    try
      Query.SQLConnection := SQLConnection1;

      FQueryAndHandleSetFields(Query);
      FQueryAndHandleSetInventoryVersion(Query);
      FQueryAndHandleSetPartsByVersion(Query, CbxInventoryVersion.Text);
    finally
      Query.Free;
      SQLConnection1.Close;
      SQLConnection1.Free;
    end;
  finally
    begin
      //Stopwatch.Stop;
      //Enable for performance testing:
      //ShowMessage('Finished in: ' + IntToStr(Stopwatch.ElapsedMilliseconds) + 'ms');
    end;
  end;

  //load parts
  TThread.Queue(nil,
    procedure
    begin
      try
        //FLoadPartsBySet();
      except
        // Handle exceptions here / delays.
      end;
    end);
end;

procedure TFrmSet.SbSetPartsResize(Sender: TObject);
begin
  TmrRefresh.Enabled := False;
  TmrRefresh.Enabled := True;
end;

procedure TFrmSet.TmrRefreshTimer(Sender: TObject);
begin
  // Don't redraw until mouse is up
  if (GetKeyState(VK_LBUTTON) and $8000) = 0 then begin
    TmrRefresh.Enabled := False;

    // Get the size without scrollbars
    var CurWidth := SbSetParts.ClientWidth;

    var MinimumPanelWidth := PnlTemplateResult.Width;
    var MaxCols := Floor(CurWidth/MinimumPanelWidth);
    //FCurMaxCols should be calculated on formShow, make it -1 for now.
    if (FCurMaxCols = -1) or (FCurMaxCols <> MaxCols) then begin
      // Move stuff around a lot
      var RowIndex := 0;
      var ColIndex := 0;
      for var ResultPanel:TPanel in FInventoryPanels do begin
        ResultPanel.Top := 0 + PnlTemplateResult.Height * RowIndex;
        ResultPanel.Left := 0 + PnlTemplateResult.Width * ColIndex;

        Inc(ColIndex);
        if ColIndex >= MaxCols then begin
          Inc(RowIndex);
          ColIndex := 0;
        end;
      end;

      // Update the current value to reduce unneeded dialog redrawing
      FCurMaxCols := MaxCols;
    end else begin
      // See if we can widen the existing cols a little.
    end;
  end;
end;

end.
