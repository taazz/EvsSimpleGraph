{ *******************************************************************************
  Author      : Roy Magne Klever (rmklever@gmail.com)
  Created     : September 26 2010 (Delphi 2010)
  Version     : 1.7
  Components  : TVistaProBar

  License     : Freeware

  Updated June 18 2011 added orientation property, vertical rendering added
  Updated October 2011 added some color properties and changed rendering a little

  ******************************************************************************* }

unit rkVistaProBar;

interface
{$MODE Delphi}
uses
  {Windows, Messages,} LCLIntf, LCLType, types, LMessages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, Math, uevscolorutils;

type
  TVPBOrientation = (vpbHorizontal, vpbVertical);

  { TVistaProBar }

  TVistaProBar = class(TGraphicControl)
  private
    { Private declarations }
    FTimer        : TTimer;
    FAltMode      : Boolean;
    FBackColor    : TColor;
    FBorderColor  : TColor;
    FCornerColor  : TColor;
    FMax          : Integer;
    FMin          : Integer;
    FMarquee      : Boolean;
    FMarqueeP     : Integer;
    FMarqueeSize  : Byte;
    FMarqueeFade  : Byte;
    FMarqueeSpeed : Byte;
    FOrientation  : TVPBOrientation;
    FPercentage   : Boolean;
    FPosition     : Integer;
    FPosTextPrefix: String;
    FPosTextSuffix: String;
    FShowPosText: Boolean;
    procedure SetMax           (const Value: integer);
    procedure SetMin           (const Value: integer);
    procedure SetPercentage    (const Value: boolean);
    procedure SetPosition      (const Value: integer);
    procedure SetPosTextPrefix (const Value: string);
    procedure SetPosTextSuffix (const Value: string);
    procedure SetShowPosText   (const Value: boolean);
    procedure CMFontChanged    (var Message: TLMessage); message CM_FontChanged;
    procedure SetAltMode       (const Value: boolean);
    procedure MarqueeOnTimer   (Sender: TObject);
    procedure SetMarquee       (const Value: boolean);
    procedure SetMarqueeSize   (const Value: Byte);
    procedure SetMarqueeFade   (const Value: Byte);
    procedure SetMarqueeSpeed  (const Value: Byte);
    procedure SetOrientation   (const Value: TVPBOrientation);
    procedure SetBackColor     (const Value: TColor);
    procedure SetBorderColor   (const Value: TColor);
    procedure SetCornerColor   (const Value: TColor);
  protected
    { Protected declarations }
    procedure Paint; override;
    procedure Resize; override;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AddPosition(APos: integer);
    procedure Draw(Canvas: TCanvas; x, y, Pos: integer);
  published
    { Published declarations }
    property AltMode       : boolean         read FAltMode       write SetAltMode;
    property BackColor     : TColor          read FBackColor     write SetBackColor      default clBtnFace;
    property BorderColor   : TColor          read FBorderColor   write SetBorderColor    default clSilver;
    property CornerColor   : TColor          read FCornerColor   write SetCornerColor    default clBtnFace;
    property Marquee       : boolean         read FMarquee       write SetMarquee        default False;
    property MarqueeSize   : Byte            read FMarqueeSize   write SetMarqueeSize;
    property MarqueeFade   : Byte            read FMarqueeFade   write SetMarqueeFade;
    property MarqueeSpeed  : Byte            read FMarqueeSpeed  write SetMarqueeSpeed;
    property Max           : integer         read FMax           write SetMax            default 100;
    property Min           : integer         read FMin           write SetMin            default 0;
    property Orientation   : TVPBOrientation read FOrientation   write SetOrientation;
    property Percentage    : boolean         read FPercentage    write SetPercentage;
    property Position      : integer         read FPosition      write SetPosition;
    property PosTextPrefix : string          read FPosTextPrefix write SetPosTextPrefix;
    property PosTextSuffix : string          read FPosTextSuffix write SetPosTextSuffix;
    property ShowPosText   : boolean         read FShowPosText   write SetShowPosText;
    property Anchors;
    property Color;
    property Align;
    property Font;
    property ParentShowHint;
    property ShowHint;
    property Visible;
    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
  end;

procedure Register;

implementation
uses GraphType, FPimage, IntfGraphics;

