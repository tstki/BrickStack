unit UFrmSearch;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  Contnrs, USet, UConfig, UConst,
  FireDAC.Comp.Client, FireDAC.Stan.Param,
  System.ImageList, Vcl.ImgList, Vcl.ExtCtrls, Vcl.Imaging.pngimage,
  USearchResult,
  UImageCache, Vcl.Grids, Vcl.Menus, System.Actions, Vcl.ActnList;

type
  TFrmSearch = class(TForm)
    PnlSearchOptions: TPanel;
    LblYear: TLabel;
    TrackYearFrom: TTrackBar;
    LblParts: TLabel;
    TrackPartsFrom: TTrackBar;
    LblYearCap: TLabel;
    LblPartsCap: TLabel;
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
    LblThemeOrCategory: TLabel;
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
    CbxIncludeAltColors: TCheckBox;
    ActShowPartOrMinifigNum: TAction;
    MnuShowPartOrFigureNumber: TMenuItem;
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
    procedure CbxSearchWhatChange(Sender: TObject);
    procedure CbxSearchStyleChange(Sender: TObject);
    procedure ActShowPartOrMinifigNumExecute(Sender: TObject);
  private
    { Private declarations }
    FSearchResult: TSearchResult; // Stored locally from query result.
    FImageCache: TImageCache;
    FDragStartPoint: TPoint;
    FDraggingStarted: Boolean;
    FConfig: TConfig;
    //FCurMaxCols: Integer;
    FLastMaxCols: Integer;
    procedure FUpdateUI;
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
    procedure FBuildSetQuery(FDQuery: TFDQuery; OwnCollection: Boolean; const SearchSubject, SearchLikeOrExact: String);
    procedure FBuiltPartQuery(FDQuery: TFDQuery; OwnCollection: Boolean; const SearchSubject, SearchLikeOrExact: String);
    procedure FBuiltMinifigureQuery();
    procedure FFillCbxThemesOrCategories(const SearchWhat: TSearchWhat);
    procedure FFillCbxSearchBy(const SearchWhat: TSearchWhat);
    // Draw helpers for DgSetsDrawCell refactor
    function FInfoRowCountForWidth: Integer;
    procedure FDrawImageInCell(const Rect: TRect; Obj: TObject; InfoRowCount: Integer);
    procedure FDrawSetInfoInCell(const Rect: TRect; Obj: TObject; InfoRowCount: Integer);
    procedure FDrawPartInfoInCell(const Rect: TRect; Obj: TObject; InfoRowCount: Integer);
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
  USQLiteConnection,
  UDlgAddToSetList,
  UDragData,
  DateUtils,
  UPart,
  UFrmMain, UStrings;

procedure TFrmSearch.FormCreate(Sender: TObject);
begin
  inherited;

  FSearchResult := TSearchResult.Create;

//  SbSearchResults.UseWheelForScrolling := True;
end;

procedure TFrmSearch.FormDestroy(Sender: TObject);
begin
  FConfig.Save(csSEARCHWINDOWFILTERS);

  FSearchResult.Free;

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

  CbxSearchStyle.Clear;
  CbxSearchStyle.Items.Add(StrSearchAll);
  CbxSearchStyle.Items.Add(StrSearchPrefix);
  CbxSearchStyle.Items.Add(StrSearchSuffix);
  CbxSearchStyle.Items.Add(StrSearchExact);
  CbxSearchStyle.ItemIndex := Integer(Config.WSearchStyle); // Prefix is faster because it can the index.

  // This whole dialog is themed for search in sets, but we'll expand on that
  CbxSearchWhat.Clear;
  CbxSearchWhat.Items.Add(StrSearchSets);  //cSEARCHTYPESET
  CbxSearchWhat.Items.Add(StrSearchParts); //cSEARCHTYPEPART
  //StrSearchMinifigures                   //cSEARCHTYPEMINIFIG
  //StrAny
  CbxSearchWhat.ItemIndex := Integer(Config.WSearchWhat);

  FFillCbxSearchBy(TSearchWhat(CbxSearchWhat.ItemIndex));

  // Ensure the year track has enough space for coming year.
  var yearsSince1945 := YearOf(Now) - 1945+1;
  var numYearTicks := yearsSince1945/10;
  TrackYearFrom.Max := Round(numYearTicks+0.5);
  TrackYearTo.Max := TrackYearFrom.Max;

  //
  MnuShowNumber.Checked := FConfig.WSearchShowNumber;
  MnuShowYear.Checked := FConfig.WSearchShowYear;
  MnuShowQuantity.Checked := FConfig.WSearchShowSetQuantity;
  MnuShowCollectionID.Checked := FConfig.WSearchShowCollectionID;
  MnuShowPartCount.Checked := FConfig.WSearchShowPartCount;
  MnuShowPartOrFigureNumber.Checked := FConfig.WSearchShowPartOrMinifigNumber;
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

  FUpdateUI;
end;

