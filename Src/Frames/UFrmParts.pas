unit UFrmParts;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Imaging.pngimage,
  Contnrs, UDelayedImage,
  FireDAC.Comp.Client, FireDAC.Stan.Param,
  UConfig, UImageCache, Vcl.Menus, System.Actions, Vcl.ActnList, Vcl.Buttons,
  UPart,
  System.ImageList, Vcl.ImgList, Vcl.Grids;

type
  TCellAction = (caNone, caClick, caDoubleClick, caRightClick);

  TFrmParts = class(TForm)
    Panel1: TPanel;
    LblInventoryVersion: TLabel;
    CbxInventoryVersion: TComboBox;
    BtnFilter: TButton;
    PopPartsFilter: TPopupMenu;
    Sort1: TMenuItem;
    Ascending1: TMenuItem;
    N1: TMenuItem;
    Sort2: TMenuItem;
    Hue1: TMenuItem;
    Part1: TMenuItem;
    Category1: TMenuItem;
    Quantity1: TMenuItem;
    IncludeSpareParts: TMenuItem;
    ActionList1: TActionList;
    ActPrintParts: TAction;
    ActExport: TAction;
    ActToggleCheckboxMode: TAction;
    ActToggleIncludeSpareParts: TAction;
    ActToggleAscending: TAction;
    ActSortByColor: TAction;
    ActSortByHue: TAction;
    ActSortByPart: TAction;
    ActSortByCategory: TAction;
    ActSortByQuantity: TAction;
    ActViewPartExternal: TAction;
    ActViewSetExternal: TAction;
    ImageList1: TImageList;
    ImgPrinter: TImage;
    ImgExport: TImage;
    SbResults: TStatusBar;
    LblPartsGridSize: TLabel;
    DgSetParts: TDrawGrid;
    TbGridSize: TTrackBar;
    ShowPartCountAndLink: TMenuItem;
    ShowPartnum: TMenuItem;
    LblPartsGridSizePx: TLabel;
    PopGridRightClick: TPopupMenu;
    Viewpartexternally1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure ActPrintPartsExecute(Sender: TObject);
    procedure BtnFilterClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ActToggleCheckboxModeExecute(Sender: TObject);
    procedure ActToggleAscendingExecute(Sender: TObject);
    procedure ActSortByColorExecute(Sender: TObject);
    procedure ActSortByHueExecute(Sender: TObject);
    procedure ActSortByPartExecute(Sender: TObject);
    procedure ActSortByCategoryExecute(Sender: TObject);
    procedure ActSortByQuantityExecute(Sender: TObject);
    procedure ActToggleIncludeSparePartsExecute(Sender: TObject);
    procedure ActExportExecute(Sender: TObject);
    procedure DgSetPartsClick(Sender: TObject);
    procedure DgSetPartsDrawCell(Sender: TObject; ACol, ARow: LongInt; Rect: TRect; State: TGridDrawState);
    procedure DgSetPartsDblClick(Sender: TObject);
    procedure DgSetPartsMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure HandleClick(CellAction: TCellAction; Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure TbGridSizeChange(Sender: TObject);
    procedure DgSetPartsSelectCell(Sender: TObject; ACol, ARow: LongInt;
      var CanSelect: Boolean);
    procedure ActViewPartExternalExecute(Sender: TObject);
  private
    { Private declarations }
    FConfig: TConfig;
    FImageCache: TImageCache;
    FInventoryPanels: TObjectList;
    FPartObjectList: TPartObjectList;
//    FCurMaxCols: Integer;
    FSetNum: String;
    //FCheckboxMode: Boolean;
    FLastMaxCols: Integer;
//    FLastCellAction: TCellAction;
    procedure FHandleQueryAndHandleSetInventoryVersion(Query: TFDQuery);
//    procedure FInvalidateGridCell(Grid: TDrawGrid; ACol, ARow: Integer);
    procedure FAdjustGrid();
    function FGetIndexByRowAndCol(ACol, ARow: Integer): Integer;
    function FTBGridSizePositionToPixels: Integer;
    function FGetGridHeight: Integer;
  public
    { Public declarations }
    property Config: TConfig read FConfig write FConfig;
    property ImageCache: TImageCache read FImageCache write FImageCache;
    procedure LoadPartsBySet(const set_num: String);
    property SetNum: String read FSetNum; // Read only
  end;

implementation

{$R *.dfm}
uses
  ShellAPI, Printers, CommCtrl,
  UFrmMain,
  USQLiteConnection,
  Math, Diagnostics, Data.DB, StrUtils,
  UDlgViewExternal, UDlgAddToSetList,
  UStrings;

const
  cPARTSORTBYCOLOR = 0;
  cPARTSORTBYHUE = 1;
  cPARTSORTBYPART = 2;
  cPARTSORTBYCATEGORY = 3;
  //cPARTSORTBYPRICE = 3; // No price info yet
  cPARTSORTBYQUANTITY = 4;

procedure TFrmParts.ActExportExecute(Sender: TObject);
begin
//
end;

procedure TFrmParts.ActPrintPartsExecute(Sender: TObject);

  procedure PrintScrollBoxContents3(ScrollBox: TScrollBox);
  var
    PrintDialog: TPrintDialog;
    Bitmap: TBitmap;
    ScrollWidth, ScrollHeight: Integer;
    ScaleFactor: Double;
  begin
    PrintDialog := TPrintDialog.Create(nil);
    try
      if PrintDialog.Execute then begin
        Bitmap := TBitmap.Create;
        try
          // Get the full size of the scrollbox content
          ScrollWidth := ScrollBox.ClientWidth;
          ScrollHeight := ScrollBox.VertScrollBar.Range;

          // Set the bitmap size to the full content size
          Bitmap.Width := ScrollWidth;
          Bitmap.Height := ScrollHeight;

          // Paint the entire content to the bitmap
          ScrollBox.VertScrollBar.Position := 0;
          ScrollBox.HorzScrollBar.Position := 0;
          //ScrollBox.PaintTo(Bitmap.Canvas.Handle, 0, 0); // No need to print the scrollbox itself.

          for var I := 0 to ScrollBox.ControlCount - 1 do begin
            var ChildControl := TPanel(ScrollBox.Controls[I]);
            if ChildControl.Visible then begin
              // Adjust the control's position based on the scroll position
              ChildControl.PaintTo(Bitmap.Canvas.Handle, ChildControl.Left, ChildControl.Top);
            end;
          end;
          // Calculate scale factor to fit the content to the printer page
          ScaleFactor := Min(Printer.PageWidth / Bitmap.Width, Printer.PageHeight / Bitmap.Height);

          Printer.BeginDoc;
          try
            // Scale the content to fit the printer page
            Printer.Canvas.StretchDraw(Rect(0, 0, Round(Bitmap.Width * ScaleFactor), Round(Bitmap.Height * ScaleFactor)), Bitmap);
          finally
            Printer.EndDoc;
          end;
        finally
          Bitmap.Free;
        end;
      end;
    finally
      PrintDialog.Free;
    end;
  end;

begin
  // Note: Printing is broken - probably due to the deferred images.

  // get parts view, print
//  PrintScrollBoxContents3(DgSetParts);
end;

procedure TFrmParts.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;

  FPartObjectList.Free;

  inherited;
end;

procedure TFrmParts.FormCreate(Sender: TObject);
begin
  inherited;
  FInventoryPanels := TObjectList.Create;
  FInventoryPanels.OwnsObjects := True;

  FPartObjectList := TPartObjectList.Create;

  DgSetParts.DefaultColWidth := FTBGridSizePositionToPixels;
  DgSetParts.DefaultRowHeight := FGetGridHeight;
  DgSetParts.FixedCols := 0;
  DgSetParts.FixedRows := 0;

  FAdjustGrid;

  LblPartsGridSizePx.Caption := IntToStr(FTBGridSizePositionToPixels) + 'px';
end;

procedure TFrmParts.FormResize(Sender: TObject);
begin
  FAdjustGrid;
end;

function TFrmParts.FTBGridSizePositionToPixels: Integer;
begin
  Result := 32 + (TbGridSize.Position*16);
end;

function TFrmParts.FGetGridHeight: Integer;
begin
  if DgSetParts.DefaultColWidth >= 64 then
    Result := FTBGridSizePositionToPixels + 40 // 64 + 20 + 20 //todo: make extra info rows optional
  else if DgSetParts.DefaultColWidth >= 48 then
    Result := FTBGridSizePositionToPixels + 20
  else
    Result := FTBGridSizePositionToPixels;
end;

procedure TFrmParts.FAdjustGrid();
begin
  // recalculate visible column and rowcount for DgSetParts
  if FPartObjectList.Count = 0 then begin
    DgSetParts.ColCount := 0;
    DgSetParts.RowCount := 0;
  end else
    DgSetParts.ColCount := Max(1, Floor(DgSetParts.ClientWidth div (DgSetParts.DefaultColWidth+1)));

  if DgSetParts.ColCount <> FLastMaxCols then begin
    DgSetParts.RowCount := Ceil(FPartObjectList.Count / DgSetParts.ColCount);
    FLastMaxCols := DgSetParts.ColCount;
    DgSetParts.Invalidate;
  end;

  FLastMaxCols := DgSetParts.ColCount;
end;

procedure TFrmParts.TbGridSizeChange(Sender: TObject);
begin
  DgSetParts.DefaultColWidth := FTBGridSizePositionToPixels;
  DgSetParts.DefaultRowHeight := FGetGridHeight;
  FAdjustGrid;

  LblPartsGridSizePx.Caption := IntToStr(FTBGridSizePositionToPixels) + 'px'
end;

procedure TFrmParts.FHandleQueryAndHandleSetInventoryVersion(Query: TFDQuery);
begin
  var MaxVersion := 1;
  try
    MaxVersion := Query.FieldByName('max(version)').AsInteger;
  except
    // Something wrong.
  end;

  if MaxVersion > 1 then begin
    CbxInventoryVersion.Items.BeginUpdate;
    try
      CbxInventoryVersion.Items.Clear;
      for var I := 1 to MaxVersion do
        CbxInventoryVersion.Items.Add(I.ToString);
    finally
      CbxInventoryVersion.Items.EndUpdate;
    end;
  end;

  // Hide the inventory version display if there's only one version.
  LblInventoryVersion.Visible := MaxVersion > 1;
  CbxInventoryVersion.visible := MaxVersion > 1;
end;

procedure TFrmParts.ActSortByCategoryExecute(Sender: TObject);
begin
//
end;

procedure TFrmParts.ActSortByColorExecute(Sender: TObject);
begin
//
end;

procedure TFrmParts.ActSortByHueExecute(Sender: TObject);
begin
//
end;

procedure TFrmParts.ActSortByPartExecute(Sender: TObject);
begin
//
end;

procedure TFrmParts.ActSortByQuantityExecute(Sender: TObject);
begin
//
end;

procedure TFrmParts.ActToggleAscendingExecute(Sender: TObject);
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

procedure TFrmParts.ActToggleCheckboxModeExecute(Sender: TObject);
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

procedure TFrmParts.ActToggleIncludeSparePartsExecute(Sender: TObject);
begin
//
end;

procedure TFrmParts.ActViewPartExternalExecute(Sender: TObject);
begin
//
end;

procedure TFrmParts.BtnFilterClick(Sender: TObject);
begin
  var P := Mouse.CursorPos;
  // Show the popup menu at the mouse cursor position
  PopPartsFilter.Popup(P.X, P.Y);
end;

//procedure TFrmParts.FInvalidateGridCell(Grid: TDrawGrid; ACol, ARow: Integer);
//begin
//  var R := Grid.CellRect(ACol, ARow);
//  InvalidateRect(Grid.Handle, @R, False);
//end;

procedure TFrmParts.HandleClick(CellAction: TCellAction; Sender: TObject);
//var
//  Col, Row: Integer;
//  SquareRect: TRect;
begin
{  var Pt := DgSetParts.ScreenToClient(Mouse.CursorPos);
  DgSetParts.MouseToCell(Pt.X, Pt.Y, Col, Row);

  var SquareSize := 16;
  SquareRect := DgSetParts.CellRect(Col, Row);
  SquareRect.Right := SquareRect.Left + SquareSize;
  SquareRect.Bottom := SquareRect.Top + SquareSize;

  if PtInRect(SquareRect, Pt) then begin
    FLastCellCol := Col;
    FLastCellRow := Row;
    FLastCellAction := CellAction;
    FInvalidateGridCell(DgSetParts, Col, Row);
  end;   }
end;

procedure TFrmParts.DgSetPartsClick(Sender: TObject);
begin
//  HandleClick(caClick, Sender);
end;

procedure TFrmParts.DgSetPartsMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
//  if Button = mbRight then
//    HandleClick(caRightClick, Sender);
end;

procedure TFrmParts.DgSetPartsSelectCell(Sender: TObject; ACol, ARow: LongInt; var CanSelect: Boolean);
begin
  var Idx := FGetIndexByRowAndCol(ACol, ARow);
  if (Idx >= 0) and (Idx<FPartObjectList.Count) then begin
    var PartObject := FPartObjectList[Idx];
    //"40211 (partcount*), This is a part description"
    var NumParts := '';
    If PartObject.Quantity <> 0 then
      NumParts := Format(' (%d%s)', [PartObject.Quantity, IfThen(PartObject.IsSpare, '*','')]);
    var Year := '';
    SbResults.Panels[1].Text := Format('%s%s, %s', [PartObject.PartNum, NumParts, PartObject.PartName]);
  end else
    SbResults.Panels[1].Text := '';
end;

procedure TFrmParts.DgSetPartsDblClick(Sender: TObject);
begin
//  HandleClick(caDoubleClick, Sender);
end;

function TFrmParts.FGetIndexByRowAndCol(ACol, ARow: Integer): Integer;
begin
  // Get the index of the visible item in the bjectList.
  Result := (ARow * DgSetParts.ColCount) + ACol;
end;

procedure TFrmParts.DgSetPartsDrawCell(Sender: TObject; ACol, ARow: LongInt; Rect: TRect; State: TGridDrawState);
begin
  var Idx := FGetIndexByRowAndCol(ACol, ARow);
  if (Idx >= 0) and (Idx<FPartObjectList.Count) then begin
    var PartObject := FPartObjectList[Idx];
    var ImageUrl := PartObject.ImgUrl;

    //TPicture
    if FImageCache <> nil then begin
      var Picture := FImageCache.GetImage(ImageUrl);
    //  ImageList1.draw
      if Assigned(Picture) and Assigned(Picture.Graphic) then begin
        // Center the image in the cell (optional)
  //      var ImgLeft := Rect.Left + (Rect.Width - Picture.Width) div 2;
  //      var ImgTop := Rect.Top + (Rect.Height - Picture.Height) div 2;
        var ImageRect := Rect;
        if DgSetParts.DefaultColWidth >= 64 then
          ImageRect.Bottom := ImageRect.Bottom - 40 // 64 -20 -20
        else if DgSetParts.DefaultColWidth >= 48 then
          ImageRect.Bottom := ImageRect.Bottom - 20;
        DgSetParts.Canvas.StretchDraw(ImageRect, Picture.Graphic);
      end;
    end;


{    // Draw cell background (optional, for selection highlight)
    if gdSelected in State then
      DgSetParts.Canvas.Brush.Color := clHighlight
    else
      DgSetParts.Canvas.Brush.Color := clWindow;
    DgSetParts.Canvas.FillRect(Rect);    }

    // Determine square color based on last action
{    var SquareColor := clRed;
    if (ACol = FLastCellCol) and (ARow = FLastCellRow) then begin
      case FLastCellAction of
        caClick:        SquareColor := clGreen;
        caDoubleClick:  SquareColor := clBlue;
        caRightClick:   SquareColor := clPurple;
      end;
    end;}

    // Draw a small square (e.g., 16x16) in the top-left of the cell
    {var SquareSize := 16;
    SquareRect := Rect;
    SquareRect.Right := SquareRect.Left + SquareSize;
    SquareRect.Bottom := SquareRect.Top + SquareSize;
    DgSetParts.Canvas.Brush.Color := SquareColor;
    DgSetParts.Canvas.FillRect(SquareRect);}

    // Inforow 1
    // Draw example text next to the square
    DgSetParts.Canvas.Brush.Style := bsClear;
    //ExampleText := Format('Cell %d,%d', [ACol, ARow]);

    if DgSetParts.DefaultColWidth >= 64 then
      DgSetParts.Canvas.TextOut(Rect.Left, Rect.Bottom - 38, PartObject.PartNum);

    if DgSetParts.DefaultColWidth >= 48 then begin
      var PartCount := '';
      if PartObject.IsSpare then
        PartCount := Format('%dx*', [PartObject.Quantity])
      else
        PartCount := Format('%dx', [PartObject.Quantity]); // todo: 999/999
      DgSetParts.Canvas.TextOut(Rect.Left, Rect.Bottom - 18, PartCount);
    end;

    {if DgSetParts.DefaultColWidth > 32 then begin
      // "More info" icon
      ImageList1.Draw(DgSetParts.Canvas, Rect.Right - 18, Rect.Bottom - 38, 1, True);
    end;}
  end;
end;

procedure TFrmParts.LoadPartsBySet(const set_num: String);

  procedure FQueryAndHandleSetFields(Query: TFDQuery);
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
          //FHandleQueryAndHandleSetFields(Query);
          Self.Caption := Format(StrFrmSetTitle, [set_num, Query.FieldByName('name').AsString]);
        end;
      finally
        Query.Close; // Close the query when done
      end;
    except
      //
    end;
  end;

  procedure FQueryAndHandleSetInventoryVersion(Query: TFDQuery);
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

begin
  // No point loading the same set as is already being shown.
  if set_num = FSetNum then
    Exit;

  FSetNum := set_num;
  Self.Caption := 'Lego set: ' + set_num; // + set name

  //var Stopwatch := TStopWatch.Create;
  //Stopwatch.Start;
  try
    // Clean up the list before adding new results
    for var I:=FInventoryPanels.Count-1 downto 0 do
      FInventoryPanels.Delete(I);

    //LvTagData.Clear;
    var SqlConnection := FrmMain.AcquireConnection;
    var FDQuery := TFDQuery.Create(nil);
    try
      // Set up the query
      FDQuery.Connection := SqlConnection;

      FQueryAndHandleSetFields(FDQuery);
      FQueryAndHandleSetInventoryVersion(FDQuery);

      var InventoryVersion := StrToIntDef(CbxInventoryVersion.Text, 1);
      FDQuery.SQL.Text := 'SELECT ip.part_num, p.name as partname, ip.quantity, CASE WHEN ip.is_spare = ''True'' THEN 1 ELSE 0 END AS is_spare,' +
                          ' ip.img_url, c.name as colorname, CASE WHEN c.is_trans = ''True'' THEN 1 ELSE 0 END AS is_trans, c.rgb' +
                          ' FROM inventories' +
                          ' LEFT JOIN inventory_parts ip ON ip.inventory_id = inventories.id' +
                          ' LEFT JOIN colors c ON c.id = ip.color_id' +
                          ' LEFT JOIN parts p ON p.part_num = ip.part_num' +
                          ' WHERE set_num = :Param1' +
                          ' AND version = :Param2';
                          //Todo: expand query with join to the parts you selected for this set
      var Params := FDQuery.Params;
      Params.ParamByName('Param1').AsString := set_num;
      Params.ParamByName('Param2').AsInteger := InventoryVersion;

      FPartObjectList.LoadFromQuery(FDQuery);

      SbResults.Panels[0].Text := 'Results: ' + IntToStr(FPartObjectList.Count);

      FLastMaxCols := -1; // Force an invalidate
      FAdjustGrid;
    finally
      FDQuery.Free;
      FrmMain.ReleaseConnection(SqlConnection);
    end;
  finally
    begin
      //Stopwatch.Stop;
      //Enable for sql performance testing:
      //ShowMessage('Finished in: ' + IntToStr(Stopwatch.ElapsedMilliseconds) + 'ms');
    end;
  end;
end;

end.

