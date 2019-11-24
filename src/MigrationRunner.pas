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

procedure TMigrationRunner.Execute;
var
  Scripts : TList<TScript>;
  Script: TObject;
  I: Integer;
  ErrorMessage : String;
begin

  Scripts := FScriptProducer.RetrieveScripts;

  for I := 0 to Scripts.Count - 1 do
  begin
    if FDatabaseHandler.IsApplied(Scripts.Items[I]) then
      Continue;

    try

      FDatabaseHandler.RunScript(Scripts.Items[I]);

    except
      on E : EDatabaseException do
      begin

        ErrorMessage := 'Failed to run migration for script:' + sLineBreak +
                        'Id = 1' + sLineBreak +
                        'Name = Create table' + sLineBreak +
                        'Script = CREATE TABLE' + sLineBreak;

        raise EMigrationException.Create(ErrorMessage);
      end;
    end;


  end;


end;

end.
