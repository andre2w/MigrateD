unit TestHTTPClient;

interface

uses
  DUnitX.TestFramework, ScriptProducer.RestProducer;

type

  [TestFixture]
  TTestHTTPClient = class(TObject)
  private
    FHTTPClient : THTTPClient;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure RetrieveJsonFromAPI;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.JSON;

{ TTestHTTPClient }

procedure TTestHTTPClient.RetrieveJsonFromAPI;
var
  exp,Result: String;
  Expected : TStringList;
  ExpectedJson, ResultJson : TJSONArray;
begin

  Expected := TStringList.Create;
  with Expected do
  begin
    Add('[');
    Add('  {');
    Add('    "id": 15,');
    Add('    "name": "Adiciona Custo Boleto na conta corrente",');
    Add('    "script": "ALTER TABLE CONTA_CORRENTE\r\nADD CUSTO_BOLETO DECIMAL(10,2);",');
    Add('    "created_at": "2016-08-15T11:48:53.193Z"');
    Add('  },');
    Add('  {');
    Add('    "id": 16,');
    Add('    "name": "Adiciona COD_PESSOA_TITULAR na CONTA_CORRENTE",');
    Add('    "script": "ALTER TABLE CONTA_CORRENTE\r\nADD COD_PESSOA_TITULAR INTEGER;\r\n",');
    Add('    "created_at": "2016-08-15T11:49:17.974Z"');
    Add('  },');
    Add('  {');
    Add('    "id": 17,');
    Add('    "name": "FK COD_PESSOA_TITULAR",');
    Add('    "script": "alter table CONTA_CORRENTE\r\nadd constraint FK_CC_PESSOA_TITULAR\r\nforeign key (COD_PESSOA_TITULAR)\r\nreferences PESSOA(PES_CODIGO);\r\n",');
    Add('    "created_at": "2016-08-15T11:49:46.982Z"');
    Add('  }');
    Add(']');
  end;

  FHTTPClient.AddQueryParamter('api_token','asdf123');
  Result := FHTTPClient.ExecuteGetRequest;

  // Convert both to JsonObject and retrieve the value so the test will be less flaky
  // since we care that the content returned is the right one and it's parseable
  Assert.AreEqual(TJSONObject.ParseJSONValue(Expected.Text).Value,
                  TJSONObject.ParseJSONValue(Result).Value);
end;

procedure TTestHTTPClient.Setup;
begin
  FHTTPClient := THTTPClient.Create('http://10.0.75.1:8080/api/scripts');
end;

procedure TTestHTTPClient.TearDown;
begin
  FreeAndNil(FHTTPClient);
end;

end.
