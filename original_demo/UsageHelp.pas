unit UsageHelp;

{$MODE Delphi}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls;

type
  THelpOnActions = class(TForm)
    PageControl: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    RichEdit1: TMemo;
    RichEdit2: TMemo;
    btnClose: TButton;
  public
    class procedure Execute;
  end;

implementation

{$R *.lfm}

{ THelpOnActions }

class procedure THelpOnActions.Execute;
begin
  with Create(Application) do
    try
      RichEdit1.Lines.LoadFromFile(ExtractFilePath(Application.ExeName) + 'Keyboard.rtf');
      RichEdit2.Lines.LoadFromFile(ExtractFilePath(Application.ExeName) + 'Mouse.rtf');
      ShowModal;
    finally
      Free;
    end;
end;

end.
