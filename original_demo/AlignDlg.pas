unit AlignDlg;

{$MODE Delphi}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, UevsSimplegraph, StdCtrls, ExtCtrls;

type
  TAlignDialog = class(TForm)
    Horz: TRadioGroup;
    Vert: TRadioGroup;
    btnOK: TButton;
    btnCancel: TButton;
  public
    class function Execute(out HorzAlign: TEvsHAlignOption;
      out VertAlign: TEvsVAlignOption): Boolean;
  end;

implementation

{$R *.lfm}

class function TAlignDialog.Execute(out HorzAlign: TEvsHAlignOption;
  out VertAlign: TEvsVAlignOption): Boolean;
begin
  Result := False;
  with Create(Application) do
    try
      if ShowModal = mrOK then
      begin
        HorzAlign := TevsHAlignOption(Horz.ItemIndex);
        VertAlign := TevsVAlignOption(Vert.ItemIndex);
        Result := True;
      end;
    finally
      Free;
    end;
end;

end.
