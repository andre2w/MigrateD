unit DatabaseHandler;

interface

uses
  ScriptProducer;

type


  {$M+}
  IDatabaseHandler = interface
  ['{c66fcb04-0e5f-11ea-8d71-362b9e155667}']
    procedure RunScript(Script : TScript);
    function IsApplied(Script : TScript) : Boolean;
    procedure StoreMigration(Script : TScript);
  end;

implementation

end.
