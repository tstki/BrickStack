unit UFrmSearch;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  Contnrs, USet, UConfig,
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
    CbxSearchBy: TComboBox;
    EditSearchText: TEdit;
    Label6: TLabel;
    LblSearch: TLabel;
    SbResults: TStatusBar;
    DgSets: TDrawGrid;
    BtnFilter: TButton;
    ImageList1: TImageList;
    CbxThemes: TComboBox;
    Label1: TLabel;
    ActionList1: TActionList;
    ActToggleIncludeSpareParts: TAction;
    ActToggleAscending: TAction;
    ActSortByTheme: TAction;
    ActSortBySetNum: TAction;
    ActSortByPartCount: TAction;
    ActSortByYear: TAction;
    ActViewSetExternal: TAction;
    PopSetsFilter: TPopupMenu;
    Sort1: TMenuItem;
    MnuSortAscending: TMenuItem;
    N1: TMenuItem;
    MnuSortByTheme: TMenuItem;
    MnuSortByNumber: TMenuItem;
    MnuSortByPartCount: TMenuItem;
    MnuSortByYear: TMenuItem;
    MnuShowNumber: TMenuItem;
    ActSortByName: TAction;
    MnuSortByName: TMenuItem;
    ActShowSetNum: TAction;
    ActShowYear: TAction;
    MnuShowYear: TMenuItem;
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
    CbxSearchInMyCollection: TCheckBox;
    Button1: TButton;
    ActSearch: TAction;
    ActExpandFilter: TAction;
    MnuShowQuantity: TMenuItem;
    MnuShowCollectionID: TMenuItem;
    Grid1: TMenuItem;
    MnuGrid64: TMenuItem;
    MnuGrid96: TMenuItem;
    MnuGrid128: TMenuItem;
    MnuGrid256: TMenuItem;
    MnuGrid192: TMenuItem;
    ActSetGridSize64: TAction;
    ActSetGridSize96: TAction;
    ActSetGridSize128: TAction;
    ActSetGridSize192: TAction;
    ActSetGridSize256: TAction;
    ActShowSetQuantity: TAction;
    ActShowCollectionID: TAction;
    Label2: TLabel;
    CbxSearchWhat: TComboBox;
    ActSpecialSearch: TAction;
    Useinspecialsearch1: TMenuItem;
    ActShowPartCount: TAction;
    MnuShowPartCount: TMenuItem;
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
    procedure DgSetsClick(Sender: TObject);
    procedure DgSetsDblClick(Sender: TObject);
    procedure DgSetsDrawCell(Sender: TObject; ACol, ARow: LongInt; Rect: TRect; State: TGridDrawState);
    procedure DgSetsMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormResize(Sender: TObject);
    procedure DgSetsMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure DgSetsMouseLeave(Sender: TObject);
    procedure DgSetsMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure DgSetsSelectCell(Sender: TObject; ACol, ARow: LongInt; var CanSelect: Boolean);
    procedure ActViewSetExecute(Sender: TObject);
    procedure ActViewPartsExecute(Sender: TObject);
    procedure ActViewSetExternalExecute(Sender: TObject);
    procedure ActAddSetToCollectionExecute(Sender: TObject);
    procedure CbxSearchInMyCollectionClick(Sender: TObject);
    procedure BtnFilterClick(Sender: TObject);
    procedure ActSearchExecute(Sender: TObject);
    procedure ActExpandFilterExecute(Sender: TObject);
    procedure ActSetGridSize64Execute(Sender: TObject);
    procedure ActSetGridSize96Execute(Sender: TObject);
    procedure ActSetGridSize128Execute(Sender: TObject);
    procedure ActSetGridSize192Execute(Sender: TObject);
    procedure ActSetGridSize256Execute(Sender: TObject);
    procedure ActSortByThemeExecute(Sender: TObject);
    procedure ActSortBySetNumExecute(Sender: TObject);
    procedure ActSortByPartCountExecute(Sender: TObject);
    procedure ActSortByNameExecute(Sender: TObject);
    procedure ActSortByYearExecute(Sender: TObject);
    procedure ActShowSetNumExecute(Sender: TObject);
    procedure ActShowYearExecute(Sender: TObject);
    procedure ActShowSetQuantityExecute(Sender: TObject);
    procedure ActShowCollectionIDExecute(Sender: TObject);
    procedure ActToggleAscendingExecute(Sender: TObject);
    procedure ActShowPartCountExecute(Sender: TObject);
  private
    { Private declarations }
    FSetObjectList: TSetObjectList; // Stored locally from query result.
    FResultPanels: TObjectList;
    FImageCache: TImageCache;
    FDragStartPoint: TPoint;
    FDraggingStarted: Boolean;
    FConfig: TConfig;
    //FCurMaxCols: Integer;
    FLastMaxCols: Integer;
    procedure FSetConfig(Config: TConfig);
    procedure FDoSearch;
    function FGetFromYear(): Integer;
    function FGetToYear(): Integer;
    function FGetFromParts(): Integer;
    function FGetToParts(): Integer;
    procedure FAdjustGrid();
    function FGetIndexByRowAndCol(ACol, ARow: LongInt): Integer;
    function FGetGridHeight: Integer;
    function FGetGridWidth: Integer;
    procedure FHandleUpdateGridSize(const NewSize: Integer);
    procedure FSaveSortSettings;
    procedure FUncheckAllSortExcept(Sender: TObject);
    procedure FSetDefaultColumnDimensionsAndAdjustGrid;
  public
    { Public declarations }
    property ImageCache: TImageCache read FImageCache write FImageCache;
    property Config: TConfig read FConfig write FSetConfig;
  end;

