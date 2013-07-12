program SGDemo;

{$MODE Delphi}

uses
  Forms,
  Main in 'Main.pas' {MainForm},
  DesignProp in 'DesignProp.pas' {DesignerProperties},
  ObjectProp in 'ObjectProp.pas' {ObjectProperties},
  LinkProp in 'LinkProp.pas' {LinkProperties},
  NodeProp in 'NodeProp.pas' {NodeProperties},
  AboutDelphiArea in 'AboutDelphiArea.pas' {About},
  UsageHelp in 'UsageHelp.pas' {HelpOnActions},
  MarginsProp in 'MarginsProp.pas' {MarginDialog},
  AlignDlg in 'AlignDlg.pas' {AlignDialog},
  SizeDlg in 'SizeDlg.pas', Interfaces {SizeDialog};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Simple Graph Demo';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
