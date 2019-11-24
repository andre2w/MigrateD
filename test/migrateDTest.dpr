program migrateDTest;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}{$STRONGLINKTYPES ON}
uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ENDIF }
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  TestMigrationRunnerUnit in 'TestMigrationRunnerUnit.pas',
  Delphi.Mocks.AutoMock in 'Delphi-Mocks\Delphi.Mocks.AutoMock.pas',
  Delphi.Mocks.Behavior in 'Delphi-Mocks\Delphi.Mocks.Behavior.pas',
  Delphi.Mocks.Expectation in 'Delphi-Mocks\Delphi.Mocks.Expectation.pas',
  Delphi.Mocks.Helpers in 'Delphi-Mocks\Delphi.Mocks.Helpers.pas',
  Delphi.Mocks.Interfaces in 'Delphi-Mocks\Delphi.Mocks.Interfaces.pas',
  Delphi.Mocks.MethodData in 'Delphi-Mocks\Delphi.Mocks.MethodData.pas',
  Delphi.Mocks.ObjectProxy in 'Delphi-Mocks\Delphi.Mocks.ObjectProxy.pas',
  Delphi.Mocks.ParamMatcher in 'Delphi-Mocks\Delphi.Mocks.ParamMatcher.pas',
  Delphi.Mocks in 'Delphi-Mocks\Delphi.Mocks.pas',
  Delphi.Mocks.Proxy in 'Delphi-Mocks\Delphi.Mocks.Proxy.pas',
  Delphi.Mocks.Proxy.TypeInfo in 'Delphi-Mocks\Delphi.Mocks.Proxy.TypeInfo.pas',
  Delphi.Mocks.ReturnTypePatch in 'Delphi-Mocks\Delphi.Mocks.ReturnTypePatch.pas',
  Delphi.Mocks.Utils in 'Delphi-Mocks\Delphi.Mocks.Utils.pas',
  Delphi.Mocks.Validation in 'Delphi-Mocks\Delphi.Mocks.Validation.pas',
  Delphi.Mocks.VirtualInterface in 'Delphi-Mocks\Delphi.Mocks.VirtualInterface.pas',
  Delphi.Mocks.VirtualMethodInterceptor in 'Delphi-Mocks\Delphi.Mocks.VirtualMethodInterceptor.pas',
  Delphi.Mocks.WeakReference in 'Delphi-Mocks\Delphi.Mocks.WeakReference.pas',
  Delphi.Mocks.When in 'Delphi-Mocks\Delphi.Mocks.When.pas',
  Sample1Main in 'Delphi-Mocks\Sample1Main.pas',
  MigrationRunner in '..\src\MigrationRunner.pas',
  ScriptProducer in '..\src\ScriptProducer.pas',
  DatabaseHandler in '..\src\DatabaseHandler.pas';

var
  runner : ITestRunner;
  results : IRunResults;
  logger : ITestLogger;
  nunitLogger : ITestLogger;
begin
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
  exit;
{$ENDIF}
  try
    //Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;
    //Create the test runner
    runner := TDUnitX.CreateRunner;
    //Tell the runner to use RTTI to find Fixtures
    runner.UseRTTI := True;
    //tell the runner how we will log things
    //Log to the console window
    logger := TDUnitXConsoleLogger.Create(true);
    runner.AddLogger(logger);
    //Generate an NUnit compatible XML File
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);
    runner.FailsOnNoAsserts := False; //When true, Assertions must be made during tests;

    //Run tests
    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    //We don't want this happening when running under CI.
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
end.
