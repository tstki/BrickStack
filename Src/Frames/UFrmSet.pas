unit UFrmSet;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Imaging.pngimage,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  Contnrs, UDelayedImage,
  FireDAC.Comp.Client,
  UConfig, UImageCache, Vcl.Menus, System.Actions, Vcl.ActnList, Vcl.Buttons,
  System.ImageList, Vcl.ImgList;

type
  TFrmSet = class(TForm)
    ImgSetImage: TImage;
    ImgViewSetExternal: TImage;
    LvTagData: TListView;
    ImgAdd: TImage;
    ImgRemove: TImage;
    ActionList1: TActionList;
    ActAddToSetList: TAction;
    ActRemoveFromSetList: TAction;
    ActViewSetExternal: TAction;
    ImgEdit: TImage;
    ActEditToSetList: TAction;
    ImgParts: TImage;
    ActViewParts: TAction;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ActAddToSetListExecute(Sender: TObject);
    procedure ActRemoveFromSetListExecute(Sender: TObject);
    procedure ActExportExecute(Sender: TObject);
    procedure ActViewSetExternalExecute(Sender: TObject);
    procedure ActToggleCheckboxModeExecute(Sender: TObject);
    procedure ActToggleIncludeSparePartsExecute(Sender: TObject);
    procedure ActToggleAscendingExecute(Sender: TObject);
    procedure ActSortByColorExecute(Sender: TObject);
    procedure ActSortByHueExecute(Sender: TObject);
    procedure ActSortByPartExecute(Sender: TObject);
    procedure ActSortByCategoryExecute(Sender: TObject);
    procedure ActSortByQuantityExecute(Sender: TObject);
    procedure ActViewPartExternalExecute(Sender: TObject);
    procedure ActEditToSetListExecute(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure ActViewPartsExecute(Sender: TObject);
  private
    { Private declarations }
    FIdHttp: TIdHttp;
    FConfig: TConfig;
    FImageCache: TImageCache;
    FSetNum: String;
    procedure FHandleQueryAndHandleSetFields(Query: TFDQuery);
  public
    { Public declarations }
    property IdHttp: TIdHttp read FIdHttp write FIdHttp;
    property Config: TConfig read FConfig write FConfig;
    property ImageCache: TImageCache read FImageCache write FImageCache;
    procedure LoadSet(const set_num: String);
    property SetNum: String read FSetNum; // Read only
  end;

implementation

{$R *.dfm}

uses
  ShellAPI, Printers,
  USQLiteConnection,
  FireDAC.Stan.Param,
  Math, Diagnostics, Data.DB, StrUtils,
  UFrmMain, UDlgViewExternal, UDlgAddToSetList,
  UStrings;

procedure TFrmSet.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
  inherited;
end;

procedure TFrmSet.FHandleQueryAndHandleSetFields(Query: TFDQuery);

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
    TThread.CreateAnonymousThread(
    procedure
    begin
      try
        var Picture := FImageCache.GetImage(Url);
        if Picture <> nil then begin
          ImgSetImage.Picture := Picture;

          TThread.Synchronize(nil,
          procedure
          begin
            // Update the UI in the main thread
            ImgSetImage.Invalidate;
          end);
        end;
      except
        // Handle exceptions here / delays.
        //Sleep(2000);
      end;
    end).Start;
  end;

  LvTagData.Items.BeginUpdate;
  try
    // Add year, category, part count, etc to table.
    FAddRow('Set num', 'set_num');
    FAddRow('Name', 'name');
    FAddRow('Released', 'year');
    FAddRow('Parts', 'num_parts');

    FAddRow('Main theme', 'theme');
    FAddRow('Sub theme', 'parenttheme');
  finally
    LvTagData.Items.EndUpdate;
  end;

  // Seems the "fieldname as" does not work. See how to get the fieldnames or FieldDefs example:
  //  for var I := 0 to Query.FieldCount - 1 do
  //    ShowMessage(Query.Fields[I].FieldName);
end;

procedure TFrmSet.LoadSet(const set_num: String);

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

begin
  // No point loading the same set as is already being shown.
  if set_num = FSetNum then
    Exit;

  FSetNum := set_num;
  Self.Caption := 'Lego set: ' + set_num; // + set name

  //var Stopwatch := TStopWatch.Create;
  //Stopwatch.Start;
  try
    LvTagData.Clear;

    var SqlConnection := FrmMain.AcquireConnection;
    var FDQuery := TFDQuery.Create(nil);
    try
      // Set up the query
      FDQuery.Connection := SqlConnection;
      FQueryAndHandleSetFields(FDQuery);
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
end;

procedure TFrmSet.ActAddToSetListExecute(Sender: TObject);
begin
  var DlgAddToSetList := TDlgAddToSetList.Create(Self);
  try
    DlgAddToSetList.SetNum := FSetNum;
    if DlgAddToSetList.ShowModal = mrOK then begin
      //Do add to MySets
    end;
  finally
    DlgAddToSetList.Free;
  end;
end;

procedure TFrmSet.ActRemoveFromSetListExecute(Sender: TObject);
begin
// Remove from setlist
end;

procedure TFrmSet.ActEditToSetListExecute(Sender: TObject);
begin
//
end;

procedure TFrmSet.ActExportExecute(Sender: TObject);
begin
// choose export format, and output list.
end;

procedure TFrmSet.ActSortByCategoryExecute(Sender: TObject);
begin
//
end;

procedure TFrmSet.ActSortByColorExecute(Sender: TObject);
begin
//
end;

procedure TFrmSet.ActSortByHueExecute(Sender: TObject);
begin
//
end;

procedure TFrmSet.ActSortByPartExecute(Sender: TObject);
begin
//
end;

procedure TFrmSet.ActSortByQuantityExecute(Sender: TObject);
begin
//
end;

procedure TFrmSet.ActToggleAscendingExecute(Sender: TObject);
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

procedure TFrmSet.ActToggleCheckboxModeExecute(Sender: TObject);
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

procedure TFrmSet.ActToggleIncludeSparePartsExecute(Sender: TObject);
begin
//
end;

procedure TFrmSet.ActViewPartExternalExecute(Sender: TObject);

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
  // get partnum from sender
  TFrmMain.OpenExternal(cTYPEPART, FGetPartNumByComponentName(TImage(Sender).Name));
end;

procedure TFrmSet.ActViewPartsExecute(Sender: TObject);
begin
  TFrmMain.ShowPartsWindow(FSetNum);
end;

procedure TFrmSet.ActViewSetExternalExecute(Sender: TObject);
begin
  TFrmMain.OpenExternal(cTYPESET, FSetNum);
end;

procedure TFrmSet.Button1Click(Sender: TObject);
begin
//
end;

end.
