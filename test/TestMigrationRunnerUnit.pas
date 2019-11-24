unit TestMigrationRunnerUnit;

interface

uses
  DUnitX.TestFramework, Delphi.Mocks, ScriptProducer, MigrationRunner,
  DatabaseHandler;

type

  [TestFixture]
  TestMigrationRunner = class(TObject)
  private
    MigrationRunner : TMigrationRunner;
    ScriptProducer  : TMock<IScriptProducer>;
    DatabaseHandler : TMock<IDatabaseHandler>;
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
  System.SysUtils, System.Generics.Collections,
  System.Rtti, System.Classes;

{ TestMigrationRunner }

procedure TestMigrationRunner.Setup;
begin
  ScriptProducer := TMock<IScriptProducer>.Create;
  DatabaseHandler := TMock<IDatabaseHandler>.Create;
  MigrationRunner := TMigrationRunner.Create(ScriptProducer, DatabaseHandler);
end;

procedure TestMigrationRunner.TearDown;
begin
  FreeAndNil(MigrationRunner);
end;

procedure TestMigrationRunner.testRunMigration;
var
  ScriptOne, ScriptTwo : TScript;
  Scripts : TList<TScript>;
begin
  ScriptOne := TScript.Create;
  ScriptOne.Id := 1;
  ScriptOne.Name := 'Create columns';
  ScriptOne.Script := TStringList.Create;
  ScriptOne.Script.Add('CREATE TABLE');

  Scripts := TList<TScript>.Create;
  Scripts.Add(ScriptOne);

  ScriptProducer.Setup.WillReturn(TValue.From<TList<TScript>>(Scripts)).When.RetrieveScripts;
  DatabaseHandler.Setup.Expect.Once.When.RunScript(ScriptOne);

  MigrationRunner.Execute;


  DatabaseHandler.Verify('Execute should call RunScript');
end;

end.