procedure TFrmSearch.FFillCbxThemesOrCategories(const SearchWhat: TSearchWhat);
begin
  var SqlConnection := FrmMain.AcquireConnection;
  var FDQuery := TFDQuery.Create(nil);

  CbxThemes.Items.BeginUpdate;

  try
    CbxThemes.Clear;
    CbxThemes.Items.AddObject('(' + StrAny + ')', TObject(0));
    FDQuery.Connection := SqlConnection;

    if SearchWhat = cSEARCHTYPESET then begin
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
    end else begin
      // Substring because some value has more than 40 characters, firedac moans about it when retrieving data.
      FDQuery.SQL.Text := 'SELECT pc.id as id, substr(pc.name,1,40) as name FROM part_categories pc' +
                          ' ORDER BY pc.name';
      FDQuery.Open;

      while not FDQuery.Eof do begin
        var PartCategoryName := FDQuery.FieldByName('name').AsString;
        var PartCategoryID := FDQuery.FieldByName('id').AsInteger;

        CbxThemes.Items.AddObject(PartCategoryName, TObject(PartCategoryID));

        FDQuery.Next; // Move to the next row
      end;
    end;
  finally
    CbxThemes.ItemIndex := 0;
    CbxThemes.Items.EndUpdate;
    FDQuery.Free;
    FrmMain.ReleaseConnection(SqlConnection);
  end;
end;

procedure TFrmSearch.FFillCbxSearchBy(const SearchWhat: TSearchWhat);
begin
  var currentIndex := CbxSearchBy.ItemIndex;

  CbxSearchBy.Items.BeginUpdate;
  try
    CbxSearchBy.Clear;
    if SearchWhat = cSEARCHTYPESET then
      CbxSearchBy.Items.Add(StrSearchSetNumber) // cNUMBER
    else if SearchWhat = cSEARCHTYPEPART then
      CbxSearchBy.Items.Add(StrSearchPartNumber) // cNUMBER
    else
      CbxSearchBy.Items.Add(StrSearchNumber); // cNUMBER
    CbxSearchBy.Items.Add(StrSearchName);   // cNAME
    //cAny
    if currentIndex >= 0 then
      CbxSearchBy.ItemIndex := currentIndex
    else
      CbxSearchBy.ItemIndex := Config.WSearchBy;
  finally
    CbxSearchBy.Items.EndUpdate;
  end;
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
  FFillCbxThemesOrCategories(TSearchWhat(CbxThemes.ItemIndex));

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
  if FSearchResult.Count = 0 then begin
    DgSets.ColCount := 0;
    DgSets.RowCount := 0;
  end else
    DgSets.ColCount := Max(1, Floor(DgSets.ClientWidth div (DgSets.DefaultColWidth+1)));

  if DgSets.ColCount <> FLastMaxCols then begin
    DgSets.RowCount := Ceil(FSearchResult.Count / DgSets.ColCount);
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
  Result := FGetGridWidth + (FInfoRowCountForWidth*20);
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

  FUpdateUI;
end;

procedure TFrmSearch.CbxSearchStyleChange(Sender: TObject);
begin
//  FUpdateUI;
end;

procedure TFrmSearch.FUpdateUI;
begin
  TrackPartsFrom.Enabled := CbxSearchWhat.ItemIndex = Integer(cSEARCHTYPESET);
  TrackPartsTo.Enabled := CbxSearchWhat.ItemIndex = Integer(cSEARCHTYPESET);
  LblParts.Enabled := CbxSearchWhat.ItemIndex = Integer(cSEARCHTYPESET);
  LblPartsCap.Enabled := CbxSearchWhat.ItemIndex = Integer(cSEARCHTYPESET);
  LblTrackParts.Enabled := CbxSearchWhat.ItemIndex = Integer(cSEARCHTYPESET);

  //Disable for now - later, a query could check if there's at least 1 set that uses a part in a year.
  TrackYearFrom.Enabled := CbxSearchWhat.ItemIndex = Integer(cSEARCHTYPESET);
  TrackYearTo.Enabled := CbxSearchWhat.ItemIndex = Integer(cSEARCHTYPESET);
  LblYear.Enabled := CbxSearchWhat.ItemIndex = Integer(cSEARCHTYPESET);
  LblYearCap.Enabled := CbxSearchWhat.ItemIndex = Integer(cSEARCHTYPESET);
  LblTrackYear.Enabled := CbxSearchWhat.ItemIndex = Integer(cSEARCHTYPESET);

  ActSortByTheme.Enabled := CbxSearchWhat.ItemIndex = Integer(cSEARCHTYPESET);
  ActSortByPartCount.Enabled := CbxSearchWhat.ItemIndex = Integer(cSEARCHTYPESET);
  ActSortByYear.Enabled := CbxSearchWhat.ItemIndex = Integer(cSEARCHTYPESET);

  ActShowPartCount.Enabled := CbxSearchWhat.ItemIndex = Integer(cSEARCHTYPESET);
  ActShowYear.Enabled := CbxSearchWhat.ItemIndex = Integer(cSEARCHTYPESET);
  ActShowSetNum.Enabled := (CbxSearchWhat.ItemIndex = Integer(cSEARCHTYPESET)) or CbxSearchInMyCollection.Checked;
  ActShowSetQuantity.Enabled := CbxSearchInMyCollection.Checked;
  ActShowCollectionID.Enabled := CbxSearchInMyCollection.Checked;
  ActShowPartOrMinifigNum.Enabled := (CbxSearchWhat.ItemIndex = Integer(cSEARCHTYPEPART));

  CbxIncludeAltColors.Enabled := not CbxSearchInMyCollection.Checked;
  CbxIncludeAltColors.Visible := CbxSearchWhat.ItemIndex = Integer(cSEARCHTYPEPART);

  if CbxSearchWhat.ItemIndex = Integer(cSEARCHTYPESET) then
    LblThemeOrCategory.Caption := StrTheme
  else // Parts of Minifigs
    LblThemeOrCategory.Caption := StrCategory;