implementation

{$R *.dfm}

uses
  Math, Diagnostics, System.Types,
  Data.DB,
  StrUtils,
  FireDAC.Comp.Client,
  USQLiteConnection,
  UDlgAddToSetList,
  UDragData,
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
  //cSetNumNameOrTheme = 0;
  cSetNum = 0;
  cName = 1;

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
  CbxSearchWhat.Items.Add(StrSearchSets);
  //StrSearchMinifigures
  //StrSearchParts
  //StrAny
  CbxSearchWhat.ItemIndex := 0;

  CbxSearchBy.Clear;
  CbxSearchBy.Items.Add(StrSearchSetNum);
  CbxSearchBy.Items.Add(StrSearchName);
  CbxSearchBy.ItemIndex := 0;

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
end;

procedure TFrmSearch.FormDestroy(Sender: TObject);
begin
  FConfig.Save(csSEARCHWINDOWFILTERS);

  FResultPanels.Free;
  FSetObjectList.Free;

  inherited;
end;

procedure TFrmSearch.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
  inherited;
end;

procedure TFrmSearch.FSetConfig(Config: TConfig);
begin
  FConfig := Config;

  MnuShowNumber.Checked := FConfig.WSearchShowNumber;
  MnuShowYear.Checked := FConfig.WSearchShowYear;
  MnuShowQuantity.Checked := FConfig.WSearchShowSetQuantity;
  MnuShowCollectionID.Checked := FConfig.WSearchShowCollectionID;
  MnuShowPartCount.Checked := FConfig.WSearchShowPartCount;
  MnuSortAscending.Checked := FConfig.WSearchSortAscending;
  MnuSortByName.Checked := FConfig.WSearchSortByName;
  MnuSortByNumber.Checked := FConfig.WSearchSortByNumber;
  MnuSortByTheme.Checked := FConfig.WSearchSortByTheme;
  MnuSortByPartCount.Checked := FConfig.WSearchSortByPartCount;
  MnuSortByYear.Checked := FConfig.WSearchSortByYear;

  CbxSearchInMyCollection.Checked := FConfig.WSearchMyCollection;

  MnuGrid64.Checked := FConfig.WSearchGridSize = 64;
  MnuGrid96.Checked := FConfig.WSearchGridSize = 96;
  MnuGrid128.Checked := FConfig.WSearchGridSize = 128;
  MnuGrid192.Checked := FConfig.WSearchGridSize = 192;
  MnuGrid256.Checked := FConfig.WSearchGridSize = 256;

  DgSets.DefaultColWidth := FGetGridWidth;
  DgSets.DefaultRowHeight := FGetGridHeight;
  DgSets.FixedCols := 0;
  DgSets.FixedRows := 0;

  FLastMaxCols := -1;
  FAdjustGrid;
