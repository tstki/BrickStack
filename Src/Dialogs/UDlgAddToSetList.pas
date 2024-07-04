unit UDlgAddToSetList;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  SqlExpr, DBXSQLite, //SQLiteTable3, SQLite3;
  USetList,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TDlgAddToSetList = class(TForm)
    Label2: TLabel;
    CbxSetList: TComboBox;
    BtnCancel: TButton;
    BtnOK: TButton;
    Label1: TLabel;
    EditAmount: TEdit;
    ChkBuilt: TCheckBox;
    ChkSpareParts: TCheckBox;
    MemoNote: TMemo;
    Label3: TLabel;
    LblMaxNote: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure MemoNoteChange(Sender: TObject);
    procedure OnChange(Sender: TObject);
    procedure BtnOKClick(Sender: TObject);
  private
    { Private declarations }
    FSetNum: String;
    FSetListObjectList: TSetListObjectList;
    procedure FFillPulldown();
    procedure FUpdateUI();
  public
    { Public declarations }
    property SetNum: String read FSetNum write FSetNum;
  end;

implementation

{$R *.dfm}

uses
  UStrings;

procedure TDlgAddToSetList.FormCreate(Sender: TObject);
begin
  inherited;
  FSetListObjectList := TSetListObjectList.Create;
end;

procedure TDlgAddToSetList.FormDestroy(Sender: TObject);
begin
  FSetListObjectList.Free;
  inherited;
end;

procedure TDlgAddToSetList.FormShow(Sender: TObject);
begin
  FFillPulldown;
  EditAmount.Text := '1';
  MemoNoteChange(Self);
end;

procedure TDlgAddToSetList.OnChange(Sender: TObject);
begin
  FUpdateUI;
end;

procedure TDlgAddToSetList.FUpdateUI();
begin
  BtnOK.Enabled := (StrtoIntDef(EditAmount.Text, 0) > 0) and
                   (CbxSetList.ItemIndex >= 0);
end;

procedure TDlgAddToSetList.BtnOKClick(Sender: TObject);
begin
// do query
//get ID
//
end;

procedure TDlgAddToSetList.FFillPulldown();
var
  Query: TSQLQuery;
begin
  // Clean up the list before adding new results
//  for var I:=FResultPanels.Count-1 downto 0 do
//    FResultPanels.Delete(I);
  FSetListObjectList.Clear;
  CbxSetList.Clear;

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

      Query.SQL.Text := 'SELECT ID, NAME' +
                        ' FROM MySetLists ORDER BY NAME';

      Query.Open; // Open the query to retrieve data
      try
        Query.First; // Move to the first row of the dataset

        while not Query.EOF do begin
          var SetListObject := TSetListObject.Create;
          SetListObject.id := Query.FieldByName('id').AsInteger;
          SetListObject.name := Query.FieldByName('name').AsString;
          FSetListObjectList.Add(SetListObject);

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

    CbxSetList.Items.BeginUpdate;
    try
      for var Obj in FSetListObjectList do
        CbxSetList.Items.AddObject(Obj.Name, TObject(Obj.ID));

      // todo: Try to use latest selection from config
      if FSetListObjectList.Count > 0 then
        CbxSetList.ItemIndex := 0;
    finally
      CbxSetList.Items.EndUpdate;
    end;
  finally
    begin
      //Stopwatch.Stop;
      //Enable for performance testing:
      //ShowMessage('Finished in: ' + IntToStr(Stopwatch.ElapsedMilliseconds) + 'ms');
    end;
  end;
end;

procedure TDlgAddToSetList.MemoNoteChange(Sender: TObject);
begin
  // Note: database limit is 1024 chars
  LblMaxNote.Caption := Format(StrMax, [MemoNote.MaxLength - Length(MemoNote.Text)]);
end;

end.
