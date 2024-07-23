unit UFrmSearch;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  Contnrs, USet,
  FireDAC.Stan.Param,
  System.ImageList, Vcl.ImgList, Vcl.ExtCtrls, Vcl.Imaging.pngimage,
  UImageCache;

type
  TFrmSearch = class(TForm)
    SbSearchResults: TScrollBox;
    PnlTemplateResult: TPanel;
    ImgTemplateSetImage: TImage;
    ImgAddSet: TImage;
    ImgShowSet: TImage;
    LblTemplateSetNum: TLabel;
    LblTemplateTheme: TLabel;
    LblTemplateYear: TLabel;
    LblTemplatePart: TLabel;
    LblTemplateName: TLabel;
    TmrRefresh: TTimer;
    PnlSearchOptions: TPanel;
    Year: TLabel;
    TrackYearFrom: TTrackBar;
    Label3: TLabel;
    TrackPartsFrom: TTrackBar;
    Label4: TLabel;
    Label5: TLabel;
    TrackYearTo: TTrackBar;
    LblTrackYear: TLabel;
    TrackPartsTo: TTrackBar;
    LblTrackParts: TLabel;
    Panel1: TPanel;
    BtnExpandOptions: TButton;
    CbxSearchStyle: TComboBox;
    CbxSearchWhat: TComboBox;
    CbxThemes: TComboBox;
    EditSearchText: TEdit;
    ImgSearch: TImage;
    Label1: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    LblSearch: TLabel;
    LblTrackResultLimit: TLabel;
    TrackResultLimit: TTrackBar;
    Label2: TLabel;
    StatusBar1: TStatusBar;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ImgSearchClick(Sender: TObject);
    procedure HandleKeyPress(Sender: TObject; var Key: Char);
    procedure FormDestroy(Sender: TObject);
    procedure ImgShowSetClick(Sender: TObject);
    procedure ImgAddSetClick(Sender: TObject);
    procedure SbSearchResultsResize(Sender: TObject);
    procedure SbSearchResultsMouseWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure SbSearchResultsMouseWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure TmrRefreshTimer(Sender: TObject);
    procedure TrackChange(Sender: TObject);
    procedure BtnExpandOptionsClick(Sender: TObject);
  private
    { Private declarations }
    FSetObjects: TSetObjectList; // Stored locally from query result.
    FResultPanels: TObjectList;
    FImageCache: TImageCache;
    FCurMaxCols: Integer;
    procedure FDoSearch;
    function FGetFromYear(): Integer;
    function FGetToYear(): Integer;
    function FGetFromParts(): Integer;
    function FGetToParts(): Integer;
    function FCreateNewResultPanel(const SetObject: TSetObject; AOwner: TComponent; ParentControl: TWinControl; RowIndex, ColIndex: Integer): TPanel;
  public
    { Public declarations }
    property ImageCache: TImageCache read FImageCache write FImageCache;
  end;

implementation

{$R *.dfm}

uses
  Math, Diagnostics,
  Data.DB,
  StrUtils,
  FireDAC.Comp.Client,
  USQLiteConnection,
  UDlgAddToSetList, UDelayedImage,
  DateUtils,
  UFrmMain, UStrings;

const
  // Search locations
  cYourCollections = 0;  // All the things. Locally                   // Generic search
  cDatabase = 1;         // All the things. Database                  //
  cYourSets = 2;         // Just your sets                            // Set search
  cDatabaseSets = 3;     // Sets in the database (imported by csv)    //
  cYourParts = 4;        // Just the parts in your collection         // Parts search
  cDatabaseParts = 5;    // Parts in the database                     //
  cYourMinifigs = 6;     // Your minifigs / minifigs in your sets     // Minifig search
  cDatabaseMinifigs = 7; // Minifigs in the database                  //

  // Search what
  cSetNum = 0;
  cName = 1;
  //cOwnedSetsByNumber = 2;
  //cOwnedSetsByName = 3;

  // Search style for others:
  cSearchAll = 0;    // "%SearchText%" // May find a lot more unrelated stuff
  // Search style for sets:
  cSearchPrefix = 1; // "SearchText%" // Also gets all versions
  cSearchSuffix = 2; // "%SearchText" and "%Searchtext-1" // Find parts of sets
  cSearchExact = 3; // "SearchText"

