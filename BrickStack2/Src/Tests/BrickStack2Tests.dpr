program BrickStack2Tests;

{$APPTYPE CONSOLE}

uses
  DUnitTestRunner,
  FireDAC.Comp.Client,
  FireDAC.DApt,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.Async,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  UBSDemoData in '..\Backend\UBSDemoData.pas',
  UBSDatabaseBootstrap in '..\Backend\UBSDatabaseBootstrap.pas',
  UBSAdminBootstrap in '..\Backend\UBSAdminBootstrap.pas',
  UBSCollectionRepository in '..\Backend\UBSCollectionRepository.pas',
  UBSTotp in '..\Backend\UBSTotp.pas',
  UBSRebrickableCatalogRepository in '..\Backend\UBSRebrickableCatalogRepository.pas',
  UBSDatabaseBootstrapTests in 'UBSDatabaseBootstrapTests.pas',
  UBSAdminBootstrapTests in 'UBSAdminBootstrapTests.pas',
  UBSCollectionRepositoryTests in 'UBSCollectionRepositoryTests.pas',
  UBSRebrickableCatalogRepositoryTests in 'UBSRebrickableCatalogRepositoryTests.pas',
  UBSDemoDataTests in 'UBSDemoDataTests.pas';

begin
  DUnitTestRunner.RunRegisteredTests;
end.
