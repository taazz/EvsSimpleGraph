unit SizeDlg;

{$MODE Delphi}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, UevsSimplegraph, StdCtrls, ExtCtrls;

type
  TSizeDialog = class(TForm)
    Horz: TRadioGroup;
    Vert: TRadioGroup;
    btnOK: TButton;
    btnCancel: TButton;
  public
    class function Execute(out HorzSize: TEvsResizeOption;
      out VertSize: TEvsResizeOption): Boolean;
  end;

implementation

{$R *.lfm}

class function TSizeDialog.Execute(out HorzSize: TEvsResizeOption;
  out VertSize: TEvsResizeOption): Boolean;
begin
  Result := False;
  with Create(Application) do
    try
      if ShowModal = mrOK then
      begin
        HorzSize := TEvsResizeOption(Horz.ItemIndex);
        VertSize := TEvsResizeOption(Vert.ItemIndex);
        Result := True;
      end;
    finally
      Free;
    end;
end;

end.
