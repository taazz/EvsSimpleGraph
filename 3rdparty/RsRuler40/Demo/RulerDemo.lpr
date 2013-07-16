program RulerDemo;

{$MODE Delphi}

uses
  Forms,
  DemoForm in 'DemoForm.pas', Interfaces {Form1};

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
