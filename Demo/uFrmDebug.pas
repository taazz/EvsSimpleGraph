unit uFrmDebug;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, SynEdit, Forms, Controls, Graphics, Dialogs,
  Grids, ExtCtrls;

type

  { TForm2 }

  TForm2 = class(TForm)
    Splitter1 : TSplitter;
    StringGrid1 : TStringGrid;
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
procedure Monitor(const Name:string; Value : string);overload;
procedure Monitor(const Name:string; Value : TRect);overload;
procedure Monitor(const Name:string; Value : TPoint);overload;
procedure Monitor(const Name:string; Value : integer);overload;

function dbgFrm : TForm2;


implementation
var
  Form2: TForm2;

{$R *.lfm}
procedure Monitor(const Name:string; Value : integer);overload;
begin
  Monitor(Name, IntToStr(Value));
end;

procedure Monitor(const Name:string; Value : string);overload;
var
  vCntr : Integer;
begin
  for vCntr := 0 to dbgFrm.StringGrid1.RowCount -1 do begin
    if CompareText(dbgFrm.StringGrid1.Cells[0,vCntr],Name) =0 then begin
      dbgFrm.StringGrid1.Cells[1, vCntr] := Value;
      Exit;
    end;
  end;
  if dbgFrm.StringGrid1.Cells[0,dbgFrm.StringGrid1.RowCount-1] <> '' then
     dbgFrm.StringGrid1.RowCount := dbgFrm.StringGrid1.RowCount + 1;
  dbgFrm.StringGrid1.Cells[0,dbgFrm.StringGrid1.RowCount-1] := Name;
  dbgFrm.StringGrid1.Cells[1,dbgFrm.StringGrid1.RowCount-1] := Value;
end;

procedure Monitor(const Name : string; Value : TRect);
begin
  Monitor(Name, Format('Top:%D, Left:%D, Bottom:%D, Right:%D',[Value.Top, Value.Left, Value.Bottom, Value.Right]));
end;

procedure Monitor(const Name : string; Value : TPoint);
begin
  Monitor(Name, Format('X:%D, Y:%D',[Value.X, Value.Y]));
end;

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

