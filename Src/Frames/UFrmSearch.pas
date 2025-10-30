unit UFrmSearch;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  Contnrs, USet,
  FireDAC.Stan.Param,
  System.ImageList, Vcl.ImgList, Vcl.ExtCtrls, Vcl.Imaging.pngimage,
  UImageCache, Vcl.Grids, Vcl.Menus, System.Actions, Vcl.ActnList;

type
  TFrmSearch = class(TForm)
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
    EditSearchText: TEdit;
    ImgSearch: TImage;
    Label6: TLabel;
    Label7: TLabel;
    LblSearch: TLabel;
    LblTrackResultLimit: TLabel;
    TrackResultLimit: TTrackBar;
    Label2: TLabel;
    SbResults: TStatusBar;
    DgSets: TDrawGrid;
    BtnFilter: TButton;
    ImageList1: TImageList;
    CbxThemes: TComboBox;
    Label1: TLabel;
    Label8: TLabel;
    TbGridSize: TTrackBar;
    ActionList1: TActionList;
    ActToggleIncludeSpareParts: TAction;
    ActToggleAscending: TAction;
    ActSortByTheme: TAction;
    ActSortBySetNum: TAction;
    ActSortByPartCount: TAction;
    ActSortByYear: TAction;
    ActViewSetExternal: TAction;
    PopPartsFilter: TPopupMenu;
    Sort1: TMenuItem;
    Ascending1: TMenuItem;
    N1: TMenuItem;
    Sort2: TMenuItem;
    Hue1: TMenuItem;
    Part1: TMenuItem;
    Category1: TMenuItem;
    ShowSetNum: TMenuItem;
    ActSortByName: TAction;
    Name1: TMenuItem;
    ActShowSetName: TAction;
    ActShowSetNum: TAction;
    ActShowIcons: TAction;
    ActShowTheme: TAction;
    ActShowYear: TAction;
    ActShowYear1: TMenuItem;
    ActShowIcons1: TMenuItem;
    Setname1: TMenuItem;
    heme1: TMenuItem;
    ImageList2: TImageList;
    PopGridRightClick: TPopupMenu;
    Viewsetexternally1: TMenuItem;
    ActViewSet: TAction;
    Viewset1: TMenuItem;
    ActAddSetToCollection: TAction;
    ActAddSetToCollection1: TMenuItem;
    N2: TMenuItem;
    ActViewParts: TAction;
    Viewparts1: TMenuItem;
    N3: TMenuItem;
    TbGridSizePx: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ImgSearchClick(Sender: TObject);
    procedure HandleKeyPress(Sender: TObject; var Key: Char);
    procedure FormDestroy(Sender: TObject);
    //procedure ImgShowSetClick(Sender: TObject);
//    procedure ImgAddSetClick(Sender: TObject);
    procedure SbSearchResultsMouseWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure SbSearchResultsMouseWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure TrackChange(Sender: TObject);
    procedure BtnExpandOptionsClick(Sender: TObject);
    procedure DgSetsClick(Sender: TObject);
    procedure DgSetsDblClick(Sender: TObject);
    procedure DgSetsDrawCell(Sender: TObject; ACol, ARow: LongInt; Rect: TRect; State: TGridDrawState);
    procedure DgSetsMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormResize(Sender: TObject);
    procedure TbGridSizeChange(Sender: TObject);
    procedure DgSetsMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure DgSetsMouseLeave(Sender: TObject);
    procedure DgSetsSelectCell(Sender: TObject; ACol, ARow: LongInt; var CanSelect: Boolean);
    procedure ActViewSetExecute(Sender: TObject);
    procedure ActViewPartsExecute(Sender: TObject);
    procedure ActViewSetExternalExecute(Sender: TObject);
    procedure ActAddSetToCollectionExecute(Sender: TObject);
  private
    { Private declarations }
    FSetObjectList: TSetObjectList; // Stored locally from query result.
    FResultPanels: TObjectList;
    FImageCache: TImageCache;
    //FCurMaxCols: Integer;
    FLastMaxCols: Integer;
    procedure FDoSearch;
    function FGetFromYear(): Integer;
    function FGetToYear(): Integer;
    function FGetFromParts(): Integer;
    function FGetToParts(): Integer;
    procedure FAdjustGrid();
    function FGetIndexByRowAndCol(ACol, ARow: LongInt): Integer;
  public
    { Public declarations }
    property ImageCache: TImageCache read FImageCache write FImageCache;
  end;