end;

procedure TFrmSearch.CbxSearchWhatChange(Sender: TObject);
begin
  //fill CbxThemes using part_categories
  FFillCbxThemesOrCategories(TSearchWhat(CbxSearchWhat.ItemIndex));
  FFillCbxSearchBy(TSearchWhat(CbxSearchWhat.ItemIndex));

  FUpdateUI;
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

function TFrmSearch.FInfoRowCountForWidth: Integer;
begin
  Result := 0;
  if DgSets.DefaultColWidth >= 64 then begin
    var SearchWhat := TSearchWhat(CbxSearchWhat.ItemIndex);
    if SearchWhat = cSEARCHTYPESET then begin
      if FConfig.WSearchShowNumber then
        Inc(Result);
      if FConfig.WSearchShowYear or FConfig.WSearchShowPartCount then
        Inc(Result);
      if FConfig.WSearchMyCollection and
        (FConfig.WSearchShowSetQuantity or FConfig.WSearchShowCollectionID) then
        Inc(Result);
    end else if SearchWhat = cSEARCHTYPEPART then begin
      if FConfig.WSearchShowPartOrMinifigNumber then
        Inc(Result);
      if FConfig.WSearchMyCollection then begin
        if FConfig.WSearchShowNumber then
          Inc(Result);
        if (FConfig.WSearchShowSetQuantity or FConfig.WSearchShowCollectionID) then
          Inc(Result);
      end;
    end;
  end;
end;

procedure TFrmSearch.FDrawImageInCell(const Rect: TRect; Obj: TObject; InfoRowCount: Integer);
begin
  if FImageCache = nil then
    Exit;

  var ImageUrl := '';
  if Obj <> nil then begin
    if FSearchResult.SearchType = cSEARCHTYPESET then
      ImageUrl := TSetObject(Obj).SetImgUrl
    else if FSearchResult.SearchType = cSEARCHTYPEPART then
      ImageUrl := TPartObject(Obj).ImgUrl;
  end;

  var Picture := FImageCache.GetImage(ImageUrl, cidMAX256);
  if Assigned(Picture) and Assigned(Picture.Graphic) then begin
    var ImageRect := Rect;
    ImageRect.Bottom := ImageRect.Bottom - (20 * InfoRowCount);
    DgSets.Canvas.StretchDraw(ImageRect, Picture.Graphic);
  end;
end;

procedure TFrmSearch.FDrawSetInfoInCell(const Rect: TRect; Obj: TObject; InfoRowCount: Integer);
var
  YPosition: Integer;
begin
  if Obj = nil then
    Exit
  else if DgSets.DefaultColWidth < 64 then
    Exit;

  // Inforow 1
  var SetObj := TSetObject(Obj);
  if FConfig.WSearchShowNumber then begin
    var Number := SetObj.SetNum;
    DgSets.Canvas.TextOut(Rect.Left + 2, Rect.Bottom - (InfoRowCount * 20) + 2, Number);
  end;

  // Inforow 2
  if FConfig.WSearchShowYear or FConfig.WSearchShowPartCount then begin
    if InfoRowCount = 3 then
      YPosition := Rect.Bottom - 38      // This is the middle row
    else if InfoRowCount = 2 then begin
      if FConfig.WSearchShowNumber then
        YPosition := Rect.Bottom - 18    // This is the bottom row
      else
        YPosition := Rect.Bottom - 38;   // This is the top row
    end else
      YPosition := Rect.Bottom - 18;

    if FConfig.WSearchShowYear then
      DgSets.Canvas.TextOut(Rect.Left + 2, YPosition, IntToStr(SetObj.SetYear));

    var SetNumPartsText := IntToStr(SetObj.SetNumParts);
    var TextWidth1 := DgSets.Canvas.TextWidth(SetNumPartsText);
    if FConfig.WSearchShowPartCount then
      DgSets.Canvas.TextOut(Rect.Right - TextWidth1 - 2, YPosition, SetNumPartsText);
  end;

  // Inforow 3 - Search in my collection - always at the bottom
  if FConfig.WSearchMyCollection and
     (FConfig.WSearchShowSetQuantity or FConfig.WSearchShowCollectionID) then begin
    YPosition := Rect.Bottom - 18;

    if FConfig.WSearchShowSetQuantity then
      DgSets.Canvas.TextOut(Rect.Left + 2, YPosition, IntToStr(SetObj.Quantity) + 'x');

    var BSSetID := IntToStr(SetObj.BSSetListID);
    var TextWidth2 := DgSets.Canvas.TextWidth(BSSetID);
    if FConfig.WSearchShowCollectionID then
      DgSets.Canvas.TextOut(Rect.Right - TextWidth2 - 2, YPosition, BSSetID);
  end;
