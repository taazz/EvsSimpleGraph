unit MarginsProp;

{$MODE Delphi}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls;

type
  TMarginDialog = class(TForm)
    btnOK: TButton;
    btnCancel: TButton;
    GroupBox1: TGroupBox;
    Edit1: TEdit;
    mLeft: TUpDown;
    Edit2: TEdit;
    mTop: TUpDown;
    Edit3: TEdit;
    mRight: TUpDown;
    Edit4: TEdit;
    mBottom: TUpDown;
  public
    class function Execute(var Margins: TRect): Boolean;
  end;

implementation

{$R *.lfm}

{ TMarginDialog }

class function TMarginDialog.Execute(var Margins: TRect): Boolean;
begin
  Result := True;
  with Create(Application) do
    try
      mLeft.Position := Margins.Left;
      mTop.Position := Margins.Top;
      mRight.Position := Margins.Right;
      mBottom.Position := Margins.Bottom;
      if ShowModal = mrOK then
      begin
        Margins.Left := mLeft.Position;
        Margins.Top := mTop.Position;
        Margins.Right := mRight.Position;
        Margins.Bottom := mBottom.Position;
        Result := True;
      end;
    finally
      Free;
    end;
end;

end.
