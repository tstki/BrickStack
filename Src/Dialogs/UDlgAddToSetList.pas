unit UDlgAddToSetList;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
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
    LblMaxNote: TLabel;
    LblNoteCap: TLabel;
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
  Math,
  FireDAC.Comp.Client, FireDAC.Stan.Param, USqLiteConnection,
  UFrmMain,
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
  Self.Caption := Format(StrAddSetTo, [SetNum]);

  FFillPulldown;
  EditAmount.Text := '1';
  MemoNoteChange(Self);
  FUpdateUI;
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
  // Should not happen
  if CbxSetList.ItemIndex < 0 then
    Exit;

  var SetListID := Integer(CbxSetList.Items.Objects[CbxSetList.ItemIndex]);

  //get mode - edit or insert. If update mode

  var SqlConnection := FrmMain.AcquireConnection;
  var FDQuery := TFDQuery.Create(nil);
  try
    FDQuery.Connection := SqlConnection;

    FDQuery.SQL.Text := 'INSERT INTO MySets' +
                        ' (MySetListID, set_num, Built, Quantity, HaveSpareParts, Notes)' +
                        ' VALUES(:MySetListID, :SetNum, :Built, :Quantity, :HaveSpareParts, :Notes);';

    var Params := FDQuery.Params;
    Params.ParamByName('MySetListID').asInteger := SetListID;
    Params.ParamByName('SetNum').asString := Setnum;
    Params.ParamByName('Built').asInteger := IfThen(ChkBuilt.Checked,1,0);
    Params.ParamByName('Quantity').asInteger := StrToInt(EditAmount.Text); // Already checked to be valid
    Params.ParamByName('HaveSpareParts').asInteger := IfThen(ChkSpareParts.Checked,1,0);
    Params.ParamByName('Notes').asString := MemoNote.Text;
    FDQuery.ExecSQL;
  finally
    FDQuery.Free;
    FrmMain.ReleaseConnection(SqlConnection);
  end;

  // call frmmain to update any possible frames that may already be open
end;

procedure TDlgAddToSetList.FFillPulldown();
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
    var SqlConnection := FrmMain.AcquireConnection;
    var FDQuery := TFDQuery.Create(nil);
    try
      FDQuery.Connection := SqlConnection;
      FDQuery.SQL.Text := 'SELECT ID, NAME' +
                          ' FROM MySetLists ORDER BY NAME';
      FDQuery.Open;

      while not FDQuery.Eof do begin
        var SetListObject := TSetListObject.Create;
        SetListObject.id := FDQuery.FieldByName('id').AsInteger;
        SetListObject.name := FDQuery.FieldByName('name').AsString;
        FSetListObjectList.Add(SetListObject);

        FDQuery.Next;
      end;
    finally
      FDQuery.Free;
      FrmMain.ReleaseConnection(SqlConnection);
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