implementation

{$R *.dfm}

uses
  Math, Diagnostics, System.Types,
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

  //View External types:
  cTYPESET = 0;
  cTYPEPART = 1;
  //cTYPEMINIFIG = 2; //Not used yet

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
  //PnlTemplateResult.Parent := nil;
//  PnlTemplateResult.Visible := False;

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

  FSetObjectList := TSetObjectList.Create;

//  SbSearchResults.UseWheelForScrolling := True;
  BtnExpandOptionsClick(Self);

  DgSets.DefaultColWidth := TbGridSize.Position;
  if DgSets.DefaultColWidth >= 64 then begin
    if PnlSearchOptions.Visible then
      DgSets.DefaultRowHeight := TbGridSize.Position + 40 // 64 + 20 + 20 //todo: make extra info rows optional
    else
      DgSets.DefaultRowHeight := TbGridSize.Position + 20; // 64 + 20
  end else
    DgSets.DefaultRowHeight := TbGridSize.Position;
  DgSets.FixedCols := 0;
  DgSets.FixedRows := 0;

  TbGridSizePx.Caption := IntToStr(TbGridSize.Position) + 'px';

  FLastMaxCols := -1;
  FAdjustGrid;
end;

procedure TFrmSearch.FormDestroy(Sender: TObject);
begin
  FResultPanels.Free;
  FSetObjectList.Free;

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
  DgSets.Anchors := [TAnchorKind.akLeft, TAnchorKind.akTop, TAnchorKind.akRight, TAnchorKind.akBottom];

  TrackChange(Self);

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

procedure TFrmSearch.FAdjustGrid();
begin
  // recalculate visible column and rowcount for DgSetParts
  if FSetObjectList.Count = 0 then begin
    DgSets.ColCount := 0;
    DgSets.RowCount := 0;
  end else
    DgSets.ColCount := Max(1, Floor(DgSets.ClientWidth div (DgSets.DefaultColWidth+1)));

  if DgSets.ColCount <> FLastMaxCols then begin
    DgSets.RowCount := Ceil(FSetObjectList.Count / DgSets.ColCount);
    FLastMaxCols := DgSets.ColCount;
    DgSets.Invalidate;
  end;

  FLastMaxCols := DgSets.ColCount;
end;

procedure TFrmSearch.FormResize(Sender: TObject);
begin
  FAdjustGrid;
end;

procedure TFrmSearch.TbGridSizeChange(Sender: TObject);
begin
  DgSets.DefaultColWidth := TbGridSize.Position;
  if DgSets.DefaultColWidth >= 64 then begin
    if PnlSearchOptions.Visible then
      DgSets.DefaultRowHeight := TbGridSize.Position + 40 // 64 + 20 + 20 //todo: make extra info rows optional
    else
      DgSets.DefaultRowHeight := TbGridSize.Position + 20; // 64 + 20
  end else
    DgSets.DefaultRowHeight := TbGridSize.Position;
  FAdjustGrid;

  TbGridSizePx.Caption := IntToStr(TbGridSize.Position) + 'px';
end;

procedure TFrmSearch.BtnExpandOptionsClick(Sender: TObject);
begin
  var OldTop := DgSets.Top;
  PnlSearchOptions.Visible := not PnlSearchOptions.Visible;
  if PnlSearchOptions.Visible then begin
    DgSets.Top := PnlSearchOptions.Top + PnlSearchOptions.Height + 2;
    DgSets.Height := DgSets.Height - (DgSets.Top-OldTop);
  end else begin
    DgSets.Top := PnlSearchOptions.Top;
    DgSets.Height := DgSets.Height + (OldTop-DgSets.Top);
  end;

  if PnlSearchOptions.Visible then
    DgSets.DefaultRowHeight := TbGridSize.Position + 40 // 64 + 20 + 20 //todo: make extra info rows optional
  else
    DgSets.DefaultRowHeight := TbGridSize.Position + 20; // 64 + 20

  DgSets.Invalidate;
end;

procedure TFrmSearch.DgSetsClick(Sender: TObject);
begin
  //determine if special buttons are active, and where they are shown.
end;

function TFrmSearch.FGetIndexByRowAndCol(ACol, ARow: LongInt): Integer;
begin
  // Get the index of the visible item in the bjectList.
  Result := (ARow * DgSets.ColCount) + ACol;