end;

procedure TFrmSearch.FDrawPartInfoInCell(const Rect: TRect; Obj: TObject; InfoRowCount: Integer);
var
  YPosition: Integer;
begin
  if Obj = nil then
    Exit
  else if DgSets.DefaultColWidth < 64 then
    Exit;

  // Inforow 1 - Part number
  var PartObj := TPartObject(Obj);
  if FConfig.WSearchShowPartOrMinifigNumber then
    DgSets.Canvas.TextOut(Rect.Left + 2, Rect.Bottom - (InfoRowCount * 20) + 2, PartObj.PartNum);

  // Inforow 2 - Set number (only when searching in own collection)
  if FConfig.WSearchMyCollection then begin
    if FConfig.WSearchShowNumber then begin
      if InfoRowCount = 3 then
        YPosition := Rect.Bottom - 38      // This is the middle row
      else if InfoRowCount = 2 then begin
        if FConfig.WSearchShowNumber then
          YPosition := Rect.Bottom - 18    // This is the bottom row
        else
          YPosition := Rect.Bottom - 38;   // This is the top row
      end else
        YPosition := Rect.Bottom - 18;

      DgSets.Canvas.TextOut(Rect.Left + 2, YPosition, PartObj.SetNum);
    end;

    // Inforow 3 - Search in my collection - always at the bottom
    YPosition := Rect.Bottom - 18;
    if FConfig.WSearchShowSetQuantity then begin
      var NumText := IntToStr(PartObj.CurQuantity);
      DgSets.Canvas.TextOut(Rect.Left + 2, YPosition, NumText + 'x');
    end;

    if FConfig.WSearchShowCollectionID then begin
      var BSSetID := IntToStr(PartObj.BSSetListID);
      var TextWidth2 := DgSets.Canvas.TextWidth(BSSetID);
      DgSets.Canvas.TextOut(Rect.Right - TextWidth2 - 2, YPosition, BSSetID);
    end;
  end;
end;

procedure TFrmSearch.DgSetsDrawCell(Sender: TObject; ACol, ARow: LongInt; Rect: TRect; State: TGridDrawState);
begin
  var Idx := FGetIndexByRowAndCol(ACol, ARow);
  if (Idx < 0) or (Idx >= FSearchResult.Count) then
    Exit;

  var Obj := nil;
  if FSearchResult.SearchType = cSEARCHTYPESET then
    Obj := FSearchResult.SetObjectList[Idx]
  else if FSearchResult.SearchType = cSEARCHTYPEPART then
    Obj := FSearchResult.PartObjectList[Idx];

  var InfoRowCount := FInfoRowCountForWidth;

  FDrawImageInCell(Rect, Obj, InfoRowCount);

  DgSets.Canvas.Brush.Style := bsClear;

  if FSearchResult.SearchType = cSEARCHTYPESET then
    FDrawSetInfoInCell(Rect, Obj, InfoRowCount)
  else if FSearchResult.SearchType = cSEARCHTYPEPART then
    FDrawPartInfoInCell(Rect, Obj, InfoRowCount);
  //else cSEARCHTYPEMINIFIG
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
      if (Idx >= 0) and (Idx < FSearchResult.Count) then begin
        // Populate drag data
        ClearDragData;
        if FSearchResult.SearchType = cSEARCHTYPESET then begin
          var SetObj := FSearchResult.SetObjectList[Idx];
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
    if (Idx >= 0) and (Idx<FSearchResult.Count) then begin
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
  if (Idx >= 0) and (Idx<FSearchResult.Count) then begin
    if FSearchResult.SearchType = cSEARCHTYPESET then begin
      var SetObject := FSearchResult.SetObjectList[Idx];
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
      SbResults.Panels[1].Text := Format('%s%s, %s%s%s%s%s%s', [SetObject.SetNum, NumParts, SetObject.SetName, Year,
                                                                IfThen(SetObject.SetThemeName<>'', ' - ', ''), SetObject.SetThemeName,
                                                                IfThen(MyCollectionInfo <> '', ', ', ''), MyCollectionInfo]);
    end else if FSearchResult.SearchType = cSEARCHTYPEPART then begin
      var PartObject := FSearchResult.PartObjectList[Idx];
      var MyCollectionInfo := '';
      if FConfig.WSearchMyCollection and (PartObject.CurQuantity > 0) then begin
        if PartObject.BSSetListName <> '' then
          MyCollectionInfo := Format('%dx in %s', [PartObject.CurQuantity, PartObject.BSSetListName]);
        if PartObject.SetNum <> '' then
          MyCollectionInfo := MyCollectionInfo + Format('(%s)', [PartObject.SetNum]); // todo, add BSSetID to make it more unique
      end;
      SbResults.Panels[1].Text := Format('%s, %s%s%s', [PartObject.PartNum, PartObject.PartName,
                                                        IfThen(MyCollectionInfo <> '', ', ', ''), MyCollectionInfo]);
    end;
  end else
    SbResults.Panels[1].Text := '';
