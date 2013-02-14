unit uFrmDebug;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, SynEdit, Forms, Controls, Graphics, Dialogs;

type

  { TForm2 }

  TForm2 = class(TForm)
    SynEdit1: TSynEdit;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
  private
    { private declarations }
  public
    { public declarations }
  end;

procedure EvsDbgPrint(const aMsg : string);

var
  Form2: TForm2;

implementation

{$R *.lfm}
function dbgFrm : TForm2;
begin
  if not Assigned(Form2) then Form2 := TForm2.Create(Application);
  Result := Form2;
end;

procedure EvsDbgPrint(const aMsg : string);
begin
  dbgFrm.SynEdit1.Lines.Add(aMsg);
end;

{ TForm2 }

procedure TForm2.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caHide;
end;
initialization
  Form2 := nil;

end.

