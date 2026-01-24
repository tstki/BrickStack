
{**************************************************************************}
{                                                                          }
{                             XML Data Binding                             }
{                                                                          }
{         Generated on: 22-Jan-26 19:39:40                                 }
{       Generated from: E:\Projects\Delphi\BrickStack\Misc\BrickLink.xml   }
{                                                                          }
{**************************************************************************}

unit UBricklinkXMLIntf;

interface

uses Xml.xmldom, Xml.XMLDoc, Xml.XMLIntf;

type

{ Forward Decls }

  IXMLINVENTORYType = interface;
  IXMLITEMType = interface;

{ IXMLINVENTORYType }

  IXMLINVENTORYType = interface(IXMLNodeCollection)
    ['{08647869-AC3B-421A-B35A-89BBCE88C8F1}']
    { Property Accessors }
    function Get_ITEM(const Index: Integer): IXMLITEMType;
    { Methods & Properties }
    function Add: IXMLITEMType;
    function Insert(const Index: Integer): IXMLITEMType;
    property ITEM[const Index: Integer]: IXMLITEMType read Get_ITEM; default;
  end;

{ IXMLITEMType }

  IXMLITEMType = interface(IXMLNode)
    ['{CB09FB41-EE62-496F-980B-EBD1128F9D50}']
    { Property Accessors }
    function Get_ITEMTYPE: UnicodeString;
    function Get_ITEMID: UnicodeString;
    function Get_COLOR: UnicodeString;
    function Get_CONDITION: UnicodeString;
    function Get_SUBCONDITION: UnicodeString;
    function Get_QTY: UnicodeString;
    function Get_EXTRA: UnicodeString;
    function Get_COUNTERPART: UnicodeString;
    function Get_ALTERNATE: UnicodeString;
    function Get_MATCHID: UnicodeString;
    function Get_MAXPRICE: UnicodeString;
    function Get_MINQTY: UnicodeString;
    function Get_QTYFILLED: UnicodeString;
    function Get_REMARKS: UnicodeString;
    function Get_NOTIFY: UnicodeString;
    function Get_WANTEDSHOW: UnicodeString;
    function Get_WANTEDLISTID: UnicodeString;
    function Get_CATEGORY: UnicodeString;
    function Get_PRICE: UnicodeString;
    function Get_BULK: UnicodeString;
    function Get_DESCRIPTION: UnicodeString;
    function Get_SALE: UnicodeString;
    function Get_STOCKROOM: UnicodeString;
    function Get_STOCKROOMID: UnicodeString;
    function Get_RETAIN: UnicodeString;
    function Get_MYCOST: UnicodeString;
    function Get_MYWEIGHT: UnicodeString;
    function Get_BUYERUSERNAME: UnicodeString;
    function Get_TQ1: UnicodeString;
    function Get_TP1: UnicodeString;
    function Get_TQ2: UnicodeString;
    function Get_TP2: UnicodeString;
    function Get_TQ3: UnicodeString;
    function Get_TP3: UnicodeString;
    function Get_EXTENDED: UnicodeString;
    function Get_INVDIMX: UnicodeString;
    function Get_INVDIMY: UnicodeString;
    function Get_INVDIMZ: UnicodeString;
    function Get_SUPERLOTID: UnicodeString;
    function Get_SUPERLOTQTY: UnicodeString;
    function Get_SUPERLOTTYPE: UnicodeString;
    function Get_SUPERLOTREMARKS: UnicodeString;
    procedure Set_ITEMTYPE(const Value: UnicodeString);
    procedure Set_ITEMID(const Value: UnicodeString);
    procedure Set_COLOR(const Value: UnicodeString);
    procedure Set_CONDITION(const Value: UnicodeString);
    procedure Set_SUBCONDITION(const Value: UnicodeString);
    procedure Set_QTY(const Value: UnicodeString);
    procedure Set_EXTRA(const Value: UnicodeString);
    procedure Set_COUNTERPART(const Value: UnicodeString);
    procedure Set_ALTERNATE(const Value: UnicodeString);
    procedure Set_MATCHID(const Value: UnicodeString);
    procedure Set_MAXPRICE(const Value: UnicodeString);
    procedure Set_MINQTY(const Value: UnicodeString);
    procedure Set_QTYFILLED(const Value: UnicodeString);
    procedure Set_REMARKS(const Value: UnicodeString);
    procedure Set_NOTIFY(const Value: UnicodeString);
    procedure Set_WANTEDSHOW(const Value: UnicodeString);
    procedure Set_WANTEDLISTID(const Value: UnicodeString);
    procedure Set_CATEGORY(const Value: UnicodeString);
    procedure Set_PRICE(const Value: UnicodeString);
    procedure Set_BULK(const Value: UnicodeString);
    procedure Set_DESCRIPTION(const Value: UnicodeString);
    procedure Set_SALE(const Value: UnicodeString);
    procedure Set_STOCKROOM(const Value: UnicodeString);
    procedure Set_STOCKROOMID(const Value: UnicodeString);
    procedure Set_RETAIN(const Value: UnicodeString);
    procedure Set_MYCOST(const Value: UnicodeString);
    procedure Set_MYWEIGHT(const Value: UnicodeString);
    procedure Set_BUYERUSERNAME(const Value: UnicodeString);
    procedure Set_TQ1(const Value: UnicodeString);
    procedure Set_TP1(const Value: UnicodeString);
    procedure Set_TQ2(const Value: UnicodeString);
    procedure Set_TP2(const Value: UnicodeString);
    procedure Set_TQ3(const Value: UnicodeString);
    procedure Set_TP3(const Value: UnicodeString);
    procedure Set_EXTENDED(const Value: UnicodeString);
    procedure Set_INVDIMX(const Value: UnicodeString);
    procedure Set_INVDIMY(const Value: UnicodeString);
    procedure Set_INVDIMZ(const Value: UnicodeString);
    procedure Set_SUPERLOTID(const Value: UnicodeString);
    procedure Set_SUPERLOTQTY(const Value: UnicodeString);
    procedure Set_SUPERLOTTYPE(const Value: UnicodeString);
    procedure Set_SUPERLOTREMARKS(const Value: UnicodeString);
    { Methods & Properties }
    property ITEMTYPE: UnicodeString read Get_ITEMTYPE write Set_ITEMTYPE;
    property ITEMID: UnicodeString read Get_ITEMID write Set_ITEMID;
    property COLOR: UnicodeString read Get_COLOR write Set_COLOR;
    property CONDITION: UnicodeString read Get_CONDITION write Set_CONDITION;
    property SUBCONDITION: UnicodeString read Get_SUBCONDITION write Set_SUBCONDITION;
    property QTY: UnicodeString read Get_QTY write Set_QTY;
    property EXTRA: UnicodeString read Get_EXTRA write Set_EXTRA;
    property COUNTERPART: UnicodeString read Get_COUNTERPART write Set_COUNTERPART;
    property ALTERNATE: UnicodeString read Get_ALTERNATE write Set_ALTERNATE;
    property MATCHID: UnicodeString read Get_MATCHID write Set_MATCHID;
    property MAXPRICE: UnicodeString read Get_MAXPRICE write Set_MAXPRICE;
    property MINQTY: UnicodeString read Get_MINQTY write Set_MINQTY;
    property QTYFILLED: UnicodeString read Get_QTYFILLED write Set_QTYFILLED;
    property REMARKS: UnicodeString read Get_REMARKS write Set_REMARKS;
    property NOTIFY: UnicodeString read Get_NOTIFY write Set_NOTIFY;
    property WANTEDSHOW: UnicodeString read Get_WANTEDSHOW write Set_WANTEDSHOW;
    property WANTEDLISTID: UnicodeString read Get_WANTEDLISTID write Set_WANTEDLISTID;
    property CATEGORY: UnicodeString read Get_CATEGORY write Set_CATEGORY;
    property PRICE: UnicodeString read Get_PRICE write Set_PRICE;
    property BULK: UnicodeString read Get_BULK write Set_BULK;
    property DESCRIPTION: UnicodeString read Get_DESCRIPTION write Set_DESCRIPTION;
    property SALE: UnicodeString read Get_SALE write Set_SALE;
    property STOCKROOM: UnicodeString read Get_STOCKROOM write Set_STOCKROOM;
    property STOCKROOMID: UnicodeString read Get_STOCKROOMID write Set_STOCKROOMID;
    property RETAIN: UnicodeString read Get_RETAIN write Set_RETAIN;
    property MYCOST: UnicodeString read Get_MYCOST write Set_MYCOST;
    property MYWEIGHT: UnicodeString read Get_MYWEIGHT write Set_MYWEIGHT;
    property BUYERUSERNAME: UnicodeString read Get_BUYERUSERNAME write Set_BUYERUSERNAME;
    property TQ1: UnicodeString read Get_TQ1 write Set_TQ1;
    property TP1: UnicodeString read Get_TP1 write Set_TP1;
    property TQ2: UnicodeString read Get_TQ2 write Set_TQ2;
    property TP2: UnicodeString read Get_TP2 write Set_TP2;
    property TQ3: UnicodeString read Get_TQ3 write Set_TQ3;
    property TP3: UnicodeString read Get_TP3 write Set_TP3;
    property EXTENDED: UnicodeString read Get_EXTENDED write Set_EXTENDED;
    property INVDIMX: UnicodeString read Get_INVDIMX write Set_INVDIMX;
    property INVDIMY: UnicodeString read Get_INVDIMY write Set_INVDIMY;
    property INVDIMZ: UnicodeString read Get_INVDIMZ write Set_INVDIMZ;
    property SUPERLOTID: UnicodeString read Get_SUPERLOTID write Set_SUPERLOTID;
    property SUPERLOTQTY: UnicodeString read Get_SUPERLOTQTY write Set_SUPERLOTQTY;
    property SUPERLOTTYPE: UnicodeString read Get_SUPERLOTTYPE write Set_SUPERLOTTYPE;
    property SUPERLOTREMARKS: UnicodeString read Get_SUPERLOTREMARKS write Set_SUPERLOTREMARKS;
  end;

