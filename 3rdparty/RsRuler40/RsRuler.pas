unit RsRuler;

{$MODE Delphi}

//----------------------------------------------------------------------------
//  Delphi 2-7, C++Builder 5 Ruler component, version 4.0, 8 nov 2003
//----------------------------------------------------------------------------
//  (c) 2003 Hans Roos, Roos Software, The Netherlands
//  Website: www.RoosSoftware.nl
//  Email: mail@roossoftware.nl
//----------------------------------------------------------------------------
//  Features:
//  4 layouts rdTop, rdLeft, rdRight and rdBottom with
//    automatic scale adjustments for each layout
//  Scale: from 1-1000 %
//  Scale numbers can be reversed
//  Units: Inches, Centimetres, Millimetres, Pixels, Meters, Kilometers
//  Automatic calculation of scalenumbers (no overlapping)
//  Sideways text for vertical layouts
//  Flat or 3D appearance
//  TRsRulerCorner: extra component for joining up to 4
//    rulers, can show the unit ('km', 'm', 'cm', 'mm', 'in' or 'px')
//  Font can be changed; sideways fonts only possible if True Type font!
//----------------------------------------------------------------------------
//  See demo project for usage
//  Licence: Freeware! Use in non-commercial or commercial apps
//  Feel free to modify the source for your own needs, but don't remove
//  my name from this file, please.
//  If you find this component useful, please let me know.
//  Don't send money, just be grateful ;)
//----------------------------------------------------------------------------
//  Known issues: None
//  Not yet implemented:
//  Better scale divisions when Inches are used
//  (is it customary to divide inches in 4ths, 8ths, 16ths etc?)
//  Anything YOU can think of; please let me know!! (mail@roossoftware.nl)
//----------------------------------------------------------------------------
//  Revision History
//  v 4.0, 07/11/2003
//    Added property:
//    property ScaleDir: to specify reversed scale numbering. e.g. right-to-left
//    or bottom-to-top
//    property VersionInfo: quick reference to the version of these components
//    Added property values: ruKilo, ruMeter (property Units)
//    Bug-fix: Compiling gave Duplicate Resource errors. Fixed.
//  v.3.0, 07/11/2001
//    Added properties:
//    property Font, ParentFont: user can select any font for scale-drawing.
//    (vertical fonts can only be drawn if True Type font is chosen)
//    property Color, TickColor, Font.Color, ScaleColor
//    property Offset: if you want RsRuler to begin with another number than 0
//    Offset is recalculated when you choose another measuring unit.
//    property ShowMinus: if negative offset, toggle minus sign visibility
//  v.2.0, 31/10/2001
//    Added property value: ruPixel, for measuring pixel units.
//    Added public function Pos2Unit: to calculate unit from mouse position.
//    (see LogoImageMouseMove procedure in demo project for usage)
//  v.1.1, 30/06/2001
//    Added properties :
//    property HairLine, HairLinePos: line on scale, moving with CursorPos.
//    property HairLineStyle: hlsLine (just a hairline)
//      or hlsRect (inverted rectangle).
//  v.1.0, 22/11/2000
//    First release.
//----------------------------------------------------------------------------




interface

uses
  LCLIntf, LCLType, LMessages, SysUtils, Messages, Classes, Graphics, Controls, Forms, ExtCtrls;

const
  Kilo: String = 'km';
  Meter: String = 'm';
  Centi: String = 'cm';
  Milli: String = 'mm';
  Inch: String = 'in';
  Pixel: String = 'px';
  None: String = '';
  cVer: String = 'Version 4.0 (c) Roos Software 2003';

