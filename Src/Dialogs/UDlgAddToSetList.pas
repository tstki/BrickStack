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
    LblAmount: TLabel;
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
    FBSSetID: Integer;
    FBSSetListID: Integer;
    FSetNum: String;
    FSetListObjectList: TSetListObjectList;
    procedure FFillPulldown();
    procedure FUpdateUI();
    procedure FSetBSSetID(BSSetID: Integer);
  public
    { Public declarations }

    property BSSetID: Integer read FBSSetID write FSetBSSetID;
    property BSSetListID: Integer read FBSSetListID write FBSSetListID;
    property SetNum: String read FSetNum write FSetNum;
  end;

implementation

{$R *.dfm}

uses
  Math,
  FireDAC.Comp.Client, FireDAC.Stan.Param, USqLiteConnection,
  UFrmMain, Data.DB,
  UStrings;

procedure TDlgAddToSetList.FormCreate(Sender: TObject);
begin
  inherited;

  EditAmount.Text := '1';

  FSetListObjectList := TSetListObjectList.Create;
end;

procedure TDlgAddToSetList.FormDestroy(Sender: TObject);
begin
  FSetListObjectList.Free;
  inherited;
end;

procedure TDlgAddToSetList.FormShow(Sender: TObject);
begin
  if FBSSetID <> 0 then
    Self.Caption := Format(StrEditSetTo, [FSetNum, FBSSetID])
  else
    Self.Caption := Format(StrAddSetTo, [FSetNum]);

  LblAmount.Enabled := FBSSetID = 0;
  EditAmount.Enabled := FBSSetID = 0;

  FFillPulldown;
  MemoNoteChange(Self);
  FUpdateUI;
end;

procedure TDlgAddToSetList.FSetBSSetID(BSSetID: Integer);
begin
  FBSSetID := BSSetID;

  var SqlConnection := FrmMain.AcquireConnection;
  var FDQuery := TFDQuery.Create(nil);
  try
    FDQuery.Connection := SqlConnection;

    FDQuery.SQL.Text := 'SELECT BSSetListID, set_num, Built, HaveSpareParts, Notes from BSSets' +
                        ' WHERE ID = :ID;';

    var Params := FDQuery.Params;
    Params.ParamByName('ID').asInteger := BSSetID;
    FDQuery.Open;

    if not FDQuery.Eof then begin
      FBSSetListID := FDQuery.FieldByName('BSSetListID').AsInteger;
      FSetNum := FDQuery.FieldByName('set_num').AsString;
      ChkBuilt.Checked := FDQuery.FieldByName('Built').AsInteger = 1;
      ChkSpareParts.Checked := FDQuery.FieldByName('HaveSpareParts').AsInteger = 1;
      MemoNote.Text := FDQuery.FieldByName('Notes').AsString;
    end;

    //read query result
  finally
    FDQuery.Free;
    FrmMain.ReleaseConnection(SqlConnection);
  end;
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

  var BSSetListID := Integer(CbxSetList.Items.Objects[CbxSetList.ItemIndex]);

  //get mode - edit or insert. If update mode

  var SqlConnection := FrmMain.AcquireConnection;
  var FDQuery := TFDQuery.Create(nil);
  try
    FDQuery.Connection := SqlConnection;

    var SqlStr := '';
    if FBSSetID <> 0 then begin
      SqlStr := 'UPDATE BSSets' +
                ' SET BSSetListID = :BSSetListID, Built = :Built, HaveSpareParts = :HaveSpareParts, Notes = :Notes' +
                ' WHERE ID = :ID;';
    end else begin
      SqlStr := 'INSERT INTO BSSets' +
                ' (BSSetListID, set_num, Built, HaveSpareParts, Notes)' +
                ' VALUES(:BSSetListID, :SetNum, :Built, :HaveSpareParts, :Notes);';
      if StrToInt(EditAmount.Text) > 1 then begin
        for var I := 1 to StrToInt(EditAmount.Text) do
          SqlStr := SqlStr + SqlStr;
      end;
    end;

    FDQuery.SQL.Text := SqlStr;

    var Params := FDQuery.Params;
    Params.ParamByName('BSSetListID').asInteger := BSSetListID;
    if FBSSetID = 0 then
      Params.ParamByName('SetNum').asString := Setnum;
    Params.ParamByName('Built').asInteger := IfThen(ChkBuilt.Checked,1,0);
    Params.ParamByName('HaveSpareParts').asInteger := IfThen(ChkSpareParts.Checked,1,0);
    Params.ParamByName('Notes').asString := MemoNote.Text;
    if FBSSetID <> 0 then
      Params.ParamByName('ID').asInteger := FBSSetID;
    FDQuery.ExecSQL;
  finally
    FDQuery.Free;
    FrmMain.ReleaseConnection(SqlConnection);
  end;

  // call frmmain to update any possible frames that may already be open
  TFrmMain.UpdateSetsByCollectionID(BSSetListID);
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
                          ' FROM BSSetLists ORDER BY NAME';
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
      var Index := 0;
      for var Obj in FSetListObjectList do begin
        CbxSetList.Items.AddObject(Obj.Name, TObject(Obj.ID));
        if (BSSetListID <> 0) and (Obj.ID = BSSetListID) then
          CbxSetList.ItemIndex := Index;

        Inc(Index);
      end;


      // todo: Try to use latest selection from config
      if ((BSSetListID = 0) and (FSetListObjectList.Count > 0)) or
         (CbxSetList.ItemIndex = -1) then
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