procedure TFrmSearch.FormCreate(Sender: TObject);
begin
  inherited;

  CbxSearchStyle.Clear;
  CbxSearchStyle.Items.Add(StrSearchAll);
  CbxSearchStyle.Items.Add(StrSearchPrefix);
  CbxSearchStyle.Items.Add(StrSearchSuffix);
  CbxSearchStyle.Items.Add(StrSearchExact);
  CbxSearchStyle.ItemIndex := 0;

  CbxSearchWhat.Clear;
  CbxSearchWhat.Items.Add(StrSearchSetNum);
  CbxSearchWhat.Items.Add(StrSearchName);
  CbxSearchWhat.ItemIndex := 0;

  //This whole dialog is themed for search in sets.
{  CbxSearchType.Clear;
  CbxSearchType.Items.Add(StrSearchSets);
  CbxSearchType.Items.Add(StrSearchMinifigs);
  CbxSearchType.Items.Add(StrSearchParts);
  CbxSearchType.ItemIndex := 0;    }

  // Template used for other results:
  PnlTemplateResult.Parent := nil;
  PnlTemplateResult.Visible := False;

//  EditPartsFrom.Text := '0';
//  EditPartsTo.Text := '9000';
//  EditYearFrom.Text := '1945';
//  EditYearTo.Text := '2050';

  // Ensure the year track has enough space for coming year.
  var yearsSince1945 := YearOf(Now) - 1945+1;
  var numYearTicks := yearsSince1945/10;
  TrackYearFrom.Max := Round(numYearTicks+0.5);
  TrackYearTo.Max := TrackYearFrom.Max;

  FResultPanels := TObjectList.Create;
  FResultPanels.OwnsObjects := True;

  FSetObjects := TSetObjectList.Create;

  SbSearchResults.UseWheelForScrolling := True;
  BtnExpandOptionsClick(Self);
end;

procedure TFrmSearch.FormDestroy(Sender: TObject);
begin
  FResultPanels.Free;
  FSetObjects.Free;

  inherited;
end;

procedure TFrmSearch.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
  inherited;
end;

procedure TFrmSearch.FormShow(Sender: TObject);
begin
  inherited;
  EditSearchText.SetFocus;

  // Research this more later - mdi child anchors are weird.
  Width := 640;
  Height := 480;
  SbSearchResults.Anchors := [TAnchorKind.akLeft,TAnchorKind.akTop, TAnchorKind.akRight, TAnchorKind.akBottom];

  TrackChange(Self);

  var CurWidth := SbSearchResults.ClientWidth;
  var MinimumPanelWidth := PnlTemplateResult.Width;
  FCurMaxCols := Floor(CurWidth/MinimumPanelWidth);

  // Fill the theme pulldown - just main themes for now. No sub themes.
  var SqlConnection := FrmMain.AcquireConnection;
  var FDQuery := TFDQuery.Create(nil);
  CbxThemes.Clear;
  CbxThemes.Items.BeginUpdate;
  CbxThemes.Items.AddObject('(' + StrAny + ')', TObject(0));
  try
    FDQuery.Connection := SqlConnection;

    // Substring because some value has more than 40 characters, firedac moans about it when retrieving data.
    FDQuery.SQL.Text := 'SELECT t.id as id, substr(t.name,1,40) as name, pt.name AS ptname, t.parent_id as ptid FROM themes t' +
                        ' LEFT JOIN themes pt ON pt.id = t.parent_id' +
                        ' ORDER BY t.name';
    FDQuery.Open;

    while not FDQuery.Eof do begin
      var ThemeName := FDQuery.FieldByName('name').AsString;
      var ParentThemeName := FDQuery.FieldByName('ptname').AsString;
      var ThemeID := FDQuery.FieldByName('id').AsInteger;

      var DisplayName := '';
      if ParentThemeName <> '' then
        DisplayName := Format('%s (%s)', [ThemeName, ParentThemeName])
      else
        DisplayName := ThemeName;

      CbxThemes.Items.AddObject(DisplayName, TObject(ThemeID));

      FDQuery.Next; // Move to the next row
    end;
  finally
    CbxThemes.ItemIndex := 0;
    CbxThemes.Items.EndUpdate;
    FDQuery.Free;
    FrmMain.ReleaseConnection(SqlConnection);
  end;

  CbxThemes.DropDownWidth := CbxThemes.DropDownWidth * 2;
end;

procedure TFrmSearch.BtnExpandOptionsClick(Sender: TObject);
begin
  var OldTop := SbSearchResults.Top;
  PnlSearchOptions.Visible := not PnlSearchOptions.Visible;
  if PnlSearchOptions.Visible then begin
    SbSearchResults.Top := PnlSearchOptions.Top + PnlSearchOptions.Height + 2;
    SbSearchResults.Height := SbSearchResults.Height - (SbSearchResults.Top-OldTop);
  end else begin
    SbSearchResults.Top := PnlSearchOptions.Top;
    SbSearchResults.Height := SbSearchResults.Height + (OldTop-SbSearchResults.Top);
  end;