end;

procedure TFrmSearch.DgSetsDrawCell(Sender: TObject; ACol, ARow: LongInt; Rect: TRect; State: TGridDrawState);
//var
//  SquareRect: TRect;
  //ExampleText: String;
begin
  var Idx := FGetIndexByRowAndCol(ACol, ARow);
  if (Idx >= 0) and (Idx<FSetObjectList.Count) then begin
    var SetObject := FSetObjectList[Idx];
    var ImageUrl := SetObject.SetImgUrl;

    //TPicture
    if FImageCache <> nil then begin
      var Picture := FImageCache.GetImage(ImageUrl);
      if Assigned(Picture) and Assigned(Picture.Graphic) then begin
        // Center the image in the cell (optional)
  //      var ImgLeft := Rect.Left + (Rect.Width - Picture.Width) div 2;
  //      var ImgTop := Rect.Top + (Rect.Height - Picture.Height) div 2;
        var ImageRect := Rect;
        if DgSets.DefaultColWidth >= 64 then begin
          if PnlSearchOptions.Visible then
            ImageRect.Bottom := ImageRect.Bottom - 40 // 64 -20 -20
          else
            ImageRect.Bottom := ImageRect.Bottom - 20;
        end;
        DgSets.Canvas.StretchDraw(ImageRect, Picture.Graphic);
  //      DgSetParts.Canvas.StretchDraw(Rect, Picture.Graphic);
      end;
    end;

    DgSets.Canvas.Brush.Style := bsClear;
    //ExampleText := Format('Cell %d,%d', [ACol, ARow]);
{    if SetObject.IsSpare then
      ExampleText := Format('%dx*', [SetObject.Quantity])
    else
      ExampleText := Format('%dx', [SetObject.Quantity]); // todo: 999/999
}

    if DgSets.DefaultColWidth >= 64 then begin    
      if PnlSearchOptions.Visible then
        DgSets.Canvas.TextOut(Rect.Left+2, Rect.Bottom - 38, SetObject.SetNum)
      else
        DgSets.Canvas.TextOut(Rect.Left+2, Rect.Bottom - 18, SetObject.SetNum);
    end;

    if DgSets.DefaultColWidth >= 32 then begin
      // "More info" icon
      //ImageList1.Draw(DgSets.Canvas, Rect.Right - 18, Rect.Bottom - 18, 1, True);
    end;

    // Inforow 2
    if PnlSearchOptions.Visible then begin
      if DgSets.DefaultColWidth >= 48 then begin
        DgSets.Canvas.TextOut(Rect.Left+2, Rect.Bottom - 18, IntToStr(SetObject.SetYear));
        if DgSets.DefaultColWidth >= 64 then begin
          var SetNumPartsText := IntToStr(SetObject.SetNumParts);
          var TextWidth := DgSets.Canvas.TextWidth(SetNumPartsText);
          DgSets.Canvas.TextOut(Rect.Right-TextWidth-2, Rect.Bottom - 18, SetNumPartsText);
        end;
      end;
    end;
  end;
end;

procedure TFrmSearch.DgSetsMouseLeave(Sender: TObject);
begin
// reset cursor
end;

procedure TFrmSearch.DgSetsMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
// check where mouse is, and change cursor if needed
end;

procedure TFrmSearch.DgSetsMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbRight then begin
    // select row/col - because the default menu handler doesn't do this
    var Col, Row: Integer;
    DgSets.MouseToCell(X, Y, Col, Row);
    if (Col >= 0) and (Row >= 0) then
      DgSets.Selection := TGridRect(Rect(Col, Row, Col, Row));

    var Idx := FGetIndexByRowAndCol(Col, Row);
    if (Idx >= 0) and (Idx<FSetObjectList.Count) then begin
      // show context menu:
      var Pt := Point(X, Y);
      Pt := DgSets.ClientToScreen(Pt);
      PopGridRightClick.Popup(Pt.X, Pt.Y);
      // open / add to set list / force reload graphic / find in your sets.
    end;
  end;

  //    HandleClick(caRightClick, Sender);
end;

