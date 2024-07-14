unit UFrmParts;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Imaging.pngimage,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  Contnrs, UDelayedImage,
  FireDAC.Comp.Client, FireDAC.Stan.Param,
  UConfig, UImageCache, Vcl.Menus, System.Actions, Vcl.ActnList, Vcl.Buttons,
  System.ImageList, Vcl.ImgList;

type
  TFrmParts = class(TForm)
    Panel1: TPanel;
    LblInventoryVersion: TLabel;
    CbxInventoryVersion: TComboBox;
    Button1: TButton;
    TmrRefresh: TTimer;
    PopPartsFilter: TPopupMenu;
    Sort1: TMenuItem;
    Ascending1: TMenuItem;
    N1: TMenuItem;
    Sort2: TMenuItem;
    Hue1: TMenuItem;
    Part1: TMenuItem;
    Category1: TMenuItem;
    Quantity1: TMenuItem;
    ogglecheckboxmode1: TMenuItem;
    Includespareparts1: TMenuItem;
    ActionList1: TActionList;
    ActAddToSetList: TAction;
    ActRemoveFromSetList: TAction;
    ActEditToSetList: TAction;
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
    StatusBar1: TStatusBar;
    SbSetParts: TScrollBox;
    PnlTemplateResult: TPanel;
    ImgTemplatePartImage: TImage;
    ImgTemplateShowPart: TImage;
    LblTemplateName: TLabel;
    CbxTemplateCheck: TCheckBox;
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SbSetPartsResize(Sender: TObject);
    procedure TmrRefreshTimer(Sender: TObject);
    procedure ActPrintPartsExecute(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    FIdHttp: TIdHttp;
    FConfig: TConfig;
    FImageCache: TImageCache;
    FInventoryPanels: TObjectList;
    FCurMaxCols: Integer;
    FSetNum: String;
    FCheckboxMode: Boolean;
    procedure FHandleQueryAndHandleSetInventoryVersion(Query: TFDQuery);
    function FCreateNewResultPanel(Query: TFDQuery; AOwner: TComponent; ParentControl: TWinControl; RowIndex, ColIndex: Integer): TPanel;
  public
    { Public declarations }
    property IdHttp: TIdHttp read FIdHttp write FIdHttp;
    property Config: TConfig read FConfig write FConfig;
    property ImageCache: TImageCache read FImageCache write FImageCache;
    procedure LoadPartsBySet(const set_num: String);
    property SetNum: String read FSetNum; // Read only
  end;

implementation

{$R *.dfm}
uses
  ShellAPI, Printers,
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
  PrintScrollBoxContents3(SbSetParts);
end;

procedure TFrmParts.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
  inherited;
end;

procedure TFrmParts.FormCreate(Sender: TObject);
begin
  inherited;
  FInventoryPanels := TObjectList.Create;
  FInventoryPanels.OwnsObjects := True;

  SbSetParts.UseWheelForScrolling := True;
end;

procedure TFrmParts.FormShow(Sender: TObject);
begin
  var CurWidth := SbSetParts.ClientWidth;
  var MinimumPanelWidth := PnlTemplateResult.Width;
  FCurMaxCols := Floor(CurWidth/MinimumPanelWidth);
  inherited;
end;

procedure TFrmParts.SbSetPartsResize(Sender: TObject);
begin
  TmrRefresh.Enabled := False;
  TmrRefresh.Enabled := True;
end;

procedure TFrmParts.TmrRefreshTimer(Sender: TObject);
begin
  // Don't redraw until mouse is up
  if (GetKeyState(VK_LBUTTON) and $8000) = 0 then begin
    TmrRefresh.Enabled := False;

    SendMessage(SbSetParts.Handle, WM_SETREDRAW, 0, 0);
    try
      // add controls to scrollbox
      // set scrollbox height

      // Get the size without scrollbars
      var CurWidth := SbSetParts.ClientWidth;

      var MinimumPanelWidth := PnlTemplateResult.Width;
      var MaxCols := Floor(CurWidth/MinimumPanelWidth);
      //FCurMaxCols should be calculated on formShow, make it -1 for now.
      if (FCurMaxCols = -1) or (FCurMaxCols <> MaxCols) then begin
        // Scroll to 0,0 first
        SbSetParts.HorzScrollBar.Position := 0;
        SbSetParts.VertScrollBar.Position := 0;

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
    finally
      SendMessage(SbSetParts.Handle, WM_SETREDRAW, 1, 0);
      RedrawWindow(SbSetParts.Handle, nil, 0, RDW_ERASE or RDW_INVALIDATE or RDW_FRAME or RDW_ALLCHILDREN);
    end;
  end;
end;

procedure TFrmParts.FHandleQueryAndHandleSetInventoryVersion(Query: TFDQuery);
begin
  var MaxVersion := Query.FieldByName('max(version)').AsInteger;
  if MaxVersion > 1 then begin
    CbxInventoryVersion.Items.BeginUpdate;
    try
      for var I := 2 to MaxVersion do
        CbxInventoryVersion.Items.Add(I.ToString);
    finally
      CbxInventoryVersion.Items.EndUpdate;
    end;
  end;
end;

procedure TFrmParts.Button1Click(Sender: TObject);
begin
  var P := Mouse.CursorPos;
  // Show the popup menu at the mouse cursor position
  PopPartsFilter.Popup(P.X, P.Y);
end;

function TFrmParts.FCreateNewResultPanel(Query: TFDQuery; AOwner: TComponent; ParentControl: TWinControl; RowIndex, ColIndex: Integer): TPanel;

  function FGetLabelOrCheckboxText(): String;
  begin
    Result := Query.FieldByName('quantity').AsString +
              'x' +
              IfThen(SameText(Query.FieldByName('is_spare').AsString, 't'), '*', '') +
              Query.FieldByName('part_num').AsString;
  end;

begin
  Result := TPanel.Create(AOwner);
  Result.Parent := ParentControl;
  Result.Width := PnlTemplateResult.Width;
  Result.Height := PnlTemplateResult.Height;
  Result.Top := 0 + PnlTemplateResult.Height * RowIndex;
  Result.Left := 0 + PnlTemplateResult.Width * ColIndex;

  for var i := 0 to PnlTemplateResult.ControlCount - 1 do begin
    var Control: TObject;
    if (PnlTemplateResult.Controls[i].ClassType = TImage) and SameText(PnlTemplateResult.Controls[i].Name, 'ImgTemplatePartImage') then
      Control := TDelayedImage.Create(Self)
    else
      Control := PnlTemplateResult.Controls[i].ClassType.Create;

    // Copy other properties as needed
    if Control.ClassType = TCheckbox then begin
      var TemplateCheckbox := TCheckbox(PnlTemplateResult.Controls[i]);
      var NewCheckbox := TCheckbox.Create(Result);

      NewCheckbox.Parent := Result;
      NewCheckbox.Top := TemplateCheckbox.Top;
      NewCheckbox.Left := TemplateCheckbox.Left;
      NewCheckbox.Width := TemplateCheckbox.Width;
      NewCheckbox.Height := TemplateCheckbox.Height;

      NewCheckbox.Caption := FGetLabelOrCheckboxText;
      NewCheckbox.Visible := FCheckboxMode;
    end else if Control.ClassType = TLabel then begin
      var TemplateLabel := TLabel(PnlTemplateResult.Controls[i]);
      var NewLabel := TLabel.Create(Result);

      NewLabel.Parent := Result;
      NewLabel.Top := TemplateLabel.Top;
      NewLabel.Left := TemplateLabel.Left;
      NewLabel.Width := TemplateLabel.Width;
      NewLabel.Height := TemplateLabel.Height;

      NewLabel.Caption := FGetLabelOrCheckboxText;
      NewLabel.Visible := not FCheckboxMode;
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
        NewImage.Name := TemplateImage.Name + '_' + StringReplace(Query.FieldByName('part_num').AsString, '-', '_', [rfReplaceAll]);
      end;

      NewImage.ImageCache := FImageCache;
      NewImage.Url := Query.FieldByName('img_url').AsString;
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
        NewImage.Name := TemplateImage.Name + '_' + StringReplace(Query.FieldByName('part_num').AsString, '-', '_', [rfReplaceAll]);
      end;

      NewImage.Picture := TemplateImage.Picture;
      NewImage.Visible := not FCheckboxMode;
    end;
    //end else if Control is TButton then begin
      //TButton(Control).OnClick := TButton(PnlTemplateResult.Controls[i]).OnClick; // Copy event handlers
    //end else if Control is TEdit then begin
      //TEdit(Control).Text := TEdit(PnlTemplateResult.Controls[i]).Text; // Copy text
    //end;
    // Add handling for other control types as needed
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

  procedure FQueryAndHandleSetPartsByVersion(Query: TFDQuery; Version: String);
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
  end;

begin
  // No point loading the same set as is already being shown.
  if set_num = FSetNum then
    Exit;

  FSetNum := set_num;
  Self.Caption := 'Lego set: ' + set_num; // + set name

  // Always assume version 1 is available. See: FHandleQueryAndHandleSetInventoryVersion
  CbxInventoryVersion.Items.BeginUpdate;
  try
    CbxInventoryVersion.Clear;
    CbxInventoryVersion.Items.Add('1');
    CbxInventoryVersion.ItemIndex := 0;
  finally
    CbxInventoryVersion.Items.EndUpdate;
  end;

  //var Stopwatch := TStopWatch.Create;
  //Stopwatch.Start;
  try
    SendMessage(SbSetParts.Handle, WM_SETREDRAW, 0, 0);
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
        FQueryAndHandleSetPartsByVersion(FDQuery, CbxInventoryVersion.Text);
      finally
        FDQuery.Free;
        FrmMain.ReleaseConnection(SqlConnection);
      end;
    finally
      SendMessage(SbSetParts.Handle, WM_SETREDRAW, 1, 0);
      RedrawWindow(SbSetParts.Handle, nil, 0, RDW_ERASE or RDW_INVALIDATE or RDW_FRAME or RDW_ALLCHILDREN);
    end;
  finally
    begin
      //Stopwatch.Stop;
      //Enable for performance testing:
      //ShowMessage('Finished in: ' + IntToStr(Stopwatch.ElapsedMilliseconds) + 'ms');
    end;
  end;
end;

end.