end;

function TFrmSearch.FCreateNewResultPanel(const SetObject: TSetObject; AOwner: TComponent; ParentControl: TWinControl; RowIndex, ColIndex: Integer): TPanel;
begin
  Result := TPanel.Create(AOwner);
  Result.Width := PnlTemplateResult.Width;
  Result.Height := PnlTemplateResult.Height;
  Result.Top := 0 + PnlTemplateResult.Height * RowIndex;
  Result.Left := 0 + PnlTemplateResult.Width * ColIndex;

  for var i := 0 to PnlTemplateResult.ControlCount - 1 do begin
    var Control: TObject;
    if (PnlTemplateResult.Controls[i].ClassType = TImage) and SameText(PnlTemplateResult.Controls[i].Name, 'ImgTemplateSetImage') then
      Control := TDelayedImage.Create(Self)
    else
      Control := PnlTemplateResult.Controls[i].ClassType.Create;

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

      if SameText(TemplateLabel.Name, 'LblTemplateSetNum') then
        NewLabel.Caption := SetObject.SetNum
      //else if SameText(TemplateLabel.Name, 'LblTemplateTheme') then
        //NewLabel.Caption := SetObject.ThemeID
      else if SameText(TemplateLabel.Name, 'LblTemplateYear') then
        NewLabel.Caption := IntToStr(SetObject.SetYear)
      else if SameText(TemplateLabel.Name, 'LblTemplatePart') then
        NewLabel.Caption := 'p: ' + IntToStr(SetObject.SetNumParts)
      else if SameText(TemplateLabel.Name, 'LblTemplateName') then
        NewLabel.Caption := SetObject.SetName //Query.FieldByName('name').AsString
      else
        NewLabel.Caption := TemplateLabel.Caption;

    end else if Control.ClassType = TDelayedImage then begin
      // Special handling for bigger images
      var TemplateImage := TImage(PnlTemplateResult.Controls[i]);
      var NewImage := TDelayedImage.Create(Result);

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
        NewImage.Name := TemplateImage.Name + '_' + StringReplace(SetObject.SetNum, '-', '_', [rfReplaceAll]);
      end;

      NewImage.ImageCache := FImageCache;
      NewImage.Url := SetObject.SetImgUrl;
      NewImage.LoadState := LSNone;
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
        NewImage.Name := TemplateImage.Name + '_' + StringReplace(SetObject.SetNum, '-', '_', [rfReplaceAll]);
      end;

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

