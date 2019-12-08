unit ScriptProducer;

interface

uses
  System.Classes, System.Generics.Collections;

type

  TScript = class(TObject)
  public
    Id : Integer;
    Name : string;
    Script : TStrings;
    function SQL : string;
  end;

  {$M+}
  IScriptProducer = interface
    ['{c66fc884-0e5f-11ea-8d71-362b9e155667}']
    function RetrieveScripts: TList<TScript>;
  end;

implementation

{ TScript }

function TScript.SQL: string;
begin
  Script.Text;
end;

end.
