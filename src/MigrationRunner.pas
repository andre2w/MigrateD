unit MigrationRunner;

interface

uses
  System.Classes, System.Generics.Collections, ScriptProducer, DatabaseHandler,
  System.SysUtils;

type

  EMigrationException = class(Exception);

  TMigrationRunner = class(TObject)
  private
    FScriptProducer : IScriptProducer;
    FDatabaseHandler : IDatabaseHandler;
    procedure ApplyMigration(Script: TScript);
  public
    procedure Execute;
    constructor Create(ScriptProducer : IScriptProducer; DatabaseHandler : IDatabaseHandler); reintroduce; overload;
  end;

implementation

uses
  DatabaseException;

{ TMigrationRunner }

constructor TMigrationRunner.Create(ScriptProducer: IScriptProducer;
  DatabaseHandler: IDatabaseHandler);
begin
  FScriptProducer := ScriptProducer;
  FDatabaseHandler := DatabaseHandler;
end;

procedure TMigrationRunner.ApplyMigration(Script: TScript);
var
  ErrorMessage: string;
begin
  try

    with FDatabaseHandler do
    begin
      StartTransaction;

      RunScript(Script);
      StoreMigration(Script);

      Commit;
    end;

  except
    on E: EDatabaseException do
    begin
      FDatabaseHandler.Rollback;
      ErrorMessage := 'Failed to run migration for script:' + sLineBreak + 'Id = ' + IntToStr(Script.Id) + sLineBreak + 'Name = ' + Script.Name + sLineBreak + 'Script = CREATE TABLE' + Script.Script.Text + sLineBreak;
      raise EMigrationException.Create(ErrorMessage);
    end;
  end;
end;

procedure TMigrationRunner.Execute;
var
  Scripts : TList<TScript>;
  Script: TScript;
  I: Integer;
begin

  Scripts := FScriptProducer.RetrieveScripts;

  for Script in Scripts do
  begin
    if FDatabaseHandler.IsApplied(Script) then
      Continue;

    ApplyMigration(Script);
  end;

end;

end.