procedure TFrmSearch.FDoSearch;
begin
  if EditSearchText.Text = '' then
    Exit;

  // Hide scrollbox while drawing
  SbSearchResults.Visible := False;
  try
    // Clean up the list before adding new results
    for var I:=FResultPanels.Count-1 downto 0 do
      FResultPanels.Delete(I);

    FSetObjects.Clear;

    //Get tickcount for performance monitoring.
    //var Stopwatch := TStopWatch.Create;
    //Stopwatch.Start;
    try
      var SqlConnection := FrmMain.AcquireConnection;
      var FDQuery := TFDQuery.Create(nil);
      try
        var SearchSubject := '';
        if CbxSearchWhat.ItemIndex = cSetNum then
          SearchSubject := 'set_num'
        else
          SearchSubject := 'name';

        var SearchLikeOrExact := '';
        if CbxSearchStyle.ItemIndex = cSearchExact then
          SearchLikeOrExact := '='
        else
          SearchLikeOrExact := 'like';

        // Set up the query
        FDQuery.Connection := SqlConnection;
        FDQuery.SQL.Text := 'SELECT set_num, name, year, img_url, num_parts' + //, theme_id
                            ' FROM Sets where (year between :fromyear and :toyear) AND' +
                            ' (num_parts BETWEEN :fromparts AND :toparts) AND ((' + SearchSubject + ' ' + SearchLikeOrExact + ' :Param1)';
        if CbxSearchStyle.ItemIndex in [cSearchSuffix, cSearchExact] then
          FDQuery.SQL.Text := FDQuery.SQL.Text + ' OR (' + SearchSubject + ' ' + SearchLikeOrExact + ' :Param2)';
        FDQuery.SQL.Text := FDQuery.SQL.Text + ')';

        var ThemeID := 0;
        if CbxThemes.ItemIndex <> 0 then begin
          ThemeID := Integer(CbxThemes.Items.Objects[CbxThemes.ItemIndex]);
          if ThemeID > 0 then
            FDQuery.SQL.Text := FDQuery.SQL.Text + ' AND theme_id = :themeid';
        end;

        FDQuery.SQL.Text := FDQuery.SQL.Text + ' LIMIT ' + IntToStr(10 + TrackResultLimit.Position * 10);

        var Params := FDQuery.Params;
        var SearchValue1 := EditSearchText.Text;
        if CbxSearchStyle.ItemIndex = cSearchAll then
          SearchValue1 := '%' + EditSearchText.Text + '%'
        else if CbxSearchStyle.ItemIndex = cSearchPrefix then
          SearchValue1 := EditSearchText.Text + '%'
        else if CbxSearchStyle.ItemIndex = cSearchSuffix then
          SearchValue1 := '%' + EditSearchText.Text
        else
          SearchValue1 := EditSearchText.Text;

        var SearchValue2 := SearchValue1 + '-1';
        Params.ParamByName('Param1').AsString := SearchValue1;

        if CbxSearchStyle.ItemIndex in [cSearchSuffix, cSearchExact] then
          Params.ParamByName('Param2').AsString := SearchValue2;

        Params.ParamByName('fromyear').AsInteger := FGetFromYear;
        Params.ParamByName('toyear').AsInteger := FGetToYear;
        Params.ParamByName('fromparts').AsInteger := FGetFromParts;
        Params.ParamByName('toparts').AsInteger := FGetToParts;
        if ThemeID > 0 then
          Params.ParamByName('themeid').AsInteger := ThemeID;

        FDQuery.Open;

        while not FDQuery.Eof do begin
          // Fill with TSetObject (not all fields are used) so we can close the query sooner and fill the panels in a thread.
          var SetObject := TSetObject.Create;
          SetObject.SetNum := FDQuery.FieldByName('set_num').AsString;
          SetObject.SetName := FDQuery.FieldByName('name').AsString;
          SetObject.SetYear := FDQuery.FieldByName('year').AsInteger;
          //SetObject.SetThemeID := FDQuery.FieldByName('theme_id').AsString;
          //SetObject.SetThemeName := FDQuery.FieldByName('name_1').AsString;
          SetObject.SetNumParts := FDQuery.FieldByName('num_parts').AsInteger;
          SetObject.SetImgUrl := FDQuery.FieldByName('img_url').AsString;
          //SetObject.Quantity := FDQuery.FieldByName('name_1').AsString;
          //SetObject.IncludeSpares := FDQuery.FieldByName('includespares').AsString;
          //SetObject.Built := FDQuery.FieldByName('built').AsString;
          //SetObject.Note := FDQuery.FieldByName('note').AsString;
          FSetObjects.Add(SetObject);

          FDQuery.Next; // Move to the next row
        end;
      finally
        FDQuery.Free;
        FrmMain.ReleaseConnection(SqlConnection);
      end;

      var RowIndex := 0;
      var ColIndex := 0;

      // Hide object, and show it when done - so we only draw once.
      SbSearchResults.Visible := False;
      try
        for var SetObject in FSetObjects do begin
          var ResultPanel := FCreateNewResultPanel(SetObject, SbSearchResults, SbSearchResults, RowIndex, ColIndex);
          ResultPanel.Parent := SbSearchResults;

          FResultPanels.Add(ResultPanel);

          Inc(ColIndex);
          if ColIndex >= FCurMaxCols then begin
            Inc(RowIndex);
            ColIndex := 0;
          end;
        end;
      finally
        SbSearchResults.Visible := True; // Only draw once
      end;
    finally
      begin
        //Stopwatch.Stop;
        //Enable for performance testing:
        //ShowMessage('Finished in: ' + IntToStr(Stopwatch.ElapsedMilliseconds) + 'ms');
      end;
    end;
  finally
    SbSearchResults.Visible := True;
  end;
end;

procedure TFrmSearch.HandleKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then // #13 = Enter
    FDoSearch;
end;

procedure TFrmSearch.ImgSearchClick(Sender: TObject);
begin
  FDoSearch;
end;

function GetSetNumByComponentName(ComponentName: String): String;
begin
  //move this to a utility class / generic function
  Result := '';
  try
    var SplittedString := ComponentName.Split(['_']);
    if High(SplittedString) > 1 then begin
      Result := SplittedString[1] + '-' + SplittedString[2];
      //Add set to collections by setnum
    end;
  except
    // Log error.
  end;
end;

procedure TFrmSearch.ImgAddSetClick(Sender: TObject);
begin
  var SetNum := GetSetNumByComponentName(TImage(Sender).Name);
  //Open the dialog to add the set to inventory
  //Post message to update the inventory if it's open
  var DlgAddToSetList := TDlgAddToSetList.Create(Self);
  try
    DlgAddToSetList.SetNum := SetNum;
    if DlgAddToSetList.ShowModal = mrOK then begin
    //TODO
      //perform query insert
      //Add SetNum
      //postmessate to frmmain to update ufrmsetlist if it's open and the set got added to the active setlist
    end;
  finally
    DlgAddToSetList.Free;
  end;