type
  PBGRA = ^TBGRA;

 //{$IFDEF QT}
 // TRGB = record
 //   r, g, b, a: Byte;
 // end;
 //{$ELSE}
 TBGRA = packed record
   case integer of
     1 : (b, g, r, a : Byte);
     2 : (Color :DWORD);
 end;
 //{$ENDIF}

  PRGBArray = ^TRGBArray;
  TRGBArray = array [0 .. 65565] of TBGRA;
// Mix two colors (value in percent)

function Blend(Color1, Color2: TColor; Value: Byte): TColor;
var
  i: LongInt;
  r1, g1, b1, r2, g2, b2: Byte;
begin
  Value := Round(2.56 * Value);
  i := ColorToRGB(Color2);
  r1 := Byte(i);
  g1 := Byte(i shr 8);
  b1 := Byte(i shr 16);
  i := ColorToRGB(Color1);
  r2 := Byte(i);
  g2 := Byte(i shr 8);
  b2 := Byte(i shr 16);
  r1 := Byte((Value * (r2 - r1)) shr 8 + r1);
  g1 := Byte((Value * (g2 - g1)) shr 8 + g1);
  b1 := Byte((Value * (b2 - b1)) shr 8 + b1);
  Result := (b1 shl 16) + (g1 shl 8) + r1;
end;

function ScanLine(aRI: TRawImage; aY:Integer):PByte;inline;
begin
  case aRI.Description.LineOrder of
    riloTopToBottom : Result := aRI.Data + (aRI.Description.BytesPerLine * aY);
    riloBottomToTop : Result := aRI.Data + (aRI.Description.BytesPerLine * (aRI.Description.Height - aY));
  end;
end;

function NextScanLine(aRI:TRawImage; aLine:PByte; aAmount:Integer=1):PByte;Inline;
begin
  case aRI.Description.LineOrder of
    riloTopToBottom : Result := aLine + (aRI.Description.BytesPerLine * aAmount);
    riloBottomToTop : Result := aLine - (aRI.Description.BytesPerLine * aAmount);
  end;
end;

function RIColor(aRI:TRawImage; const R, G, B : Byte; A:Byte = {$IFDEF LCLGTK2}255{$ELSE}0{$ENDIF}) : DWord;inline;
begin
  Result := DWORD(R shl aRI.Description.Redshift)   or DWORD(B shl aRI.Description.BlueShift) or
            DWORD(G shl aRI.Description.GreenShift) or DWORD(A shl aRI.Description.AlphaShift);
end;

function RISetAlpha(aRI:TRawImage; const aColor:LongWord; const A:Byte) : DWord;//inline;
var
  Clr : TBGRA absolute Result;
begin
  //aRI.WriteChannels();
  case aRI.Description.AlphaShift of
    0 :;
  end;
  Result := RIColor(aRI, 0, 0, 0, A);

  Result := aColor xor (Byte(aColor shr aRI.Description.AlphaShift) shl aRI.Description.AlphaShift);
  Result := Result or  (A shl aRI.Description.AlphaShift);
end;

procedure SmoothMarquee(bmp: TBitmap; const ARect: TRect; const c1: TColor;
  MSize, MFade: Byte; Orientation: TVPBOrientation);
var
  //
  vOpaque, vTransparent : Byte;
  vRI                   : TRawImage;
  //
  rc2, gc2, bc2: integer;
  x, y, w, h, x1, y1: integer;
  p1, p2: integer;
  Row: PRGBArray;
  C: TBGRA;
  slMain, slSize, slPtr: PtrUInt;
  Color: integer;
  Profil: array of TBGRA;
  ar: TRect;