type
  TRulerDir = (rdTop, rdLeft, rdRight, rdBottom);
  TRulerScaleDir = (rsdNormal, rsdReverse);
  TRulerUnit = (ruKilo, ruMeter, ruCenti, ruMilli, ruInch, ruPixel, ruNone);
  TCornerPos = (cpLeftTop, cpRightTop, cpLeftBottom, cpRightBottom);
  THairLineStyle = (hlsLine, hlsRect);

  // base class, defines common properties and behaviour of its
  // descendants TRsRuler and TRsRulerCorner
  TRsBaseRuler = class(TGraphicControl)
  private
    fFlat: Boolean;
    fScaleColor: TColor;
    fTickColor: TColor;
    fUnits: TRulerUnit;
    fVersionInfo: String;
    procedure SetFlat(const Value: Boolean);
    procedure SetScaleColor(const Value: TColor);
    procedure SetTickColor(const Value: TColor);
  protected
    LeftSideLF, RightSideLF, NormLF: TLogFont;
    //OldFont, NormFont, LeftSideFont, RightSideFont: HFont;
    OldFont, NormFont, LeftSideFont, RightSideFont: TFont;
    FirstTime: Boolean;
    procedure Paint; override;
    procedure SetUnit(const Value: TRulerUnit); virtual;
    procedure FontChange(Sender: TObject);
    procedure ChangeFonts;
    procedure DeleteFonts;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Units: TRulerUnit read fUnits write SetUnit;
    property Flat: Boolean read fFlat write SetFlat;
    property ScaleColor: TColor read fScaleColor write SetScaleColor;
    property TickColor: TColor read fTickColor write SetTickColor;
    property VersionInfo: String read fVersionInfo write fVersionInfo;
  end;


  TRsRuler = class(TRsBaseRuler)
  private
    fDirection: TRulerDir;
    fScale: Integer;
    fScaleFactor: Double;
    fAdvance: Double;
    fHairLine: Boolean;
    fHairLinePos: Integer;
    fHairLineStyle: THairLineStyle;
    fOffset: Double;
    fShowMinus: Boolean;
    fScaleDir: TRulerScaleDir;
    procedure SetDirection(const Value: TRulerDir);
    procedure SetScaleDir(const Value: TRulerScaleDir);
    procedure SetScale(const Value: Integer);
    procedure SetHairLine(const Value: Boolean);
    procedure SetHairLinePos(const Value: Integer);
    procedure SetHairLineStyle(const Value: THairLineStyle);
    procedure SetOffset(const Value: Double);
    procedure SetShowMinus(const Value: Boolean);
  protected
    procedure SetUnit(const Value: TRulerUnit); override;
    procedure DrawHairLine;
    procedure CalcAdvance;
    procedure PaintScaleTics;
    procedure PaintScaleLabels;
    procedure Paint; override;
    function ConvertOffset(ToUnit: TRulerUnit): Double;
  public
    constructor Create(AOwner: TComponent); override;
    function Pos2Unit(APos: Integer): Double;
  published
    property VersionInfo;
    property Direction: TRulerDir read fDirection write SetDirection;
    property ScaleDir: TRulerScaleDir read fScaleDir write SetScaleDir;
    property Units;
    property Scale: Integer read fScale write SetScale;
    property HairLine: Boolean read fHairLine write SetHairLine;
    property HairLinePos: Integer read fHairLinePos write SetHairLinePos;
    property HairLineStyle: THairLineStyle read fHairLineStyle write SetHairLineStyle;
    property ScaleColor;
    property TickColor;
    property Offset: Double read fOffset write SetOffset;
    property ShowMinus: Boolean read fShowMinus write SetShowMinus;
    property Align;
    property Font;
    property Color;
    property Height;
    property Width;
    property Visible;
    property Hint;
    property ShowHint;
    property Tag;
    property ParentFont;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnClick;
    property OnDblClick;
    property OnResize;
  end;

  TRsRulerCorner = class(TRsBaseRuler)
  private
    fPosition: TCornerPos;
    procedure SetPosition(const Value: TCornerPos);
  protected
    fUStr: String;
    procedure Paint; override;
    procedure SetUnit(const Value: TRulerUnit); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property VersionInfo;
    property Align;
    property Position: TCornerPos read fPosition write SetPosition;
    property Flat;
    property ScaleColor;
    property TickColor;
    property Font;
    property Color;
    property Units;
    property Visible;
    property Hint;
    property ShowHint;
    property Tag;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnClick;
    property OnDblClick;
    property OnResize;
  end;

