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

procedure EvsDbgPrint(const aMsg  : string);overload;
procedure EvsDbgPrint(const aRect : TRect);overload;
procedure EvsDbgPrint(const aPt   : TPoint);overload;


function dbgFrm : TForm2;

var
  Form2: TForm2;

implementation

{$R *.lfm}

procedure EvsDbgPrint(const aRect : TRect);
begin
  EvsDbgPrint(Format('Top:%D, Left:%D, Bottom:%D, Right:%D',[aRect.Top, aRect.Left, aRect.Bottom, aRect.Right]));
end;

procedure EvsDbgPrint(const aPt : TPoint);
begin
  EvsDbgPrint(Format('X:%D, Y:%D',[aPt.X, aPt.Y]));
end;

function dbgFrm : TForm2;
begin
  if not Assigned(Form2) then Form2 := TForm2.Create(Application);
  Result := Form2;
end;

procedure EvsDbgPrint(const aMsg : string);
begin
  dbgFrm.SynEdit1.Lines.Add(aMsg);
  dbgFrm.SynEdit1.CaretY := dbgFrm.SynEdit1.Lines.Count-1;
end;

{ TForm2 }

procedure TForm2.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caHide;
end;
initialization
  Form2 := nil;

end.