procedure TFrmSearch.DgSetsSelectCell(Sender: TObject; ACol, ARow: LongInt; var CanSelect: Boolean);
begin
  var Idx := FGetIndexByRowAndCol(ACol, ARow);
  if (Idx >= 0) and (Idx<FSetObjectList.Count) then begin
    var SetObject := FSetObjectList[Idx];
    //"40211-1 (partcount), This is a set name (Year) - Theme name"
    var NumParts := '';
    If SetObject.SetNumParts <> 0 then
      NumParts := Format(' (%d)', [SetObject.SetNumParts]);
    var Year := '';
    If SetObject.SetYear <> 0 then
      Year := Format(' (%d)', [SetObject.SetYear]);
    SbResults.Panels[1].Text := Format('%s%s, %s%s%s%s', [SetObject.SetNum, NumParts, SetObject.SetName, Year, IFThen(SetObject.SetThemeName<>'', ' - ', ''), SetObject.SetThemeName]);
  end else
    SbResults.Panels[1].Text := '';
end;

procedure TFrmSearch.FDoSearch;
begin
  if EditSearchText.Text = '' then
    Exit;

  // Hide scrollbox while drawing
//  SbSearchResults.Visible := False;
  try
    // Clean up the list before adding new results
    for var I:=FResultPanels.Count-1 downto 0 do
      FResultPanels.Delete(I);

    FSetObjectList.Clear;

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

        FSetObjectList.LoadFromQuery(FDQuery, False);

        FLastMaxCols := -1; // Force an invalidate
        FAdjustGrid;

        SbResults.Panels[0].Text := 'Results: ' + IntToStr(FSetObjectList.Count);
      finally
        FDQuery.Free;
        FrmMain.ReleaseConnection(SqlConnection);
      end;
    finally
      begin
        //Stopwatch.Stop;
        //Enable for performance testing:
        //ShowMessage('Finished in: ' + IntToStr(Stopwatch.ElapsedMilliseconds) + 'ms');
      end;
    end;
  finally
//    SbSearchResults.Visible := True;
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

procedure TFrmSearch.ActAddSetToCollectionExecute(Sender: TObject);
begin
  var sel := DgSets.Selection;
  var Idx := FGetIndexByRowAndCol(Sel.left, sel.top);
  if (Idx >= 0) and (Idx<FSetObjectList.Count) then begin
    var SetObject := FSetObjectList[Idx];
    var DlgAddToSetList := TDlgAddToSetList.Create(Self);
    try
      DlgAddToSetList.BSSetID := 0; // New
      DlgAddToSetList.SetNum := SetObject.SetNum;
      if DlgAddToSetList.ShowModal = mrOK then begin
        // DlgAddToSetList handles the query.
      end;
    finally
      DlgAddToSetList.Free;
    end;
  end;
end;

procedure TFrmSearch.ActViewSetExternalExecute(Sender: TObject);
begin
  var sel := DgSets.Selection;
  var Idx := FGetIndexByRowAndCol(Sel.left, sel.top);
  if (Idx >= 0) and (Idx<FSetObjectList.Count) then begin
    var SetObject := FSetObjectList[Idx];
    TFrmMain.OpenExternal(cTYPESET, SetObject.SetNum);
  end;
end;

procedure TFrmSearch.ActViewPartsExecute(Sender: TObject);
begin
  // Open parts window
  var sel := DgSets.Selection;
  var Idx := FGetIndexByRowAndCol(Sel.left, sel.top);
  if (Idx >= 0) and (Idx<FSetObjectList.Count) then begin
    var SetObject := FSetObjectList[Idx];
    TFrmMain.ShowPartsWindow(SetObject.SetNum);
  end;
end;

procedure TFrmSearch.ActViewSetExecute(Sender: TObject);
begin
  // Open set
  var sel := DgSets.Selection;
  var Idx := FGetIndexByRowAndCol(Sel.left, sel.top);
  if (Idx >= 0) and (Idx<FSetObjectList.Count) then begin
    var SetObject := FSetObjectList[Idx];
    TFrmMain.ShowSetWindow(SetObject.SetNum);
  end;
end;

procedure TFrmSearch.DgSetsDblClick(Sender: TObject);
begin
  ActViewSet.Execute;
end;
{
procedure TFrmSearch.ImgShowSetClick(Sender: TObject);
begin
  var SetNum := GetSetNumByComponentName(TImage(Sender).Name);
  TFrmMain.ShowSetWindow(SetNum);
end;        }

procedure TFrmSearch.SbSearchResultsMouseWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
begin
// SbSearchResults.UseWheelForScrolling := True;//then
end;

procedure TFrmSearch.SbSearchResultsMouseWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
begin
//
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