end;

procedure TFrmSearch.FBuildSetQuery(FDQuery: TFDQuery; OwnCollection: Boolean; const SearchSubject, SearchLikeOrExact: String);
begin
  var ThemeID := 0;

  if OwnCollection then begin
    FDQuery.SQL.Text := 'SELECT s.set_num, s.name, s.year, s.img_url, s.num_parts, bss.BSSetListID, bl.name AS BSSetListName, count(*) AS quantity' + //, theme_id
                        ' FROM BSSets bss'+
                        ' LEFT JOIN Sets s on BSS.set_num = s.set_num' +
                        ' INNER JOIN BSSetLists bl on bl.id = bss.BSSetListID' +
                        ' WHERE (year between :fromyear and :toyear) AND' +
                        ' (s.num_parts BETWEEN :fromparts AND :toparts) AND' +
                        ' ((' + SearchSubject + ' ' + SearchLikeOrExact + ' :Param1)';
    if TSearchStyle(CbxSearchStyle.ItemIndex) in [cSEARCHSUFFIX, cSEARCHEXACT] then
      FDQuery.SQL.Text := FDQuery.SQL.Text + ' OR (' + SearchSubject + ' ' + SearchLikeOrExact + ' :Param2)';
    FDQuery.SQL.Text := FDQuery.SQL.Text + ')';

    if CbxThemes.ItemIndex <> 0 then begin
      ThemeID := Integer(CbxThemes.Items.Objects[CbxThemes.ItemIndex]);
      if ThemeID > 0 then
        FDQuery.SQL.Text := FDQuery.SQL.Text + ' AND s.theme_id = :themeid';
    end;

    FDQuery.SQL.Text := FDQuery.SQL.Text + ' AND s.set_num IN (SELECT bs.set_num from BSSets bs WHERE' +
                                           ' ((' + SearchSubject + ' ' + SearchLikeOrExact + ' :Param1)';
    if TSearchStyle(CbxSearchStyle.ItemIndex) in [cSEARCHSUFFIX, cSEARCHEXACT] then
      FDQuery.SQL.Text := FDQuery.SQL.Text + ' OR (' + SearchSubject + ' ' + SearchLikeOrExact + ' :Param2)';
    FDQuery.SQL.Text := FDQuery.SQL.Text + '))' +
                                           ' GROUP BY bss.BSSetListID, s.set_num ';
  end else begin
    FDQuery.SQL.Text := 'SELECT s.set_num, s.name, s.year, s.img_url, s.num_parts' + //, theme_id
                        ' FROM Sets s WHERE (year between :fromyear and :toyear) AND' +
                        ' (s.num_parts BETWEEN :fromparts AND :toparts) AND' +
                        ' ((' + SearchSubject + ' ' + SearchLikeOrExact + ' :Param1)';
    if TSearchStyle(CbxSearchStyle.ItemIndex) in [cSEARCHSUFFIX, cSEARCHEXACT] then
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
      SortSql := ' ORDER BY ' + SortSql + ' ASC'
    else
      SortSql := ' ORDER BY ' + SortSql + ' DESC';
  end;

  if FConfig.WSearchMyCollection then begin
    if SortSql <> '' then
      SortSql := SortSql + ', s.set_num, bss.bssetlistid'
    else
      SortSql := ' ORDER BY s.set_num, bss.bssetlistid';
  end;

  FDQuery.SQL.Text := FDQuery.SQL.Text + SortSql;

  // Limit results
  FDQuery.SQL.Text := FDQuery.SQL.Text + ' LIMIT ' + IntToStr(10 + Config.SearchLimit * 10);

  // Fill the params
  var Params := FDQuery.Params;
  var SearchValue1 := EditSearchText.Text;
  if TSearchStyle(CbxSearchStyle.ItemIndex) = cSEARCHALL then
    SearchValue1 := '%' + EditSearchText.Text + '%'
  else if TSearchStyle(CbxSearchStyle.ItemIndex) = cSEARCHPREFIX then
    SearchValue1 := EditSearchText.Text + '%'
  else if TSearchStyle(CbxSearchStyle.ItemIndex) = cSEARCHSUFFIX then
    SearchValue1 := '%' + EditSearchText.Text
  else
    SearchValue1 := EditSearchText.Text;

  var SearchValue2 := SearchValue1 + '-1';
  Params.ParamByName('Param1').AsString := SearchValue1;

  if TSearchStyle(CbxSearchStyle.ItemIndex) in [cSEARCHSUFFIX, cSEARCHEXACT] then
    Params.ParamByName('Param2').AsString := SearchValue2;

  Params.ParamByName('fromyear').AsInteger := FGetFromYear;
  Params.ParamByName('toyear').AsInteger := FGetToYear;
  Params.ParamByName('fromparts').AsInteger := FGetFromParts;
  Params.ParamByName('toparts').AsInteger := FGetToParts;
  if ThemeID > 0 then
    Params.ParamByName('themeid').AsInteger := ThemeID;