end;

procedure TFrmSearch.FormShow(Sender: TObject);
begin
  inherited;
  EditSearchText.SetFocus;

  // Research this more later - mdi child anchors are weird.
  Width := 626;
  Height := 480;
  DgSets.Anchors := [TAnchorKind.akLeft, TAnchorKind.akTop, TAnchorKind.akRight, TAnchorKind.akBottom];

  TrackChange(Self);

  // Wire up mouse handlers used to initiate drags
  DgSets.OnMouseDown := DgSetsMouseDown;
  DgSets.OnMouseMove := DgSetsMouseMove;

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

  ActExpandFilter.Execute;
end;

procedure TFrmSearch.FormResize(Sender: TObject);
begin
  FAdjustGrid;
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

procedure TFrmSearch.FSetDefaultColumnDimensionsAndAdjustGrid;
begin
  DgSets.DefaultColWidth := FGetGridWidth;
  DgSets.DefaultRowHeight := FGetGridHeight;

  FAdjustGrid;
end;

function TFrmSearch.FGetGridHeight: Integer;
begin
  var InfoRowCount := 0;
  if DgSets.DefaultColWidth >= 64 then begin
    if FConfig.WSearchShowNumber then
      Inc(InfoRowCount);
    if FConfig.WSearchShowYear or FConfig.WSearchShowPartCount then
      Inc(InfoRowCount);
    if FConfig.WSearchMyCollection and
      (FConfig.WSearchShowSetQuantity or FConfig.WSearchShowCollectionID) then
      Inc(InfoRowCount);
  end;

  Result := FGetGridWidth + (InfoRowCount*20);
end;

function TFrmSearch.FGetGridWidth: Integer;
begin
  if FConfig = nil then
    Result := 96
  else
    Result := FConfig.WSearchGridSize;
end;

procedure TFrmSearch.BtnFilterClick(Sender: TObject);
begin
  var P := Mouse.CursorPos;
  // Show the popup menu at the mouse cursor position
  PopSetsFilter.Popup(P.X, P.Y);
end;

procedure TFrmSearch.CbxSearchInMyCollectionClick(Sender: TObject);
begin
  FConfig.WSearchMyCollection := CbxSearchInMyCollection.Checked;

  DgSets.DefaultRowHeight := FGetGridHeight;
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
var
  YPosition: Integer;
begin
  var Idx := FGetIndexByRowAndCol(ACol, ARow);
  if (Idx >= 0) and (Idx<FSetObjectList.Count) then begin
    var SetObject := FSetObjectList[Idx];
    var ImageUrl := SetObject.SetImgUrl;

    var InfoRowCount := 0;
    if DgSets.DefaultColWidth >= 64 then begin
      if FConfig.WSearchShowNumber then
        Inc(InfoRowCount);
      if FConfig.WSearchShowYear or FConfig.WSearchShowPartCount then
        Inc(InfoRowCount);
      if FConfig.WSearchMyCollection and
        (FConfig.WSearchShowSetQuantity or FConfig.WSearchShowCollectionID) then
        Inc(InfoRowCount);
    end;

  // set number
  // year                      // part count
  // count of set in bsset     // bssetid

    //TPicture
    if FImageCache <> nil then begin
      var Picture := FImageCache.GetImage(ImageUrl, cidMAX256);
      if Assigned(Picture) and Assigned(Picture.Graphic) then begin
        // Center the image in the cell (optional)
  //      var ImgLeft := Rect.Left + (Rect.Width - Picture.Width) div 2;
  //      var ImgTop := Rect.Top + (Rect.Height - Picture.Height) div 2;
        var ImageRect := Rect;
//        if DgSets.DefaultColWidth >= 64 then begin
//          if PnlSearchOptions.Visible then
//            ImageRect.Bottom := ImageRect.Bottom - 40 // 64 -20 -20
//          else
            ImageRect.Bottom := ImageRect.Bottom - (20*InfoRowCount);
