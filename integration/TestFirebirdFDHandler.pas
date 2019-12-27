unit TestFirebirdFDHandler;

interface

uses
  DUnitX.TestFramework, DatabaseHandler.FirebirdFDHandler, FireDAC.Comp.Client,
  FireDAC.Phys.FB, Data.DB;

type

  [TestFixture]
  TTestFirebirdFDHandler = class
  private
    FDBInfo : DatabaseInfo;
    FDatabase : TFDConnection;
    FQuery    : TFDQuery;
    FFBLink   : TFDPhysFBDriverLink;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure ShouldCreateScriptsTableWhenInstantiated;
    [Test]
    procedure ShouldStoreMigrationInScriptsTable;
    [Test]
    procedure ShouldRunMigrationWithSingleStatement;
    [Test]
    procedure ShouldRunMigrationWithMultipleStatements;
    [Test]
    procedure ShouldBeAbleToRollbackTransaction;
    [TearDown]
    procedure Teardown;
  end;

implementation

uses
  System.SysUtils, ScriptProducer, System.Classes;

{ TTestFirebirdFDHandler }

procedure TTestFirebirdFDHandler.Setup;
begin
  FDBInfo.Hostname := 'localhost';
  FDBInfo.Database := 'C:\Projects\Delphi\migrateD\TEST.FDB';
  FDBInfo.Username := 'SYSDBA';
  FDBInfo.Password := '6sge6';

  FFBLink := TFDPhysFBDriverLink.Create(nil);
  FFBLink.VendorLib := 'fbclient.dll';

  FDatabase := TFDConnection.Create(nil);
  FDatabase.Close;
  FDatabase.LoginPrompt := False;
  FDatabase.DriverName := 'FB';

  with FDatabase.Params do
  begin
    Clear;
    Add('Database=' + FDBInfo.Hostname + ':' + FDBInfo.Database);
    Add('DriverID=FB');
    Add('User_Name='+ FDBInfo.Username);
    Add('Password=' + FDBInfo.Password);
  end;

  FDatabase.Open;

  FQuery := TFDQuery.Create(nil);
  FQuery.Connection := FDatabase;
end;

procedure TTestFirebirdFDHandler.ShouldBeAbleToRollbackTransaction;
var
  DatabaseHandler : TFirebirdFDHandler;
  Script : TScript;
begin

  DatabaseHandler := TFirebirdFDHandler.Create(FDBInfo);

  Script := TScript.Create;
  Script.Id := 1;
  Script.Name := 'create test table';
  Script.Script := TStringList.Create;

  with Script.Script do
  begin
    Add('CREATE TABLE TEST_TABLE (  ');
    Add(' ID INTEGER                ');
    Add(');                         ');
  end;

  with DatabaseHandler do
  begin
    StartTransaction;
    RunScript(Script);
    Rollback;
  end;

  with FQuery, SQL do
  begin
    Clear;
    Close;
    Add('SELECT RDB$RELATION_NAME FROM RDB$RELATIONS  WHERE  RDB$RELATION_NAME = ''TEST_TABLE'' ;');
    Open;
  end;

  Assert.IsTrue(FQuery.IsEmpty,'TEST_TABLE table should not be present');
  FreeAndNil(DatabaseHandler);

end;

procedure TTestFirebirdFDHandler.ShouldCreateScriptsTableWhenInstantiated;
var
  DatabaseHandler : TFirebirdFDHandler;
begin

  DatabaseHandler := TFirebirdFDHandler.Create(FDBInfo);

  with FQuery, SQL do
  begin
    Clear;
    Close;
    Add('SELECT RDB$RELATION_NAME FROM RDB$RELATIONS  WHERE  RDB$RELATION_NAME = ''SCRIPTS'' ;');
    Open;
  end;

  Assert.IsFalse(FQuery.IsEmpty,'SCRIPT table should be present');
  FreeAndNil(DatabaseHandler);
end;

procedure TTestFirebirdFDHandler.ShouldRunMigrationWithMultipleStatements;
var
  DatabaseHandler : TFirebirdFDHandler;
  ScriptOne : TScript;