procedure Register;

implementation


procedure Register;
begin
  RegisterComponents('Xtra', [TRsRuler, TRsRulerCorner]);
end;

procedure InvertRect(aDC:HDC; aRect:TRect);
begin
  LCLIntf.BitBlt(aDC,aRect.Left,aRect.Top, aRect.Right-aRect.Left, aRect.Bottom - aRect.Top,
                 aDC,0,0, DSTINVERT);
end;

{ TRsBaseRuler }

constructor TRsBaseRuler.Create(AOwner: TComponent);
begin
  inherited;
  // Initialize vars:
  fFlat := False;
  fUnits := ruCenti;
  fScaleColor := clWindow;
  fTickColor := clWindowText;
  fVersionInfo := cVer;
  FirstTime := True;

  OldFont       := TFont.Create;
  NormFont      := TFont.Create;
  LeftSideFont  := TFont.Create;
  RightSideFont := TFont.Create;

  //OldFont := 0;
  //NormFont := 0;
  //LeftSideFont := 0;
  //RightSideFont := 0;
  Font.OnChange := FontChange;
end;

procedure TRsBaseRuler.ChangeFonts;
begin
  DeleteFonts;
  LeftSideFont := TFont.Create;
  with LeftSideFont do
  begin
    Orientation := 900;
    Name   := Font.Name;
    Height := -Font.Height;
    Style  := Font.Style;
    Color  := Font.Color;
  end;
  RightSideFont := Font.Create;
  with RightSideFont do
  begin
    Orientation := 2700;
    Name   := Font.Name;
    Height := -Font.Height;
    Style  := Font.Style;
    Color  := Font.Color;
    //FillChar(RightSideLF, SizeOf(RightSideLF), 0);
    //lfEscapement := 2700;
    //lfOrientation := 2700;
    //StrPCopy(lfFaceName, Font.Name);
    //lfHeight := -Font.Height;
    //lfWeight := FW_BOLD * Integer(fsBold in Font.Style);
    //lfItalic := Integer(fsItalic in Font.Style);
  end;
  NormFont := TFont.Create;
  with NormFont do
  begin
    //Orientation := 900;
    Name   := Font.Name;
    Height := -Font.Height;
    Style  := Font.Style;
    Color  := Font.Color;
    //FillChar(NormLF, SizeOf(NormLF), 0);
    //StrPCopy(lfFaceName, Font.Name);
    //lfHeight := -Font.Height;
    //lfWeight := FW_BOLD * Integer(fsBold in Font.Style);
    //lfItalic := Integer(fsItalic in Font.Style);
  end;
  Canvas.Font.Color := Font.Color;
  //LeftSideFont := CreateFontIndirect(LeftSideLF);
  //RightSideFont := CreateFontIndirect(RightSideLF);
  //NormFont := CreateFontIndirect(NormLF);
end;

procedure TRsBaseRuler.DeleteFonts;
begin
  //if NormFont <> 0 then DeleteObject(NormFont);
  //if LeftSideFont <> 0 then DeleteObject(LeftSideFont);
  //if RightSideFont <> 0 then DeleteObject(RightSideFont);
  //if Assigned(NormFont) then FreeAndNil(NormFont);
  //if Assigned(LeftSideFont) then FreeAndNil(LeftSideFont);
  //if Assigned(RightSideFont) then FreeAndNil(RightSideFont);
end;

destructor TRsBaseRuler.Destroy;
begin
  DeleteFonts;
  inherited;
end;

procedure TRsBaseRuler.FontChange(Sender: TObject);
begin
  ChangeFonts;
  Invalidate;
end;