//        end;
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
    // "More info" icon
    //ImageList1.Draw(DgSets.Canvas, Rect.Right - 18, Rect.Bottom - 18, 1, True);

    //visual:
    // count of set in bsset     // bssetid
    // set number
    // year                      // part count

    if DgSets.DefaultColWidth >= 64 then begin
      // Inforow 1
      if FConfig.WSearchShowNumber then
        DgSets.Canvas.TextOut(Rect.Left+2, Rect.Bottom - (InfoRowCount*20) + 2, SetObject.SetNum);

      // Inforow 2
      if FConfig.WSearchShowYear or FConfig.WSearchShowPartCount then begin
        if InfoRowCount = 3 then
          YPosition := Rect.Bottom - 38    // This is the middle row
        else if InfoRowCount = 2 then begin
          if FConfig.WSearchShowNumber then
            YPosition := Rect.Bottom - 18  // This is the bottom row
          else
            YPosition := Rect.Bottom - 38; // This is the top row
        end else // This is the only row.
          YPosition := Rect.Bottom - 18;

        if FConfig.WSearchShowYear then
          DgSets.Canvas.TextOut(Rect.Left+2, YPosition, IntToStr(SetObject.SetYear));
        var SetNumPartsText := IntToStr(SetObject.SetNumParts);
        var TextWidth1 := DgSets.Canvas.TextWidth(SetNumPartsText);
        if FConfig.WSearchShowPartCount then begin
          DgSets.Canvas.TextOut(Rect.Right-TextWidth1-2, YPosition, SetNumPartsText);
        end;
      end;

      // Inforow 3 - Search in my collection - always at the bottom
      if FConfig.WSearchMyCollection and
         (FConfig.WSearchShowSetQuantity or FConfig.WSearchShowCollectionID) then begin
        YPosition := Rect.Bottom - 18;

        if FConfig.WSearchShowSetQuantity then
          DgSets.Canvas.TextOut(Rect.Left+2, YPosition, IntToStr(SetObject.Quantity) + 'x');
        var BSSetID := IntToStr(SetObject.BSSetListID);
        var TextWidth2 := DgSets.Canvas.TextWidth(BSSetID);
        if FConfig.WSearchShowCollectionID then
          DgSets.Canvas.TextOut(Rect.Right-TextWidth2-2, YPosition, BSSetID);
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
  // Start a drag if left button is down and the mouse moved enough
  if (ssLeft in Shift) and not FDraggingStarted then begin
    var dx := Abs(X - FDragStartPoint.X);
    var dy := Abs(Y - FDragStartPoint.Y);
    if (dx >= 6) or (dy >= 6) then begin
      // Determine the cell under the cursor
      var Col, Row: Integer;
      DgSets.MouseToCell(X, Y, Col, Row);
      var Idx := FGetIndexByRowAndCol(Col, Row);
      if (Idx >= 0) and (Idx < FSetObjectList.Count) then begin
        // Populate drag data
        ClearDragData;
        var SetObj := FSetObjectList[Idx];
        if Assigned(SetObj) then begin
          if SetObj.BSSetID <> 0 then
            DraggedBSSetIDs.Add(SetObj.BSSetID)
          else
            DraggedSetNums.Add(SetObj.SetNum);
        end;

        // Start the drag operation. The Source will be the grid control.
        DgSets.BeginDrag(False);
        FDraggingStarted := True;
      end;
    end;
  end;
end;

procedure TFrmSearch.DgSetsMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  // Record starting point for possible drag
  if Button = mbLeft then begin
    FDragStartPoint := Point(X, Y);
    FDraggingStarted := False;
  end;
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
    var MyCollectionInfo := '';
    if FConfig.WSearchMyCollection then
      MyCollectionInfo := Format('%dx in %s', [SetObject.Quantity, SetObject.BSSetListName]);
    SbResults.Panels[1].Text := Format('%s%s, %s%s%s%s%s%s', [SetObject.SetNum, NumParts, SetObject.SetName, Year, IfThen(SetObject.SetThemeName<>'', ' - ', ''), SetObject.SetThemeName, IfThen(MyCollectionInfo <> '', ', ', ''), MyCollectionInfo]);
  end else
    SbResults.Panels[1].Text := '';
end;

