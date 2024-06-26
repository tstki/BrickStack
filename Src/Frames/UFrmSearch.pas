unit UFrmSearch;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  Contnrs, IdHttp, USet,
  SqlExpr, DBXSQLite, //SQLiteTable3, SQLite3;
  System.ImageList, Vcl.ImgList, Vcl.ExtCtrls, Vcl.Imaging.pngimage,
  UImageCache;

type
  TFrmSearch = class(TForm)
    EditSearchText: TEdit;
    LblSearch: TLabel;
    Label2: TLabel;
    ComboBox3: TComboBox;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    SbSearchResults: TScrollBox;
    Theme: TLabel;
    Label1: TLabel;
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    Edit3: TEdit;
    Edit5: TEdit;
    CheckBox2: TCheckBox;
    Label5: TLabel;
    Label4: TLabel;
    Edit2: TEdit;
    Edit4: TEdit;
    Label3: TLabel;
    Year: TLabel;
    ImgSearch: TImage;
    CbxSearchStyle: TComboBox;
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
  private
    { Private declarations }
    FSetObjects: TSetObjectList; // Stored locally from query result.
    FResultPanels: TObjectList;
    FIdHttp: TIdHTTP;
    FImageCache: TImageCache;
    FCurMaxCols: Integer;
    procedure FDoSearch;
    function FCreateNewResultPanel(const SetObject: TSetObject; AOwner: TComponent; ParentControl: TWinControl; RowIndex, ColIndex: Integer): TPanel;
  public
    { Public declarations }
    property IdHttp: TIdHttp read FIdHttp write FIdHttp;
    property ImageCache: TImageCache read FImageCache write FImageCache;
  end;

implementation

{$R *.dfm}

uses
  Math,
  Diagnostics,
  UDlgAddToSetList, UDelayedImage,
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

  // Search style for others:
  cSearchAll = 0;        // "%SearchText%"  // May find a lot more than you want
  // Search style for sets:
  cSearchSetDefault = 1; // "SearchText-%"  // Also get all If the set has versions
  cSearchSetLike = 2;    // "%SearchText-%" // Find parts of sets

procedure TFrmSearch.FormCreate(Sender: TObject);
begin
  inherited;

  CbxSearchStyle.Clear;
  CbxSearchStyle.Items.Add(StrSearchAll);
  CbxSearchStyle.Items.Add(StrSearchSetDefault);
  CbxSearchStyle.Items.Add(StrSearchSetLike);
  CbxSearchStyle.ItemIndex := 1;

  // Template used for other results:
  PnlTemplateResult.Parent := nil;
  PnlTemplateResult.Visible := False;

  FResultPanels := TObjectList.Create;
  FResultPanels.OwnsObjects := True;

  FSetObjects := TSetObjectList.Create;

  SbSearchResults.UseWheelForScrolling := True;
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
  // Research this more later - mdi child anchors are weird.
  Width := 640;
  Height := 480;
  SbSearchResults.Anchors := [TAnchorKind.akLeft,TAnchorKind.akTop, TAnchorKind.akRight, TAnchorKind.akBottom];

  var CurWidth := SbSearchResults.ClientWidth;
  var MinimumPanelWidth := PnlTemplateResult.Width;
  FCurMaxCols := Floor(CurWidth/MinimumPanelWidth);
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
var
  Query: TSQLQuery;
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
      var FilePath := ExtractFilePath(ParamStr(0));

      //var SQLConnection := FrmMain.AcquireConnection; // Change to this.
      var SQLConnection1 := TSqlConnection.Create(self);
      SQLConnection1.DriverName := 'SQLite';
      SQLConnection1.Params.Values['Database'] := FilePath + '\Dbase\Brickstack.db';
      SQLConnection1.Open;

      Query := TSQLQuery.Create(nil);
      try
        Query.SQLConnection := SQLConnection1;

        Query.SQL.Text := 'SELECT set_num, name, year, img_url, num_parts' + //, theme_id
                          ' FROM Sets where set_num like :Param1 LIMIT 30'; // todo: configure result limitation

        // Always use params to prevent injection and allow sql to reuse queryplans
        var Params := Query.Params;
        var SearchValue := EditSearchText.Text;
        if CbxSearchStyle.ItemIndex = cSearchSetDefault then
          SearchValue := EditSearchText.Text
        else
          SearchValue := '%' + EditSearchText.Text;
        if CbxSearchStyle.ItemIndex in [cSearchSetDefault, cSearchSetLike] then
          SearchValue := SearchValue + '-';
        SearchValue := SearchValue + '%';
        Params.ParamByName('Param1').AsString := SearchValue;

        Query.Open; // Open the query to retrieve data
        try
          Query.First; // Move to the first row of the dataset

          while not Query.EOF do begin
            // Fill with TSetObject (not all fields are used) so we can close the query sooner and fill the panels in a thread.
            var SetObject := TSetObject.Create;
            SetObject.SetNum := Query.FieldByName('set_num').AsString;
            SetObject.SetName := Query.FieldByName('name').AsString;
            SetObject.SetYear := Query.FieldByName('year').AsInteger;
            //SetObject.SetThemeID := Query.FieldByName('theme_id').AsString;
            //SetObject.SetThemeName := Query.FieldByName('name_1').AsString;
            SetObject.SetNumParts := Query.FieldByName('num_parts').AsInteger;
            SetObject.SetImgUrl := Query.FieldByName('img_url').AsString;
            //SetObject.Quantity := Query.FieldByName('name_1').AsString;
            //SetObject.IncludeSpares := Query.FieldByName('includespares').AsString;
            //SetObject.Built := Query.FieldByName('built').AsString;
            //SetObject.Note := Query.FieldByName('note').AsString;
            FSetObjects.Add(SetObject);

            Query.Next; // Move to the next row
          end;
        finally
          Query.Close; // Close the query when done
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

end.
