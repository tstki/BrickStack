
{**************************************************************************}
{                                                                          }
{                             XML Data Binding                             }
{                                                                          }
{         Generated on: 21-Jul-24 11:28:20                                 }
{       Generated from: E:\Projects\Delphi\BrickStack\Misc\BrickLink.xml   }
{                                                                          }
{**************************************************************************}

unit UBrickLinkXMLIntf;

interface

uses Xml.xmldom, Xml.XMLDoc, Xml.XMLIntf;

type

{ Forward Decls }

  IXMLINVENTORYType = interface;
  IXMLITEMType = interface;

{ IXMLINVENTORYType }

  IXMLINVENTORYType = interface(IXMLNodeCollection)
    ['{CFE41B22-4503-4C8E-9209-0FD8074A6D71}']
    { Property Accessors }
    function Get_ITEM(const Index: Integer): IXMLITEMType;
    { Methods & Properties }
    function Add: IXMLITEMType;
    function Insert(const Index: Integer): IXMLITEMType;
    property ITEM[const Index: Integer]: IXMLITEMType read Get_ITEM; default;
  end;

{ IXMLITEMType }

  IXMLITEMType = interface(IXMLNode)
    ['{D7C06246-5670-440E-B224-22BCBFF88F49}']
    { Property Accessors }
    function Get_ITEMTYPE: UnicodeString;
    function Get_ITEMID: UnicodeString;
    function Get_MINQTY: Integer;
    procedure Set_ITEMTYPE(const Value: UnicodeString);
    procedure Set_ITEMID(const Value: UnicodeString);
    procedure Set_MINQTY(const Value: Integer);
    { Methods & Properties }
    property ITEMTYPE: UnicodeString read Get_ITEMTYPE write Set_ITEMTYPE;
    property ITEMID: UnicodeString read Get_ITEMID write Set_ITEMID;
    property MINQTY: Integer read Get_MINQTY write Set_MINQTY;
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
    function Get_MINQTY: Integer;
    procedure Set_ITEMTYPE(const Value: UnicodeString);
    procedure Set_ITEMID(const Value: UnicodeString);
    procedure Set_MINQTY(const Value: Integer);
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

function TXMLITEMType.Get_MINQTY: Integer;
begin
  Result := XmlStrToInt(ChildNodes['MINQTY'].Text);
end;

procedure TXMLITEMType.Set_MINQTY(const Value: Integer);
begin
  ChildNodes['MINQTY'].NodeValue := Value;
end;

end.