begin
  Assert(bmp.PixelFormat = pf32bit,'Unsupported pixel format');
  if ((ARect.Right - ARect.Left) - 1 <= 0) or
    ((ARect.Bottom - ARect.Top) - 1 <= 1) then
    Exit;
  h := bmp.Height;
  w := bmp.Width;
  Color := ColorToRGB(c1);
  rc2 := Byte(Color);
  gc2 := Byte(Color shr 8);
  bc2 := Byte(Color shr 16);
  c.a := FPimage.alphaOpaque;
  vOpaque := {$IFNDEF LCLGTK2} FPimage.alphaOpaque {$ELSE}FPimage.alphaTransparent{$ENDIF};
  vTransparent := FPimage.alphaTransparent;

  bmp.BeginUpdate(False);
  try
    vRI := bmp.RawImage;
    slSize := vRI.Description.BytesPerLine;
    slMain := PtrUInt(ScanLine(vRI, 0));// Integer(vRI.Data);
    //slMain := integer(bmp.ScanLine[0]);
    //slSize := integer(bmp.ScanLine[1]) - slMain;
    if Orientation = vpbHorizontal then
    begin
      SetLength(Profil, Trunc((w / 100) * MSize));
      w := Length(Profil);
      p1 := w - 1;
      p2 := Trunc((w / 100) * MFade);

      for x := 0 to p1 - p2 do
      begin
        if x < p2 then
        begin
          x1 := 95 + Trunc((159 / p2) * (p2 - x));
          C.b := x1;
          C.g := x1;
          C.r := x1;
          Profil[x] := C;
          Profil[p1 - x] := C;
        end
        else
        begin
          C.b := 96;
          C.g := 96;
          C.r := 96;
          Profil[x] := C;
        end;
      end;
      ar := ARect;
      if ar.Left < 0 then
        ar.Left := ar.Left * -1;
      x1 := 0;
      for x := ARect.Left to ARect.Left + p1 do
      begin
        slPtr := slMain;
        for y := 0 to h - 1 do
        begin
          Row := PRGBArray(slPtr);
          if (x > -1) and (x < bmp.Width) then
          begin
            C.b := Byte((Profil[x1].b * (Row[x].b - bc2)) shr 8 + bc2);
            C.g := Byte((Profil[x1].g * (Row[x].g - gc2)) shr 8 + gc2);
            C.r := Byte((Profil[x1].b * (Row[x].r - rc2)) shr 8 + rc2);
            //Row[x] := C;
            //Row[x].r := C.r;
            //Row[x].g := C.g;
            //Row[x].b := C.b;
            //Row[x].a := vOpaque;
            Row[x].Color := RIColor(vRI, C.r, C.g, C.b, vOpaque);
          end;
          slPtr := PtrUInt(NextScanLine(vRI, Pointer(slPtr), 1));
        end;
        x1 := x1 + 1;
      end;
    end
    else
    begin
      SetLength(Profil, Trunc((h / 100) * MSize));
      h := Length(Profil);
      p1 := h - 1;
      p2 := Trunc((h / 100) * MFade);
      for y := 0 to p1 - p2 do
      begin
        if y < p2 then
        begin
          y1 := 95 + Trunc((159 / p2) * (p2 - y));
          C.b := y1;
          C.g := y1;
          C.r := y1;
          Profil[y] := C;
          Profil[p1 - y] := C;
        end
        else
        begin
          C.b := 96;
          C.g := 96;
          C.r := 96;
          Profil[y] := C;
        end;
      end;
      ar := ARect;
      if ar.Bottom < 0 then
        ar.Top := bmp.Height;
      if ar.Top > 0 then
        y1 := 0
      else
        y1:= (ar.Top * -1);
      if (ar.Top > -1) and (ar.Top < bmp.Height) then
        //slPtr := Integer(bmp.ScanLine[ARect.Top])
        slPtr := longword(vRI.Data) + (ar.Top * slSize)
      else
        slPtr := slMain;
      for y := (ARect.Top + y1) to ARect.Top + p1 do
      begin
        if (y > -1) and (y < bmp.Height) then
        begin
          Row := PRGBArray(slPtr);
          for x := 0 to w - 1 do
          begin
            C.b := Byte((Profil[y1].b * (Row[x].b - bc2)) shr 8 + bc2);
            C.g := Byte((Profil[y1].g * (Row[x].g - gc2)) shr 8 + gc2);
            C.r := Byte((Profil[y1].b * (Row[x].r - rc2)) shr 8 + rc2);

            //Row[x].r := C.r;
            //Row[x].g := C.g;
            //Row[x].b := C.b;
            //Row[x].a := vOpaque;
            Row[x].Color := RIColor(vRI, C.r, C.g, C.b);
          end;
        end;
        y1 := y1 + 1;
        slPtr := PtrUInt(NextScanLine(vRI, Pointer(slPtr), 1));// + slSize;
      end;
    end;
  finally
    bmp.EndUpdate(False);
  end;
