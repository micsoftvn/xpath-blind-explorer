program XPathBlindExplorer;

uses
  Forms,
  untMain in 'untMain.pas' {frmMain},
  IniFiles32 in 'IniFiles32.pas',
  untIniSettings in 'untIniSettings.pas',
  untVariables in 'untVariables.pas',
  untGenericProcedures in 'untGenericProcedures.pas',
  untLog in 'untLog.pas',
  untCURL in 'untCURL.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := '';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.