{ Forward Decls }

  TXMLINVENTORYType = class;
  TXMLITEMType = class;

{ TXMLINVENTORYType }

  TXMLINVENTORYType = class(TXMLNodeCollection, IXMLINVENTORYType)
  protected
    { IXMLINVENTORYType }
    function Get_ITEM(const Index: Integer): IXMLITEMType;
    function Add: IXMLITEMType;
    function Insert(const Index: Integer): IXMLITEMType;
  public
    procedure AfterConstruction; override;
  end;

{ TXMLITEMType }

  TXMLITEMType = class(TXMLNode, IXMLITEMType)
  protected
    { IXMLITEMType }
    function Get_ITEMTYPE: UnicodeString;
    function Get_ITEMID: UnicodeString;
    function Get_COLOR: UnicodeString;
    function Get_CONDITION: UnicodeString;
    function Get_SUBCONDITION: UnicodeString;
    function Get_QTY: UnicodeString;
    function Get_EXTRA: UnicodeString;
    function Get_COUNTERPART: UnicodeString;
    function Get_ALTERNATE: UnicodeString;
    function Get_MATCHID: UnicodeString;
    function Get_MAXPRICE: UnicodeString;
    function Get_MINQTY: UnicodeString;
    function Get_QTYFILLED: UnicodeString;
    function Get_REMARKS: UnicodeString;
    function Get_NOTIFY: UnicodeString;
    function Get_WANTEDSHOW: UnicodeString;
    function Get_WANTEDLISTID: UnicodeString;
    function Get_CATEGORY: UnicodeString;
    function Get_PRICE: UnicodeString;
    function Get_BULK: UnicodeString;
    function Get_DESCRIPTION: UnicodeString;
    function Get_SALE: UnicodeString;
    function Get_STOCKROOM: UnicodeString;
    function Get_STOCKROOMID: UnicodeString;
    function Get_RETAIN: UnicodeString;
    function Get_MYCOST: UnicodeString;
    function Get_MYWEIGHT: UnicodeString;
    function Get_BUYERUSERNAME: UnicodeString;
    function Get_TQ1: UnicodeString;
    function Get_TP1: UnicodeString;
    function Get_TQ2: UnicodeString;
    function Get_TP2: UnicodeString;
    function Get_TQ3: UnicodeString;
    function Get_TP3: UnicodeString;
    function Get_EXTENDED: UnicodeString;
    function Get_INVDIMX: UnicodeString;
    function Get_INVDIMY: UnicodeString;
    function Get_INVDIMZ: UnicodeString;
    function Get_SUPERLOTID: UnicodeString;
    function Get_SUPERLOTQTY: UnicodeString;
    function Get_SUPERLOTTYPE: UnicodeString;
    function Get_SUPERLOTREMARKS: UnicodeString;
    procedure Set_ITEMTYPE(const Value: UnicodeString);
    procedure Set_ITEMID(const Value: UnicodeString);
    procedure Set_COLOR(const Value: UnicodeString);
    procedure Set_CONDITION(const Value: UnicodeString);
    procedure Set_SUBCONDITION(const Value: UnicodeString);
    procedure Set_QTY(const Value: UnicodeString);
    procedure Set_EXTRA(const Value: UnicodeString);
    procedure Set_COUNTERPART(const Value: UnicodeString);
    procedure Set_ALTERNATE(const Value: UnicodeString);
    procedure Set_MATCHID(const Value: UnicodeString);
    procedure Set_MAXPRICE(const Value: UnicodeString);
    procedure Set_MINQTY(const Value: UnicodeString);
    procedure Set_QTYFILLED(const Value: UnicodeString);
    procedure Set_REMARKS(const Value: UnicodeString);
    procedure Set_NOTIFY(const Value: UnicodeString);
    procedure Set_WANTEDSHOW(const Value: UnicodeString);
    procedure Set_WANTEDLISTID(const Value: UnicodeString);
    procedure Set_CATEGORY(const Value: UnicodeString);
    procedure Set_PRICE(const Value: UnicodeString);
    procedure Set_BULK(const Value: UnicodeString);
    procedure Set_DESCRIPTION(const Value: UnicodeString);
    procedure Set_SALE(const Value: UnicodeString);
    procedure Set_STOCKROOM(const Value: UnicodeString);
    procedure Set_STOCKROOMID(const Value: UnicodeString);
    procedure Set_RETAIN(const Value: UnicodeString);
    procedure Set_MYCOST(const Value: UnicodeString);
    procedure Set_MYWEIGHT(const Value: UnicodeString);
    procedure Set_BUYERUSERNAME(const Value: UnicodeString);
    procedure Set_TQ1(const Value: UnicodeString);
    procedure Set_TP1(const Value: UnicodeString);
    procedure Set_TQ2(const Value: UnicodeString);
    procedure Set_TP2(const Value: UnicodeString);
    procedure Set_TQ3(const Value: UnicodeString);
    procedure Set_TP3(const Value: UnicodeString);
    procedure Set_EXTENDED(const Value: UnicodeString);
    procedure Set_INVDIMX(const Value: UnicodeString);
    procedure Set_INVDIMY(const Value: UnicodeString);
    procedure Set_INVDIMZ(const Value: UnicodeString);
    procedure Set_SUPERLOTID(const Value: UnicodeString);
    procedure Set_SUPERLOTQTY(const Value: UnicodeString);
    procedure Set_SUPERLOTTYPE(const Value: UnicodeString);
    procedure Set_SUPERLOTREMARKS(const Value: UnicodeString);
  end;