end;

procedure SmoothGradient(Canvas: TCanvas; const ARect: TRect; const c1: TColor;
  const Gray: boolean; Orientation: TVPBOrientation);
var
  vAlpha, vOpaque : Byte;
  vRI             : TRawImage;

  rc1, gc1, bc1,
  rc2, gc2, bc2,
  rc3, gc3, bc3,
  rc4, gc4, bc4   : integer;
  x, y, w, h      : integer;
  i, w1, fo,
  h1,sp, sm       : integer;
  Row, AltRow     : PRGBArray;
  C, AC           : TBGRA;
  slMain, slSize,
  slPtr           : integer;
  Color, tc       : integer;
  Profil          : array of TBGRA;
  r, g, b         : integer;
  bmp             : TBitmap;

begin
  if ((ARect.Right - ARect.Left) - 1 <= 0) or
    ((ARect.Bottom - ARect.Top) - 1 <= 1) then
    Exit;
  bmp := TBitmap.Create;
  bmp.PixelFormat := pf32Bit; // pf24Bit;
  bmp.SetSize((ARect.Right - ARect.Left) - 1,(ARect.Bottom - ARect.Top) - 1);
  bmp.Canvas.Brush.Color := clWhite;
  bmp.canvas.Brush.Style := bsSolid;
  bmp.canvas.Pen.Style := psClear;
  bmp.Canvas.Rectangle(5,5,10,10);
  //bmp.Canvas.Brush.Color := clWhite;
  //bmp.Canvas.FillRect(0, 0, bmp.Width-1, bmp.Height-1);
  h := bmp.Height;
  w := bmp.Width;
  if Orientation = vpbHorizontal then
    SetLength(Profil, h)
  else
    SetLength(Profil, w);
  // Get colors for first gradient
  Color := ColorToRGB(c1);
  if Gray then begin
    rc1 := 253;
    gc1 := 253;
    bc1 := 253;
    rc2 := 218;
    gc2 := 218;
    bc2 := 218;
    rc3 := 160;
    gc3 := 160;
    bc3 := 160;
    rc4 := 213;
    gc4 := 213;
    bc4 := 213;
  end else begin
    tc := Blend(Color, clWhite, 5);
    rc1 := Byte(tc);
    gc1 := Byte(tc shr 8);
    bc1 := Byte(tc shr 16);
    tc := Blend(Color, clWhite, 50);
    rc2 := Byte(tc);
    gc2 := Byte(tc shr 8);
    bc2 := Byte(tc shr 16);
    tc := Blend(Color, clBlack, 60);
    rc3 := Byte(tc);
    gc3 := Byte(tc shr 8);
    bc3 := Byte(tc shr 16);
    tc := Blend(Color, clBlack, 80);
    rc4 := Byte(tc);
    gc4 := Byte(tc shr 8);
    bc4 := Byte(tc shr 16);
  end;

  // Init scanline accsess
  bmp.BeginUpdate(False);

  try
    vRI := bmp.RawImage;
    if (vRI.Description.BitsPerPixel) <> 32 then raise exception.Create('Unsupported bitmap format');

    //vRI.Description.Init_BPP32_B8G8R8A8_BIO_TTB((ARect.Right - ARect.Left) - 1,(ARect.Bottom - ARect.Top) - 1);
    slSize := vRI.Description.BytesPerLine; //integer(bmp.ScanLine[1]) - slMain;
    //slMain := Integer(vRI.Data);//integer(bmp.ScanLine[0]);
    slMain := PtrUInt(ScanLine(vRI, 0));

    if Orientation = vpbHorizontal then begin
      // Calc first gradient
      sp := Trunc(h / 2.25);
      y := sp;
      for i := 0 to y - 1 do begin
        C.r := Byte(rc1 + (((rc2 - rc1) * (i)) div y));
        C.g := Byte(gc1 + (((gc2 - gc1) * (i)) div y));
        C.b := Byte(bc1 + (((bc2 - bc1) * (i)) div y));
        Profil[i] := C;
      end;
      for i := y to h - 1 do begin
        C.r := Byte(rc3 + (((rc4 - rc3) * (i)) div h));
        C.g := Byte(gc3 + (((gc4 - gc3) * (i)) div h));
        C.b := Byte(bc3 + (((bc4 - bc3) * (i)) div h));
        Profil[i] := C;
      end;
      // First gradient done
      if Gray then begin
        rc1 := 200;
        gc1 := 200;
        bc1 := 200;
        rc2 := 253;
        gc2 := 253;
        bc2 := 253;
      end else begin
        tc := Blend(Color, clBlack, 50);
        rc1 := Byte(tc);
        gc1 := Byte(tc shr 8);
        bc1 := Byte(tc shr 16);
        tc := Blend(Color, clWhite, 50);
        rc2 := Byte(tc);
        gc2 := Byte(tc shr 8);
        bc2 := Byte(tc shr 16);
      end;
      w1 := w - 1;
      w := (w shr 1) + (w and 1);

      // Paint gradient
      fo := 25;
      for x := 0 to w - 1 do begin
        if x < fo then begin
          C.b := Byte(bc1 + (((bc2 - bc1) * x) div fo));
          C.g := Byte(gc1 + (((gc2 - gc1) * x) div fo));
          C.r := Byte(rc1 + (((rc2 - rc1) * x) div fo));
        end else begin
          C.b := bc2;
          C.g := gc2;
          C.r := rc2;
        end;
        slPtr := slMain;
        for y := 0 to h - 1 do begin
          Row := PRGBArray(slPtr);
          r := Profil[y].r;
          g := Profil[y].g;
          b := Profil[y].b;
          if (x = 0) or ((y < sp) or (y = h - 1)) then begin
            if x = 0 then
              sm := 3
            else
              sm := 2;
            //Row[x].r := ((C.r - r) shr sm + r);
            //Row[x].g := ((C.g - g) shr sm + g);
            //Row[x].b := ((C.b - b) shr sm + b);
            Row[x].Color := RIColor(vRI,(C.r - r) shr sm + r,(C.g - g) shr sm + g,(C.b - b) shr sm + b, vOpaque);
          end  else begin
            //Row[x].r := Byte((C.r - r) div 2 + r);
            //Row[x].g := Byte((C.g - g) div 2 + g);
            //Row[x].b := Byte((C.b - b) div 2 + b);
            Row[x].Color := RIColor(vRI, (C.r - r) div 2 + r,(C.g - g) div 2 + g,(C.b - b) div 2 + b,vOpaque);
          end;
          if (x < (w1 - x)) then Row[w1 - x] := Row[x];
          slPtr :=PtrUInt(ScanLine(vRI, y+1));
        end;
      end;
    end
    else
    begin
      // Calc first gradient
      sp := Trunc(w / 2.5);
      x := sp;
      for i := 0 to x - 1 do begin
        C.r := Byte(rc1 + (((rc2 - rc1) * (i)) div x));
        C.g := Byte(gc1 + (((gc2 - gc1) * (i)) div x));
        C.b := Byte(bc1 + (((bc2 - bc1) * (i)) div x));
        Profil[i] := C;
      end;
      for i := x to w - 1 do begin
        C.r := Byte(rc3 + (((rc4 - rc3) * (i)) div w));
        C.g := Byte(gc3 + (((gc4 - gc3) * (i)) div w));
        C.b := Byte(bc3 + (((bc4 - bc3) * (i)) div w));
        Profil[i] := C;
      end;
      // First gradient done
      if Gray then begin
        rc1 := 200;
        gc1 := 200;
        bc1 := 200;
        rc2 := 253;
        gc2 := 253;
        bc2 := 253;
      end else begin
        tc := Blend(Color, clBlack, 50);
        rc1 := Byte(tc);
        gc1 := Byte(tc shr 8);
        bc1 := Byte(tc shr 16);
        tc := Blend(Color, clWhite, 50);
        rc2 := Byte(tc);
        gc2 := Byte(tc shr 8);
        bc2 := Byte(tc shr 16);
      end;
      h1 := h - 1;
      h := (h shr 1) + (h and 1);

      //slPtr := integer(bmp.ScanLine[bmp.Height - 1]);

      //slPtr := PtrUInt(vri.Data) + ((bmp.Height - 1)*slSize); //( integer(bmp.ScanLine[bmp.Height - 1]);
      slPtr := PtrUInt(ScanLine(vRI, bmp.Height - 1)); //( integer(bmp.ScanLine[bmp.Height - 1]);
      // Paint gradient
      fo := 25;
      for y := 0 to h - 1 do begin
        Row := PRGBArray(slMain);
        AltRow := PRGBArray(slPtr);
        if y < fo then begin
          C.b := Byte(bc1 + (((bc2 - bc1) * y) div fo));
          C.g := Byte(gc1 + (((gc2 - gc1) * y) div fo));
          C.r := Byte(rc1 + (((rc2 - rc1) * y) div fo));
        end else begin
          C.b := bc2;
          C.g := gc2;
          C.r := rc2;
        end;

        for x := 0 to w - 1 do begin
          r := Profil[x].r;
          g := Profil[x].g;
          b := Profil[x].b;
          if (y = 0) or ((x < sp) or (x = w - 1)) then begin
            if y = 0 then
              sm := 3
            else
              sm := 2;
            //Row[x].r := Byte((C.r - r) shr sm + r);
            //Row[x].g := Byte((C.g - g) shr sm + g);
            //Row[x].b := Byte((C.b - b) shr sm + b);
            Row[x].Color := RIColor(vRI, Byte((C.r - r) shr sm + r), Byte((C.g - g) shr sm + g), Byte((C.b - b) shr sm + b));
          end else begin
            //Row[x].r := Byte((C.r - r) div 2 + r);
            //Row[x].g := Byte((C.g - g) div 2 + g);
            //Row[x].b := Byte((C.b - b) div 2 + b);
            Row[x].Color := RIColor(vRI, Byte((C.r - r) div 2 + r), Byte((C.g - g) div 2 + g), Byte((C.b - b) div 2 + b));
          end;
          if (y < (h1 - y)) then
            AltRow[x] := Row[x];
        end;
        slMain := PtrUInt(ScanLine(vRI, y+1)); //slMain + slSize;
        slPtr := PtrUInt(ScanLine(vRI, bmp.Height - y)); //slPtr - slSize;
      end;
    end;
  finally
    //vRI := Nil;
    bmp.EndUpdate(False);
  end;
  Profil := nil;
  Canvas.Draw(ARect.Left, ARect.Top, bmp);
  FreeAndNil(bmp);
