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
    procedure RunAllMigrationsThereWereNotRan;

    [TestCase] [WillRaise(EMigrationException)]
    procedure ThrowExceptionWhenMigrationFails;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections,
  System.Rtti, System.Classes, DatabaseException;

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

procedure TestMigrationRunner.ThrowExceptionWhenMigrationFails;
var
  ScriptOne, ScriptTwo : TScript;
  Scripts : TList<TScript>;
  ErrorMessage : String;
begin
  ScriptOne := TScript.Create;
  ScriptOne.Id := 1;
  ScriptOne.Name := 'Create table';
  ScriptOne.Script := TStringList.Create;
  ScriptOne.Script.Add('CREATE TABLE');

  Scripts := TList<TScript>.Create;
  Scripts.Add(ScriptOne);

  ScriptProducer.Setup.WillReturn(TValue.From(Scripts)).When.RetrieveScripts;
  DatabaseHandler.Setup.WillReturn(TValue.From(False)).When.IsApplied(ScriptOne);
  DatabaseHandler.Setup.WillRaise(EDatabaseException).When.RunScript(ScriptOne);

  ErrorMessage := 'Failed to run migration for script:' + sLineBreak +
                  'Id = 1' + sLineBreak +
                  'Name = Create table' + sLineBreak +
                  'Script = CREATE TABLE' + sLineBreak;

  Assert.WillRaise(MigrationRunner.Execute, EMigrationException, ErrorMessage);
end;

procedure TestMigrationRunner.RunAllMigrationsThereWereNotRan;
var
  ScriptOne, ScriptTwo : TScript;
  Scripts : TList<TScript>;
begin
  ScriptOne := TScript.Create;
  ScriptOne.Id := 1;
  ScriptOne.Name := 'Create table';
  ScriptOne.Script := TStringList.Create;
  ScriptOne.Script.Add('CREATE TABLE');

  ScriptTwo := TScript.Create;
  ScriptTwo.Id := 2;
  ScriptTwo.Name := 'Create columns';
  ScriptTwo.Script := TStringList.Create;
  ScriptTwo.Script.Add('CREATE colum');

  Scripts := TList<TScript>.Create;
  Scripts.Add(ScriptOne);
  Scripts.Add(ScriptTwo);

  ScriptProducer.Setup.WillReturn(TValue.From(Scripts)).When.RetrieveScripts;
  with DatabaseHandler.Setup do
  begin
    Expect.Once.When.RunScript(ScriptTwo);
    Expect.Never.When.RunScript(ScriptOne);
    WillReturn(TValue.From(True)).When.IsApplied(ScriptOne);
    WillReturn(TValue.From(False)).When.IsApplied(ScriptTwo);
  end;

  MigrationRunner.Execute;

  DatabaseHandler.Verify('Execute should call RunScript');
end;

end.