begin

  DatabaseHandler := TFirebirdFDHandler.Create(FDBInfo);

  ScriptOne := TScript.Create;
  ScriptOne.Id := 1;
  ScriptOne.Name := 'create test table';
  ScriptOne.Script := TStringList.Create;

  with ScriptOne.Script do
  begin
    Add('CREATE TABLE TEST_TABLE (  ');
    Add(' ID INTEGER                ');
    Add(');                         ');
    Add('');
    Add('CREATE TABLE OTHER_TEST_TABLE (  ');
    Add(' ID INTEGER                      ');
    Add(');                               ');
  end;

  DatabaseHandler.RunScript(ScriptOne);

  with FQuery, SQL do
  begin
    Clear;
    Close;
    Add('SELECT RDB$RELATION_NAME FROM RDB$RELATIONS');
    Add('WHERE RDB$RELATION_NAME in (''TEST_TABLE'',''OTHER_TEST_TABLE'') ;');
    Open;
  end;

  Assert.AreEqual(FQuery.RecordCount ,2);
  FreeAndNil(DatabaseHandler);

  with FQuery, SQL do
  begin
    Clear;
    Close;
    Add('DROP TABLE TEST_TABLE;');
    ExecSQL;
  end;

  with FQuery, SQL do
  begin
    Clear;
    Close;
    Add('DROP TABLE OTHER_TEST_TABLE;');
    ExecSQL;
  end;

end;

procedure TTestFirebirdFDHandler.ShouldRunMigrationWithSingleStatement;
var
  DatabaseHandler : TFirebirdFDHandler;
  Script : TScript;
begin

  DatabaseHandler := TFirebirdFDHandler.Create(FDBInfo);

  Script := TScript.Create;
  Script.Id := 1;
  Script.Name := 'create test table';
  Script.Script := TStringList.Create;

  with Script.Script do
  begin
    Add('CREATE TABLE TEST_TABLE (  ');
    Add(' ID INTEGER                ');
    Add(');                         ');
  end;

  DatabaseHandler.RunScript(Script);

  with FQuery, SQL do
  begin
    Clear;
    Close;
    Add('SELECT RDB$RELATION_NAME FROM RDB$RELATIONS WHERE RDB$RELATION_NAME = ''TEST_TABLE'' ;');
    Open;
  end;

  Assert.IsFalse(FQuery.IsEmpty,'TEST_TABLE table should be present');
  FreeAndNil(DatabaseHandler);

  with FQuery, SQL do
  begin
    Clear;
    Close;
    Add('DROP TABLE TEST_TABLE;');
    ExecSQL;
  end;
end;

procedure TTestFirebirdFDHandler.ShouldStoreMigrationInScriptsTable;
var
  DatabaseHandler : TFirebirdFDHandler;
  Script : TScript;
begin

  DatabaseHandler := TFirebirdFDHandler.Create(FDBInfo);

  Script := TScript.Create;
  Script.Id := 1;
  Script.Name := 'Create table';
  Script.Script := TStringList.Create;
  Script.Script.Add('CREATE TABLE');

  DatabaseHandler.StoreMigration(Script);

  with FQuery, SQL do
  begin
    Clear;
    Close;
    Add('SELECT * FROM SCRIPTS');
    Open;

    Assert.AreEqual(Script.Id, FieldByName('ID').AsInteger);
    Assert.AreEqual(Script.Name, FieldByName('Name').AsString);
  end;

  with FQuery, SQL do
  begin
    Clear;
    Close;
    Add('DELETE FROM SCRIPTS WHERE ID = 1');
    ExecSQL;
  end;
end;

procedure TTestFirebirdFDHandler.Teardown;
begin
  FDatabase.StartTransaction;

  with FQuery, SQL do
  begin
    Clear;
    Clear;
    Add('DROP TABLE SCRIPTS;');
    ExecSQL;
  end;

  FDatabase.Commit;

  FQuery.Close;
  FDatabase.Close;

  FreeAndNil(FQuery);
  FreeAndNil(FDatabase);
  FreeAndNil(FFBLink);
end;

end.
