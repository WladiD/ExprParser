program ExpressionTest;

uses
  Forms,
  Main in 'Main.pas' {MainForm},
  ExprParser in '..\..\ExprParser.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
