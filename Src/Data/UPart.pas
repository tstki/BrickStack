unit UPart;

interface

uses
  FireDAC.Comp.Client,
  System.Classes, Generics.Collections;

type
  TPartObject = class(TObject)
  private
    { Private declarations }
    // Part details
    FPartNum: String;
    FName: String;
    FQuantity: Integer; // A.k.a. max count
    FIsSpare: Boolean;
    FImgUrl: String;
    FColorRGB: String;
    FColorName: String;
    FColorIsTrans: Boolean;

    //FDirty: Boolean;    // Not saved // Item was modified and needs to update
    //FDoDelete: Boolean; // Not saved // Item was deleted during import, remove it from the database on save.

    // Selection storage
    //FMaxCount: Integer; // Amount in set
    //FSelected: Integer; // Amount "owned" in this inventory.


    //FLoaded: Boolean; // Not saved. Used to indicate whether the part content was loaded into this object yet (for performance)
  public
    { Public declarations }
    //procedure LoadByPartNum(PartNum: String);
    procedure LoadFromQuery(FDQuery: TFDQuery);
    property PartNum: String read FPartNum write FPartNum;
    property PartName: String read FName write FName;
    property Quantity: Integer read FQuantity write FQuantity;
    property IsSpare: Boolean read FIsSpare write FIsSpare;
    property ImgUrl: String read FImgUrl write FImgUrl;
    property ColorRGB: String read FColorRGB write FColorRGB;
    property ColorName: String read FColorName write FColorName;
    property ColorIsTrans: Boolean read FColorIsTrans write FColorIsTrans;
  end;

  // Move this to a separate unit later:
  TPartObjectList = class(TObjectList<TPartObject>)
  public
    procedure LoadFromQuery(FDQuery: TFDQuery);
    procedure LoadFromExternal;
    //procedure LoadFromFile;
    //procedure SaveToFile(ReWrite: Boolean);
    procedure SaveToSQL(SqlConnection: TFDConnection);
  end;

implementation

uses
  SysUtils;
//QueryToPartObjectList
//EnrichPartObjects - with your own parts for this set
                   {
procedure TPartObject.LoadByPartNum(PartNum: String);
begin
  var SqlConnection := FrmMain.AcquireConnection; // Kept until end of form
  var FDQuery := TFDQuery.Create(nil);
  try
    FDQuery.Connection := SqlConnection;
    FDQuery.SQL.Text := 'SELECT id, name, description, useincollection, externalid, externaltype, sortindex,'+
                        ' (select sum(quantity) FROM BSSets s WHERE s.BSSetListID = m.ID) AS SetCount' +
                        ' FROM BSSetLists m WHERE ID=:ID';

    var Params := FDQuery.Params;
    Params.ParamByName('id').asInteger := ID;

    FDQuery.Open;

    Self.LoadFromQuery(FDQuery);
  finally
    FDQuery.Free;
    FrmMain.ReleaseConnection(SqlConnection);
  end;
end;}

procedure TPartObject.LoadFromQuery(FDQuery: TFDQuery);
begin
  Self.FPartNum := FDQuery.FieldByName('part_num').AsString;
  Self.FName := FDQuery.FieldByName('partname').AsString;
  Self.FQuantity := FDQuery.FieldByName('quantity').AsInteger;
  Self.FIsSpare := (FDQuery.FieldByName('is_spare').AsInteger) = 1;
  Self.FImgUrl := FDQuery.FieldByName('img_url').AsString;
  Self.FColorRGB := FDQuery.FieldByName('rgb').AsString;
  Self.FColorName := FDQuery.FieldByName('colorname').AsString;
  Self.FColorIsTrans := (FDQuery.FieldByName('is_trans').AsInteger) = 1;

//  Self.FPartCatID := FDQuery.FieldByName('partcatid').AsInteger;
//  Self.FPartMaterial := FDQuery.FieldByName('partmaterial').AsString;

  //Self.IconIndex := FDQuery.FieldByName('iconindex').AsInteger;
{  if FDQuery.FieldByName('setcount').AsString <> '' then // Zero gives empty string
    Self.SetCount := FDQuery.FieldByName('setcount').AsInteger
  else
    Self.SetCount := 0;    }
  //Self.FDirty := False;
  //Self.FDoDelete := False;
end;

// TPartObjectList

procedure TPartObjectList.LoadFromQuery(FDQuery: TFDQuery);
begin
  FDQuery.Open;

  while not FDQuery.Eof do begin
    var PartObject := TPartObject.Create;
    PartObject.LoadFromQuery(FDQuery);

    Self.Add(PartObject);

    FDQuery.Next;
  end;
end;

procedure TPartObjectList.LoadFromExternal();//FNetHttp
begin
//
end;

procedure TPartObjectList.SaveToSQL(SqlConnection: TFDConnection);
begin
//todo: if dirty, do insert or update.
//Intended for a batch save after import

//start transaction?
              {
  for var PartObject in Self do begin
    if not PartObject.FDirty then
      Continue;

    if PartObject.FID <> 0 then begin
      if PartObject.FDoDelete then begin
      //delete
      end else begin
      //update
      end;
    end else begin
      //insert
    end;
  end;    }

//commit transaction
end;

end.
