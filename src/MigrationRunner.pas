unit MigrationRunner;

interface

uses
  System.Classes, System.Generics.Collections, ScriptProducer, DatabaseHandler;

type

  TMigrationRunner = class(TObject)
  private
    FScriptProducer : IScriptProducer;
    FDatabaseHandler : IDatabaseHandler;
  public
    procedure Execute;
    constructor Create(ScriptProducer : IScriptProducer; DatabaseHandler : IDatabaseHandler); reintroduce; overload;
  end;

implementation

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
begin

  Scripts := FScriptProducer.RetrieveScripts;

  for I := 0 to Scripts.Count - 1 do
    FDatabaseHandler.RunScript(Scripts.Items[I]);


end;

end.