end;

procedure TFrmSearch.FBuiltPartQuery(FDQuery: TFDQuery; OwnCollection: Boolean; const SearchSubject, SearchLikeOrExact: String);
begin
  var CategoryID := 0;

  if OwnCollection then begin
    FDQuery.SQL.Text := 'SELECT p.name as partname, bpi.color_id, p.part_num, bpi.BSSetID, bpi.quantity,' +
                        ' ip.img_url, bsl.id as BSSetListID, bsl.Name as BSSetListName, s.name as setname, s.set_num as set_num' +
                        ' FROM BSDBPartsInventory bpi'+
                        ' LEFT JOIN inventory_parts ip on ip.part_num = bpi.part_num' +
                        ' LEFT JOIN parts p on p.part_num = bpi.part_num AND bpi.color_id = ip.color_id' +
                        ' LEFT JOIN bssets bss on bss.ID = bpi.BSSetID' +
                        ' LEFT JOIN bssetlists bsl on bsl.ID = bss.BSSetListID' +
                        ' LEFT JOIN sets s on s.set_num = bss.set_num' +
                        ' WHERE'+ //' (year between :fromyear and :toyear) AND' +
                        ' ((' + SearchSubject + ' ' + SearchLikeOrExact + ' :Param1)';
    if TSearchStyle(CbxSearchStyle.ItemIndex) in [cSEARCHSUFFIX, cSEARCHEXACT] then
      FDQuery.SQL.Text := FDQuery.SQL.Text + ' OR (' + SearchSubject + ' ' + SearchLikeOrExact + ' :Param2)';
    FDQuery.SQL.Text := FDQuery.SQL.Text + ')';

    if CbxThemes.ItemIndex <> 0 then begin
      CategoryID := Integer(CbxThemes.Items.Objects[CbxThemes.ItemIndex]);
      if CategoryID > 0 then
        FDQuery.SQL.Text := FDQuery.SQL.Text + ' AND p.part_cat_id = :categoryid';
    end;
    FDQuery.SQL.Text := FDQuery.SQL.Text + ' GROUP BY bpi.BSSetID, p.part_num';
  end else begin
    if CbxIncludeAltColors.Checked then begin
      FDQuery.SQL.Text := 'SELECT DISTINCT p.part_num, p.name as partname, ip.img_url' + //, s.year, s.img_url, s.num_parts' +
                          ' FROM Parts p' +
                          ' LEFT JOIN inventory_parts ip on ip.part_num = p.part_num' +
                          ' WHERE' + //' (year between :fromyear and :toyear) AND' +
                          ' ((' + SearchSubject + ' ' + SearchLikeOrExact + ' :Param1)';
      if TSearchStyle(CbxSearchStyle.ItemIndex) in [cSEARCHSUFFIX, cSEARCHEXACT] then
        FDQuery.SQL.Text := FDQuery.SQL.Text + ' OR (' + SearchSubject + ' ' + SearchLikeOrExact + ' :Param2)';
      FDQuery.SQL.Text := FDQuery.SQL.Text + ')';
    end else begin
      FDQuery.SQL.Text := 'WITH ranked AS (' +
                          ' SELECT prt.part_num, prt.name, prt.part_cat_id, ip.img_url, ip.color_id,' +
                                 ' ROW_NUMBER() OVER (' +
                                   ' PARTITION BY prt.part_num' +
                                   ' ORDER by color_id asc' +
                                 ' ) AS rn' +
                          ' FROM Parts prt' +
                          ' LEFT JOIN inventory_parts ip ON ip.part_num = prt.part_num' +
                          ' WHERE' + //' (year between :fromyear and :toyear) AND' +
                          ' ((' + SearchSubject + ' ' + SearchLikeOrExact + ' :Param1))';
    if TSearchStyle(CbxSearchStyle.ItemIndex) in [cSEARCHSUFFIX, cSEARCHEXACT] then
      FDQuery.SQL.Text := FDQuery.SQL.Text + ' OR (' + SearchSubject + ' ' + SearchLikeOrExact + ' :Param2)';
    FDQuery.SQL.Text := FDQuery.SQL.Text + ') SELECT p.part_num, p.name AS partname, p.img_url, p.color_id, p.part_cat_id' +
                          ' FROM ranked p' +
                          ' WHERE rn = 1';
    end;

    if CbxThemes.ItemIndex <> 0 then begin
      CategoryID := Integer(CbxThemes.Items.Objects[CbxThemes.ItemIndex]);
      if CategoryID > 0 then
        FDQuery.SQL.Text := FDQuery.SQL.Text + ' AND p.part_cat_id = :categoryid';
    end;
  end;

  //order by
  var SortSql := '';
  if FConfig.WSearchSortByNumber then
    SortSql := 'p.part_num'
  else if FConfig.WSearchSortByName then
    SortSql := 'p.name'
