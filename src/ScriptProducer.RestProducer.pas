unit ScriptProducer.RestProducer;

interface

uses
  ScriptProducer, System.Generics.Collections, REST.Client, System.JSON;

type

  {$M+}
  IHTTPClient = interface
    procedure AddQueryParamter(Key, Value : String);
    procedure AddHeader(Key, Value : String);
    function  ExecuteGetRequest : String;
  end;

  THTTPClient = class(TInterfacedObject, IHTTPClient)
  private
    FRestClient : TRESTClient;
    FRequest : TRESTRequest;
    FResponse: TRESTResponse;
  public
    constructor Create(const URL : string); reintroduce; overload;
    procedure AddQueryParamter(Key, Value : String);
    procedure AddHeader(Key, Value : String);
    function  ExecuteGetRequest : String;
    destructor  Destroy; override;
  end;


  TRestProducer = class(TInterfacedObject,IScriptProducer)
  private
    FHTTPClient : IHTTPClient;
  public
    constructor Create(const HTTPClient: IHTTPClient); reintroduce; overload;
    function RetrieveScripts: TList<TScript>;
  end;

implementation

uses
  REST.Types, System.SysUtils, System.Classes;

{ TRestProducer }

constructor TRestProducer.Create(const HTTPClient: IHTTPClient);
begin
  FHTTPClient := HTTPClient;
end;

function TRestProducer.RetrieveScripts: TList<TScript>;
var
  ScriptsPayload : string;
  JsonPayload: TJSONArray;
  I : Integer;
  Script : TScript;
  Scripts : TList<TScript>;
  JObj: TJSONObject;
  debug : string;
begin
  ScriptsPayload := FHTTPClient.ExecuteGetRequest;
  Scripts := TList<TScript>.Create;
  
  JsonPayload := TJSONArray(TJSONObject.ParseJSONValue(ScriptsPayload));
  
  for I := 0 to JsonPayload.Count - 1 do
  begin
    JObj := JsonPayload.Items[i] as TJSONObject;
    debug :=  JObj.ToString;  

    Script := TScript.Create;
    Script.Id := StrToInt(JObj.GetValue('id').Value);
    Script.Name := Copy( JObj.GetValue('name').Value,0,49);
    Script.Script := TStringList.Create;
    Script.Script.Text := JObj.GetValue('script').Value;
    Scripts.Add(Script);
  end;

  Result := Scripts;
end;

{ THTTPClient }

procedure THTTPClient.AddHeader(Key, Value: String);
begin
  FRestClient.SetHTTPHeader(Key, Value);
end;

procedure THTTPClient.AddQueryParamter(Key, Value: String);
begin
  FRestClient.AddParameter(Key, Value, pkGETorPOST);
end;

constructor THTTPClient.Create(const URL: string);
begin
  FRestClient := TRESTClient.Create(URL);

  FRequest          := TRESTRequest.Create(nil);
  FResponse         := TRESTResponse.Create(nil);
  FRequest.Client   := FRestClient;
  FRequest.Response := FResponse;
end;

destructor THTTPClient.Destroy;
begin
  FreeAndNil(FResponse);
  FreeAndNil(FRequest);
  FreeAndNil(FRestClient);
  inherited;
end;

function THTTPClient.ExecuteGetRequest: String;
begin
  FRequest.Execute;
  Result := FResponse.JSONText;
end;

end.