{ Global Functions }

function GetINVENTORY(Doc: IXMLDocument): IXMLINVENTORYType;
function LoadINVENTORY(const FileName: string): IXMLINVENTORYType;
function NewINVENTORY: IXMLINVENTORYType;

const
  TargetNamespace = '';

implementation

uses System.Variants, System.SysUtils, Xml.xmlutil;

{ Global Functions }

function GetINVENTORY(Doc: IXMLDocument): IXMLINVENTORYType;
begin
  Result := Doc.GetDocBinding('INVENTORY', TXMLINVENTORYType, TargetNamespace) as IXMLINVENTORYType;
end;

function LoadINVENTORY(const FileName: string): IXMLINVENTORYType;
begin
  Result := LoadXMLDocument(FileName).GetDocBinding('INVENTORY', TXMLINVENTORYType, TargetNamespace) as IXMLINVENTORYType;
end;

function NewINVENTORY: IXMLINVENTORYType;
begin
  Result := NewXMLDocument.GetDocBinding('INVENTORY', TXMLINVENTORYType, TargetNamespace) as IXMLINVENTORYType;
end;

{ TXMLINVENTORYType }

procedure TXMLINVENTORYType.AfterConstruction;
begin
  RegisterChildNode('ITEM', TXMLITEMType);
  ItemTag := 'ITEM';
  ItemInterface := IXMLITEMType;
  inherited;
