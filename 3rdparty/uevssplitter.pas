{------------------------------------------------------------------------------
 TdfsSplitter v2.03
------------------------------------------------------------------------------
 A descendant of the TSplitter component (D3, C3, & D4) that adds a
 "maximize - restore" button.  This mimics the behavior of the splitter in
 Netscape Communicator v4.5.  Clicking the button moves the splitter to its
 farthest extreme.  Clicking again returns it to the last position.

 Copyright 2000-2001, Brad Stowers.  All Rights Reserved.

 Copyright:
 All Delphi Free Stuff (hereafter "DFS") source code is copyrighted by
 Bradley D. Stowers (hereafter "author"), and shall remain the exclusive
 property of the author.

 Distribution Rights:
 You are granted a non-exlusive, royalty-free right to produce and distribute
 compiled binary files (executables, DLLs, etc.) that are built with any of
 the DFS source code unless specifically stated otherwise.
 You are further granted permission to redistribute any of the DFS source
 code in source code form, provided that the original archive as found on the
 DFS web site (http://www.delphifreestuff.com) is distributed unmodified. For
 example, if you create a descendant of TdfsColorButton, you must include in
 the distribution package the colorbtn.zip file in the exact form that you
 downloaded it from http://www.delphifreestuff.com/mine/files/colorbtn.zip.

 Restrictions:
 Without the express written consent of the author, you may not:
   * Distribute modified versions of any DFS source code by itself. You must
     include the original archive as you found it at the DFS site.
   * Sell or lease any portion of DFS source code. You are, of course, free
     to sell any of your own original code that works with, enhances, etc.
     DFS source code.
   * Distribute DFS source code for profit.

 Warranty:
 There is absolutely no warranty of any kind whatsoever with any of the DFS
 source code (hereafter "software"). The software is provided to you "AS-IS",
 and all risks and losses associated with it's use are assumed by you. In no
 event shall the author of the softare, Bradley D. Stowers, be held
 accountable for any damages or losses that may occur from use or misuse of
 the software.

 Support:
 Support is provided via the DFS Support Forum, which is a web-based message
 system.  You can find it at http://www.delphifreestuff.com/discus/
 All DFS source code is provided free of charge. As such, I can not guarantee
 any support whatsoever. While I do try to answer all questions that I
 receive, and address all problems that are reported to me, you must
 understand that I simply can not guarantee that this will always be so.

 Clarifications:
 If you need any further information, please feel free to contact me directly.
 This agreement can be found online at my site in the "Miscellaneous" section.
------------------------------------------------------------------------------
 The lateset version of my components are always available on the web at:
   http://www.delphifreestuff.com/
 See DFSSplitter.txt for notes, known issues, and revision history.
------------------------------------------------------------------------------
 Date last modified:  June 27, 2001
------------------------------------------------------------------------------}

unit uEvsSplitter;

{$MODE OBJFPC}{$H+}



interface

uses
  LCLIntf, LCLType, LMessages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls;

const
  MOVEMENT_TOLERANCE = 5; // See WMLButtonUp message handler.
  DEF_BUTTON_HIGHLIGHT_COLOR = $00FFCFCF; // RGB(207,207,255)

type
  TEvsButtonWidthType = (btwPixels, btwPercentage);
  TEvsButtonStyle = (bsNetscape, bsWindows);
  TEvsWindowsButton = (wbMin, wbMax, wbClose);
  TEvsWindowsButtons = set of TEvsWindowsButton;

  {..... TEvsSplitter }

  TEvsSplitter = class(TSplitter)
  private
    FShowButton: boolean;
    FButtonWidthType: TEvsButtonWidthType;
    FButtonWidth: integer;
    FOnMaximize: TNotifyEvent;
    FOnMinimize: TNotifyEvent;
    FOnRestore: TNotifyEvent;
    FMaximized: boolean;
    FMinimized: boolean;
    // Internal use for "restoring" from "maximized" state
    FRestorePos: integer;
    // For internal use to avoid calling GetButtonRect when not necessary
    FLastKnownButtonRect: TRect;
    // Internal use to avoid unecessary painting
    FIsHighlighted: boolean;
    // Internal for detecting real clicks
    FGotMouseDown: boolean;
    FButtonColor: TColor;
    FButtonHighlightColor: TColor;
    FArrowColor: TColor;
    FTextureColor1: TColor;
    FTextureColor2: TColor;
    FAutoHighlightColor : boolean;
    FAllowDrag: boolean;
    FButtonStyle: TEvsButtonStyle;
    FWindowsButtons: TEvsWindowsButtons;
    FOnClose: TNotifyEvent;
    FButtonCursor: TCursor;
    procedure SetShowButton(const aValue : boolean);
    procedure SetButtonWidthType(const aValue : TEvsButtonWidthType);
    procedure SetButtonWidth(const aValue : integer);
    function GetButtonRect: TRect;
    procedure SetMaximized(const aValue : boolean);
    procedure SetMinimized(const aValue : boolean);
    function GetAlign: TAlign;
    procedure SetAlign(const aValue : TAlign);
    procedure SetArrowColor(const Value: TColor);
    procedure SetButtonColor(const Value: TColor);
    procedure SetButtonHighlightColor(const Value: TColor);
    procedure SetButtonStyle(const Value: TEvsButtonStyle);
    procedure SetTextureColor1(const Value: TColor);
    procedure SetTextureColor2(const Value: TColor);
    procedure SetAutoHighLightColor(const Value: boolean);
    procedure SetAllowDrag(const Value: boolean);
    procedure SetWindowsButtons(const Value: TEvsWindowsButtons);
    procedure SetButtonCursor(const Value: TCursor);
    procedure WMLButtonDown(var aMsg : TLMLButtonDown); message LM_LBUTTONDOWN;
    procedure WMLButtonUp(var aMsg : TLMLButtonUp); message LM_LBUTTONUP;
    procedure WMMouseMove(var aMsg : TLMMouseMove); message LM_MOUSEMOVE;
    procedure CMMouseEnter(var aMsg : TLMMouse); message CM_MOUSEENTER;
    procedure CMMouseLeave(var aMsg : TLMMouse); message CM_MOUSELEAVE;
  protected
    // Internal use for moving splitter position with FindControl and
    // UpdateControlSize
    FControl: TControl;
    FDownPos: TPoint;

    procedure LoadOtherProperties(Reader: TReader); dynamic;
    procedure StoreOtherProperties(Writer: TWriter); dynamic;
    procedure DefineProperties(Filer: TFiler); override;
    procedure Paint; override;

    procedure Loaded; override;
    procedure PaintButton(aHighlight : boolean); dynamic;
    function DrawArrow(aCanvas : TCanvas; aAvailableRect : TRect;
                       aOffset : integer; aArrowSize : integer; aColor : TColor) : integer;
  dynamic;
    function WindowButtonHitTest(X, Y: integer): TEvsWindowsButton; dynamic;
    function ButtonHitTest(X, Y: integer): boolean; dynamic;
    procedure DoMaximize;  dynamic;
    procedure DoMinimize;  dynamic;
    procedure DoRestore;   dynamic;
    procedure DoClose;     dynamic;
    procedure FindControl; dynamic;
    procedure UpdateControlSize(NewSize: integer); dynamic;
    function GrabBarColor: TColor;
    function VisibleWinButtons: integer;
  public
    constructor Create(AOwner: TComponent); override;

    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;

    property ButtonRect: TRect read GetButtonRect;
    property RestorePos: integer read FRestorePos write FRestorePos;
  published
    property Maximized           : boolean             read FMaximized            write SetMaximized;
    property Minimized           : boolean             read FMinimized            write SetMinimized;
    property AllowDrag           : boolean             read FAllowDrag            write SetAllowDrag            default TRUE;
    property ButtonCursor        : TCursor             read FButtonCursor         write SetButtonCursor;
    property ButtonStyle         : TEvsButtonStyle     read FButtonStyle          write SetButtonStyle          default bsNetscape;
    property WindowsButtons      : TEvsWindowsButtons  read FWindowsButtons       write SetWindowsButtons       default [wbMin, wbMax, wbClose];
    property ButtonWidthType     : TEvsButtonWidthType read FButtonWidthType      write SetButtonWidthType      default btwPixels;
    property ButtonWidth         : integer             read FButtonWidth          write SetButtonWidth          default 100;
    property ShowButton          : boolean             read FShowButton           write SetShowButton           default TRUE;
    property ButtonColor         : TColor              read FButtonColor          write SetButtonColor          default clBtnFace;
    property ArrowColor          : TColor              read FArrowColor           write SetArrowColor           default clNavy;
    property ButtonHighlightColor: TColor              read FButtonHighlightColor write SetButtonHighlightColor default DEF_BUTTON_HIGHLIGHT_COLOR;
    property AutoHighlightColor  : Boolean             read FAutoHighlightColor   write SetAutoHighlightColor   default FALSE;
    property TextureColor1       : TColor              read FTextureColor1        write SetTextureColor1        default clWhite;
    property TextureColor2       : TColor              read FTextureColor2        write SetTextureColor2        default clNavy;
    property Align               : TAlign              read GetAlign              write SetAlign;
    property Width                                                                                              default 10;
    property OnMaximize          : TNotifyEvent        read FOnMaximize           write FOnMaximize;
    property OnMinimize          : TNotifyEvent        read FOnMinimize           write FOnMinimize;
    property OnRestore           : TNotifyEvent        read FOnRestore            write FOnRestore;
    property OnClose             : TNotifyEvent        read FOnClose              write FOnClose;
    property Beveled                                                                                            default FALSE;
    property Enabled;
  end;

implementation

{ TEvsSplitter }

constructor TEvsSplitter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  Beveled           := FALSE;
  FAllowDrag        := TRUE;
  FButtonStyle      := bsNetscape;
  FWindowsButtons   := [wbMin, wbMax, wbClose];
  FButtonWidthType  := btwPixels;
  FButtonWidth      := 100;
  FShowButton       := TRUE;
  SetRectEmpty(FLastKnownButtonRect);
  FIsHighlighted := FALSE;
  FGotMouseDown  := FALSE;
  FControl       := NIL;
  FDownPos       := Point(0,0);
  FMaximized     := FALSE;
  FMinimized     := FALSE;
  FRestorePos    := -1;
  Width          := 10;
  FButtonColor   := clBtnFace;
  FArrowColor    := clNavy;
  FButtonHighlightColor := DEF_BUTTON_HIGHLIGHT_COLOR;
  FAutoHighLightColor   := FALSE;
  FTextureColor1        := clWhite;
  FTextureColor2        := clNavy;
end;

function TEvsSplitter.GrabBarColor: TColor;
var
  vBeginRGB: array[0..2] of Byte;
  vRGBDifference: array[0..2] of integer;
  R,G,B: Byte;
  vBeginColor,
  vEndColor: TColor;
  vNumberOfColors: integer;

begin
  //Need to figure out how many colors available at runtime
  vNumberOfColors := 256;

  vBeginColor := clActiveCaption;
  vEndColor := clBtnFace;

  vBeginRGB[0] := GetRValue(ColorToRGB(vBeginColor));
  vBeginRGB[1] := GetGValue(ColorToRGB(vBeginColor));
  vBeginRGB[2] := GetBValue(ColorToRGB(vBeginColor));

  vRGBDifference[0] := GetRValue(ColorToRGB(vEndColor)) - vBeginRGB[0];
  vRGBDifference[1] := GetGValue(ColorToRGB(vEndColor)) - vBeginRGB[1];
  vRGBDifference[2] := GetBValue(ColorToRGB(vEndColor)) - vBeginRGB[2];

  R := vBeginRGB[0] + MulDiv (180, vRGBDifference[0], vNumberOfColors - 1);
  G := vBeginRGB[1] + MulDiv (180, vRGBDifference[1], vNumberOfColors - 1);
  B := vBeginRGB[2] + MulDiv (180, vRGBDifference[2], vNumberOfColors - 1);

  Result := RGB (R, G, B);
end;

function TEvsSplitter.DrawArrow(aCanvas: TCanvas; aAvailableRect: TRect; aOffset: integer;
   aArrowSize: integer; aColor: TColor): integer;
var
  x, y, q, i, j: integer;
  vArrowAlign: TAlign;
begin
  // STB Nitro drivers have a LineTo bug, so I've opted to use the slower
  // SetPixel method to draw the arrows.

  if not Odd(aArrowSize) then
    Dec(aArrowSize);
  if aArrowSize < 1 then
    aArrowSize := 1;

  if FMaximized then
  begin
    case Align of
      alLeft:   vArrowAlign := alRight;
      alRight:  vArrowAlign := alLeft;
      alTop:    vArrowAlign := alBottom;
    else //alBottom
      vArrowAlign := alTop;
    end;
  end else
    vArrowAlign := Align;
  q := aArrowSize * 2 - 1 ;
  Result := q;
  aCanvas.Pen.Color := aColor;
  with aAvailableRect do
  begin
    case vArrowAlign of
      alLeft:
        begin
          x := Left + ((Right - Left - aArrowSize) div 2) + 1;
          if aOffset < 0 then
            y := Bottom + aOffset - q
          else
            y := Top + aOffset;
          for j := x + aArrowSize - 1 downto x do
          begin
            for i := y to y + q - 1 do
              aCanvas.Pixels[j, i] := aColor;
            inc(y);
            dec(q,2);
          end;
        end;
      alRight:
        begin
          x := Left + ((Right - Left - aArrowSize) div 2) + 1;
          if aOffset < 0 then
            y := Bottom + aOffset - q
          else
            y := Top + aOffset;
          for j := x to x + aArrowSize - 1 do
          begin
            for i := y to y + q - 1 do
              aCanvas.Pixels[j, i] := aColor;
            inc(y);
            dec(q,2);
          end;
        end;
      alTop:
        begin
          if aOffset < 0 then
            x := Right + aOffset - q
          else
            x := Left + aOffset;
          y := Top + ((Bottom - Top - aArrowSize) div 2) + 1;
          for i := y + aArrowSize - 1 downto y do
          begin
            for j := x to x + q - 1 do
              aCanvas.Pixels[j, i] := aColor;
            inc(x);
            dec(q,2);
          end;
        end;
    else // alBottom
      if aOffset < 0 then
        x := Right + aOffset - q
      else
        x := Left + aOffset;
      y := Top + ((Bottom - Top - aArrowSize) div 2) + 1;
      for i := y to y + aArrowSize - 1 do
      begin
        for j := x to x + q - 1 do
          aCanvas.Pixels[j, i] := aColor;
        inc(x);
        dec(q,2);
      end;
    end;
  end;
end;

function TEvsSplitter.GetButtonRect: TRect;
var
  vBW: integer;
begin
  if ButtonStyle = bsWindows then
  begin
    if Align in [alLeft, alRight] then
      vBW := (ClientRect.Right - ClientRect.Left) * VisibleWinButtons
    else
      vBW := (ClientRect.Bottom - ClientRect.Top) * VisibleWinButtons;
    if vBW < 1 then
      SetRectEmpty(Result)
    else
    begin
      if Align in [alLeft, alRight] then
        Result := Rect(0, 0, ClientRect.Right - ClientRect.Left, vBW -
          VisibleWinButtons)
      else
        Result := Rect(ClientRect.Right - vBW + VisibleWinButtons, 0,
          ClientRect.Right, ClientRect.Bottom - ClientRect.Top);
      InflateRect(Result, -1, -1);
    end;
  end
  else
  begin
    // Calc the rectangle the button goes in
    if ButtonWidthType = btwPercentage then
    begin
      if Align in [alLeft, alRight] then
        vBW := ClientRect.Bottom - ClientRect.Top
      else
        vBW := ClientRect.Right - ClientRect.Left;
      vBW := MulDiv(vBW, FButtonWidth, 100);
    end
    else
      vBW := FButtonWidth;
    if vBW < 1 then
      SetRectEmpty(Result)
    else
    begin
      Result := ClientRect;
      if Align in [alLeft, alRight] then
      begin
        Result.Top := (ClientRect.Bottom - ClientRect.Top - vBW) div 2;
        Result.Bottom := Result.Top + vBW;
        InflateRect(Result, -1, 0);
      end
      else
      begin
        Result.Left := (ClientRect.Right - ClientRect.Left - vBW) div 2;
        Result.Right := Result.Left + vBW;
        InflateRect(Result, 0, -1);
      end;
    end;
  end;
  if not IsRectEmpty(Result) then
  begin
    if Result.Top < 1 then
      Result.Top := 1;
    if Result.Left < 1 then
      Result.Left := 1;
    if Result.Bottom >= ClientRect.Bottom then
      Result.Bottom := ClientRect.Bottom - 1;
    if Result.Right >= ClientRect.Right then
      Result.Right := ClientRect.Right - 1;
    // Make smaller if it's beveled
    if Beveled then
      if Align in [alLeft, alRight] then
        InflateRect(Result, -3, 0)
      else
        InflateRect(Result, 0, -3);
  end;
  FLastKnownButtonRect := Result;
end;

procedure TEvsSplitter.Paint;
begin
// Exclude button rect from update region here for less flicker.
  inherited Paint;

// Don't paint while being moved unless ResizeStyle = rsUpdate!!!
// Make rect smaller if Beveled is true.
  PaintButton(FIsHighlighted);
end;

procedure TEvsSplitter.PaintButton(aHighlight: boolean);
const
  cTEXTURE_SIZE = 3;
var
  vBtnRect: TRect;
  vCaptionBtnRect: TRect;
  vBW: integer;
  vTextureBmp: TBitmap;
  x, y: integer;
  vRW, RH: integer;
  vOffscreenBmp: TBitmap;
  vWinButton: array[0..2] of TEvsWindowsButton;
  b: TEvsWindowsButton;
  vBtnFlag: UINT;
begin
  if (not FShowButton) or (not Enabled) or (GetParentForm(Self) = NIL) then
    exit;

  if FAutoHighLightColor then
    FButtonHighlightColor := GrabBarColor;

  vBtnRect := ButtonRect; // So we don't repeatedly call GetButtonRect
  if IsRectEmpty(vBtnRect) then
    exit; // nothing to draw

  vOffscreenBmp := TBitmap.Create;
  try
    OffsetRect(vBtnRect, -vBtnRect.Left, -vBtnRect.Top);
    vOffscreenBmp.Width := vBtnRect.Right;
    vOffscreenBmp.Height := vBtnRect.Bottom;

    if ButtonStyle = bsWindows then
    begin
      vOffscreenBmp.Canvas.Brush.Color := Color;
      vOffscreenBmp.Canvas.FillRect(vBtnRect);
      if Align in [alLeft, alRight] then
        vBW := vBtnRect.Right
      else
        vBW := vBtnRect.Bottom;
      FillChar(vWinButton, SizeOf(vWinButton), 0);
      x := 0;
      if Align in [alLeft, alRight] then
      begin
        for b := High(TEvsWindowsButton) downto Low(TEvsWindowsButton) do
          if b in WindowsButtons then
          begin
            vWinButton[x] := b;
            inc(x);
          end;
      end
      else
      begin
        for b := Low(TEvsWindowsButton) to High(TEvsWindowsButton) do
          if b in WindowsButtons then
          begin
            vWinButton[x] := b;
            inc(x);
          end;
      end;
      for x := 0 to VisibleWinButtons - 1 do
      begin
        if Align in [alLeft, alRight] then
          vCaptionBtnRect := Bounds(0, x * vBW, vBW, vBW)
        else
          vCaptionBtnRect := Bounds(x * vBW, 0, vBW, vBW);
        vBtnFlag := 0;
        case vWinButton[x] of
          wbMin:
            begin
              if Minimized then
                vBtnFlag := DFCS_CAPTIONRESTORE
              else
                vBtnFlag := DFCS_CAPTIONMIN;
            end;
          wbMax:
            begin
              if Maximized then
                vBtnFlag := DFCS_CAPTIONRESTORE
              else
                vBtnFlag := DFCS_CAPTIONMAX;
            end;
          wbClose:
            begin
              vBtnFlag := DFCS_CAPTIONCLOSE;
            end;
        end;
        DrawFrameControl(vOffscreenBmp.Canvas.Handle, vCaptionBtnRect, DFC_CAPTION,
          vBtnFlag);
      end;
    end
    else
    begin
      // Draw basic button
      vOffscreenBmp.Canvas.Brush.Color := clGray;
      vOffscreenBmp.Canvas.FrameRect(vBtnRect);
      InflateRect(vBtnRect, -1, -1);

      vOffscreenBmp.Canvas.Pen.Color := clWhite;
      with vBtnRect, vOffscreenBmp.Canvas do
      begin
        // This is not going to work with the STB bug.  Have to find workaround.
        MoveTo(Left, Bottom-1);
        LineTo(Left, Top);
        LineTo(Right, Top);
      end;
      Inc(vBtnRect.Left);
      Inc(vBtnRect.Top);

      if aHighlight then
        vOffscreenBmp.Canvas.Brush.Color := ButtonHighlightColor
      else
        vOffscreenBmp.Canvas.Brush.Color := ButtonColor;
      vOffscreenBmp.Canvas.FillRect(vBtnRect);
      FIsHighlighted := aHighlight;
      Dec(vBtnRect.Right);
      Dec(vBtnRect.Bottom);

      // Draw the insides of the button
      with vBtnRect do
      begin
        // Draw the arrows
        if Align in [alLeft, alRight] then
        begin
          InflateRect(vBtnRect, 0, -4);
          vBW := vBtnRect.Right - vBtnRect.Left;
          DrawArrow(vOffscreenBmp.Canvas, vBtnRect, 1, vBW, ArrowColor);
          vBW := DrawArrow(vOffscreenBmp.Canvas, vBtnRect, -1, vBW, ArrowColor);
          InflateRect(vBtnRect, 0, -(vBW+4));
        end else begin
          InflateRect(vBtnRect, -4, 0);
          vBW := vBtnRect.Bottom - vBtnRect.Top;
          DrawArrow(vOffscreenBmp.Canvas, vBtnRect, 1, vBW, ArrowColor);
          vBW := DrawArrow(vOffscreenBmp.Canvas, vBtnRect, -1, vBW, ArrowColor);
          InflateRect(vBtnRect, -(vBW+4), 0);
        end;

        // Draw the texture
        // Note: This is so complex because I'm trying to make as much like the
        //       Netscape splitter as possible.  They use a 3x3 texture pattern, and
        //       that's harder to tile.  If the had used an 8x8 (or smaller
        //       divisibly, i.e. 2x2 or 4x4), I could have used Brush.Bitmap and
        //       FillRect and they whole thing would have been about half the size,
        //       twice as fast, and 1/10th as complex.
        vRW := vBtnRect.Right - vBtnRect.Left;
        RH := vBtnRect.Bottom - vBtnRect.Top;
        if (vRW >= cTEXTURE_SIZE) and (RH >= cTEXTURE_SIZE) then
        begin
          vTextureBmp := TBitmap.Create;
          try
            with vTextureBmp do
            begin
              Width := vRW;
              Height := RH;
              // Draw first square
              Canvas.Brush.Color := vOffscreenBmp.Canvas.Brush.Color;
              Canvas.FillRect(Rect(0, 0, vRW+1, RH+1));
              Canvas.Pixels[1,1] := TextureColor1;
              Canvas.Pixels[2,2] := TextureColor2;

              // Tile first square all the way across
              for x := 1 to ((vRW div cTEXTURE_SIZE) + ord(vRW mod cTEXTURE_SIZE > 0)) do
              begin
                Canvas.CopyRect(Bounds(x * cTEXTURE_SIZE, 0, cTEXTURE_SIZE,
                   cTEXTURE_SIZE), Canvas, Rect(0, 0, cTEXTURE_SIZE, cTEXTURE_SIZE));
              end;

              // Tile first row all the way down
              for y := 1 to ((RH div cTEXTURE_SIZE) + ord(RH mod cTEXTURE_SIZE > 0)) do
              begin
                Canvas.CopyRect(Bounds(0, y * cTEXTURE_SIZE, vRW, cTEXTURE_SIZE),
                   Canvas, Rect(0, 0, vRW, cTEXTURE_SIZE));
              end;

              // Above could be better if it reversed process when splitter was
              // taller than it was wider.  Optimized only for horizontal right now.
            end;
            // Copy texture bitmap to the screen.
            vOffscreenBmp.Canvas.CopyRect(vBtnRect, vTextureBmp.Canvas,
               Rect(0, 0, vRW, RH));
          finally
            vTextureBmp.Free;
          end;
        end;
      end;
    end;
(**)
    Canvas.CopyRect(ButtonRect, vOffscreenBmp.Canvas, Rect(0, 0,
       vOffscreenBmp.Width, vOffscreenBmp.Height));
  finally
    vOffscreenBmp.Free;
  end;
end;

procedure TEvsSplitter.SetButtonWidth(const aValue: integer);
begin
  if aValue <> FButtonWidth then
  begin
    FButtonWidth := aValue;
    if (FButtonWidthType = btwPercentage) and (FButtonWidth > 100) then
      FButtonWidth := 100;
    if FButtonWidth < 0 then
      FButtonWidth := 0;
    if (ButtonStyle = bsNetscape) and ShowButton then
      Invalidate;
  end;
end;

procedure TEvsSplitter.SetButtonWidthType(const aValue: TEvsButtonWidthType);
begin
  if aValue <> FButtonWidthType then
  begin
    FButtonWidthType := aValue;
    if (FButtonWidthType = btwPercentage) and (FButtonWidth > 100) then
      FButtonWidth := 100;
    if (ButtonStyle = bsNetscape) and ShowButton then
      Invalidate;
  end;
end;

procedure TEvsSplitter.SetShowButton(const aValue: boolean);
begin
  if aValue <> FShowButton then
  begin
    FShowButton := aValue;
    SetRectEmpty(FLastKnownButtonRect);
    Invalidate;
  end;
end;

procedure TEvsSplitter.WMMouseMove(var aMsg : TLMMouseMove);
begin
  if AllowDrag then
  begin
    inherited;

    // The order is important here.  ButtonHitTest must be evaluated before
    // the ButtonStyle because it will change the cursor (over button or not).
    // If the order were reversed, the cursor would not get set for bsWindows
    // style since short-circuit boolean eval would stop it from ever being
    // called in the first place.
    if ButtonHitTest(aMsg.XPos, aMsg.YPos) and (ButtonStyle = bsNetscape) then
    begin
      if not FIsHighlighted then
        PaintButton(TRUE)
    end else
      if FIsHighlighted then
        PaintButton(FALSE);
  end else
    DefaultHandler(aMsg); // Bypass TSplitter and just let normal handling occur.
end;

procedure TEvsSplitter.CMMouseEnter(var aMsg : TLMMouse);
var
  vPos: TPoint;
begin
  inherited;

  GetCursorPos(vPos); // CM_MOUSEENTER doesn't send mouse vpos.
  vPos := Self.ScreenToClient(vPos);
  // The order is important here.  ButtonHitTest must be evaluated before
  // the ButtonStyle because it will change the cursor (over button or not).
  // If the order were reversed, the cursor would not get set for bsWindows
  // style since short-circuit boolean eval would stop it from ever being
  // called in the first place.
  if ButtonHitTest(vPos.x, vPos.y) and (ButtonStyle = bsNetscape) then
  begin
    if not FIsHighlighted then
      PaintButton(TRUE)
  end else
    if FIsHighlighted then
      PaintButton(FALSE);
end;

procedure TEvsSplitter.CMMouseLeave(var aMsg : TLMMouse);
begin
  inherited;

  if (ButtonStyle = bsNetscape) and FIsHighlighted then
    PaintButton(FALSE);

  FGotMouseDown := FALSE;
end;

procedure TEvsSplitter.WMLButtonDown(var aMsg : TLMLButtonDown);
begin
  if Enabled then
  begin
    FGotMouseDown := ButtonHitTest(aMsg.XPos, aMsg.YPos);
    if FGotMouseDown then
    begin
      FindControl;
      FDownPos := ClientToScreen(Point(aMsg.XPos, aMsg.YPos));
    end;
  end;
  if AllowDrag then
    inherited // Let TSplitter have it.
  else
    // Bypass TSplitter and just let normal handling occur. Prevents drag painting.
    DefaultHandler(aMsg);
end;

procedure TEvsSplitter.WMLButtonUp(var aMsg : TLMLButtonUp);
var
  vCurPos: TPoint;
  vOldMax: boolean;
begin
  inherited;

  if FGotMouseDown then
  begin
    if ButtonHitTest(aMsg.XPos, aMsg.YPos) then
    begin
      vCurPos := ClientToScreen(Point(aMsg.XPos, aMsg.YPos));
      // More than a little movement is not a click, but a regular resize.
      if ((Align in [alLeft, alRight]) and
         (Abs(FDownPos.x - vCurPos.X) <= MOVEMENT_TOLERANCE)) or
         ((Align in [alTop, alBottom]) and
         (Abs(FDownPos.y - vCurPos.Y) <= MOVEMENT_TOLERANCE)) then
      begin
        StopSplitterMove(vCurPos);
        if ButtonStyle = bsNetscape then
          Maximized := not Maximized
        else
          case WindowButtonHitTest(aMsg.XPos, aMsg.YPos) of
            wbMin: Minimized := not Minimized;
            wbMax: Maximized := not Maximized;
            wbClose: DoClose;
          end;
      end;
    end;
    FGotMouseDown := FALSE;
  end
  else if AllowDrag then
  begin
    FindControl;
    if FControl = NIL then
      exit;

    vOldMax := FMaximized;
    case Align of
      alLeft, alRight: FMaximized := FControl.Width <= MinSize;
      alTop, alBottom: FMaximized := FControl.Height <= MinSize;
    end;
    if FMaximized then
    begin
      UpdateControlSize(MinSize);
      if not vOldMax then
        DoMaximize;
    end
    else
    begin
      case Align of
        alLeft,
        alRight:  FRestorePos := FControl.Width;
        alTop,
        alBottom: FRestorePos := FControl.Height;
      end;
      if vOldMax then
        DoRestore;
    end;
  end;
  Invalidate;
end;

function TEvsSplitter.WindowButtonHitTest(X, Y: integer): TEvsWindowsButton;
var
  vBtnRect: TRect;
  i: integer;
  b: TEvsWindowsButton;
  vWinButton: array[0..2] of TEvsWindowsButton;
  vBW: integer;
  vBRs: array[0..2] of TRect;
begin
  Result := wbMin;
  // Figure out which one was hit.  This function assumes ButtonHitTest has
  // been called and returned TRUE.
  vBtnRect := ButtonRect; // So we don't repeatedly call GetButtonRect
  i := 0;
  if Align in [alLeft, alRight] then
  begin
    for b := High(TEvsWindowsButton) downto Low(TEvsWindowsButton) do
      if b in WindowsButtons then
      begin
        vWinButton[i] := b;
        inc(i);
      end;
  end
  else
    for b := Low(TEvsWindowsButton) to High(TEvsWindowsButton) do
      if b in WindowsButtons then
      begin
        vWinButton[i] := b;
        inc(i);
      end;

  if Align in [alLeft, alRight] then
    vBW := vBtnRect.Right - vBtnRect.Left
  else
    vBW := vBtnRect.Bottom - vBtnRect.Top;
  FillChar(vBRs, SizeOf(vBRs), 0);
  for i := 0 to VisibleWinButtons - 1 do
    if ((Align in [alLeft, alRight]) and PtInRect(Bounds(vBtnRect.Left,
      vBtnRect.Top + (vBW * i), vBW, vBW), Point(X, Y))) or ((Align in [alTop,
      alBottom]) and PtInRect(Bounds(vBtnRect.Left + (vBW * i), vBtnRect.Top, vBW,
      vBW), Point(X, Y))) then
    begin
      Result := vWinButton[i];
      break;
    end;
end;

function TEvsSplitter.ButtonHitTest(X, Y: integer): boolean;
begin
  // We use FLastKnownButtonRect here so that we don't have to recalculate the
  // button rect with GetButtonRect every time the mouse moved.  That would be
  // EXTREMELY inefficient.
  Result := PtInRect(FLastKnownButtonRect, Point(X, Y));
  if Align in [alLeft, alRight] then
  begin
    if (not AllowDrag) or ((Y >= FLastKnownButtonRect.Top) and
      (Y <= FLastKnownButtonRect.Bottom)) then
      Cursor := FButtonCursor
    else
      Cursor := crHSplit;
  end else begin
    if (not AllowDrag) or ((X >= FLastKnownButtonRect.Left) and
      (X <= FLastKnownButtonRect.Right)) then
      Cursor := FButtonCursor
    else
      Cursor := crVSplit;
  end;
end;

procedure TEvsSplitter.DoMaximize;
begin
  if assigned(FOnMaximize) then
    FOnMaximize(Self);
end;


procedure TEvsSplitter.DoRestore;
begin
  if assigned(FOnRestore) then
    FOnRestore(Self);
end;

//DoClose

procedure TEvsSplitter.SetMaximized(const aValue: boolean);
begin
  if aValue <> FMaximized then
  begin

    if csLoading in ComponentState then
    begin
      FMaximized := aValue;
      exit;
    end;

    FindControl;
    if FControl = NIL then
      exit;

    if aValue then
    begin
      if FMinimized then
        FMinimized := FALSE
      else
      begin
        case Align of
          alLeft,
          alRight:  FRestorePos := FControl.Width;
          alTop,
          alBottom: FRestorePos := FControl.Height;
        else
          exit;
        end;
      end;
      if ButtonStyle = bsNetscape then
        UpdateControlSize(-3000)
      else
        case Align of
          alLeft,
          alBottom: UpdateControlSize(3000);
          alRight,
          alTop: UpdateControlSize(-3000);
        else
          exit;
        end;
      FMaximized := aValue;
      DoMaximize;
    end
    else
    begin
      UpdateControlSize(FRestorePos);
      FMaximized := aValue;
      DoRestore;
    end;
  end;
end;

procedure TEvsSplitter.SetMinimized(const aValue: boolean);
begin
  if aValue <> FMinimized then
  begin

    if csLoading in ComponentState then
    begin
      FMinimized := aValue;
      exit;
    end;

    FindControl;
    if FControl = NIL then
      exit;

    if aValue then
    begin
      if FMaximized then
        FMaximized := FALSE
      else
      begin
        case Align of
          alLeft,
          alRight:  FRestorePos := FControl.Width;
          alTop,
          alBottom: FRestorePos := FControl.Height;
        else
          exit;
        end;
      end;
      FMinimized := aValue;
      // Just use something insanely large to get it to move to the other extreme
      case Align of
        alLeft,
        alBottom: UpdateControlSize(-3000);
        alRight,
        alTop: UpdateControlSize(3000);
      else
        exit;
      end;
      DoMinimize;
    end
    else
    begin
      FMinimized := aValue;
      UpdateControlSize(FRestorePos);
      DoRestore;
    end;
  end;
end;

function TEvsSplitter.GetAlign: TAlign;
begin
  Result := inherited Align;
end;

procedure TEvsSplitter.SetAlign(const aValue : TAlign);
begin
  inherited Align := aValue;

  Invalidate; // Direction changing, redraw arrows.
  //{$IFNDEF DFS_COMPILER_4_UP}
  //// D4 does this already
  //if (Cursor <> crVSplit) and (Cursor <> crHSplit) then Exit;
  //if Align in [alBottom, alTop] then
  //  Cursor := crVSplit
  //else
  //  Cursor := crHSplit;
  //{$ENDIF}
end;


procedure TEvsSplitter.FindControl;
var
  P: TPoint;
  I: Integer;
  R: TRect;
begin
  if Parent = NIL then
    exit;
  FControl := NIL;
  P := Point(Left, Top);
  case Align of
    alLeft: Dec(P.X);
    alRight: Inc(P.X, Width);
    alTop: Dec(P.Y);
    alBottom: Inc(P.Y, Height);
  else
    Exit;
  end;
  for I := 0 to Parent.ControlCount - 1 do
  begin
    FControl := Parent.Controls[I];
    if FControl.Visible and FControl.Enabled then
    begin
      R := FControl.BoundsRect;
      if (R.Right - R.Left) = 0 then
        Dec(R.Left);
      if (R.Bottom - R.Top) = 0 then
        Dec(R.Top);
      if PtInRect(R, P) then
        Exit;
    end;
  end;
  FControl := NIL;
end;


procedure TEvsSplitter.UpdateControlSize(NewSize: integer);
begin
  if (FControl <> NIL) then
  begin
    case Align of
      alLeft   : SetSplitterPosition(FControl.Left + NewSize); //MoveViaMouse(Left, FControl.Left + NewSize, TRUE);
      alTop    : SetSplitterPosition(FControl.Top + NewSize); //MoveViaMouse(Top, FControl.Top + NewSize, FALSE);
      alRight  : SetSplitterPosition((FControl.Left + FControl.Width - Width) - NewSize); //MoveViaMouse(Left, (FControl.Left + FControl.Width - Width) - NewSize, TRUE);
      alBottom : SetSplitterPosition((FControl.Top + FControl.Height - Height) - NewSize); //MoveViaMouse(Top, (FControl.Top + FControl.Height - Height) - NewSize, FALSE);
    end;
    Update;
  end;
end;

procedure TEvsSplitter.SetArrowColor(const Value: TColor);
begin
  if FArrowColor <> Value then
  begin
    FArrowColor := Value;
    if (ButtonStyle = bsNetscape) and ShowButton then
      Invalidate;
  end;
end;

procedure TEvsSplitter.SetButtonColor(const Value: TColor);
begin
  if FButtonColor <> Value then
  begin
    FButtonColor := Value;
    if (ButtonStyle = bsNetscape) and ShowButton then
      Invalidate;
  end;
end;

procedure TEvsSplitter.SetButtonHighlightColor(const Value: TColor);
begin
  if FButtonHighlightColor <> Value then
  begin
    FButtonHighlightColor := Value;
    if (ButtonStyle = bsNetscape) and ShowButton then
      Invalidate;
  end;
end;

procedure TEvsSplitter.SetAutoHighlightColor(const Value: boolean);
begin
  if FAutoHighLightColor <> Value then
  begin
    FAutoHighLightColor := Value;
    if FAutoHighLightColor then
      FButtonHighLightColor := GrabBarColor
    else
      FButtonHighLightColor := DEF_BUTTON_HIGHLIGHT_COLOR;
    if (ButtonStyle = bsNetscape) and ShowButton then
      Invalidate;
  end;
end;

procedure TEvsSplitter.SetTextureColor1(const Value: TColor);
begin
  if FTextureColor1 <> Value then
  begin
    FTextureColor1 := Value;
    if (ButtonStyle = bsNetscape) and ShowButton then
      Invalidate;
  end;
end;

procedure TEvsSplitter.SetTextureColor2(const Value: TColor);
begin
  if FTextureColor2 <> Value then
  begin
    FTextureColor2 := Value;
    if (ButtonStyle = bsNetscape) and ShowButton then
      Invalidate;
  end;
end;

procedure TEvsSplitter.Loaded;
begin
  inherited Loaded;
  if FRestorePos = -1 then
  begin
    FindControl;
    if FControl <> NIL then
      case Align of
        alLeft,
        alRight:  FRestorePos := FControl.Width;
        alTop,
        alBottom: FRestorePos := FControl.Height;
      end;
  end;
end;

procedure TEvsSplitter.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
  if FRestorePos < 0 then
  begin
    FindControl;
    if FControl <> NIL then
      case Align of
        alLeft,
        alRight:  FRestorePos := FControl.Width;
        alTop,
        alBottom: FRestorePos := FControl.Height;
      end;
  end;
end;

procedure TEvsSplitter.SetAllowDrag(const Value: boolean);
var
  Pt: TPoint;
begin
  if FAllowDrag <> Value then
  begin
    FAllowDrag := Value;
    // Have to reset cursor in case it's on the splitter at the moment
    GetCursorPos(Pt);
    Pt := ScreenToClient(Pt);
    ButtonHitTest(Pt.x, Pt.y);
  end;
end;

function TEvsSplitter.VisibleWinButtons: integer;
var
  x: TEvsWindowsButton;
begin
  Result := 0;
  for x := Low(TEvsWindowsButton) to High(TEvsWindowsButton) do
    if x in WindowsButtons then
      inc(Result);
end;

procedure TEvsSplitter.SetButtonStyle(const Value: TEvsButtonStyle);
begin
  FButtonStyle := Value;
  if ShowButton then
    Invalidate;
end;

procedure TEvsSplitter.SetWindowsButtons(const Value: TEvsWindowsButtons);
begin
  FWindowsButtons := Value;
  if (ButtonStyle = bsWindows) and ShowButton then
    Invalidate;
end;

procedure TEvsSplitter.DoMinimize;
begin
  if assigned(FOnMinimize) then
    FOnMinimize(Self);
end;

procedure TEvsSplitter.DoClose;
begin
  if Assigned(FOnClose) then
    FOnClose(Self);
end;

procedure TEvsSplitter.SetButtonCursor(const Value: TCursor);
begin
  FButtonCursor := Value;
end;

procedure TEvsSplitter.LoadOtherProperties(Reader: TReader);
begin
  RestorePos := Reader.ReadInteger;
end;


procedure TEvsSplitter.StoreOtherProperties(Writer: TWriter);
begin
  Writer.WriteInteger(RestorePos);
end;

procedure TEvsSplitter.DefineProperties(Filer: TFiler);
begin
  inherited;
  Filer.DefineProperty('RestorePos', @LoadOtherProperties, @StoreOtherProperties,
    Minimized or Maximized);
end;

end.