procedure TRsBaseRuler.Paint;
begin
  Canvas.Brush.Color := Color;
  Canvas.FillRect(Rect(0, 0, Width, Height));
  if FirstTime then
  // setup fonts, cannot be done in Create method,
  // so do it when Ruler gets painted...
  begin
    FirstTime := False;
    ChangeFonts;
    OldFont.Assign(Canvas.Font);//.Handle;
  end;
end;

procedure TRsBaseRuler.SetFlat(const Value: Boolean);
begin
  if Value <> fFlat then
  begin
    fFlat := Value;
    Invalidate;
  end;
end;

procedure TRsBaseRuler.SetScaleColor(const Value: TColor);
begin
  if Value <> fScaleColor then
  begin
    fScaleColor := Value;
    Invalidate;
  end;
end;

procedure TRsBaseRuler.SetTickColor(const Value: TColor);
begin
  if Value <> fTickColor then
  begin
    fTickColor := Value;
    Invalidate;
  end;
end;

procedure TRsBaseRuler.SetUnit(const Value: TRulerUnit);
begin
  // method is empty, see descendants
end;


{ TRsRuler }
constructor TRsRuler.Create(AOwner: TComponent);
begin
  inherited;
  fDirection := rdTop;
  fScaleDir := rsdNormal;
  fScale := 100;
  Height := 33;
  Width := 200;
  fScaleFactor := 1;
  fAdvance := 1;
  fOffset := 0.0;
  fHairLinePos := -1;
  fHairLine := False;
  fHairLineStyle := hlsLine;
  fShowMinus := True;
end;

procedure TRsRuler.CalcAdvance;
begin
  fAdvance := Screen.PixelsPerInch / 10 * fScale / 100;
  if fUnits <> ruInch then fAdvance := fAdvance / 2.54;
  if fUnits = ruPixel then fAdvance := 5 * fScale / 100;
  case fScale of
    1: fScaleFactor := 100;
    2: fScaleFactor := 50;
    3..5: fScaleFactor := 25;
    6..8: fScaleFactor := 20;
    9..12: fScaleFactor := 10;
    13..25: fScaleFactor := 5;
    26..35: fScaleFactor := 4;
    36..50: fScaleFactor := 2;
    51..125: fScaleFactor := 1;
    126..300: fScaleFactor :=  0.5;
    301..400: fScaleFactor := 0.25;
    401..500: fScaleFactor := 0.2;
    501..1000: fScaleFactor := 0.1;
  end;
  fAdvance := fAdvance * fScaleFactor;
end;

procedure TRsRuler.PaintScaleTics;
var
  Pos: Double;
  Start, N, Last, LongTick, Adv: Integer;
begin
  if (fDirection = rdTop) or (fDirection = rdBottom) then Last := Width else Last := Height;
  Start := 0;
  Adv := 1;
  if fScaleDir = rsdReverse then
  begin
    Start := Last;
    Adv := -1;
  end;
  Pos := 0;
  N := 0;
  Canvas.Pen.Color := fTickColor;
  while Pos < Last do with Canvas do
  begin
    LongTick := 2 * (3 + Integer(N mod 5 = 0));
    if (fDirection = rdTop) or (fDirection = rdBottom) then
    begin
      if fDirection = rdTop then
      begin
        MoveTo(Start + Adv * Trunc(Pos), Height - 1);
        LineTo(Start + Adv * Trunc(Pos), Height - LongTick);
      end;
      if fDirection = rdBottom then
      begin
        MoveTo(Start + Adv * Trunc(Pos), 0);
        LineTo(Start + Adv * Trunc(Pos), LongTick - 1);
      end;
    end else
    begin
      if fDirection = rdLeft then
      begin
        MoveTo(Width - 1, Start + Adv * Trunc(Pos));
        LineTo(Width - LongTick, Start + Adv * Trunc(Pos));
      end;
      if fDirection = rdRight then
      begin
        MoveTo(0, Start + Adv * Trunc(Pos));
        LineTo(LongTick - 1, Start + Adv * Trunc(Pos));
      end;
    end;
    Inc(N);
    Pos := Pos + 2 * fAdvance; // always advance two units to next ticmark
  end;
