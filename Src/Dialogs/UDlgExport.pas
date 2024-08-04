unit UDlgExport;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

const
  // Export type
  etSETLIST = 0;
  //etPARTS = 1;
  //etFIGURES = 2;

type
  TDlgExport = class(TForm)
    Label1: TLabel;
    CbxExportOptions: TComboBox;
    BtnOK: TButton;
    BtnCancel: TButton;
    LblRemoteOptions: TLabel;
    CbxRemoteOptions: TComboBox;
    procedure BtnOKClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure CbxExportOptionsChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    FExportID: String;
    FExportType: Integer; // See above
    FExportName: String;
    procedure FUpdateUI;
  public
    { Public declarations }
    property ExportType: Integer read FExportType write FExportType;
    property ExportID: String read FExportID write FExportID;
    property ExportName: String read FExportName write FExportName;
  end;

implementation

{$R *.dfm}

uses
  System.UITypes,
  FireDAC.Comp.Client, FireDAC.Stan.Param,
  Data.DB,
  USQLiteConnection,
  UBrickLinkXMLIntf,
  UFrmMain, UStrings;

const
  // Export kind
  ekREBRICKABLEAPI = 0;
  ekREBRICKABLECSV = 1;
  ekBRICKLINKXML = 2;

  // Export remote options
  eoAPPEND = 0;
  eoSUBTRACT = 1;
  eoREPLACE = 2;
  eoDELETEALL = 3;

procedure TDlgExport.FormCreate(Sender: TObject);
begin
  inherited;

  CbxExportOptions.Items.BeginUpdate;
  try
    CbxExportOptions.Items.Clear;
    CbxExportOptions.Items.Add(StrNameRebrickableAPI);
    CbxExportOptions.Items.Add(StrNameRebrickableCSV);
    CbxExportOptions.Items.Add(StrNameBrickLinkXML);
    CbxExportOptions.ItemIndex := 0;
  finally
    CbxExportOptions.Items.EndUpdate;
  end;

  CbxRemoteOptions.Items.BeginUpdate;
  try
    CbxRemoteOptions.Items.Clear;
    CbxRemoteOptions.Items.Add(StrExportRemoteAppend);
    CbxRemoteOptions.Items.Add(StrExportRemoteSubtract);
    CbxRemoteOptions.Items.Add(StrExportRemoteReplace);
    CbxRemoteOptions.Items.Add(StrExportRemoteDeleteAll);
    CbxRemoteOptions.ItemIndex := 0;
  finally
    CbxRemoteOptions.Items.EndUpdate;
  end;
end;

procedure TDlgExport.FormShow(Sender: TObject);
begin
  Caption := Caption + ' - ' + FExportName;
  FUpdateUI;
end;

procedure TDlgExport.BtnOKClick(Sender: TObject);
begin
  // Examples:

  //RebrickableCSV
  //Set Number,Quantity,Includes Spares,Inventory ID
  //1,2,3,4

  //BrickLinkXML - UBrickLinkXMLIntf
  //<INVENTORY><ITEM><ITEMTYPE>S</ITEMTYPE><ITEMID>7065-1</ITEMID><MINQTY>1</MINQTY></ITEM>
  //Itemtype: S=Set, S=Minifig, P=Part?

  if CbxExportOptions.ItemIndex = ekREBRICKABLEAPI then begin
    // do query
    // API call
  end else begin
    var SaveDialog := TSaveDialog.Create(Self);
    try
      if CbxExportOptions.ItemIndex = ekREBRICKABLECSV then begin
        SaveDialog.Filter := StrExportCSVFilter;
        SaveDialog.DefaultExt := StrExportCSVFileType;
      end else begin //ekBRICKLINKXML
        SaveDialog.Filter := StrExportXMLFilter;
        SaveDialog.DefaultExt := StrExportXMLileType;
      end;
      SaveDialog.Title := StrSaveAsTitle;

      if SaveDialog.Execute then begin
        if FileExists(SaveDialog.FileName) and (MessageDlg(Format(StrFileExistsWarning, [SaveDialog.FileName]), mtConfirmation, mbYesNo, 0) = mrNo) then
          Exit;

        var SqlConnection := FrmMain.AcquireConnection;
        var FDQuery := TFDQuery.Create(nil);
        try
          // Set up the query
          FDQuery.Connection := SqlConnection;
          FDQuery.SQL.Text := 'SELECT S.Set_Num, S.Quantity, S.HaveSpareParts, (SELECT i.ID FROM INVENTORIES i' +
                              ' WHERE i.Set_Num = S.Set_Num AND i.version=1) AS InventoryID FROM BSSets S WHERE BSSetListID = :BSSetListID';
          //todo: warning, using explicit version 1 here because the user can't select an inventory version yet
          var Params := FDQuery.Params;
          Params.ParamByName('BSSetListID').AsInteger := FExportID.ToInteger;
          FDQuery.Open;

          if CbxExportOptions.ItemIndex = ekREBRICKABLECSV then begin
            var SL := TStringList.Create;
            try
              // Header
              SL.Add('Set Number,Quantity,Includes Spares,Inventory ID');

              while not FDQuery.Eof do begin
                var SetNum := FDQuery.FieldByName('Set_Num').AsString;
                var Quantity := FDQuery.FieldByName('Quantity').AsString;
                var HaveSpareParts := FDQuery.FieldByName('HaveSpareParts').AsString;
                var InventoryID := FDQuery.FieldByName('InventoryID').AsString;

                SL.Add(Format('%s,%s,%s,%s', [SetNum, Quantity, HaveSpareParts, InventoryID]));

                FDQuery.Next; // Move to the next row
              end;

              SL.SaveToFile(SaveDialog.FileName);
            finally
              SL.Free;
            end;
          end else begin // XML
            var xmldoc := NewINVENTORY;

            while not FDQuery.Eof do begin
              var SetNum := FDQuery.FieldByName('Set_Num').AsString;
              var Quantity := FDQuery.FieldByName('Quantity').AsInteger;

              var Item := xmldoc.Add;
              Item.ITEMTYPE := 'S'; // TODO: Just supporting sets for now, parts/ figures need to be added later
              Item.ITEMID := SetNum;
              Item.MINQTY := Quantity;

              FDQuery.Next; // Move to the next row
            end;

            xmldoc.OwnerDocument.SaveToFile(SaveDialog.FileName);
          end;
        finally
          FDQuery.Free;
          FrmMain.ReleaseConnection(SqlConnection);
        end;
      end else
        Exit; // User abort
    finally
      SaveDialog.Free;
    end;
  end;
end;

procedure TDlgExport.FUpdateUI;
begin
  LblRemoteOptions.Enabled := CbxExportOptions.ItemIndex = ekREBRICKABLEAPI;
  CbxRemoteOptions.Enabled := CbxExportOptions.ItemIndex = ekREBRICKABLEAPI;

  //CbxRemoteOptions
  //disable extra ui items if not available for something.
  //show warning labels if needed
end;

procedure TDlgExport.CbxExportOptionsChange(Sender: TObject);
begin
  FUpdateUI;
end;

end.
