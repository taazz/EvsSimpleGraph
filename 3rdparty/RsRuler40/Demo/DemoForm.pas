unit DemoForm;

{$MODE Delphi}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  RsRuler, ExtCtrls, Buttons, ComCtrls, StdCtrls, Math{, ColorGrd};


const
  NumPaletteEntries = 20;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Panel4: TPanel;
    RsRulerCorner2: TRsRulerCorner;
    RsRulerCorner3: TRsRulerCorner;
    RsRuler2: TRsRuler;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton4: TSpeedButton;
    Label1: TLabel;
    TrackBar1: TTrackBar;
    PctBtn: TSpeedButton;
    SpeedButton5: TSpeedButton;
    SpeedButton6: TSpeedButton;
    SpeedButton7: TSpeedButton;
    Label2: TLabel;
    SpeedButton8: TSpeedButton;
    PosLabel: TLabel;
    Panel7: TPanel;
    FontBox: TComboBox;
    SizeBox: TComboBox;
    BoldBtn: TSpeedButton;
    ItalicBtn: TSpeedButton;
    ColorGrid1: TColorGrid;
    ColorSwitchBtn: TSpeedButton;
    Panel3: TPanel;
    RsRulerCorner1: TRsRulerCorner;
    RsRuler1: TRsRuler;
    RsRulerCorner4: TRsRulerCorner;
    Panel5: TPanel;
    RsRuler4: TRsRuler;
    Panel6: TPanel;
    RsRuler3: TRsRuler;
    LogoImage: TImage;
    HorTrack: TTrackBar;
    Label3: TLabel;
    Label4: TLabel;
    Bevel1: TBevel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Bevel2: TBevel;
    Label8: TLabel;
    VerTrack: TTrackBar;
    Label9: TLabel;
    SpeedButton9: TSpeedButton;
    SpeedButton10: TSpeedButton;
    Label10: TLabel;
    SpeedButton11: TSpeedButton;
    SpeedButton12: TSpeedButton;
    SpeedButton13: TSpeedButton;
    SpeedButton14: TSpeedButton;
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure SpeedButton4Click(Sender: TObject);
    procedure SpeedButton5Click(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure PctBtnClick(Sender: TObject);
    procedure LogoImageMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure SpeedButton6Click(Sender: TObject);
    procedure SpeedButton7Click(Sender: TObject);
    procedure SpeedButton8Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FontBoxChange(Sender: TObject);
    procedure SizeBoxChange(Sender: TObject);
    procedure BoldBtnClick(Sender: TObject);
    procedure ItalicBtnClick(Sender: TObject);
    procedure ColorGrid1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ColorSwitchBtnClick(Sender: TObject);
    procedure HorTrackChange(Sender: TObject);
    procedure VerTrackChange(Sender: TObject);
    procedure SpeedButton9Click(Sender: TObject);
    procedure SpeedButton10Click(Sender: TObject);
    procedure SpeedButton11Click(Sender: TObject);
    procedure SpeedButton12Click(Sender: TObject);
    procedure SpeedButton13Click(Sender: TObject);
    procedure SpeedButton14Click(Sender: TObject);
  private
    PaletteEntries: array[0..NumPaletteEntries - 1] of TPaletteEntry;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

procedure TForm1.SpeedButton1Click(Sender: TObject);
begin
  RsRulerCorner1.Flat := (Sender as TSpeedButton).Down;
  RsRulerCorner2.Flat := (Sender as TSpeedButton).Down;
  RsRulerCorner3.Flat := (Sender as TSpeedButton).Down;
  RsRulerCorner4.Flat := (Sender as TSpeedButton).Down;
  RsRuler1.Flat := (Sender as TSpeedButton).Down;
  RsRuler2.Flat := (Sender as TSpeedButton).Down;
  RsRuler3.Flat := (Sender as TSpeedButton).Down;
  RsRuler4.Flat := (Sender as TSpeedButton).Down;
end;

procedure TForm1.SpeedButton2Click(Sender: TObject);
begin
  RsRulerCorner1.Units := ruCenti;
  RsRuler1.Units := ruCenti;
  RsRuler2.Units := ruCenti;
  RsRuler3.Units := ruCenti;
  RsRuler4.Units := ruCenti;
end;

procedure TForm1.SpeedButton3Click(Sender: TObject);
begin
  RsRulerCorner1.Units := ruMilli;
  RsRuler1.Units := ruMilli;
  RsRuler2.Units := ruMilli;
  RsRuler3.Units := ruMilli;
  RsRuler4.Units := ruMilli;
end;

procedure TForm1.SpeedButton4Click(Sender: TObject);
begin
  RsRulerCorner1.Units := ruInch;
  RsRuler1.Units := ruInch;
  RsRuler2.Units := ruInch;
  RsRuler3.Units := ruInch;
  RsRuler4.Units := ruInch;
end;

procedure TForm1.SpeedButton5Click(Sender: TObject);
begin
  RsRuler1.HairLine := (Sender as TSpeedButton).Down;
  RsRuler2.HairLine := (Sender as TSpeedButton).Down;
  RsRuler3.HairLine := (Sender as TSpeedButton).Down;
  RsRuler4.HairLine := (Sender as TSpeedButton).Down;
  SpeedButton6.Visible := (Sender as TSpeedButton).Down;
  SpeedButton7.Visible := (Sender as TSpeedButton).Down;
end;

procedure TForm1.TrackBar1Change(Sender: TObject);
begin
  RsRuler1.Scale := (Sender as TTrackBar).Position;
  RsRuler2.Scale := (Sender as TTrackBar).Position;
  RsRuler3.Scale := (Sender as TTrackBar).Position;
  RsRuler4.Scale := (Sender as TTrackBar).Position;
  (Sender as TTrackBar).Hint := IntToStr((Sender as TTrackBar).Position) + '%';;
  PctBtn.Caption := IntToStr(RsRuler1.Scale) +'%';
  LogoImage.Width := Max(1, Round(200 * RsRuler1.Scale / 100));
  LogoImage.Height := Max(1, Round(133 * RsRuler1.Scale / 100));
end;

procedure TForm1.PctBtnClick(Sender: TObject);
begin
  TrackBar1.Position := 100;
end;

procedure TForm1.LogoImageMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  RsRuler1.HairLinePos := X;
  RsRuler2.HairLinePos := X;
  RsRuler3.HairLinePos := Y;
  RsRuler4.HairLinePos := Y;
  PosLabel.Caption := Format('(%.3g; %.3g)', [RsRuler1.Pos2Unit(X), RsRuler3.Pos2Unit(Y)]);
end;



procedure TForm1.SpeedButton6Click(Sender: TObject);
begin
  RsRuler1.HairLineStyle := hlsLine;
  RsRuler2.HairLineStyle := hlsLine;
  RsRuler3.HairLineStyle := hlsLine;
  RsRuler4.HairLineStyle := hlsLine;
end;

procedure TForm1.SpeedButton7Click(Sender: TObject);
begin
  RsRuler1.HairLineStyle := hlsRect;
  RsRuler2.HairLineStyle := hlsRect;
  RsRuler3.HairLineStyle := hlsRect;
  RsRuler4.HairLineStyle := hlsRect;
end;

procedure TForm1.SpeedButton8Click(Sender: TObject);
begin
  RsRulerCorner1.Units := ruPixel;
  RsRuler1.Units := ruPixel;
  RsRuler2.Units := ruPixel;
  RsRuler3.Units := ruPixel;
  RsRuler4.Units := ruPixel;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FontBox.Items.Assign(Screen.Fonts);
  GetPaletteEntries(GetStockObject(DEFAULT_PALETTE), 0, NumPaletteEntries, PaletteEntries);
end;

procedure TForm1.FormShow(Sender: TObject);
var
  i: Integer;
begin
  FontBox.ItemIndex := 0;
  for i := 0 to Pred(FontBox.Items.Count) do if FontBox.Items[i] = RsRuler1.Font.Name then FontBox.ItemIndex := i;

end;

procedure TForm1.FontBoxChange(Sender: TObject);
begin
  RsRuler1.Font.Name := FontBox.Items[FontBox.ItemIndex];
  RsRuler2.Font.Name := FontBox.Items[FontBox.ItemIndex];
  RsRuler3.Font.Name := FontBox.Items[FontBox.ItemIndex];
  RsRuler4.Font.Name := FontBox.Items[FontBox.ItemIndex];
  RsRulerCorner1.Font.Name := FontBox.Items[FontBox.ItemIndex];
  RsRulerCorner2.Font.Name := FontBox.Items[FontBox.ItemIndex];
  RsRulerCorner3.Font.Name := FontBox.Items[FontBox.ItemIndex];
  RsRulerCorner4.Font.Name := FontBox.Items[FontBox.ItemIndex];
end;

procedure TForm1.SizeBoxChange(Sender: TObject);
begin
  RsRuler1.Font.Size := StrToInt(SizeBox.Items[SizeBox.ItemIndex]);
  RsRuler2.Font.Size := StrToInt(SizeBox.Items[SizeBox.ItemIndex]);
  RsRuler3.Font.Size := StrToInt(SizeBox.Items[SizeBox.ItemIndex]);
  RsRuler4.Font.Size := StrToInt(SizeBox.Items[SizeBox.ItemIndex]);
  RsRulerCorner1.Font.Size := StrToInt(SizeBox.Items[SizeBox.ItemIndex]);
  RsRulerCorner2.Font.Size := StrToInt(SizeBox.Items[SizeBox.ItemIndex]);
  RsRulerCorner3.Font.Size := StrToInt(SizeBox.Items[SizeBox.ItemIndex]);
  RsRulerCorner4.Font.Size := StrToInt(SizeBox.Items[SizeBox.ItemIndex]);
end;

procedure TForm1.BoldBtnClick(Sender: TObject);
begin
  if BoldBtn.Down then
  begin
    RsRuler1.Font.Style := RsRuler1.Font.Style + [fsBold];
    RsRuler2.Font.Style := RsRuler2.Font.Style + [fsBold];
    RsRuler3.Font.Style := RsRuler3.Font.Style + [fsBold];
    RsRuler4.Font.Style := RsRuler4.Font.Style + [fsBold];
    RsRulerCorner1.Font.Style := RsRulerCorner1.Font.Style + [fsBold];
    RsRulerCorner2.Font.Style := RsRulerCorner2.Font.Style + [fsBold];
    RsRulerCorner3.Font.Style := RsRulerCorner3.Font.Style + [fsBold];
    RsRulerCorner4.Font.Style := RsRulerCorner4.Font.Style + [fsBold];
  end else
  begin
    RsRuler1.Font.Style := RsRuler1.Font.Style - [fsBold];
    RsRuler2.Font.Style := RsRuler2.Font.Style - [fsBold];
    RsRuler3.Font.Style := RsRuler3.Font.Style - [fsBold];
    RsRuler4.Font.Style := RsRuler4.Font.Style - [fsBold];
    RsRulerCorner1.Font.Style := RsRulerCorner1.Font.Style + [fsBold];
    RsRulerCorner2.Font.Style := RsRulerCorner2.Font.Style + [fsBold];
    RsRulerCorner3.Font.Style := RsRulerCorner3.Font.Style + [fsBold];
    RsRulerCorner4.Font.Style := RsRulerCorner4.Font.Style + [fsBold];
  end;
end;

procedure TForm1.ItalicBtnClick(Sender: TObject);
begin
  if ItalicBtn.Down then
  begin
    RsRuler1.Font.Style := RsRuler1.Font.Style + [fsItalic];
    RsRuler2.Font.Style := RsRuler2.Font.Style + [fsItalic];
    RsRuler3.Font.Style := RsRuler3.Font.Style + [fsItalic];
    RsRuler4.Font.Style := RsRuler4.Font.Style + [fsItalic];
    RsRulerCorner1.Font.Style := RsRulerCorner1.Font.Style + [fsItalic];
    RsRulerCorner2.Font.Style := RsRulerCorner2.Font.Style + [fsItalic];
    RsRulerCorner3.Font.Style := RsRulerCorner3.Font.Style + [fsItalic];
    RsRulerCorner4.Font.Style := RsRulerCorner4.Font.Style + [fsItalic];
  end else
  begin
    RsRuler1.Font.Style := RsRuler1.Font.Style - [fsItalic];
    RsRuler2.Font.Style := RsRuler2.Font.Style - [fsItalic];
    RsRuler3.Font.Style := RsRuler3.Font.Style - [fsItalic];
    RsRuler4.Font.Style := RsRuler4.Font.Style - [fsItalic];
    RsRulerCorner1.Font.Style := RsRulerCorner1.Font.Style - [fsItalic];
    RsRulerCorner2.Font.Style := RsRulerCorner2.Font.Style - [fsItalic];
    RsRulerCorner3.Font.Style := RsRulerCorner3.Font.Style - [fsItalic];
    RsRulerCorner4.Font.Style := RsRulerCorner4.Font.Style - [fsItalic];
  end;
end;

procedure TForm1.ColorGrid1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Idx: Integer;
begin
  if Button = mbLeft then
  begin
    Idx := ColorGrid1.ForegroundIndex;
    if Idx >= 8 then Inc(Idx, 4);
    with PaletteEntries[Idx] do
    begin
      if ColorSwitchBtn.Down then
      begin
        RsRuler1.TickColor := TColor(RGB(peRed, peGreen, peBlue));
        RsRuler2.TickColor := TColor(RGB(peRed, peGreen, peBlue));
        RsRuler3.TickColor := TColor(RGB(peRed, peGreen, peBlue));
        RsRuler4.TickColor := TColor(RGB(peRed, peGreen, peBlue));
        RsRulerCorner1.TickColor := TColor(RGB(peRed, peGreen, peBlue));
        RsRulerCorner2.TickColor := TColor(RGB(peRed, peGreen, peBlue));
        RsRulerCorner3.TickColor := TColor(RGB(peRed, peGreen, peBlue));
        RsRulerCorner4.TickColor := TColor(RGB(peRed, peGreen, peBlue));
      end else
      begin
        RsRuler1.Font.Color := TColor(RGB(peRed, peGreen, peBlue));
        RsRuler2.Font.Color := TColor(RGB(peRed, peGreen, peBlue));
        RsRuler3.Font.Color := TColor(RGB(peRed, peGreen, peBlue));
        RsRuler4.Font.Color := TColor(RGB(peRed, peGreen, peBlue));
        RsRulerCorner1.Font.Color := TColor(RGB(peRed, peGreen, peBlue));
        RsRulerCorner2.Font.Color := TColor(RGB(peRed, peGreen, peBlue));
        RsRulerCorner3.Font.Color := TColor(RGB(peRed, peGreen, peBlue));
        RsRulerCorner4.Font.Color := TColor(RGB(peRed, peGreen, peBlue));
      end;
    end;
  end;
  if Button = mbRight then
  begin
    Idx := ColorGrid1.BackgroundIndex;
    if Idx >= 8 then Inc(Idx, 4);
    with PaletteEntries[Idx] do
    begin
      if ColorSwitchBtn.Down then
      begin
        RsRuler1.Color := TColor(RGB(peRed, peGreen, peBlue));
        RsRuler2.Color := TColor(RGB(peRed, peGreen, peBlue));
        RsRuler3.Color := TColor(RGB(peRed, peGreen, peBlue));
        RsRuler4.Color := TColor(RGB(peRed, peGreen, peBlue));
        RsRulerCorner1.Color := TColor(RGB(peRed, peGreen, peBlue));
        RsRulerCorner2.Color := TColor(RGB(peRed, peGreen, peBlue));
        RsRulerCorner3.Color := TColor(RGB(peRed, peGreen, peBlue));
        RsRulerCorner4.Color := TColor(RGB(peRed, peGreen, peBlue));
      end else
      begin
        RsRuler1.ScaleColor := TColor(RGB(peRed, peGreen, peBlue));
        RsRuler2.ScaleColor := TColor(RGB(peRed, peGreen, peBlue));
        RsRuler3.ScaleColor := TColor(RGB(peRed, peGreen, peBlue));
        RsRuler4.ScaleColor := TColor(RGB(peRed, peGreen, peBlue));
        RsRulerCorner1.ScaleColor := TColor(RGB(peRed, peGreen, peBlue));
        RsRulerCorner2.ScaleColor := TColor(RGB(peRed, peGreen, peBlue));
        RsRulerCorner3.ScaleColor := TColor(RGB(peRed, peGreen, peBlue));
        RsRulerCorner4.ScaleColor := TColor(RGB(peRed, peGreen, peBlue));
      end;
    end;
  end;
end;

procedure TForm1.ColorSwitchBtnClick(Sender: TObject);
begin
  if ColorSwitchBtn.Down
  then ColorGrid1.Hint := 'FG = TickColor, BG = Color'
  else ColorGrid1.Hint := 'FG = Fontcolor, BG = ScaleColor';
end;

procedure TForm1.HorTrackChange(Sender: TObject);
begin
  RsRuler1.Offset := HorTrack.Position;
  RsRuler2.Offset := HorTrack.Position;
  SpeedButton9.Caption := IntToStr(HorTrack.Position);
end;

procedure TForm1.VerTrackChange(Sender: TObject);
begin
  RsRuler3.Offset := VerTrack.Position;
  RsRuler4.Offset := VerTrack.Position;
  SpeedButton10.Caption := IntToStr(VerTrack.Position);
end;

procedure TForm1.SpeedButton9Click(Sender: TObject);
begin
  HorTrack.Position := 0;
end;

procedure TForm1.SpeedButton10Click(Sender: TObject);
begin
  VerTrack.Position := 0;
end;

procedure TForm1.SpeedButton11Click(Sender: TObject);
begin
  RsRuler1.ShowMinus := (Sender as TSpeedButton).Down;
  RsRuler2.ShowMinus := (Sender as TSpeedButton).Down;
  RsRuler3.ShowMinus := (Sender as TSpeedButton).Down;
  RsRuler4.ShowMinus := (Sender as TSpeedButton).Down;
end;

procedure TForm1.SpeedButton12Click(Sender: TObject);
begin
  RsRulerCorner1.Units := ruMeter;
  RsRuler1.Units := ruMeter;
  RsRuler2.Units := ruMeter;
  RsRuler3.Units := ruMeter;
  RsRuler4.Units := ruMeter;
end;

procedure TForm1.SpeedButton13Click(Sender: TObject);
begin
  RsRulerCorner1.Units := ruKilo;
  RsRuler1.Units := ruKilo;
  RsRuler2.Units := ruKilo;
  RsRuler3.Units := ruKilo;
  RsRuler4.Units := ruKilo;
end;

procedure TForm1.SpeedButton14Click(Sender: TObject);
begin
  if RsRuler1.ScaleDir = rsdNormal then
  begin
    RsRuler1.ScaleDir := rsdReverse;
    RsRuler2.ScaleDir := rsdReverse;
    RsRuler3.ScaleDir := rsdReverse;
    RsRuler4.ScaleDir := rsdReverse;
  end else
  begin
    RsRuler1.ScaleDir := rsdNormal;
    RsRuler2.ScaleDir := rsdNormal;
    RsRuler3.ScaleDir := rsdNormal;
    RsRuler4.ScaleDir := rsdNormal;
  end;
end;

end.
