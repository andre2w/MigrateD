unit TestMigrationRunnerUnit;

interface

uses
  DUnitX.TestFramework, Delphi.Mocks, ScriptProducer, MigrationRunner,
  DatabaseHandler, System.Generics.Collections;

type

  [TestFixture]
  TestMigrationRunner = class(TObject)
  private
    MigrationRunner : TMigrationRunner;
    ScriptProducer  : TMock<IScriptProducer>;
    DatabaseHandler : TMock<IDatabaseHandler>;
    ScriptOne       : TScript;
    ScriptTwo       : TScript;
    Scripts         : TList<TScript>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [TestCase]
    procedure RunAllMigrationsThereWereNotApplied;
    [TestCase]
    procedure ThrowExceptionWhenMigrationFails;
    [TestCase]
    procedure StoreMigrationAfterBeingApplied;
    [TestCase]
    procedure CommitScriptWhenMigrationIsApplied;
    [TestCase]
    procedure RollbackWhenMigrationFails;
  end;

implementation

uses
  System.SysUtils,
  System.Rtti, System.Classes, DatabaseException;

{ TestMigrationRunner }

procedure TestMigrationRunner.Setup;
begin
  ScriptProducer := TMock<IScriptProducer>.Create;
  DatabaseHandler := TMock<IDatabaseHandler>.Create;
  MigrationRunner := TMigrationRunner.Create(ScriptProducer, DatabaseHandler);

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

end;

procedure TestMigrationRunner.TearDown;
begin
  FreeAndNil(MigrationRunner);
end;

procedure TestMigrationRunner.ThrowExceptionWhenMigrationFails;
var
  ErrorMessage : String;
begin

  ScriptProducer.Setup.WillReturn(TValue.From(Scripts)).When.RetrieveScripts;
  DatabaseHandler.Setup.WillReturn(TValue.From(False)).When.IsApplied(ScriptOne);
  DatabaseHandler.Setup.WillReturn(TValue.From(False)).When.IsApplied(ScriptTwo);
  DatabaseHandler.Setup.WillRaise(EDatabaseException).When.RunScript(ScriptOne);

  ErrorMessage := 'Failed to run migration for script:' + sLineBreak +
                  'Id = ' + IntToStr( ScriptOne.Id ) + sLineBreak +
                  'Name = ' + ScriptOne.Name + sLineBreak +
                  'Script = ' + ScriptOne.SQL;

  Assert.WillRaise(MigrationRunner.Execute, EMigrationException, ErrorMessage);
end;

procedure TestMigrationRunner.CommitScriptWhenMigrationIsApplied;
begin
  ScriptProducer.Setup.WillReturn(TValue.From(Scripts)).When.RetrieveScripts;
  DatabaseHandler.Setup.WillReturn(TValue.From(True)).When.IsApplied(ScriptOne);
  DatabaseHandler.Setup.WillReturn(TValue.From(False)).When.IsApplied(ScriptTwo);
  DatabaseHandler.Setup.Expect.Once.When.Commit;
  DatabaseHandler.Setup.Expect.Once.When.StartTransaction;

  MigrationRunner.Execute;

  DatabaseHandler.Verify('Execute should call Commit');
end;

procedure TestMigrationRunner.RollbackWhenMigrationFails;
begin
  ScriptProducer.Setup.WillReturn(TValue.From(Scripts)).When.RetrieveScripts;
  DatabaseHandler.Setup.WillReturn(TValue.From(True)).When.IsApplied(ScriptOne);
  DatabaseHandler.Setup.WillReturn(TValue.From(False)).When.IsApplied(ScriptTwo);
  DatabaseHandler.Setup.WillRaise(EDatabaseException).When.RunScript(ScriptTwo);
  DatabaseHandler.Setup.Expect.Once.When.Rollback;
  DatabaseHandler.Setup.Expect.Once.When.StartTransaction;

  Assert.WillRaise(MigrationRunner.Execute, EMigrationException);

  DatabaseHandler.Verify('Execute should call Rollback');
end;

procedure TestMigrationRunner.RunAllMigrationsThereWereNotApplied;
begin

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

procedure TestMigrationRunner.StoreMigrationAfterBeingApplied;
begin
  ScriptProducer.Setup.WillReturn(TValue.From(Scripts)).When.RetrieveScripts;
  DatabaseHandler.Setup.WillReturn(TValue.From(False)).When.IsApplied(ScriptOne);
  DatabaseHandler.Setup.WillReturn(TValue.From(False)).When.IsApplied(ScriptTwo);
  DatabaseHandler.Setup.Expect.Once.When.StoreMigration(ScriptOne);
  DatabaseHandler.Setup.Expect.Once.When.StoreMigration(ScriptTwo);


  MigrationRunner.Execute;

  DatabaseHandler.Verify('Execute should call StoreMigration');
end;

end.