procedure TFrmSearch.FDoSearch;
begin
  if EditSearchText.Text = '' then
    Exit;
{
select * from sets where set_num = ‘4200-1’; – one set, 102 parts
select * from inventories where set_num = ‘4200-1’; – 9677

select * from inventory_parts where inventory_id = 9677; – the set inventory

select * from inventory_minifigs where inventory_id = 9677; – fig-001386
select * from inventories where set_num = ‘fig-001386’; – 52201
select * from minifigs where fig_num = ‘fig-001386’; – 1 figure with 5 parts.
select * from inventory_parts where inventory_id = 52201; – the minifig parts

select * from inventory_sets where set_num = ‘4200-1’; – 1726, is the “set box” this set and 4 others are a part of
select * from inventory_sets where inventory_id = 1726; – is a list of sets in a set box
}

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
        if CbxSearchBy.ItemIndex = cSetNum then
          SearchSubject := 's.set_num'
        else // cName
          SearchSubject := 's.name';
        //cSetNumNameOrTheme
        // special handling

        var SearchLikeOrExact := '';
        if CbxSearchStyle.ItemIndex = cSearchExact then
          SearchLikeOrExact := '='
        else
          SearchLikeOrExact := 'LIKE';

        // Set up the query
        FDQuery.Connection := SqlConnection;

        var ThemeID := 0;

        // Build the query
        if FConfig.WSearchMyCollection then begin
          FDQuery.SQL.Text := 'SELECT s.set_num, s.name, s.year, s.img_url, s.num_parts, bss.BSSetListID, bl.name AS BSSetListName, count(*) AS quantity' + //, theme_id
                              ' FROM BSSets bss'+
                              ' LEFT JOIN Sets s on BSS.set_num = s.set_num' +
                              ' INNER JOIN BSSetLists bl on bl.id = bss.BSSetListID' +
                              ' WHERE (year between :fromyear and :toyear) AND' +
                              ' (s.num_parts BETWEEN :fromparts AND :toparts) AND' +
                              ' ((' + SearchSubject + ' ' + SearchLikeOrExact + ' :Param1)';
          if CbxSearchStyle.ItemIndex in [cSearchSuffix, cSearchExact] then
            FDQuery.SQL.Text := FDQuery.SQL.Text + ' OR (' + SearchSubject + ' ' + SearchLikeOrExact + ' :Param2)';
          FDQuery.SQL.Text := FDQuery.SQL.Text + ')';

          if CbxThemes.ItemIndex <> 0 then begin
            ThemeID := Integer(CbxThemes.Items.Objects[CbxThemes.ItemIndex]);
            if ThemeID > 0 then
              FDQuery.SQL.Text := FDQuery.SQL.Text + ' AND s.theme_id = :themeid';
          end;

          FDQuery.SQL.Text := FDQuery.SQL.Text + ' AND s.set_num IN (SELECT bs.set_num from BSSets bs WHERE' +
                                                 ' ((' + SearchSubject + ' ' + SearchLikeOrExact + ' :Param1)';
          if CbxSearchStyle.ItemIndex in [cSearchSuffix, cSearchExact] then
            FDQuery.SQL.Text := FDQuery.SQL.Text + ' OR (' + SearchSubject + ' ' + SearchLikeOrExact + ' :Param2)';
          FDQuery.SQL.Text := FDQuery.SQL.Text + '))' +
                                                 ' GROUP BY bss.BSSetListID, s.set_num ';
        end else begin
          FDQuery.SQL.Text := 'SELECT s.set_num, s.name, s.year, s.img_url, s.num_parts' + //, theme_id
                              ' FROM Sets s WHERE (year between :fromyear and :toyear) AND' +
                              ' (s.num_parts BETWEEN :fromparts AND :toparts) AND' +
                              ' ((' + SearchSubject + ' ' + SearchLikeOrExact + ' :Param1)';
          if CbxSearchStyle.ItemIndex in [cSearchSuffix, cSearchExact] then
            FDQuery.SQL.Text := FDQuery.SQL.Text + ' OR (' + SearchSubject + ' ' + SearchLikeOrExact + ' :Param2)';
          FDQuery.SQL.Text := FDQuery.SQL.Text + ')';

          if CbxThemes.ItemIndex <> 0 then begin
            ThemeID := Integer(CbxThemes.Items.Objects[CbxThemes.ItemIndex]);
            if ThemeID > 0 then
              FDQuery.SQL.Text := FDQuery.SQL.Text + ' AND s.theme_id = :themeid';
          end;
        end;

        //order by
        var SortSql := '';
        if FConfig.WSearchSortByNumber then
          SortSql := 's.set_num'
        else if FConfig.WSearchSortByName then
          SortSql := 's.name'
        else if FConfig.WSearchSortByYear then
          SortSql := 's.year'
        else if FConfig.WSearchSortByTheme then
          SortSql := 's.theme_id'
        else if FConfig.WSearchSortByPartCount then
          SortSql := 's.num_parts';

        if SortSql <> '' then begin
          if FConfig.WPartsSortAscending then
            SortSql := 'ORDER BY ' + SortSql + ' ASC'
          else
            SortSql := 'ORDER BY ' + SortSql + ' DESC';
        end;

        if FConfig.WSearchMyCollection then begin
          if SortSql <> '' then
            SortSql := SortSql + ', s.set_num, bss.bssetlistid'
          else
            SortSql := 'ORDER BY s.set_num, bss.bssetlistid';
        end;

        FDQuery.SQL.Text := FDQuery.SQL.Text + SortSql;

        // Limit results
        FDQuery.SQL.Text := FDQuery.SQL.Text + ' LIMIT ' + IntToStr(10 + Config.SearchLimit * 10);

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

        FSetObjectList.LoadFromQuery(FDQuery, False, FConfig.WSearchMyCollection);

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