end;

procedure TFrmSearch.ImgShowSetClick(Sender: TObject);
begin
  var SetNum := GetSetNumByComponentName(TImage(Sender).Name);
  TFrmMain.ShowSetWindow(SetNum);
end;

procedure TFrmSearch.SbSearchResultsMouseWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
begin
 SbSearchResults.UseWheelForScrolling := True;//then
end;

procedure TFrmSearch.SbSearchResultsMouseWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
begin
//
end;

procedure TFrmSearch.SbSearchResultsResize(Sender: TObject);
begin
  TmrRefresh.Enabled := False;
  TmrRefresh.Enabled := True;
end;

procedure TFrmSearch.TmrRefreshTimer(Sender: TObject);
begin
  // Don't redraw until mouse is up
  if (GetKeyState(VK_LBUTTON) and $8000) = 0 then begin
    TmrRefresh.Enabled := False;
    // Get the size without scrollbars
    var CurWidth := SbSearchResults.ClientWidth;

    var MinimumPanelWidth := PnlTemplateResult.Width;
    var MaxCols := Floor(CurWidth/MinimumPanelWidth);
    //FCurMaxCols should be calculated on formShow, make it -1 for now.
    if (FCurMaxCols = -1) or (FCurMaxCols <> MaxCols) then begin

      SendMessage(SbSearchResults.Handle, WM_SETREDRAW, 0, 0);
      try
        // Move stuff around a lot
        var RowIndex := 0;
        var ColIndex := 0;
        for var ResultPanel:TPanel in FResultPanels do begin
          //
          ResultPanel.Top := 0 + PnlTemplateResult.Height * RowIndex;
          ResultPanel.Left := 0 + PnlTemplateResult.Width * ColIndex;

          Inc(ColIndex);
          if ColIndex >= MaxCols then begin
            Inc(RowIndex);
            ColIndex := 0;
          end;
        end;
      finally
        SendMessage(SbSearchResults.Handle, WM_SETREDRAW, 1, 0);
        RedrawWindow(SbSearchResults.Handle, nil, 0, RDW_ERASE or RDW_INVALIDATE or RDW_FRAME or RDW_ALLCHILDREN);
      end;

      // Update the current value to reduce unneeded dialog redrawing
      FCurMaxCols := MaxCols;
    end else begin
      // See if we can widen the existing cols a little.
    end;
  end;
end;

function TFrmSearch.FGetFromYear(): Integer;
begin
  Result := 1945 + TrackYearFrom.Position * 10;
end;

function TFrmSearch.FGetToYear(): Integer;
begin
  var CurrentYear := YearOf(Now);
  var ToYear := 1945 + TrackYearTo.Position * 10;

  if ToYear > CurrentYear then
    Result := CurrentYear+1
  else
    Result := ToYear;
end;

function TFrmSearch.FGetFromParts(): Integer;
begin
  Result := TrackPartsFrom.Position * 500;
end;

function TFrmSearch.FGetToParts(): Integer;
begin
  var ToParts := TrackPartsTo.Position * 500;

  Result := IfThen(TrackPartsTo.Position = TrackPartsTo.Max, 9999, ToParts);
end;

procedure TFrmSearch.TrackChange(Sender: TObject);
begin
  LblTrackResultLimit.Caption := IntToStr(10 + TrackResultLimit.Position * 10);

  // Restrict year selections so they can't have the same value.
  if TrackYearFrom.Position >= TrackYearTo.Position then begin
    if Sender = TrackYearFrom then
      TrackYearFrom.Position := TrackYearTo.Position-1;
    if Sender = TrackYearTo then
      TrackYearTo.Position := TrackYearFrom.Position+1;
  end;
  // Restrict parts selection
  if TrackPartsFrom.Position >= TrackPartsTo.Position then begin
    if Sender = TrackPartsFrom then
      TrackPartsFrom.Position := TrackPartsTo.Position-1;
    if Sender = TrackPartsTo then
      TrackPartsTo.Position := TrackPartsFrom.Position+1;
  end;

  LblTrackYear.Caption := IntToStr(FGetFromYear) + '-' + IntToStr(FGetToYear);

  var ToParts := FGetToParts;

  LblTrackParts.Caption := IntToStr(FGetFromParts) + '-' +
                           IfThen(ToParts = 9999, 'Any', IntToStr(ToParts));
end;

end.