//  else if FConfig.WSearchSortByYear then
//    SortSql := 's.year'
  else if FConfig.WSearchSortByTheme then
    SortSql := 'p.part_cat_id';
//  else if FConfig.WSearchSortByPartCount then
//    SortSql := 's.num_parts';

  if SortSql <> '' then begin
    if FConfig.WPartsSortAscending then
      SortSql := ' ORDER BY ' + SortSql + ' ASC'
    else
      SortSql := ' ORDER BY ' + SortSql + ' DESC';
  end;

  if FConfig.WSearchMyCollection then begin
    if OwnCollection then begin
      if SortSql <> '' then
        SortSql := SortSql + ', p.part_num DESC, bss.BSSetListID, bpi.BSSetID'
      else
        SortSql := ' ORDER BY p.part_num DESC, bss.BSSetListID, bpi.BSSetID';
    end else begin
      if SortSql <> '' then
        SortSql := SortSql + ', p.part_num, bss.bssetlistid'
      else
        SortSql := ' ORDER BY p.part_num, bss.bssetlistid';
    end;
  end;
//2780 is the generic black connector
  FDQuery.SQL.Text := FDQuery.SQL.Text + SortSql;

  // Limit results
  FDQuery.SQL.Text := FDQuery.SQL.Text + ' LIMIT ' + IntToStr(10 + Config.SearchLimit * 10);

  // Fill the params
  var Params := FDQuery.Params;
  var SearchValue1 := EditSearchText.Text;
  if TSearchStyle(CbxSearchStyle.ItemIndex) = cSEARCHALL then
    SearchValue1 := '%' + EditSearchText.Text + '%'
  else if TSearchStyle(CbxSearchStyle.ItemIndex) = cSEARCHPREFIX then
    SearchValue1 := EditSearchText.Text + '%'
  else if TSearchStyle(CbxSearchStyle.ItemIndex) = cSEARCHSUFFIX then
    SearchValue1 := '%' + EditSearchText.Text
  else
    SearchValue1 := EditSearchText.Text;

  var SearchValue2 := SearchValue1 + '-1';
  Params.ParamByName('Param1').AsString := SearchValue1;

  if TSearchStyle(CbxSearchStyle.ItemIndex) in [cSEARCHSUFFIX, cSEARCHEXACT] then
    Params.ParamByName('Param2').AsString := SearchValue2;

//  Params.ParamByName('fromyear').AsInteger := FGetFromYear;
//  Params.ParamByName('toyear').AsInteger := FGetToYear;
//  Params.ParamByName('fromparts').AsInteger := FGetFromParts;
//  Params.ParamByName('toparts').AsInteger := FGetToParts;
  if CategoryID > 0 then
    Params.ParamByName('categoryid').AsInteger := CategoryID;
end;

procedure TFrmSearch.FBuiltMinifigureQuery();
begin
//
end;

procedure TFrmSearch.FDoSearch;
begin
  if EditSearchText.Text = '' then
    Exit;

  // dont save "EditSearchText.Text"
  Config.WSearchStyle := CbxSearchStyle.ItemIndex;
  Config.WSearchWhat := CbxSearchWhat.ItemIndex;
  Config.WSearchBy := CbxSearchBy.ItemIndex;

{
  select * from sets where set_num = '4200-1'; = one set, 102 parts
  select * from inventories where set_num = '4200-1'; = 9677

  select * from inventory_parts where inventory_id = 9677; = the set inventory

  select * from inventory_minifigs where inventory_id = 9677; = fig-001386
  select * from inventories where set_num = 'fig-001386'; = 52201
  select * from minifigs where fig_num = 'fig-001386'; = 1 figure with 5 parts.
  select * from inventory_parts where inventory_id = 52201; = the minifig parts

  select * from inventory_sets where set_num = '4200-1'; = 1726, is the 'set box' this set and 4 others are a part of
  select * from inventory_sets where inventory_id = 1726; = is a list of sets in a set box
}

  // Hide scrollbox while drawing