end;

function TXMLINVENTORYType.Get_ITEM(const Index: Integer): IXMLITEMType;
begin
  Result := List[Index] as IXMLITEMType;
end;

function TXMLINVENTORYType.Add: IXMLITEMType;
begin
  Result := AddItem(-1) as IXMLITEMType;
end;

function TXMLINVENTORYType.Insert(const Index: Integer): IXMLITEMType;
begin
  Result := AddItem(Index) as IXMLITEMType;
end;

{ TXMLITEMType }

function TXMLITEMType.Get_ITEMTYPE: UnicodeString;
begin
  Result := ChildNodes['ITEMTYPE'].Text;
end;

procedure TXMLITEMType.Set_ITEMTYPE(const Value: UnicodeString);
begin
  ChildNodes['ITEMTYPE'].NodeValue := Value;
end;

function TXMLITEMType.Get_ITEMID: UnicodeString;
begin
  Result := ChildNodes['ITEMID'].Text;
end;

procedure TXMLITEMType.Set_ITEMID(const Value: UnicodeString);
begin
  ChildNodes['ITEMID'].NodeValue := Value;
end;

function TXMLITEMType.Get_COLOR: UnicodeString;
begin
  Result := ChildNodes['COLOR'].Text;
end;

procedure TXMLITEMType.Set_COLOR(const Value: UnicodeString);
begin
  ChildNodes['COLOR'].NodeValue := Value;