end;

procedure TRsRuler.PaintScaleLabels;
var
  Pos, Number, ScaleN: Double;
  Start, N, Last, Wi, He, Center, Adv: Integer;
  S: String;
begin
  if (fDirection = rdTop) or (fDirection = rdBottom) then Last := Width else Last := Height;
  Start := 0;
  Adv := 1;
  if fScaleDir = rsdReverse then
  begin
    Start := Last;
    Adv := -1;
  end;
  Pos := 0;
  N := 0;
  Canvas.Pen.Color := Font.Color;
  while Pos < Last do with Canvas do
  begin
    Number := fScaleFactor * N / 10;
    if Units = ruMilli then Number := 10 * Number;
    if Units = ruMeter then Number := Number / 100;
    if Units = ruKilo then Number := Number / 100000;
    if Units = ruPixel then Number := 50 * Number;
    ScaleN := Number + fOffset;
    if fUnits = ruPixel then ScaleN := Round(ScaleN);
    if fUnits = ruInch then ScaleN := Round(100 * ScaleN) / 100;
    if fShowMinus then S := FormatFloat('0.##', ScaleN) else S := FormatFloat('0.##', Abs(ScaleN));
    Wi := TextWidth(S);
    He := TextHeight(S);
    if (fDirection = rdTop) or (fDirection = rdBottom) then
    begin
      MoveTo(Start + Adv * Trunc(Pos), 1);  // only Pos is important
      if fDirection = rdTop then
      begin
        // draw number..
        if (N <> 0) and (N mod 10 = 0) then TextOut(PenPos.X - Wi div 2, Height - He - 8, S)
        else if (N <> 0) and (N mod 5 = 0) then
        begin
          // or just a notch
          Center := Height + (-(He + 6) - 8) div 2;
          MoveTo(Start + Adv * Trunc(Pos), Center - 1);
          LineTo(Start + Adv * Trunc(Pos), Center + 2);
        end;
      end;
      if fDirection = rdBottom then
      begin
        // draw number..
        if (N <> 0) and (N mod 10 = 0) then TextOut(PenPos.X - Wi div 2, 8, S)
        else if (N <> 0) and (N mod 5 = 0) then
        begin
          // or just a notch
          Center := ((He + 6) + 8) div 2;
          MoveTo(Start + Adv * Trunc(Pos), Center - 2);
          LineTo(Start + Adv * Trunc(Pos), Center + 1);
        end;
      end;
    end else
    begin
      MoveTo(1, Start + Adv * Trunc(Pos));
      if fDirection = rdLeft then
      begin
        // draw number..
        if (N <> 0) and (N mod 10 = 0) then TextOut(Width - He - 7, PenPos.Y + Wi div 2, S)
        else if (N <> 0) and (N mod 5 = 0) then
        begin
          // or just a notch
          Center := Width + (-(He + 6) - 8) div 2;
          MoveTo(Center - 1, Start + Adv * Trunc(Pos));
          LineTo(Center + 2, Start + Adv * Trunc(Pos));
        end;
      end;
      if fDirection = rdRight then
      begin
        if (N <> 0) and (N mod 10 = 0) then TextOut(He + 7, PenPos.Y - Wi div 2, S)
        else if (N <> 0) and (N mod 5 = 0) then
        begin
          // or just a notch
          Center := ((He + 6) + 8) div 2;
          MoveTo(Center - 2, Start + Adv * Trunc(Pos));
          LineTo(Center + 1, Start + Adv * Trunc(Pos));
        end;
      end;
    end;
    Inc(N);
    Pos := Pos + fAdvance;
  end;
end;

procedure TRsRuler.Paint;
var
  Rect: TRect;
  He, d: Integer;
