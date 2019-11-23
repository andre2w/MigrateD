unit TestMigrationRunnerUnit;

interface

uses
  DUnitX.TestFramework, MigrationRunnerUnit;

type

  [TestFixture]
  TestMigrationRunner = class(TObject)
  private
    MigrationRunner : TMigrationRunner;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [TestCase]
    procedure testRunMigration;
  end;

implementation

uses
  System.SysUtils;

{ TestMigrationRunner }

procedure TestMigrationRunner.Setup;
begin
  MigrationRunner := TMigrationRunner.Create;
end;

procedure TestMigrationRunner.TearDown;
begin
  FreeAndNil(MigrationRunner);
end;

procedure TestMigrationRunner.testRunMigration;
begin
  MigrationRunner.execute;
end;

end.