end;

function TXMLITEMType.Get_CONDITION: UnicodeString;
begin
  Result := ChildNodes['CONDITION'].Text;
end;

procedure TXMLITEMType.Set_CONDITION(const Value: UnicodeString);
begin
  ChildNodes['CONDITION'].NodeValue := Value;
end;

function TXMLITEMType.Get_SUBCONDITION: UnicodeString;
begin
  Result := ChildNodes['SUB-CONDITION'].Text;
end;

procedure TXMLITEMType.Set_SUBCONDITION(const Value: UnicodeString);
begin
  ChildNodes['SUB-CONDITION'].NodeValue := Value;
end;

function TXMLITEMType.Get_QTY: UnicodeString;
begin
  Result := ChildNodes['QTY'].Text;
end;

procedure TXMLITEMType.Set_QTY(const Value: UnicodeString);
begin
  ChildNodes['QTY'].NodeValue := Value;
end;

function TXMLITEMType.Get_EXTRA: UnicodeString;
begin
  Result := ChildNodes['EXTRA'].Text;
end;

procedure TXMLITEMType.Set_EXTRA(const Value: UnicodeString);
begin
  ChildNodes['EXTRA'].NodeValue := Value;
end;

function TXMLITEMType.Get_COUNTERPART: UnicodeString;
begin
  Result := ChildNodes['COUNTERPART'].Text;
end;

procedure TXMLITEMType.Set_COUNTERPART(const Value: UnicodeString);
begin
  ChildNodes['COUNTERPART'].NodeValue := Value;
end;

function TXMLITEMType.Get_ALTERNATE: UnicodeString;
begin
  Result := ChildNodes['ALTERNATE'].Text;
end;

procedure TXMLITEMType.Set_ALTERNATE(const Value: UnicodeString);
begin
  ChildNodes['ALTERNATE'].NodeValue := Value;
end;

function TXMLITEMType.Get_MATCHID: UnicodeString;
begin
  Result := ChildNodes['MATCHID'].Text;
end;

procedure TXMLITEMType.Set_MATCHID(const Value: UnicodeString);
begin
  ChildNodes['MATCHID'].NodeValue := Value;
end;

function TXMLITEMType.Get_MAXPRICE: UnicodeString;
begin
  Result := ChildNodes['MAXPRICE'].Text;
end;

procedure TXMLITEMType.Set_MAXPRICE(const Value: UnicodeString);
begin
  ChildNodes['MAXPRICE'].NodeValue := Value;
end;

function TXMLITEMType.Get_MINQTY: UnicodeString;
begin
  Result := ChildNodes['MINQTY'].Text;
end;

procedure TXMLITEMType.Set_MINQTY(const Value: UnicodeString);
begin
  ChildNodes['MINQTY'].NodeValue := Value;
end;

function TXMLITEMType.Get_QTYFILLED: UnicodeString;
begin
  Result := ChildNodes['QTYFILLED'].Text;
end;

procedure TXMLITEMType.Set_QTYFILLED(const Value: UnicodeString);
begin
  ChildNodes['QTYFILLED'].NodeValue := Value;
end;

function TXMLITEMType.Get_REMARKS: UnicodeString;
begin
  Result := ChildNodes['REMARKS'].Text;
end;

procedure TXMLITEMType.Set_REMARKS(const Value: UnicodeString);
begin
  ChildNodes['REMARKS'].NodeValue := Value;
