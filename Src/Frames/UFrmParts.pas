unit UFrmParts;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Imaging.pngimage,
  Contnrs,
  FireDAC.Comp.Client, FireDAC.Stan.Param,
  UConfig, UImageCache, Vcl.Menus, System.Actions, Vcl.ActnList, Vcl.Buttons,
  UPart,
  System.ImageList, Vcl.ImgList, Vcl.Grids;

type
  TCellAction = (caNone, caLeftClick, caDoubleClick, caRightClick);
  TPartsMode = (caView, caEdit);

  TFrmParts = class(TForm)
    Panel1: TPanel;
    LblInventoryVersion: TLabel;
    CbxInventoryVersion: TComboBox;
    BtnFilter: TButton;
    PopPartsFilter: TPopupMenu;
    Sort1: TMenuItem;
    MnuSortAscending: TMenuItem;
    N1: TMenuItem;
    MnuSortByColor: TMenuItem;
    MnuSortByHue: TMenuItem;
    MnuSortByPart: TMenuItem;
    MnuSortByCategory: TMenuItem;
    MnuSortByQuantity: TMenuItem;
    MnuIncludeSpareParts: TMenuItem;
    ActionList1: TActionList;
    ActPrintParts: TAction;
    ActExport: TAction;
    ActToggleIncludeSpareParts: TAction;
    ActToggleAscending: TAction;
    ActSortByColor: TAction;
    ActSortByHue: TAction;
    ActSortByPart: TAction;
    ActSortByCategory: TAction;
    ActSortByQuantity: TAction;
    ActViewPartExternal: TAction;
    ImageList16: TImageList;
    SbResults: TStatusBar;
    LblPartsGridSize: TLabel;
    DgSetParts: TDrawGrid;
    TbGridSize: TTrackBar;
    MnuShowPartCount: TMenuItem;
    MnuShowPartnum: TMenuItem;
    LblPartsGridSizePx: TLabel;
    PopGridRightClick: TPopupMenu;
    Viewpartexternally1: TMenuItem;
    ImageList32: TImageList;
    Button2: TButton;
    Button1: TButton;
    ActPartsInvertComplete: TAction;
    ActPartsCompleteAll: TAction;
    ActPartsRemoveAll: TAction;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    ActToggleIncludeNonSpare: TAction;
    MnuIncludeNonSpareParts: TMenuItem;
    ActShowCount: TAction;
    ActShowPartNum: TAction;
    procedure FormCreate(Sender: TObject);
    procedure ActPrintPartsExecute(Sender: TObject);
    procedure BtnFilterClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ActToggleAscendingExecute(Sender: TObject);
    procedure ActSortByColorExecute(Sender: TObject);
    procedure ActSortByHueExecute(Sender: TObject);
    procedure ActSortByPartExecute(Sender: TObject);
    procedure ActSortByCategoryExecute(Sender: TObject);
    procedure ActSortByQuantityExecute(Sender: TObject);
    procedure ActToggleIncludeSparePartsExecute(Sender: TObject);
    procedure ActExportExecute(Sender: TObject);
    procedure DgSetPartsDrawCell(Sender: TObject; ACol, ARow: LongInt; Rect: TRect; State: TGridDrawState);
    procedure DgSetPartsDblClick(Sender: TObject);
    procedure DgSetPartsMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormResize(Sender: TObject);
    procedure TbGridSizeChange(Sender: TObject);
    procedure DgSetPartsSelectCell(Sender: TObject; ACol, ARow: LongInt;  var CanSelect: Boolean);
    procedure ActViewPartExternalExecute(Sender: TObject);
    procedure ActPartsInvertCompleteExecute(Sender: TObject);
    procedure ActPartsCompleteAllExecute(Sender: TObject);
    procedure ActPartsRemoveAllExecute(Sender: TObject);
    procedure MnuShowPartnumClick(Sender: TObject);
    procedure ActToggleIncludeNonSpareExecute(Sender: TObject);
    procedure ActShowCountExecute(Sender: TObject);
    procedure ActShowPartNumExecute(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FPartsMode: TPartsMode;
    FConfig: TConfig;
    FImageCache: TImageCache;
    FInventoryPanels: TObjectList;
    FPartObjectList: TPartObjectList;
//    FCurMaxCols: Integer;
    FSetNum: String;
    FBSSetID: Integer;
    //FCheckboxMode: Boolean;
    FLastMaxCols: Integer;
//    FLastCellAction: TCellAction;
    procedure FSetConfig(Config: TConfig);
    procedure FSaveSortSettings;
    procedure FHandleQueryAndHandleSetInventoryVersion(Query: TFDQuery);
    procedure FInvalidateGridCell(Grid: TDrawGrid; ACol, ARow: Integer);
    procedure FAdjustGrid();
    function FGetIndexByRowAndCol(ACol, ARow: Integer): Integer;
    function FGetGridWidth: Integer;
    function FGetGridHeight: Integer;
    procedure FModifyQuantity(PartObject: TPartObject; Amount: Integer; Increment: Boolean);
    procedure FDrawPartCell(ACanvas: TCanvas; ACol, ARow: Integer; Rect: TRect; AForPrint: Boolean = False);
    procedure FHandleClick(CellAction: TCellAction; Sender: TObject);
    procedure FUncheckAllSortExcept(Sender: TObject);
    procedure FSetDefaultColumnDimensionsAndAdjustGrid;
  public
    { Public declarations }
    property Config: TConfig read FConfig write FSetConfig;
    property ImageCache: TImageCache read FImageCache write FImageCache;
    procedure LoadPartsBySet(const set_num: String; const ForceRefresh: Boolean);
    procedure LoadPartCountByID(const BSSetID: Integer);
    property SetNum: String read FSetNum; // Read only
    //property BSSetID: Integer read FBSSetID;
    property PartsMode: TPartsMode read FPartsMode write FPartsMode;
  end;

implementation

{$R *.dfm}
uses
  ShellAPI, Printers, CommCtrl, UITypes,
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

procedure TFrmParts.ActPartsCompleteAllExecute(Sender: TObject);
begin
  if MessageDlg(StrMsgSetPartsToComplete, mtConfirmation, mbYesNo, 0) <> mrYes then
    Exit;

  var InvVersion := 1; //StrToIntDef(CbxInventoryVersion.Text, 1);

  var SqlConnection := FrmMain.AcquireConnection;
  var FDQuery := TFDQuery.Create(nil);
  var FDTransaction := TFDTransaction.Create(nil);
  try
    FDQuery.Connection := SqlConnection;
    FDTransaction.Connection := SqlConnection;

    FDTransaction.StartTransaction;
    try
      // Update existing rows
      FDQuery.SQL.Text :=
        'UPDATE BSDBPartsInventory ' +
        'SET quantity = ( ' +
        '  SELECT ip.quantity ' +
        '  FROM inventories ' +
        '  JOIN inventory_parts ip ON ip.inventory_id = inventories.id ' +
        '  WHERE inventories.set_num = :set_num ' +
        '    AND inventories.version = :version ' +
        '    AND ip.inventory_id = BSDBPartsInventory.InventoryID ' +
        '    AND ip.part_num     = BSDBPartsInventory.part_num ' +
        '    AND ip.color_id     = BSDBPartsInventory.color_id ' +
        '    AND ip.is_spare     = BSDBPartsInventory.is_spare ' +
        '  LIMIT 1 ' +
        ') ' +
        'WHERE EXISTS ( ' +
        '  SELECT 1 ' +
        '  FROM inventories ' +
        '  JOIN inventory_parts ip ON ip.inventory_id = inventories.id ' +
        '  WHERE inventories.set_num = :set_num ' +
        '    AND inventories.version = :version ' +
        '    AND ip.inventory_id = BSDBPartsInventory.InventoryID ' +
        '    AND ip.part_num     = BSDBPartsInventory.part_num ' +
        '    AND ip.color_id     = BSDBPartsInventory.color_id ' +
        '    AND ip.is_spare     = BSDBPartsInventory.is_spare ' +
        ');';
      FDQuery.Params.ParamByName('set_num').AsString := FSetNum;
      FDQuery.Params.ParamByName('version').AsInteger := InvVersion;
      FDQuery.ExecSQL;

      // Insert missing rows
      FDQuery.SQL.Text :=
        'INSERT INTO BSDBPartsInventory (InventoryID, Part_Num, color_id, is_spare, quantity, BSSetID) ' +
        'SELECT ip.inventory_id, ip.part_num, ip.color_id, ip.is_spare, ip.quantity, :BSSetID ' +
        'FROM inventories ' +
        'JOIN inventory_parts ip ON ip.inventory_id = inventories.id ' +
        'LEFT JOIN BSDBPartsInventory bp ' +
        '  ON bp.inventoryID = ip.inventory_id ' +
        ' AND bp.part_num    = ip.part_num ' +
        ' AND bp.color_id    = ip.color_id ' +
        ' AND bp.is_spare    = ip.is_spare ' +
        'WHERE inventories.set_num = :set_num ' +
        '  AND inventories.version = :version ' +
        '  AND bp.id IS NULL;';
      FDQuery.Params.ParamByName('BSSetID').AsInteger := FBSSetID;
      FDQuery.Params.ParamByName('set_num').AsString := FSetNum;
      FDQuery.Params.ParamByName('version').AsInteger := InvVersion;
      FDQuery.ExecSQL;

      FDTransaction.Commit;

      // Update the parts manually instead of getting the data by query:
      for var PartObject in FPartObjectList do
        PartObject.CurQuantity := PartObject.MaxQuantity;
    except
      FDTransaction.Rollback;
      raise;
    end;
  finally
    FDQuery.Free;
    FDTransaction.Free;
    FrmMain.ReleaseConnection(SqlConnection);
  end;

  DgSetParts.Invalidate;
end;

procedure TFrmParts.ActPartsInvertCompleteExecute(Sender: TObject);
begin
  if MessageDlg(StrMsgInvertPartsSelection, mtConfirmation, mbYesNo, 0) <> mrYes then
    Exit;

  // Invert "max -> 0" and "0 -> max" for current set/version in one atomic operation.
  var SqlConnection := FrmMain.AcquireConnection;
  var FDQuery := TFDQuery.Create(nil);
  var FDTransaction := TFDTransaction.Create(nil);
  try
    FDQuery.Connection := SqlConnection;
    FDTransaction.Connection := SqlConnection;
    var InvVersion := 1; //StrToIntDef(CbxInventoryVersion.Text, 1);

    FDTransaction.StartTransaction;
    try
      FDQuery.SQL.Text := 'UPDATE BSDBPartsInventory ' +
                          'SET quantity = CASE ' +
                          '  WHEN quantity = (SELECT ip.quantity FROM inventories ' +
                          '                   JOIN inventory_parts ip ON ip.inventory_id = inventories.id ' +
                          '                   WHERE inventories.set_num = :setnum AND inventories.version = :version ' +
                          '                     AND ip.inventory_id = BSDBPartsInventory.InventoryID ' +
                          '                     AND ip.part_num = BSDBPartsInventory.part_num ' +
                          '                     AND ip.color_id = BSDBPartsInventory.color_id ' +
                          '                     AND ip.is_spare = BSDBPartsInventory.is_spare ' +
                          '                   LIMIT 1) THEN 0 ' +
                          '  WHEN quantity = 0 THEN (SELECT ip.quantity FROM inventories ' +
                          '                          JOIN inventory_parts ip ON ip.inventory_id = inventories.id ' +
                          '                          WHERE inventories.set_num = :setnum AND inventories.version = :version ' +
                          '                            AND ip.inventory_id = BSDBPartsInventory.InventoryID ' +
                          '                            AND ip.part_num = BSDBPartsInventory.part_num ' +
                          '                            AND ip.color_id = BSDBPartsInventory.color_id ' +
                          '                            AND ip.is_spare = BSDBPartsInventory.is_spare ' +
                          '                          LIMIT 1) ' +
                          '  ELSE quantity END ' +
                          'WHERE EXISTS (SELECT 1 FROM inventories ' +
                          '              JOIN inventory_parts ip ON ip.inventory_id = inventories.id ' +
                          '              WHERE inventories.set_num = :setnum AND inventories.version = :version ' +
                          '                AND ip.inventory_id = BSDBPartsInventory.InventoryID ' +
                          '                AND ip.part_num = BSDBPartsInventory.part_num ' +
                          '                AND ip.color_id = BSDBPartsInventory.color_id ' +
                          '                AND ip.is_spare = BSDBPartsInventory.is_spare);';

      FDQuery.Params.ParamByName('setnum').AsString := FSetNum;
      FDQuery.Params.ParamByName('version').AsInteger := InvVersion;
      FDQuery.ExecSQL;

      //-- insert any rows that don't exist yet
      FDQuery.SQL.Text := 'INSERT INTO BSDBPartsInventory (InventoryID, Part_Num, color_id, is_spare, quantity, BSSetID) ' +
                          'SELECT ip.inventory_id, ip.part_num, ip.color_id, ip.is_spare, ip.quantity, :BSSetID ' +
                          'FROM inventories ' +
                          'JOIN inventory_parts ip ON ip.inventory_id = inventories.id ' +
                          'LEFT JOIN BSDBPartsInventory bp ' +
                          '  ON  bp.inventoryID = ip.inventory_id ' +
                          '  AND bp.part_num    = ip.part_num ' +
                          '  AND bp.color_id    = ip.color_id ' +
                          '  AND bp.is_spare    = ip.is_spare ' +
                          'WHERE inventories.set_num = :setnum ' +
                          '  AND inventories.version = :version ' +
                          '  AND bp.id IS NULL;';

      FDQuery.Params.ParamByName('BSSetID').AsInteger := FBSSetID;
      FDQuery.Params.ParamByName('setnum').AsString := FSetNum;
      FDQuery.Params.ParamByName('version').AsInteger := InvVersion;
      FDQuery.ExecSQL;

      FDTransaction.Commit;

      // Update the parts manually instead of getting the data by query:
      // set any part that is 0 to max
      // set any part that is maxed to zero
      for var PartObject in FPartObjectList do begin
        // skip parts without a defined max - should not happen.
        if PartObject.MaxQuantity = 0 then
          Continue;

        if PartObject.CurQuantity = 0 then
          PartObject.CurQuantity := PartObject.MaxQuantity
        else if PartObject.CurQuantity >= PartObject.MaxQuantity then
          PartObject.CurQuantity := 0;
      end;
    except
      FDTransaction.Rollback;
      raise;
    end;
  finally
    FDQuery.Free;
    FDTransaction.Free;
    FrmMain.ReleaseConnection(SqlConnection);
  end;

  DgSetParts.Invalidate;
end;

procedure TFrmParts.ActPartsRemoveAllExecute(Sender: TObject);
begin
  if MessageDlg(StrMsgSetPartsToZero, mtConfirmation, mbYesNo, 0) = mrYes then begin
    for var PartObject in FPartObjectList do
      PartObject.CurQuantity := 0;

    var SqlConnection := FrmMain.AcquireConnection;
    var FDQuery := TFDQuery.Create(nil);
    try
      FDQuery.Connection := SqlConnection;

      var SqlStr := '';
      if FBSSetID <> 0 then begin
        SqlStr := 'UPDATE BSDBPartsInventory' +
                  ' SET quantity = 0' +
                  ' WHERE BSSetID = :BSSetID;';
      end;

      FDQuery.SQL.Text := SqlStr;

      var Params := FDQuery.Params;
      Params.ParamByName('BSSetID').asInteger := FBSSetID;
      FDQuery.ExecSQL;
    finally
      FDQuery.Free;
      FrmMain.ReleaseConnection(SqlConnection);
    end;

    DgSetParts.Invalidate;
  end;
end;

procedure TFrmParts.ActPrintPartsExecute(Sender: TObject);

  procedure PrintScrollBoxContents3(Box: TDrawGrid);
  var
    PrintDialog: TPrintDialog;
    Bitmap: TBitmap;
    ScaleFactor: Double;
  begin
    PrintDialog := TPrintDialog.Create(nil);
    try
      if PrintDialog.Execute then begin
        Bitmap := TBitmap.Create;
        try
          // Get the full size of the scrollbox content
          // Calculate full content size (all columns and rows)
          var TotalCols := Box.ColCount;
          var TotalRows := Box.RowCount;
          var CellW := Box.DefaultColWidth;
          var CellH := Box.DefaultRowHeight;

          var FullWidth := Max(1, TotalCols) * CellW;
          var FullHeight := Max(1, TotalRows) * CellH;

          // Guard against extremely large bitmaps
          if (FullWidth < 1) or (FullHeight < 1) then
            Exit;

          Bitmap.Width := FullWidth;
          Bitmap.Height := FullHeight;

          // Fill background
          Bitmap.Canvas.Brush.Color := clWhite;
          Bitmap.Canvas.FillRect(Rect(0,0,Bitmap.Width,Bitmap.Height));

          // Render every cell into the bitmap using the same drawing logic as the grid
          for var R := 0 to TotalRows - 1 do begin
            for var C := 0 to TotalCols - 1 do begin
              var CellRect: TRect;
              CellRect.Left := C * CellW;
              CellRect.Top := R * CellH;
              CellRect.Right := CellRect.Left + CellW;
              CellRect.Bottom := CellRect.Top + CellH;

              FDrawPartCell(Bitmap.Canvas, C, R, CellRect, True);
            end;
          end;
{          for var I := 0 to Box.ControlCount - 1 do begin
            var ChildControl := TPanel(ScrollBox.Controls[I]);
            if ChildControl.Visible then begin
              // Adjust the control's position based on the scroll position
              ChildControl.PaintTo(Bitmap.Canvas.Handle, ChildControl.Left, ChildControl.Top);
            end;
          end;   }
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
  //todo: fix

  // get parts view, print
  PrintScrollBoxContents3(DgSetParts);
end;

procedure TFrmParts.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;

  FPartObjectList.Free;

  inherited;
end;

procedure TFrmParts.FSetDefaultColumnDimensionsAndAdjustGrid;
begin
  DgSetParts.DefaultColWidth := FGetGridWidth;
  DgSetParts.DefaultRowHeight := FGetGridHeight;

  FAdjustGrid;
end;

procedure TFrmParts.FSetConfig(Config: TConfig);
begin
  FConfig := Config;

  MnuShowPartCount.Checked := FConfig.WPartsShowPartCount;
  MnuShowPartnum.Checked := FConfig.WPartsShowPartnum;
  MnuIncludeNonSpareParts.Checked := FConfig.WPartsIncludeNonSpareParts;
  MnuIncludeSpareParts.Checked := FConfig.WPartsIncludeSpareParts;
  MnuSortByCategory.Checked := FConfig.WPartsSortByCategory;
  MnuSortByColor.Checked := FConfig.WPartsSortByColor;
  MnuSortByHue.Checked := FConfig.WPartsSortByHue;
  MnuSortByPart.Checked := FConfig.WPartsSortByPart;
  MnuSortByQuantity.Checked := FConfig.WPartsSortByQuantity;
  MnuSortAscending.Checked := FConfig.WPartsSortAscending;

  DgSetParts.FixedCols := 0;
  DgSetParts.FixedRows := 0;
  FSetDefaultColumnDimensionsAndAdjustGrid;

  LblPartsGridSizePx.Caption := IntToStr(FGetGridWidth) + 'px';
end;

procedure TFrmParts.FormCreate(Sender: TObject);
begin
  inherited;
  FInventoryPanels := TObjectList.Create;
  FInventoryPanels.OwnsObjects := True;

  FPartObjectList := TPartObjectList.Create;
end;

procedure TFrmParts.FormDestroy(Sender: TObject);
begin
  FConfig.Save(csPARTSWINDOWFILTERS);
end;

procedure TFrmParts.FormResize(Sender: TObject);
begin
  FAdjustGrid;
end;

function TFrmParts.FGetGridWidth: Integer;
begin
  Result := 32 + (TbGridSize.Position*16);
end;

function TFrmParts.FGetGridHeight: Integer;
begin
  if Config <> nil then begin
    if Config.WPartsShowPartnum and (DgSetParts.DefaultColWidth >= 64) then begin
      if Config.WPartsShowPartCount then
        Result := FGetGridWidth + 40  // 64 + 20 + 20
      else
        Result := FGetGridWidth + 20; // 64 + 20
    end else if Config.WPartsShowPartCount and (DgSetParts.DefaultColWidth >= 48) then
      Result := FGetGridWidth + 20
    else
      Result := FGetGridWidth;
  end else
    Result := FGetGridWidth;
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
  DgSetParts.DefaultColWidth := FGetGridWidth;
  DgSetParts.DefaultRowHeight := FGetGridHeight;
  FAdjustGrid;

  LblPartsGridSizePx.Caption := IntToStr(FGetGridWidth) + 'px'
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

procedure TFrmParts.ActShowCountExecute(Sender: TObject);
begin
  MnuShowPartCount.Checked := not MnuShowPartCount.Checked;

  Config.WPartsShowPartCount := MnuShowPartCount.Checked;

  FSetDefaultColumnDimensionsAndAdjustGrid;

  DgSetParts.Invalidate;
end;

procedure TFrmParts.ActShowPartNumExecute(Sender: TObject);
begin
  MnuShowPartnum.Checked := not MnuShowPartnum.Checked;

  Config.WPartsShowPartnum := MnuShowPartnum.Checked;

  FSetDefaultColumnDimensionsAndAdjustGrid;

  DgSetParts.Invalidate;
end;

procedure TFrmParts.ActToggleIncludeNonSpareExecute(Sender: TObject);
begin
  // Needs minimum of 1 checked.
  MnuIncludeNonSpareParts.Checked := not MnuIncludeNonSpareParts.Checked;
  if not MnuIncludeNonSpareParts.Checked and not MnuIncludeSpareParts.Checked then
    MnuIncludeSpareParts.Checked := True;

  FConfig.WPartsIncludeSpareParts := MnuIncludeSpareParts.Checked;
  FConfig.WPartsIncludeNonSpareParts := MnuIncludeNonSpareParts.Checked;

  LoadPartsBySet(FSetNum, True);
end;

procedure TFrmParts.ActToggleIncludeSparePartsExecute(Sender: TObject);
begin
  // Needs minimum of 1 checked.
  MnuIncludeSpareParts.Checked := not MnuIncludeSpareParts.Checked;
  if not MnuIncludeNonSpareParts.Checked and not MnuIncludeSpareParts.Checked then
    MnuIncludeNonSpareParts.Checked := True;

  FConfig.WPartsIncludeSpareParts := MnuIncludeSpareParts.Checked;
  FConfig.WPartsIncludeNonSpareParts := MnuIncludeNonSpareParts.Checked;

  LoadPartsBySet(FSetNum, True);
end;

procedure TFrmParts.FUncheckAllSortExcept(Sender: TObject);
begin
  if Sender <> MnuSortByCategory then
    MnuSortByCategory.Checked := False;
  if Sender <> MnuSortByColor then
    MnuSortByColor.Checked := False;
  if Sender <> MnuSortByHue then
    MnuSortByHue.Checked := False;
  if Sender <> MnuSortByPart then
    MnuSortByPart.Checked := False;
  if Sender <> MnuSortByQuantity then
    MnuSortByQuantity.Checked := False;
end;

procedure TFrmParts.FSaveSortSettings;
begin
  FConfig.WPartsSortByCategory := MnuSortByCategory.Checked;
  FConfig.WPartsSortByColor := MnuSortByColor.Checked;
  FConfig.WPartsSortByHue := MnuSortByHue.Checked;
  FConfig.WPartsSortByPart := MnuSortByPart.Checked;
  FConfig.WPartsSortByQuantity := MnuSortByQuantity.Checked;
end;

procedure TFrmParts.ActSortByCategoryExecute(Sender: TObject);
begin
  MnuSortByCategory.Checked := not MnuSortByCategory.Checked;
  if MnuSortByCategory.Checked then
    FUncheckAllSortExcept(MnuSortByCategory);
  FSaveSortSettings;
  LoadPartsBySet(FSetNum, True);
end;

procedure TFrmParts.ActSortByColorExecute(Sender: TObject);
begin
  MnuSortByColor.Checked := not MnuSortByColor.Checked;
  if MnuSortByColor.Checked then
    FUncheckAllSortExcept(MnuSortByColor);
  FSaveSortSettings;
  LoadPartsBySet(FSetNum, True);
end;

procedure TFrmParts.ActSortByHueExecute(Sender: TObject);
begin
  MnuSortByHue.Checked := not MnuSortByHue.Checked;
  if MnuSortByHue.Checked then
    FUncheckAllSortExcept(MnuSortByHue);
  FSaveSortSettings;
  LoadPartsBySet(FSetNum, True);
end;

procedure TFrmParts.ActSortByPartExecute(Sender: TObject);
begin
  MnuSortByPart.Checked := not MnuSortByPart.Checked;
  if MnuSortByPart.Checked then
    FUncheckAllSortExcept(MnuSortByPart);
  FSaveSortSettings;
  LoadPartsBySet(FSetNum, True);
end;

procedure TFrmParts.ActSortByQuantityExecute(Sender: TObject);
begin
  MnuSortByQuantity.Checked := not MnuSortByQuantity.Checked;
  if MnuSortByQuantity.Checked then
    FUncheckAllSortExcept(MnuSortByQuantity);
  FSaveSortSettings;
  LoadPartsBySet(FSetNum, True);
end;

procedure TFrmParts.ActToggleAscendingExecute(Sender: TObject);
begin
  MnuSortAscending.Checked := not MnuSortAscending.Checked;
  FConfig.WPartsSortAscending := MnuSortAscending.Checked;
  LoadPartsBySet(FSetNum, True);
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

procedure TFrmParts.FInvalidateGridCell(Grid: TDrawGrid; ACol, ARow: Integer);
begin
  var R := Grid.CellRect(ACol, ARow);
  InvalidateRect(Grid.Handle, @R, False);
end;

procedure TFrmParts.FHandleClick(CellAction: TCellAction; Sender: TObject);

  function IsCtrlDown: Boolean;
  begin
    Result := (GetKeyState(VK_CONTROL) and $8000) <> 0;
  end;

  function IsShiftDown: Boolean;
  begin
    Result := (GetKeyState(VK_SHIFT) and $8000) <> 0;
  end;

  function IsCtrlShiftDown: Boolean;
  begin
    Result := IsCtrlDown and IsShiftDown;
  end;

var
  Col, Row: Integer;
begin
  var Pt := DgSetParts.ScreenToClient(Mouse.CursorPos);
  DgSetParts.MouseToCell(Pt.X, Pt.Y, Col, Row);

  var Idx := FGetIndexByRowAndCol(Col, Row);
  if (Idx >= 0) and (Idx<FPartObjectList.Count) then begin
    // Ignore doubleclick here.
    if CellAction = caDoubleClick then begin
      if FPartsMode = caEdit then
        Exit
      else begin
        case FConfig.PartsListDoubleClickAction of
          caVIEWEXTERNAL:
            ActViewPartExternal.Execute;
          //else // caVIEW
            //ActViewPart.Execute;
        end;
      end;
    end;

    var PartObject := FPartObjectList[Idx];
    var Qty := Config.PartIncrementClick;
    if IsCtrlDown and IsShiftDown then
      Qty := Config.PartIncrementCtrlShiftClick
    else if IsCtrlDown then
      Qty := Config.PartIncrementCtrlClick
    else if IsShiftDown then
      Qty := Config.PartIncrementShiftClick;

    FModifyQuantity(PartObject, Qty, (CellAction = caLeftClick) or (CellAction = caDoubleClick));
    FInvalidateGridCell(DgSetParts, Col, Row);
  end;

{Click values:
- normal: +1/-1
- shift: +10/-10
- ctrl: +50/-50
- ctrl+shift: +100/-100
  Or maybe set an incrementor button/mode. Also keyboard, +/- button
}
end;

procedure TFrmParts.FModifyQuantity(PartObject: TPartObject; Amount: Integer; Increment: Boolean);

  procedure FFDoUpdatePartQuantity(Query: TFDQuery; const PartObject: TPartObject);
  begin
    Query.SQL.Text := 'Update BSDBPartsInventory set quantity = :quantity where id = :id';
    try
      // Always use params to prevent injection and allow sql to reuse queryplans
      var Params := Query.Params;
      Params.ParamByName('quantity').AsInteger := PartObject.CurQuantity;
      Params.ParamByName('id').AsInteger := PartObject.BSPartID;

      Query.ExecSQL;
    except
      //
    end;
  end;

  procedure FFDoInsertPartQuantity(Query: TFDQuery; const PartObject: TPartObject);
  begin
    Query.SQL.Text := 'insert into BSDBPartsInventory (InventoryID, part_num, color_id, is_spare, quantity, BSSetID)' +
                      ' values (:InventoryID, :part_num, :color_id, :is_spare, :quantity, :BSSetID)';
    try
      // Always use params to prevent injection and allow sql to reuse queryplans
      var Params := Query.Params;
      Params.ParamByName('InventoryID').AsInteger := PartObject.InventoryID;
      Params.ParamByName('part_num').AsString := PartObject.PartNum;
      Params.ParamByName('color_id').AsInteger := PartObject.ColorID;
      Params.ParamByName('is_spare').AsBoolean:= PartObject.IsSpare;
      Params.ParamByName('quantity').AsInteger := PartObject.CurQuantity;
      Params.ParamByName('BSSetID').AsInteger := Self.FBSSetID;

      Query.ExecSQL;
    except
      //
    end;
  end;

  function FQueryMaxPartID(Query: TFDQuery): Integer;
  begin
    Result := 0;

    Query.SQL.Text := 'SELECT MAX(ID) AS maxid' +
                      ' FROM BSDBPartsInventory';
    try
      Query.Open; // Open the query to retrieve data

      try
        Query.First; // Move to the first row of the dataset

        if not Query.EOF then
          Result := StrToIntDef(Query.FieldByName('maxid').AsString, 0);
      finally
        Query.Close; // Close the query when done
      end;
    except
      //
    end;
  end;


begin
  if Increment then
    PartObject.CurQuantity := PartObject.CurQuantity + Amount
  else
    PartObject.CurQuantity := PartObject.CurQuantity - Amount;

  if Increment then begin
    if PartObject.CurQuantity > PartObject.MaxQuantity then
      PartObject.CurQuantity := PartObject.MaxQuantity;
  end else begin
    if PartObject.CurQuantity < 0 then
      PartObject.CurQuantity := 0;
  end;

  //var Stopwatch := TStopWatch.Create;
  //Stopwatch.Start;
  try
    var SqlConnection := FrmMain.AcquireConnection;
    var FDQuery := TFDQuery.Create(nil);
    try
      // Set up the query
      FDQuery.Connection := SqlConnection;

      //do query.
      if PartObject.BSPartID <> 0 then begin
        FFDoUpdatePartQuantity(FDQuery, PartObject);
      end else begin
        var FDTransaction := TFDTransaction.Create(nil);
        try
          FDTransaction.Connection := SqlConnection;
          FDTransaction.StartTransaction;
          try
            FFDoInsertPartQuantity(FDQuery, PartObject);
            PartObject.BSPartID := FQueryMaxPartID(FDQuery);

            FDTransaction.Commit;
          except
            FDTransaction.Rollback;
          end;
        finally
          FDTransaction.Free;
        end;
      end;
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

procedure TFrmParts.DgSetPartsMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbRight then
    FHandleClick(caRightClick, Sender)
  else if Button = mbLeft then
    FHandleClick(caLeftClick, Sender);
end;

procedure TFrmParts.DgSetPartsDblClick(Sender: TObject);
begin
  FHandleClick(caDoubleClick, Sender);
end;

procedure TFrmParts.DgSetPartsSelectCell(Sender: TObject; ACol, ARow: LongInt; var CanSelect: Boolean);
begin
  var Idx := FGetIndexByRowAndCol(ACol, ARow);
  if (Idx >= 0) and (Idx<FPartObjectList.Count) then begin
    var PartObject := FPartObjectList[Idx];
    //"40211 (partcount*), This is a part description"
    var NumParts := '';
    If PartObject.MaxQuantity <> 0 then
      NumParts := Format(' (%d%s)', [PartObject.MaxQuantity, IfThen(PartObject.IsSpare, '*','')]);
    var Year := '';
    SbResults.Panels[1].Text := Format('%s%s, %s', [PartObject.PartNum, NumParts, PartObject.PartName]);
  end else
    SbResults.Panels[1].Text := '';
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

    // Draw cell background (optional, for selection highlight)
    if FPartsMode = caEdit then begin
      if PartObject.CurQuantity = PartObject.MaxQuantity then
        DgSetParts.Canvas.Brush.Color := clGreen;
      DgSetParts.Canvas.FillRect(Rect);
    end;

    // TPicture
    if FImageCache <> nil then begin
      var Picture := FImageCache.GetImage(ImageUrl, cidMAX128);
      //  ImageList1.draw
      if Assigned(Picture) and Assigned(Picture.Graphic) then begin
        var ImageRect := Rect;
        if Config.WPartsShowPartnum and (DgSetParts.DefaultColWidth >= 64) then begin
          if Config.WPartsShowPartCount then
            ImageRect.Bottom := ImageRect.Bottom - 40  // 64 -20 -20
          else
            ImageRect.Bottom := ImageRect.Bottom - 20; // 64 -20
        end else if Config.WPartsShowPartCount and (DgSetParts.DefaultColWidth >= 48) then
          ImageRect.Bottom := ImageRect.Bottom - 20;
        DgSetParts.Canvas.StretchDraw(ImageRect, Picture.Graphic);
      end;
    end;

    DgSetParts.Canvas.Brush.Style := bsClear;

    if Config.WPartsShowPartnum and (DgSetParts.DefaultColWidth >= 64) then begin
      if Config.WPartsShowPartCount then
        DgSetParts.Canvas.TextOut(Rect.Left, Rect.Bottom - 38, PartObject.PartNum)
      else
        DgSetParts.Canvas.TextOut(Rect.Left, Rect.Bottom - 18, PartObject.PartNum);
    end;

    if Config.WPartsShowPartCount and (DgSetParts.DefaultColWidth >= 48) then begin
      var PartCount := '';
      if FPartsMode = caView then
        PartCount := Format('%dx', [PartObject.MaxQuantity])
      else
        PartCount := Format('%d/%d', [PartObject.CurQuantity, PartObject.MaxQuantity]);

      if PartObject.IsSpare then
        PartCount := PartCount + '*';

      DgSetParts.Canvas.TextOut(Rect.Left, Rect.Bottom - 18, PartCount);
    end;

    {if DgSetParts.DefaultColWidth > 32 then begin
      // "More info" icon
      ImageList1.Draw(DgSetParts.Canvas, Rect.Right - 18, Rect.Bottom - 38, 1, True);
    end;}
  end;
end;

procedure TFrmParts.FDrawPartCell(ACanvas: TCanvas; ACol, ARow: Integer; Rect: TRect; AForPrint: Boolean = False);
begin
  var Idx := FGetIndexByRowAndCol(ACol, ARow);
  if (Idx >= 0) and (Idx < FPartObjectList.Count) then begin
    var PartObject := FPartObjectList[Idx];
    var ImageUrl := PartObject.ImgUrl;

    // Draw cell background
    if FPartsMode = caEdit then begin
      if PartObject.CurQuantity = PartObject.MaxQuantity then begin
        if AForPrint then
          ACanvas.Brush.Color := TColor(RGB(210, 250, 210)) // much lighter green for printing
        else
          ACanvas.Brush.Color := clGreen;
      end else
        ACanvas.Brush.Color := clWindow;
      ACanvas.FillRect(Rect);
    end else begin
      ACanvas.Brush.Color := clWindow;
      ACanvas.FillRect(Rect);
    end;

    // Draw image if available
    if FImageCache <> nil then begin
      var Picture := FImageCache.GetImage(ImageUrl, cidMAX128);
      if Assigned(Picture) and Assigned(Picture.Graphic) then begin
        var ImageRect := Rect;
        if Config.WPartsShowPartnum and (DgSetParts.DefaultColWidth >= 64) then begin
          if Config.WPartsShowPartCount then
            ImageRect.Bottom := ImageRect.Bottom - 40
          else
            ImageRect.Bottom := ImageRect.Bottom - 20;
        end else if Config.WPartsShowPartCount and (DgSetParts.DefaultColWidth >= 48) then
          ImageRect.Bottom := ImageRect.Bottom - 20;

        ACanvas.StretchDraw(ImageRect, Picture.Graphic);
      end;
    end;

    // Draw texts
    ACanvas.Brush.Style := bsClear;

    if Config.WPartsShowPartnum and (DgSetParts.DefaultColWidth >= 64) then begin
      if Config.WPartsShowPartCount then
        ACanvas.TextOut(Rect.Left, Rect.Bottom - 38, PartObject.PartNum)
      else
        ACanvas.TextOut(Rect.Left, Rect.Bottom - 18, PartObject.PartNum);
    end;

    if Config.WPartsShowPartCount and (DgSetParts.DefaultColWidth >= 48) then begin
      var PartCount := '';
      if FPartsMode = caView then
        PartCount := Format('%dx', [PartObject.MaxQuantity])
      else
        PartCount := Format('%d/%d', [PartObject.CurQuantity, PartObject.MaxQuantity]);

      if PartObject.IsSpare then
        PartCount := PartCount + '*';

      ACanvas.TextOut(Rect.Left, Rect.Bottom - 18, PartCount);
    end;
  end else begin
    // Empty cell: clear background
    ACanvas.Brush.Color := clWindow;
    ACanvas.FillRect(Rect);
  end;
end;

procedure TFrmParts.LoadPartsBySet(const set_num: String; const ForceRefresh: Boolean);

  procedure FQueryAndHandleSetFields(Query: TFDQuery);
  begin
    Query.SQL.Text := 'SELECT s.set_num, s.name, s."year", s.num_parts, s.img_url, t.name AS theme, pt.name AS parenttheme' +
                      ' FROM sets s' +
                      ' LEFT JOIN themes t ON t.id = s.theme_id' +
                      ' LEFT JOIN themes pt ON pt.id = t.parent_id' +
                      ' WHERE s.set_num = :set_num';
    try
      // Always use params to prevent injection and allow sql to reuse queryplans
      var Params := Query.Params;
      Params.ParamByName('set_num').AsString := set_num;

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
    Query.SQL.Text := 'SELECT max(version) FROM inventories WHERE set_num = :set_num';
    try
      // Always use params to prevent injection and allow sql to reuse queryplans
      var Params := Query.Params;
      Params.ParamByName('set_num').AsString := set_num;

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
  if (set_num = FSetNum) and not ForceRefresh then
    Exit;

  FSetNum := set_num;
  Self.Caption := 'Lego set: ' + set_num; // + set name
  FPartObjectList.Clear;

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
      FDQuery.SQL.Text := 'SELECT ip.part_num, p.name as partname, ip.quantity, ip.is_spare,' +
                          ' ip.img_url, ip.color_id as color_id, ip.inventory_id' + //, c.name as colorname, c.is_trans, c.rgb
                          ' FROM inventories' +
                          ' LEFT JOIN inventory_parts ip ON ip.inventory_id = inventories.id';
      if FConfig.WPartsSortByHue then begin
        FDQuery.SQL.Text := FDQuery.SQL.Text +
                            ' LEFT JOIN colors c ON c.id = ip.color_id';
      end;
      FDQuery.SQL.Text := FDQuery.SQL.Text +
                          ' LEFT JOIN parts p ON p.part_num = ip.part_num' +
                          ' WHERE set_num = :set_num' +
                          ' AND version = :version';

      // Exclude part type:
      if not FConfig.WPartsIncludeSpareParts then begin
        FDQuery.SQL.Text := FDQuery.SQL.Text +
                          ' AND is_spare = 0'
      end else if not FConfig.WPartsIncludeNonSpareParts then begin
        FDQuery.SQL.Text := FDQuery.SQL.Text +
                          ' AND is_spare = 1';
      end;

      FDQuery.SQL.Text := FDQuery.SQL.Text +
                          ' ORDER BY ip.is_spare ASC';

      var SortSql := '';
      if FConfig.WPartsSortByCategory then
        SortSql := ', ip.part_num'
      else if FConfig.WPartsSortByColor then
        SortSql := ', color_id'
      else if FConfig.WPartsSortByHue then
        SortSql := ', c.rgb'
      else if FConfig.WPartsSortByPart then
        SortSql := ', p.part_cat_id'
      else if FConfig.WPartsSortByQuantity then
        SortSql := ', ip.quantity';

      if SortSql <> '' then begin
        if FConfig.WPartsSortAscending then
          SortSql := SortSql + ' ASC'
        else
          SortSql := SortSql + ' DESC';
      end;
      FDQuery.SQL.Text := FDQuery.SQL.Text + SortSql;

      var Params := FDQuery.Params;
      Params.ParamByName('set_num').AsString := set_num;
      Params.ParamByName('version').AsInteger := InventoryVersion; // TODO: Needs to be stored with the set_num and BSSetID

      FPartObjectList.LoadFromQuery(FDQuery, True, False, False);

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

procedure TFrmParts.MnuShowPartnumClick(Sender: TObject);
begin

end;

// Not used by view parts mode:
procedure TFrmParts.LoadPartCountByID(const BSSetID: Integer);

  procedure FEnrichPartsFromQuery(FDQuery: TFDQuery);
  begin
    FDQuery.Open;

    while not FDQuery.Eof do begin
      var BSPartID := FDQuery.FieldByName('id').AsInteger;
      var InventoryID := FDQuery.FieldByName('inventoryid').AsInteger;
      var PartNum := FDQuery.FieldByName('part_num').AsString;
      var ColorID := FDQuery.FieldByName('color_id').AsInteger;
      var IsSpare := (FDQuery.FieldByName('is_spare').AsInteger) = 1;

      // Todo, speed up by using indexable dictionary
      for var Part in FPartObjectList do begin
        if Part.BSPartID = BSPartID then begin
          Part.CurQuantity := FDQuery.FieldByName('quantity').AsInteger;
          Continue;
        end else if (Part.ColorID = ColorID) and
                    (Part.IsSpare = IsSpare) and
                    (Part.InventoryID = InventoryID) and
                    SameText(Part.PartNum, PartNum) then begin // Do string compare last, because of performance
          Part.CurQuantity := FDQuery.FieldByName('quantity').AsInteger;
          Part.BSPartID := BSPartID;
          Continue;
        end;
      end;

      FDQuery.Next;
    end;
  end;

// Enrich FPartObjectList by getting which parts we own for this set.
begin
  FBSSetID := BSSetID;
  Self.Caption := Self.Caption + Format(' (ID: %d)', [BSSetID]); //todo: add config to show debug information
  //todo: Investigate if this could be 1 query, joined with getting the parts?

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

      FDQuery.SQL.Text := 'select id, inventoryid, part_num, color_id, is_spare, quantity from BSDBPartsInventory' +
                          ' where BSSetID = :BSSetID';
      var Params := FDQuery.Params;
      Params.ParamByName('BSSetID').AsInteger := BSSetID;
      FEnrichPartsFromQuery(FDQuery);
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