end;

{ TVistaProBar }

procedure TVistaProBar.AddPosition(APos: integer);
begin
  Position := Position + APos;
  //Invalidate;
end;

procedure TVistaProBar.CMFontChanged(var Message : TLMessage);
begin
  Invalidate;
end;

constructor TVistaProBar.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csOpaque];
  Width := 150;
  Height := 17;
  Color := clLime;
  FBackColor:= clBtnFace;
  FBorderColor:= clSilver;
  FCornerColor:= clBtnFace;
  FPosition := 0;
  FMin := 0;
  FMax := 100;
  FPosTextSuffix := '';
  FPosTextPrefix := '';
  FPercentage := False;
  FTimer := TTimer.Create(self);
  FTimer.Enabled := False;
  FTimer.Interval := 25;
  FTimer.OnTimer := MarqueeOnTimer;
  FMarqueeSize := 40;
  FMarqueeFade := 30;
  FMarqueeSpeed := 25;
  FOrientation := vpbHorizontal;
end;

destructor TVistaProBar.Destroy;
begin
  FTimer.Free;
  inherited;
end;

procedure TVistaProBar.Draw(Canvas: TCanvas; x, y, Pos: Integer);
var
  vRI           : TRawImage;
  vOpaque       : Byte;
  r             : TRect;
  Len           : integer;
  Percent       : Extended;
  ACap          : string;
  TempBmp       : TBitmap;
  C             : TColor;
  ts            : TSize;
  slSize, slPtr : PtrUInt;
  w, h          : integer;
  Row           : PRGBArray;
  vStep         : Integer;
  vRP           : TRawImagePosition;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  vOpaque := {$IFNDEF LCLGTK2} alphaOpaque {$ELSE}alphaTransparent{$ENDIF};
  if vOpaque > 0 then dec(vOpaque,1) else inc(vOpaque,1);

  TempBmp := TBitmap.Create;
  TempBmp.PixelFormat := pf32Bit; // pf24Bit;
  TempBmp.SetSize(Width, Height);
  //TempBmp.BeginUpdate();
  //TempBmp.RawImage.Description.Init_BPP32_R8G8B8A8_BIO_TTB(Width, Height);
  //TempBmp.EndUpdate();
  Assert(TempBmp.PixelFormat=pf32bit,'unsupported pixel format');
  //TempBmp.Canvas.Brush.Style := bsSolid;
  //TempBmp.Canvas.Pen.Color := clWhite;
  //TempBmp.Canvas.FillRect(1,1,6,6);
  C := Blend(clWhite, clSilver, 50);
  TempBmp.Canvas.Pen.Color := FBorderColor;
  r := Rect(0, 0, TempBmp.Width, TempBmp.Height);
  TempBmp.Canvas.Brush.Color := FBackColor;
  TempBmp.Canvas.Rectangle(r);
  TempBmp.Canvas.Pen.Color := Blend(FBorderColor, clWhite, 99);
  TempBmp.Canvas.MoveTo(1, 0);
  TempBmp.Canvas.LineTo(r.Right - 1, r.Top);
  C := Blend(FBorderColor, FCornerColor, 15);
  TempBmp.Canvas.Pixels[r.Left, r.Top] := C;
  TempBmp.Canvas.Pixels[r.Left, r.Bottom - 1] := C;
  TempBmp.Canvas.Pixels[r.Right - 1, r.Top] := C;
  TempBmp.Canvas.Pixels[r.Right - 1, r.Bottom - 1] := C;

  C := Blend(FBorderColor, FBackColor, 65);
  TempBmp.Canvas.Pixels[r.Left + 1, r.Top + 1] := C;
  TempBmp.Canvas.Pixels[r.Left + 1, r.Bottom - 2] := C;
  TempBmp.Canvas.Pixels[r.Right - 2, r.Top + 1] := C;
  TempBmp.Canvas.Pixels[r.Right - 2, r.Bottom - 2] := C;


  r.Left := 1;
  r.Top := 1;
  if not FAltMode then
    SmoothGradient(TempBmp.Canvas, r, Color, True, FOrientation);
  Len := FMax - FMin;

  if FMarquee then begin
    Len := 100;
    if FMarqueeP = 0 then
      Percent := 0
    else
      Percent := FMarqueeP / Len;
    if Orientation = vpbHorizontal then begin
      r.Right := Round(Width * Percent);
      r.Left := r.Right - Round(Width * (FMarqueeSize / 100));
    end else begin
      r.Top := Height - Round(Height * Percent);
      r.Bottom := r.Top + Round(Height * (FMarqueeSize / 100));
    end;
  end else if r.Right > 0 then begin
    if FMax = FMin then
      Percent := 0
    else
      Percent := (FPosition - FMin) / Len;
    if FOrientation = vpbVertical then
      r.Top := Math.Max(r.Bottom - Round(Height * Percent), 1)
    else
      r.Right := Round(Width * Percent);
  end;

  if r.Right > 0 then
    if FMarquee then
      SmoothMarquee(TempBmp, r, Color, FMarqueeSize, FMarqueeFade, FOrientation)
    else
      SmoothGradient(TempBmp.Canvas, r, Color, False, FOrientation);
  if FPercentage then
    ACap := IntToStr(Round(Percent * 100)) + '%'
  else
    ACap := IntToStr(FPosition);
  if FShowPosText then
    ACap := FPosTextPrefix + ACap + FPosTextSuffix;
  TempBmp.Canvas.Font := Font;
  if FShowPosText then begin
    TempBmp.Canvas.Brush.Style := bsClear;
    ts := TempBmp.Canvas.TextExtent(ACap);
    TempBmp.Canvas.TextOut((Width - ts.cx) div 2, (Height - ts.cy) div 2, ACap);
  end;
  {.$IFNDEF LCLGTK2}

  TempBmp.BeginUpdate(False);
  try
    vRI := TempBmp.RawImage;
    //vRI.Description.Init_BPP32_B8G8R8A8_BIO_TTB(Width, Height);
    //slPtr := integer(TempBmp.ScanLine[0]);
    slPtr := PtrUInt(ScanLine(vRI,0));
    //slSize := integer(TempBmp.ScanLine[1]) - slPtr;
    slSize := vRI.Description.BytesPerLine;
    for h := 0 to TempBmp.Height - 1 do
    begin
      Row := PRGBArray(slPtr);
      for w := 0 to TempBmp.Width - 1 do
        {$IFNDEF LCLQT}
        Row[w].a := vOpaque;
        //Row[x].Color := RISetAlpha(vRI, Row[x].Color, vOpaque);
        {$ELSE}
        Row[x].Color := RISetAlpha(vRI, Row[x].Color, vOpaque);
        //Row[w].a := vOpaque;
        {$ENDIF}
      slPtr := PtrUInt(NextScanLine(vRI, Pointer(slPtr), 1));
    end;
  finally
    //vRI:= Nil;
    TempBmp.EndUpdate(False);
  end;
  {.$ENDIF}
  TempBmp.Canvas.Brush.Style := bsSolid;
  Canvas.CopyMode := cmSrcCopy;
  Canvas.Draw(x, y, TempBmp);
  TempBmp.Free;
