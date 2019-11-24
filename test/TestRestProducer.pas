unit TestRestProducer;

interface

uses
   DUnitX.TestFramework, ScriptProducer, ScriptProducer.RestProducer,
  Delphi.Mocks;

type

  [TestFixture]
  TTestRestProducer = class(TObject)
  private
    FRestProducer : TRestProducer;
    FHTTPClient   : TMock<IHTTPClient>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure ShouldRetrieveAndParseScripts;
  end;
implementation

uses
  System.SysUtils, System.Rtti, System.Generics.Collections, System.Classes;

{ TTestRestProducer }

procedure TTestRestProducer.Setup;
begin
  FHTTPClient   := TMock<IHTTPClient>.Create;
  FRestProducer := TRestProducer.Create(FHTTPClient);
end;

procedure TTestRestProducer.ShouldRetrieveAndParseScripts;
var
  ResponseBody : String;
  Result, Scripts : TList<TScript>;
begin
  ResponseBody := '[{"id":15,"name":"Adiciona Custo Boleto na conta corrente","script":"ALTER TABLE CONTA_CORRENTE\r\nADD CUSTO_BOLETO DECIMAL(10,2);","created_at":"2016-08-15T11:48:53.193Z"}]';
  FHTTPClient.Setup.WillReturn(TValue.From(ResponseBody)).When.ExecuteGetRequest;

  Scripts := TList<TScript>.Create;
  Scripts.Add( TScript.Create );

  with Scripts.Items[0] do
  begin
    Id     := 15;
    Name   := 'Adiciona Custo Boleto na conta corrente';
    Script := TStringList.Create;
    Script.Add('ALTER TABLE CONTA_CORRENTE');
    Script.Add('ADD CUSTO_BOLETO DECIMAL(10,2);');
  end;

  Result := FRestProducer.RetrieveScripts;

  Assert.AreEqual(Scripts.Items[0].Id, Result.Items[0].Id);
  Assert.AreEqual(Scripts.Items[0].Name, Result.Items[0].Name);
  Assert.AreEqual(Scripts.Items[0].Script.Text, Result.Items[0].Script.Text);
end;

procedure TTestRestProducer.TearDown;
begin
  FreeAndNil(FRestProducer);
end;

end.