begin
  inherited;
  fHairLinePos := -1;
  Rect := ClientRect;
  if Not Flat then DrawEdge(Canvas.Handle, Rect, EDGE_RAISED, BF_RECT);
  d := 2 - Integer(Flat);
  //SelectObject(Canvas.Handle, NormFont);
  OldFont.Assign(Canvas.Font);
  Canvas.Font := NormFont;
  He := Canvas.TextHeight('0') + 6;
  if (fDirection = rdTop) or (fDirection = rdBottom) then
  begin
    if fDirection = rdTop then SetRect(Rect, d, Height - He - 1, Width - d, Height - 8);
    if (fDirection = rdBottom) then SetRect(Rect, d, 8, Width - d, He + 1);
    //SelectObject(Canvas.Handle, NormFont);
    Canvas.Font := NormFont;
  end else
  begin
    if fDirection = rdLeft then
    begin
      SetRect(Rect, Width - He, d, Width - 8, Height - d);
      //SelectObject(Canvas.Handle, LeftSideFont);
      Canvas.Font := LeftSideFont;
    end;
    if fDirection = rdRight then
    begin
      SetRect(Rect, He, d, 8, Height - d);
      //SelectObject(Canvas.Handle, RightSideFont);
      Canvas.Font := RightSideFont;
    end;
  end;
  Canvas.Brush.Color := fScaleColor;
  Canvas.FillRect(Rect);
  CalcAdvance;
  SetBKMode(Canvas.Handle, TRANSPARENT);
  PaintScaleTics;
  PaintScaleLabels;
  SetBKMode(Canvas.Handle, OPAQUE);
  //SelectObject(Canvas.Handle, OldFont);
  Canvas.Font := OldFont;
end;

procedure TRsRuler.SetDirection(const Value: TRulerDir);
var
  Dim: TPoint;
  OldDir: TRulerDir;
begin
  OldDir := fDirection;
  if Value <> fDirection then
  begin
    if ((OldDir = rdTop) or (OldDir = rdBottom)) and ((Value = rdLeft) or (Value = rdRight))
    or ((OldDir = rdLeft) or (OldDir = rdRight)) and ((Value = rdTop) or (Value = rdBottom)) then
    begin
      Dim := Point(Width, Height);
      Width := Dim.Y;
      Height := Dim.X;
    end;
    fDirection := Value;
    Invalidate;
  end;
end;

procedure TRsRuler.SetScaleDir(const Value: TRulerScaleDir);
begin
  if (Value <> fScaleDir) then
  begin
    fScaleDir := Value;
    Invalidate;
  end;
end;

procedure TRsRuler.SetScale(const Value: Integer);
begin
  if (Value <> fScale) and (Value > 0) then
  begin
    fScale := Value;
    Invalidate;
  end;
end;

procedure TRsRuler.SetUnit(const Value: TRulerUnit);
begin
  if Value <> fUnits then
  begin
    fOffSet := ConvertOffset(Value);
    fUnits := Value;
    Invalidate;
  end;
end;


procedure TRsRuler.SetHairLine(const Value: Boolean);
begin
  if Value <> fHairLine then
  begin
    fHairLine := Value;
    Invalidate;
  end;
end;

procedure TRsRuler.SetHairLinePos(const Value: Integer);
begin
  if Value <> fHairLinePos then
  begin
    DrawHairLine; // erase old position
    fHairLinePos := Value;
    DrawHairLine; // draw new position
  end;
end;

procedure TRsRuler.DrawHairLine;
var
  He: Integer;