end;

function TXMLITEMType.Get_NOTIFY: UnicodeString;
begin
  Result := ChildNodes['NOTIFY'].Text;
end;

procedure TXMLITEMType.Set_NOTIFY(const Value: UnicodeString);
begin
  ChildNodes['NOTIFY'].NodeValue := Value;
end;

function TXMLITEMType.Get_WANTEDSHOW: UnicodeString;
begin
  Result := ChildNodes['WANTEDSHOW'].Text;
end;

procedure TXMLITEMType.Set_WANTEDSHOW(const Value: UnicodeString);
begin
  ChildNodes['WANTEDSHOW'].NodeValue := Value;
end;

function TXMLITEMType.Get_WANTEDLISTID: UnicodeString;
begin
  Result := ChildNodes['WANTEDLISTID'].Text;
end;

procedure TXMLITEMType.Set_WANTEDLISTID(const Value: UnicodeString);
begin
  ChildNodes['WANTEDLISTID'].NodeValue := Value;
end;

function TXMLITEMType.Get_CATEGORY: UnicodeString;
begin
  Result := ChildNodes['CATEGORY'].Text;
end;

procedure TXMLITEMType.Set_CATEGORY(const Value: UnicodeString);
begin
  ChildNodes['CATEGORY'].NodeValue := Value;
end;

function TXMLITEMType.Get_PRICE: UnicodeString;
begin
  Result := ChildNodes['PRICE'].Text;
end;

procedure TXMLITEMType.Set_PRICE(const Value: UnicodeString);
begin
  ChildNodes['PRICE'].NodeValue := Value;
end;

function TXMLITEMType.Get_BULK: UnicodeString;
begin
  Result := ChildNodes['BULK'].Text;
end;

procedure TXMLITEMType.Set_BULK(const Value: UnicodeString);
begin
  ChildNodes['BULK'].NodeValue := Value;
end;

function TXMLITEMType.Get_DESCRIPTION: UnicodeString;
begin
  Result := ChildNodes['DESCRIPTION'].Text;
end;

procedure TXMLITEMType.Set_DESCRIPTION(const Value: UnicodeString);
begin
  ChildNodes['DESCRIPTION'].NodeValue := Value;
end;

function TXMLITEMType.Get_SALE: UnicodeString;
begin
  Result := ChildNodes['SALE'].Text;
end;

procedure TXMLITEMType.Set_SALE(const Value: UnicodeString);
begin
  ChildNodes['SALE'].NodeValue := Value;
end;

function TXMLITEMType.Get_STOCKROOM: UnicodeString;
begin
  Result := ChildNodes['STOCKROOM'].Text;
end;

procedure TXMLITEMType.Set_STOCKROOM(const Value: UnicodeString);
begin
  ChildNodes['STOCKROOM'].NodeValue := Value;
end;

function TXMLITEMType.Get_STOCKROOMID: UnicodeString;
begin
  Result := ChildNodes['STOCKROOMID'].Text;
end;

procedure TXMLITEMType.Set_STOCKROOMID(const Value: UnicodeString);
begin
  ChildNodes['STOCKROOMID'].NodeValue := Value;
end;

function TXMLITEMType.Get_RETAIN: UnicodeString;
begin
  Result := ChildNodes['RETAIN'].Text;
end;

procedure TXMLITEMType.Set_RETAIN(const Value: UnicodeString);
begin
  ChildNodes['RETAIN'].NodeValue := Value;
end;

function TXMLITEMType.Get_MYCOST: UnicodeString;
begin
  Result := ChildNodes['MYCOST'].Text;
end;

procedure TXMLITEMType.Set_MYCOST(const Value: UnicodeString);
begin
  ChildNodes['MYCOST'].NodeValue := Value;
end;

function TXMLITEMType.Get_MYWEIGHT: UnicodeString;
begin
  Result := ChildNodes['MYWEIGHT'].Text;
end;

procedure TXMLITEMType.Set_MYWEIGHT(const Value: UnicodeString);
begin
  ChildNodes['MYWEIGHT'].NodeValue := Value;
end;

function TXMLITEMType.Get_BUYERUSERNAME: UnicodeString;
begin
  Result := ChildNodes['BUYERUSERNAME'].Text;
end;

procedure TXMLITEMType.Set_BUYERUSERNAME(const Value: UnicodeString);
begin
  ChildNodes['BUYERUSERNAME'].NodeValue := Value;