procedure TFrmSearch.ActExpandFilterExecute(Sender: TObject);
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

  DgSets.DefaultRowHeight := FGetGridHeight;

  DgSets.Invalidate;
end;

procedure TFrmSearch.ActSearchExecute(Sender: TObject);
begin
  FDoSearch;
end;

procedure TFrmSearch.FHandleUpdateGridSize(const NewSize: Integer);
begin
  if FConfig <> nil then begin
    if NewSize <> 0 then
      FConfig.WSearchGridSize := NewSize;

    MnuGrid64.Checked := FConfig.WSearchGridSize = 64;
    MnuGrid96.Checked := FConfig.WSearchGridSize = 96;
    MnuGrid128.Checked := FConfig.WSearchGridSize = 128;
    MnuGrid192.Checked := FConfig.WSearchGridSize = 192;
    MnuGrid256.Checked := FConfig.WSearchGridSize = 256;
  end;

  DgSets.DefaultColWidth := FGetGridWidth;
  DgSets.DefaultRowHeight := FGetGridHeight;
  FAdjustGrid;
end;

procedure TFrmSearch.ActSetGridSize64Execute(Sender: TObject);
begin
  FHandleUpdateGridSize(64);
end;

procedure TFrmSearch.ActSetGridSize96Execute(Sender: TObject);
begin
  FHandleUpdateGridSize(96);
end;

procedure TFrmSearch.ActShowCollectionIDExecute(Sender: TObject);
begin
  MnuShowCollectionID.Checked := not MnuShowCollectionID.Checked;

  Config.WSearchShowCollectionID := MnuShowCollectionID.Checked;

  FSetDefaultColumnDimensionsAndAdjustGrid;

  DgSets.Invalidate;
end;

procedure TFrmSearch.ActShowPartCountExecute(Sender: TObject);
begin
  MnuShowPartCount.Checked := not MnuShowPartCount.Checked;

  Config.WSearchShowPartCount := MnuShowPartCount.Checked;

  FSetDefaultColumnDimensionsAndAdjustGrid;

  DgSets.Invalidate;
end;

procedure TFrmSearch.ActShowSetNumExecute(Sender: TObject);
begin
  MnuShowNumber.Checked := not MnuShowNumber.Checked;

  Config.WSearchShowNumber := MnuShowNumber.Checked;

  FSetDefaultColumnDimensionsAndAdjustGrid;

  DgSets.Invalidate;
end;

procedure TFrmSearch.ActShowSetQuantityExecute(Sender: TObject);
begin
  MnuShowQuantity.Checked := not MnuShowQuantity.Checked;

  Config.WSearchShowSetQuantity := MnuShowQuantity.Checked;

  FSetDefaultColumnDimensionsAndAdjustGrid;

  DgSets.Invalidate;