begin
  if fHairLine then if fHairLinePos <> -1 then with Canvas do
  begin
    Pen.Mode := pmNotXOr;
    //SelectObject(Canvas.Handle, NormFont);
    Canvas.Font := NormFont;
    He := TextHeight('0') + 6;
    //SelectObject(Canvas.Handle, OldFont);
    Canvas.Font := OldFont;
    if fDirection = rdTop then
    begin
      if fHairLineStyle = hlsLine
      then InvertRect(Canvas.Handle, Rect(fHairLinePos - 1, Height - He - 1, fHairLinePos, Height - 8))
      else
      if fScaleDir = rsdNormal then InvertRect(Canvas.Handle, Rect(1, Height - He - 1, fHairLinePos, Height - 8))
      else InvertRect(Canvas.Handle, Rect(Width, Height - He - 1, fHairLinePos, Height - 8));
    end;
    if fDirection = rdBottom then
    begin
      if fHairLineStyle = hlsLine
      then InvertRect(Canvas.Handle, Rect(fHairLinePos - 1, 8, fHairLinePos, He))
      else
      if fScaleDir = rsdNormal
      then InvertRect(Canvas.Handle, Rect(1, 8, fHairLinePos, He + 1))
      else InvertRect(Canvas.Handle, Rect(Width, 8, fHairLinePos, He + 1));
    end;
    if fDirection = rdLeft then
    begin
      if fHairLineStyle = hlsLine
      then InvertRect(Canvas.Handle, Rect(Width - He, fHairLinePos - 1, Width - 8, fHairLinePos))
      else
      if fScaleDir = rsdNormal then InvertRect(Canvas.Handle, Rect(Width - He, 1, Width - 8, fHairLinePos))
      else InvertRect(Canvas.Handle, Rect(Width - He, Height, Width - 8, fHairLinePos));
    end;
    if fDirection = rdRight then
    begin
      if fHairLineStyle = hlsLine
      then InvertRect(Canvas.Handle, Rect(8, fHairLinePos - 1, He, fHairLinePos))
      else
      if fScaleDir = rsdNormal then InvertRect(Canvas.Handle, Rect(8, 1, He, fHairLinePos))
      else InvertRect(Canvas.Handle, Rect(8, Height, He, fHairLinePos));
    end;
    Pen.Mode := pmCopy;
  end;
end;

procedure TRsRuler.SetHairLineStyle(const Value: THairLineStyle);
begin
  if Value <> fHairLineStyle then
  begin
    fHairLineStyle := Value;
    Invalidate;
  end;
end;

function TRsRuler.Pos2Unit(APos: Integer): Double;
var
  ThePos, EndPos: Integer;
begin
  ThePos := APos;
  if (fDirection = rdTop) or (fDirection = rdBottom) then EndPos := Width else EndPos := Height;
  if fScaleDir = rsdReverse then ThePos := EndPos - APos;
  Result := fOffset;
  if fUnits = ruPixel then Result := Trunc(Result) + Trunc(ThePos / Scale * 100); // zero-based counting of pixels
  if fUnits = ruInch  then Result := Result + ThePos / Scale * 100 / Screen.PixelsPerInch;
  if fUnits = ruCenti then Result := Result + ThePos / Scale * 100 / Screen.PixelsPerInch * 2.54;
  if fUnits = ruMilli then Result := Result + ThePos / Scale * 100 / Screen.PixelsPerInch * 25.4;
  if fUnits = ruMeter then Result := Result + ThePos / Scale * 100 / Screen.PixelsPerInch * 0.0254;
  if fUnits = ruMeter then Result := Result + ThePos / Scale * 100 / Screen.PixelsPerInch * 0.0000254;
end;

procedure TRsRuler.SetOffset(const Value: Double);
begin
  if Value <> fOffset then
  begin
    fOffset := Value;
    Invalidate;
  end;
end;

procedure TRsRuler.SetShowMinus(const Value: Boolean);
begin
  if Value <> fShowMinus then
  begin
    fShowMinus := Value;
    Invalidate;
  end;
end;

function TRsRuler.ConvertOffset(ToUnit: TRulerUnit): Double;
var
  DivFactor, MulFactor: Double;
