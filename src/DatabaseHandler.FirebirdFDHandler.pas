unit DatabaseHandler.FirebirdFDHandler;

interface

uses
  Data.DB, DatabaseHandler, ScriptProducer, FireDAC.Stan.Param,
  FireDAC.Comp.Client, FireDAC.Phys.FB, FireDAC.Comp.Script;

type

  DatabaseInfo = record
    Hostname: String;
    Database: string;
    Username: String;
    Password: String;
  end;

  TFirebirdFDHandler = class(TInterfacedObject, IDatabaseHandler)
  private
    FDatabase : TFDConnection;
    FQuery    : TFDQuery;
    FFBLink   : TFDPhysFBDriverLink;
    FScriptExecutor : TFDScript;
    procedure SetupConnection(DatabaseInfo: DatabaseInfo);
    procedure SetupScriptsTable;
  public
    procedure RunScript(Script : TScript);
    function IsApplied(Script : TScript) : Boolean;
    constructor Create(DatabaseInfo : DatabaseInfo); overload;
    procedure StoreMigration(Script : TScript);
    procedure Commit;
  end;

implementation

uses
  System.SysUtils, DatabaseException, FireDAC.Stan.Error;

{ TFirebirdFDHandler }

procedure TFirebirdFDHandler.Commit;
begin
  FDatabase.Commit;
end;

constructor TFirebirdFDHandler.Create(DatabaseInfo: DatabaseInfo);
begin
  SetupConnection(DatabaseInfo);
  SetupScriptsTable;
end;

function TFirebirdFDHandler.IsApplied(Script: TScript): Boolean;
begin
  with FQuery,SQL do
  begin
    Clear;
    Close;
    Add('SELECT ID FROM SCRIPTS WHERE ID = :ID ');
    ParamByName('ID').AsInteger := Script.Id;
    Open;
  end;

  Result := not FQuery.IsEmpty;
end;

procedure TFirebirdFDHandler.RunScript(Script: TScript);
begin

  try
    FScriptExecutor.ExecuteScript(Script.Script);
  except

    on E : EFDDBEngineException do
    begin
      raise EDatabaseException.Create(E.Message);
    end;

  end;

end;

procedure TFirebirdFDHandler.SetupConnection(DatabaseInfo: DatabaseInfo);
begin
  FFBLink := TFDPhysFBDriverLink.Create(nil);
  FFBLink.VendorLib := 'fbclient.dll';

  FDatabase := TFDConnection.Create(nil);
  FDatabase.Close;
  FDatabase.LoginPrompt := False;
  FDatabase.DriverName := 'FB';

  with FDatabase.Params do
  begin
    Clear;
    Add('Database=' + DatabaseInfo.Hostname + ':' + DatabaseInfo.Database);
    Add('DriverID=FB');
    Add('User_Name='+ DatabaseInfo.Username);
    Add('Password=' + DatabaseInfo.Password);
  end;

  FDatabase.Open;

  FQuery := TFDQuery.Create(nil);
  FQuery.Connection := FDatabase;

  FScriptExecutor := TFDScript.Create(nil);
  FScriptExecutor.Connection := FDatabase;
end;

procedure TFirebirdFDHandler.SetupScriptsTable;
begin
  with FQuery,SQL do
  begin
    Clear;
    Close;
    Add(' SELECT RDB$RELATION_NAME FROM RDB$RELATIONS ');
    Add(' WHERE  RDB$RELATION_NAME = ''SCRIPTS'' ; ');
    Open;
  end;

  if not FQuery.IsEmpty then
    Exit;

  if not FDatabase.InTransaction then
    FDatabase.StartTransaction;

  try

    with FQuery,SQL do
    begin
      Clear;
      Close;
      Add('CREATE TABLE SCRIPTS (        ');
      Add(' ID INTEGER,                  ');
      Add(' NOME VARCHAR(50),            ');
      Add(' DATAHORA_EXECUCAO TIMESTAMP  ');
      Add(');                            ');
      ExecSQL;
    end;

    FDatabase.Commit;

  except
    on E : Exception do
    begin
      FDatabase.Rollback;
      raise Exception.Create('Erro ao criar tabela de scripts' + #13 + 'Erro: ' + e.Message );
    end;
  end;


end;

procedure TFirebirdFDHandler.StoreMigration(Script: TScript);
begin
  with FQuery,SQL do
  begin
    Clear;
    Close;
    Add('INSERT INTO SCRIPTS (ID, NOME, DATAHORA_EXECUCAO) ');
    Add('VALUES (:ID, :NOME, :DATAHORA_EXECUCAO);');
    ParamByName('ID').AsInteger := Script.Id;
    ParamByName('NOME').AsString := Script.Name;
    ParamByName('DATAHORA_EXECUCAO').AsDateTime := Now;
    ExecSQL;
  end;
end;

end.
