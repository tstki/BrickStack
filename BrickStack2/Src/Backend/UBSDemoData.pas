unit UBSDemoData;

interface

function BuildDemoJson: string;

implementation

function BuildDemoJson: string;
begin
  Result :=
    '{"service":"BrickStack2 backend","mode":"dummy",' +
    '"collection":{"name":"My Collection","sets":128,"pieces":18432,"built":71},' +
    '"setLists":[' +
      '{"name":"To build","sets":12},' +
      '{"name":"Built","sets":71},' +
      '{"name":"Wishlist","sets":45}' +
    ']}';
end;

end.
