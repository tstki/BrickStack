program BrickStack2Tests;

{$APPTYPE CONSOLE}

uses
  DUnitTestRunner,
  UBSDemoData in '..\Backend\UBSDemoData.pas',
  UBSDemoDataTests in 'UBSDemoDataTests.pas';

begin
  DUnitTestRunner.RunRegisteredTests;
end.