end;

procedure TVistaProBar.MarqueeOnTimer(Sender: TObject);
begin
  if (FMarqueeP >= 100 + FMarqueeSize) then
    FMarqueeP := 0;
  Invalidate;
  Inc(FMarqueeP);
end;

procedure TVistaProBar.Paint;
begin
  if Visible then
  begin
    Canvas.Lock;
    Draw(Canvas, 0, 0, FPosition);
    Canvas.Unlock;
  end;
end;

procedure TVistaProBar.Resize;
begin
  inherited;
end;

procedure TVistaProBar.SetAltMode(const Value: boolean);
begin
  FAltMode := Value;
  Invalidate;
end;

procedure TVistaProBar.SetBackColor(const Value: TColor);
begin
  FBackColor := Value;
  Invalidate;
end;

procedure TVistaProBar.SetBorderColor(const Value: TColor);
begin
  FBorderColor := Value;
  Invalidate;
end;

procedure TVistaProBar.SetCornerColor(const Value: TColor);
begin
  FCornerColor := Value;
  Invalidate;
end;

procedure TVistaProBar.SetMarquee(const Value: boolean);
begin
  FMarquee := Value;
  FTimer.Enabled := Value;
  Paint;
end;

procedure TVistaProBar.SetMarqueeFade(const Value: Byte);
begin
  FMarqueeFade := Value;
  Paint;