begin
  DivFactor := 1; // std: ruMilli
  if (fUnits = ruCenti) then DivFactor := 0.1;
  if (fUnits = ruMeter) then DivFactor := 0.001;
  if (fUnits = ruKilo) then DivFactor := 0.000001;
  if (fUnits = ruInch) then DivFactor := 1 / 25.4;
  if (fUnits = ruPixel) then DivFactor := Screen.PixelsPerInch / 25.4;
  MulFactor := 1;
  if (ToUnit = ruCenti) then MulFactor := 0.1;
  if (ToUnit = ruMeter) then MulFactor := 0.001;
  if (ToUnit = ruKilo) then MulFactor := 0.000001;
  if (ToUnit = ruMilli) then MulFactor := 1;
  if (ToUnit = ruInch) then MulFactor := 1 / 25.4;
  if (ToUnit = ruPixel) then MulFactor := Screen.PixelsPerInch / 25.4;
  Result := fOffset / DivFactor * MulFactor;
end;

{ TRsRulerCorner }

constructor TRsRulerCorner.Create(AOwner: TComponent);
begin
  inherited;
  fPosition := cpLeftTop;
  fUStr := Centi;
  Width := 24;
  Height := 24;
  Hint := 'centimeter';
end;

procedure TRsRulerCorner.Paint;
var
  Wi, He, d: Integer;
  W,H     : Integer;
  R: TRect;
begin
  inherited;
  R := ClientRect;
  OldFont.Assign(Canvas.Font);
  Canvas.Font := NormFont;
  //SelectObject(Canvas.Handle, NormFont);
  W := Width;
  H := Height;
  with Canvas do
  begin
    if Not Flat then DrawEdge(Handle, R, EDGE_RAISED, BF_RECT);
    Brush.Color := fScaleColor;
    Brush.Style := bsSolid;
    He := TextHeight('0') + 6;
    //SetBKMode(Handle, TRANSPARENT);
    Canvas.Font.Color := Font.Color;
    Wi := TextWidth(fUStr);
    d := 2 - Integer(Flat);
    if fPosition = cpLeftTop then
    begin
      Canvas.Rectangle(W - He, H - He - 1, W - d, H - 8);
      FillRect(W - He, H - He, W - 8, H - d);
      TextOut(W - He + 1 + (He - 2 - Wi) div 2, H - He - 1, fUStr);
    end;
    if fPosition = cpRightTop then
    begin
      FillRect(Rect(d, H - He - 1, He, H - 8));
      FillRect(Rect(8, H - He, He, H - d));
      TextOut(2 + (He - Wi) div 2, H - He, fUStr);
    end;
    if fPosition = cpLeftBottom then
    begin
      FillRect(Rect(W - He, 8, W - d, He + 1));
      FillRect(Rect(W - He, d, W - 8, He));
      TextOut(W - He + 1 + (He - 2 - Wi) div 2, 8, fUStr);
    end;
    if fPosition = cpRightBottom then
    begin
      FillRect(Rect(d, 8, He, He + 1));
      FillRect(Rect(8, d, He, He));
      TextOut(2 + (He - Wi) div 2, 8, fUStr);
    end;
  end;
  //SetBKMode(Canvas.Handle, OPAQUE);
  //SelectObject(Canvas.Handle, OldFont);
  Canvas.Font := OldFont;
end;



procedure TRsRulerCorner.SetPosition(const Value: TCornerPos);
begin
  if Value <> fPosition then
  begin
    fPosition := Value;
    Invalidate;
  end;
end;

procedure TRsRulerCorner.SetUnit(const Value: TRulerUnit);
begin
  if Value <> fUnits then
  begin
    fUnits := Value;
    if fUnits = ruKilo then begin fUStr := Kilo; Hint := 'kilometer'; end;
    if fUnits = ruMeter then begin fUStr := Meter; Hint := 'meter'; end;
    if fUnits = ruCenti then begin fUStr := Centi; Hint := 'centimeter'; end;
    if fUnits = ruMilli then begin fUStr := Milli; Hint := 'millimeter'; end;
    if fUnits = ruInch then begin fUStr := Inch; Hint := 'inch'; end;
    if fUnits = ruPixel then begin fUStr := Pixel; Hint := 'pixel'; end;
    if fUnits = ruNone then begin fUStr := None; Hint := ''; end;
    Invalidate;
  end;
end;



end.