//  SbSearchResults.Visible := False;
  try
    // Clean up the list before adding new results
    FSearchResult.Clear;

    //Get tickcount for performance monitoring.
    //var Stopwatch := TStopWatch.Create;
    //Stopwatch.Start;
    try
      var SqlConnection := FrmMain.AcquireConnection;
      var FDQuery := TFDQuery.Create(nil);
      try
        var SearchSubject := '';
        if TSearchWhat(CbxSearchWhat.ItemIndex) = cSEARCHTYPESET then begin
          if TSearchBy(CbxSearchBy.ItemIndex) = cNUMBER then
            SearchSubject := 's.set_num'
          else // cNAME
            SearchSubject := 's.name';
          //cNUMORNAME
          // special handling
        end else if TSearchWhat(CbxSearchWhat.ItemIndex) = cSEARCHTYPEPART then begin
          if CbxIncludeAltColors.Checked or FConfig.WSearchMyCollection then begin
            if TSearchBy(CbxSearchBy.ItemIndex) = cNUMBER then
              SearchSubject := 'p.part_num'
            else // cNAME
              SearchSubject := 'p.name';
            //cNUMORNAME
            // special handling
          end else begin
            if TSearchBy(CbxSearchBy.ItemIndex) = cNUMBER then
              SearchSubject := 'prt.part_num'
            else // cNAME
              SearchSubject := 'prt.name';
            //cNUMORNAME
            // special handling
          end;
        end else begin // cSEARCHTYPEMINIFIG
          //
        end;

        var SearchLikeOrExact := '';
        if TSearchStyle(CbxSearchStyle.ItemIndex) = cSEARCHEXACT then
          SearchLikeOrExact := '='
        else
          SearchLikeOrExact := 'LIKE';

        // Set up the query
        FDQuery.Connection := SqlConnection;

        //CbxSearchWhat
        if TSearchWhat(CbxSearchWhat.ItemIndex) = cSEARCHTYPESET then
          FBuildSetQuery(FDQuery, FConfig.WSearchMyCollection, SearchSubject, SearchLikeOrExact)
        else if TSearchWhat(CbxSearchWhat.ItemIndex) = cSEARCHTYPEPART then
          FBuiltPartQuery(FDQuery, FConfig.WSearchMyCollection, SearchSubject, SearchLikeOrExact)
        else begin // cSEARCHTYPEMINIFIG
          //FBuiltMinifigureQuery()
        end;

        // Run the query, and add the results into the ObjectList
        FSearchResult.LoadFromQuery(FDQuery, TSearchWhat(CbxSearchWhat.ItemIndex), False, FConfig.WSearchMyCollection);

        FLastMaxCols := -1; // Force an invalidate
        FAdjustGrid;

        SbResults.Panels[0].Text := 'Results: ' + IntToStr(FSearchResult.Count);
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
  if (Idx >= 0) and (Idx<FSearchResult.Count) then begin
    if FSearchResult.SearchType = cSEARCHTYPESET then begin
      var SetObject := FSearchResult.SetObjectList[Idx];
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
    end else begin
      //todo part
    end;
  end;
end;

procedure TFrmSearch.ActViewSetExternalExecute(Sender: TObject);
begin
  var sel := DgSets.Selection;
  var Idx := FGetIndexByRowAndCol(Sel.left, sel.top);
  if (Idx >= 0) and (Idx<FSearchResult.Count) then begin
    if FSearchResult.SearchType = cSEARCHTYPESET then begin
      var SetObject := FSearchResult.SetObjectList[Idx];
      TFrmMain.OpenExternal(cTYPESET, SetObject.SetNum);
    end else begin
      //todo part
    end;
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

procedure TFrmSearch.ActShowPartOrMinifigNumExecute(Sender: TObject);
begin
  MnuShowPartOrFigureNumber.Checked := not MnuShowPartOrFigureNumber.Checked;

  Config.WSearchShowPartOrMinifigNumber := MnuShowPartOrFigureNumber.Checked;

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
  if (Idx >= 0) and (Idx<FSearchResult.Count) then begin
    if FSearchResult.SearchType = cSEARCHTYPESET then begin
      var SetObject := FSearchResult.SetObjectList[Idx];
      TFrmMain.ShowPartsWindow(SetObject.SetNum);
    end else begin
      //todo part
    end;
  end;
end;

procedure TFrmSearch.ActViewSetExecute(Sender: TObject);
begin
  // Open set
  var sel := DgSets.Selection;
  var Idx := FGetIndexByRowAndCol(Sel.left, sel.top);
  if (Idx >= 0) and (Idx<FSearchResult.Count) then begin
    if FSearchResult.SearchType = cSEARCHTYPESET then begin
      var SetObject := FSearchResult.SetObjectList[Idx];
      TFrmMain.ShowSetWindow(SetObject.SetNum);
    end else begin
      //todo part
    end;
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
// SbSearchResults.UseWheelForScrolling := True; //then
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
