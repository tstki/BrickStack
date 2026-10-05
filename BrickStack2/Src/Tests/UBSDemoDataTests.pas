unit UBSDemoDataTests;

interface

uses
  TestFramework;

type
  TDemoDataTests = class(TTestCase)
  published
    procedure ReturnsCollectionTotalsAndLists;
  end;

implementation

uses
  System.JSON,
  System.SysUtils,
  UBSDemoData;

procedure TDemoDataTests.ReturnsCollectionTotalsAndLists;
var
  Json: string;
  ParsedJson: TJSONValue;
begin
  Json := BuildDemoJson;
  ParsedJson := TJSONObject.ParseJSONValue(Json);
  try
    Check(Assigned(ParsedJson), 'Backend demo payload must be valid JSON');
    Check(Pos('"service":"BrickStack2 backend"', Json) > 0);
    Check(Pos('"sets":128', Json) > 0);
    Check(Pos('"pieces":18432', Json) > 0);
    Check(Pos('"name":"To build"', Json) > 0);
  finally
    ParsedJson.Free;
  end;
end;

initialization
  RegisterTest(TDemoDataTests.Suite);

end.