end;

function TXMLITEMType.Get_TQ1: UnicodeString;
begin
  Result := ChildNodes['TQ1'].Text;
end;

procedure TXMLITEMType.Set_TQ1(const Value: UnicodeString);
begin
  ChildNodes['TQ1'].NodeValue := Value;
end;

function TXMLITEMType.Get_TP1: UnicodeString;
begin
  Result := ChildNodes['TP1'].Text;
end;

procedure TXMLITEMType.Set_TP1(const Value: UnicodeString);
begin
  ChildNodes['TP1'].NodeValue := Value;
end;

function TXMLITEMType.Get_TQ2: UnicodeString;
begin
  Result := ChildNodes['TQ2'].Text;
end;

procedure TXMLITEMType.Set_TQ2(const Value: UnicodeString);
begin
  ChildNodes['TQ2'].NodeValue := Value;
end;

function TXMLITEMType.Get_TP2: UnicodeString;
begin
  Result := ChildNodes['TP2'].Text;
end;

procedure TXMLITEMType.Set_TP2(const Value: UnicodeString);
begin
  ChildNodes['TP2'].NodeValue := Value;
end;

function TXMLITEMType.Get_TQ3: UnicodeString;
begin
  Result := ChildNodes['TQ3'].Text;
end;

procedure TXMLITEMType.Set_TQ3(const Value: UnicodeString);
begin
  ChildNodes['TQ3'].NodeValue := Value;
end;

function TXMLITEMType.Get_TP3: UnicodeString;
begin
  Result := ChildNodes['TP3'].Text;
end;

procedure TXMLITEMType.Set_TP3(const Value: UnicodeString);
begin
  ChildNodes['TP3'].NodeValue := Value;
end;

function TXMLITEMType.Get_EXTENDED: UnicodeString;
begin
  Result := ChildNodes['EXTENDED'].Text;
end;

procedure TXMLITEMType.Set_EXTENDED(const Value: UnicodeString);
begin
  ChildNodes['EXTENDED'].NodeValue := Value;
end;

function TXMLITEMType.Get_INVDIMX: UnicodeString;
begin
  Result := ChildNodes['INVDIMX'].Text;
end;

procedure TXMLITEMType.Set_INVDIMX(const Value: UnicodeString);
begin
  ChildNodes['INVDIMX'].NodeValue := Value;
end;

function TXMLITEMType.Get_INVDIMY: UnicodeString;
begin
  Result := ChildNodes['INVDIMY'].Text;
end;

procedure TXMLITEMType.Set_INVDIMY(const Value: UnicodeString);
begin
  ChildNodes['INVDIMY'].NodeValue := Value;
end;

function TXMLITEMType.Get_INVDIMZ: UnicodeString;
begin
  Result := ChildNodes['INVDIMZ'].Text;
end;

procedure TXMLITEMType.Set_INVDIMZ(const Value: UnicodeString);
begin
  ChildNodes['INVDIMZ'].NodeValue := Value;
end;

function TXMLITEMType.Get_SUPERLOTID: UnicodeString;
begin
  Result := ChildNodes['SUPERLOTID'].Text;
end;

procedure TXMLITEMType.Set_SUPERLOTID(const Value: UnicodeString);
begin
  ChildNodes['SUPERLOTID'].NodeValue := Value;
end;

function TXMLITEMType.Get_SUPERLOTQTY: UnicodeString;
begin
  Result := ChildNodes['SUPERLOTQTY'].Text;
end;

procedure TXMLITEMType.Set_SUPERLOTQTY(const Value: UnicodeString);
begin
  ChildNodes['SUPERLOTQTY'].NodeValue := Value;
end;

function TXMLITEMType.Get_SUPERLOTTYPE: UnicodeString;
begin
  Result := ChildNodes['SUPERLOTTYPE'].Text;
end;

procedure TXMLITEMType.Set_SUPERLOTTYPE(const Value: UnicodeString);
begin
  ChildNodes['SUPERLOTTYPE'].NodeValue := Value;
end;

function TXMLITEMType.Get_SUPERLOTREMARKS: UnicodeString;
begin
  Result := ChildNodes['SUPERLOTREMARKS'].Text;
end;

procedure TXMLITEMType.Set_SUPERLOTREMARKS(const Value: UnicodeString);
begin
  ChildNodes['SUPERLOTREMARKS'].NodeValue := Value;
end;

end.