end;

procedure TFrmSearch.ActShowYearExecute(Sender: TObject);
begin
  MnuShowYear.Checked := not MnuShowYear.Checked;

  Config.WSearchShowYear := MnuShowYear.Checked;

  FSetDefaultColumnDimensionsAndAdjustGrid;

  DgSets.Invalidate;
end;

procedure TFrmSearch.ActSortByNameExecute(Sender: TObject);
begin
  MnuSortByName.Checked := not MnuSortByName.Checked;
  if MnuSortByName.Checked then
    FUncheckAllSortExcept(MnuSortByName);
  FSaveSortSettings;
  FDoSearch;
end;

procedure TFrmSearch.ActSortByPartCountExecute(Sender: TObject);
begin
  MnuSortByPartCount.Checked := not MnuSortByPartCount.Checked;
  if MnuSortByPartCount.Checked then
    FUncheckAllSortExcept(MnuSortByPartCount);
  FSaveSortSettings;
  FDoSearch;
end;

procedure TFrmSearch.ActSortBySetNumExecute(Sender: TObject);
begin
  MnuSortByNumber.Checked := not MnuSortByNumber.Checked;
  if MnuSortByNumber.Checked then
    FUncheckAllSortExcept(MnuSortByNumber);
  FSaveSortSettings;
  FDoSearch;
end;

procedure TFrmSearch.ActSortByThemeExecute(Sender: TObject);
begin
  MnuSortByTheme.Checked := not MnuSortByTheme.Checked;
  if MnuSortByTheme.Checked then
    FUncheckAllSortExcept(MnuSortByTheme);
  FSaveSortSettings;
  FDoSearch;
end;

procedure TFrmSearch.ActSortByYearExecute(Sender: TObject);
begin
  MnuSortByYear.Checked := not MnuSortByYear.Checked;
  if MnuSortByYear.Checked then
    FUncheckAllSortExcept(MnuSortByYear);
  FSaveSortSettings;
  FDoSearch;
end;

procedure TFrmSearch.ActToggleAscendingExecute(Sender: TObject);
begin
  MnuSortAscending.Checked := not MnuSortAscending.Checked;
  FConfig.WPartsSortAscending := MnuSortAscending.Checked;
  FDoSearch;
end;

procedure TFrmSearch.FUncheckAllSortExcept(Sender: TObject);
begin
  if Sender <> MnuSortByName then
    MnuSortByName.Checked := False;
  if Sender <> MnuSortByNumber then
    MnuSortByNumber.Checked := False;
  if Sender <> MnuSortByTheme then
    MnuSortByTheme.Checked := False;
  if Sender <> MnuSortByPartCount then
    MnuSortByPartCount.Checked := False;
  if Sender <> MnuSortByYear then
    MnuSortByYear.Checked := False;
end;

procedure TFrmSearch.FSaveSortSettings;
begin
  FConfig.WSearchSortAscending := MnuSortAscending.Checked;
  FConfig.WSearchSortByName := MnuSortByName.Checked;
  FConfig.WSearchSortByNumber := MnuSortByNumber.Checked;
  FConfig.WSearchSortByTheme := MnuSortByTheme.Checked;
  FConfig.WSearchSortByPartCount := MnuSortByPartCount.Checked;
  FConfig.WSearchSortByYear := MnuSortByYear.Checked;
end;

procedure TFrmSearch.ActSetGridSize128Execute(Sender: TObject);
begin
  FHandleUpdateGridSize(128);
end;

procedure TFrmSearch.ActSetGridSize192Execute(Sender: TObject);
begin
  FHandleUpdateGridSize(192);
end;

procedure TFrmSearch.ActSetGridSize256Execute(Sender: TObject);
begin
  FHandleUpdateGridSize(256);
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
  case FConfig.SearchListDoubleClickAction of
    caVIEWEXTERNAL:
      ActViewSetExternal.Execute;
    caVIEWPARTS:
      ActViewParts.Execute;
    else // caVIEW
      ActViewSet.Execute;
  end;
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
