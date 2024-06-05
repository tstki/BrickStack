unit UFrmSearch;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  Contnrs, IdHttp,
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
    procedure SbSearchResultsMouseWheelDown(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure SbSearchResultsMouseWheelUp(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure TmrRefreshTimer(Sender: TObject);
  private
    { Private declarations }
    FResultPanels: TObjectList;
    FIdHttp: TIdHTTP;
    FImageCache: TImageCache;
    FCurMaxCols: Integer;
    procedure FDoSearch;
    function FCreateNewResultPanel(Query: TSQLQuery; AOwner: TComponent; ParentControl: TWinControl; RowIndex, ColIndex: Integer): TPanel;
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

  SbSearchResults.UseWheelForScrolling := True;
end;

procedure TFrmSearch.FormDestroy(Sender: TObject);
begin
  FResultPanels.Free;
end;

procedure TFrmSearch.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TFrmSearch.FormShow(Sender: TObject);
begin
  // Research this more later - mdi child anchors are weird.
  Width := 640;
  Height := 480;
  SbSearchResults.Anchors := [TAnchorKind.akLeft,TAnchorKind.akTop, TAnchorKind.akRight, TAnchorKind.akBottom];

  var CurWidth := SbSearchResults.ClientWidth;
  var MinimumPanelWidth := PnlTemplateResult.Width;
  FCurMaxCols := Floor(CurWidth/MinimumPanelWidth);
end;

function TFrmSearch.FCreateNewResultPanel(Query: TSQLQuery; AOwner: TComponent; ParentControl: TWinControl; RowIndex, ColIndex: Integer): TPanel;
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

      if SameText(TemplateLabel.Name, 'LblTemplateSetNum') then
        NewLabel.Caption := Query.FieldByName('set_num').AsString
      //else if SameText(TemplateLabel.Name, 'LblTemplateTheme') then
        //NewLabel.Caption := Query.FieldByName('theme_id').AsString
      else if SameText(TemplateLabel.Name, 'LblTemplateYear') then
        NewLabel.Caption := Query.FieldByName('year').AsString
      //else if SameText(TemplateLabel.Name, 'LblTemplatePart') then
        //NewLabel.Caption := Query.FieldByName('num_parts').AsString
      else if SameText(TemplateLabel.Name, 'LblTemplateName') then
        NewLabel.Caption := Query.FieldByName('name').AsString
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
        NewImage.Name := TemplateImage.Name + '_' + StringReplace(Query.FieldByName('set_num').AsString, '-', '_', [rfReplaceAll]);
      end;

      if SameText(TemplateImage.Name, 'ImgTemplateSetImage') then begin
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

        Query.SQL.Text := 'SELECT * FROM Sets';
        Query.SQL.Text := Query.SQL.Text + ' where set_num like :Param1 LIMIT 30'; // configure result limitation

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

          var RowIndex := 0;
          var ColIndex := 0;

          while not Query.EOF do begin
            var ResultPanel := FCreateNewResultPanel(Query, SbSearchResults, SbSearchResults, RowIndex, ColIndex);
            ResultPanel.Parent := SbSearchResults;

            FResultPanels.Add(ResultPanel);

            Inc(ColIndex);
            if ColIndex >= FCurMaxCols then begin
              Inc(RowIndex);
              ColIndex := 0;
            end;

            Query.Next; // Move to the next row
          end;
        finally
          Query.Close; // Close the query when done
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

      PnlTemplateResult.Visible := False;
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
      PnlTemplateResult.Visible := True;

      // Update the current value to reduce unneeded dialog redrawing
      FCurMaxCols := MaxCols;
    end else begin
      // See if we can widen the existing cols a little.
    end;
  end;
end;

end.