end;

procedure TVistaProBar.SetMarqueeSize(const Value: Byte);
begin
  FMarqueeSize := Value;
  Paint;
end;

procedure TVistaProBar.SetMarqueeSpeed(const Value: Byte);
begin
  FMarqueeSpeed := Value;
  FTimer.Interval := Value;
end;

procedure TVistaProBar.SetMax(const Value: integer);
begin
  if FMax = Value then
    Exit;
  FMax := Value;
  //Paint;
  Invalidate;
end;

procedure TVistaProBar.SetMin(const Value: integer);
begin
  if FMin = Value then
    Exit;
  FMin := Value;
  //Paint;
  Invalidate;
end;

procedure TVistaProBar.SetOrientation(const Value: TVPBOrientation);
begin
  FOrientation := Value;
  Paint;
end;

procedure TVistaProBar.SetPercentage(const Value: boolean);
begin
  if FPercentage = Value then
    Exit;
  FPercentage := Value;
  //Paint;
  Invalidate;
end;

procedure TVistaProBar.SetPosition(const Value: integer);
begin
  if FPosition = Value then
    Exit;
  if Value > FMax then
    FPosition := FMax
  else if Value < FMin then
    FPosition := FMin
  else
    FPosition := Value;
  //Paint;
  Invalidate;
end;

procedure TVistaProBar.SetPosTextPrefix(const Value: string);
begin
  if FPosTextPrefix = Value then
    Exit;
  FPosTextPrefix := Value;
  //Paint;
  Invalidate;
end;

procedure TVistaProBar.SetPosTextSuffix(const Value: string);
begin
  if FPosTextSuffix = Value then
    Exit;
  FPosTextSuffix := Value;
  //Paint;
  Invalidate;
end;

procedure TVistaProBar.SetShowPosText(const Value: boolean);
begin
  if FShowPosText = Value then
    Exit;
  FShowPosText := Value;
  //Paint;
  Invalidate;
end;

procedure Register;
begin
  RegisterComponents('rmklever', [TVistaProBar]);
end;

end.
