{------------------------------------------------------------------------------
  TEvsSimpleGraph is a port of TSimpleGraph 2.8 to Freepascal and lazarus.
  I have eliminated a number of properties and methods that I felt that have no
  usefulnes other of perhaps eye candy. In no perticula order

  TMemoryHandleStream -- used exclusively to copying from and to the clipboard\
                         NOT USED on lazarus.

  TMetafile           -- since metafile is windows specific I removed it from the code.

  TEvsSimpleGraph.........................
  GetAsMetafile       -- no metafile class so this got booted.
  Transparent         -- removed the property there is no need for a transparent
                         graph editor.
  WMWindowPosChanging -- it had transparent specific code only. Removed.
  wmPaint             -- Since the override does not really override the ancestor
                         methods there was no reason to keep it. the code in a form
                         or an other is still there and can be enabled with a define
                         I keep it as a testing ground when I try to find other ways
                         of doing things in a more cross platform way. For a release
                         software this should be removed.

  WMPrint             -- This uses a lot of code that has no binding in lclintf it
                         will be removed, and replaced by the print method.
  print               -- has to be tested it makes assumption about the Paint structure data
                         that are not true in freepascal. Since it uses Tcanvas to print
                         it should be easy to test.
  TransformRgn        -- Has no alternative outside windows. Needs to be replaced or removed.
                           This and the abilities the code is using can be replicated on QT and GTK2
                           but I do not see any support for them in lcl and I have to dig down to the api level.
                           QT4Pas does not surface the call to return the region rectangles so I am stack there
                           Need to ask for help on the forums/lists.
                           GTK2 headers probably have the required apis but I haven't spend to much
                           time looking at this point.
  TGraphScrollBar     -- Needs to eliminate all calls to flatSB api.
                         -- FlatSB api removed.
                            All scroll related bugshave been ironed out it should
                            work all 3 platforms.
                         -- On platforms Qt, GTK2 there is no autoscrolling when the mouse
                            reaches the screen edges I need to investigate why.
                         -- The scroll in to view does not work either. I need to check it.

  Zooming             -- zoom does not work.
                         although it has no meaningful usage inside the designer
                         it can be used to create an overview window and to stretch
                         a design for printing. Needs to  be implemented in the
                         long run but I'm thinking on removing it for the 1st release.

                      -- Use the mouse wheel to zoom.

  Background          -- There are a number of problems with the background it
                         will be removed for the first version and be re enabled
                         after the first release. Make sure to support it on loading
                         from the original authors files discarding the contents.

  HitTest             -- Its used to select the mouse cursor to show the various
                         modes there are problems with the current implementation.

                      All problems solved except one GTK does not support ptInRegion
                      it always returns false. I need to either re-enable it my self
                      or file a bug report on the bug tracker.
-----------------------------------------------------------------------------------------------------------

 ENHANCEMENTS

   TGraphObjectList   -- Change the behavior from an array based list to a double
                         linked list.
   TGraphLayer        -- Add support for layers
                         1) Maintain a seperate list of object on each layer.
                         2) Maintain a top/bottom index for the object in each layer.
                         3) Encapsulating the Graphlist  inside each layer
                            changing simpleGraph to hold a list of layers only.
                            Requires to change the properties that access objects
                            by index and the count property.

   Regions            -- regions are here to stay. I'm not going to give up on
                         that speed for something else for now.

   TextDraw           -- Extend existing canvas with extra methods for text manipulation
                         make sure that they can be used for most widgsets.
                         Must support
                         -- Rotation    : in any angle (floating point) around
                                          any random center.
                         -- alignment   : Any kind of alignment that windows support
                                          including RTL placement.
                         -- Measurement : Retreive the most used measurements for
                                          the selected font style and alignment.
                                          eg rect, width, height etc of the formated
                                          text. Even if that means it has to be rendered
                                          on an invisible canvas and retrieve the
                                          info from there.

  Clipboard support for metafile images has been removed.

  ORIGINAL AUTHOR
------------------------------------------------------------------------------
  TSimpleGraph v2.80
  by Kambiz R. Khojasteh

  kambiz@delphiarea.com
  http://www.delphiarea.com
------------------------------------------------------------------------------}

unit usimplegraph;
{$mode objfpc}
{.$MODE DELPHI}
{$H+}

interface

//{$MESSAGE HINT|WARN|ERROR|FATAL 'text string' }. a small reminder.
//The following Define is for testing purposes to see what needs to be converted
//from windows specific code
{$IFDEF LCLWIN32}
{$DEFINE WIN}
{$ENDIF}


{$DEFINE CANVAS_TEXTDRAW} //replace the api calls with canvas only calls

{$DEFINE SUBCLASS} // required for the scroll bars to work correctly.


{.$DEFINE DBGFRM} // replace with fpc debug units and remove dependency.
{$IFDEF DBGFRM}
{$ENDIF}

{$IFDEF WIN}
  {.$DEFINE METAFILE_SUPPORT}
  {$DEFINE WIN_TRANSFORM}  //required for windows it speeds things up considerably.
{$ENDIF}

uses
  Classes, SysUtils, Types, Controls, Forms, Menus, LMessages,
  LCLIntf, LCLType, LCLProc, GraphType, Graphics
  {$IFDEF WIN        } ,Windows   {$ENDIF}
  {$IFDEF DBGFRM     } ,UFrmDebug {$ENDIF}
  ;

{%REGION Const}
const
  // Custom Cursors
  crHandFlat  = 51;
  crHandGrab  = 52;
  crHandPnt   = 53;
  crXHair1    = 54;
  crXHair2    = 55;
  crXHair3    = 56;
  crXHairLink = 57;

  // Default Graph Hit Test Flags
  GHT_NOWHERE     = $00000000;
  GHT_TRANSPARENT = $00000001;
  GHT_LEFT        = $00000002;
  GHT_TOP         = $00000004;
  GHT_RIGHT       = $00000008;
  GHT_BOTTOM      = $00000010;
  GHT_TOPLEFT     = $00000020;
  GHT_TOPRIGHT    = $00000040;
  GHT_BOTTOMLEFT  = $00000080;
  GHT_BOTTOMRIGHT = $00000100;
  GHT_CLIENT      = $00000200;
  GHT_CAPTION     = $00000400;
  GHT_POINT       = $00000800;  // High word contains the point's index
  GHT_LINE        = $00001000;  // High word contains the line's index

  GHT_BODY_MASK   = GHT_CLIENT or GHT_CAPTION;
  GHT_SIDES_MASK  = GHT_LEFT or GHT_TOP or GHT_RIGHT or GHT_BOTTOM or
                    GHT_TOPLEFT or GHT_TOPRIGHT or GHT_BOTTOMLEFT or
                    GHT_BOTTOMRIGHT;


{$IFDEF FPC}

  ETO_RTLREADING       = 128;  //needed

{$ENDIF}
{%ENDREGION}

type
  TEvsSimpleGraph     = class;
  TEvsGraphObjectList = class;
  TEvsGraphObject     = class;
  TEvsGraphLink       = class;
  TEvsGraphNode       = class;
  TEvsGraphLayer      = class;
  TEvsGraphCanvas     = class;
  TCanvasClass        = class of TCanvas;

  TPoints                   = array of TPoint;
  EEvsGraphStreamError      = class(EStreamError);
  EEvsGraphInvalidOperation = class(EInvalidOperation);
  EEvsPointListError        = class(EListError);

  TGridSize   = 4..128;
  TMarkerSize = 3..9;
  TZoom       = 5..36863;

  TEvsObjectSide = (osLeft, osTop, osRight, osBottom);
  TEvsObjectSides = set of TEvsObjectSide;

  TEvsGraphObjectListAction = (glAdded, glRemoved, glReordered);

  TEvsGraphObjectListEvent = procedure(Sender: TObject; GraphObject: TEvsGraphObject;
    Action: TEvsGraphObjectListAction) of object;

  TListEnumState = record
    Current : integer;
    Dir     : integer;
  end;

  {$IFDEF FPC}
  TWMPrint = packed record
    Msg: Cardinal;
    DC: HDC;
    Flags: Cardinal;
    Result: Integer;
  end;

  TWMPrintClient = TWMPrint;
  {$ENDIF}

{$IFNDEF WIN}
  {$MESSAGE WARN 'Region Specific structures copied from windows unit'}
  XFORM = record
    eM11 : Single;
    eM12 : Single;
    eM21 : Single;
    eM22 : Single;
    eDx  : Single;
    eDy  : Single;
  end;
  LPXFORM = ^XFORM;
  _XFORM = XFORM;
  TXFORM = XFORM;
  PXFORM = ^XFORM;
{$ENDIF}

  TEvsGraphObjectState = (osCreating, osDestroying, osLoading, osReading, osWriting,
    osUpdating, osDragging, osDragDisabled, osConverting);
  TEvsGraphObjectStates = set of TEvsGraphObjectState;

  TEvsGraphChangeFlag = (gcView, gcData, gcText, gcPlacement, gcDependency);
  TEvsGraphChangeFlags = set of TEvsGraphChangeFlag;

  TEvsGraphDependencyChangeFlag = (gdcChanged, gdcRemoved);

  TEvsGraphObjectOption = (goLinkable, goSelectable, goShowCaption);
  TEvsGraphObjectOptions = set of TEvsGraphObjectOption;

  TEvsGraphLinkOption = (gloFixedStartPoint, gloFixedEndPoint, gloFixedBreakPoints,
    gloFixedAnchorStartPoint, gloFixedAnchorEndPoint);
  TEvsGraphLinkOptions = set of TEvsGraphLinkOption;

  TEvsLinkBeginEndStyle = (lsNone, lsArrow, lsArrowSimple, lsCircle, lsDiamond);

  TEvsLinkNormalizeOptions = set of (lnoDeleteSamePoint, lnoDeleteSameAngle);

  TEvsLinkChangeMode = (lcmNone, lcmInsertPoint, lcmRemovePoint, lcmMovePoint,
    lcmMovePolyline);

  TEvsGraphNodeOption = (gnoMovable, gnoResizable, gnoShowBackground);
  TEvsGraphNodeOptions = set of TEvsGraphNodeOption;

  TEvsGraphBoundsKind = (bkGraph, bkSelected, bkDragging);

  TEvsGraphCommandMode = (cmViewOnly, cmPan, cmEdit, cmInsertNode, cmInsertLink);

  TEvsGraphDrawOrder = (doDefault, doNodesOnTop, doLinksOnTop);

  TEvsGraphClipboardFormat = (cfNative, cfMetafile, cfBitmap);
  TEvsGraphClipboardFormats = set of TEvsGraphClipboardFormat;

  TEvsGraphZoomOrigin = (zoTopLeft, zoCenter, zoCursor, zoCursorCenter);

  TEvsHAlignOption = (haNoChange, haLeft, haCenter, haRight, haSpaceEqually);
  TEvsVAlignOption = (vaNoChange, vaTop, vaCenter, vaBottom, vaSpaceEqually);

  TEvsResizeOption = (roNoChange, roSmallest, roLargest);

  TEvsGraphNotifyEvent       = procedure(Graph: TEvsSimpleGraph; GraphObject: TEvsGraphObject) of object;
  TEvsGraphContextPopupEvent = procedure(Graph: TEvsSimpleGraph;
                                         GraphObject: TEvsGraphObject;
                                         const MousePos: TPoint;
                                         var Handled: boolean) of object;
  TEvsGraphDrawEvent         = procedure(Graph: TEvsSimpleGraph; Canvas: TCanvas) of object;
  TEvsGraphObjectDrawEvent   = procedure(Graph: TEvsSimpleGraph; GraphObject: TEvsGraphObject;
                                         Canvas: TCanvas) of object;
  TEvsGraphInfoTipEvent      = procedure(Graph: TEvsSimpleGraph; GraphObject: TEvsGraphObject;
                                         var InfoTip: string) of object;
  TEvsGraphHookEvent         = procedure(Graph: TEvsSimpleGraph; GraphObject: TEvsGraphObject;
                                         Link: TEvsGraphLink; Index: integer) of object;
  TEvsGraphCanHookEvent      = procedure(Graph: TEvsSimpleGraph; GraphObject: TEvsGraphObject;
                                         Link: TEvsGraphLink; Index: integer; var CanHook: boolean) of object;
  TEvsGraphCanLinkEvent      = procedure(Graph: TEvsSimpleGraph; Link: TEvsGraphLink;
                                         Source, Target: TEvsGraphObject; var CanLink: boolean) of object;
  TEvsCanMoveResizeNodeEvent = procedure(Graph: TEvsSimpleGraph; Node: TEvsGraphNode;
                                         var NewLeft, NewTop, NewWidth, NewHeight: integer;
                                         var CanMove, CanResize: boolean) of object;
  TEvsGraphNodeResizeEvent   = procedure(Graph: TEvsSimpleGraph; Node: TEvsGraphNode) of object;
  TEvsGraphCanRemoveEvent    = procedure(Graph: TEvsSimpleGraph; GraphObject: TEvsGraphObject;
                                         var CanRemove: boolean) of object;
  TEvsGraphBeginDragEvent    = procedure(Graph: TEvsSimpleGraph; GraphObject: TEvsGraphObject;
                                         HT: DWORD) of object;
  TEvsGraphEndDragEvent      = procedure(Graph: TEvsSimpleGraph; GraphObject: TEvsGraphObject;
                                         HT: DWORD; Cancelled: boolean) of object;
  TEvsGraphStreamEvent       = procedure(Graph: TEvsSimpleGraph; GraphObject: TEvsGraphObject;
                                         Stream: TStream) of object;

  TEvsGraphForEachMethod     = function(GraphObject: TEvsGraphObject;
                                        UserData: integer): boolean of object;

  TEvsGraphObjectClass = class of TEvsGraphObject;
  TEvsGraphNodeClass   = class of TEvsGraphNode;
  TEvsGraphLinkClass   = class of TEvsGraphLink;
  TEvsGraphLayerClass  = class of TEvsGraphLayer;
  TEvsGraphCanvasClass = class of TEvsGraphCanvas;

  TEvsCanvasRecall = class(TObject)          // TEST DIF BETWEEN TEXTSTYLE AND TEXTFLAG.
  private
    fPen: TPen;
    fFont: TFont;
    fBrush: TBrush;
    fCopyMode: TCopyMode;
    fTextFlags: TTextStyle;// integer;
    fReference: TCanvas;
    procedure SetReference(Value: TCanvas);
  public
    constructor Create(AReference: TCanvas);
    destructor Destroy; override;
    procedure Store;
    procedure Retrieve;
    property Reference: TCanvas read fReference write SetReference;
  end;

  { TEvsPenRecall }
  TEvsPenRecall = class
  private
    FBackup    : TPen;
    FReference : TPen;
    procedure SetReference(aValue:TPen);
  public
    constructor Create(AReference: TPen);
    destructor Destroy; override;
    procedure Store;
    procedure Retrieve;
    property Reference: TPen read fReference write SetReference;
  end;

  { TEvsBrushRecall }
  TEvsBrushRecall = class
  private
    FBackup    : TBrush;
    FReference : TBrush;
    procedure SetReference(aValue : TBrush);
  public
    constructor Create(AReference: TBrush);
    destructor Destroy; override;
    procedure Store;
    procedure Retrieve;
    property Reference: TBrush read fReference write SetReference;
  end;

  { TEvsCompatibleCanvas }
  TEvsCompatibleCanvas = class(TCanvas)               //WORKS
   public
     constructor Create;                            //CreateCompatibleDC -- MAPS TO LCLINTF
     destructor Destroy; override;
   end;



  TEvsGraphStreamableObject = class(TComponent)       //CLEAN
  private
    fID: DWORD;
    fG: TEvsGraphObject;
    fDummy: integer;
  published
    property ID: DWORD read fID write fID;
    property G: TEvsGraphObject read fG write fG stored True;
    property Left: integer read fDummy write fDummy stored False;
    property Top: integer read fDummy write fDummy stored False;
    property Tag stored False;
    property Name stored False;
  end;

  { TEvsCustomCanvas }

  TEvsCustomCanvas = class(TCanvas)
  private
    FOffsetX : Double;
    FOffsetY : Double;
    FScaleX  : Double;
    FScaleY  : Double;
    procedure SetOffsetX(aValue : Double);
    procedure SetOffsetY(aValue : Double);
    procedure SetScaleX (aValue : Double);
    procedure SetScaleY (aValue : Double);
  protected
    // Those two procedures do not get the translated coordinates if overriden
    // must be translated before doing any drawing.
    procedure DoMoveTo(x, y : integer);                                                                                 override;
    procedure DoLine(x1, y1, x2, y2 : integer);                                                                         override;


    procedure DoArc(ALeft, ATop, ARight, ABottom, Angle16Deg, Angle16DegLength: Integer);                               virtual;
    procedure DoArc(ALeft, ATop, ARight, ABottom, SX, SY, EX, EY: Integer);                                             virtual;
    procedure DoBrushCopy (ADestRect: TRect; ABitmap: Graphics.TBitmap; ASourceRect: TRect; ATransparentColor: TColor); virtual;
    procedure DoChord     (X1, Y1, X2, Y2, Angle16Deg, Angle16DegLength: Integer);                                      virtual;overload;
    procedure DoChord     (X1, Y1, X2, Y2, SX, SY, EX, EY: Integer);                                                    virtual;overload;
    procedure DoCopyRect  (const Dest: TRect; SrcCanvas: TCanvas; const Source: TRect);                                 virtual;
    procedure DoDraw      (X,Y: Integer; SrcGraphic: TGraphic);                                                         virtual;
    procedure DoDrawFocusRect(const ARect: TRect);                                                                      virtual;
    procedure DoStretchDraw  (const DestRect: TRect; SrcGraphic: TGraphic);                                             virtual;
    procedure DoEllipse      (x1, y1, x2, y2: Integer);                                                                 virtual;
    procedure DoFillRect     (const ARect: TRect);                                                                      virtual;
    procedure DoFloodFill    (X, Y: Integer; FillColor: TColor; FillStyle: TFillStyle);                                 virtual;
    procedure DoFrame3d      (var ARect: TRect; const FrameWidth: integer; const Style: TGraphicsBevelCut);             virtual;
    procedure DoFrame        (const ARect: TRect);                                                                      virtual;
    procedure DoFrameRect    (const ARect: TRect);                                                                      virtual;
    procedure DoGradientFill (ARect: TRect; AStart, AStop: TColor; ADirection: TGradientDirection);                     virtual;
    procedure DoRadialPie    (X1, Y1, X2, Y2, StartAngle16Deg, Angle16DegLength: Integer);                              override;
    procedure DoPie          (EllipseX1,EllipseY1,EllipseX2,EllipseY2,StartX,StartY,EndX,EndY: Integer);                virtual;
    procedure DoRectangle    (X1,Y1,X2,Y2: Integer);                                                                    virtual;
    procedure DoRoundRect    (X1, Y1, X2, Y2: Integer; RX,RY: Integer);                                                 virtual;
    procedure DoTextOut      (X,Y: Integer; const Text: String);                                                        virtual;
    procedure DoTextRect     (ARect: TRect; X, Y: integer; const Text: string;const Style: TTextStyle);                 virtual;
    procedure DoPolyBezier(Points: PPoint; NumPts: Integer; Filled : boolean = False;Continuous: boolean = False);      override;
    procedure DoPolygon   (Points: PPoint; NumPts: Integer; Winding: boolean = False);                                  virtual;
    procedure DoPolyline  (Points: PPoint; NumPts: Integer);                                                            virtual;

    procedure TranslateCoordinates(var InCoords : Array of TPOINT);           virtual; overload;
    procedure TranslateCoordinates(var InCoords : PPOINT; NumPoints:Integer); virtual; overload;
  public
    procedure Arc          (ALeft, ATop, ARight, ABottom, Angle16Deg, Angle16DegLength: Integer);                        override;
    procedure Arc          (ALeft, ATop, ARight, ABottom, SX, SY, EX, EY: Integer);                                      override;
    procedure BrushCopy    (ADestRect: TRect; ABitmap: Graphics.TBitmap; ASourceRect: TRect; ATransparentColor: TColor); override;
    procedure Chord        (x1, y1, x2, y2, Angle16Deg, Angle16DegLength: Integer);                                      override;
    procedure Chord        (x1, y1, x2, y2, SX, SY, EX, EY: Integer);                                                    override;
    procedure CopyRect     (const Dest: TRect; SrcCanvas: TCanvas; const Source: TRect);                                 override;
    procedure Draw         (X,Y: Integer; SrcGraphic: TGraphic);                                                         override;
    procedure DrawFocusRect(const ARect: TRect);                                                                         override;
    procedure StretchDraw  (const DestRect: TRect; SrcGraphic: TGraphic);                                                override;
    procedure Ellipse      (x1, y1, x2, y2: Integer);                                                                    override;
    procedure FillRect     (const ARect: TRect);                                                                         override;
    procedure FloodFill    (X, Y: Integer; FillColor: TColor; FillStyle: TFillStyle);                                    override;
    procedure Frame3d      (var ARect: TRect; const FrameWidth: integer; const Style: TGraphicsBevelCut);                override;
    procedure Frame        (const ARect: TRect);                                                                         override;
    procedure FrameRect    (const ARect: TRect);                                                                         override;
    procedure GradientFill (ARect: TRect; AStart, AStop: TColor; ADirection: TGradientDirection);
    procedure RadialPie    (x1, y1, x2, y2, StartAngle16Deg, Angle16DegLength: Integer);                                 override;
    procedure Pie          (EllipseX1,EllipseY1,EllipseX2,EllipseY2,StartX,StartY,EndX,EndY: Integer);                   override;
    procedure Rectangle    (X1,Y1,X2,Y2: Integer);                                                                       override;
    procedure RoundRect    (X1, Y1, X2, Y2: Integer; RX,RY: Integer);                                                    override;
    procedure TextOut      (X,Y: Integer; const Text: String);                                                           override;
    procedure TextRect     (ARect: TRect; X, Y: integer; const Text: string;const Style: TTextStyle);                    override;

    procedure PolyBezier(Points: PPoint; NumPts: Integer; Filled : boolean = False;Continuous: boolean = False);         override;
    procedure Polygon   (Points: PPoint; NumPts: Integer; Winding: boolean = False);                                     override;
    procedure Polyline  (Points: PPoint; NumPts: Integer);                                                               override;
  public
    constructor Create;
    procedure SetTransformation(XScale, YScale, DX, DY : Double); virtual;
    procedure ClearTransformation; virtual;
  public
    property OffsetX : Double  read FOffsetX write SetOffsetX;
    property OffsetY : Double  read FOffsetY write SetOffsetY;
    property ScaleX  : Double  read FScaleX  write SetScaleX;
    property ScaleY  : Double  read FScaleY  write SetScaleY;
  end;
  //{$INTERFACE CORBA}
  //IEvsCoordinateTranslation = interface
  //  ['{D173501F-C8D5-4FE6-80DE-1F0FF958BB37}']
  //  procedure SetOffset(constref aOffSetX:Double; constref aOffSetY:Double);
  //  procedure SetScale(constref aScaleX:Double; constref aScaleY:Double);
  //end;
  //
  { TEvsGraphCanvas }

  TEvsGraphCanvas = class(TControlCanvas) //add extra functionality  to existing canvas and use different renderers as well eg(GDI+)
  private
    FOffsetX : Double;
    FOffsetY : Double;
    FScaleX  : Double;
    FScaleY  : Double;
    procedure SetOffsetX(aValue : Double);
    procedure SetOffsetY(aValue : Double);
    procedure SetScaleX (aValue : Double);
    procedure SetScaleY (aValue : Double);
  protected
    procedure TranslateCoordinates(var InCoords : Array of TPOINT);           virtual; overload;
    procedure TranslateCoordinates(var InCoords : PPOINT; NumPoints:Integer); virtual; overload;
    function TranslatePoints(const InCoords:PPOINT; aNumPts:Integer):PPOINT;
    procedure DoMoveTo(x, y : integer); override;
    procedure DoLineTo(x, y : integer); override;
    procedure DoLine(x1, y1, x2, y2: integer); override;
  public

    procedure Arc          (ALeft, ATop, ARight, ABottom, Angle16Deg, Angle16DegLength: Integer);                        override;
    procedure Arc          (ALeft, ATop, ARight, ABottom, SX, SY, EX, EY: Integer);                                      override;
    procedure BrushCopy    (ADestRect: TRect; ABitmap: Graphics.TBitmap; ASourceRect: TRect; ATransparentColor: TColor); override;
    procedure Chord        (x1, y1, x2, y2, Angle16Deg, Angle16DegLength: Integer);                                      override;
    procedure Chord        (x1, y1, x2, y2, SX, SY, EX, EY: Integer);                                                    override;
    procedure CopyRect     (const Dest: TRect; SrcCanvas: TCanvas; const Source: TRect);                                 override;
    procedure Draw         (X,Y: Integer; SrcGraphic: TGraphic);                                                         override;
    procedure DrawFocusRect(const ARect: TRect);                                                                         override;
    procedure StretchDraw  (const DestRect: TRect; SrcGraphic: TGraphic);                                                override;
    procedure Ellipse      (x1, y1, x2, y2: Integer);                                                                    override;
    procedure FillRect     (const ARect: TRect);                                                                         override;
    procedure FloodFill    (X, Y: Integer; FillColor: TColor; FillStyle: TFillStyle);                                    override;
    procedure Frame3d      (var ARect: TRect; const FrameWidth: integer; const Style: TGraphicsBevelCut);                override;
    procedure Frame        (const ARect: TRect);                                                                         override;
    procedure FrameRect    (const ARect: TRect);                                                                         override;
    procedure GradientFill (ARect: TRect; AStart, AStop: TColor; ADirection: TGradientDirection);
    procedure RadialPie    (x1, y1, x2, y2, StartAngle16Deg, Angle16DegLength: Integer);                                 override;
    procedure Pie          (EllipseX1,EllipseY1,EllipseX2,EllipseY2,StartX,StartY,EndX,EndY: Integer);                   override;
    procedure Rectangle    (X1,Y1,X2,Y2: Integer);                                                                       override;
    procedure RoundRect    (X1, Y1, X2, Y2: Integer; RX,RY: Integer);                                                    override;
    procedure TextOut      (X,Y: Integer; const Text: String);                                                           override;
    procedure TextRect     (ARect: TRect; X, Y: integer; const Text: string;const Style: TTextStyle);                    override;

    procedure PolyBezier(Points: PPoint; NumPts: Integer; Filled : boolean = False;Continuous: boolean = False);         override;
    procedure Polygon   (Points: PPoint; NumPts: Integer; Winding: boolean = False);                                     override;
    procedure Polyline  (Points: PPoint; NumPts: Integer);                                                               override;
  public
    constructor Create;virtual;overload;
    constructor Create(aCanvas:TCanvas);Virtual;overload;
    property OffsetX : Double  read FOffsetX write SetOffsetX;
    property OffsetY : Double  read FOffsetY write SetOffsetY;
    property ScaleX  : Double  read FScaleX  write SetScaleX;
    property ScaleY  : Double  read FScaleY  write SetScaleY;
  end;


  { TEvsGraphLayer }
  // a layer keeps track only the top, bottom indexies in the graphlist
  TEvsGraphLayer = class(TPersistent)    //under heavy construction.
  private
    FBottom,
    FTop      : Integer;
    FName     : String;
    FID       : Integer;
    FLocked   : Boolean;
    FPrintable: Boolean;
    FVisible  : Boolean;
    function GetCount: Integer;
    procedure SetID(AValue: Integer);
    procedure SetLocked(AValue: Boolean);
    procedure SetPrintable(AValue: Boolean);
    procedure SetVisible(AValue: Boolean);
  protected
    function CanAdd(const aObject:TEvsGraphObject):Boolean;
    function CanRemove(const aObject:TevsGraphObject):Boolean;
    procedure SlideUp(Count:Integer);
    procedure SlideDown(Count:Integer);
    function Add(Const aObject:TEvsGraphObject):Integer;//-1 unable to add, >-1 the object's new ZOrder
    procedure Remove(const OldZOrder,NewZOrder:Integer);
    property Top :Integer read FTOP;
    property Bottom:Integer read FBottom;
    property Count : Integer read GetCount;
    property Name  : String  read FName    write FName;
  public
    property ID        : Integer read FID write SetID;
    property Locked    : Boolean read FLocked write SetLocked;
    Property Printable : Boolean read FPrintable write SetPrintable;
    Property Visible   : Boolean read FVisible write SetVisible;
  end;

  { TEvsGraphLayerList }

  TEvsGraphLayerList = class
  strict private
    FList  : TFPList;
    FLastID: QWord;
    function GetCount: Integer;
    function GetLayer(Index: Integer): TEvsGraphLayer;
  protected
    procedure PackIDs;
    function UniqueName(const prefix :String):String;
    function ByID(const aID:integer):TEvsGraphLayer;
    function ByName(const aName:String):TEvsGraphLayer;
  public
    constructor Create;
    destructor Destroy; override;
    function New : TEvsGraphLayer;
    function Delete(Index :integer):Boolean;overload;
    function Delete(Layer:TEvsGraphLayer):Boolean;overload;
    property Count:Integer Read GetCount;
    property Layers[Index:Integer]:TEvsGraphLayer read GetLayer;
  end;

  TEvsGraphScrollBar = class(TPersistent)                    //NEEDS WORK ON 3 METHODS
  private
    fOwner: TEvsSimpleGraph;
    fIncrement: TScrollBarInc;
    fPageIncrement: TScrollBarInc;
    fPosition: Integer;
    fRange: Integer;
    fCalcRange: Integer;
    fKind: TScrollBarKind;
    fMargin: Word;
    fVisible: Boolean;
    fTracking: Boolean;
    fSmooth: Boolean;
    fDelay: Integer;
    fButtonSize: Integer;
    fColor: TColor;
    fParentColor: Boolean;
    fSize: Integer;
    fStyle: TScrollBarStyle;
    fThumbSize: Integer;
    fPageDiv: Integer;
    fLineDiv: Integer;
    fUpdateNeeded: Boolean;
    FLastMsgPos:Integer;
    procedure DoSetRange(Value: Integer);
    function InternalGetScrollPos: integer;
    procedure SetButtonSize(AValue: integer);
    procedure SetColor(AValue: TColor);
    procedure SetParentColor(Value: boolean);
    procedure SetPosition(AValue: Integer);
    procedure SetSize(Value: integer);                                          //NEEDS WORK
    procedure SetStyle(Value: TScrollBarStyle);
    procedure SetThumbSize(Value: integer);
    procedure SetVisible(AValue: boolean);
    function IsIncrementStored: boolean;
  protected
    constructor Create(AOwner: TEvsSimpleGraph; AKind: TScrollBarKind);
    function ControlSize(ControlSB, AssumeSB: Boolean): Integer;
    procedure CalcAutoRange;
    procedure Update(ControlSB, AssumeSB: Boolean);                             //NEEDS WORK
    function NeedsScrollBarVisible: Boolean;
    procedure ScrollMessage(var Msg: TLMScroll);
  public
    procedure Assign(Source: TPersistent); override;
    procedure ChangeBiDiPosition;
    function IsScrollBarVisible: boolean;                                       //NEEDS WORK
    property Kind: TScrollBarKind read fKind;
    property ScrollPos: integer read InternalGetScrollPos;
    property Range: integer read fRange;
    property Owner: TEvsSimpleGraph read fOwner;
  published
    property Position: Integer read fPosition write SetPosition default 0;
    property Margin: Word read fMargin write fMargin default 0;
    property ButtonSize: integer read fButtonSize write SetButtonSize default 0;
    property Color: TColor read fColor write SetColor default clBtnHighlight;
    property Increment: TScrollBarInc
      read fIncrement write fIncrement stored IsIncrementStored default 8;
    property ParentColor: boolean read fParentColor write SetParentColor default True;
    property Smooth: boolean read fSmooth write fSmooth default False; //JKOZ SMOOTH
    property Size: integer read fSize write SetSize default 0;
    property Style: TScrollBarStyle read fStyle write SetStyle default ssRegular;
    property ThumbSize: integer read fThumbSize write SetThumbSize default 0;
    property Tracking: boolean read fTracking write fTracking default False;
    property Visible: boolean read fVisible write SetVisible default True;
  end;

  TEvsGraphObjectListEnumerator = class
  private
    FGraphList : TEvsGraphObjectList;
    FPosition  : Integer;
  public
    constructor Create(aList: TEvsGraphObjectList);
    function GetCurrent: TEvsGraphObject;
    function MoveNext: Boolean;
    property Current: TEvsGraphObject read GetCurrent;
  end;

  TEvsGraphObjectListReverseEnumerator = class
  private
    FGraphList : TEvsGraphObjectList;
    FPosition  : Integer;
  public
    constructor Create(aList: TEvsGraphObjectList);
    function GetCurrent: TEvsGraphObject;
    function MoveNext: Boolean;
    property Current: TEvsGraphObject read GetCurrent;
  end;

  TEvsGraphObjectList = class(TPersistent)         //CLEAN
  private
    fItems: array of TEvsGraphObject;
    fCount: integer;
    fCapacity: integer;
    fOnChange: TEvsGraphObjectListEvent;
    Enum: TListEnumState;
    EnumStack: array of TListEnumState;
    EnumStackPos: integer;
    procedure SetCapacity(Value: integer);
    function GetItems(Index: integer): TEvsGraphObject;
  protected
    procedure Grow;
    function Replace(OldItem, NewItem: TEvsGraphObject): integer;
    procedure AdjustDeleted(Index: integer; var EnumState: TListEnumState);
    procedure NotifyAction(Item: TEvsGraphObject; Action: TEvsGraphObjectListAction); virtual;
  public
    destructor Destroy; override;
    procedure Clear;
    function GetEnumerator: TEvsGraphObjectListEnumerator;
    function GetReverseEnumerator: TEvsGraphObjectListReverseEnumerator;
    procedure Assign(Source: TPersistent); override;
    function Add(Item: TEvsGraphObject): integer;
    procedure Insert(Index: integer; Item: TEvsGraphObject);
    procedure Delete(Index: integer);
    function Remove(Item: TEvsGraphObject): integer;
    procedure Move(CurIndex, NewIndex: integer);
    function IndexOf(Item: TEvsGraphObject): integer;
    function First: TEvsGraphObject;
    function Prior: TEvsGraphObject;
    function Next: TEvsGraphObject;
    function Last: TEvsGraphObject;
    function Push: boolean;
    function Pop: boolean;
    property Count: integer read fCount;
    property Capacity: integer read fCapacity write SetCapacity;
    property Items[Index: integer]: TEvsGraphObject read GetItems; default;
    property OnChange: TEvsGraphObjectListEvent read fOnChange write fOnChange;
  end;

  { TEvsGraphObject }

  TEvsGraphObject = class(TPersistent)   //TESTING
  private
    fID              : DWORD;
    fOwner           : TEvsSimpleGraph;
    fBrush           : TBrush;
    fPen             : TPen;
    fText            : string;
    fHint            : string;
    fFont            : TFont;
    fParentFont      : boolean;
    fOptions         : TEvsGraphObjectOptions;
    fVisible         : boolean;
    fSelected        : boolean;
    fStates          : TEvsGraphObjectStates;
    fDependentList   : TEvsGraphObjectList;
    fLinkInputList   : TEvsGraphObjectList;
    fLinkOutputList  : TEvsGraphObjectList;
    fTextToShow      : string;
    fTag             : integer;
    fData            : Pointer;
    fHasCustomData   : boolean;
    fVisualRect      : TRect;
    fVisualRectFlags : TEvsGraphChangeFlags;
    UpdateCount      : integer;
    PendingChanges   : TEvsGraphChangeFlags;
    DragDisableCount : integer;
    function GetLayer :TEvsGraphLayer;
    function  GetOwnerZoomFactor : Double;
    procedure SetBrush(Value: TBrush);
    procedure SetLayer(aValue :TEvsGraphLayer);
    procedure SetPen(Value: TPen);
    procedure SetText(const Value: string);
    procedure SetHint(const Value: string);
    procedure SetFont(Value: TFont);
    procedure SetParentFont(Value: boolean);
    procedure SetVisible(Value: boolean);
    procedure SetSelected(Value: boolean);
    function  GetZOrder: integer;
    procedure SetZOrder(Value: integer);
    procedure SetOptions(Value: TEvsGraphObjectOptions);
    procedure SetHasCustomData(Value: boolean);
    function  GetShowing: boolean;
    function  GetDragging: boolean;
    function  GetDependents(Index: integer): TEvsGraphObject;
    function  GetDependentCount: integer;
    function  GetLinkInputs(Index: integer): TEvsGraphLink;
    function  GetLinkInputCount: integer;
    function  GetLinkOutputs(Index: integer): TEvsGraphLink;
    function  GetLinkOutputCount: integer;
    function  IsFontStored: boolean;
    procedure ListChanged(Sender: TObject; GraphObject: TEvsGraphObject; Action: TEvsGraphObjectListAction);
    procedure ReadCustomData(Stream: TStream);
    procedure WriteCustomData(Stream: TStream);
  protected
    constructor CreateAsReplacement(AGraphObject: TEvsGraphObject);                                 virtual;
    constructor CreateFromStream(AOwner: TEvsSimpleGraph; AStream: TStream);                        virtual;
    function GetOwner: TPersistent;                                                                 override;
    procedure DefineProperties(Filer: TFiler);                                                      override;
    procedure Initialize;                                                                           virtual;
    procedure Loaded;                                                                               virtual;
    procedure ReplaceID(OldID, NewID: DWORD);                                                       virtual;
    procedure ReplaceObject(OldObject, NewObject: TEvsGraphObject);                                 virtual;
    procedure NotifyDependents(Flag: TEvsGraphDependencyChangeFlag);                                virtual;
    procedure LookupDependencies;                                                                   virtual;
    procedure UpdateDependencies;                                                                   virtual;
    procedure UpdateDependencyTo(GraphObject: TEvsGraphObject;Flag: TEvsGraphDependencyChangeFlag); virtual;
    function UpdateTextPlacement(Recalc: boolean; dX, dY: integer): boolean;                        virtual;
    procedure Changed(Flags: TEvsGraphChangeFlags);                                                 virtual;
    procedure BoundsChanged(dX, dY, dCX, dCY: integer);                                             virtual;
    procedure DependentChanged(GraphObject: TEvsGraphObject;Action: TEvsGraphObjectListAction);     virtual;
    procedure LinkInputChanged(GraphObject: TEvsGraphObject;Action: TEvsGraphObjectListAction);     virtual;
    procedure LinkOutputChanged(GraphObject: TEvsGraphObject;Action: TEvsGraphObjectListAction);    virtual;
    procedure ParentFontChanged;                                                                    virtual;
    function IsUpdateLocked: boolean;                                                               virtual;
    function NeighborhoodRadius: integer;                                                           virtual;
    function FixHookAnchor: TPoint;                                                                 virtual; abstract;
    function RelativeHookAnchor(RefPt: TPoint): TPoint;                                             virtual; abstract;
    procedure DrawControlPoint(aCanvas: TCanvas; const aPoint: TPoint;Enabled: boolean);            virtual;
    procedure DrawControlPoints(aCanvas: TCanvas);                                                  virtual; abstract;
    procedure DrawHighlight(aCanvas: TCanvas);                                                      virtual; abstract;
    procedure DrawText(aCanvas: TCanvas);                                                           virtual; abstract;
    procedure DrawBody(aCanvas: TCanvas);                                                           virtual; abstract;
    procedure Draw(aCanvas: TCanvas);                                                               virtual;
    procedure DrawState(aCanvas: TCanvas);                                                          virtual;
    function IsVisibleOn(aCanvas: TCanvas): boolean;                                                virtual;
    procedure QueryVisualRect(out aRect: TRect);                                                    virtual; abstract;
    function QueryHitTest(const aPoint: TPoint): DWORD;                                             virtual;
    function QueryCursor(HT: DWORD): TCursor;                                                       virtual;
    function QueryMobility(HT: DWORD): TEvsObjectSides;                                             virtual;
    function OffsetHitTest(HT: DWORD; dX, dY: integer): boolean;                                    virtual;
    procedure SnapHitTestOffset(HT: DWORD; var dX, dY: integer);                                    virtual;
    function BeginFollowDrag(HT: DWORD): boolean;                                                   virtual;
    function EndFollowDrag: boolean;                                                                virtual;
    procedure DisableDrag;                                                                          virtual;
    procedure EnableDrag;                                                                           virtual;
    procedure StyleChanged(Sender: TObject);
    procedure MoveBy(dX, dY: integer);                                                              virtual; abstract;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;const Pt: TPoint);                 virtual;
    procedure MouseMove(Shift: TShiftState; const Pt: TPoint);                                      virtual;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; const Pt: TPoint);                  virtual;
    function KeyPress(var Key: word; Shift: TShiftState): boolean;                                  virtual;
    procedure SetBoundsRect(const Rect: TRect);                                                     virtual; abstract;
    function GetBoundsRect: TRect;                                                                  virtual; abstract;
    function GetSelectedVisualRect: TRect;                                                          virtual;
  protected
    property TextToShow      : string               read fTextToShow          write fTextToShow;
    property DependentList   : TEvsGraphObjectList  read fDependentList;
    property LinkInputList   : TEvsGraphObjectList  read fLinkInputList;
    property LinkOutputList  : TEvsGraphObjectList  read fLinkOutputList;
    property VisualRectFlags : TEvsGraphChangeFlags read fVisualRectFlags     write fVisualRectFlags;
    property ParentZoomFactor: Double               read GetOwnerZoomFactor;
    property Layer           : TEvsGraphLayer       read GetLayer write SetLayer;
  public
    constructor Create(AOwner: TEvsSimpleGraph); virtual;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure Assign(Source: TPersistent); override;
    procedure AssignTo(Dest: TPersistent); override;
    function ConvertTo(AnotherClass: TEvsGraphObjectClass): TEvsGraphObject; virtual;
    procedure LoadFromStream(Stream: TStream); virtual;
    procedure SaveToStream(Stream: TStream); virtual;
    procedure BeginUpdate; virtual;
    procedure EndUpdate; virtual;
    procedure Invalidate; virtual;
    procedure BringToFront; virtual;
    procedure SendToBack; virtual;
    class function IsLink: boolean; virtual;
    class function IsNode: boolean; virtual;
    function IsLocked: boolean; virtual;
    function Delete: boolean; virtual;
    function CanDelete: boolean; virtual;
    function HitTest(const Pt: TPoint): DWORD; virtual;
    function ContainsPoint(X, Y: integer): boolean; virtual;
    function ContainsRect(const Rect: TRect): boolean; virtual;
    function BeginDrag(const Pt: TPoint; HT: DWORD = $FFFFFFFF): boolean; virtual;
    function DragTo(const Pt: TPoint; SnapToGrid: boolean): boolean; virtual;
    function DragBy(dX, dY: integer; SnapToGrid: boolean): boolean; virtual;
    function EndDrag(Accept: boolean): boolean; virtual;
    property States  : TEvsGraphObjectStates read fStates;
    property Dragging: boolean read GetDragging;
    property Showing : boolean read GetShowing;
    property Owner   : TEvsSimpleGraph read fOwner;
    property ZOrder  : integer read GetZOrder write SetZOrder;
    property Selected: boolean read fSelected write SetSelected;
    property BoundsRect: TRect read GetBoundsRect write SetBoundsRect;
    property VisualRect: TRect read fVisualRect;
    property SelectedVisualRect: TRect read GetSelectedVisualRect;
    property Dependents[Index: integer]: TEvsGraphObject read GetDependents;
    property DependentCount: integer read GetDependentCount;
    property LinkInputs[Index: integer]: TEvsGraphLink read GetLinkInputs;
    property LinkInputCount: integer read GetLinkInputCount;
    property LinkOutputs[Index: integer]: TEvsGraphLink read GetLinkOutputs;
    property LinkOutputCount: integer read GetLinkOutputCount;
    property Data: Pointer read fData write fData;
    property ID: DWORD read fID;
  published
    property Text: string read fText write SetText;
    property Hint: string read fHint write SetHint;
    property Brush: TBrush read fBrush write SetBrush;
    property Pen: TPen read fPen write SetPen;
    property Font: TFont read fFont write SetFont stored IsFontStored;
    property ParentFont: boolean read fParentFont write SetParentFont default True;
    property Options: TEvsGraphObjectOptions
      read fOptions write SetOptions default [goLinkable, goSelectable, goShowCaption];
    property Visible: boolean read fVisible write SetVisible default True;
    property Tag: integer read fTag write fTag default 0;
    property HasCustomData: boolean
      read fHasCustomData write SetHasCustomData default False;
  end;

  { TEvsGraphLink }

  TEvsGraphLink = class(TEvsGraphObject)
  private
    fPoints           : TPoints;
    fPointCount       : integer;
    fSource           : TEvsGraphObject;
    fTarget           : TEvsGraphObject;
    fTextPosition     : integer;
    fTextSpacing      : integer;
    fBeginStyle       : TEvsLinkBeginEndStyle;
    fBeginSize        : byte;
    fEndStyle         : TEvsLinkBeginEndStyle;
    fEndSize          : byte;
    fLinkOptions      : TEvsGraphLinkOptions;
    fTextRegion       : HRGN;
    fTextAngle        : double;
    fTextCenter       : TPoint;
    fTextLine         : integer;
    fChangeMode       : TEvsLinkChangeMode;
    fAcceptingHook    : boolean;
    fHookingObject    : TEvsGraphObject;
    fMovingPoint      : integer;
    SourceID          : DWORD;
    TargetID          : DWORD;
    UpdatingEndPoints : boolean;
    CheckingLink      : boolean;

    procedure ReadArrowSize(Reader : TReader);
    procedure ReadFromNode(Reader : TReader);
    procedure ReadKind(Reader : TReader);
    procedure ReadToNode(Reader : TReader);

    procedure SetSource(Value: TEvsGraphObject);
    procedure SetTarget(Value: TEvsGraphObject);
    procedure SetLinkOptions(Value: TEvsGraphLinkOptions);
    procedure SetTextPosition(Value: integer);
    procedure SetTextSpacing(Value: integer);                                   //DONE SPACING SUPPORT ON OTHER PLATFORMS??
    procedure SetBeginStyle(Value: TEvsLinkBeginEndStyle);
    procedure SetBeginSize(Value: byte);
    procedure SetEndStyle(Value: TEvsLinkBeginEndStyle);
    procedure SetEndSize(Value: byte);
    function GetPoints(Index: integer): TPoint;
    procedure SetPoints(Index: integer; const Value: TPoint);
    procedure SetPolyline(const Value: TPoints);
    procedure ReadSource(Reader: TReader);
    procedure WriteSource(Writer: TWriter);
    procedure ReadTarget(Reader: TReader);
    procedure WriteTarget(Writer: TWriter);
    procedure ReadPoints(Stream: TStream);
    procedure WritePoints(Stream: TStream);
  protected
    procedure DefineProperties(Filer: TFiler); override;
    procedure Loaded; override;
    function FixHookAnchor: TPoint; override;
    function RelativeHookAnchor(RefPt: TPoint): TPoint; override;
    procedure ReplaceID(OldID, NewID: DWORD); override;
    procedure ReplaceObject(OldObject, NewObject: TEvsGraphObject); override;
    procedure NotifyDependents(Flag: TEvsGraphDependencyChangeFlag); override;
    procedure UpdateDependencyTo(GraphObject: TEvsGraphObject;
      Flag: TEvsGraphDependencyChangeFlag); override;
    procedure UpdateDependencies; override;
    procedure LookupDependencies; override;
    function UpdateTextPlacement(Recalc: boolean; dX, dY: integer               //WIN32ONLY
      ): boolean; override;
    function CreateTextRegion: HRGN; virtual;                                   //WIN32 OLNLY
    function IndexOfLongestLine: integer; virtual;                              //DONE
    function IndexOfNearestLine(const Pt: TPoint; Neighborhood: integer         //DONE
      ): integer; virtual;
    procedure QueryVisualRect(out Rect: TRect); override;                       {$MESSAGE HINT 'REGION ALTERNATIVE'}
    function QueryHitTest(const Pt: TPoint): DWORD; override;                   {$MESSAGE WARN 'REGION ALTERNATIVE'}
    function QueryCursor(HT: DWORD): TCursor; override;                         //DONE
    function QueryMobility(HT: DWORD): TEvsObjectSides; override;                  //DONE
    function OffsetHitTest(HT: DWORD; dX, dY: integer): boolean; override;      //DONE
    procedure SnapHitTestOffset(HT: DWORD; var dX, dY: integer); override;      //DONE
    function BeginFollowDrag(HT: DWORD): boolean; override;                     //DONE
    procedure MoveBy(dX, dY: integer); override;                                //DONE
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;               //DONE
      const Pt: TPoint); override;                                              //DONE
    procedure MouseMove(Shift: TShiftState; const Pt: TPoint); override;        //DONE
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;                 //DONE
      const Pt: TPoint); override;                                              //DONE
    procedure UpdateChangeMode(HT: DWORD; Shift: TShiftState); virtual;         //DONE
    function PointStyleOffset(Style: TEvsLinkBeginEndStyle; Size: integer): integer; //DONE
      virtual;                                                                  //DONE
    function PointStyleRect(const Pt: TPoint; const Angle: double;              //DONE
      Style: TEvsLinkBeginEndStyle; Size: integer): TRect; virtual;                //DONE
    function DrawPointStyle(aCanvas: TCanvas; const Pt: TPoint;                  //DONE
      const Angle: double; Style: TEvsLinkBeginEndStyle; Size: integer): TPoint; virtual;//DONE
    procedure DrawControlPoints(aCanvas: TCanvas); override;                     //DONE
    procedure DrawHighlight(aCanvas: TCanvas); override;                         //DONE
    procedure DrawText(aCanvas: TCanvas); override;                              //IMPLEMENTATION REQUIRED
    procedure DrawBody(Canvas: TCanvas); override;                              //DONE
    procedure SetBoundsRect(const Rect: TRect); override;                       //DONE
    function GetBoundsRect: TRect; override;                                    //DONE
  protected
    property TextRegion: HRGN read fTextRegion;                                 {$MESSAGE WARN 'REGION ALTERNATIVE'}
    property TextAngle: double read fTextAngle;                                 //CLEAN
    property TextCenter: TPoint read fTextCenter;                               //CLEAN
    property TextLine: integer read fTextLine;                                  //CLEAN
    property ChangeMode: TEvsLinkChangeMode read fChangeMode write fChangeMode;    //CLEAN
    property AcceptingHook: boolean read fAcceptingHook;                        //CLEAN
    property HookingObject: TEvsGraphObject read fHookingObject;                //CLEAN
    property MovingPoint: integer read fMovingPoint;                            //CLEAN
  public
    constructor Create(AOwner: TEvsSimpleGraph); override;                      //CLEAN
    constructor CreateNew(AOwner: TEvsSimpleGraph; ASource: TEvsGraphObject;    //CLEAN
      const Pts: array of TPoint; ATarget: TEvsGraphObject); virtual;
    destructor Destroy; override;                                               //CLEAN
    procedure Assign(Source: TPersistent); override;                            //CLEAN
    function ContainsRect(const Rect: TRect): boolean; override;                //WORKS RAGION ATLERNATIVE
    function CanMove: boolean; virtual;                                         //CLEAN
    function AddPoint(const Pt: TPoint): integer; virtual;                      //CLEAN
    procedure InsertPoint(AIndex: integer; const APt: TPoint); virtual;         //CLEAN
    procedure RemovePoint(AIndex: integer); virtual;                            //CLEAN
    function IndexOfPoint(const Pt: TPoint; Neighborhood: integer = 0): integer; virtual; //CLEAN
    function AddBreakPoint(const Pt: TPoint): integer; virtual;                 //CLEAN
    function NormalizeBreakPoints(AOptions: TEvsLinkNormalizeOptions): boolean; virtual;//CLEAN
    function IsFixedPoint(AIndex: integer; AHookedPointsAsFixed: boolean): boolean; //CLEAN
      virtual;
    function IsHookedPoint(AIndex: integer): boolean; virtual;                  //CLEAN
    function HookedObjectOf(AIndex: integer): TEvsGraphObject; virtual;         //CLEAN
    function HookedIndexOf(AGraphObject: TEvsGraphObject): integer; virtual;    //CLEAN
    function HookedPointCount: integer; virtual;                                //CLEAN
    function CanHook(AIndex: integer; AGraphObject: TEvsGraphObject): boolean; virtual; //CLEAN
    function Hook(AIndex: integer; AGraphObject: TEvsGraphObject): boolean; virtual;  //CLEAN
    function Unhook(AGraphObject: TEvsGraphObject): integer; overload; virtual;       //CLEAN
    function Unhook(AIndex: integer): boolean; overload; virtual;                     //CLEAN
    function CanLink(ASource, ATarget: TEvsGraphObject): boolean; virtual;            //CLEAN
    function Link(ASource, ATarget: TEvsGraphObject): boolean; virtual;               //CLEAN
    function Rotate(const AAngle: double; const AOrigin: TPoint): boolean; virtual;   //CLEAN
    function Scale(const AFactor: double): boolean; virtual;                          //CLEAN
    procedure Reverse; virtual;                                                       //CLEAN
    class function IsLink: boolean; override;                                         //CLEAN
    property Source: TEvsGraphObject read fSource write SetSource;                    //DONE
    property Target: TEvsGraphObject read fTarget write SetTarget;                    //CLEAN
    property Points[Index: integer]: TPoint read GetPoints write SetPoints;           //CLEAN
    property PointCount: integer read fPointCount;                                    //CLEAN
    property Polyline: TPoints read fPoints write SetPolyline;                        //CLEAN
  published
    property BeginStyle: TEvsLinkBeginEndStyle
      read fBeginStyle write SetBeginStyle default lsNone;
    property BeginSize: byte read fBeginSize write SetBeginSize default 6;
    property EndStyle: TEvsLinkBeginEndStyle
      read fEndStyle write SetEndStyle default lsArrow;
    property EndSize: byte read fEndSize write SetEndSize default 6;
    property LinkOptions: TEvsGraphLinkOptions
      read fLinkOptions write SetLinkOptions default [];
    property TextPosition: integer read fTextPosition write SetTextPosition default -1;
    property TextSpacing: integer read fTextSpacing write SetTextSpacing default 0;
  end;

  { TEVSBezierLink }

  TEVSBezierLink = class(TEVSGraphLink)
  protected
    FPolyline      : TPoints;
    FCreateByMouse : Boolean;
    function IndexOfNearestLine (const Pt: TPoint; Neighborhood: integer): integer;             override;
    function RelativeHookAnchor (RefPt: TPoint): TPoint;                                        override;
    procedure MouseUp           (aButton: TMouseButton; aShift: TShiftState; const aPt: TPoint);override;
    procedure MouseDown         (aButton: TMouseButton; aShift: TShiftState; const aPt: TPoint);override;
    procedure Changed           (aFlags: TEvsGraphChangeFlags);                                 override;
    procedure DrawBody          (aCanvas:TCanvas);                                              override;
    function QueryHitTest       (const aPt: TPoint): DWORD;                                     override;
    procedure DrawHighlight     (aCanvas: TCanvas);                                             override;
    procedure UpdateChangeMode  (aHT: DWORD; aShift: TShiftState);                              override;
  end;

  TEvsGraphNode = class(TEvsGraphObject)                                              //DrawText replacement required.  Region alternative
  private
    fLeft              : integer;
    fTop               : integer;
    fWidth             : integer;
    fHeight            : integer;
    fAlignment         : TAlignment;
    fLayout            : TTextLayout;
    fMargin            : integer;
    fBackground        : TPicture;
    fBackgroundMargins : TRect;
    fNodeOptions       : TEvsGraphNodeOptions;
    fRegion            : HRGN;
    fTextRect          : TRect;
    procedure SetLeft               (Value: integer);
    procedure SetTop                (Value: integer);
    procedure SetWidth              (Value: integer);
    procedure SetHeight             (Value: integer);
    procedure SetAlignment          (Value: TAlignment);
    procedure SetLayout             (Value: TTextLayout);
    procedure SetMargin             (Value: integer);
    procedure SetNodeOptions        (Value: TEvsGraphNodeOptions);
    procedure SetBackground         (Value: TPicture);
    procedure SetBackgroundMargins  (const Value: TRect);
    procedure BackgroundChanged     (Sender: TObject);
    procedure ReadBackgroundMargins (Reader: TReader);
    procedure WriteBackgroundMargins(Writer: TWriter);
  protected
    procedure DefineProperties(Filer: TFiler);                                      override;
    procedure Initialize;                                                           override;
    function FixHookAnchor: TPoint;                                                 override;
    function RelativeHookAnchor(RefPt: TPoint): TPoint;                             override;
    function LinkIntersect(const LinkPt: TPoint; const LinkAngle: double): TPoints; virtual; abstract;
    procedure BoundsChanged(dX, dY, dCX, dCY: integer);                             override;
    function UpdateTextPlacement(Recalc: boolean; dX, dY: integer): boolean;        override;
    procedure QueryMaxTextRect(out Rect: TRect);                                    virtual;
    procedure QueryTextRect(out Rect: TRect);                                       virtual;
    function CreateRegion: HRGN;                                                    virtual; abstract;
    function CreateClipRgn(ACanvas: TCanvas): HRGN;                                 virtual;
    procedure QueryVisualRect(out Rect: TRect);                                     override;
    function QueryHitTest(const Pt: TPoint): DWORD;                                 override;
    function QueryCursor(HT: DWORD): TCursor;                                       override;
    function QueryMobility(HT: DWORD): TEvsObjectSides;                             override;
    function OffsetHitTest(HT: DWORD; dX, dY: integer): boolean;                    override;
    procedure SnapHitTestOffset(HT: DWORD; var dX, dY: integer);                    override;
    function BeginFollowDrag(HT: DWORD): boolean;                                   override;
    procedure MoveBy(dX, dY: integer);                                              override;
    procedure DrawControlPoints(aCanvas: TCanvas);                                  override;
    procedure DrawHighlight(aCanvas: TCanvas);                                      override;
    procedure DrawText(aCanvas: TCanvas);                                           override;
    procedure DrawBackground(aCanvas: TCanvas);                                     virtual;
    procedure DrawBorder(aCanvas: TCanvas);                                         virtual; abstract;
    procedure DrawBody(aCanvas: TCanvas);                                           override;
    procedure SetBoundsRect(const aRect: TRect);                                    override;
    function GetBoundsRect: TRect;                                                  override;
    function GetCenter: TPoint;                                                     virtual;
  protected
    property Region: HRGN read fRegion;
    property TextRect: TRect read fTextRect;
  public
    constructor Create(AOwner: TEvsSimpleGraph); override;
    constructor CreateNew(AOwner: TEvsSimpleGraph; const Bounds: TRect); virtual;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function ContainsRect(const Rect: TRect): boolean; override;
    procedure CanMoveResize(var NewLeft, NewTop, NewWidth, NewHeight: integer;
      out CanMove, CanResize: boolean); virtual;
    procedure SetBounds(aLeft, aTop, aWidth, aHeight: integer); virtual;
    property Center: TPoint read GetCenter;
    property BackgroundMargins: TRect read fBackgroundMargins write SetBackgroundMargins;
  published
    property Left: integer read fLeft write SetLeft;
    property Top: integer read fTop write SetTop;
    property Width: integer read fWidth write SetWidth;
    property Height: integer read fHeight write SetHeight;
    property Alignment: TAlignment read fAlignment write SetAlignment default taCenter;
    property Layout: TTextLayout read fLayout write SetLayout default tlCenter;
    property Margin: integer read fMargin write SetMargin default 8;
    property Background: TPicture read fBackground write SetBackground;
    property NodeOptions: TEvsGraphNodeOptions
      read fNodeOptions write SetNodeOptions default
      [gnoMovable, gnoResizable, gnoShowBackground];
  end;

  TEvsPolygonalNode = class(TEvsGraphNode)
   private
     fVertices: TPoints;
   protected
     function GetCenter    : TPoint;                                                  override;
     function CreateRegion : HRGN;                                                    override;
     procedure Initialize;                                                            override;
     procedure BoundsChanged(dX, dY, dCX, dCY: integer);                              override;
     procedure DrawBorder   (aCanvas: TCanvas);                                       override;
     function LinkIntersect (const LinkPt: TPoint; const LinkAngle: double): TPoints; override;
     procedure DefineVertices(const ARect: TRect; var Points: TPoints);               virtual; abstract;
   public
     destructor Destroy; override;
     property Vertices: TPoints read fVertices;
   end;

  TEvsRoundRectangularNode = class(TEvsGraphNode)
  protected
    function CreateRegion: HRGN;                                                    override;
    procedure DrawBorder  (Canvas: TCanvas);                                        override;
    function LinkIntersect(const LinkPt: TPoint; const LinkAngle: double): TPoints; override;
  end;

  TEvsEllipticNode = class(TEvsGraphNode)
  protected
    function CreateRegion: HRGN;                                                    override;
    procedure DrawBorder  (Canvas: TCanvas);                                        override;
    function LinkIntersect(const LinkPt: TPoint; const LinkAngle: double): TPoints; override;
  end;

  TEvsTriangularNode = class(TEvsPolygonalNode)
  protected
    procedure QueryMaxTextRect(out Rect: TRect);                         override;
    procedure DefineVertices  (const ARect: TRect; var Points: TPoints); override;
  end;

  TEvsRectangularNode = class(TEvsPolygonalNode)
  protected
    //function QueryHitTest(const Pt : TPoint) : DWORD; override;
    function CreateRegion: HRGN;                                       override;
    procedure DefineVertices(const ARect: TRect; var Points: TPoints); override;
  end;

  TEvsRhomboidalNode = class(TEvsPolygonalNode)
  protected
    procedure QueryMaxTextRect(out Rect: TRect);                         override;
    procedure DefineVertices  (const ARect: TRect; var Points: TPoints); override;
  end;

  TEvsPentagonalNode = class(TEvsPolygonalNode)
  protected
    procedure QueryMaxTextRect(out Rect: TRect);                         override;
    procedure DefineVertices  (const ARect: TRect; var Points: TPoints); override;
  end;

  TEvsHexagonalNode = class(TEvsPolygonalNode)
  protected
    procedure QueryMaxTextRect(out Rect: TRect);                         override;
    procedure DefineVertices  (const ARect: TRect; var Points: TPoints); override;
  end;

  TEvsGraphConstraints = class(TPersistent)              //DONE
  private
    fOwner      : TEvsSimpleGraph;
    fBoundsRect : TRect;
    fSourceRect : TRect;
    fOnChange   : TNotifyEvent;
    procedure SetBoundsRect(const Rect: TRect);
    function  GetField     (Index: Integer): Integer;
    procedure SetField     (Index: Integer; Value: Integer);
  protected
    function GetOwner: TPersistent; override;
    procedure DoChange; virtual;
  public
    constructor Create   (AOwner: TEvsSimpleGraph);
    procedure Assign     (Source: TPersistent); override;
    procedure SetBounds  (aLeft, aTop, aWidth, aHeight: Integer);
    function WithinBounds(const Pts: array of TPoint): Boolean;
    function ConfinePt   (var Pt: TPoint): Boolean;
    function ConfineRect (var Rect: TRect): Boolean;
    function ConfineOffset(var dX, dY: Integer; Mobility: TEvsObjectSides): Boolean;

    property Owner     : TEvsSimpleGraph read fOwner;
    property BoundsRect: TRect           read fBoundsRect write SetBoundsRect;
    property SourceRect: TRect           read fSourceRect write fSourceRect;
    property OnChange  : TNotifyEvent    read fOnChange   write fOnChange;
  published
    property MinLeft  : Integer index 0 read GetField write SetField default 0;
    property MinTop   : Integer index 1 read GetField write SetField default 0;
    property MaxRight : Integer index 2 read GetField write SetField default $0000FFFF;
    property MaxBottom: Integer index 3 read GetField write SetField default $0000FFFF;
  end;

  TInitEvent = procedure (aCanvas:TCanvas) of object;
  { TEvsCustomGraphPainter }

  TEvsCustomGraphPainter = class(TComponent)
  private
    FGraph: TEvsSimpleGraph;
    procedure SetGraph(AValue: TEvsSimpleGraph);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    function GetCanvas:TEvsGraphCanvasClass;virtual;abstract;
    procedure CanvasInit(aCanvas:TCanvas);virtual;abstract;
  published
    property Graph:TEvsSimpleGraph read FGraph write SetGraph;
  end;

  { TEvsSimpleGraph }

  TEvsSimpleGraph = class(TCustomControl)
  private
    FActiveLayer :TEvsGraphLayer;
    FCanvasInit           : TInitEvent;
    FCustomCanvas         : TCanvasClass;
    fHorzScrollBar        : TEvsGraphScrollBar;
    fVertScrollBar        : TEvsGraphScrollBar;
    fZoom                 : TZoom;
    FZoomFactor           : Double;
    fGridSize             : TGridSize;
    fGridColor            : TColor;
    fShowGrid             : Boolean;
    fSnapToGrid           : Boolean;
    fShowHiddenObjects    : Boolean;
    fHideSelection        : Boolean;
    fLockNodes            : Boolean;
    fLockLinks            : Boolean;
    fMarkerColor          : TColor;
    fMarkerSize           : TMarkerSize;
    fObjects              : TEvsGraphObjectList;
    fSelectedObjects      : TEvsGraphObjectList;
    fDraggingObjects      : TEvsGraphObjectList;
    fDefaultKeyMap        : Boolean;
    fObjectPopupMenu      : TPopupMenu;
    fDefaultNodeClass     : TEvsGraphNodeClass;
    fDefaultLinkClass     : TEvsGraphLinkClass;
    fModified             : Boolean;
    fCommandMode          : TEvsGraphCommandMode;
    fGraphConstraints     : TEvsGraphConstraints;
    fMinNodeSize          : Word;
    fDrawOrder            : TEvsGraphDrawOrder;
    fFixedScrollBars      : Boolean;
    fValidMarkedArea      : Boolean;
    fMarkedArea           : TRect;
    fDragSource           : TEvsGraphObject;
    fDragHitTest          : DWORD;
    fDragSourcePt         : TPoint;
    fDragTargetPt         : TPoint;
    fDragModified         : Boolean;
    fCanvasRecall         : TEvsCanvasRecall;
    fClipboardFormats     : TEvsGraphClipboardFormats;
    fObjectAtCursor       : TEvsGraphObject;
    fOnObjectInitInstance : TEvsGraphNotifyEvent;
    fOnObjectInsert       : TEvsGraphNotifyEvent;
    fOnObjectRemove       : TEvsGraphNotifyEvent;
    fOnObjectChange       : TEvsGraphNotifyEvent;
    fOnObjectSelect       : TEvsGraphNotifyEvent;
    fOnObjectClick        : TEvsGraphNotifyEvent;
    fOnObjectDblClick     : TEvsGraphNotifyEvent;

    fOnAfterDraw          : TEvsGraphDrawEvent;
    fOnBeforeDraw         : TEvsGraphDrawEvent;
    fOnCanHookLink        : TEvsGraphCanHookEvent;
    fOnCanLinkObjects     : TEvsGraphCanLinkEvent;
    fOnCanMoveResizeNode  : TEvsCanMoveResizeNodeEvent;
    fOnCanRemoveObject    : TEvsGraphCanRemoveEvent;
    fOnCommandModeChange  : TNotifyEvent;
    fOnGraphChange        : TNotifyEvent;
    fOnInfoTip            : TEvsGraphInfoTipEvent;
    fOnNodeMoveResize     : TEvsGraphNodeResizeEvent;
    fOnObjectAfterDraw    : TEvsGraphObjectDrawEvent;
    fOnObjectBeforeDraw   : TEvsGraphObjectDrawEvent;
    fOnObjectBeginDrag    : TEvsGraphBeginDragEvent;
    fOnObjectContextPopup : TEvsGraphContextPopupEvent;
    fOnObjectEndDrag      : TEvsGraphEndDragEvent;
    fOnObjectHook         : TEvsGraphHookEvent;
    fOnObjectMouseEnter   : TEvsGraphNotifyEvent;
    fOnObjectMouseLeave   : TEvsGraphNotifyEvent;
    fOnObjectRead         : TEvsGraphStreamEvent;
    fOnObjectUnhook       : TEvsGraphHookEvent;
    fOnObjectWrite        : TEvsGraphStreamEvent;
    fOnZoomChange         : TNotifyEvent;
    FSuspendQueryEvents   : Integer;
    SaveBounds            : array[TEvsGraphBoundsKind] of TRect;
    SaveBoundsChange      : set of TEvsGraphBoundsKind;
    SaveInvalidateRect    : TRect;
    SaveModified          : Integer;
    SaveRangeChange       : Boolean;
    UndoStorage           : TMemoryStream;
    UpdateCount           : Integer;
    UpdatingScrollBars    : Boolean;  //for internal use only.
    FPrinting             : Boolean;
    FLayers               : TEvsGraphLayerList; //layer support.

    function GetLayer(Index :Integer) :TEvsGraphLayer;
    function GetMidPoint  : TPoint;
    function GetBoundingRect(Kind: TEvsGraphBoundsKind): TRect;
    function GetCursorPos : TPoint;
    function GetVisibleBounds: TRect;
    function ReadGraphObject(Stream: TStream): TEvsGraphObject;
    procedure ObjectChanged(GraphObject: TEvsGraphObject; Flags: TEvsGraphChangeFlags);
    procedure ObjectListChanged(Sender: TObject; GraphObject: TEvsGraphObject;
      AAction: TEvsGraphObjectListAction);
    procedure SelectedListChanged(Sender: TObject; GraphObject: TEvsGraphObject;
      AAction: TEvsGraphObjectListAction);
    procedure SetCommandMode(AValue: TEvsGraphCommandMode);
    procedure SetCursorPos(const Pt: TPoint);
    procedure SetCustomCanvas(aValue :TCanvasClass);
    procedure SetDrawOrder(Value: TEvsGraphDrawOrder);
    procedure SetFixedScrollBars(AValue: Boolean);
    procedure SetGraphConstraints(AValue: TEvsGraphConstraints);
    procedure SetGridColor(AValue: TColor);
    procedure SetGridSize(AValue: TGridSize);
    procedure SetHideSelection(Value: boolean);
    procedure SetHorzScrollBar(AValue: TEvsGraphScrollBar);
    procedure SetLayer(Index :Integer; aValue :TEvsGraphLayer);
    procedure SetLockLinks(Value: boolean);
    procedure SetLockNodes(Value: boolean);
    procedure SetMarkedArea(AValue: TRect);
    procedure SetMarkerColor(Value: TColor);
    procedure SetMarkerSize(Value: TMarkerSize);
    procedure SetShowGrid(AValue: Boolean);
    procedure SetShowHiddenObjects(Value: boolean);
    procedure SetVertScrollBar(AValue: TEvsGraphScrollBar);
    procedure SetZoom(AValue: TZoom);
    procedure WriteGraphObject(Stream: TStream; GraphObject: TEvsGraphObject);
  protected

    class procedure WSRegisterClass; override;

    function DrawTextBiDiModeFlags(aFlags:longint):LongInt;
    procedure SuspendQueryEvents;inline;
    Procedure ResumeQueryEvents;
    //procedure AdjustDC(aDC: HDC; aOrg: PPoint = nil); virtual;                    //WORKS - HEAVY
    procedure CalcAutoRange; virtual;
    function CreateUniqueID(aGraphObject: TEvsGraphObject): DWORD; virtual;


    {$IFDEF SUBCLASS_WMPRINT}
    procedure WMPrint(var Msg: TWMPrint); message WM_PRINT;                     //WORKS-???
    {$ENDIF}
    procedure WMSize(var Msg: TLMSize); message LM_SIZE;
    procedure WMHScroll(var Msg: TLMHScroll); message LM_HSCROLL;
    procedure WMVScroll(var Msg: TLMVScroll); message LM_VSCROLL;
    procedure CNKeyDown(var Msg: TLMKeyDown); message CN_KEYDOWN;
    procedure CNKeyUp(var Msg: TLMKeyUp); message CN_KEYUP;
    procedure CMFontChanged(var Msg: TLMessage); message CM_FONTCHANGED;
    procedure CMBiDiModeChanged(var Msg: TLMessage); message CM_BIDIMODECHANGED;
    procedure CMMouseLeave(var Msg: TLMessage); message CM_MOUSELEAVE;
    procedure CMHintShow(var Msg: TCMHintShow); message CM_HINTSHOW;

    function BeginDragObject(aGraphObject: TEvsGraphObject; const aPt: TPoint;
      aHT: DWORD): boolean; virtual;
    procedure BackupObjects(aStream: TStream; aObjectList: TEvsGraphObjectList);virtual;
    procedure DoAfterDraw(aCanvas: TCanvas); virtual;
    procedure DoBeforeDraw(aCanvas: TCanvas); virtual;
    procedure DoCanHookLink(aGraphObject: TEvsGraphObject; aLink: TEvsGraphLink;
      aIndex: integer; var aCanHook: boolean); virtual;
    procedure DoCanLinkObjects(aLink: TEvsGraphLink; aSource, aTarget: TEvsGraphObject;
      var aCanLink: boolean); virtual;
    procedure DoCanMoveResizeNode(aNode: TEvsGraphNode;var aLeft, aTop, aWidth,
      aHeight: integer; var aCanMove, aCanResize: boolean);virtual;
    procedure DoCanRemoveObject(aGraphObject: TEvsGraphObject;
      var aCanRemove: boolean); virtual;
    procedure DoCommandModeChange; virtual;
    procedure DoGraphChange; virtual;
    procedure DoNodeMoveResize(aNode: TEvsGraphNode); virtual;
    procedure DoObjectAfterDraw(aCanvas: TCanvas; aGraphObject: TEvsGraphObject); virtual;
    procedure DoObjectBeforeDraw(aCanvas: TCanvas; aGraphObject: TEvsGraphObject); virtual;
    procedure DoObjectBeginDrag(aGraphObject: TEvsGraphObject; aHT: DWORD); virtual;
    procedure DoObjectChange(aGraphObject: TEvsGraphObject); virtual;
    procedure DoObjectClick(aGraphObject: TEvsGraphObject); virtual;
    procedure DoObjectContextPopup(aGraphObject: TEvsGraphObject;
      const aMousePos: TPoint; var aHandled: boolean); virtual;
    procedure DoObjectDblClick(aGraphObject: TEvsGraphObject); virtual;
    procedure DoObjectEndDrag(aGraphObject: TEvsGraphObject; aHT: DWORD;
      aCancelled: boolean); virtual;
    procedure DoObjectHook(aGraphObject: TEvsGraphObject; aLink: TEvsGraphLink;
      aIndex: integer); virtual;
    procedure DoObjectInitInstance(aGraphObject: TEvsGraphObject); virtual;
    procedure DoObjectInsert(aGraphObject: TEvsGraphObject); virtual;
    procedure DoObjectMouseEnter(aGraphObject: TEvsGraphObject); virtual;
    procedure DoObjectMouseLeave(aGraphObject: TEvsGraphObject); virtual;
    procedure DoObjectRead(aGraphObject: TEvsGraphObject; aStream: TStream); virtual;
    procedure DoObjectRemove(aGraphObject: TEvsGraphObject); virtual;
    procedure DoObjectSelect(aGraphObject: TEvsGraphObject); virtual;
    procedure DoObjectUnhook(aGraphObject: TEvsGraphObject; aLink: TEvsGraphLink;
      aIndex: integer); virtual;
    procedure DoObjectWrite(aGraphObject: TEvsGraphObject; aStream: TStream); virtual;
    procedure DoZoomChange; virtual;
    procedure DraggingListChanged(Sender: TObject; aGraphObject: TEvsGraphObject;
      aAction: TEvsGraphObjectListAction);
    procedure DrawEditStates(aCanvas: TCanvas); virtual;
    procedure DrawGrid(ACanvas: TCanvas); virtual;
    procedure DrawObjects(aCanvas: TCanvas; AObjectList: TEvsGraphObjectList); virtual;
    procedure EndDragObject(Accept: boolean); virtual;
    procedure ReadObjects(aStream: TStream); virtual;
    procedure RenewObjectAtCursor(aNewObjectAtCursor: TEvsGraphObject); virtual;
    procedure RestoreObjects(aStream: TStream); virtual;
    procedure WriteObjects(aStream: TStream; aObjectList: TEvsGraphObjectList); virtual;
    {$IFDEF METAFILE_SUPPORT}
    function GetAsMetafile(RefDC: HDC; ObjectList: TGraphObjectList): TMetafile; virtual; //UNTESTED
    {$ENDIF}
    procedure UpdateScrollBars; virtual;

    function GetObjectsBounds(aObjectList: TEvsGraphObjectList): TRect; virtual;

    procedure GPToCP(var aPoints; aCount: Integer);
    procedure CPToGP(var aPoints; aCount: Integer);

    function GetAsBitmap(aObjectList: TEvsGraphObjectList): Graphics.TBitmap; virtual;
    procedure PerformDragBy(adX, adY: integer); virtual;
    procedure PerformInvalidate(aRect: PRect);
    procedure CheckObjectAtCursor(const aPt: TPoint); virtual;
    function InsertObjectByMouse(var aPt: TPoint; aGraphObjectClass: TEvsGraphObjectClass;
      aGridSnap: boolean): TEvsGraphObject;

    function DefaultKeyHandler(var Key: word; Shift: TShiftState): boolean; virtual;

    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure Paint; override;
    procedure DrawBackGround(const aCanvas:TCanvas; const ClipRect:TRect);virtual;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: integer); override;
    procedure DoContextPopup(MousePos: TPoint; var Handled: boolean); override;
    procedure Click; override;
    procedure DblClick; override;
    procedure DoEnter; override;
    procedure DoExit; override;
    function ZoomRect(const aRect: TRect): boolean;
    function ZoomObject(aGraphObject: TEvsGraphObject): boolean;
    function ZoomSelection: boolean;
    function ZoomGraph: boolean;
    function ChangeZoom(aNewZoom: integer; aOrigin: TEvsGraphZoomOrigin): boolean;
    function ChangeZoomBy(aDelta: integer; aOrigin: TEvsGraphZoomOrigin): boolean;
    function LayerByOrder(const aOrder:integer):TEvsGraphLayer;
  protected
    property CanvasRecall: TEvsCanvasRecall read fCanvasRecall;
    property DragHitTest: DWORD read fDragHitTest write fDragHitTest;
    property DragModified: boolean read fDragModified;
    property DragSourcePt: TPoint read fDragSourcePt write fDragSourcePt;
    property DragTargetPt: TPoint read fDragTargetPt write fDragTargetPt;
    property MarkedArea: TRect read fMarkedArea write SetMarkedArea;
    property ValidMarkedArea: boolean read fValidMarkedArea;
    property Zoom: TZoom read fZoom write SetZoom default 100;
    property Printing : Boolean read fPrinting;

    property OnCanvasInit : TInitEvent read FCanvasInit write FCanvasInit;             //internal exclusive use.
    procedure OffsetObjects(const aList:TEvsGraphObjectList; aDX, aDY:Integer);
  public
    procedure StartPrinting;
    procedure EndPrinting;

    procedure CLtoGP(var Points : array of TPoint);
    procedure GPtoCL(var Points : array of TPoint);
  public
    class procedure Register(aNodeClass: TEvsGraphNodeClass); overload;
    class procedure Unregister(aNodeClass: TEvsGraphNodeClass); overload;
    class function NodeClassCount: integer;
    class function NodeClasses(aIndex: integer): TEvsGraphNodeClass;
    class procedure Register(aLinkClass: TEvsGraphLinkClass); overload;
    class procedure Unregister(aLinkClass: TEvsGraphLinkClass); overload;
    class function LinkClassCount: integer;
    class function LinkClasses(aIndex: integer): TEvsGraphLinkClass;

  public  //methods
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure Invalidate; override;
    procedure InvalidateRect(const Rect: TRect);
    procedure DrawTo(aCanvas: TCanvas);
    procedure Print(aCanvas: TCanvas; const Rect: TRect);
    procedure ScrollInView(aGraphObject: TEvsGraphObject); overload;
    procedure ScrollInView(const aRect: TRect); overload;
    procedure ScrollInView(const aPt: TPoint); overload;
    procedure ScrollCenter(aGraphObject: TEvsGraphObject); overload;
    procedure ScrollCenter(const aRect: TRect); overload;
    procedure ScrollCenter(const aPt: TPoint); overload;
    procedure ScrollBy(aDeltaX, aDeltaY: integer);override;
    procedure ToggleSelection(const aRect: TRect; aKeepOld: boolean;
      aGraphObjectClass: TEvsGraphObjectClass = nil);
    function FindObjectAt(aX, aY: integer;
      aLookAfter: TEvsGraphObject = nil): TEvsGraphObject;
    function FindObjectByID(aID: DWORD): TEvsGraphObject;
    function InsertNode(const aBounds: TRect;
      aNodeClass: TEvsGraphNodeClass = nil): TEvsGraphNode;
    function InsertLink(aSource, aTarget: TEvsGraphObject;
      aLinkClass: TEvsGraphLinkClass = nil): TEvsGraphLink; overload;
    function InsertLink(aSource: TEvsGraphObject; const aPts: array of TPoint;
      aLinkClass: TEvsGraphLinkClass = nil): TEvsGraphLink; overload;
    function InsertLink(const aPts: array of TPoint; aTarget: TEvsGraphObject;
      aLinkClass: TEvsGraphLinkClass = nil): TEvsGraphLink; overload;
    function InsertLink(const aPts: array of TPoint;
      aLinkClass: TEvsGraphLinkClass = nil): TEvsGraphLink; overload;
    // zoom moved to protected
    function AlignSelection(aHorz: TEvsHAlignOption; aVert: TEvsVAlignOption): boolean;  virtual;
    function ResizeSelection(aHorz: TEvsResizeOption; aVert: TEvsResizeOption): boolean; virtual;
    function ForEachObject(aCallback: TEvsGraphForEachMethod; aUserData: integer;
      aSelection: boolean = False): integer;
    function FindNextObject(aStartIndex: integer; aInclusive, aBackward, aWrap: boolean;
      aGraphObjectClass: TEvsGraphObjectClass = nil): TEvsGraphObject;
    function SelectNextObject(aBackward: boolean;
      aGraphObjectClass: TEvsGraphObjectClass = nil): boolean;
    function ObjectsCount(aGraphObjectClass: TEvsGraphObjectClass = nil): integer;
    function SelectedObjectsCount(aGraphObjectClass: TEvsGraphObjectClass = nil): integer;
    procedure ClearSelection;
    procedure Clear;
    procedure CopyToGraphic(aGraphic: TGraphic);                                            //WORKS --No Metafile
    procedure LoadFromStream(aStream: TStream);
    procedure SaveToStream(aStream: TStream);
    procedure LoadFromFile(const aFilename: string);
    procedure SaveToFile(const aFilename: string);
    procedure MergeFromStream(aStream: TStream; aOffsetX, aOffsetY: integer);
    procedure MergeFromFile(const aFilename: string; aOffsetX, aOffsetY: integer);
    function ClientToGraph(aX, aY: integer): TPoint;
    function GraphToClient(aX, aY: integer): TPoint;
    function ScreenToGraph(aX, aY: integer): TPoint;
    function GraphToScreen(aX, aY: integer): TPoint;
    procedure SnapOffset(const aPt: TPoint; var adX, adY: integer);
    function SnapPoint(const aPt: TPoint): TPoint;
    {$IFDEF METAFILE_SUPPORT}
    procedure SaveAsMetafile(const Filename: string);                                      //NO METAFILE SUPPORT
    {$ENDIF}
    procedure SaveAsBitmap(const aFilename: string);
    function PasteFromClipboard: boolean;                                                  //CONVERTED TO CLIPBRD STREAMS TEST IT.
    procedure CopyToClipboard(aSelection: Boolean = True);                                 //USING CLIPBRD METHODS TEST IT
  public  //properties
    property ActiveLayer  : TEvsGraphLayer read FActiveLayer write FActiveLayer;
    property CustomCanvas : TCanvasClass read FCustomCanvas write SetCustomCanvas;
    property CommandMode: TEvsGraphCommandMode read fCommandMode write SetCommandMode;
    property DraggingObjects: TEvsGraphObjectList read fDraggingObjects;
    property DragSource: TEvsGraphObject read fDragSource;
    property GraphBounds: TRect index bkGraph read GetBoundingRect;
    property Modified: Boolean read fModified write fModified;
    property Objects: TEvsGraphObjectList read fObjects;
    property SelectedObjects: TEvsGraphObjectList read fSelectedObjects;
    property ObjectAtCursor: TEvsGraphObject read fObjectAtCursor;
    /// index property will create a number of problems
    property SelectionBounds: TRect index bkSelected read GetBoundingRect;
    property DraggingBounds: TRect index bkDragging read GetBoundingRect;

    property VisibleBounds: TRect read GetVisibleBounds;
    property CursorPos: TPoint read GetCursorPos write SetCursorPos;
    property DefaultNodeClass: TEvsGraphNodeClass read fDefaultNodeClass write fDefaultNodeClass;
    property DefaultLinkClass: TEvsGraphLinkClass read fDefaultLinkClass write fDefaultLinkClass;
    property Layers[Index:Integer] : TEvsGraphLayer read GetLayer;// write SetLayer;
  published
    property HorzScrollBar: TEvsGraphScrollBar read fHorzScrollBar write SetHorzScrollBar;
    property VertScrollBar: TEvsGraphScrollBar read fVertScrollBar write SetVertScrollBar;
    property FixedScrollBars: Boolean read fFixedScrollBars write SetFixedScrollBars default False;
    //zoom moved to protected
    property ShowGrid: Boolean read fShowGrid write SetShowGrid default True;
    property GridColor: TColor read fGridColor write SetGridColor default clGray;
    property GridSize: TGridSize read fGridSize write SetGridSize default 8;
    property GraphConstraints: TEvsGraphConstraints read fGraphConstraints write SetGraphConstraints;
    property SnapToGrid: boolean read fSnapToGrid write fSnapToGrid default True;
    property Align;
    property Anchors;
    property BiDiMode;
    property ClipboardFormats: TEvsGraphClipboardFormats
      read fClipboardFormats write fClipboardFormats default [cfNative];
    property Color;
    property Constraints;
    property DefaultKeyMap: boolean
      read fDefaultKeyMap write fDefaultKeyMap default True;
    property DragCursor;
    property DragKind;
    property DragMode;
    property DrawOrder: TEvsGraphDrawOrder read fDrawOrder write SetDrawOrder default doDefault;
    property Enabled;
    property Font;
    property Height;
    property HideSelection: boolean read fHideSelection write SetHideSelection default False;
    property LockLinks: boolean read fLockLinks write SetLockLinks default False;
    property LockNodes: boolean read fLockNodes write SetLockNodes default False;
    //property OnContextPopup;
    property MarkerColor: TColor read fMarkerColor write SetMarkerColor default clBlack;
    property MarkerSize: TMarkerSize read fMarkerSize write SetMarkerSize default 3;
    property MinNodeSize: word read fMinNodeSize write fMinNodeSize default 16;
    property ObjectPopupMenu: TPopupMenu read fObjectPopupMenu write fObjectPopupMenu;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHiddenObjects: boolean read fShowHiddenObjects write SetShowHiddenObjects default False;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property Width;
    {$IFNDEF FPC}
    property OnCanResize;
    {$ENDIF}
    property OnClick;
    property OnConstrainedResize;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnDockDrop;
    property OnDockOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetSiteInfo;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
    property OnUnDock;
    property OnObjectInitInstance: TEvsGraphNotifyEvent
      read fOnObjectInitInstance write fOnObjectInitInstance;
    property OnObjectInsert: TEvsGraphNotifyEvent
      read fOnObjectInsert write fOnObjectInsert;
    property OnObjectRemove: TEvsGraphNotifyEvent
      read fOnObjectRemove write fOnObjectRemove;
    property OnObjectChange: TEvsGraphNotifyEvent
      read fOnObjectChange write fOnObjectChange;
    property OnObjectSelect: TEvsGraphNotifyEvent
      read fOnObjectSelect write fOnObjectSelect;
    property OnObjectClick: TEvsGraphNotifyEvent read fOnObjectClick write fOnObjectClick;
    property OnObjectDblClick: TEvsGraphNotifyEvent
      read fOnObjectDblClick write fOnObjectDblClick;
    property OnObjectContextPopup: TEvsGraphContextPopupEvent
      read fOnObjectContextPopup write fOnObjectContextPopup;
    property OnObjectBeforeDraw: TEvsGraphObjectDrawEvent
      read fOnObjectBeforeDraw write fOnObjectBeforeDraw;
    property OnObjectAfterDraw: TEvsGraphObjectDrawEvent
      read fOnObjectAfterDraw write fOnObjectAfterDraw;
    property OnObjectBeginDrag: TEvsGraphBeginDragEvent
      read fOnObjectBeginDrag write fOnObjectBeginDrag;
    property OnObjectEndDrag: TEvsGraphEndDragEvent
      read fOnObjectEndDrag write fOnObjectEndDrag;
    property OnObjectMouseEnter: TEvsGraphNotifyEvent
      read fOnObjectMouseEnter write fOnObjectMouseEnter;
    property OnObjectMouseLeave: TEvsGraphNotifyEvent
      read fOnObjectMouseLeave write fOnObjectMouseLeave;
    property OnObjectRead: TEvsGraphStreamEvent read fOnObjectRead write fOnObjectRead;
    property OnObjectWrite: TEvsGraphStreamEvent read fOnObjectWrite write fOnObjectWrite;
    property OnObjectHook: TEvsGraphHookEvent read fOnObjectHook write fOnObjectHook;
    property OnObjectUnhook: TEvsGraphHookEvent read fOnObjectUnhook write fOnObjectUnhook;
    property OnCanHookLink: TEvsGraphCanHookEvent read fOnCanHookLink write fOnCanHookLink;
    property OnCanLinkObjects: TEvsGraphCanLinkEvent
      read fOnCanLinkObjects write fOnCanLinkObjects;
    property OnCanMoveResizeNode: TEvsCanMoveResizeNodeEvent
      read fOnCanMoveResizeNode write fOnCanMoveResizeNode;
    property OnCanRemoveObject: TEvsGraphCanRemoveEvent
      read fOnCanRemoveObject write fOnCanRemoveObject;
    property OnNodeMoveResize: TEvsGraphNodeResizeEvent
      read fOnNodeMoveResize write fOnNodeMoveResize;
    property OnGraphChange: TNotifyEvent read fOnGraphChange write fOnGraphChange;
    property OnCommandModeChange: TNotifyEvent
      read fOnCommandModeChange write fOnCommandModeChange;
    property OnBeforeDraw: TEvsGraphDrawEvent read fOnBeforeDraw write fOnBeforeDraw;
    property OnAfterDraw: TEvsGraphDrawEvent read fOnAfterDraw write fOnAfterDraw;
    property OnInfoTip: TEvsGraphInfoTipEvent read fOnInfoTip write fOnInfoTip;
    property OnZoomChange: TNotifyEvent read fOnZoomChange write fOnZoomChange;
  end;


function WrapText(Canvas: TCanvas; const Text: string; MaxWidth: integer): string;
function MinimizeText(Canvas: TCanvas; const Text: string; const Rect: TRect): string;

function IsBetween(Value: integer; Bound1, Bound2: integer): boolean;

function NormalizeAngle(const Angle: double): double;

function EqualPoint(const Pt1, Pt2: TPoint): boolean;

procedure RotatePoints(var Points: array of TPoint; const Angle: double;const OrgPt: TPoint);
procedure ScalePoints(var Points: array of TPoint; const Factor: double;const RefPt: TPoint);
procedure ShiftPoints(var Points: array of TPoint; dX, dY: integer; const RefPt: TPoint);
procedure OffsetPoints(var Points: array of TPoint; dX, dY: integer);
function CenterOfPoints(const Points: array of TPoint): TPoint;
function BoundsRectOfPoints(const Points: array of TPoint): TRect;
function NearestPoint(const Points: array of TPoint; const RefPt: TPoint;out NearestPt: TPoint): integer;

function MakeSquare(const Center: TPoint; Radius: integer): TRect;
function MakeRect(const Corner1, Corner2: TPoint): TRect;
function CenterOfRect(const Rect: TRect): TPoint;
procedure UnionRect(var DstRect: TRect; const SrcRect: TRect);
procedure IntersectRect(var DstRect: TRect; const SrcRect: TRect);
function OverlappedRect(const Rect1, Rect2: TRect): boolean;

function LineLength(const LinePt1, LinePt2: TPoint): double;
function LineSlopeAngle(const LinePt1, LinePt2: TPoint): double;
function DistanceToLine(const LinePt1, LinePt2: TPoint; const QueryPt: TPoint): double;
function NearestPointOnLine(const LinePt1, LinePt2: TPoint; const RefPt: TPoint): TPoint;
function NextPointOfLine(const LineAngle: double; const ThisPt: TPoint;const DistanceFromThisPt: double): TPoint;

function IntersectLines(const Line1Pt: TPoint; const Line1Angle: double;const Line2Pt: TPoint;
                        const Line2Angle: double; out Intersect: TPoint): boolean;

function IntersectLineRect(const LinePt: TPoint; const LineAngle: double;const Rect: TRect): TPoints;
function IntersectLineEllipse(const LinePt: TPoint; const LineAngle: double;const Bounds: TRect): TPoints;
function IntersectLineRoundRect(const LinePt: TPoint; const LineAngle: double;const Bounds: TRect; CW, CH: integer): TPoints;
function IntersectLinePolygon(const LinePt: TPoint; const LineAngle: double;const Vertices: array of TPoint): TPoints;
function IntersectLinePolyline(const LinePt: TPoint; const LineAngle: double;const Vertices: array of TPoint): TPoints;

function TransformRgn(Rgn: HRGN; const XForm: TXForm): HRGN;

var
  CF_SIMPLEGRAPH: integer = 0;

implementation

uses Math, InterfaceBase, Clipbrd;//, Windows;

{$R Cursors.res}

resourcestring
  SListIndexError = 'Index out of range (%d)';
  SListEnumerateError = 'List enumeration is not initialized';
  SStreamContentError = 'Invalid stream content';
  SLinkCreateError = 'Cannot create link with the specified parameters';

const {$MESSAGE HINT 'NEEDS ATTENTION FOR OTHER OPERATING SYSTEMS'}
  WM_SETREDRAW = 11;
  // used to lock the drawing in a window/DC and speed up the calculations
  // although it works as it is it has no locking effect and this makes it
  // unuseful. I need to find a work around that will allow me to lock a DC for
  // drawing.

const
  EmptySize :TSize = (CX:0;CY:0;);
  StreamSignature: DWORD =
    (Ord('S') shl 24) or (Ord('G') shl 16) or (Ord('.') shl 8) or Ord('0');

  TextAlignFlags: array[TAlignment] of integer = (DT_LEFT, DT_RIGHT, DT_CENTER);
  TextLayoutFlags: array[TTextLayout] of integer = (DT_TOP, DT_VCENTER, DT_BOTTOM);

  Pi: double = System.Pi;
  MaxDouble: double = +1.7E+308;

  EmptyRect: TRect = (Left: +MaxInt; Top: +MaxInt; Right: -MaxInt; Bottom: -MaxInt);
  {$IFDEF WIN}
  //GGI_MARK_NONEXISTING_GLYPHS = $1;
  {$ENDIF}
var
  RegisteredNodeClasses: TList;
  RegisteredLinkClasses: TList;

type
  TParentControl = class(TWinControl);

  TFixed = type Integer;
  PFixedPoint = ^TFixedPoint;
  TFixedPoint = record
    X, Y: TFixed;
  end;

  PFloatPoint = ^TFloatPoint;
  TFloat = Single;
  TFloatPoint = record
    X, Y: TFloat;
  end;

const
  InViewPort = True;
  InGraph    = False;

{$REGION ' HELPER FUNCTIONS '}

function GetBezierPolyline(Control_Points: array of TPoint): TPoints;
const
  cBezierTolerance = 0.00001;
  half = 0.5;
var
   I, J, ArrayLen, ResultCnt: Integer;
   CtrlPts: array[0..3] of TFloatPoint;

  function FixedPoint(const FP: TFloatPoint): TPoint;
  begin
    Result.X := Round(FP.X * 65536);
    Result.Y := Round(FP.Y * 65536);
  end;

  function FloatPoint(const P: TPoint): TFloatPoint;overload;
  const
    F = 1 / 65536;
  begin
    with P do
    begin
      Result.X := X * F;
      Result.Y := Y * F;
    end;
  end;

  procedure RecursiveCBezier(const p1, p2, p3, p4: TFloatPoint);
   var
     p12, p23, p34, p123, p234, p1234: TFloatPoint;
   begin
     // assess flatness of curve ...
     // http://groups.google.com/group/comp.graphics.algorithms/tree/browse_frm/thread/d85ca902fdbd746e
     if abs(p1.x + p3.x - 2*p2.x) + abs(p2.x + p4.x - 2*p3.x) +
       abs(p1.y + p3.y - 2*p2.y) + abs(p2.y + p4.y - 2*p3.y) < cBezierTolerance then
     begin
       if ResultCnt = Length(Result) then
         SetLength (Result, Length(Result) + 128);
       Result[ResultCnt] := FixedPoint(p4);
       Inc(ResultCnt);
     end else
     begin
       p12.X := (p1.X + p2.X) *half;
       p12.Y := (p1.Y + p2.Y) *half;
       p23.X := (p2.X + p3.X) *half;
       p23.Y := (p2.Y + p3.Y) *half;
       p34.X := (p3.X + p4.X) *half;
       p34.Y := (p3.Y + p4.Y) *half;
       p123.X := (p12.X + p23.X) *half;
       p123.Y := (p12.Y + p23.Y) *half;
       p234.X := (p23.X + p34.X) *half;
       p234.Y := (p23.Y + p34.Y) *half;
       p1234.X := (p123.X + p234.X) *half;
       p1234.Y := (p123.Y + p234.Y) *half;
       RecursiveCBezier(p1, p12, p123, p1234);
       RecursiveCBezier(p1234, p234, p34, p4);
     end;
   end;

begin
   //first check that the 'control_points' count is valid ...
   ArrayLen := Length(Control_Points);
   if (ArrayLen < 4) or ((ArrayLen -1) mod 3 <> 0) then Exit;

   SetLength(Result, 128);
   Result[0] := Control_Points[0];
   ResultCnt := 1;
   for I := 0 to (ArrayLen div 3)-1 do
   begin
     for J := 0 to 3 do
       CtrlPts[J] := FloatPoint(Control_Points[I*3 +J]);
     RecursiveCBezier(CtrlPts[0], CtrlPts[1], CtrlPts[2], CtrlPts[3]);
   end;
   SetLength(Result, ResultCnt);
end;

function Evs_DecToRad(aAngle:Double):Double;
begin
  Result := 3.141592654 * 2 / 360 * aAngle;
end;

function RotateCCW(aPoint:Tpoint; aAngle:Double):TPoint; overload;
var
  vSinA, vCosA : Extended;
  vRads      : Double;
begin
  vRads := {3.141592654 * 2 / 360 *} aAngle;
  vSinA := Sin(vRads);vCosA := Cos(vRads);
  Result.x := round((aPoint.x * vCosA) + (aPoint.y * vSinA));
  Result.y := round(-(aPoint.x * vSinA) + (aPoint.y * vCosA));
end;
function RotateCCW(aPoint:Tpoint; aAngle:Double; aCenter:TPoint):TPoint; overload;
var
  vSinA, vCosA : Extended;
  vRads      : Double;
begin
  vRads := aAngle;
  vSinA := Sin(vRads);vCosA := Cos(vRads);
  Result.X := aPoint.x - aCenter.x;
  Result.Y := aPoint.y - aCenter.y;
  Result.x := round((Result.x * vCosA) + (Result.y * vSinA));
  Result.y := round(-(Result.x * vSinA) + (Result.y * vCosA));
  Result.x := Result.x + aCenter.x;
  Result.y := Result.y + aCenter.y;
end;

function RotateCW(aPoint:Tpoint; aAngle:Double):TPoint;overload;
var
  vSinA, vCosA : Extended;
  vRads      : Double;
begin
  vRads := {3.141592654 * 2 / 360 *} aAngle;
  vSinA := Sin(vRads);vCosA := Cos(vRads);

  Result.x := round((aPoint.x*vCosA) - (aPoint.y * vSinA));
  Result.y := round((aPoint.x*vSinA) + (aPoint.y* vCosA));
end;
function RotateCW(aPoint:Tpoint; aAngle:Double; aCenter:TPoint):TPoint; overload;
var
  vSinA, vCosA : Extended;
  vRads      : Double;
begin
  vRads := aAngle;
  vSinA := Sin(vRads);vCosA := Cos(vRads);
  Result.X := aPoint.x - aCenter.x;
  Result.Y := aPoint.y - aCenter.y;
  Result.x := round((Result.x * vCosA) - (Result.y * vSinA));
  Result.y := round((Result.x * vSinA) + (Result.y * vCosA));
  Result.x := Result.x + aCenter.x;
  Result.y := Result.y + aCenter.y;
end;

function PtInPoly
   (const Points: Array of TPoint; X,Y: Integer):
   Boolean;
var Count, K, J : Integer;
begin
  Result := False;
  Count := Length(Points) ;
  J := Count-1;
  for K := 0 to Count-1 do begin
   if ((Points[K].Y <=Y) and (Y < Points[J].Y)) or
      ((Points[J].Y <=Y) and (Y < Points[K].Y)) then
   begin
    if (x < (Points[j].X - Points[K].X) *
       (y - Points[K].Y) /
       (Points[j].Y - Points[K].Y) + Points[K].X) then
        Result := not Result;
    end;
    J := K;
  end;
end;

function CreateEmptyRgn: HRGN;
begin
  Result := CreateRectRgn(0,0,0,0);
end;

function RectInRegion(Rgn: HRGN; ARect: TRect): Boolean;
var
  RectRgn, TmpRgn: HRGN;
begin
  RectRgn := CreateRectRgnIndirect(ARect);
  try
    TmpRgn := CreateEmptyRgn;
    try
      Result := CombineRgn(TmpRgn, RectRgn, Rgn, RGN_AND) <> NULLREGION;
    finally
      DeleteObject(TmpRgn);
    end;
  finally
    DeleteObject(RectRgn);
  end;
end;

//procedure CopyParentImage(Control: TControl; DC: HDC; X, Y: integer);
//var
//  I, SaveIndex: integer;
//  SelfR, CtlR: TRect;
//  NextControl: TControl;
//begin
//  if (Control = nil) or (Control.Parent = nil) then
//    Exit;
//  with Control.Parent do
//    ControlState := ControlState + [csPaintCopy];
//  try
//    SelfR := Control.BoundsRect;
//    Inc(X, SelfR.Left);
//    Inc(Y, SelfR.Top);
//    SaveIndex := SaveDC(DC);
//    try
//      SetViewportOrgEx(DC, -X, -Y, nil);
//      with TParentControl(Control.Parent) do
//      begin
//        with ClientRect do
//          IntersectClipRect(DC, Left, Top, Right, Bottom);
//        TParentControl(Control.Parent).Perform(LM_ERASEBKGND, DC, 0);
//        PaintWindow(DC);
//      end;
//    finally
//      RestoreDC(DC, SaveIndex);
//    end;
//    for I := 0 to Control.Parent.ControlCount - 1 do
//    begin
//      NextControl := Control.Parent.Controls[I];
//      if NextControl = Control then
//        Break
//      else if (NextControl <> nil) and (NextControl is TGraphicControl) then
//      begin
//        with TGraphicControl(NextControl) do
//        begin
//          CtlR := BoundsRect;
//          if Visible and OverlappedRect(SelfR, CtlR) then
//          begin
//            ControlState := ControlState + [csPaintCopy];
//            SaveIndex := SaveDC(DC);
//            try
//              LCLIntf.SetViewPortOrgEx(DC, Left - X, Top - Y, nil);
//              IntersectClipRect(DC, 0, 0, Width, Height);
//              Perform(LM_ERASEBKGND, DC, 0);
//              Perform(LM_PAINT, DC, 0);
//            finally
//              RestoreDC(DC, SaveIndex);
//              ControlState := ControlState - [csPaintCopy];
//            end;
//          end;
//        end;
//      end;
//    end;
//  finally
//    with Control.Parent do
//      ControlState := ControlState - [csPaintCopy];
//  end;
//end;

function TransformRgn(Rgn: HRGN; const XForm: TXForm): HRGN;
{$IFDEF WIN_TRANSFORM}
var
  RgnData: PRgnData;
  RgnDataSize: DWORD;
begin
  Result := 0;
  RgnDataSize := GetRegionData(Rgn, 0, nil);
  if RgnDataSize > 0 then
  begin
    GetMem(RgnData, RgnDataSize);
    try
      GetRegionData(Rgn, RgnDataSize, RgnData);
      Result := ExtCreateRegion(@Xform, RgnDataSize, RgnData^);
    finally
      FreeMem(RgnData);
    end;
  end;
end;
{$ELSE WIN_TRANSFORM}
begin
  Result := CreateRegionCopy(Rgn);

  OffsetRgn(Result, round(XForm.eDx), round(XForm.eDy));
end;
{$ENDIF WIN_TRANSFORM}

function WrapText(Canvas: TCanvas; const Text: string; MaxWidth: integer): string;
var
  DC: HDC;
  TextExtent: TSize;
  S, P, E: PChar;
  Line: string;
  IsFirstLine: boolean;
begin
  Result := '';
  DC := Canvas.Handle;
  IsFirstLine := True;
  P := PChar(Text);
  while P^ = ' ' do
    Inc(P);
  while P^ <> #0 do
  begin
    S := P;
    E := nil;
    while (P^ <> #0) and (P^ <> #13) and (P^ <> #10) do
    begin
      LCLIntf.GetTextExtentPoint(DC, S, P - S + 1, TextExtent);
      if (TextExtent.CX > MaxWidth) and (E <> nil) then
      begin
        if (P^ <> ' ') and (P^ <> ^I) then
        begin
          while (E >= S) do
            case E^ of
              '.', ',', ';', '?', '!', '-', ':',
              ')', ']', '}', '>', '/', '\', ' ':
                break;
              else
                Dec(E);
            end;
          if E < S then
            E := P - 1;
        end;
        Break;
      end;
      E := P;
      Inc(P);
    end;
    if E <> nil then
    begin
      while (E >= S) and (P^ = ' ') do
        Dec(E);
    end;
    if E <> nil then
      SetString(Line, S, E - S + 1)
    else
      SetLength(Line, 0);
    if (P^ = #13) or (P^ = #10) then
    begin
      Inc(P);
      if (P^ <> (P - 1)^) and ((P^ = #13) or (P^ = #10)) then
        Inc(P);
      if P^ = #0 then
        Line := Line + LineEnding;
    end
    else if P^ <> ' ' then
      P := E + 1;
    while P^ = ' ' do
      Inc(P);
    if IsFirstLine then
    begin
      Result := Line;
      IsFirstLine := False;
    end
    else
      Result := Result + LineEnding + Line;
  end;
end;

function MinimizeText(Canvas: TCanvas; const Text: string; const Rect: TRect): string;
const
  vEllipsisSingle: string = '…';
  vEllipsisTriple: string = '...';
var
  vDC: HDC;
  S, E: PChar;
  vTextExtent: TSize;
  vTextHeight: integer;
  vLastLine: string;
  vEllipsis: PString;
  vMaxWidth, vMaxHeight: integer;
  vGlyphIndex: word;
  vGlyphIndexPointer : PWORD;
begin
 {$MESSAGE WARN 'MinimizeText: Heavy winapi'}

  vMaxWidth := Rect.Right - Rect.Left;
  vMaxHeight := Rect.Bottom - Rect.Top;
  Result := WrapText(Canvas, Text, vMaxWidth);
  vDC := Canvas.Handle;
  vTextHeight := 0;
  S := PChar(Result);
  while S^ <> #0 do
  begin
    E := S;
    while (E^ <> #0) and (E^ <> #13) and (E^ <> #10) do
      Inc(E);
    if E > S then
      GetTextExtentPoint(vDC, S, E - S, vTextExtent)
    else
      GetTextExtentPoint(vDC, ' ', 1, vTextExtent);
    Inc(vTextHeight, vTextExtent.CY);
    if vTextHeight <= vMaxHeight then
    begin
      S := E;
      if S^ <> #0 then
      begin
        Inc(S);
        if (S^ <> (S - 1)^) and ((S^ = #13) or (S^ = #10)) then
          Inc(S);
      end;
    end
    else
    begin
      repeat
        Dec(S);
      until (S < PChar(Result)) or ((S^ <> #13) and (S^ <> #10));
      SetLength(Result, S - PChar(Result) + 1);
      if S >= PChar(Result) then
      begin
        E := StrEnd(PChar(Result));
        S := E;
        repeat
          Dec(S)
        until (S < PChar(Result)) or ((S^ = #13) or (S^ = #10));
        SetString(vLastLine, S + 1, E - S - 1);
        SetLength(Result, S - PChar(Result) + 1);

        vEllipsis := @vEllipsisTriple;

        vLastLine := vLastLine + vEllipsis^;
        GetTextExtentPoint(vDC, PChar(vLastLine), Length(vLastLine), vTextExtent);
        while (vTextExtent.CX > vMaxWidth) and (Length(vLastLine) > Length(vEllipsis^)) do
        begin
          Delete(vLastLine, Length(vLastLine) - Length(vEllipsis^), 1);
          GetTextExtentPoint(vDC, PChar(vLastLine), Length(vLastLine), vTextExtent);
        end;
        Result := Result + vLastLine;
      end;
      Break;
    end;
  end;
end;

function Sqr(const X: double): double;inline;
begin
  Result := X * X;
end;

function IsBetween(Value: integer; Bound1, Bound2: integer): boolean; inline;
begin
  if Bound1 <= Bound2 then
    Result := (Value >= Bound1) and (Value <= Bound2)
  else
    Result := (Value >= Bound2) and (Value <= Bound1);
end;

function EqualPoint(const Pt1, Pt2: TPoint): boolean; inline;
begin
  Result := (Pt1.X = Pt2.X) and (Pt1.Y = Pt2.Y);
end;

procedure TransformPoints(var Points: array of TPoint; const XForm: TXForm);
var
  I: integer;
begin
  for I := Low(Points) to High(Points) do begin
    Points[I].X := Round(Points[I].X * XForm.eM11 + Points[I].Y * XForm.eM21 + XForm.eDx);
    Points[I].Y := Round(Points[I].X * XForm.eM12 + Points[I].Y * XForm.eM22 + XForm.eDy);
  end;
end;

procedure RotatePoints(var Points: array of TPoint; const Angle: double;
  const OrgPt: TPoint);
var
  Sin, Cos: extended;
  Prime: TPoint;
  I: integer;
begin
  SinCos(NormalizeAngle(Angle), Sin, Cos);
  for I := Low(Points) to High(Points) do
    with Points[I] do
    begin
      Prime.X := X - OrgPt.X;
      Prime.Y := Y - OrgPt.Y;
      X := Round(Prime.X * Cos - Prime.Y * Sin) + OrgPt.X;
      Y := Round(Prime.X * Sin + Prime.Y * Cos) + OrgPt.Y;
    end;
end;

procedure OffsetPoints(var Points: array of TPoint; dX, dY: integer);
var
  I: integer;
begin
  for I := Low(Points) to High(Points) do
    with Points[I] do
    begin
      Inc(X, dX);
      Inc(Y, dY);
    end;
end;

procedure ScalePoints(var Points: array of TPoint; const Factor: double;
  const RefPt: TPoint);
var
  I: integer;
  Angle: double;
  Distance: double;
begin
  for I := Low(Points) to High(Points) do
  begin
    Angle := LineSlopeAngle(Points[I], RefPt);
    Distance := LineLength(Points[I], RefPt);
    Points[I] := NextPointOfLine(Angle, RefPt, Distance * Factor);
  end;
end;

procedure ShiftPoints(var Points: array of TPoint; dX, dY: integer; const RefPt: TPoint);
var
  I: integer;
begin
  for I := Low(Points) to High(Points) do
    with Points[I] do
    begin
      if X < RefPt.X then
        Dec(X, dX)
      else if X > RefPt.X then
        Inc(X, dX);
      if Y < RefPt.Y then
        Dec(Y, dY)
      else if Y > RefPt.Y then
        Inc(Y, dY);
    end;
end;

function CenterOfPoints(const Points: array of TPoint): TPoint;
var
  I: integer;
  Sum: TPoint;
begin
  Sum.X := 0;
  Sum.Y := 0;
  for I := Low(Points) to High(Points) do
    with Points[I] do
    begin
      Inc(Sum.X, X);
      Inc(Sum.Y, Y);
    end;
  Result.X := Sum.X div Length(Points);
  Result.Y := Sum.Y div Length(Points);
end;

function BoundsRectOfPoints(const Points: array of TPoint): TRect;
var
  I: integer;
begin
  SetRect(Result, MaxInt, MaxInt, -MaxInt, -MaxInt);
  for I := Low(Points) to High(Points) do
    with Points[I], Result do
    begin
      if X < Left then
        Left := X;
      if Y < Top then
        Top := Y;
      if X > Right then
        Right := X;
      if Y > Bottom then
        Bottom := Y;
    end;
end;

function NearestPoint(const Points: array of TPoint; const RefPt: TPoint;
  out NearestPt: TPoint): integer;
var
  I: integer;
  Distance: double;
  NearestDistance: double;
begin
  Result := -1;
  NearestDistance := MaxDouble;
  for I := Low(Points) to High(Points) do
  begin
    Distance := LineLength(Points[I], RefPt);
    if Distance < NearestDistance then
    begin
      NearestDistance := Distance;
      Result := I;
    end;
  end;
  if Result >= 0 then
    NearestPt := Points[Result];
end;

function MakeSquare(const Center: TPoint; Radius: integer): TRect;
begin
  Result.TopLeft := Center;
  Result.BottomRight := Center;
  InflateRect(Result, Radius, Radius);
end;

function MakeRect(const Corner1, Corner2: TPoint): TRect;
begin
  if Corner1.X > Corner2.X then
  begin
    Result.Left := Corner2.X;
    Result.Right := Corner1.X;
  end
  else
  begin
    Result.Left := Corner1.X;
    Result.Right := Corner2.X;
  end;
  if Corner1.Y > Corner2.Y then
  begin
    Result.Top := Corner2.Y;
    Result.Bottom := Corner1.Y;
  end
  else
  begin
    Result.Top := Corner1.Y;
    Result.Bottom := Corner2.Y;
  end;
end;

function CenterOfRect(const Rect: TRect): TPoint;
begin
  Result.X := (Rect.Left + Rect.Right) div 2;
  Result.Y := (Rect.Top + Rect.Bottom) div 2;
end;

procedure UnionRect(var DstRect: TRect; const SrcRect: TRect);
begin
  if DstRect.Left > SrcRect.Left then
    DstRect.Left := SrcRect.Left;
  if DstRect.Top > SrcRect.Top then
    DstRect.Top := SrcRect.Top;
  if DstRect.Right < SrcRect.Right then
    DstRect.Right := SrcRect.Right;
  if DstRect.Bottom < SrcRect.Bottom then
    DstRect.Bottom := SrcRect.Bottom;
end;

procedure IntersectRect(var DstRect: TRect; const SrcRect: TRect);
begin
  if DstRect.Left < SrcRect.Left then
    DstRect.Left := SrcRect.Left;
  if DstRect.Top < SrcRect.Top then
    DstRect.Top := SrcRect.Top;
  if DstRect.Right > SrcRect.Right then
    DstRect.Right := SrcRect.Right;
  if DstRect.Bottom > SrcRect.Bottom then
    DstRect.Bottom := SrcRect.Bottom;
end;

function OverlappedRect(const Rect1, Rect2: TRect): boolean;
begin
  Result := (Rect1.Right >= Rect2.Left) and (Rect2.Right >= Rect1.Left) and
    (Rect1.Bottom >= Rect2.Top) and (Rect2.Bottom >= Rect1.Top);
end;

function NormalizeAngle(const Angle: double): double;
begin
  Result := Angle;
  while Result > Pi do
    Result := Result - 2 * Pi;
  while Result < -Pi do
    Result := Result + 2 * Pi;
end;

function LineLength(const LinePt1, LinePt2: TPoint): double;
begin
  Result := Sqrt(Sqr(LinePt2.X - LinePt1.X) + Sqr(LinePt2.Y - LinePt1.Y));
end;

function LineSlopeAngle(const LinePt1, LinePt2: TPoint): double;
begin
  if LinePt1.X <> LinePt2.X then
    Result := ArcTan2(LinePt2.Y - LinePt1.Y, LinePt2.X - LinePt1.X)
  else if LinePt1.Y > LinePt2.Y then
    Result := -Pi / 2
  else if LinePt1.Y < LinePt2.Y then
    Result := +Pi / 2
  else
    Result := 0;
end;

function DistanceToLine(const LinePt1, LinePt2: TPoint; const QueryPt: TPoint): double;
var
  Pt: TPoint;
begin
  Pt := NearestPointOnLine(LinePt1, LinePt2, QueryPt);
  Result := LineLength(QueryPt, Pt);
end;

function NextPointOfLine(const LineAngle: double; const ThisPt: TPoint;
  const DistanceFromThisPt: double): TPoint;
var
  X, Y, M: double;
  Angle: double;
begin
  Angle := NormalizeAngle(LineAngle);
  if Abs(Angle) <> Pi / 2 then
  begin
    M := Tan(LineAngle);
    if Abs(Angle) < Pi / 2 then
      X := ThisPt.X - DistanceFromThisPt / Sqrt(1 + Sqr(M))
    else
      X := ThisPt.X + DistanceFromThisPt / Sqrt(1 + Sqr(M));
    Y := ThisPt.Y + M * (X - ThisPt.X);
    Result.X := Round(X);
    Result.Y := Round(Y);
  end
  else
  begin
    Result.X := ThisPt.X;
    if Angle > 0 then
      Result.Y := ThisPt.Y - Round(DistanceFromThisPt)
    else
      Result.Y := ThisPt.Y + Round(DistanceFromThisPt);
  end;
end;

function NearestPointOnLine(const LinePt1, LinePt2: TPoint; const RefPt: TPoint): TPoint;
var
  LoPt, HiPt: TPoint;
  LoDis, HiDis: double;
begin
  LoPt := LinePt1;
  HiPt := LinePt2;
  Result.X := (LoPt.X + HiPt.X) div 2;
  Result.Y := (LoPt.Y + HiPt.Y) div 2;
  while ((Result.X <> LoPt.X) or (Result.Y <> LoPt.Y)) and
    ((Result.X <> HiPt.X) or (Result.Y <> HiPt.Y)) do
  begin
    LoDis := Sqrt(Sqr(RefPt.X - (LoPt.X + Result.X) div 2) +
      Sqr(RefPt.Y - (LoPt.Y + Result.Y) div 2));
    HiDis := Sqrt(Sqr(RefPt.X - (HiPt.X + Result.X) div 2) +
      Sqr(RefPt.Y - (HiPt.Y + Result.Y) div 2));
    if LoDis < HiDis then
      HiPt := Result
    else
      LoPt := Result;
    Result.X := (LoPt.X + HiPt.X) div 2;
    Result.Y := (LoPt.Y + HiPt.Y) div 2;
  end;
end;

function IntersectLines(const Line1Pt: TPoint; const Line1Angle: double;
  const Line2Pt: TPoint; const Line2Angle: double; out Intersect: TPoint): boolean;
var
  M1, M2: double;
  C1, C2: double;
begin
  Result := True;
  if (Abs(Line1Angle) = Pi / 2) and (Abs(Line2Angle) = Pi / 2) then
    // Lines have identical slope, so they are either parallel or identical
    Result := False
  else if Abs(Line1Angle) = Pi / 2 then
  begin
    M2 := Tan(Line2Angle);
    C2 := Line2Pt.Y - M2 * Line2Pt.X;
    Intersect.X := Line1Pt.X;
    Intersect.Y := Round(M2 * Intersect.X + C2);
  end
  else if Abs(Line2Angle) = Pi / 2 then
  begin
    M1 := Tan(Line1Angle);
    C1 := Line1Pt.Y - M1 * Line1Pt.X;
    Intersect.X := Line2Pt.X;
    Intersect.Y := Round(M1 * Intersect.X + C1);
  end
  else
  begin
    M1 := Tan(Line1Angle);
    M2 := Tan(Line2Angle);
    if M1 = M2 then
      // Lines have identical slope, so they are either parallel or identical
      Result := False
    else
    begin
      C1 := Line1Pt.Y - M1 * Line1Pt.X;
      C2 := Line2Pt.Y - M2 * Line2Pt.X;
      Intersect.X := Round((C1 - C2) / (M2 - M1));
      Intersect.Y := Round((M2 * C1 - M1 * C2) / (M2 - M1));
    end;
  end;
end;

function IntersectLineRect(const LinePt: TPoint; const LineAngle: double;
  const Rect: TRect): TPoints;
var
  Corners: array[0..3] of TPoint;
begin
  Corners[0].X := Rect.Left;
  Corners[0].Y := Rect.Top;
  Corners[1].X := Rect.Right;
  Corners[1].Y := Rect.Top;
  Corners[2].X := Rect.Right;
  Corners[2].Y := Rect.Bottom;
  Corners[3].X := Rect.Left;
  Corners[3].Y := Rect.Bottom;
  Result := IntersectLinePolygon(LinePt, LineAngle, Corners);
end;

function IntersectLineEllipse(const LinePt: TPoint; const LineAngle: double;
  const Bounds: TRect): TPoints;
var
  M, C: double;
  A2, B2, a, b, d: double;
  Xc, Yc, X, Y: double;
begin
  SetLength(Result, 0);
  if IsRectEmpty(Bounds) then
    Exit;
  Xc := (Bounds.Left + Bounds.Right) / 2;
  Yc := (Bounds.Top + Bounds.Bottom) / 2;
  A2 := Sqr((Bounds.Right - Bounds.Left) / 2);
  B2 := Sqr((Bounds.Bottom - Bounds.Top) / 2);
  if Abs(LineAngle) = Pi / 2 then
  begin
    d := 1 - (Sqr(LinePt.X - Xc) / A2);
    if d >= 0 then
    begin
      if d = 0 then
      begin
        SetLength(Result, 1);
        Result[0].X := LinePt.X;
        Result[0].Y := Round(Yc);
      end
      else
      begin
        C := Sqrt(B2) * Sqrt(d);
        SetLength(Result, 2);
        Result[0].X := LinePt.X;
        Result[0].Y := Round(Yc - C);
        Result[1].X := LinePt.X;
        Result[1].Y := Round(Yc + C);
      end;
    end;
  end
  else
  begin
    M := Tan(LineAngle);
    C := LinePt.Y - M * LinePt.X;
    a := (B2 + A2 * Sqr(M));
    b := (A2 * M * (C - Yc)) - B2 * Xc;
    d := Sqr(b) - a * (B2 * Sqr(Xc) + A2 * Sqr(C - Yc) - A2 * B2);
    if (d >= 0) and (a <> 0) then
    begin
      if d = 0 then
      begin
        SetLength(Result, 1);
        X := -b / a;
        Y := M * X + C;
        Result[0].X := Round(X);
        Result[0].Y := Round(Y);
      end
      else
      begin
        SetLength(Result, 2);
        X := (-b - Sqrt(d)) / a;
        Y := M * X + C;
        Result[0].X := Round(X);
        Result[0].Y := Round(Y);
        X := (-b + Sqrt(d)) / a;
        Y := M * X + C;
        Result[1].X := Round(X);
        Result[1].Y := Round(Y);
      end;
    end;
  end;
end;

function IntersectLineRoundRect(const LinePt: TPoint; const LineAngle: double;
  const Bounds: TRect; CW, CH: integer): TPoints;
var
  I: integer;
  CornerBounds: TRect;
  CornerIntersects: TPoints;
  W, H, Xc, Yc, dX, dY: integer;
begin
  Result := IntersectLineRect(LinePt, LineAngle, Bounds);
  if Length(Result) > 0 then
  begin
    W := Bounds.Right - Bounds.Left;
    H := Bounds.Bottom - Bounds.Top;
    Xc := (Bounds.Left + Bounds.Right) div 2;
    Yc := (Bounds.Top + Bounds.Bottom) div 2;
    for I := 0 to Length(Result) - 1 do
    begin
      dX := Result[I].X - Xc;
      dY := Result[I].Y - Yc;
      if ((W div 2) - (Abs(dX)) < (CW div 2)) and
        (((H div 2) - Abs(dY)) < (CH div 2)) then
      begin
        SetRect(CornerBounds, Bounds.Left, Bounds.Top, Bounds.Left +
          CW, Bounds.Top + CH);
        if dX > 0 then
          OffsetRect(CornerBounds, W - CW, 0);
        if dY > 0 then
          OffsetRect(CornerBounds, 0, H - CH);
        CornerIntersects := IntersectLineEllipse(LinePt, LineAngle, CornerBounds);
        try
          if Length(CornerIntersects) = 2 then
            if dX < 0 then
              Result[I] := CornerIntersects[0]
            else
              Result[I] := CornerIntersects[1];
        finally
          SetLength(CornerIntersects, 0);
        end;
      end;
    end;
  end;
end;

function IntersectLinePolygon(const LinePt: TPoint; const LineAngle: double;
  const Vertices: array of TPoint): TPoints;
var
  I: integer;
  V1, V2: integer;
  EdgeAngle: double;
  Intersect: TPoint;
begin
  SetLength(Result, 0);
  for I := Low(Vertices) to High(Vertices) do
  begin
    V1 := I;
    V2 := Succ(I) mod Length(Vertices);
    EdgeAngle := LineSlopeAngle(Vertices[V1], Vertices[V2]);
    if IntersectLines(LinePt, LineAngle, Vertices[V1], EdgeAngle, Intersect) and
      IsBetween(Intersect.X, Vertices[V1].X, Vertices[V2].X) and
      IsBetween(Intersect.Y, Vertices[V1].Y, Vertices[V2].Y) then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[Length(Result) - 1] := Intersect;
    end;
  end;
end;

function IntersectLinePolyline(const LinePt: TPoint; const LineAngle: double;
  const Vertices: array of TPoint): TPoints;
var
  I: integer;
  V1, V2: integer;
  EdgeAngle: double;
  Intersect: TPoint;
begin
  SetLength(Result, 0);
  for I := Low(Vertices) to Pred(High(Vertices)) do
  begin
    V1 := I;
    V2 := Succ(I);
    EdgeAngle := LineSlopeAngle(Vertices[V1], Vertices[V2]);
    if IntersectLines(LinePt, LineAngle, Vertices[V1], EdgeAngle, Intersect) and
      IsBetween(Intersect.X, Vertices[V1].X, Vertices[V2].X) and
      IsBetween(Intersect.Y, Vertices[V1].Y, Vertices[V2].Y) then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[Length(Result) - 1] := Intersect;
    end;
  end;
end;

{ TEvsCustomGraphPainter }

procedure TEvsCustomGraphPainter.SetGraph(AValue: TEvsSimpleGraph);
begin
  if FGraph=AValue then Exit;
  if Assigned(FGraph) and (not (csDestroying in FGraph.ComponentState)) then begin
    FGraph.RemoveFreeNotification(Self); //be a good boy and clean up after your self.
    FGraph.CustomCanvas := Nil;
    FGraph.OnCanvasInit:= nil;
  end;
  FGraph := AValue;
  if Assigned(FGraph) then begin
    FGraph.FreeNotification(Self);
    FGraph.CustomCanvas := GetCanvas;
    FGraph.OnCanvasInit := @CanvasInit;;
    FGraph.Repaint;
  end;
end;

procedure TEvsCustomGraphPainter.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  if (Operation = opRemove) and (AComponent = FGraph) then FGraph := Nil;
  inherited Notification(AComponent, Operation);
end;

{$ENDREGION}

{$REGION ' TEvsGraphObjectListEnumerator '}

constructor TEvsGraphObjectListEnumerator.Create(aList : TEvsGraphObjectList);
begin
  inherited Create;
  FGraphList := aList;
  FPosition := -1;
end;

function TEvsGraphObjectListEnumerator.GetCurrent : TEvsGraphObject;
begin
  Result := FGraphList[FPosition];
end;

function TEvsGraphObjectListEnumerator.MoveNext : Boolean;
begin
  Inc(FPosition);
  Result := FPosition < FGraphList.Count;
end;
{$ENDREGION}

{$REGION ' TEvsGraphObjectListReverseEnumerator '}

constructor TEvsGraphObjectListReverseEnumerator.Create(
  aList : TEvsGraphObjectList);
begin
  inherited Create;
  FGraphList := aList;
  FPosition := aList.Count;
end;

function TEvsGraphObjectListReverseEnumerator.GetCurrent : TEvsGraphObject;
begin
  Result := FGraphList[FPosition];
end;

function TEvsGraphObjectListReverseEnumerator.MoveNext : Boolean;
begin
  Dec(FPosition);
  Result := FPosition > -1;
end;

{$ENDREGION}

{$REGION ' TEvsGraphLayerList '}

function TEvsGraphLayerList.GetCount: Integer;
begin
  Result := fList.Count;
end;

function TEvsGraphLayerList.GetLayer(Index: Integer): TEvsGraphLayer;
begin
  Result := TEvsGraphLayer(fList[Index]);
end;

procedure TEvsGraphLayerList.PackIDs;
var
  vCntr :Integer;
begin
  for vCntr := 0 to FList.Count -1 do begin
    Layers[vCntr].ID := vCntr+1;
  end;
  FLastID := FList.Count;
end;

function TEvsGraphLayerList.UniqueName(const prefix :String) :String;
var
  vDone : Boolean;
  vCntr : Integer;
begin
  vDone := False;
  vCntr:=1;
  Result := prefix + ' ' + IntToStr(vCntr);
  repeat
    Result := prefix +  ' ' + IntToStr(vCntr);
    vDone  := (ByName(Result) = nil);
    Inc(vCntr);
  until vDone;
end;

function TEvsGraphLayerList.ByID(const aID :integer) :TEvsGraphLayer;
var
  vCntr :Integer;
begin
  Result := nil;
  for vCntr := 0 to Count -1 do
    if Layers[vCntr].ID = aID then Exit(Layers[vCntr]);
end;

function TEvsGraphLayerList.ByName(const aName :String) :TEvsGraphLayer;
var
  vCntr :Integer;
begin
  Result := nil;
  for vCntr := 0 to Count -1 do
    if CompareText(Layers[vCntr].Name,aName) = 0  then Exit(Layers[vCntr]);
end;

constructor TEvsGraphLayerList.Create;
begin
  inherited Create;
  fList := TFPList.Create;
end;

destructor TEvsGraphLayerList.Destroy;
begin
  fList.Free;
  inherited Destroy;
end;

function TEvsGraphLayerList.New: TEvsGraphLayer;
begin
  Result := TEvsGraphLayer.Create;
  Result.Name := UniqueName('Layer');
  fList.Add(Result);
end;

function TEvsGraphLayerList.Delete(Index: integer): Boolean;
var
  DelLayer : TEvsGraphLayer;
begin
  Result := False;
  DelLayer := TEvsGraphLayer(fList[Index]);
  fList.Delete(Index);
  DelLayer.Free;
  Result := True;
end;

function TEvsGraphLayerList.Delete(Layer: TEvsGraphLayer): Boolean;
var
  Idx : integer;
begin
  Result := False;
  Idx:=fList.IndexOf(Layer);
  if Idx > -1 then begin
    fList.Delete(Idx);
    Layer.Free;
    Result:=True;
  end;
end;
{$ENDREGION}

{$REGION ' TGraphLayer '}

function TEvsGraphLayer.GetCount: Integer;
begin
  Result:= FTop - FBottom;
end;

procedure TEvsGraphLayer.SetID(AValue: Integer);
begin
  if FID=AValue then Exit;
  FID:=AValue;
end;

procedure TEvsGraphLayer.SetLocked(AValue: Boolean);
begin
  if FLocked=AValue then Exit;
  FLocked:=AValue;
end;

procedure TEvsGraphLayer.SetPrintable(AValue: Boolean);
begin
  if FPrintable=AValue then Exit;
  FPrintable:=AValue;
end;

procedure TEvsGraphLayer.SetVisible(AValue: Boolean);
begin
  if FVisible=AValue then Exit;
  FVisible:=AValue;
end;

function TEvsGraphLayer.CanAdd(const aObject: TEvsGraphObject): Boolean;
begin
  Result :=  True;  //not aObject.IsLocked and aObject.Visible and aObject.canmove;
end;

function TEvsGraphLayer.CanRemove(const aObject: TevsGraphObject): Boolean;
begin
  Result := True;
end;

procedure TEvsGraphLayer.SlideUp(Count: Integer);
begin
  inc(FBottom, Count);
  inc(FTop   , Count);
end;

procedure TEvsGraphLayer.SlideDown(Count: Integer);
begin
  Dec(FTop   , Count);
  Dec(FBottom, Count);
end;

function TEvsGraphLayer.Add(Const aObject :TEvsGraphObject) :Integer;
begin
  Result := -1;
  if CanAdd(aObject) then begin;
    if (aObject.ZOrder>FTop) or (aObject.ZOrder < 0) then begin
      aObject.ZOrder := FTop+1;
      FTop := aObject.ZOrder;
    end else if (aObject.ZOrder < FBottom) then begin
      aObject.ZOrder := FBottom -1;
      FBottom := aObject.ZOrder;
    end;
    Result := aObject.ZOrder;
  end;
end;

procedure TEvsGraphLayer.Remove(const OldZOrder, NewZOrder: Integer);
begin
  if NewZOrder < FBottom then Inc(FBottom);
  if NewZOrder > FTop then Dec(FTop);
end;


{$ENDREGION}

{$REGION ' TEvsGraphScrollBar '}
procedure TEvsGraphScrollBar.DoSetRange(Value: Integer);
var
  NewRange: Integer;
begin
  if Value <= 0 then
    NewRange := 0
  else
    NewRange := MulDiv(Value, Owner.Zoom, 100);
  if fRange <> NewRange then
  begin
    fRange := NewRange;
    Owner.UpdateScrollBars;
  end;
end;

function TEvsGraphScrollBar.InternalGetScrollPos: integer;
begin
  Result := 0;
  if Visible then
    Result := Position;
end;

procedure TEvsGraphScrollBar.SetButtonSize(AValue: integer);
const
  SysConsts: array[TScrollBarKind] of integer = (SM_CXHSCROLL, SM_CXVSCROLL);
var
  NewValue: integer;
begin
  if AValue <> ButtonSize then
  begin
    NewValue := AValue;
    if NewValue = 0 then
      AValue := GetSystemMetrics(SysConsts[Kind]);
    fButtonSize := AValue;
    fUpdateNeeded := True;
    Owner.UpdateScrollBars;
    if NewValue = 0 then
      fButtonSize := 0;
  end;
end;

procedure TEvsGraphScrollBar.SetColor(AValue: TColor);
begin
  if AValue <> Color then
  begin
    fColor := AValue;
    fParentColor := False;
    fUpdateNeeded := True;
    Owner.UpdateScrollBars;
  end;
end;

procedure TEvsGraphScrollBar.SetParentColor(Value: boolean);
begin
  if ParentColor <> Value then
  begin
    fParentColor := Value;
    if Value then
      Color := Owner.Parent.Color;//Self. ParentColor clBtnHighlight;
  end;
end;

procedure TEvsGraphScrollBar.SetPosition(AValue: Integer);
var
  Code: word;
  Form: TCustomForm;
  OldPos: integer;
  TestPos : integer;
  MsgStr  :string ='';
begin
  if csReading in Owner.ComponentState then
    fPosition := AValue
  else
  begin
    if AValue > fCalcRange then
      AValue := fCalcRange
    else if AValue < 0 then
      AValue := 0;
    if Kind = sbHorizontal then
      Code := SB_HORZ
    else
      Code := SB_VERT;
    if AValue <> FPosition then
    begin
      OldPos := FPosition;
      fPosition := AValue;
      if Kind = sbHorizontal then
        Owner.ScrollBy(OldPos - AValue, 0)
      else
        Owner.ScrollBy(0, OldPos - AValue);
      if csDesigning in Owner.ComponentState then
      begin
        Form := GetParentForm(Owner);
        if Assigned(Form) and Assigned(Form.Designer) then
          Form.Designer.Modified;
      end;
    end;

    if GetScrollPos(Owner.Handle, Code) <> FPosition then
      SetScrollPos(Owner.Handle, Code, FPosition, True);
  end;
end;

procedure TEvsGraphScrollBar.SetSize(Value: integer);
const
  SysConsts: array[TScrollBarKind] of integer = (SM_CYHSCROLL, SM_CYVSCROLL);
var
  NewValue: integer;
begin
  if Value <> Size then
  begin
    NewValue := Value;
    if NewValue = 0 then
      Value := GetSystemMetrics(SysConsts[Kind]); {NEEDS TO BE TESTED WITH NON WINDOWS CLIENTS}
    fSize := Value;
    fUpdateNeeded := True;
    Owner.UpdateScrollBars;
    if NewValue = 0 then
      fSize := 0;
  end;
end;

procedure TEvsGraphScrollBar.SetStyle(Value: TScrollBarStyle);
begin
  if fStyle <> Value then
  begin
    fStyle := Value;
    fUpdateNeeded := True;
    Owner.UpdateScrollBars;
  end;
end;

procedure TEvsGraphScrollBar.SetThumbSize(Value: integer);
begin
  if ThumbSize <> Value then
  begin
    fThumbSize := Value;
    fUpdateNeeded := True;
    Owner.UpdateScrollBars;
  end;
end;

procedure TEvsGraphScrollBar.SetVisible(AValue: boolean);
begin
  if fVisible=AValue then Exit;
  fVisible := AValue;
  Owner.UpdateScrollBars;
end;

function TEvsGraphScrollBar.IsIncrementStored: boolean;
begin
  Result := not Smooth;
end;

constructor TEvsGraphScrollBar.Create(AOwner: TEvsSimpleGraph; AKind: TScrollBarKind);
begin
  inherited Create;
  fOwner := AOwner;
  fKind := AKind;
  fPageIncrement := 100;
  fIncrement := 60;//fPageIncrement div 10;
  fVisible := True;
  fDelay := 10;
  fLineDiv := 4;
  fPageDiv := 12;
  fColor := clBtnHighlight;
  fParentColor := True;
  fUpdateNeeded := True;
  fStyle := ssRegular;
end;

procedure TEvsGraphScrollBar.CalcAutoRange;
var
  NewRange, AlignMargin: Integer;

  procedure ProcessHorz(Control: TControl);
  begin
    if Control.Visible then
      case Control.Align of
        alLeft, alNone:
          if (Control.Align = alLeft) or (Control.Anchors * [akLeft, akRight] = [akLeft]) then
            NewRange := Max(NewRange, Position + Control.Left + Control.Width);
        alRight: Inc(AlignMargin, Control.Width);
      end;
  end;

  procedure ProcessVert(Control: TControl);
  begin
    if Control.Visible then
      case Control.Align of
        alTop, alNone:
          if (Control.Align = alTop) or (Control.Anchors * [akTop, akBottom] = [akTop]) then
            NewRange := Max(NewRange, Position + Control.Top + Control.Height);
        alBottom: Inc(AlignMargin, Control.Height);
      end;
  end;

var
  I: Integer;
begin
  case fKind of
    sbHorizontal:
      if not Owner.FixedScrollBars then
      begin
        NewRange := 1;
        if Owner.ValidMarkedArea then
          with Owner.MarkedArea do
            if NewRange < Right then
              NewRange := Right;
        with Owner.GraphBounds do
          if NewRange < Right then
            NewRange := Right;
      end
      else
        NewRange := Owner.GraphConstraints.MaxRight;
    sbVertical:
      if not Owner.FixedScrollBars then begin
        NewRange := 1;
        if Owner.ValidMarkedArea then
          with Owner.MarkedArea do
            if NewRange < Bottom then
              NewRange := Bottom;
        with Owner.GraphBounds do
          if NewRange < Bottom then
            NewRange := Bottom;
      end else
        NewRange := Owner.GraphConstraints.MaxBottom;
  else
    Exit;
  end;
  AlignMargin := 0;
  for I := 0 to Owner.ControlCount - 1 do
    case fKind of
      sbHorizontal:
        ProcessHorz(Owner.Controls[I]);
      sbVertical:
        ProcessVert(Owner.Controls[I]);
    end;
  NewRange:=NewRange + 10;// 10 pixels from bottom and right as a margin so the shapes are visible always.
  DoSetRange(NewRange + AlignMargin + fMargin);
end;

function TEvsGraphScrollBar.NeedsScrollBarVisible: Boolean;
begin
  Result := fRange > ControlSize(False, False);
end;

procedure TEvsGraphScrollBar.ScrollMessage(var Msg: TLMScroll);
var
  Incr, FinalIncr, Count: integer;
  CurrentTime, StartTime, ElapsedTime: longint;

  //function GetRealScrollPosition: integer;
  //var
  //  SI: TScrollInfo;
  //  Code: integer;
  //begin
  //  SI.cbSize := SizeOf(TScrollInfo);
  //  SI.fMask := SIF_TRACKPOS;
  //  Code := SB_HORZ;
  //  if fKind = sbVertical then
  //    Code := SB_VERT;
  //  Result := Msg.Pos;//+6;
  //  //if GetScrollInfo(Owner.Handle, Code, SI) then
  //  //  Result := SI.nTrackPos;
  //end;
begin
  with Msg do
  begin
    if fSmooth and (ScrollCode in [SB_LINEUP, SB_LINEDOWN, SB_PAGEUP, SB_PAGEDOWN]) then
    begin
      case ScrollCode of
        SB_LINEUP, SB_LINEDOWN:
        begin
          Incr := fIncrement div fLineDiv;
          FinalIncr := fIncrement mod fLineDiv;
          Count := fLineDiv;
        end;
        SB_PAGEUP, SB_PAGEDOWN:
        begin
          Incr := FPageIncrement;
          FinalIncr := Incr mod fPageDiv;
          Incr := Incr div fPageDiv;
          Count := fPageDiv;
        end;
        else
          Count := 0;
          Incr := 0;
          FinalIncr := 0;
      end;
      CurrentTime := 0;
      while Count > 0 do
      begin
        StartTime := GetTickCount;
        ElapsedTime := StartTime - CurrentTime;
        if ElapsedTime < fDelay then
          Sleep(fDelay - ElapsedTime);
        CurrentTime := StartTime;
        case ScrollCode of
          SB_LINEUP: SetPosition(fPosition - Incr);
          SB_LINEDOWN: SetPosition(fPosition + Incr);
          SB_PAGEUP: SetPosition(fPosition - Incr);
          SB_PAGEDOWN: SetPosition(fPosition + Incr);
        end;
        Owner.Update;
        Dec(Count);
      end;
      if FinalIncr > 0 then
      begin
        case ScrollCode of
          SB_LINEUP: SetPosition(fPosition - FinalIncr);
          SB_LINEDOWN: SetPosition(fPosition + FinalIncr);
          SB_PAGEUP: SetPosition(fPosition - FinalIncr);
          SB_PAGEDOWN: SetPosition(fPosition + FinalIncr);
        end;
      end;
    end
    else begin
      case ScrollCode of
        SB_LINEUP: SetPosition(fPosition - fIncrement);
        SB_LINEDOWN: SetPosition(fPosition + fIncrement);
        SB_PAGEUP: SetPosition(fPosition - ControlSize(True, False));
        SB_PAGEDOWN: SetPosition(fPosition + ControlSize(True, False));
        SB_THUMBPOSITION:
          //if fCalcRange > 32767 then
          //  //SetPosition(GetRealScrollPosition)
          //else
          begin
            if FLastMsgPos = Pos then Exit;
            FLastMsgPos:=Pos;
            if abs(fPosition-Pos) < fIncrement then begin
              if fPosition < Pos then
                Pos := Pos+fIncrement
                //SetPosition(Pos+fIncrment)
              else if fPosition > Pos then
                Pos := Pos-fIncrement;
              SetPosition(Pos);
            end else SetPosition(Pos);
          end;
        SB_THUMBTRACK:
          if Tracking then
            //if fCalcRange > 32767 then
            //  SetPosition(GetRealScrollPosition)
            //else
              SetPosition(Pos);
        SB_TOP: SetPosition(0);
        SB_BOTTOM: SetPosition(fCalcRange);
        SB_ENDSCROLL:
        begin
        end;
      end;
      Owner.Invalidate;
    end;
  end;
end;

procedure TEvsGraphScrollBar.Assign(Source: TPersistent);
begin
  if Source is TEvsGraphScrollBar then
  begin
    DoSetRange(TEvsGraphScrollBar(Source).Range);
    Visible := TEvsGraphScrollBar(Source).Visible;
    Position := TEvsGraphScrollBar(Source).Position;
    ButtonSize := TEvsGraphScrollBar(Source).ButtonSize;
    Color := TEvsGraphScrollBar(Source).Color;
    ParentColor := TEvsGraphScrollBar(Source).ParentColor;
    Increment := TEvsGraphScrollBar(Source).Increment;
    Margin := TEvsGraphScrollBar(Source).Margin;
    Smooth := TEvsGraphScrollBar(Source).Smooth;
    Size := TEvsGraphScrollBar(Source).Size;
    Style := TEvsGraphScrollBar(Source).Style;
    ThumbSize := TEvsGraphScrollBar(Source).ThumbSize;
    Tracking := TEvsGraphScrollBar(Source).Tracking;
  end
  else
    inherited Assign(Source);
end;

procedure TEvsGraphScrollBar.ChangeBiDiPosition;
begin
  if Kind = sbHorizontal then
    if IsScrollBarVisible then
      if not Owner.UseRightToLeftScrollBar then
        Position := 0
      else
        Position := Range;
end;

function TEvsGraphScrollBar.IsScrollBarVisible: boolean;
var
  vStyle: longint;
begin
  {$IFDEF WIN}
  if Kind = sbVertical then
    vStyle := WS_VSCROLL
  else
    vStyle := WS_HSCROLL;
  Result := Visible and ((GetWindowLong(Owner.Handle, GWL_STYLE) and vStyle) <> 0);
  {$ELSE}
  if Kind = sbVertical then vStyle := SB_VERT
  else vStyle := SB_HORZ;
  Result := Visible;
  if Owner.HandleAllocated then
    Result := Result and GetScrollbarVisible(Owner.Handle, vStyle);
  {$ENDIF}
end;

function TEvsGraphScrollBar.ControlSize(ControlSB, AssumeSB: Boolean): Integer;
var
  BorderAdjust: Integer;

  function ScrollBarVisible(Code: Word): Boolean;
  var
    Style: Longint;
  begin
    Style := WS_HSCROLL;
    if Code = SB_VERT then Style := WS_VSCROLL;
    Result := GetWindowLong(Owner.Handle, GWL_STYLE) and Style <> 0;
  end;

  function Adjustment(Code, Metric: Word): Integer;
  begin
    Result := 0;
    if not ControlSB then
      if AssumeSB and not ScrollBarVisible(Code) then
        Result := -(GetSystemMetrics(Metric) - BorderAdjust)
      else if not AssumeSB and ScrollBarVisible(Code) then
        Result := GetSystemMetrics(Metric) - BorderAdjust;
  end;

begin
  BorderAdjust := Integer((GetWindowLong(Owner.Handle, GWL_STYLE) and
    (WS_BORDER or WS_THICKFRAME)) <> 0);
  if Kind = sbVertical then
    Result := Owner.ClientHeight + Adjustment(SB_HORZ, SM_CXHSCROLL)
  else
    Result := Owner.ClientWidth + Adjustment(SB_VERT, SM_CYVSCROLL);
end;

procedure TEvsGraphScrollBar.Update(ControlSB, AssumeSB: Boolean);
type
  TPropKind = (pkStyle, pkButtonSize, pkThumbSize, pkSize, pkBkColor);

var
  Code: word;
  ScrollInfo: TScrollInfo;

  procedure UpdateScrollProperties(Redraw: boolean);
  begin
    {$MESSAGE WARN 'UpdateScrollProperties needs implementation'}
  end;

begin
  fCalcRange := 0;
  if Kind = sbVertical then
    Code := SB_VERT
  else
    Code := SB_HORZ;
  if Visible then
  begin
    fCalcRange := Range - ControlSize(ControlSB, AssumeSB);
    if fCalcRange < 0 then
      fCalcRange := 0;
  end;
  ScrollInfo.cbSize := SizeOf(ScrollInfo);
  ScrollInfo.fMask := SIF_ALL;
  ScrollInfo.nMin := 0;
  if fCalcRange > 0 then
    ScrollInfo.nMax := Range
  else
    ScrollInfo.nMax := 0;
  ScrollInfo.nPage := ControlSize(ControlSB, AssumeSB) + 1;
  ScrollInfo.nPos := fPosition;
  ScrollInfo.nTrackPos := fPosition;
  UpdateScrollProperties(fUpdateNeeded);
  fUpdateNeeded := False;
  SetScrollInfo(Owner.Handle, Code, ScrollInfo, True);
  SetPosition(fPosition);
  fPageIncrement := (ControlSize(True, False) * 9) div 10;
end;

{$ENDREGION}

{$REGION ' TEvsSimpleGraph '}
procedure TEvsSimpleGraph.SetHorzScrollBar(AValue: TEvsGraphScrollBar);
begin
  fHorzScrollBar.Assign(AValue);
end;

procedure TEvsSimpleGraph.SetLayer(Index :Integer; aValue :TEvsGraphLayer);
begin
  //FLayers.Layers[Index] := aValue;
end;

procedure TEvsSimpleGraph.SetLockNodes(Value: boolean);
begin
  if LockNodes <> Value then
  begin
    fLockNodes := Value;
    Invalidate;
  end;
end;

procedure TEvsSimpleGraph.SetLockLinks(Value: boolean);
begin
  if LockLinks <> Value then
  begin
    fLockLinks := Value;
    Invalidate;
  end;
end;

procedure TEvsSimpleGraph.SetMarkedArea(AValue: TRect);
begin
  if not LCLIntf.EqualRect(MarkedArea, AValue) then
  begin
    if fValidMarkedArea then
      InvalidateRect(fMarkedArea);
    fMarkedArea := AValue;
    fValidMarkedArea := (AValue.Left <= AValue.Right) and (AValue.Top <= AValue.Bottom);
    CalcAutoRange;
    if fValidMarkedArea then
      InvalidateRect(fMarkedArea);
  end;
end;

procedure TEvsSimpleGraph.SetMarkerColor(Value: TColor);
begin
  if MarkerColor <> Value then
  begin
    fMarkerColor := Value;
    if SelectedObjects.Count > 0 then
      Invalidate;
  end;
end;

procedure TEvsSimpleGraph.SetMarkerSize(Value: TMarkerSize);
begin
  if MarkerSize <> Value then
  begin
    fMarkerSize := Value;
    if SelectedObjects.Count > 0 then
      Invalidate;
  end;
end;

procedure TEvsSimpleGraph.SetShowHiddenObjects(Value: boolean);
begin
  if ShowHiddenObjects <> Value then
  begin
    fShowHiddenObjects := Value;
    CalcAutoRange;
    Invalidate;
  end;
end;

procedure TEvsSimpleGraph.SetHideSelection(Value: boolean);
begin
  if HideSelection <> Value then
  begin
    fHideSelection := Value;
    if not Focused and (SelectedObjects.Count > 0) then
      InvalidateRect(SelectionBounds);
  end;
end;

procedure TEvsSimpleGraph.SetFixedScrollBars(AValue: Boolean);
begin
  if fFixedScrollBars = AValue then Exit;
  fFixedScrollBars := AValue;
  CalcAutoRange;
end;

procedure TEvsSimpleGraph.SetGraphConstraints(AValue: TEvsGraphConstraints);
begin
  fGraphConstraints.Assign(AValue);
end;

procedure TEvsSimpleGraph.SetGridColor(AValue: TColor);
begin
  if fGridColor=AValue then Exit;
  fGridColor:=AValue;
  if ShowGrid then Invalidate;
end;

procedure TEvsSimpleGraph.SetGridSize(AValue: TGridSize);
begin
  if fGridSize=AValue then Exit;
  fGridSize:=AValue;
  if ShowGrid then Invalidate;
end;

function TEvsSimpleGraph.GetCursorPos: TPoint;
begin
  with ScreenToClient(Mouse.CursorPos) do
    Result := ClientToGraph(X, Y);
end;

function TEvsSimpleGraph.GetBoundingRect(Kind: TEvsGraphBoundsKind): TRect;
begin
  if Kind in SaveBoundsChange then
  begin
    case Kind of
      bkGraph:
        SaveBounds[Kind] := GetObjectsBounds(Objects);
      bkSelected:
        SaveBounds[Kind] := GetObjectsBounds(SelectedObjects);
      bkDragging:
        SaveBounds[Kind] := GetObjectsBounds(DraggingObjects);
    end;
    Exclude(SaveBoundsChange, Kind);
  end;
  Result := SaveBounds[Kind];
end;

function TEvsSimpleGraph.GetMidPoint : TPoint;
var
  vBounds : TRECT;
begin
  vBounds := GetObjectsBounds(fObjects);
  Result.Y := (vBounds.Top + vBounds.Bottom) div 2;
  Result.X := (vBounds.Left + vBounds.Right) div 2;
end;

function TEvsSimpleGraph.GetLayer(Index :Integer) :TEvsGraphLayer;
begin
  Result := FLayers.Layers[Index];
end;

function TEvsSimpleGraph.GetVisibleBounds: TRect;
begin
  Result := ClientRect;
  CPToGP(Result, 2);
end;

procedure TEvsSimpleGraph.SetCommandMode(AValue: TEvsGraphCommandMode);
begin
  if CommandMode <> AValue then
  begin
    if Assigned(DragSource) then
      DragSource.EndDrag(False);
    fCommandMode := AValue;
    if not (CommandMode in [cmPan, cmEdit]) then
      SelectedObjects.Clear;
    CalcAutoRange;
    DoCommandModeChange;
  end;
end;

procedure TEvsSimpleGraph.SetCursorPos(const Pt: TPoint);
begin
  Mouse.CursorPos := ClientToScreen(GraphToClient(Pt.X, Pt.Y));
end;

procedure TEvsSimpleGraph.SetCustomCanvas(aValue :TCanvasClass);
begin
  if FCustomCanvas = aValue then Exit;
  FCustomCanvas := aValue;
  //if (FCustomCanvas.ClassType <> Canvas.ClassType) and FCustomCanvas.InheritsFrom(TControlCanvas) then begin
  //  Canvas.Free;;
  //  Canvas := FCustomCanvas.Create;
  //  TControlCanvas(FCustomCanvas).Control := Self;
  //end;//nice idea will not work the create method is not virtual.
end;

procedure TEvsSimpleGraph.SetDrawOrder(Value: TEvsGraphDrawOrder);
begin
  if DrawOrder <> Value then
  begin
    fDrawOrder := Value;
    Invalidate;
  end;
end;

procedure TEvsSimpleGraph.UpdateScrollBars;
begin
  if not UpdatingScrollBars and HandleAllocated then
  begin
    try
      UpdatingScrollBars := True;
      if VertScrollBar.NeedsScrollBarVisible then
      begin
        HorzScrollBar.Update(False, True);
        VertScrollBar.Update(True, False);
      end
      else if HorzScrollBar.NeedsScrollBarVisible then
      begin
        VertScrollBar.Update(False, True);
        HorzScrollBar.Update(True, False);
      end
      else
      begin
        VertScrollBar.Update(False, False);
        HorzScrollBar.Update(True, False);
      end;
    finally
      UpdatingScrollBars := False;
    end;
  end;
end;

procedure TEvsSimpleGraph.SetShowGrid(AValue: Boolean);
begin
  if fShowGrid <> AValue then begin
    fShowGrid:=AValue;
    Invalidate;
  end;
end;

procedure TEvsSimpleGraph.SetVertScrollBar(AValue: TEvsGraphScrollBar);
begin
  FVertScrollBar.Assign(AValue);
end;
procedure SaveRawData(InStream:TStream; outFile:String);
var
  vFS : TFileStream;
begin
  vFS := TFileStream.Create(outFile,fmCreate);
  vFS.CopyFrom(InStream, InStream.Size);
  vFS.Free;
end;

function TEvsSimpleGraph.PasteFromClipboard: boolean;
var
  vStream: TMemoryStream;
  I, vCount: integer;
begin
  Result := False;
  if Clipboard.HasFormat(CF_SIMPLEGRAPH) then
  begin
    Clipboard.Open;
    try
      vStream := TMemoryStream.Create;
      try
        Clipboard.GetFormat(CF_SIMPLEGRAPH, vStream);
        BeginUpdate;
        try
          SelectedObjects.Clear;
          vCount := Objects.Count;
          vStream.Position:=0;
          ReadObjects(vStream);
          SelectedObjects.Capacity := Objects.Count - vCount;
          for I := Objects.Count - 1 downto vCount do
            Objects[I].Selected := True;
          OffsetObjects(SelectedObjects, 10, 10);
          Result := True;
        finally
          EndUpdate;
        end;
      finally
        vStream.Free;
      end;
    finally
      Clipboard.Close;
    end;
  end;
end;

procedure TEvsSimpleGraph.SaveAsBitmap(const aFilename: string);
var
  vBitmap: Graphics.TBitmap;
begin
  vBitmap := GetAsBitmap(Objects);
  try
    vBitmap.SaveToFile(aFilename);
  finally
    vBitmap.Free;
  end;
end;

procedure TEvsSimpleGraph.CopyToClipboard(aSelection :Boolean);
var
  vObjectList: TEvsGraphObjectList;
  vStream : TMemoryStream;
  {$IFDEF METAFILE_SUPPORT}
  vMetafile: TMetafile;
  {$ENDIF}
  vBitmap: Graphics.TBitmap;
begin
  if CF_SIMPLEGRAPH =0 then
    CF_SIMPLEGRAPH := RegisterClipboardFormat('Simple Graph Format');
  if aSelection then
    vObjectList := SelectedObjects
  else
    vObjectList := Objects;
  if vObjectList.Count > 0 then
  begin
    Clipboard.Open;
    try
      Clipboard.Clear;
      {$IFDEF METAFILE_SUPPORT}
      if cfMetafile in ClipboardFormats then
      begin
        vMetafile := GetAsMetafile(0, vObjectList);
        try
          Clipboard.Assign(vMetafile);
        finally
          vMetafile.Free;
        end;
      end;
      {$ENDIF}
      if cfBitmap in ClipboardFormats then
      begin
        vBitmap := GetAsBitmap(vObjectList);
        vStream := TMemoryStream.Create;
        try
          vBitmap.HandleType := bmDDB;
          //vBitmap.SaveToStream(vStream);
          //vStream.Position := 0;
          Clipboard.Assign(vBitmap);//AddFormat(CF_Bitmap, vStream);
        finally
          vBitmap.Free;
          vStream.Free;
        end;
      end;
      if cfNative in ClipboardFormats then
      begin
        vStream := TMemoryStream.Create;
        try
          WriteObjects(vStream, vObjectList);
          vStream.Position := 0;
          Clipboard.AddFormat(CF_SIMPLEGRAPH, vStream);
        finally
          vStream.Free;
        end;
      end;
    finally
      Clipboard.Close;
    end;
  end;
end;

{$IFDEF METAFILE_SUPPORT}
procedure TEvsSimpleGraph.SaveAsMetafile(const aFilename: string);
var
  vMetafile: TMetafile;
begin
  vMetafile := GetAsMetafile(0, Objects);
  try
    vMetafile.SaveToFile(aFilename);
  finally
    vMetafile.Free;
  end;
end;
{$ENDIF}

procedure TEvsSimpleGraph.SetZoom(AValue: TZoom);
begin
  if AValue < Low(TZoom) then
    AValue := Low(TZoom)
  else if AValue > High(TZoom) then
    AValue := High(TZoom);
  if Zoom <> AValue then
  begin
    fZoom := AValue;
    FZoomFactor := FZoom/100;
    CalcAutoRange;
    Invalidate;
    DoZoomChange;
  end;
end;

procedure TEvsSimpleGraph.ObjectChanged(GraphObject: TEvsGraphObject;
  Flags: TEvsGraphChangeFlags);
begin
  if (csDestroying in ComponentState) then
    Exit;
  if UpdateCount = 0 then
  begin
    if gcPlacement in Flags then
    begin
      SaveBoundsChange := [Low(TEvsGraphBoundsKind)..High(TEvsGraphBoundsKind)];
      CalcAutoRange;
    end;
    if gcData in Flags then
    begin
      if not Assigned(DragSource) then
      begin
        Modified := True;
        DoGraphChange;
      end
      else
        fDragModified := True;
    end;
  end
  else
  begin
    if (gcData in Flags) and not (CommandMode in [cmInsertLink, cmInsertNode]) then
      SaveModified := 1;
    if gcPlacement in Flags then
      SaveRangeChange := True;
  end;
  if gcView in Flags then
    GraphObject.Invalidate;
end;

procedure TEvsSimpleGraph.ObjectListChanged(Sender: TObject;
  GraphObject: TEvsGraphObject; AAction: TEvsGraphObjectListAction);
begin
  case AAction of
    glAdded:
      if GraphObject.Owner = Self then
      begin
        DoObjectInsert(GraphObject);
        ObjectChanged(GraphObject, [gcView, gcData, gcPlacement]);
      end
      else
        TEvsGraphObjectList(Sender).Remove(GraphObject);
    glRemoved:
      if GraphObject.Owner = Self then
      begin
        if GraphObject = DragSource then
          GraphObject.EndDrag(False)
        else if osDragging in GraphObject.States then
          DraggingObjects.Remove(GraphObject);
        if GraphObject = ObjectAtCursor then
          RenewObjectAtCursor(nil);
        GraphObject.Selected := False;
        DoObjectRemove(GraphObject);
        ObjectChanged(GraphObject, [gcView, gcData, gcPlacement]);
        if not (osDestroying in GraphObject.States) then
          GraphObject.Free;
      end;
    glReordered:
      if GraphObject.Owner = Self then
        ObjectChanged(GraphObject, [gcView, gcData]);
  end;
end;

procedure TEvsSimpleGraph.SelectedListChanged(Sender: TObject;
  GraphObject: TEvsGraphObject; AAction: TEvsGraphObjectListAction);
begin
  case AAction of
    glAdded:
      if (GraphObject.Owner = Self) and GraphObject.Selected then
      begin
        Include(SaveBoundsChange, bkSelected);
        DoObjectSelect(GraphObject);
      end
      else
        TEvsGraphObjectList(Sender).Remove(GraphObject);
    glRemoved:
      if GraphObject.Owner = Self then
      begin
        GraphObject.Selected := False;
        Include(SaveBoundsChange, bkSelected);
        DoObjectSelect(GraphObject);
      end;
  end;
end;

function EvsFindClass(const AClassName: string): TPersistentClass;
begin
  if CompareText(AClassName, 'TGraphLink') = 0 then Result := GetClass('TEvsGraphLink')
  else if CompareText(AClassName, 'TRectangularNode')      = 0 then Result := GetClass('TEvsRectangularNode')
  else if CompareText(AClassName, 'TRhomboidalNode')       = 0 then Result := GetClass('TEvsRhomboidalNode')
  else if CompareText(AClassName, 'TPentagonalNode')       = 0 then Result := GetClass('TEvsPentagonalNode')
  else if CompareText(AClassName, 'THexagonalNode')        = 0 then Result := GetClass('TEvsHexagonalNode')
  else if CompareText(AClassName, 'TPolygonalNode')        = 0 then Result := GetClass('TEvsPolygonalNode')
  else if CompareText(AClassName, 'TRoundRectangularNode') = 0 then Result := GetClass('TEvsRoundRectangularNode')
  else if CompareText(AClassName, 'TEllipticNode')         = 0 then Result := GetClass('TEvsEllipticNode')
  else if CompareText(AClassName, 'TTriangularNode')       = 0 then Result := GetClass('TEvsTriangularNode')
  else Result := FindClass(AClassName);
end;

function TEvsSimpleGraph.ReadGraphObject(Stream: TStream): TEvsGraphObject;
var
  vClassName: array[0..255] of AnsiChar;
  ClassNameLen: integer;
  ClassNameStr: string;
  GraphObjectClass: TEvsGraphObjectClass;
begin
  Stream.Read(ClassNameLen, SizeOf(ClassNameLen));
  Stream.Read(vClassName, ClassNameLen);
  ClassNameStr := string(vClassName);
  GraphObjectClass := TEvsGraphObjectClass(EvsFindClass(ClassNameStr));
  Result := GraphObjectClass.CreateFromStream(Self, Stream);
end;

procedure TEvsSimpleGraph.WriteGraphObject(Stream: TStream;
  GraphObject: TEvsGraphObject);
var
  vClassName: array[0..255] of AnsiChar;
  ClassNameLen: integer;
begin
  ClassNameLen := Length(GraphObject.ClassName) + 1;
  Stream.Write(ClassNameLen, SizeOf(ClassNameLen));
  StrPCopy(vClassName, ansistring(GraphObject.ClassName));
  Stream.Write(vClassName, ClassNameLen);
  GraphObject.SaveToStream(Stream);
end;

class procedure TEvsSimpleGraph.WSRegisterClass;
begin
  inherited WSRegisterClass;
end;

function TEvsSimpleGraph.DrawTextBiDiModeFlags(aFlags: longint): LongInt;
begin
  Result := aFlags;
  { do not change center alignment }
  if SysLocale.MiddleEast and (BiDiMode = bdRightToLeft) then
    if Result and DT_RIGHT = DT_RIGHT then
      Result := Result and not DT_RIGHT
    else if not (Result and DT_CENTER = DT_CENTER) then
      Result := Result or DT_RIGHT;
  if SysLocale.MiddleEast and (BiDiMode <> bdLeftToRight) then
    Result := Result or DT_RTLREADING;
end;

procedure TEvsSimpleGraph.SuspendQueryEvents;
begin
  inc(FSuspendQueryEvents);
end;

Procedure TEvsSimpleGraph.ResumeQueryEvents;
begin
  Dec(FSuspendQueryEvents);
end;

//procedure TEvsSimpleGraph.AdjustDC(aDC: HDC; aOrg: PPoint);
//begin
//  if Assigned(aOrg) then
//    LCLIntf.SetViewPortOrgEx(aDC, -(aOrg^.X + HorzScrollBar.Position), -(aOrg^.Y + VertScrollBar.Position), nil)
//  else
//    LCLIntf.SetViewPortOrgEx(aDC, -HorzScrollBar.Position, -VertScrollBar.Position, nil);
//  LCLIntf.SetMapMode(aDC, MM_ANISOTROPIC);
//  LCLIntf.SetWindowExtEx(aDC, 100, 100, nil);
//  LCLIntf.SetViewPortExtEx(aDC, Zoom, Zoom, nil);
//end;

function TEvsSimpleGraph.CreateUniqueID(aGraphObject: TEvsGraphObject): DWORD;
var
  G: TEvsGraphObject;
  vUnique: boolean;
  vID: DWORD;
  I: integer;
begin
  if aGraphObject.ID <> 0 then
    vID := aGraphObject.ID
  else
    vID := Objects.Count + 1;
  repeat
    vUnique := True;
    for I := Objects.Count - 1 downto 0 do
    begin
      G := Objects[I];
      if (G <> aGraphObject) and (G.ID = vID) then
      begin
        Inc(vID);
        vUnique := False;
        Break;
      end;
    end;
  until vUnique;
  Result := vID;
end;

procedure TEvsSimpleGraph.CreateWnd;
begin
  inherited CreateWnd;
  UpdateScrollBars;
end;

procedure TEvsSimpleGraph.BackupObjects(aStream: TStream;
  aObjectList: TEvsGraphObjectList);
var
  vObjectCount : integer;
  I, vID       : integer;
begin
  vObjectCount := aObjectList.Count;
  aStream.Write(vObjectCount, SizeOf(vObjectCount));
  for I := 0 to aObjectList.Count - 1 do
  begin
    vID := aObjectList[I].ID;
    aStream.Write(vID, SizeOf(vID));
    aObjectList[I].SaveToStream(aStream);
  end;
end;

function TEvsSimpleGraph.BeginDragObject(aGraphObject: TEvsGraphObject;
  const aPt: TPoint; aHT: DWORD): boolean;
var
  I: integer;
begin
  Result := False;
  if Assigned(aGraphObject) then
  begin
    UndoStorage.Clear;
    fDragSource := aGraphObject;
    fDragHitTest := aHT;
    fDragSourcePt := aPt;
    fDragTargetPt := aPt;
    if not DragSource.Selected then
    begin
      SelectedObjects.Clear;
      DragSource.Selected := True;
    end;
    DraggingObjects.Clear;
    DraggingObjects.Capacity := SelectedObjects.Count;
    DraggingObjects.Add(DragSource);
    if not (CommandMode in [cmInsertLink, cmInsertNode]) then
    begin
      fDragModified := False;
      UndoStorage.Seek(0, soFromBeginning);
      BackupObjects(UndoStorage, DraggingObjects);
      for I := 0 to SelectedObjects.Count - 1 do
        with SelectedObjects[I] do
          if (DragSource.ID <> ID) and BeginFollowDrag(DragHitTest) then
            DraggingObjects.Add(SelectedObjects[I]);
      DoObjectBeginDrag(aGraphObject, aHT);
    end
    else
      fDragModified := True;
    Result := True;
  end;
end;

procedure TEvsSimpleGraph.DraggingListChanged(Sender: TObject;
  aGraphObject: TEvsGraphObject; aAction: TEvsGraphObjectListAction);
begin
  case aAction of
    glAdded:
      if aGraphObject.Owner = Self then
        Include(SaveBoundsChange, bkDragging)
      else
        TEvsGraphObjectList(Sender).Remove(aGraphObject);
    glRemoved:
      if aGraphObject.Owner = Self then
        Include(SaveBoundsChange, bkDragging);
  end;
end;

procedure TEvsSimpleGraph.DoCommandModeChange;
begin
  if not (csDestroying in ComponentState) and Assigned(fOnCommandModeChange) then
    fOnCommandModeChange(Self);
end;

procedure TEvsSimpleGraph.DoGraphChange;
begin
  if Assigned(fOnGraphChange) then
    fOnGraphChange(Self);
end;

procedure TEvsSimpleGraph.DoObjectAfterDraw(aCanvas: TCanvas;
  aGraphObject: TEvsGraphObject);
begin
  if Assigned(OnObjectAfterDraw) then
    OnObjectAfterDraw(Self, aGraphObject, aCanvas);
end;

procedure TEvsSimpleGraph.DoObjectBeforeDraw(aCanvas: TCanvas;
  aGraphObject: TEvsGraphObject);
begin
  if Assigned(OnObjectBeforeDraw) then
    OnObjectBeforeDraw(Self, aGraphObject, aCanvas);
end;

procedure TEvsSimpleGraph.DoObjectBeginDrag(aGraphObject: TEvsGraphObject; aHT: DWORD);
begin
  if Assigned(fOnObjectBeginDrag) then
    fOnObjectBeginDrag(Self, aGraphObject, aHT);
end;

procedure TEvsSimpleGraph.DoObjectInitInstance(aGraphObject: TEvsGraphObject);
begin
  if Assigned(fOnObjectInitInstance) then
    fOnObjectInitInstance(Self, aGraphObject);
end;

procedure TEvsSimpleGraph.DoObjectInsert(aGraphObject: TEvsGraphObject);
begin
  if Assigned(fOnObjectInsert) then
    fOnObjectInsert(Self, aGraphObject);
end;

procedure TEvsSimpleGraph.DoObjectMouseEnter(aGraphObject: TEvsGraphObject);
begin
  if Assigned(fOnObjectMouseEnter) then
    fOnObjectMouseEnter(Self, aGraphObject);
end;

procedure TEvsSimpleGraph.DoObjectMouseLeave(aGraphObject: TEvsGraphObject);
begin
  if Assigned(fOnObjectMouseLeave) then
    fOnObjectMouseLeave(Self, aGraphObject);
end;

procedure TEvsSimpleGraph.DoObjectRemove(aGraphObject: TEvsGraphObject);
begin
  if Assigned(fOnObjectRemove) then
    fOnObjectRemove(Self, aGraphObject);
end;

procedure TEvsSimpleGraph.DoObjectSelect(aGraphObject: TEvsGraphObject);
begin
  if Assigned(fOnObjectSelect) then
    fOnObjectSelect(Self, aGraphObject);
end;

procedure TEvsSimpleGraph.DoObjectChange(aGraphObject: TEvsGraphObject);
begin
  if Assigned(fOnObjectChange) then
    fOnObjectChange(Self, aGraphObject);
end;

procedure TEvsSimpleGraph.DoObjectContextPopup(aGraphObject: TEvsGraphObject;
  const aMousePos: TPoint; var aHandled: boolean);
begin
  if Assigned(fOnObjectContextPopup) then
    fOnObjectContextPopup(Self, aGraphObject, aMousePos, aHandled);
end;

{$IFDEF SUBCLASS}

{$IFDEF SUBCLASS_WMPRINT}
procedure TEvsSimpleGraph.WMPrint(var Msg: TWMPrint);
var
  Rect: TRect;
  SavedDC: integer;
begin
  if Visible or not longbool(Msg.Flags and PRF_CHECKVISIBLE) then
  begin
    if longbool(Msg.Flags and PRF_ERASEBKGND) then
    begin
      GetClipBox(Msg.DC, @Rect);
      FillRect(Msg.DC, Rect, Brush.Handle);
    end;
    if longbool(Msg.Flags and PRF_CLIENT) then
    begin
      SavedDC := SaveDC(Msg.DC);
      try
        //AdjustDC(Msg.DC);  //jkoz remove AdjustDC
        PaintWindow(Msg.DC);
      finally
        RestoreDC(Msg.DC, SavedDC);
      end;
    end;
    if (ControlCount > 0) and longbool(Msg.Flags and PRF_CHILDREN) then
    begin
      SavedDC := SaveDC(Msg.DC);
      try
        PaintControls(Msg.DC, nil);
      finally
        RestoreDC(Msg.DC, SavedDC);
      end;
    end;
  end;
end;
{$ENDIF}

procedure TEvsSimpleGraph.WMSize(var Msg: TLMSize);
begin
  {.$MESSAGE HINT 'Seek a method to override instead.'}
  UpdatingScrollBars := True;
  try
    CalcAutoRange;
  finally
    UpdatingScrollBars := False;
  end;
  if HorzScrollBar.Visible or VertScrollBar.Visible then
    UpdateScrollBars;
  inherited;
end;

procedure TEvsSimpleGraph.WMHScroll(var Msg: TLMHScroll);
begin
  if {$IFDEF LCLWIN32} (Msg.ScrollBar = 0) and {$ENDIF} HorzScrollBar.Visible then
  begin
    HorzScrollBar.ScrollMessage(Msg);
    Invalidate;
  end
  else
    inherited;
end;

procedure TEvsSimpleGraph.WMVScroll(var Msg: TLMVScroll);
begin
  if {$IFDEF LCLWIN32} (Msg.ScrollBar = 0) and  {$ENDIF} VertScrollBar.Visible then
  begin
    VertScrollBar.ScrollMessage(Msg);
    Invalidate;
  end
  else
    inherited;
end;

procedure TEvsSimpleGraph.CNKeyDown(var Msg: TLMKeyDown);
begin
  Mouse.CursorPos := Mouse.CursorPos; // To force cursor update
  if not (DefaultKeyMap and DefaultKeyHandler(Msg.CharCode, KeyDataToShiftState(Msg.KeyData))) then
    inherited;
end;

procedure TEvsSimpleGraph.CNKeyUp(var Msg: TLMKeyUp);
begin
  inherited;
  Mouse.CursorPos := Mouse.CursorPos; // To force cursor update
end;

procedure TEvsSimpleGraph.CMFontChanged(var Msg: TLMessage);
var
  I: integer;
begin
  inherited;
  BeginUpdate;
  try
    for I := 0 to Objects.Count - 1 do
      with Objects[I] do
        ParentFontChanged;
  finally
    EndUpdate;
  end;
end;

procedure TEvsSimpleGraph.CMBiDiModeChanged(var Msg: TLMessage);
var
  Save: integer;
begin
  Save := Msg.WParam;
  try
    { prevent inherited from calling Invalidate & RecreateWnd }
    if not (Self is TEvsSimpleGraph) then
      Msg.wParam := 1;
    inherited;
  finally
    Msg.wParam := Save;
  end;
  if HandleAllocated then
  begin
    HorzScrollBar.ChangeBiDiPosition;
    UpdateScrollBars;
  end;
end;

procedure TEvsSimpleGraph.CMMouseLeave(var Msg: TLMessage);
begin
  inherited;
  if (GetCapture <> WindowHandle) then
  begin
    RenewObjectAtCursor(nil);
    Screen.Cursor := crDefault;
  end;
end;

procedure TEvsSimpleGraph.CMHintShow(var Msg: TCMHintShow);
var
  HintObject: TEvsGraphObject;
begin
  inherited;
  with Msg.HintInfo^ do
  begin
    with ClientToGraph(CursorPos.X, CursorPos.Y) do
      HintObject := FindObjectAt(X, Y);
    if Assigned(HintObject) then
    begin
      if Assigned(OnInfoTip) or (HintObject.Hint <> '') or
        (HintObject.Text <> HintObject.TextToShow) then
      begin
        CursorRect := HintObject.VisualRect;
        GPToCP(CursorRect, 2); {$MESSAGE WARN 'GPToCP'}
        Application.Hint := HintObject.Hint;
        HintStr := GetShortHint(HintObject.Hint);
        if (HintStr = '') and (HintObject.Text <> HintObject.TextToShow) then
          HintStr := HintObject.Text;
        if Assigned(OnInfoTip) then
          OnInfoTip(Self, HintObject, HintStr);
      end;
    end;
  end;
end;

{$ENDIF}

procedure TEvsSimpleGraph.DrawGrid(ACanvas: TCanvas);

  function FirstGridPos(aPos: integer): integer;
  var
    M: integer;
  begin
    M := aPos mod fGridSize;
    if M < 0 then
      Result := fGridSize + M
    else if M > 0 then
      Result := aPos + fGridSize - M
    else if aPos < 0 then
      Result := 0
    else
      Result := aPos;
  end;

var
  //vDC: HDC;
  vRect: TRect;
  vSX, vSY: integer;
  vX, vY: integer;
  //vDotColor: integer;
begin
  vRect := aCanvas.ClipRect;
  IntersectRect(vRect, GraphConstraints.BoundsRect);
  vSX := FirstGridPos(vRect.Left);
  vSY := FirstGridPos(vRect.Top);
  //vDotColor := ColorToRGB(GridColor);
  aCanvas.Pen.Mode := pmCopy;
  //vDC := aCanvas.Handle;
  vY := vSY;
  while vY < vRect.Bottom do
  begin
    vX := vSX;
    while vX < vRect.Right do
    begin
      ACanvas.Pixels[vX,vY]:= GridColor;
      //WidgetSet.DCSetPixel(vDC, vX, vY, vDotColor);
      Inc(vX, GridSize);
    end;
    Inc(vY, GridSize);
  end;
end;

procedure TEvsSimpleGraph.DrawObjects(aCanvas: TCanvas;
  AObjectList: TEvsGraphObjectList);
var
  I: integer;
begin
  DoBeforeDraw(aCanvas);
  CanvasRecall.Reference := aCanvas;
  if aCanvas is TEvsGraphCanvas then begin
    TEvsGraphCanvas(aCanvas).OffsetX := -fHorzScrollBar.Position;
    TEvsGraphCanvas(aCanvas).OffsetY := -fVertScrollBar.Position;
  end;
  try
    case DrawOrder of
      doNodesOnTop:
      begin
        for I := 0 to AObjectList.Count - 1 do
          with AObjectList[I] do
            if IsLink then
              Draw(aCanvas);
        for I := 0 to AObjectList.Count - 1 do
          with AObjectList[I] do
            if IsNode then
              Draw(aCanvas);
      end;
      doLinksOnTop:
      begin
        for I := 0 to AObjectList.Count - 1 do
          with AObjectList[I] do
            if IsNode then
              Draw(aCanvas);
        for I := 0 to AObjectList.Count - 1 do
          with AObjectList[I] do
            if IsLink then
              Draw(aCanvas);
      end;
      else
        for I := 0 to AObjectList.Count - 1 do
          AObjectList[I].Draw(aCanvas);
    end;
  finally
    CanvasRecall.Reference := nil;
  end;
  DoAfterDraw(aCanvas);
end;

procedure TEvsSimpleGraph.EndDragObject(Accept: boolean);
var
  I: integer;
  Source: TEvsGraphObject;
begin
  if Assigned(DragSource) then
  begin
    Source := DragSource;
    fDragSource := nil;
    for I := 1 to DraggingObjects.Count - 1 do
      DraggingObjects[I].EndFollowDrag;
    DraggingObjects.Clear;
    if not Accept then
    begin
      fDragModified := False;
      if not (CommandMode in [cmInsertLink, cmInsertNode]) then
      begin
        UndoStorage.Seek(0, soFromBeginning);
        RestoreObjects(UndoStorage);
      end
      else
        Source.Free;
    end;
    UndoStorage.Clear;
    if not (CommandMode in [cmInsertLink, cmInsertNode]) then
      DoObjectEndDrag(Source, DragHitTest, not Accept)
    else
      CommandMode := cmEdit;
    if DragModified then
    begin
      Modified := True;
      DoGraphChange;
    end;
  end;
end;

procedure TEvsSimpleGraph.DrawEditStates(aCanvas :TCanvas);
var
  I: integer;
  vR : TRect;
begin
  if not HideSelection or Focused then
    for I := 0 to SelectedObjects.Count - 1 do
      with SelectedObjects[I] do
        DrawState(aCanvas);
  if ValidMarkedArea and not IsRectEmpty(MarkedArea) then
  begin
    aCanvas.Brush.Style := bsClear;
    aCanvas.Pen.Mode := pmNot;
    aCanvas.Pen.Style := psDot;
    aCanvas.Pen.Width := 0;
    vR := MarkedArea;
    ACanvas.Rectangle(vR)
  end;
end;


procedure TEvsSimpleGraph.Paint;

procedure InitCanvas(aCnv:TCanvas);
begin
  if aCnv is TEvsGraphCanvas then begin
    TEvsGraphCanvas(aCnv).OffsetX := -fHorzScrollBar.Position;
    TEvsGraphCanvas(aCnv).OffsetY := -fVertScrollBar.Position;
  end;
  if Assigned(FCanvasInit) then FCanvasInit(aCnv);
end;

procedure RestoreCanvas(aCnv:TCanvas);
begin
  if aCnv is TEvsGraphCanvas then begin
    TEvsGraphCanvas(aCnv).OffsetX := 0;
    TEvsGraphCanvas(aCnv).OffsetY := 0;
  end;
end;

Function GetCanvas:TCanvas;
begin
  if Assigned(FCustomCanvas) then begin
    if FCustomCanvas.InheritsFrom(TEvsGraphCanvas) then begin
      Result := TEvsGraphCanvasClass(FCustomCanvas).Create(Canvas)
    end else begin
      Result := FCustomCanvas.Create;
      Result.Handle := Canvas.Handle;
    end;
    Result.AntialiasingMode := Canvas.AntialiasingMode;
  end else Result := Canvas;
end;

var
  vTmp : TCanvas;
  vdbg : string;

procedure LockCanvas(aCanvas:TCanvas);
begin
  aCanvas.lock;
  IF aCanvas<>Canvas then Canvas.Lock;
end;

procedure UnlockCanvas(aCanvas:TCanvas);
begin
  aCanvas.Unlock;
  IF aCanvas<>Canvas then Canvas.Unlock;
end;

begin
  vTmp := GetCanvas;
  LockCanvas(vTmp);
  try
    vdbg := vTmp.ClassName;
    if ShowGrid then DrawGrid(vTmp);
    InitCanvas(vTmp);
    DrawObjects(vTmp, Objects);
    DrawEditStates(vTmp);
    RestoreCanvas(vTmp);
    if csDesigning in ComponentState then begin
      vTmp.Brush.Style := bsClear;
      vTmp.Pen.Style   := psDash;
      vTmp.Pen.Mode    := pmCopy;
      vTmp.Pen.Color   := clBlack;
      vTmp.Pen.Width   := 0;
      vTmp.Rectangle(ClientRect);
    end;
  finally
    UnlockCanvas(vTmp);
    if vTmp <> Canvas then vTmp.Free;
  end;
end;

procedure TEvsSimpleGraph.DrawBackGround(const aCanvas:TCanvas; const ClipRect:TRect);
var
  vPS  : TPenStyle;
  vBrs : TColor;
begin
  vPS := aCanvas.Pen.Style;
  vBrs := aCanvas.Brush.Color;
  aCanvas.Pen.Style := psClear;
  aCanvas.Brush.Color:= Self.Color;
  try
    if IsRectEmpty(ClipRect) then
      aCanvas.Rectangle(ClientRect)
    else
      aCanvas.Rectangle(ClipRect);
  finally
    aCanvas.Pen.Style:=vPS;
    aCanvas.Brush.Color:=vBrs;
  end;
end;

procedure TEvsSimpleGraph.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: integer);
var
  Pt: TPoint;
  NewObject: TEvsGraphObject;
begin
  if not Focused then
    SetFocus;
  inherited MouseDown(Button, Shift, X, Y);
  Pt := ClientToGraph(X, Y);
  CheckObjectAtCursor(Pt);
  case CommandMode of
    cmInsertNode, cmInsertLink:
      if Assigned(DragSource) then
        DragSource.MouseDown(Button, Shift, Pt)
      else if (Button = mbLeft) and not (ssDouble in Shift) then
      begin
        NewObject := nil;
        case CommandMode of
          cmInsertNode:
            NewObject := InsertObjectByMouse(Pt, DefaultNodeClass,
              SnapToGrid xor (ssCtrl in Shift));
          cmInsertLink:
            NewObject := InsertObjectByMouse(Pt, DefaultLinkClass,
              SnapToGrid xor (ssCtrl in Shift));
        end;
        if Assigned(NewObject) then
        begin
          NewObject.Selected := True;
          NewObject.MouseDown(Button, Shift, Pt);
          if DragSource <> NewObject then
          begin
            CommandMode := cmEdit;
            ObjectChanged(NewObject, [gcData]);
          end
          else
            CursorPos := Pt;
          RenewObjectAtCursor(NewObject);
        end;
      end;
    cmPan:
      if (Button = mbLeft) and not (ssDouble in SHift) then
      begin
        fDragSourcePt.X := X;
        fDragSourcePt.Y := Y;
        Screen.Cursor := crHandGrab;
      end;
    else
      if Assigned(ObjectAtCursor) and (CommandMode <> cmViewOnly) and
        (goSelectable in ObjectAtCursor.Options) then
        ObjectAtCursor.MouseDown(Button, Shift, Pt)
      else if (Button = mbLeft) and not (ssDouble in Shift) then
      begin
        fDragSourcePt := Pt;
        fDragTargetPt := Pt;
        MarkedArea := MakeRect(fDragSourcePt, fDragTargetPt);
        Screen.Cursor := crCross;
      end;
  end;
end;

procedure TEvsSimpleGraph.MouseMove(Shift: TShiftState; X, Y: integer);
var
  Pt: TPoint;
  NewPos: integer;
begin
  Pt := ClientToGraph(X, Y);
  CheckObjectAtCursor(Pt);
  if CommandMode = cmPan then
  begin
    if ssLeft in Shift then
    begin
      with HorzScrollBar do
        if IsScrollBarVisible then
        begin
          NewPos := Position + (fDragSourcePt.X - X);
          if NewPos < 0 then
            NewPos := 0
          else if NewPos > Range then
            NewPos := Range;
          Position := NewPos;
          fDragSourcePt.X := X;
        end;
      with VertScrollBar do
        if IsScrollBarVisible then
        begin
          NewPos := Position + (fDragSourcePt.Y - Y);
          if NewPos < 0 then
            NewPos := 0
          else if NewPos > Range then
            NewPos := Range;
          Position := NewPos;
          fDragSourcePt.Y := Y;
        end;
    end
    else
      Screen.Cursor := crHandFlat;
  end
  else if ValidMarkedArea then
  begin
    fDragTargetPt := Pt;
    MarkedArea := MakeRect(fDragSourcePt, fDragTargetPt);
    ScrollInView(fDragTargetPt);
  end
  else
  begin
    if Assigned(ObjectAtCursor) and (CommandMode <> cmViewOnly) then
      ObjectAtCursor.MouseMove(Shift, Pt)
    else if CommandMode in [cmInsertNode, cmInsertLink] then
      Screen.Cursor := crXHair1
    else
      Screen.Cursor := Cursor;
  end;
  inherited MouseMove(Shift, X, Y);
end;

procedure TEvsSimpleGraph.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: integer);
var
  Pt: TPoint;
begin
  Pt := ClientToGraph(X, Y);
  CheckObjectAtCursor(Pt);
  if CommandMode = cmPan then
  begin
    if Button = mbLeft then
      Screen.Cursor := crHandFlat;
  end
  else if ValidMarkedArea then
  begin
    if not (ssAlt in Shift) then
    begin
      if CommandMode = cmEdit then
      begin
        if ssCtrl in Shift then
          ToggleSelection(MarkedArea, ssShift in Shift, TEvsGraphNode)
        else
          ToggleSelection(MarkedArea, ssShift in Shift, TEvsGraphObject);
      end;
    end
    else if not IsRectEmpty(MarkedArea) then
      ZoomRect(MarkedArea);
    MarkedArea := Types.Rect(maxLongint, maxLongint, -maxLongint, -maxLongint);
    Screen.Cursor := Cursor;
  end
  else
  begin
    if Assigned(ObjectAtCursor) and (CommandMode <> cmViewOnly) then
      ObjectAtCursor.MouseUp(Button, Shift, Pt)
    else
      Screen.Cursor := Cursor;
  end;
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TEvsSimpleGraph.DoContextPopup(MousePos: TPoint; var Handled: boolean);
begin
  if not Assigned(DragSource) then
  begin
    if SelectedObjects.Count > 0 then
    begin
      DoObjectContextPopup(SelectedObjects[0], MousePos, Handled);
      if not Handled and Assigned(ObjectPopupMenu) then
      begin
        with ClientToScreen(MousePos) do
          ObjectPopupMenu.Popup(X, Y);
        Handled := True;
      end;
    end;
    if not Handled then
      inherited DoContextPopup(MousePos, Handled);
  end
  else
    Handled := True;
end;

procedure TEvsSimpleGraph.Click;
begin
  if SelectedObjects.Count > 0 then
    DoObjectClick(SelectedObjects[0])
  else
    inherited Click;
end;

procedure TEvsSimpleGraph.DblClick;
begin
  if not Assigned(DragSource) then
    if SelectedObjects.Count > 0 then
      DoObjectDblClick(SelectedObjects[0])
    else
      inherited DblClick;
end;

procedure TEvsSimpleGraph.DoEnter;
begin
  inherited DoEnter;
  if HideSelection and (SelectedObjects.Count > 0) then
    InvalidateRect(SelectionBounds);
end;

procedure TEvsSimpleGraph.DoExit;
begin
  inherited DoExit;
  if HideSelection and (SelectedObjects.Count > 0) then
    InvalidateRect(SelectionBounds);
end;

procedure TEvsSimpleGraph.RenewObjectAtCursor(aNewObjectAtCursor: TEvsGraphObject);
begin
  if aNewObjectAtCursor <> ObjectAtCursor then
  begin
    if Assigned(ObjectAtCursor) then
      DoObjectMouseLeave(ObjectAtCursor);
    fObjectAtCursor := aNewObjectAtCursor;
    if Assigned(ObjectAtCursor) then
      DoObjectMouseEnter(ObjectAtCursor);
    if not Assigned(DragSource) then
      Application.CancelHint;
  end;
end;

procedure TEvsSimpleGraph.RestoreObjects(aStream: TStream);
var
  GraphObject: TEvsGraphObject;
  ObjectCount: integer;
  I, ID: integer;
begin
  BeginUpdate;
  Inc(FSuspendQueryEvents);
  try
    ObjectCount := Objects.Count;
    aStream.Read(ObjectCount, SizeOf(ObjectCount));
    for I := 0 to ObjectCount - 1 do
    begin
      aStream.Read(ID, SizeOf(ID));
      GraphObject := FindObjectByID(ID);
      GraphObject.LoadFromStream(aStream);
    end;
  finally
    Inc(FSuspendQueryEvents);
    EndUpdate;
  end;
end;

procedure TEvsSimpleGraph.DoNodeMoveResize(aNode: TEvsGraphNode);
begin
  if Assigned(fOnNodeMoveResize) then
    fOnNodeMoveResize(Self, aNode);
end;

procedure TEvsSimpleGraph.ReadObjects(aStream: TStream);
var
  vOldObjectCount      : integer;
  vObjectCount         : integer;
  I, J, vOldID, vNewID : integer;
begin
  BeginUpdate;
  SuspendQueryEvents;
  try
    vOldObjectCount := Objects.Count;
    aStream.Read(vObjectCount, SizeOf(vObjectCount));
    if vObjectCount > 0 then
    begin
      Objects.Capacity := vOldObjectCount + vObjectCount;
      for I := 0 to vObjectCount - 1 do
        ReadGraphObject(aStream);
      for I := vOldObjectCount to Objects.Count - 1 do
      begin
        vOldID := Objects[I].ID;
        vNewID := CreateUniqueID(Objects[I]);
        if vOldID <> vNewID then
          for J := vOldObjectCount to Objects.Count - 1 do
            Objects[J].ReplaceID(vOldID, vNewID);
      end;
      for I := vOldObjectCount to Objects.Count - 1 do
        Objects[I].Loaded;
    end;
  finally
    ResumeQueryEvents;
    EndUpdate;
  end;
end;

procedure TEvsSimpleGraph.WriteObjects(aStream: TStream;
  aObjectList: TEvsGraphObjectList);
var
  vObjectCount: integer;
  I: integer;
begin
  vObjectCount := aObjectList.Count;
  aStream.Write(vObjectCount, SizeOf(vObjectCount));
  for I := 0 to aObjectList.Count - 1 do
    WriteGraphObject(aStream, aObjectList[I]);
end;

procedure TEvsSimpleGraph.DoCanRemoveObject(aGraphObject: TEvsGraphObject;
  var aCanRemove: boolean);
begin
  if (FSuspendQueryEvents = 0) and Assigned(fOnCanRemoveObject) then
    fOnCanRemoveObject(Self, aGraphObject, aCanRemove);
end;

procedure TEvsSimpleGraph.DoCanMoveResizeNode(aNode: TEvsGraphNode; var aLeft,
  aTop, aWidth, aHeight: integer; var aCanMove, aCanResize: boolean);
begin
  if (FSuspendQueryEvents = 0) and Assigned(fOnCanMoveResizeNode) then
    fOnCanMoveResizeNode(Self, aNode, aLeft, aTop, aWidth, aHeight, aCanMove, aCanResize);
end;

procedure TEvsSimpleGraph.DoCanLinkObjects(aLink: TEvsGraphLink; aSource,
  aTarget: TEvsGraphObject; var aCanLink: boolean);
begin
  if (FSuspendQueryEvents = 0) and Assigned(fOnCanLinkObjects) then
    fOnCanLinkObjects(Self, aLink, aSource, aTarget, aCanLink);
end;

procedure TEvsSimpleGraph.DoCanHookLink(aGraphObject: TEvsGraphObject;
  aLink: TEvsGraphLink; aIndex: integer; var aCanHook: boolean);
begin
  if (FSuspendQueryEvents = 0) and Assigned(fOnCanHookLink) then
    fOnCanHookLink(Self, aGraphObject, aLink, aIndex, aCanHook);
end;

procedure TEvsSimpleGraph.DoObjectHook(aGraphObject: TEvsGraphObject;
  aLink: TEvsGraphLink; aIndex: integer);
begin
  if Assigned(fOnObjectHook) then
    fOnObjectHook(Self, aGraphObject, aLink, aIndex);
end;

procedure TEvsSimpleGraph.DoObjectUnhook(aGraphObject: TEvsGraphObject;
  aLink: TEvsGraphLink; aIndex: integer);
begin
  if Assigned(fOnObjectUnhook) then
    fOnObjectUnhook(Self, aGraphObject, aLink, aIndex);
end;

procedure TEvsSimpleGraph.DoObjectRead(aGraphObject: TEvsGraphObject;
  aStream: TStream);
begin
  if Assigned(fOnObjectRead) then
    fOnObjectRead(Self, aGraphObject, aStream);
end;

procedure TEvsSimpleGraph.DoObjectWrite(aGraphObject: TEvsGraphObject;
  aStream: TStream);
begin
  if Assigned(fOnObjectWrite) then
    fOnObjectWrite(Self, aGraphObject, aStream);
end;

procedure TEvsSimpleGraph.DoObjectEndDrag(aGraphObject: TEvsGraphObject; aHT: DWORD;
  aCancelled: boolean);
begin
  if Assigned(fOnObjectEndDrag) then
    fOnObjectEndDrag(Self, aGraphObject, aHT, aCancelled);
end;

procedure TEvsSimpleGraph.DoZoomChange;
begin
  if Assigned(fOnZoomChange) then
    fOnZoomChange(Self);
end;

procedure TEvsSimpleGraph.DoBeforeDraw(aCanvas :TCanvas);
begin
  if Assigned(OnBeforeDraw) then
    OnBeforeDraw(Self, Canvas);
end;

procedure TEvsSimpleGraph.DoAfterDraw(aCanvas :TCanvas);
begin
  if Assigned(OnAfterDraw) then
    OnAfterDraw(Self, Canvas);
end;

procedure TEvsSimpleGraph.DoObjectClick(aGraphObject: TEvsGraphObject);
begin
  if Assigned(fOnObjectClick) then
    fOnObjectClick(Self, aGraphObject);
end;

procedure TEvsSimpleGraph.DoObjectDblClick(aGraphObject: TEvsGraphObject);
begin
  if Assigned(fOnObjectDblClick) then
    fOnObjectDblClick(Self, aGraphObject);
end;

{$IFDEF METAFILE_SUPPORT}
function TEvsSimpleGraph.GetAsMetafile(RefDC: HDC; ObjectList: TGraphObjectList): TMetafile;
var
  Rect: TRect;
  MetaCanvas: TMetafileCanvas;
begin
  Rect := GetObjectsBounds(ObjectList);
  Result := TMetafile.Create;
  Result.Width := (Rect.Right - Rect.Left) + 1;
  Result.Height := (Rect.Bottom - Rect.Top) + 1;
  MetaCanvas := TMetafileCanvas.Create(Result, RefDC);
  try
    SetViewportOrgEx(MetaCanvas.Handle, -Rect.Left, -Rect.Top, nil);
    DrawObjects(MetaCanvas, ObjectList);
  finally
    MetaCanvas.Free;
  end;
end;
{$ENDIF}

procedure TEvsSimpleGraph.CalcAutoRange;
begin
  HorzScrollBar.CalcAutoRange;
  VertScrollBar.CalcAutoRange;
  if ControlCount > 0 then Realign;
end;

function TEvsSimpleGraph.GetObjectsBounds(aObjectList: TEvsGraphObjectList): TRect;
var
  vCntr: Integer;
  vAnyFound: Boolean;
  vGraphObject: TEvsGraphObject;
begin
  vAnyFound := False;
  FillChar(Result, SizeOf(TRect), 0);
  for vCntr := aObjectList.Count - 1 downto 0 do
  begin
    vGraphObject := aObjectList[vCntr];
    if vGraphObject.Showing then
    begin
      if vAnyFound then
        UnionRect(Result, vGraphObject.VisualRect)
      else
      begin
        vAnyFound := True;
        Result := vGraphObject.VisualRect;
      end
    end;
  end;
end;

procedure TEvsSimpleGraph.GPToCP(var aPoints; aCount: Integer);
Type PPPoint = ^PPOINT;
var
//{$IFDEF LCLWIN32}
//  vMemDC: HDC;
//{$ELSE}
  vTmp  : PPoint;
  vCntr : Integer;
//{$ENDIF}
begin
  //{$IFDEF LCLWIN32}
  //vMemDC := CreateCompatibleDC(0);
  //try
  //  AdjustDC(vMemDC);
  //  LPtoDP(vMemDC, aPoints, aCount);
  //finally
  //  DeleteDC(vMemDC);
  //end;
  //{$ELSE}
  vTmp := @aPoints;
  for vCntr := 0 to aCount -1 do begin
    vTmp[vCntr].x := vTmp[vCntr].x - fHorzScrollBar.Position;
    vTmp[vCntr].y := vTmp[vCntr].y - fVertScrollBar.Position;
  end;
  //{$ENDIF}
end;

procedure TEvsSimpleGraph.CPToGP(var aPoints; aCount: Integer);
var
//{$IFDEF LCLWIN32}
//  vMemDC: HDC;
//{$ELSE}
  vTmp : PPoint;
  vCntr : Integer;
//{$ENDIF}
begin
  //{$IFDEF LCLWIN32}
  //vMemDC := CreateCompatibleDC(0);
  //try
  //  AdjustDC(vMemDC);   //JKOZ Remove AdjustDC
  //  DPtoLP(vMemDC, aPoints, aCount);
  //finally
  //  DeleteDC(vMemDC);
  //end;
  //{$ELSE}
  vTmp := @aPoints;
  for vCntr := 0 to aCount -1 do begin
    vTmp[vCntr].x := vTmp[vCntr].x + fHorzScrollBar.Position;
    vTmp[vCntr].y := vTmp[vCntr].y + fVertScrollBar.Position;
  end;
  //{$ENDIF}
end;

function TEvsSimpleGraph.GetAsBitmap(aObjectList: TEvsGraphObjectList): Graphics.TBitmap;
var
  vRect: TRect;
begin
  vRect := GetObjectsBounds(aObjectList);
  GPToCP(vRect,2);
  Result := Graphics.TBitmap.Create;
  Result.PixelFormat := pf24bit;
  Result.Canvas.Brush.Color := clWhite;
  Result.Canvas.Brush.Style := bsSolid;
  Result.SetSize((vRect.Right - vRect.Left) + 1,(vRect.Bottom - vRect.Top) + 1);
  Result.Canvas.FillRect(0, 0, Result.Width, Result.Height);
  SetViewportOrgEx(Result.Canvas.Handle, -vRect.Left, -vRect.Top, nil);
  DrawObjects(Result.Canvas, aObjectList);
  SetViewportOrgEx(Result.Canvas.Handle, 0, 0, nil);
end;

procedure TEvsSimpleGraph.PerformDragBy(adX, adY: integer);
var
  I: integer;
  vMobility: TEvsObjectSides;
  vTest : TPoint;
begin
  if Assigned(DragSource) and ((adX <> 0) or (adY <> 0)) then
  begin
    vMobility := [];
    for I := 0 to DraggingObjects.Count - 1 do
      vMobility := vMobility + DraggingObjects[I].QueryMobility(DragHitTest);
    GraphConstraints.SourceRect := DraggingBounds; //TODO: Fix needed for moving points
    if not GraphConstraints.ConfineOffset(adX, adY, vMobility) then
      Exit;
    BeginUpdate;
    try
      for I := 0 to DraggingObjects.Count - 1 do
        DraggingObjects[I].OffsetHitTest(DragHitTest, adX, adY);
    finally
      EndUpdate;
    end;
    Inc(fDragTargetPt.X, adX);
    Inc(fDragTargetPt.Y, adY);
    vTest := fDragTargetPt;
    ScrollInView(vTest);
  end;
end;

procedure TEvsSimpleGraph.PerformInvalidate(aRect: PRect);
var
  vR : TRect;
begin
  if WindowHandle <> 0 then
  begin
    if ControlCount = 0 then
      WidgetSet.InvalidateRect(WindowHandle, aRect, False)
    else
      RedrawWindow(WindowHandle, aRect, 0, RDW_INVALIDATE or RDW_ALLCHILDREN);
  end;
end;

procedure TEvsSimpleGraph.CheckObjectAtCursor(const aPt: TPoint);
begin
  if Assigned(DragSource) then
    RenewObjectAtCursor(DragSource)
  else
    RenewObjectAtCursor(FindObjectAt(aPt.X, aPt.Y));
end;

function TEvsSimpleGraph.InsertObjectByMouse(var aPt: TPoint;
  aGraphObjectClass: TEvsGraphObjectClass; aGridSnap: boolean): TEvsGraphObject;
var
  vObjectAtPt: TEvsGraphObject;
  vRect: TRect;
begin
  Result := nil;
  if aGraphObjectClass.IsLink then
  begin
    vObjectAtPt := FindObjectAt(aPt.X, aPt.Y);
    if Assigned(vObjectAtPt) then
      Result := InsertLink(vObjectAtPt, [aPt], TEvsGraphLinkClass(aGraphObjectClass));
    if not Assigned(Result) then
    begin
      if aGridSnap then
        aPt := SnapPoint(aPt);
      if GraphConstraints.WithinBounds([aPt]) then
        Result := InsertLink([aPt, aPt], TEvsGraphLinkClass(aGraphObjectClass));
    end;
    if Assigned(Result) then
      aPt := TEvsGraphLink(Result).Points[TEvsGraphLink(Result).PointCount - 1];
  end
  else if aGraphObjectClass.IsNode then
  begin
    if aGridSnap then
      aPt := SnapPoint(aPt);
    if GraphConstraints.WithinBounds([aPt]) then
    begin
      vRect.TopLeft := aPt;
      if SnapToGrid and (MinNodeSize <= GridSize) then
      begin
        vRect.Right := aPt.X + GridSize;
        vRect.Bottom := aPt.Y + GridSize;
      end
      else
      begin
        vRect.Right := aPt.X + MinNodeSize;
        vRect.Bottom := aPt.Y + MinNodeSize;
        if SnapToGrid and ((MinNodeSize mod GridSize) <> 0) then
        begin
          Inc(vRect.Right, GridSize - (MinNodeSize mod GridSize));
          Inc(vRect.Bottom, GridSize - (MinNodeSize mod GridSize));
        end;
      end;
      GraphConstraints.ConfinePt(vRect.BottomRight);
      Result := InsertNode(vRect, TEvsGraphNodeClass(aGraphObjectClass));
      if Assigned(Result) then
        aPt := Result.BoundsRect.BottomRight;
    end;
  end;
end;

function TEvsSimpleGraph.DefaultKeyHandler(var Key: word; Shift: TShiftState): boolean;
const
  VK_PAGEUP = 33;
  VK_PAGEDOWN = 34;
var
  GraphObject: TEvsGraphObject;
  NewPos: integer;
begin
  Result := False;
  if Assigned(DragSource) then
  begin
    GraphConstraints.SourceRect := DraggingBounds;
    Result := DragSource.KeyPress(Key, Shift);
  end
  else if not (CommandMode in [cmViewOnly, cmPan]) then
  begin
    GraphConstraints.SourceRect := SelectionBounds;
    BeginUpdate;
    try
      GraphObject := SelectedObjects.First;
      while Assigned(GraphObject) do
      begin
        SelectedObjects.Push;
        try
          if GraphObject.KeyPress(Key, Shift) then
            Result := True;
        finally
          SelectedObjects.Pop;
        end;
        GraphObject := SelectedObjects.Next;
      end;
    finally
      EndUpdate;
    end;
  end;
  if not Result then
    case Key of
      VK_TAB:
        if not (CommandMode in [cmViewOnly, cmPan]) then
        begin
          SelectNextObject(ssShift in Shift);
          Result := True;
        end;
      VK_LEFT, VK_RIGHT:
      begin
        with HorzScrollBar do
          if {(CommandMode = cmPan) and }IsScrollBarVisible then
          begin
            if Key = VK_LEFT then
              NewPos := Position - Increment
            else
              NewPos := Position + Increment;
            if NewPos < 0 then
              Position := 0
            else if NewPos > Range then
              Position := Range
            else
              Position := NewPos;
          end;
        Result := (CommandMode = cmPan);
      end;
      VK_UP, VK_DOWN:
      begin
        with VertScrollBar do
          if {(CommandMode = cmPan) and }IsScrollBarVisible then
          begin
            if Key = VK_UP then
              NewPos := Position - Increment
            else
              NewPos := Position + Increment;
            if NewPos < 0 then
              Position := 0
            else if NewPos > Range then
              Position := Range
            else
              Position := NewPos;
          end;
        Result := (CommandMode = cmPan);
      end;
      VK_HOME:
        if VertScrollBar.IsScrollBarVisible then begin
          VertScrollBar.Position := 0;
          Result := True;
        end;
      VK_END :
          if VertScrollBar.IsScrollBarVisible then begin
            VertScrollBar.Position := VertScrollBar.Range;
            Result := True;
          end;
      VK_PAGEUP :
          if VertScrollBar.IsScrollBarVisible then begin
            VertScrollBar.Position := VertScrollBar.Position - VertScrollBar.fPageIncrement;
            Result := True;
          end;
      VK_PAGEDOWN :
          if VertScrollBar.IsScrollBarVisible then begin
            VertScrollBar.Position := VertScrollBar.Position + VertScrollBar.fPageIncrement;
            Result := True;
          end;
    end;
end;

procedure TEvsSimpleGraph.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params.WindowClass do
    style := style and not (CS_HREDRAW or CS_VREDRAW);
end;

class procedure TEvsSimpleGraph.Register(aNodeClass: TEvsGraphNodeClass);
begin
  if not Assigned(RegisteredNodeClasses) then
    RegisteredNodeClasses := TList.Create;
  if RegisteredNodeClasses.IndexOf(aNodeClass) < 0 then
  begin
    RegisteredNodeClasses.Add(aNodeClass);
    classes.RegisterClass(aNodeClass);
  end;
end;

class procedure TEvsSimpleGraph.Unregister(aNodeClass: TEvsGraphNodeClass);
begin
  if Assigned(RegisteredNodeClasses) then
  begin
    classes.UnRegisterClass(aNodeClass);
    RegisteredNodeClasses.Remove(aNodeClass);
    if RegisteredNodeClasses.Count = 0 then
    begin
      RegisteredNodeClasses.Free;
      RegisteredNodeClasses := nil;
    end;
  end;
end;

class function TEvsSimpleGraph.NodeClassCount: integer;
begin
  if Assigned(RegisteredNodeClasses) then
    Result := RegisteredNodeClasses.Count
  else
    Result := 0;
end;

class function TEvsSimpleGraph.NodeClasses(aIndex: integer): TEvsGraphNodeClass;
begin
  Result := TEvsGraphNodeClass(RegisteredNodeClasses[aIndex]);
end;

class procedure TEvsSimpleGraph.Register(aLinkClass: TEvsGraphLinkClass);
begin
  if not Assigned(RegisteredLinkClasses) then
    RegisteredLinkClasses := TList.Create;
  if RegisteredLinkClasses.IndexOf(aLinkClass) < 0 then
  begin
    RegisteredLinkClasses.Add(aLinkClass);
    Classes.RegisterClass(aLinkClass);
  end;
end;

class procedure TEvsSimpleGraph.Unregister(aLinkClass: TEvsGraphLinkClass);
begin
  if Assigned(RegisteredLinkClasses) then
  begin
    Classes.UnregisterClass(aLinkClass);
    RegisteredLinkClasses.Remove(aLinkClass);
    if RegisteredLinkClasses.Count = 0 then
    begin
      RegisteredLinkClasses.Free;
      RegisteredLinkClasses := nil;
    end;
  end;
end;

class function TEvsSimpleGraph.LinkClassCount: integer;
begin
  if Assigned(RegisteredLinkClasses) then
    Result := RegisteredLinkClasses.Count
  else
    Result := 0;
end;

class function TEvsSimpleGraph.LinkClasses(aIndex: integer): TEvsGraphLinkClass;
begin
  Result := TEvsGraphLinkClass(RegisteredLinkClasses[aIndex]);
end;

constructor TEvsSimpleGraph.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);

  Canvas.Free;
  Canvas := TEvsGraphCanvas.Create;
  TControlCanvas(Canvas).Control := Self;

  Canvas.AntialiasingMode:=amOn;
  ControlStyle              := [csCaptureMouse, csClickEvents, csDoubleClicks, csOpaque];

  FCustomCanvas             := Nil;

  UndoStorage               := TMemoryStream.Create;
  fHorzScrollBar            := TEvsGraphScrollBar.Create(Self, sbHorizontal);
  fVertScrollBar            := TEvsGraphScrollBar.Create(Self, sbVertical);
  fGraphConstraints         := TEvsGraphConstraints.Create(Self);
  fCanvasRecall             := TEvsCanvasRecall.Create(nil);
  fObjects                  := TEvsGraphObjectList.Create;
  fObjects.OnChange         := @ObjectListChanged;
  fSelectedObjects          := TEvsGraphObjectList.Create;
  fSelectedObjects.OnChange := @SelectedListChanged;
  fDraggingObjects          := TEvsGraphObjectList.Create;
  fDraggingObjects.OnChange := @DraggingListChanged;
  fGridSize                 := 8;
  fGridColor                := clGray;
  fShowGrid                 := True;
  fSnapToGrid               := True;
  fLockNodes                := False;
  fLockLinks                := False;
  fMarkerColor              := clBlack;
  fMarkerSize               := 3;
  fMinNodeSize              := 16;
  fZoom                     := 100;
  fZoomFactor               := 1.0;
  fDefaultKeyMap            := True;
  fCommandMode              := cmEdit;
  fModified                 := False;
  fMarkedArea               := EmptyRect;
  fClipboardFormats         := [cfNative];
  fPrinting                 := False;
  FLayers                   := TEvsGraphLayerList.Create;
  FActiveLayer              := FLayers.New;
  if NodeClassCount > 0 then fDefaultNodeClass := NodeClasses(0);
  if LinkClassCount > 0 then fDefaultLinkClass := LinkClasses(0);
  //DoubleBuffered := True;
  Color := clWindow;
end;

destructor TEvsSimpleGraph.Destroy;
begin
  Inc(FSuspendQueryEvents);
  Inc(UpdateCount);
  fObjects.Free;
  fSelectedObjects.Free;
  fDraggingObjects.Free;
  fGraphConstraints.Free;
  fHorzScrollBar.Free;
  fVertScrollBar.Free;
  fCanvasRecall.Free;
  UndoStorage.Free;
  inherited Destroy;
end;

procedure TEvsSimpleGraph.BeginUpdate;
begin
  if UpdateCount = 0 then
  begin
    SaveModified := 0;
    SaveRangeChange := False;
    SaveInvalidateRect := EmptyRect;
  end;
  Inc(UpdateCount);
end;

procedure TEvsSimpleGraph.EndUpdate;
begin
  Dec(UpdateCount);
  if (UpdateCount = 0) and not (csDestroying in ComponentState) then
  begin
    if SaveRangeChange then
    begin
      SaveBoundsChange := [Low(TEvsGraphBoundsKind)..High(TEvsGraphBoundsKind)];
      CalcAutoRange;
    end;
    if not IsRectEmpty(SaveInvalidateRect) then
      PerformInvalidate(@SaveInvalidateRect);
    if SaveModified <> 0 then
    begin
      Modified := (SaveModified = 1);
      DoGraphChange;
    end;
  end;
end;

procedure TEvsSimpleGraph.Invalidate;
begin
  if UpdateCount <> 0 then
    SaveInvalidateRect := Types.Rect(0, 0, Screen.Width, Screen.Height)
  else
    PerformInvalidate(nil);
end;

procedure TEvsSimpleGraph.InvalidateRect(const Rect: TRect);
var
  ScreenRect: TRect;
begin
  ScreenRect := Rect;
  GPToCP(ScreenRect, 2); {$MESSAGE WARN 'GPTOCP'}
  Inc(ScreenRect.Right);
  Inc(ScreenRect.Bottom);
  if UpdateCount <> 0 then
  begin
    if IsRectEmpty(SaveInvalidateRect) then
      SaveInvalidateRect := ScreenRect
    else
      UnionRect(SaveInvalidateRect, ScreenRect);
  end
  else
    PerformInvalidate(@ScreenRect);
end;

procedure TEvsSimpleGraph.DrawTo(aCanvas :TCanvas);
begin
  DrawObjects(Canvas, Objects);
end;

procedure TEvsSimpleGraph.Print(aCanvas: TCanvas; const Rect: TRect);
var
  vGraphRect            : TRect;
  {$IFDEF METAFILE_SUPPORT}
  vMetafile             : TMetafile;
  {$ENDIF}
  vRectSize, vGraphSize : TPoint;
begin
  {$MSSAGE WARN 'IMPLEMENT TEvsSimpleGraph.Print'}
  vGraphRect := GraphBounds;
  FPrinting := True;
  try
    if not IsRectEmpty(vGraphRect) then
    begin
      vGraphSize.X := vGraphRect.Right - vGraphRect.Left;
      vGraphSize.Y := vGraphRect.Bottom - vGraphRect.Top;
      vRectSize.X := Rect.Right - Rect.Left;
      vRectSize.Y := Rect.Bottom - Rect.Top;
      if (vRectSize.X / vGraphSize.X) < (vRectSize.Y / vGraphSize.Y) then
      begin
        vGraphSize.Y := MulDiv(vGraphSize.Y, vRectSize.X, vGraphSize.X);
        vGraphSize.X := vRectSize.X;
      end
      else
      begin
        vGraphSize.X := MulDiv(vGraphSize.X, vRectSize.Y, vGraphSize.Y);
        vGraphSize.Y := vRectSize.Y;
      end;
      SetRect(vGraphRect, 0, 0, vGraphSize.X, vGraphSize.Y);
      OffsetRect(vGraphRect,
        Rect.Left + (vRectSize.X - vGraphSize.X) div 2,
        Rect.Top + (vRectSize.Y - vGraphSize.Y) div 2);
      {$IFDEF METAFILE_SUPPORT}
      vMetafile := GetAsMetafile(aCanvas.Handle, Objects);
      try
        aCanvas.StretchDraw(vGraphRect, vMetafile);
      finally
        vMetafile.Free;
      end;
      {$ELSE}
        {$MESSAGE WARN 'NO PRINTING SUPPORT'}
      {$ENDIF}
    end;
  finally
    FPrinting := False;
  end;
end;

procedure TEvsSimpleGraph.ScrollInView(aGraphObject: TEvsGraphObject);
begin
  if Assigned(aGraphObject) then
    ScrollInView(aGraphObject.SelectedVisualRect);
end;

procedure TEvsSimpleGraph.ScrollInView(const aRect: TRect);
var
  vPt: TPoint;
begin
  vPt := aRect.TopLeft;
  with VisibleBounds do
  begin
    if ((aRect.Right - aRect.Left) <= (Right - Left)) and (aRect.Right > Right) then
      vPt.X := aRect.Right;
    if ((aRect.Bottom - aRect.Top) <= (Bottom - Top)) and (aRect.Bottom > Bottom) then
      vPt.Y := aRect.Bottom;
  end;
  ScrollInView(vPt);
end;

procedure TEvsSimpleGraph.ScrollInView(const aPt: TPoint);
var
  vX, vY: integer;
begin
  vX := MulDiv(aPt.X, Zoom, 100);
  vY := MulDiv(aPt.Y, Zoom, 100);
  with HorzScrollBar do
    if IsScrollBarVisible then
    begin
      if vX < Position then
        Position := vX
      else if vX > Position + Self.ClientWidth then
        Position := vX - Self.ClientWidth;
    end;
  with VertScrollBar do
    if IsScrollBarVisible then
    begin
      if vY < Position then
        Position := vY
      else if vY > Position + Self.ClientHeight then
        Position := vY - Self.ClientHeight;
    end;
end;

procedure TEvsSimpleGraph.ScrollCenter(aGraphObject: TEvsGraphObject);
begin
  ScrollCenter(aGraphObject.VisualRect);
end;

procedure TEvsSimpleGraph.ScrollCenter(const aRect: TRect);
begin
  ScrollCenter(CenterOfRect(aRect));
end;

procedure TEvsSimpleGraph.ScrollCenter(const aPt: TPoint);
var
  vX, vY: integer;
begin
  vX := MulDiv(aPt.X, Zoom, 100);
  vY := MulDiv(aPt.Y, Zoom, 100);
  with HorzScrollBar do
    if IsScrollBarVisible then
      Position := vX - Self.ClientWidth div 2;
  with VertScrollBar do
    if IsScrollBarVisible then
      Position := vY - Self.ClientHeight div 2;
end;

procedure TEvsSimpleGraph.ScrollBy(aDeltaX, aDeltaY: integer);
begin
  inherited ScrollBy(aDeltaX, aDeltaY);
  Invalidate;
  UpdateWindow(WindowHandle);
end;

procedure TEvsSimpleGraph.ToggleSelection(const aRect: TRect; aKeepOld: boolean;
  aGraphObjectClass: TEvsGraphObjectClass);
var
  vGraphObject: TEvsGraphObject;
  vCntr: integer;
begin
  if not Assigned(aGraphObjectClass) then
    aGraphObjectClass := TEvsGraphObject;
  for vCntr := 0 to Objects.Count - 1 do
  begin
    vGraphObject := Objects[vCntr];
    if (vGraphObject is aGraphObjectClass) and vGraphObject.ContainsRect(aRect) then
      vGraphObject.Selected := not (aKeepOld and vGraphObject.Selected)
    else if not aKeepOld then
      vGraphObject.Selected := False;
  end;
end;

function TEvsSimpleGraph.FindObjectAt(aX, aY: integer; aLookAfter: TEvsGraphObject): TEvsGraphObject;
var
  vTopIndex, vCntr : integer;
  vGraphObject     : TEvsGraphObject;
  vHT              : DWORD;
  vPt              : TPoint;
begin
  Result := nil;
  if Assigned(aLookAfter) then
    vTopIndex := aLookAfter.ZOrder
  else
    vTopIndex := Objects.Count;
  vPt := types.Point(aX, aY);
  for vCntr := vTopIndex - 1 downto 0 do
  begin
    vGraphObject := Objects[vCntr];
    if vGraphObject <> DragSource then
    begin
      vHT := vGraphObject.HitTest(vPt);
      if vHT <> GHT_NOWHERE then
      begin
        if not Assigned(Result) then
          Result := vGraphObject;
        if SelectedObjects.Count = 0 then
          Exit
        else if vGraphObject.Selected then
        begin
          if vGraphObject = Result then
            Exit
          else if vGraphObject.IsLink or ((vHT and GHT_BODY_MASK) = 0) then
          begin
            Result := vGraphObject;
            Exit;
          end;
        end;
      end;
    end;
  end;
end;

function TEvsSimpleGraph.FindObjectByID(aID: DWORD): TEvsGraphObject;
var
  I: integer;
begin
  Result := nil;
  for I := Objects.Count - 1 downto 0 do
    if Objects[I].ID = aID then
    begin
      Result := Objects[I];
      Exit;
    end;
end;

function TEvsSimpleGraph.InsertNode(const aBounds: TRect;
  aNodeClass: TEvsGraphNodeClass): TEvsGraphNode;
begin
  if not Assigned(aNodeClass) then
    aNodeClass := DefaultNodeClass;
  try
    Result := aNodeClass.CreateNew(Self, aBounds);
  except
    Result := nil;
  end;
end;

function TEvsSimpleGraph.InsertLink(aSource, aTarget: TEvsGraphObject;
  aLinkClass: TEvsGraphLinkClass): TEvsGraphLink;
begin
  if not Assigned(aLinkClass) then
    aLinkClass := DefaultLinkClass;
  try
    Result := aLinkClass.CreateNew(Self, aSource, [], aTarget)
  except
    Result := nil;
  end;
end;

function TEvsSimpleGraph.InsertLink(aSource: TEvsGraphObject;
  const aPts: array of TPoint; aLinkClass: TEvsGraphLinkClass): TEvsGraphLink;
begin
  if not Assigned(aLinkClass) then
    aLinkClass := DefaultLinkClass;
  try
    Result := aLinkClass.CreateNew(Self, aSource, aPts, nil);
  except
    Result := nil;
  end;
end;

function TEvsSimpleGraph.InsertLink(const aPts: array of TPoint;
  aTarget: TEvsGraphObject; aLinkClass: TEvsGraphLinkClass): TEvsGraphLink;
begin
  if not Assigned(aLinkClass) then
    aLinkClass := DefaultLinkClass;
  try
    Result := aLinkClass.CreateNew(Self, nil, aPts, aTarget);
  except
    Result := nil;
  end;
end;

function TEvsSimpleGraph.InsertLink(const aPts: array of TPoint;
  aLinkClass: TEvsGraphLinkClass): TEvsGraphLink;
begin
  if not Assigned(aLinkClass) then
    aLinkClass := DefaultLinkClass;
  try
    Result := aLinkClass.CreateNew(Self, nil, aPts, nil);
  except
    Result := nil;
  end;
end;

function TEvsSimpleGraph.ZoomRect(const aRect: TRect): boolean;
var
  vHorZoom, vVerZoom: integer;
  vClientRect: TRect;
begin
  vClientRect := ClientRect;
  if VertScrollBar.IsScrollBarVisible then
    Dec(vClientRect.Right, GetSystemMetrics(SM_CXVSCROLL));
  if HorzScrollBar.IsScrollBarVisible then
    Dec(vClientRect.Bottom, GetSystemMetrics(SM_CYHSCROLL));
  vHorZoom := MulDiv(100, vClientRect.Right - vClientRect.Left, aRect.Right - aRect.Left);
  vVerZoom := MulDiv(100, vClientRect.Bottom - vClientRect.Top, aRect.Bottom - aRect.Top);
  if vHorZoom < vVerZoom then
    Zoom := vHorZoom
  else
    Zoom := vVerZoom;
  ScrollCenter(aRect);
  Result := (Zoom = vHorZoom) or (Zoom = vVerZoom);
end;

function TEvsSimpleGraph.ZoomObject(aGraphObject: TEvsGraphObject): boolean;
begin
  if Assigned(aGraphObject) then
    Result := ZoomRect(aGraphObject.VisualRect)
  else
    Result := False;
end;

function TEvsSimpleGraph.ZoomSelection: boolean;
begin
  if SelectedObjects.Count > 0 then
    Result := ZoomRect(SelectionBounds)
  else
    Result := False;
end;

function TEvsSimpleGraph.ZoomGraph: boolean;
begin
  if Objects.Count > 0 then
    Result := ZoomRect(GraphBounds)
  else
    Result := False;
end;

function TEvsSimpleGraph.ChangeZoom(aNewZoom: integer; aOrigin: TEvsGraphZoomOrigin): boolean;
var
  vRect: TRect;
begin
  Result := False;
  if aNewZoom < Low(TZoom) then
    aNewZoom := Low(TZoom)
  else if aNewZoom > High(TZoom) then
    aNewZoom := High(TZoom);
  if fZoom <> aNewZoom then
  begin
    case aOrigin of
      zoTopLeft, zoCenter:
        vRect := VisibleBounds;
      zoCursor, zoCursorCenter:
        vRect.TopLeft := CursorPos;
    end;
    fZoom := aNewZoom;
    FZoomFactor := 100/aNewZoom;
    CalcAutoRange;
    case aOrigin of
      zoTopLeft:
        ScrollInView(vRect);
      zoCenter:
        ScrollCenter(vRect);
      zoCursor:
      begin
        vRect.BottomRight := CursorPos;
        with HorzScrollBar do
          if IsScrollBarVisible then
            Position := Position - MulDiv(vRect.Right - vRect.Left, Zoom, 100);
        with VertScrollBar do
          if IsScrollBarVisible then
            Position := Position - MulDiv(vRect.Bottom - vRect.Top, Zoom, 100);
      end;
      zoCursorCenter:
        ScrollCenter(vRect.TopLeft);
    end;
    Invalidate;
    DoZoomChange;
    Result := True;
  end;
end;

function TEvsSimpleGraph.ChangeZoomBy(aDelta: integer; aOrigin: TEvsGraphZoomOrigin): boolean;
begin
  Result := ChangeZoom(Zoom + aDelta, aOrigin);
end;

function TEvsSimpleGraph.LayerByOrder(const aOrder :integer) :TEvsGraphLayer;
var
  vCntr :Integer;
begin
  Result:=nil;
  for vCntr := 0 to FLayers.Count -1 do begin
    if (Layers[vCntr].Top >= aOrder) and (Layers[vCntr].Bottom <= aOrder) then begin
      Result := Layers[vCntr];
      Break;
    end;
  end;
end;

procedure TEvsSimpleGraph.CLtoGP(var Points : array of TPoint);
var
  vCntr : Integer;
  vZoomFactor : Double;
begin
  vZoomFactor := Zoom/100;
  fHorzScrollBar.IsScrollBarVisible;
  for vCntr := Low(Points) to High(Points) do begin
    if fHorzScrollBar.IsScrollBarVisible then Points[vCntr].X := Points[vCntr].X + fHorzScrollBar.Position;
    if fVertScrollBar.IsScrollBarVisible then Points[vCntr].Y := Points[vCntr].Y + fVertScrollBar.Position;
  end;
end;

procedure TEvsSimpleGraph.GPtoCL(var Points : array of TPoint);
var
  vCntr : Integer;
begin
  for vCntr := Low(Points) to High(Points) do begin
    Points[vCntr].X := round((Points[vCntr].X - fHorzScrollBar.Position) * FZoomFactor);
    Points[vCntr].Y := round((Points[vCntr].Y - fVertScrollBar.Position) * FZoomFactor);
  end;
end;

procedure TEvsSimpleGraph.OffsetObjects(const aList : TEvsGraphObjectList; aDX, aDY : Integer);
var
  vCntr : Integer;
begin
  for vCntr := 0 to aList.Count -1 do begin
    aList[vCntr].MoveBy(aDX,aDY);
  end;
end;

procedure TEvsSimpleGraph.StartPrinting;
begin
  FPrinting := True;
end;

procedure TEvsSimpleGraph.EndPrinting;
begin
  FPrinting := False;
end;

function TEvsSimpleGraph.AlignSelection(aHorz: TEvsHAlignOption; aVert: TEvsVAlignOption): boolean;

  function DoHSpaceEqually: boolean;
  var
    vI, vJ                  : integer;
    vObjectList             : TEvsGraphObjectList;
    vGraphObject            : TEvsGraphObject;
    vSpace, vLeft, vdX, vdY : integer;
  begin
    Result := False;
    vObjectList := TEvsGraphObjectList.Create;
    try
      vObjectList.Capacity := SelectedObjects.Count;
      for vI := 0 to SelectedObjects.Count - 1 do
      begin
        vGraphObject := SelectedObjects[vI];
        for vJ := 0 to vObjectList.Count - 1 do
          if vObjectList[vJ].BoundsRect.Left > vGraphObject.BoundsRect.Left then
          begin
            vObjectList.Insert(vJ, vGraphObject);
            vGraphObject := nil;
            Break;
          end;
        if Assigned(vGraphObject) then
          vObjectList.Add(vGraphObject);
      end;
      vSpace := vObjectList[vObjectList.Count - 1].BoundsRect.Right -
        vObjectList[0].BoundsRect.Left;
      for vI := 0 to vObjectList.Count - 1 do
        with vObjectList[vI].BoundsRect do
          Dec(vSpace, Right - vLeft);
      vSpace := vSpace div (vObjectList.Count - 1);
      vdY := 0;
      vLeft := vObjectList[0].BoundsRect.Right + vSpace;
      for vI := 1 to vObjectList.Count - 2 do
      begin
        GraphConstraints.SourceRect := vObjectList[vI].BoundsRect;
        vdX := vLeft - vObjectList[vI].BoundsRect.Left;
        if GraphConstraints.ConfineOffset(vdX, vdY, [osLeft, osRight]) and
          vObjectList[vI].OffsetHitTest(GHT_CLIENT, vdX, vdY) then
          Result := True;
        vLeft := vObjectList[vI].BoundsRect.Right + vSpace;
      end;
    finally
      vObjectList.Free;
    end;
  end;

  function DoVSpaceEqually: boolean;
  var
    vI, vJ                 : integer;
    vObjectList            : TEvsGraphObjectList;
    vGraphObject           : TEvsGraphObject;
    vSpace, vTop, vdX, vdY : integer;
  begin
    Result := False;
    vObjectList := TEvsGraphObjectList.Create;
    try
      vObjectList.Capacity := SelectedObjects.Count;
      for vI := 0 to SelectedObjects.Count - 1 do
      begin
        vGraphObject := SelectedObjects[vI];
        for vJ := 0 to vObjectList.Count - 1 do
          if vObjectList[vJ].BoundsRect.Top > vGraphObject.BoundsRect.Top then
          begin
            vObjectList.Insert(vJ, vGraphObject);
            vGraphObject := nil;
            Break;
          end;
        if Assigned(vGraphObject) then
          vObjectList.Add(vGraphObject);
      end;
      vSpace := vObjectList[vObjectList.Count - 1].BoundsRect.Bottom -
        vObjectList[0].BoundsRect.Top;
      for vI := 0 to vObjectList.Count - 1 do
        with vObjectList[vI].BoundsRect do
          Dec(vSpace, Bottom - Top);
      vSpace := vSpace div (vObjectList.Count - 1);
      vdX := 0;
      vTop := vObjectList[0].BoundsRect.Bottom + vSpace;
      for vI := 1 to vObjectList.Count - 2 do
      begin
        GraphConstraints.SourceRect := vObjectList[vI].BoundsRect;
        vdY := vTop - vObjectList[vI].BoundsRect.Top;
        if GraphConstraints.ConfineOffset(vdX, vdY, [osTop, osBottom]) and
          vObjectList[vI].OffsetHitTest(GHT_CLIENT, vdX, vdY) then
          Result := True;
        vTop := vObjectList[vI].BoundsRect.Bottom + vSpace;
      end;
    finally
      vObjectList.Free;
    end;
  end;

  function DoOtherAlignment: boolean;
  var
    vI                 : integer;
    vRefRect, vObjRect : TRect;
    vdX, vdY           : integer;
  begin
    Result := False;
    vRefRect := SelectedObjects[0].BoundsRect;
    for vI := 1 to SelectedObjects.Count - 1 do
    begin
      vObjRect := SelectedObjects[vI].BoundsRect;
      case aHorz of
        haLeft:
          vdX := vRefRect.Left - vObjRect.Left;
        haCenter:
          vdX := CenterOfRect(vRefRect).X - CenterOfRect(vObjRect).X;
        haRight:
          vdX := vRefRect.Right - vObjRect.Right;
        else
          vdX := 0;
      end;
      case aVert of
        vaTop:
          vdY := vRefRect.Top - vObjRect.Top;
        vaCenter:
          vdY := CenterOfRect(vRefRect).Y - CenterOfRect(vObjRect).Y;
        vaBottom:
          vdY := vRefRect.Bottom - vObjRect.Bottom;
        else
          vdY := 0;
      end;
      GraphConstraints.SourceRect := vObjRect;
      if GraphConstraints.ConfineOffset(vdX, vdY, [osLeft, osTop, osRight, osBottom]) and
        SelectedObjects[vI].OffsetHitTest(GHT_CLIENT, vdX, vdY) then
        Result := True;
    end;
  end;

begin
  Result := False;
  if SelectedObjects.Count > 1 then
  begin
    BeginUpdate;
    try
      if (aHorz = haSpaceEqually) and (SelectedObjects.Count > 2) and DoHSpaceEqually then
        Result := True;
      if (aVert = vaSpaceEqually) and (SelectedObjects.Count > 2) and DoVSpaceEqually then
        Result := True;
      if ((aHorz <> haSpaceEqually) or (aVert <> vaSpaceEqually)) and DoOtherAlignment then
        Result := True;
    finally
      EndUpdate;
    end;
  end;
end;

function TEvsSimpleGraph.ResizeSelection(aHorz: TEvsResizeOption;
  aVert: TEvsResizeOption): boolean;
var
  vMaxWidth, vMaxHeight: integer;
  vMinWidth, vMinHeight: integer;
  vdX, vdY: integer;
  vObjRect: TRect;
  I, V: integer;
begin
  Result := False;
  if SelectedObjects.Count > 1 then
  begin
    vMinWidth := MaxInt;
    vMaxWidth := 0;
    vMinHeight := MaxInt;
    vMaxHeight := 0;
    for I := 0 to SelectedObjects.Count - 1 do
      with SelectedObjects[I].BoundsRect do
      begin
        V := Right - Left;
        if V < vMinWidth then
          vMinWidth := V;
        if V > vMaxWidth then
          vMaxWidth := V;
        V := Bottom - Top;
        if V < vMinHeight then
          vMinHeight := V;
        if V > vMaxHeight then
          vMaxHeight := V;
      end;
    BeginUpdate;
    try
      for I := 0 to SelectedObjects.Count - 1 do
      begin
        vObjRect := SelectedObjects[I].BoundsRect;
        case aHorz of
          roNoChange:
            vdX := 0;
          roSmallest:
            vdX := vMinWidth - (vObjRect.Right - vObjRect.Left);
          roLargest:
            vdX := vMaxWidth - (vObjRect.Right - vObjRect.Left);
        end;
        case aVert of
          roNoChange:
            vdY := 0;
          roSmallest:
            vdY := vMinHeight - (vObjRect.Bottom - vObjRect.Top);
          roLargest:
            vdY := vMaxHeight - (vObjRect.Bottom - vObjRect.Top);
        end;
        GraphConstraints.SourceRect := vObjRect;
        if GraphConstraints.ConfineOffset(vdX, vdY, [osRight, osBottom]) and
          SelectedObjects[I].OffsetHitTest(GHT_BOTTOMRIGHT, vdX, vdY) then
          Result := True;
      end;
    finally
      EndUpdate;
    end;
  end;
end;

function TEvsSimpleGraph.ForEachObject(aCallback: TEvsGraphForEachMethod;
  aUserData: integer; aSelection: boolean): integer;
var
  vGraphObject: TEvsGraphObject;
  vObjectList: TEvsGraphObjectList;
begin
  Result := 0;
  if aSelection then
    vObjectList := SelectedObjects
  else
    vObjectList := Objects;
  if Assigned(aCallback) and (vObjectList.Count > 0) then
  begin
    BeginUpdate;
    try
      vGraphObject := vObjectList.First;
      while Assigned(vGraphObject) do
      begin
        vObjectList.Push;
        try
          if not aCallback(vGraphObject, aUserData) then
            Break;
        finally
          vObjectList.Pop;
        end;
        vGraphObject := vObjectList.Next;
      end;
    finally
      EndUpdate;
    end;
  end;
end;

function TEvsSimpleGraph.FindNextObject(aStartIndex: integer; aInclusive,
  aBackward, aWrap: boolean; aGraphObjectClass: TEvsGraphObjectClass): TEvsGraphObject;
var
  I: integer;
begin
  Result := nil;
  if not Assigned(aGraphObjectClass) then
    aGraphObjectClass := TEvsGraphObject;
  if aBackward then
  begin
    for I := aStartIndex - Ord(not aInclusive) downto 0 do
      if Objects[I] is aGraphObjectClass then
      begin
        Result := Objects[I];
        Exit;
      end;
    if aWrap then
    begin
      for I := Objects.Count - 1 downto aStartIndex + 1 do
        if Objects[I] is aGraphObjectClass then
        begin
          Result := Objects[I];
          Exit;
        end;
    end;
  end
  else
  begin
    for I := aStartIndex + Ord(not aInclusive) to Objects.Count - 1 do
      if Objects[I] is aGraphObjectClass then
      begin
        Result := Objects[I];
        Exit;
      end;
    if aWrap then
    begin
      for I := 0 to aStartIndex - 1 do
        if Objects[I] is aGraphObjectClass then
        begin
          Result := Objects[I];
          Exit;
        end;
    end;
  end;
end;

function TEvsSimpleGraph.SelectNextObject(aBackward: boolean;
  aGraphObjectClass: TEvsGraphObjectClass): boolean;
var
  vIndex, I    : integer;
  vGraphObject : TEvsGraphObject;
begin
  Result := False;
  if not Assigned(aGraphObjectClass) then
    aGraphObjectClass := TEvsGraphObject;
  if Objects.Count > 0 then
  begin
    vGraphObject := nil;
    for I := 0 to SelectedObjects.Count - 1 do
      if SelectedObjects[I] is aGraphObjectClass then
      begin
        vGraphObject := SelectedObjects[I];
        Break;
      end;
    repeat
      vIndex := Objects.IndexOf(vGraphObject);
      vGraphObject := FindNextObject(vIndex, False, aBackward, True, aGraphObjectClass);
    until not Assigned(vGraphObject) or (goSelectable in vGraphObject.Options);
    if Assigned(vGraphObject) then
    begin
      SelectedObjects.Clear;
      vGraphObject.Selected := True;
      ScrollInView(vGraphObject);
      Result := True;
    end;
  end;
end;

function TEvsSimpleGraph.ObjectsCount(aGraphObjectClass: TEvsGraphObjectClass): integer;
var
  I: integer;
begin
  if Assigned(aGraphObjectClass) then
  begin
    Result := 0;
    for I := 0 to Objects.Count - 1 do
      if Objects[I] is aGraphObjectClass then
        Inc(Result);
  end
  else
    Result := Objects.Count;
end;

function TEvsSimpleGraph.SelectedObjectsCount(
  aGraphObjectClass: TEvsGraphObjectClass): integer;
var
  I: integer;
begin
  if Assigned(aGraphObjectClass) then
  begin
    Result := 0;
    for I := 0 to SelectedObjects.Count - 1 do
      if SelectedObjects[I] is aGraphObjectClass then
        Inc(Result);
  end
  else
    Result := SelectedObjects.Count;
end;

procedure TEvsSimpleGraph.ClearSelection;
begin
  SelectedObjects.Clear;
end;

procedure TEvsSimpleGraph.Clear;
begin
  if Objects.Count > 0 then
  begin
    BeginUpdate;
    try
      SuspendQueryEvents;
      try
        Objects.Clear;
      finally
        ResumeQueryEvents;
      end;
      SaveModified := 2;
    finally
      EndUpdate;
    end;
  end;
  CommandMode := cmEdit;
  HorzScrollBar.Position := 0;
  VertScrollBar.Position := 0;
end;

procedure TEvsSimpleGraph.CopyToGraphic(aGraphic: TGraphic);
var
  G: TGraphic;
begin
  {.$MESSAGE HINT 'METAFILE SUPPORT'}
  {$IFDEF METAFILE_SUPPORT}
  if aGraphic is TMetafile then
  begin
    G := GetAsMetafile(0, Objects);
    try
      aGraphic.Assign(G);
    finally
      G.Free;
    end;
  end
  else
  {$ENDIF}
  {$MESSAGE WARN 'OUT OF MEMORY ERROR MIGHT BE RAISED'}
  //Depends on the size of the drawing arrea.
  begin
    G := GetAsBitmap(Objects);
    try
      aGraphic.Assign(G);
    finally
      G.Free;
    end;
  end;
end;

procedure TEvsSimpleGraph.LoadFromStream(aStream: TStream);
var
  vSignature: DWORD;
begin
  aStream.Read(vSignature, SizeOf(vSignature));
  if vSignature <> StreamSignature then
    raise EEvsGraphStreamError.Create(SStreamContentError);
  BeginUpdate;
  try
    Clear;
    ReadObjects(aStream);
    SaveModified := 2;
  finally
    EndUpdate;
  end;
end;

procedure TEvsSimpleGraph.SaveToStream(aStream: TStream);
begin
  aStream.Write(StreamSignature, SizeOf(StreamSignature));
  WriteObjects(aStream, Objects);
  Modified := False;
end;

procedure TEvsSimpleGraph.LoadFromFile(const aFilename: string);
var
  vStream: TFileStream;
begin
  vStream := TFileStream.Create(aFilename, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(vStream);
  finally
    vStream.Free;
  end;
end;

procedure TEvsSimpleGraph.SaveToFile(const aFilename: string);
var
  vStream: TFileStream;
begin
  vStream := TFileStream.Create(aFilename, fmCreate or fmShareExclusive);
  try
    SaveToStream(vStream);
  finally
    vStream.Free;
  end;
end;

procedure TEvsSimpleGraph.MergeFromStream(aStream: TStream; aOffsetX,
  aOffsetY: integer);
var
  vSignature         : DWORD;
  vOldObjectCount, I : integer;
  vNewObjectsBounds  : TRect;
begin
  aStream.Read(vSignature, SizeOf(vSignature));
  if vSignature <> StreamSignature then
    raise EEvsGraphStreamError.Create(SStreamContentError);
  BeginUpdate;
  try
    SelectedObjects.Clear;
    vOldObjectCount := Objects.Count;
    ReadObjects(aStream);
    if vOldObjectCount <> Objects.Count then begin
      fSelectedObjects.Capacity := fObjects.Count - vOldObjectCount;
      for I := vOldObjectCount to fObjects.Count - 1 do
        Objects[I].Selected := True;
      vNewObjectsBounds := GetObjectsBounds(fSelectedObjects);
      GraphConstraints.SourceRect := vNewObjectsBounds;
      if GraphConstraints.ConfineOffset(aOffsetX, aOffsetY, [osLeft, osTop, osRight, osBottom]) then begin
        SuspendQueryEvents;
        try
          for I := 0 to FSelectedObjects.Count - 1 do
            FSelectedObjects[I].MoveBy(aOffsetX, aOffsetY);
        finally
          ResumeQueryEvents;
        end;
        OffsetRect(vNewObjectsBounds, aOffsetX, aOffsetY);
      end;
    end;
  finally
    EndUpdate;
  end;
  CommandMode := cmEdit;
  if vOldObjectCount <> Objects.Count then ScrollInView(vNewObjectsBounds);
end;

procedure TEvsSimpleGraph.MergeFromFile(const aFilename: string; aOffsetX,
  aOffsetY: integer);
var
  vStream: TFileStream;
begin
  vStream := TFileStream.Create(aFilename, fmOpenRead or fmShareDenyWrite);
  try
    MergeFromStream(vStream, aOffsetX, aOffsetY);
  finally
    vStream.Free;
  end;
end;

function TEvsSimpleGraph.ClientToGraph(aX, aY: integer): TPoint;
begin
  Result.X := aX;
  Result.Y := aY;
  //CPToGP(Result, 1);
  CLtoGP(Result);
end;

function TEvsSimpleGraph.GraphToClient(aX, aY: integer): TPoint;
begin
  Result.X := aX;
  Result.Y := aY;
  GPToCP(Result, 1);
  //GPtoCL(Result);
end;

function TEvsSimpleGraph.ScreenToGraph(aX, aY: integer): TPoint;
begin
  with ScreenToClient(types.Point(aX, aY)) do
    Result := ClientToGraph(X, Y);
end;

function TEvsSimpleGraph.GraphToScreen(aX, aY: integer): TPoint;
begin
  Result := ClientToScreen(GraphToClient(aX, aY));
end;

procedure TEvsSimpleGraph.SnapOffset(const aPt: TPoint; var adX, adY: integer);
begin
  with SnapPoint(types.Point(aPt.X + adX, aPt.Y + adY)) do
  begin
    if adX <> 0 then
      adX := X - aPt.X;
    if adY <> 0 then
      adY := Y - aPt.Y;
  end;
end;

function TEvsSimpleGraph.SnapPoint(const aPt: TPoint): TPoint;
begin
  Result.X := ((aPt.X + (Integer(GridSize) div 2)) div GridSize) * GridSize;
  Result.Y := ((aPt.Y + (Integer(GridSize) div 2)) div GridSize) * GridSize;
end;
{$ENDREGION}

{$REGION ' TEvsGraphConstraints '}

constructor TEvsGraphConstraints.Create(AOwner: TEvsSimpleGraph);
begin
  inherited Create;
  fOwner := AOwner;
  fBoundsRect := types.Rect(0, 0, $0000FFFF, $0000FFFF);
end;

function TEvsGraphConstraints.GetOwner: TPersistent;
begin
  Result := fOwner;
end;

procedure TEvsGraphConstraints.DoChange;
begin
  if Assigned(Owner) then
  begin
    Owner.CalcAutoRange;
    Owner.Invalidate;
  end;
  if Assigned(OnChange) then
    OnChange(Self);
end;

procedure TEvsGraphConstraints.Assign(Source: TPersistent);
begin
  if Source is TEvsGraphConstraints then
    BoundsRect := TEvsGraphConstraints(Source).BoundsRect
  else
    inherited Assign(Source);
end;

procedure TEvsGraphConstraints.SetBounds(aLeft, aTop, aWidth, aHeight: Integer);
begin
  BoundsRect := Bounds(aLeft, aTop, aWidth, aHeight);
end;

function TEvsGraphConstraints.WithinBounds(const Pts: array of TPoint): Boolean;
var
  I: Integer;
begin
  Result := True;
  for I := Low(Pts) to High(Pts) do
    if not PtInRect(BoundsRect, Pts[I]) then
    begin
      Result := False;
      Exit;
    end;
end;

function TEvsGraphConstraints.ConfinePt(var Pt: TPoint): Boolean;
begin
  Result := True;
  if Pt.X < BoundsRect.Left then
  begin
    Pt.X := BoundsRect.Left;
    Result := False;
  end
  else if Pt.X > BoundsRect.Right then
  begin
    Pt.X := BoundsRect.Right;
    Result := False;
  end;
  if Pt.Y < BoundsRect.Top then
  begin
    Pt.Y := BoundsRect.Top;
    Result := False;
  end
  else if Pt.Y > BoundsRect.Bottom then
  begin
    Pt.Y := BoundsRect.Bottom;
    Result := False;
  end;
end;

function TEvsGraphConstraints.ConfineRect(var Rect: TRect): Boolean;
begin
  Result := True;
  if Rect.Left < BoundsRect.Left then
  begin
    Rect.Left := BoundsRect.Left;
    Result := False;
  end;
  if Rect.Right > BoundsRect.Right then
  begin
    Rect.Right := BoundsRect.Right;
    Result := False;
  end;
  if Rect.Top < BoundsRect.Top then
  begin
    Rect.Top := BoundsRect.Top;
    Result := False;
  end;
  if Rect.Bottom > BoundsRect.Bottom then
  begin
    Rect.Bottom := BoundsRect.Bottom;
    Result := False;
  end;
end;

function TEvsGraphConstraints.ConfineOffset(var dX, dY: Integer; Mobility: TEvsObjectSides): Boolean;
begin
  with SourceRect do
  begin
    if (osLeft in Mobility) and (Left + dX < BoundsRect.Left) then
      dX := BoundsRect.Left - Left;
    if (osTop in Mobility) and (Top + dY < BoundsRect.Top) then
      dY := BoundsRect.Top - Top;
    if (osRight in Mobility) and (Right + dX > BoundsRect.Right) then
      dX := BoundsRect.Right - Right;
    if (osBottom in Mobility) and (Bottom + dY > BoundsRect.Bottom) then
      dY := BoundsRect.Bottom - Bottom;
  end;
  Result := (dX <> 0) or (dY <> 0);
end;

procedure TEvsGraphConstraints.SetBoundsRect(const Rect: TRect);
begin
  if not EqualRect(BoundsRect, Rect) then
  begin
    fBoundsRect := Rect;
    DoChange;
  end;
end;

function TEvsGraphConstraints.GetField(Index: Integer): Integer;
begin
  case Index of
    0: Result := BoundsRect.Left;
    1: Result := BoundsRect.Top;
    2: Result := BoundsRect.Right;
    3: Result := BoundsRect.Bottom;
  else
    Result := 0;
  end;
end;

procedure TEvsGraphConstraints.SetField(Index, Value: Integer);
begin
  case Index of
    0: BoundsRect := Types.Rect(Value, MinTop, MaxRight, MaxBottom);
    1: BoundsRect := Types.Rect(MinLeft, Value, MaxRight, MaxBottom);
    2: BoundsRect := Types.Rect(MinLeft, MinTop, Value, MaxBottom);
    3: BoundsRect := Types.Rect(MinLeft, MinTop, MaxRight, Value);
  end;
end;

{$ENDREGION}

{$REGION ' TEvsCanvasRecall '}

constructor TEvsCanvasRecall.Create(AReference: TCanvas);
begin
  fReference := AReference;
  fFont := TFont.Create;
  fPen := TPen.Create;
  fBrush := TBrush.Create;
  Store;
end;

destructor TEvsCanvasRecall.Destroy;
begin
  Retrieve;
  fBrush.Free;
  fPen.Free;
  fFont.Free;
  inherited Destroy;
end;

procedure TEvsCanvasRecall.Store;
begin
  if Assigned(fReference) then
  begin
    fFont.Assign(fReference.Font);
    fPen.Assign(fReference.Pen);
    fBrush.Assign(fReference.Brush);
    fCopyMode := fReference.CopyMode;
    fTextFlags := fReference.TextStyle;
  end;
end;

procedure TEvsCanvasRecall.Retrieve;
begin
  if Assigned(fReference) then
  begin
    fReference.Font.Assign(fFont);
    fReference.Pen.Assign(fPen);
    fReference.Brush.Assign(fBrush);
    fReference.CopyMode := fCopyMode;
    fReference.TextStyle := fTextFlags;
  end;
end;

procedure TEvsCanvasRecall.SetReference(Value: TCanvas);
begin
  if fReference <> Value then
  begin
    Retrieve;
    fReference := Value;
    Store;
  end;
end;
{$ENDREGION}

{$REGION ' TCompatibleCanvas '}
{ TEvsCompatibleCanvas }
constructor TEvsCompatibleCanvas.Create;
begin
  inherited Create;
  Handle := LCLIntf.CreateCompatibleDC(0);                                      //LCLINTF
end;

destructor TEvsCompatibleCanvas.Destroy;
var
  DC: HDC;
begin
  DC := Handle;
  Handle := 0;
  if DC <> 0 then
  {$IFDEF LCLWIN32}
    DeleteObject(DC);
  {$ELSE}
    DeleteDC(DC);
  {$ENDIF}
  inherited Destroy;
end;
{$ENDREGION}

{$REGION ' TGraphObjectList '}
{ TEvsGraphObjectList }

destructor TEvsGraphObjectList.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TEvsGraphObjectList.SetCapacity(Value: integer);
begin
  if fCapacity <> Value then
  begin
    fCapacity := Value;
    while fCapacity < fCount do
      Delete(fCount - 1);
    SetLength(fItems, fCapacity);
  end;
end;

function TEvsGraphObjectList.GetItems(Index: integer): TEvsGraphObject;
begin
  if (Index < 0) or (Index >= fCount) then
    raise EListError.CreateFmt(SListIndexError, [Index]);
  Result := fItems[Index];
end;

procedure TEvsGraphObjectList.Grow;
begin
  if fCount < 64 then
    SetCapacity(fCapacity + 16)
  else
    SetCapacity(fCapacity + 8);
end;

function TEvsGraphObjectList.Replace(OldItem, NewItem: TEvsGraphObject): integer;
begin
  Result := IndexOf(OldItem);
  if Result >= 0 then
    fItems[Result] := NewItem;
end;

procedure TEvsGraphObjectList.NotifyAction(Item: TEvsGraphObject;
  Action: TEvsGraphObjectListAction);
begin
  if Assigned(Item) and Assigned(OnChange) then
    OnChange(Self, Item, Action);
end;

procedure TEvsGraphObjectList.AdjustDeleted(Index: integer; var EnumState: TListEnumState);
begin
  if (EnumState.Dir <> 0) and ((Index < EnumState.Current) or
    ((EnumState.Dir = +1) and (Index = EnumState.Current))) then
    Dec(EnumState.Current);
end;

procedure TEvsGraphObjectList.Clear;
begin
  SetCapacity(0);
  EnumStack := nil;
end;

function TEvsGraphObjectList.GetEnumerator : TEvsGraphObjectListEnumerator;
begin
  Result := TEvsGraphObjectListEnumerator.Create(Self);
end;

function TEvsGraphObjectList.GetReverseEnumerator : TEvsGraphObjectListReverseEnumerator;
begin
  Result := TEvsGraphObjectListReverseEnumerator.Create(Self);
end;

procedure TEvsGraphObjectList.Assign(Source: TPersistent);
var
  I: integer;
begin
  if Source is TEvsGraphObjectList then
  begin
    Clear;
    Capacity := TEvsGraphObjectList(Source).Count;
    for I := 0 to TEvsGraphObjectList(Source).Count - 1 do
      Add(TEvsGraphObjectList(Source).Items[I]);
  end
  else
    inherited Assign(Source);
end;

function TEvsGraphObjectList.IndexOf(Item: TEvsGraphObject): integer;
var
  I: integer;
begin
  Result := -1;
  for I := Count - 1 downto 0 do
    if fItems[I] = Item then
    begin
      Result := I;
      Exit;
    end;
end;

function TEvsGraphObjectList.Add(Item: TEvsGraphObject): integer;
begin
  if Count = Capacity then
    Grow;
  Result := fCount;
  fItems[Result] := Item;
  Inc(fCount);
  NotifyAction(Item, glAdded);
end;

procedure TEvsGraphObjectList.Insert(Index: integer; Item: TEvsGraphObject);
begin
  if (Index < 0) or (Index > fCount) then
    raise EListError.CreateFmt(SListIndexError, [Index]);
  if Count = Capacity then
    Grow;
  if Index < fCount then
    System.Move(fItems[Index], fItems[Index + 1], (fCount - Index) *
      SizeOf(TEvsGraphObject));
  fItems[Index] := Item;
  Inc(fCount);
  NotifyAction(Item, glAdded);
end;

procedure TEvsGraphObjectList.Delete(Index: integer);
var
  Item: TEvsGraphObject;
  I: integer;
begin
  if (Index < 0) or (Index >= fCount) then
    raise EListError.CreateFmt(SListIndexError, [Index]);
  Item := fItems[Index];
  Dec(fCount);
  if Index < fCount then
    System.Move(fItems[Index + 1], fItems[Index], (fCount - Index) *
      SizeOf(TEvsGraphObject));
  AdjustDeleted(Index, Enum);
  for I := 0 to EnumStackPos - 1 do
    AdjustDeleted(Index, EnumStack[I]);
  NotifyAction(Item, glRemoved);
end;

function TEvsGraphObjectList.Remove(Item: TEvsGraphObject): integer;
begin
  Result := IndexOf(Item);
  if Result >= 0 then
    Delete(Result);
end;

procedure TEvsGraphObjectList.Move(CurIndex, NewIndex: integer);
var
  Item: TEvsGraphObject;
begin
  if CurIndex <> NewIndex then
  begin
    if (CurIndex < 0) or (CurIndex >= fCount) then
      raise EListError.CreateFmt(SListIndexError, [CurIndex]);
    if (NewIndex < 0) or (NewIndex >= fCount) then
      raise EListError.CreateFmt(SListIndexError, [NewIndex]);
    Item := fItems[CurIndex];
    fItems[CurIndex] := nil;
    Delete(CurIndex);
    Insert(NewIndex, nil);
    fItems[NewIndex] := Item;
    NotifyAction(Item, glReordered);
  end;
end;

function TEvsGraphObjectList.First: TEvsGraphObject;
begin
  if fCount > 0 then
  begin
    Enum.Dir := +1;
    Enum.Current := 0;
    Result := fItems[0];
  end
  else
  begin
    Enum.Dir := 0;
    Result := nil;
  end;
end;

function TEvsGraphObjectList.Prior: TEvsGraphObject;
begin
  Dec(Enum.Current);
  if (Enum.Current >= 0) and (Enum.Current < fCount) then
    Result := fItems[Enum.Current]
  else if Enum.Dir <> 0 then
  begin
    Enum.Dir := 0;
    Result := nil;
  end
  else
    raise EListError.Create(SListEnumerateError);
end;

function TEvsGraphObjectList.Next: TEvsGraphObject;
begin
  Inc(Enum.Current);
  if (Enum.Current >= 0) and (Enum.Current < fCount) then
    Result := fItems[Enum.Current]
  else if Enum.Dir <> 0 then
  begin
    Enum.Dir := 0;
    Result := nil;
  end
  else
    raise EListError.Create(SListEnumerateError);
end;

function TEvsGraphObjectList.Last: TEvsGraphObject;
begin
  if fCount > 0 then
  begin
    Enum.Dir := -1;
    Enum.Current := fCount - 1;
    Result := fItems[fCount - 1];
  end
  else
  begin
    Enum.Dir := 0;
    Result := nil;
  end;
end;

function TEvsGraphObjectList.Push: boolean;
begin
  Result := False;
  if Enum.Dir <> 0 then
  begin
    if EnumStackPos = Length(EnumStack) then
      SetLength(EnumStack, EnumStackPos + 1);
    EnumStack[EnumStackPos] := Enum;
    Inc(EnumStackPos);
    Result := True;
  end;
end;

function TEvsGraphObjectList.Pop: boolean;
begin
  Result := False;
  if EnumStackPos > 0 then
  begin
    Dec(EnumStackPos);
    Enum := EnumStack[EnumStackPos];
    Result := True;
  end;
end;

{$ENDREGION}

{$REGION ' TEvsGraphObject '}
{ TEvsGraphObject }

constructor TEvsGraphObject.CreateAsReplacement(AGraphObject: TEvsGraphObject);
var
  I: integer;
  Stream: TMemoryStream;
begin
  Include(AGraphObject.fStates, osConverting);
  Include(fStates, osConverting);
  Create(AGraphObject.Owner);
  Stream := TMemoryStream.Create;
  try
    AGraphObject.SaveToStream(Stream);
    Stream.Seek(0, soFromBeginning);
    LoadFromStream(Stream);
  finally
    Stream.Free;
  end;
  Data := AGraphObject.Data;
  LinkInputList.Assign(AGraphObject.LinkInputList);
  LinkOutputList.Assign(AGraphObject.LinkOutputList);
  DependentList.Assign(AGraphObject.DependentList);
  Owner.Objects.Replace(AGraphObject, Self);
  Owner.SelectedObjects.Replace(AGraphObject, Self);
  for I := Owner.Objects.Count - 1 downto 0 do
    Owner.Objects[I].ReplaceObject(AGraphObject, Self);
end;

constructor TEvsGraphObject.CreateFromStream(AOwner: TEvsSimpleGraph; AStream: TStream);
begin
  Include(fStates, osLoading);
  Create(AOwner);
  LoadFromStream(AStream);
end;

constructor TEvsGraphObject.Create(AOwner: TEvsSimpleGraph);
begin
  Include(fStates, osCreating);
  fOwner := AOwner;
  fVisible := True;
  fParentFont := True;
  fFont := TFont.Create;
  fFont.Assign(Owner.Font);
  fFont.OnChange := @StyleChanged;
  fBrush := TBrush.Create;
  fBrush.OnChange := @StyleChanged;
  fPen := TPen.Create;
  fPen.OnChange := @StyleChanged;
  fDependentList := TEvsGraphObjectList.Create;
  fDependentList.OnChange := @ListChanged;
  fLinkInputList := TEvsGraphObjectList.Create;
  fLinkInputList.OnChange := @ListChanged;
  fLinkOutputList := TEvsGraphObjectList.Create;
  fLinkOutputList.OnChange := @ListChanged;
  fOptions := [goLinkable, goSelectable, goShowCaption];
  fVisualRectFlags := [gcPlacement];
  //Layer := AOwner.ActiveLayer; //JKOZ:layers
  //AOwner.ActiveLayer.Add(Self); //JKOZ:layers not in alyer yet no need to call setlayer;
end;

destructor TEvsGraphObject.Destroy;
begin
  fPen.Free;
  fBrush.Free;
  fFont.Free;
  fLinkInputList.Free;
  fLinkOutputList.Free;
  fDependentList.Free;
  inherited Destroy;
end;

procedure TEvsGraphObject.AfterConstruction;
begin
  inherited AfterConstruction;
  if osConverting in States then
  begin
    Exclude(fStates, osConverting);
    Exclude(fStates, osCreating);
    Initialize;
    Changed([gcView, gcData, gcPlacement]);
  end
  else
  begin
    if not (osLoading in States) then
    begin
      fID := Owner.CreateUniqueID(Self);
      Owner.DoObjectInitInstance(Self);
    end;
    Exclude(fStates, osCreating);
    Initialize;
    Owner.Objects.Add(Self);
  end;
end;

procedure TEvsGraphObject.BeforeDestruction;
begin
  if not (osDestroying in States) then
  begin
    Include(fStates, osDestroying);
    if not (osConverting in States) then
    begin
      Owner.Objects.Remove(Self);
      NotifyDependents(gdcRemoved);
    end;
  end;
  inherited BeforeDestruction;
end;

function TEvsGraphObject.GetOwner: TPersistent;
begin
  Result := Owner;
end;

procedure TEvsGraphObject.Initialize;
begin
  if not (osLoading in States) then
    LookupDependencies;
  UpdateTextPlacement(True, 0, 0);
  QueryVisualRect(fVisualRect);
  NotifyDependents(gdcChanged);
end;

procedure TEvsGraphObject.Loaded;
begin
  Exclude(fStates, osLoading);
  LookupDependencies;
end;

procedure TEvsGraphObject.ReplaceID(OldID, NewID: DWORD);
begin
  if ID = OldID then
    fID := NewID;
end;

procedure TEvsGraphObject.ReplaceObject(OldObject, NewObject: TEvsGraphObject);
begin
  repeat
  until DependentList.Replace(OldObject, NewObject) < 0;
  repeat
  until LinkInputList.Replace(OldObject, NewObject) < 0;
  repeat
  until LinkOutputList.Replace(OldObject, NewObject) < 0;
end;

procedure TEvsGraphObject.UpdateDependencyTo(GraphObject: TEvsGraphObject;
  Flag: TEvsGraphDependencyChangeFlag);
begin
end;

procedure TEvsGraphObject.LookupDependencies;
begin
end;

procedure TEvsGraphObject.UpdateDependencies;
begin
end;

procedure TEvsGraphObject.NotifyDependents(Flag: TEvsGraphDependencyChangeFlag);
var
  DependentObject: TEvsGraphObject;
begin
  DependentObject := DependentList.First;
  while Assigned(DependentObject) do
  begin
    DependentList.Push;
    try
      DependentObject.UpdateDependencyTo(Self, Flag);
    finally
      DependentList.Pop;
    end;
    DependentObject := DependentList.Next;
  end;
end;

function TEvsGraphObject.UpdateTextPlacement(Recalc: boolean; dX, dY: integer): boolean;
begin
  Result := False;
end;

procedure TEvsGraphObject.Changed(Flags: TEvsGraphChangeFlags);
var
  NewVisualRect: TRect;
begin
  if not IsUpdateLocked then
  begin
    if gcDependency in Flags then
      UpdateDependencies;
    if (gcText in Flags) and ((Text <> '') or (TextToShow <> '')) then
      UpdateTextPlacement(True, 0, 0);
    if gcPlacement in Flags then
      NotifyDependents(gdcChanged);
    if (gcView in Flags) and ((Flags * VisualRectFlags) <> []) then
    begin
      QueryVisualRect(NewVisualRect);
      if not EqualRect(NewVisualRect, VisualRect) then
      begin
        Include(Flags, gcPlacement);
        if gcView in Flags then
          Invalidate;
        fVisualRect := NewVisualRect;
      end;
    end;
    if (gcData in Flags) or (gcPlacement in Flags) then
      Owner.DoObjectChange(Self);
    Owner.ObjectChanged(Self, Flags);
  end
  else
    PendingChanges := PendingChanges + Flags;
end;

procedure TEvsGraphObject.BoundsChanged(dX, dY, dCX, dCY: integer);
var
  Shifted: boolean;
  SavedVisualRectFlags: TEvsGraphChangeFlags;
begin
  Shifted := (dCX = 0) and (dCY = 0);
  if Text <> '' then
    UpdateTextPlacement(not Shifted, dX, dY);
  SavedVisualRectFlags := VisualRectFlags;
  try
    if Shifted then
    begin
      Invalidate;
      OffsetRect(fVisualRect, dX, dY);
      VisualRectFlags := VisualRectFlags - [gcData, gcPlacement];
    end;
    Changed([gcView, gcData, gcPlacement]);
  finally
    VisualRectFlags := SavedVisualRectFlags;
  end;
end;

procedure TEvsGraphObject.DependentChanged(GraphObject: TEvsGraphObject;
  Action: TEvsGraphObjectListAction);
begin
end;

procedure TEvsGraphObject.LinkInputChanged(GraphObject: TEvsGraphObject;
  Action: TEvsGraphObjectListAction);
begin
  case Action of
    glAdded: DependentList.Add(GraphObject);
    glRemoved: DependentList.Remove(GraphObject);
  end;
end;

procedure TEvsGraphObject.LinkOutputChanged(GraphObject: TEvsGraphObject;
  Action: TEvsGraphObjectListAction);
begin
  case Action of
    glAdded: DependentList.Add(GraphObject);
    glRemoved: DependentList.Remove(GraphObject);
  end;
end;

procedure TEvsGraphObject.ParentFontChanged;
begin
  if ParentFont then
  begin
    Font.OnChange := nil;
    try
      Font.Assign(Owner.Font);
    finally
      Font.OnChange := @StyleChanged;
    end;
    Changed([gcView, gcText]);
  end;
end;

function TEvsGraphObject.QueryCursor(HT: DWORD): TCursor;
begin
  Result := Owner.Cursor;
end;

function TEvsGraphObject.QueryMobility(HT: DWORD): TEvsObjectSides;
begin
  Result := [];
end;

function TEvsGraphObject.QueryHitTest(const aPoint : TPoint) : DWORD;
begin
  Result := GHT_NOWHERE;
end;

function TEvsGraphObject.OffsetHitTest(HT: DWORD; dX, dY: integer): boolean;
begin
 Result := False;
end;

procedure TEvsGraphObject.SnapHitTestOffset(HT: DWORD; var dX, dY: integer);
begin
end;

procedure TEvsGraphObject.MouseDown(Button: TMouseButton; Shift: TShiftState;
  const Pt: TPoint);
var
  HT: DWORD;
begin
  if Dragging then
    EndDrag(True);
  if Selected and (ssShift in Shift) then
    Selected := False
  else if not Selected and (goSelectable in Options) then
  begin
    if not (ssShift in Shift) then
      Owner.SelectedObjects.Clear;
    Selected := True;
  end;
  HT := HitTest(Pt);
  if (Button = mbLeft) and not (ssDouble in Shift) and Selected and not IsLocked then
    BeginDrag(Pt, HT);
  Screen.Cursor := QueryCursor(HT);
end;

procedure TEvsGraphObject.MouseMove(Shift: TShiftState; const Pt: TPoint);
begin
  if Dragging then
    DragTo(Pt, Owner.SnapToGrid xor (ssCtrl in Shift))
  else
    Screen.Cursor := QueryCursor(HitTest(Pt));
end;

procedure TEvsGraphObject.MouseUp(Button: TMouseButton; Shift: TShiftState;
  const Pt: TPoint);
begin
  if Dragging then
  begin
    EndDrag(True);
    Screen.Cursor := QueryCursor(HitTest(Pt));
  end;
end;

function TEvsGraphObject.KeyPress(var Key: word; Shift: TShiftState): boolean;
var
  dX, dY: integer;
  Mobility: TEvsObjectSides;
  HT: DWORD;
begin
  Result := False;
  dX := 0;
  dY := 0;
  case Key of
    VK_ESCAPE:
    begin
      if Dragging then
      begin
        Result := True;
        EndDrag(False);
      end;
    end;
    VK_LEFT:
      if (Shift - [ssCtrl]) <= [ssShift] then
        dX := -1;
    VK_RIGHT:
      if (Shift - [ssCtrl]) <= [ssShift] then
        dX := +1;
    VK_UP:
      if (Shift - [ssCtrl]) <= [ssShift] then
        dY := -1;
    VK_DOWN:
      if (Shift - [ssCtrl]) <= [ssShift] then
        dY := +1;
  end;
  if (dX <> 0) or (dY <> 0) then
  begin
    if Owner.SnapToGrid xor (ssCtrl in Shift) then
    begin
      dX := dX * Owner.GridSize;
      dY := dY * Owner.GridSize;
    end;
    if ssShift in Shift then
    begin
      Mobility := [osRight, osBottom];
      HT := GHT_BOTTOMRIGHT;
    end
    else
    begin
      Mobility := [osLeft, osTop, osRight, osBottom];
      HT := GHT_CLIENT;
    end;
    if Owner.GraphConstraints.ConfineOffset(dX, dY, Mobility) then
      OffsetHitTest(HT, dX, dY);
    Result := True;
  end;
end;

function TEvsGraphObject.BeginDrag(const Pt: TPoint; HT: DWORD): boolean;
begin
  Result := False;
  if not (osDragDisabled in States) and (not Assigned(Owner.DragSource) or
    (Owner.DragSource = Self)) then
  begin
    if HT = $FFFFFFFF then
      HT := HitTest(Pt);
    if Owner.BeginDragObject(Self, Pt, HT) then
    begin
      Include(fStates, osDragging);
      Changed([gcView]);
      Result := True;
    end;
  end;
end;

function TEvsGraphObject.DragTo(const Pt: TPoint; SnapToGrid: boolean): boolean;
begin
  with Owner.DragTargetPt do
    Result := DragBy(Pt.X - X, Pt.Y - Y, SnapToGrid);
end;

function TEvsGraphObject.DragBy(dX, dY: integer; SnapToGrid: boolean): boolean;
begin
  Result := False;
  if Owner.DragSource = Self then
  begin
    if (dX <> 0) or (dY <> 0) then
    begin
      if SnapToGrid then
        SnapHitTestOffset(Owner.DragHitTest, dX, dY);
      Owner.PerformDragBy(dX, dY);
    end;
    Result := True;
  end;
end;

function TEvsGraphObject.EndDrag(Accept: boolean): boolean;
begin
  Result := False;
  if Owner.DragSource = Self then
  begin
    Exclude(fStates, osDragging);
    Changed([gcView]);
    Owner.EndDragObject(Accept);
    Result := True;
  end;
end;

function TEvsGraphObject.BeginFollowDrag(HT: DWORD): boolean;
begin
  Result := False;
  if not (osDragDisabled in States) or IsLocked then
  begin
    Include(fStates, osDragging);
    Changed([gcView]);
    Result := True;
  end;
end;

function TEvsGraphObject.EndFollowDrag: boolean;
begin
  Result := False;
  if Dragging then
  begin
    Exclude(fStates, osDragging);
    Changed([gcView]);
    Result := True;
  end;
end;

procedure TEvsGraphObject.DisableDrag;
begin
  if DragDisableCount = 0 then
    Include(fStates, osDragDisabled);
  Inc(DragDisableCount);
end;

procedure TEvsGraphObject.EnableDrag;
begin
  Dec(DragDisableCount);
  if DragDisableCount = 0 then
    Exclude(fStates, osDragDisabled);
end;

function TEvsGraphObject.IsFontStored: boolean;
begin
  Result := not ParentFont;
end;

procedure TEvsGraphObject.SetFont(Value: TFont);
begin
  Font.Assign(Value);
end;

procedure TEvsGraphObject.SetParentFont(Value: boolean);
begin
  if ParentFont <> Value then
  begin
    fParentFont := Value;
    if ParentFont then
    begin
      Font.OnChange := nil;
      try
        Font.Assign(Owner.Font);
      finally
        Font.OnChange := @StyleChanged;
      end;
      Changed([gcView, gcData, gcText]);
    end
    else
      Changed([gcData]);
  end;
end;

procedure TEvsGraphObject.SetOptions(Value: TEvsGraphObjectOptions);
begin
  if Options <> Value then
  begin
    fOptions := Value;
    Changed([gcView, gcData]);
  end;
end;

procedure TEvsGraphObject.SetHasCustomData(Value: boolean);
begin
  if HasCustomData <> Value then
  begin
    fHasCustomData := Value;
    Changed([gcData]);
  end;
end;

procedure TEvsGraphObject.SetBrush(Value: TBrush);
begin
  Brush.Assign(Value);
end;

procedure TEvsGraphObject.SetLayer(aValue :TEvsGraphLayer);
var
  vLayer : TEvsGraphLayer;
  vOld   : Integer;
begin
  vLayer := GetLayer;
  vOld := ZOrder;
  aValue.Add(Self);
  if Assigned(vLayer) then vLayer.Remove(vOld, ZOrder);
end;

function TEvsGraphObject.GetOwnerZoomFactor : Double;
begin
  Result := Owner.FZoomFactor;
end;

function TEvsGraphObject.GetLayer :TEvsGraphLayer;
begin
  Result := Owner.LayerByOrder(ZOrder);
end;

procedure TEvsGraphObject.SetPen(Value: TPen);
begin
  Pen.Assign(Value);
end;

procedure TEvsGraphObject.SetText(const Value: string);
begin
  if Text <> Value then
  begin
    fText := Value;
    Changed([gcView, gcData, gcText]);
  end;
end;

procedure TEvsGraphObject.SetHint(const Value: string);
begin
  if Hint <> Value then
  begin
    fHint := Value;
    Changed([gcData]);
  end;
end;

function TEvsGraphObject.GetZOrder: integer;
begin
  Result := Owner.Objects.IndexOf(Self);
end;

procedure TEvsGraphObject.SetZOrder(Value: integer);
begin
  if (Value < 0) or (Value >= Owner.Objects.Count) then
    Value := Owner.Objects.Count - 1;
  Owner.Objects.Move(ZOrder, Value);
end;

procedure TEvsGraphObject.SetSelected(Value: boolean);
begin
  if not (goSelectable in Options) then
    Value := False;
  if Selected <> Value then
  begin
    fSelected := Value;
    if Selected then
      Owner.SelectedObjects.Add(Self)
    else
      Owner.SelectedObjects.Remove(Self);
    Changed([gcView]);
  end;
end;

procedure TEvsGraphObject.SetVisible(Value: boolean);
begin
  if Visible <> Value then
  begin
    fVisible := Value;
    Changed([gcView, gcData]);
  end;
end;

procedure TEvsGraphObject.StyleChanged(Sender: TObject);
begin
  if Sender = Font then
  begin
    fParentFont := False;
    Changed([gcView, gcData, gcText]);
  end
  else if Sender = Pen then
    Changed([gcView, gcData, gcText, gcPlacement])
  else
    Changed([gcView, gcData]);
end;

procedure TEvsGraphObject.ListChanged(Sender: TObject; GraphObject: TEvsGraphObject;
  Action: TEvsGraphObjectListAction);
begin
  if Sender = DependentList then
    DependentChanged(GraphObject, Action)
  else if Sender = LinkInputList then
    LinkInputChanged(GraphObject, Action)
  else if Sender = LinkOutputList then
    LinkOutputChanged(GraphObject, Action);
end;

function TEvsGraphObject.GetSelectedVisualRect: TRect;
var
  D: integer;
begin
  Result := VisualRect;
  D := Owner.MarkerSize - Pen.Width div 2;
  if D > 0 then
    InflateRect(Result, D, D);
end;

function TEvsGraphObject.GetShowing: boolean;
begin
  Result := (Visible or Owner.ShowHiddenObjects) and not (osDestroying in States);
end;

function TEvsGraphObject.GetDragging: boolean;
begin
  Result := osDragging in States;
end;

function TEvsGraphObject.GetDependents(Index: integer): TEvsGraphObject;
begin
  Result := DependentList[Index];
end;

function TEvsGraphObject.GetDependentCount: integer;
begin
  Result := DependentList.Count;
end;

function TEvsGraphObject.GetLinkInputs(Index: integer): TEvsGraphLink;
begin
  Result := TEvsGraphLink(LinkInputList[Index]);
end;

function TEvsGraphObject.GetLinkInputCount: integer;
begin
  Result := LinkInputList.Count;
end;

function TEvsGraphObject.GetLinkOutputs(Index: integer): TEvsGraphLink;
begin
  Result := TEvsGraphLink(LinkOutputList[Index]);
end;

function TEvsGraphObject.GetLinkOutputCount: integer;
begin
  Result := LinkOutputList.Count;
end;

class function TEvsGraphObject.IsLink: boolean;
begin
  Result := False;
end;

class function TEvsGraphObject.IsNode: boolean;
begin
  Result := not IsLink;
end;

function TEvsGraphObject.IsLocked: boolean;
begin
  if IsLink then
    Result := Owner.LockLinks
  else if IsNode then
    Result := Owner.LockNodes
  else
    Result := False;
end;

function TEvsGraphObject.IsVisibleOn(aCanvas : TCanvas) : boolean;
Var
  vDCRect:TRect;
begin
  if Showing then begin
    {$MESSAGE HINT 'METAFILE SUPPORT OMMITED'}
    if not Owner.Printing then begin
    //if not (aCanvas is TMetafileCanvas) then  // Windows.RectVisible bug!!!
       vDCRect := SelectedVisualRect;
       owner.GPToCP(vDCRect,2);      {$MESSAGE HINT 'GPtoCP needs attention'}
       Result := RectVisible(aCanvas.Handle, vDCRect)
    end else
      Result := True
  end else
    Result := False;
end;

function TEvsGraphObject.IsUpdateLocked: boolean;
begin
  Result := (States * [osCreating, osDestroying, osReading, osUpdating]) <> [];
end;

function TEvsGraphObject.NeighborhoodRadius: integer;
begin
  Result := Pen.Width div 2;
  if Result < Owner.MarkerSize then
    Result := Owner.MarkerSize;
end;

procedure TEvsGraphObject.BringToFront;
begin
  ZOrder := MaxInt;
end;

procedure TEvsGraphObject.SendToBack;
begin
  ZOrder := 0;
end;

function TEvsGraphObject.Delete: boolean;
begin
  Result := False;
  if (Self <> nil) and CanDelete then
  begin
    Destroy;
    Result := True;
  end;
end;

function TEvsGraphObject.CanDelete: boolean;
begin
  Result := True;
  Owner.DoCanRemoveObject(Self, Result);
end;

function TEvsGraphObject.HitTest(const Pt: TPoint): DWORD;
var
  vPoint :TPoint;
begin
  Result := GHT_NOWHERE;
  vPoint := Pt;
  if Showing and ((Selected and PtInRect(SelectedVisualRect, vPoint)) or
    (not Selected and PtInRect(VisualRect, vPoint))) then
  begin
    Result := QueryHitTest(Pt);
    if (Result <> GHT_NOWHERE) and not (goSelectable in Options) then
      Result := GHT_TRANSPARENT;
  end;
end;

function TEvsGraphObject.ContainsPoint(X, Y: integer): boolean;
begin
  Result := (HitTest(Types.Point(X, Y)) <> GHT_NOWHERE);
end;

function TEvsGraphObject.ContainsRect(const Rect: TRect): boolean;
begin
  if Showing then
    if Selected then
      Result := OverlappedRect(Rect, SelectedVisualRect)
    else
      Result := OverlappedRect(Rect, VisualRect)
  else
    Result := False;
end;

procedure TEvsGraphObject.Assign(Source: TPersistent);
begin
  if Source is TEvsGraphObject then
  begin
    BeginUpdate;
    try
      Text := TEvsGraphObject(Source).Text;
      Hint := TEvsGraphObject(Source).Hint;
      Brush := TEvsGraphObject(Source).Brush;
      Pen := TEvsGraphObject(Source).Pen;
      Font := TEvsGraphObject(Source).Font;
      ParentFont := TEvsGraphObject(Source).ParentFont;
      Visible := TEvsGraphObject(Source).Visible;
      Options := TEvsGraphObject(Source).Options;
    finally
      EndUpdate;
    end;
  end
  else
    inherited Assign(Source);
end;

procedure TEvsGraphObject.AssignTo(Dest: TPersistent);
begin
  if Dest is TEvsGraphObject then
    Dest.Assign(Self)
  else
    inherited AssignTo(Dest);
end;

procedure TEvsGraphObject.DrawControlPoint(aCanvas : TCanvas;
  const aPoint : TPoint; Enabled : boolean);
var
  R: TRect;
begin
  R := MakeSquare(aPoint, Owner.MarkerSize);
  aCanvas.Rectangle(R.Left, R.Top, R.Right, R.Bottom);
  if not Enabled then
  begin
    InflateRect(R, -2, -2);
    aCanvas.Rectangle(R.Left, R.Top, R.Right, R.Bottom);
  end;
end;

procedure TEvsGraphObject.Draw(aCanvas : TCanvas);
begin
  if IsVisibleOn(aCanvas) then
  begin
    aCanvas.Brush := Brush;
    aCanvas.Pen := Pen;
    aCanvas.Font := Font;
    Owner.DoObjectBeforeDraw(aCanvas, Self);
    DrawBody(aCanvas);
    if goShowCaption in Options then
      DrawText(aCanvas);
    Owner.DoObjectAfterDraw(aCanvas, Self);
  end;
end;

procedure TEvsGraphObject.DrawState(aCanvas : TCanvas);
begin
  if IsVisibleOn(aCanvas) then
  begin
    if Dragging then
    begin
      aCanvas.Brush.Style := bsClear;
      aCanvas.Pen.Mode := pmNot;
      aCanvas.Pen.Style := psSolid;
      if Pen.Width >= 2 then
        aCanvas.Pen.Width := (Pen.Width - 1) div 2
      else
        aCanvas.Pen.Width := Pen.Width + 2;
      DrawHighlight(aCanvas);
    end
    else if Selected then
    begin
      aCanvas.Pen.Width := 1;
      aCanvas.Pen.Mode := pmCopy;
      aCanvas.Pen.Style := psInsideFrame;
      aCanvas.Pen.Color := Owner.MarkerColor;
      aCanvas.Brush.Style := bsSolid;
      aCanvas.Brush.Color := Owner.Color;
      DrawControlPoints(aCanvas);
    end;
  end;
end;

function TEvsGraphObject.ConvertTo(AnotherClass: TEvsGraphObjectClass): TEvsGraphObject;
begin
  Result := Self;
  if Assigned(AnotherClass) and (ClassType <> AnotherClass) and
    ((IsLink and AnotherClass.IsLink) or (IsNode and AnotherClass.IsNode)) then
  begin
    Result := AnotherClass.CreateAsReplacement(Self);
    Self.Free;
  end;
end;

procedure TEvsGraphObject.LoadFromStream(Stream: TStream);
var
  Streamable: TEvsGraphStreamableObject;
begin
  BeginUpdate;
  try
    Include(fStates, osReading);
    try
      Streamable := TEvsGraphStreamableObject.Create(nil);
      try
        Streamable.G := Self;
        Stream.ReadComponent(Streamable);
        Self.fID := Streamable.ID;
      finally
        Streamable.Free;
      end;
    finally
      Exclude(fStates, osReading);
    end;
    if not (osCreating in States) then
      Initialize;
  finally
    EndUpdate;
  end;
end;

procedure TEvsGraphObject.SaveToStream(Stream: TStream);
var
  Streamable: TEvsGraphStreamableObject;
begin
  Include(fStates, osWriting);
  try
    Streamable := TEvsGraphStreamableObject.Create(nil);
    try
      Streamable.G := Self;
      Streamable.ID := Self.ID;
      Stream.WriteComponent(Streamable);
    finally
      Streamable.Free;
    end;
  finally
    Exclude(fStates, osWriting);
  end;
end;

procedure TEvsGraphObject.BeginUpdate;
begin
  if UpdateCount = 0 then
  begin
    Include(fStates, osUpdating);
    PendingChanges := [];
  end;
  Inc(UpdateCount);
end;

procedure TEvsGraphObject.EndUpdate;
begin
  Dec(UpdateCount);
  if UpdateCount = 0 then
  begin
    Exclude(fStates, osUpdating);
    if PendingChanges <> [] then
      Changed(PendingChanges);
  end;
end;

procedure TEvsGraphObject.Invalidate;
begin
  Owner.InvalidateRect(SelectedVisualRect);
end;

procedure TEvsGraphObject.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);
  Filer.DefineBinaryProperty('CustomData', @ReadCustomData, @WriteCustomData,
    HasCustomData);
end;

procedure TEvsGraphObject.ReadCustomData(Stream: TStream);
var
  TmpStream: TMemoryStream;
  CustomDataSize: integer;
begin
  Stream.Read(CustomDataSize, SizeOf(CustomDataSize));
  if CustomDataSize > 0 then
  begin
    TmpStream := TMemoryStream.Create;
    try
      TmpStream.CopyFrom(Stream, CustomDataSize);
      TmpStream.Seek(0, soFromBeginning);
      Owner.DoObjectRead(Self, TmpStream);
    finally
      TmpStream.Free;
    end;
  end;
end;

procedure TEvsGraphObject.WriteCustomData(Stream: TStream);
var
  TmpStream: TMemoryStream;
  CustomDataSize: integer;
begin
  TmpStream := TMemoryStream.Create;
  try
    Owner.DoObjectWrite(Self, TmpStream);
    CustomDataSize := TmpStream.Size;
    Stream.Write(CustomDataSize, SizeOf(CustomDataSize));
    if CustomDataSize > 0 then
    begin
      TmpStream.Seek(0, soFromBeginning);
      Stream.CopyFrom(TmpStream, CustomDataSize);
    end;
  finally
    TmpStream.Free;
  end;
end;

{$ENDREGION}

{$REGION ' TEvsGraphLink '}

constructor TEvsGraphLink.Create(AOwner: TEvsSimpleGraph);
begin
  inherited Create(AOwner);
  fTextPosition := -1;
  fTextSpacing := 0;
  fLinkOptions := [];
  fBeginStyle := lsNone;
  fBeginSize := 6;
  fEndStyle := lsArrow;
  fEndSize := 6;
  fMovingPoint := -1;
  VisualRectFlags := VisualRectFlags + [gcText];
end;

constructor TEvsGraphLink.CreateNew(AOwner: TEvsSimpleGraph; ASource: TEvsGraphObject;
  const Pts: array of TPoint; ATarget: TEvsGraphObject);
var
  I: integer;
begin
  Create(AOwner);
  if Assigned(ASource) then
    AddPoint(ASource.FixHookAnchor);
  for I := Low(Pts) to High(Pts) do
    AddPoint(Pts[I]);
  if Assigned(ATarget) then
    AddPoint(ATarget.FixHookAnchor);
  if Assigned(ASource) and Assigned(ATarget) then
    Link(ASource, ATarget)
  else if Assigned(ASource) then
    Hook(0, ASource)
  else if Assigned(ATarget) then
    Hook(PointCount - 1, ATarget);
  if (Source <> ASource) or (Target <> ATarget) then
    raise EEvsGraphInvalidOperation.Create(SLinkCreateError);
end;

destructor TEvsGraphLink.Destroy;
begin
  if TextRegion <> 0 then
    DeleteObject(TextRegion);
  SetLength(fPoints, 0);
  inherited Destroy;
end;

procedure TEvsGraphLink.Assign(Source: TPersistent);
begin
  BeginUpdate;
  try
    inherited Assign(Source);
    if Source is TEvsGraphLink then
    begin
      Polyline := TEvsGraphLink(Source).Polyline;
      BeginStyle := TEvsGraphLink(Source).BeginStyle;
      BeginSize := TEvsGraphLink(Source).BeginSize;
      EndStyle := TEvsGraphLink(Source).EndStyle;
      EndSize := TEvsGraphLink(Source).EndSize;
      LinkOptions := TEvsGraphLink(Source).LinkOptions;
      TextPosition := TEvsGraphLink(Source).TextPosition;
      TextSpacing := TEvsGraphLink(Source).TextSpacing;
      if Assigned(TEvsGraphLink(Source).Source) and Assigned(TEvsGraphLink(Source).Target) then
        Link(TEvsGraphLink(Source).Source, TEvsGraphLink(Source).Target)
      else
      begin
        Source := TEvsGraphLink(Source).Source;
        Target := TEvsGraphLink(Source).Target;
      end;
    end;
  finally
    EndUpdate;
  end;
end;

function TEvsGraphLink.ContainsRect(const Rect: TRect): boolean;

  function ContainsEdge(const Pt: TPoint; const Angle: double): boolean;
  var
    Intersects: TPoints;
    I: integer;
  begin
    Result := False;
    Intersects := IntersectLinePolyline(Pt, Angle, Polyline);
    try
      for I := 0 to Length(Intersects) - 1 do
        if PtInRect(Rect, Intersects[I]) then
        begin
          Result := True;
          Break;
        end;
    finally
      SetLength(Intersects, 0);
    end;
  end;

var
  I: integer;
begin
  if inherited ContainsRect(Rect) then
  begin
    if (TextRegion <> 0) and (goShowCaption in Options) and
      RectInRegion(TextRegion, Rect) then
      Result := True
    else
    begin
      for I := 0 to PointCount - 1 do
        if PtInRect(Rect, Points[I]) then
        begin
          Result := True;
          Exit;
        end;
      Result := ContainsEdge(Rect.TopLeft, 0) or
        ContainsEdge(Rect.TopLeft, Pi / 2) or
        ContainsEdge(Rect.BottomRight, 0) or
        ContainsEdge(Rect.BottomRight, Pi / 2);
    end;
  end
  else
    Result := False;
end;

function TEvsGraphLink.PointStyleOffset(Style: TEvsLinkBeginEndStyle; Size: integer): integer;
begin
  case Style of
    lsArrow, lsArrowSimple:
      Result := 2 * (Size + Pen.Width);
    lsCircle, lsDiamond:
      Result := (Size + Pen.Width + 1) div 2;
    else
      Result := 0;
  end;
end;

function TEvsGraphLink.PointStyleRect(const Pt: TPoint; const Angle: double;
  Style: TEvsLinkBeginEndStyle; Size: integer): TRect;
var
  Pts: array[1..3] of TPoint;
  M: integer;
begin
  Size := PointStyleOffset(Style, Size);
  case Style of
    lsArrow:
    begin
      Pts[1] := Pt;
      Pts[2] := NextPointOfLine(Angle + Pi / 9, Pt, Size);
      Pts[3] := NextPointOfLine(Angle - Pi / 9, Pt, Size);
      Result := BoundsRectOfPoints(Pts);
    end;
    lsArrowSimple:
    begin
      Pts[1] := NextPointOfLine(Angle + Pi / 6, Pt, Size);
      Pts[2] := Pt;
      Pts[3] := NextPointOfLine(Angle - Pi / 6, Pt, Size);
      Result := BoundsRectOfPoints(Pts);
    end;
    lsCircle, lsDiamond:
    begin
      Result := MakeSquare(Pt, Size);
    end;
    else
      Result := MakeSquare(Pt, 1);
  end;
  if Pen.Style <> psInsideFrame then
  begin
    M := (Pen.Width div 2) + 1;
    InflateRect(Result, M, M);
  end;
end;

function TEvsGraphLink.DrawPointStyle(aCanvas : TCanvas; const Pt : TPoint;
  const Angle : double; Style : TEvsLinkBeginEndStyle; Size : integer) : TPoint;
var
  Pts: array[1..4] of TPoint;
begin
  Size := PointStyleOffset(Style, Size);
  case Style of
    lsArrow:
    begin
      Pts[1] := Pt;
      Pts[2] := NextPointOfLine(Angle + Pi / 9, Pt, Size);
      Pts[3] := NextPointOfLine(Angle, Pt, MulDiv(Size, 6, 10));
      Pts[4] := NextPointOfLine(Angle - Pi / 9, Pt, Size);
      aCanvas.Polygon(Pts);
      Result := Pts[3];
    end;
    lsArrowSimple:
    begin
      Pts[1] := NextPointOfLine(Angle + Pi / 6, Pt, Size);
      Pts[2] := Pt;
      Pts[3] := NextPointOfLine(Angle - Pi / 6, Pt, Size);
      aCanvas.Polyline(Slice(Pts, 3));
      Result := Pt;
    end;
    lsCircle:
    begin
      Pts[1] := Pt;
      aCanvas.Ellipse(Pts[1].X - Size, Pts[1].Y - Size, Pts[1].X + Size, Pts[1].Y + Size);
      Result := NextPointOfLine(Angle, Pt, Size);
    end;
    lsDiamond:
    begin
      Pts[1] := NextPointOfLine(Angle, Pt, Size);
      Pts[2] := NextPointOfLine(Angle + Pi / 2, Pt, Size);
      Pts[3] := NextPointOfLine(Angle, Pt, -Size);
      Pts[4] := NextPointOfLine(Angle - Pi / 2, Pt, Size);
      aCanvas.Polygon(Pts);
      Result := Pts[1];
    end;
    else
      Result := Pt;
  end;
end;

procedure TEvsGraphLink.DrawControlPoints(aCanvas : TCanvas);
var
  I: integer;
begin
  DrawControlPoint(aCanvas, fPoints[0], not (IsLocked or
    (gloFixedStartPoint in LinkOptions)));
  for I := 1 to PointCount - 2 do
    DrawControlPoint(aCanvas, fPoints[I], not (IsLocked or (gloFixedBreakPoints in LinkOptions)));
  DrawControlPoint(aCanvas, fPoints[PointCount - 1], not
    (IsLocked or (gloFixedEndPoint in LinkOptions)));
end;

procedure TEvsGraphLink.DrawHighlight(aCanvas: TCanvas);
var
  vPtRect       : TRect;
  vFirst, vLast : integer;
  vTmp          : TPoints;
begin
  if PointCount > 1 then
  begin
    if (MovingPoint >= 0) and (MovingPoint < PointCount) then begin
      if MovingPoint > 0 then
        vFirst := MovingPoint - 1
      else
        vFirst := MovingPoint;

      if MovingPoint < PointCount - 1 then vLast := MovingPoint + 1
      else vLast := MovingPoint;

      vTmp := Copy(Polyline, vFirst, vLast - vFirst + 1);
    end else vTmp := Copy(Polyline);
    aCanvas.Polyline(vTmp);
  end
  else if PointCount = 1 then
  begin
    vPtRect := MakeSquare(Points[0], aCanvas.Pen.Width);
    aCanvas.Ellipse(vPtRect.Left, vPtRect.Top, vPtRect.Right, vPtRect.Bottom);
  end;
end;

procedure TEvsGraphLink.DrawText(aCanvas: TCanvas);
var
  vPoint, vPt : TPOINT;
  vTextStyle  : TTextStyle;
  vCnvBck     : TEvsCanvasRecall;
  vSize       : TSize;
begin
  if TextRegion <> 0 then
  begin
    vCnvBck := TEvsCanvasRecall.Create(aCanvas);
    try
      aCanvas.AntialiasingMode := amOn;
      aCanvas.Font.Quality := fqCleartypeNatural;
      aCanvas.Brush.Style := bsClear;
      vTextStyle := aCanvas.TextStyle;
      vTextStyle.Alignment := taCenter;
      vTextStyle.Layout := tlBottom;
      vTextStyle.Opaque := False;
      vTextStyle.Clipping := True;
      vTextStyle.SingleLine := False;
      vTextStyle.Wordbreak := True;
      vTextStyle.RightToLeft := Owner.UseRightToLeftReading;
      vSize := aCanvas.TextExtent(TextToShow);
      vPoint := TextCenter;
      vPt.x := vPoint.x - (vSize.cx div 2);
      vPt.y := vPoint.y - vSize.cy;
      if Abs(TextAngle) > Pi / 2 then begin
        aCanvas.Font.Orientation := Round(-1800 * (TextAngle - Pi) / Pi);
        RotatePoints(vPt, TextAngle - Pi, TextCenter);
      end
      else begin
        aCanvas.Font.Orientation := Round(-1800 * TextAngle / Pi);
        RotatePoints(vPt, TextAngle, TextCenter);
      end;
      aCanvas.TextStyle := vTextStyle;
      aCanvas.TextOut(vPt.x,vPt.y,fTextToShow);
   finally
      vCnvBck.Free;
    end;
  end;
end;

procedure TEvsGraphLink.DrawBody(Canvas: TCanvas);
  procedure CopyPoints(Var Source,Dest:TPoints);
  var
    Cntr:integer;
  begin
    SetLength(Dest,Length(Source));
    for Cntr := Low(Source) to High(Source) do
      Dest[Cntr] := Source[Cntr];
  end;

var
  OldPenStyle: TPenStyle;
  OldBrushStyle: TBrushStyle;
  ModifiedPolyline: TPoints;
  Angle: double =0.0;
  PtRect: TRect;
begin
  ModifiedPolyline := nil;
  if PointCount = 1 then
  begin
    PtRect := MakeSquare(Points[0], Pen.Width div 2);
    while not IsRectEmpty(PtRect) do
    begin
      Canvas.Ellipse(PtRect.Left, PtRect.Top, PtRect.Right, PtRect.Bottom);
      InflateRect(PtRect, -1, -1);
    end;
  end
  else if PointCount >= 2 then
  begin
    if (BeginStyle <> lsNone) or (EndStyle <> lsNone) then
    begin
      OldPenStyle := Canvas.Pen.Style;
      Canvas.Pen.Style := psSolid;
      try
        if BeginStyle <> lsNone then
        begin
          if ModifiedPolyline = nil then
            ModifiedPolyline := Copy(Polyline, 0, PointCount);
          Angle := LineSlopeAngle(fPoints[1], fPoints[0]);
          ModifiedPolyline[0] :=
            DrawPointStyle(Canvas, fPoints[0], Angle, BeginStyle, BeginSize);
        end;
        if EndStyle <> lsNone then
        begin
          if ModifiedPolyline = nil then
            ModifiedPolyline := Copy(Polyline, 0, PointCount);
          Angle := LineSlopeAngle(fPoints[PointCount - 2], fPoints[PointCount - 1]);
          ModifiedPolyline[PointCount - 1] :=
            DrawPointStyle(Canvas, fPoints[PointCount - 1], Angle, EndStyle, EndSize);

        end;
      finally
        Canvas.Pen.Style := OldPenStyle;
      end;
    end;
    OldBrushStyle := Canvas.Brush.Style;
    try
      Canvas.Brush.Style := bsClear;
      if ModifiedPolyline <> nil then begin
        Canvas.Polyline(ModifiedPolyline);
      end else
        Canvas.Polyline(Polyline);
    finally
      Canvas.Brush.Style := OldBrushStyle;
      Canvas.Pen.Style := OldPenStyle;
    end;
  end;
  ModifiedPolyline := nil;
end;

procedure TEvsGraphLink.SetBoundsRect(const Rect: TRect);
begin
  // Nothing to do
end;

function TEvsGraphLink.GetBoundsRect: TRect;
begin
  Result := BoundsRectOfPoints(Polyline);
end;

procedure TEvsGraphLink.QueryVisualRect(out Rect: TRect);
var
  TextRect: TRect;
  Margin: integer;
  Angle: double;
begin
  Rect := BoundsRect;
  Margin := (Pen.Width div 2) + 1;
  InflateRect(Rect, Margin, Margin);
  if PointCount >= 2 then
  begin
    if BeginStyle <> lsNone then
    begin
      Angle := LineSlopeAngle(fPoints[1], fPoints[0]);
      UnionRect(Rect, PointStyleRect(fPoints[0], Angle, BeginStyle, BeginSize));
    end;
    if EndStyle <> lsNone then
    begin
      Angle := LineSlopeAngle(fPoints[PointCount - 2], fPoints[PointCount - 1]);
      UnionRect(Rect, PointStyleRect(fPoints[PointCount - 1], Angle, EndStyle, EndSize));
    end;
  end;
  if (TextRegion <> 0) and (goShowCaption in Options) then
  begin
    GetRgnBox(TextRegion, @TextRect);
    UnionRect(Rect, TextRect);
  end;
end;

class function TEvsGraphLink.IsLink: boolean;
begin
  Result := True;
end;

function TEvsGraphLink.FixHookAnchor: TPoint;
var
  MidPoint: integer;
begin
  if PointCount > 0 then
  begin
    MidPoint := PointCount div 2;
    if Odd(PointCount) then
      Result := fPoints[MidPoint]
    else
      Result := CenterOfPoints([fPoints[MidPoint - 1], fPoints[MidPoint]]);
  end
  else
    Result := CenterOfRect(Owner.VisibleBounds);
end;

function TEvsGraphLink.RelativeHookAnchor(RefPt: TPoint): TPoint;

  function ValidAnchor(Index: integer): boolean;
  var
    GraphObject: TEvsGraphObject;
  begin
    GraphObject := HookedObjectOf(Index);
    Result := not Assigned(GraphObject) or GraphObject.IsLink;
  end;

var
  Pt: TPoint;
  Line: integer;
  Index: integer;
begin
  Line := IndexOfNearestLine(RefPt, MaxInt);
  if Line >= 0 then
  begin
    Pt := NearestPointOnLine(fPoints[Line], fPoints[Line + 1], RefPt);
    Index := IndexOfPoint(Pt, NeighborhoodRadius);
    if Index < 0 then
      Result := Pt
    else if ValidAnchor(Index) then
      Result := fPoints[Index]
    else
    begin
      if (Index = 0) and ValidAnchor(Index + 1) then
        Result := Points[Index + 1]
      else if (Index = PointCount - 1) and ValidAnchor(Index - 1) then
        Result := fPoints[Index - 1]
      else
        Result := FixHookAnchor;
    end;
  end
  else if PointCount = 1 then
    Result := fPoints[0]
  else
    Result := RefPt;
end;

function TEvsGraphLink.IndexOfLongestLine: integer;
var
  I: integer;
  LongestLength: double;
  Length: double;
begin
  Result := -1;
  LongestLength := -MaxInt;
  for I := 0 to PointCount - 2 do
  begin
    Length := LineLength(fPoints[I], fPoints[I + 1]);
    if Length > LongestLength then
    begin
      LongestLength := Length;
      Result := I;
    end;
  end;
end;

function TEvsGraphLink.IndexOfNearestLine(const Pt: TPoint; Neighborhood: integer): integer;
var
  I: integer;
  NearestDistance: double;
  Distance: double;
begin
  Result := -1;
  NearestDistance := MaxDouble;
  for I := 0 to PointCount - 2 do
  begin
    Distance := DistanceToLine(fPoints[I], fPoints[I + 1], Pt);
    if (Trunc(Distance) <= Neighborhood) and (Distance < NearestDistance) then
    begin
      NearestDistance := Distance;
      Result := I;
    end;
  end;
end;

function TEvsGraphLink.QueryHitTest(const Pt: TPoint): DWORD;
var
  Neighborhood: integer;
  I: integer;
begin
  Neighborhood := NeighborhoodRadius;
  for I := PointCount - 1 downto 0 do
    if PtInRect(MakeSquare(fPoints[I], Neighborhood), Pt) then
    begin
      if Selected then
        Result := GHT_POINT or (I shl 16)
      else
        Result := GHT_CLIENT;
      Exit;
    end;
  for I := 0 to PointCount - 2 do
    if DistanceToLine(fPoints[I], fPoints[I + 1], Pt) <= Neighborhood then
    begin
      if Selected then
        Result := GHT_LINE or (I shl 16) or GHT_CLIENT
      else
        Result := GHT_CLIENT;
      Exit;
    end;

  if (TextRegion <> 0) and (goShowCaption in Options) and PtInRegion(TextRegion, Pt.X, Pt.Y) then
    Result := GHT_CAPTION or GHT_CLIENT
  else
    Result := inherited QueryHitTest(Pt);
end;

procedure TEvsGraphLink.SnapHitTestOffset(HT: DWORD; var dX, dY: integer);
begin
  if (HT and GHT_POINT) <> 0 then
    Owner.SnapOffset(fPoints[HiWord(HT)], dX, dY)
  else if (HT and GHT_BODY_MASK) <> 0 then
    Owner.SnapOffset(fPoints[0], dX, dY)
  else
    inherited SnapHitTestOffset(HT, dX, dY);
end;

function TEvsGraphLink.QueryMobility(HT: DWORD): TEvsObjectSides;
begin
  if (HT and (GHT_POINT or GHT_BODY_MASK)) <> 0 then
    Result := [osLeft, osTop, osRight, osBottom]
  else
    Result := inherited QueryMobility(HT);
end;

function TEvsGraphLink.OffsetHitTest(HT: DWORD; dX, dY: integer): boolean;
var
  Index: integer;
  MovedPoints: integer;
  ShiftRef: TPoint;
begin
  Result := False;
  if (HT and GHT_POINT) <> 0 then
  begin
    Index := HiWord(HT);
    if not IsFixedPoint(Index, True) then
    begin
      with fPoints[Index] do
      begin
        Inc(X, dX);
        Inc(Y, dY);
      end;
      Changed([gcView, gcData, gcText, gcPlacement]);
      Result := True;
    end;
  end
  else if (HT and GHT_BODY_MASK) <> 0 then
  begin
    MovedPoints := 0;
    for Index := 0 to PointCount - 1 do
      if not IsFixedPoint(Index, True) then
      begin
        with fPoints[Index] do
        begin
          Inc(X, dX);
          Inc(Y, dY);
        end;
        Inc(MovedPoints);
      end;
    if MovedPoints > 0 then
    begin
      if (MovedPoints = PointCount) and not IsUpdateLocked then
        BoundsChanged(dX, dY, 0, 0)
      else
        Changed([gcView, gcData, gcText, gcPlacement]);
      Result := True;
    end;
  end
  else if (HT and GHT_SIDES_MASK) <> 0 then
  begin
    case HT of
      GHT_LEFT:
        with BoundsRect do
        begin
          ShiftRef.X := Right;
          ShiftRef.Y := (Top + Bottom) div 2;
          dX := -dX;
          dY := 0;
        end;
      GHT_TOP:
        with BoundsRect do
        begin
          ShiftRef.X := (Left + Right) div 2;
          ShiftRef.Y := Bottom;
          dX := 0;
          dY := -dY;
        end;
      GHT_RIGHT:
        with BoundsRect do
        begin
          ShiftRef.X := Left;
          ShiftRef.Y := (Top + Bottom) div 2;
          dY := 0;
        end;
      GHT_BOTTOM:
        with BoundsRect do
        begin
          ShiftRef.X := (Left + Right) div 2;
          ShiftRef.Y := Top;
          dX := 0;
        end;
      GHT_TOPLEFT:
        with BoundsRect do
        begin
          ShiftRef.X := Right;
          ShiftRef.Y := Bottom;
          dX := -dX;
          dY := -dY;
        end;
      GHT_TOPRIGHT:
        with BoundsRect do
        begin
          ShiftRef.X := Left;
          ShiftRef.Y := Bottom;
          dY := -dY;
        end;
      GHT_BOTTOMLEFT:
        with BoundsRect do
        begin
          ShiftRef.X := Right;
          ShiftRef.Y := Top;
          dX := -dX;
        end;
      GHT_BOTTOMRIGHT:
        with BoundsRect do
        begin
          ShiftRef.X := Left;
          ShiftRef.Y := Top;
        end;
    end;
    if CanMove then
    begin
      ShiftPoints(fPoints, dX, dY, ShiftRef);
      Changed([gcView, gcData, gcText, gcPlacement]);
      Result := True;
    end;
  end
  else
    inherited OffsetHitTest(HT, dX, dY);
end;

procedure TEvsGraphLink.MoveBy(dX, dY: integer);
var
  I: integer;
begin
  if (PointCount > 0) and ((dX <> 0) or (dY <> 0)) then
  begin
    for I := 0 to PointCount - 1 do
      with fPoints[I] do
      begin
        Inc(X, dX);
        Inc(Y, dY);
      end;
    if not IsUpdateLocked then
      BoundsChanged(dX, dY, 0, 0)
    else
      Changed([gcView, gcData, gcText, gcPlacement]);
  end;
end;

function TEvsGraphLink.BeginFollowDrag(HT: DWORD): boolean;
begin
  if (HT and GHT_BODY_MASK) <> 0 then
    Result := inherited BeginFollowDrag(HT)
  else
    Result := False;
end;

function TEvsGraphLink.QueryCursor(HT: DWORD): TCursor;
begin
  case LoWord(HT) and not GHT_CLIENT of
    GHT_POINT:
      case ChangeMode of
        lcmRemovePoint:
          Result := crXHair3;
        lcmMovePoint:
          if AcceptingHook then
            Result := crXHairLink
          else
            Result := crXHair2;
        else
          Result := crHandPoint;
      end;
    GHT_LINE:
      case ChangeMode of
        lcmInsertPoint:
          Result := crXHair1;
        lcmMovePolyline:
          Result := crSizeAll;
        else
          Result := crHandPoint;
      end;
    GHT_CAPTION:
      if ChangeMode = lcmMovePolyline then
        Result := crSizeAll
      else
        Result := crHandPoint;
    else
      if HT = GHT_CLIENT then
        Result := crHandPoint
      else
        Result := inherited QueryCursor(HT);
  end;
end;

procedure TEvsGraphLink.UpdateChangeMode(HT: DWORD; Shift: TShiftState);
var
  Index: integer;
begin
  ChangeMode := lcmNone;
  Index := HiWord(HT);
  case LoWord(HT) and not GHT_CLIENT of
    GHT_POINT:
      if not IsFixedPoint(Index, False) then
      begin
        if ssAlt in Shift then
          ChangeMode := lcmRemovePoint
        else
          ChangeMode := lcmMovePoint;
      end;
    GHT_LINE:
      if not (gloFixedBreakPoints in LinkOptions) then
      begin
        if ssAlt in Shift then
          ChangeMode := lcmInsertPoint
        else if not IsFixedPoint(Index, True) and not IsFixedPoint(Index + 1, True) then
          ChangeMode := lcmMovePolyline;
      end;
    GHT_CAPTION:
      if not (gloFixedBreakPoints in LinkOptions) and
        (HookedPointCount < PointCount) then
        ChangeMode := lcmMovePolyline;
  end;
end;

procedure TEvsGraphLink.MouseDown(Button: TMouseButton; Shift: TShiftState;
  const Pt: TPoint);
var
  HT: DWORD;
  Handled: boolean;
  NewPt: TPoint;
  WasDragging: boolean;
  DragDisabled: boolean;
begin
  Handled := False;
  WasDragging := False;
  if Dragging then
  begin
    WasDragging := True;
    EndDrag(True);
  end;
  DragDisabled := False;
  if WasDragging and (ssRight in Shift) and (ChangeMode = lcmMovePoint) then
  begin
    if Owner.SnapToGrid xor (ssCtrl in Shift) then
      NewPt := Owner.SnapPoint(Pt)
    else
      NewPt := Pt;
    Owner.GraphConstraints.ConfinePt(NewPt);
    if MovingPoint = 0 then
    begin
      BeginDrag(Pt, MakeLong(GHT_POINT, MovingPoint));
      InsertPoint(MovingPoint + 1, NewPt);
    end
    else
    begin
      BeginDrag(Pt, MakeLong(GHT_POINT, MovingPoint + 1));
      InsertPoint(MovingPoint, NewPt);
      Inc(fMovingPoint);
    end;
    Handled := True;
  end
  else if (Button = mbLeft) and Selected and not IsLocked then
  begin
    HT := HitTest(Pt);
    UpdateChangeMode(HT, Shift);
    case ChangeMode of
      lcmMovePoint:
      begin
        fMovingPoint := HiWord(HT);
        fHookingObject := HookedObjectOf(MovingPoint);
        fAcceptingHook := Assigned(fHookingObject);
        Unhook(fMovingPoint);
      end;
      lcmRemovePoint:
      begin
        RemovePoint(HiWord(HT));
        if PointCount = 0 then
        begin
          Free; // We don't need TSimpleGraph.OnCanRemoveObject event
          Exit;
        end;
        Handled := True;
      end;
      lcmInsertPoint:
      begin
        fMovingPoint := AddBreakPoint(Pt);
        if MovingPoint >= 0 then
          ChangeMode := lcmMovePoint
        else
          Handled := True;
      end;
      lcmMovePolyline:
        fMovingPoint := -1;
      else
        DisableDrag;
        DragDisabled := True;
    end;
    if Handled then
    begin
      if Dragging then
        EndDrag(True);
      Screen.Cursor := QueryCursor(HT);
    end;
  end;
  if not Handled then
  begin
    inherited MouseDown(Button, Shift, Pt);
    if DragDisabled then
      EnableDrag;
  end;
end;

procedure TEvsGraphLink.MouseMove(Shift: TShiftState; const Pt: TPoint);
begin
  if not Dragging and Selected and not IsLocked then
    UpdateChangeMode(HitTest(Pt), Shift)
  else if (ChangeMode = lcmMovePoint) and (MovingPoint in [0, PointCount - 1]) then
  begin
    fHookingObject := Owner.FindObjectAt(Pt.X, Pt.Y);
    if (not (ssAlt in Shift) and CanHook(MovingPoint, HookingObject)) xor
      AcceptingHook then
    begin
      fAcceptingHook := not fAcceptingHook;
      Screen.Cursor := QueryCursor(MakeLong(GHT_POINT, MovingPoint));
    end;
  end;
  inherited MouseMove(Shift, Pt);
end;

procedure TEvsGraphLink.MouseUp(Button: TMouseButton; Shift: TShiftState; const Pt: TPoint);
begin
  if not Dragging or (Button <> mbRight) or (ChangeMode <> lcmMovePoint) then
  begin
    inherited MouseUp(Button, Shift, Pt);
    if (ChangeMode = lcmMovePoint) and AcceptingHook then
      Hook(MovingPoint, HookingObject);
    fMovingPoint := -1;
    fHookingObject := nil;
    fAcceptingHook := False;
    ChangeMode := lcmNone;
  end;
end;

function TEvsGraphLink.CanHook(AIndex: integer; AGraphObject: TEvsGraphObject): boolean;
begin
  Result := False;
  if Assigned(AGraphObject) and (AGraphObject <> Self) and
    (not (AGraphObject is TEvsGraphLink) or
    (TEvsGraphLink(AGraphObject).HookedIndexOf(Self) < 0)) then
  begin
    if AIndex = 0 then
    begin
      if AGraphObject = Source then
        Result := True
      else if CheckingLink or (AGraphObject <> Target) then
      begin
        Result := goLinkable in AGraphObject.Options;
        Owner.DoCanHookLink(AGraphObject, Self, AIndex, Result);
        if Result and not CheckingLink and Assigned(Target) then
          Owner.DoCanLinkObjects(Self, AGraphObject, Target, Result);
      end;
    end
    else if AIndex >= PointCount - 1 then
    begin
      if AGraphObject = Target then
        Result := True
      else if CheckingLink or (AGraphObject <> Source) then
      begin
        Result := goLinkable in AGraphObject.Options;
        Owner.DoCanHookLink(AGraphObject, Self, AIndex, Result);
        if Result and not CheckingLink and Assigned(Source) then
          Owner.DoCanLinkObjects(Self, Source, AGraphObject, Result);
      end;
    end;
  end;
end;

function TEvsGraphLink.Hook(AIndex: integer; AGraphObject: TEvsGraphObject): boolean;
begin
  Result := False;
  if Assigned(AGraphObject) then
  begin
    if AIndex = 0 then
    begin
      if AGraphObject = Source then
        Result := True
      else if CanHook(AIndex, AGraphObject) then
      begin
        BeginUpdate;
        try
          Unhook(Source);
          if PointCount < 1 then
            InsertPoint(0, AGraphObject.FixHookAnchor);
          fSource := AGraphObject;
          SourceID := AGraphObject.ID;
          AGraphObject.LinkOutputList.Add(Self);
          Changed([gcView, gcData, gcDependency]);
        finally
          EndUpdate;
        end;
        Owner.DoObjectHook(AGraphObject, Self, AIndex);
        Result := True;
      end;
    end
    else if AIndex >= PointCount - 1 then
    begin
      if AGraphObject = Target then
        Result := True
      else if CanHook(AIndex, AGraphObject) then
      begin
        BeginUpdate;
        try
          Unhook(Target);
          if PointCount < 2 then
            AddPoint(AGraphObject.FixHookAnchor);
          fTarget := AGraphObject;
          TargetID := AGraphObject.ID;
          AGraphObject.LinkInputList.Add(Self);
          Changed([gcView, gcData, gcDependency]);
        finally
          EndUpdate;
        end;
        Owner.DoObjectHook(AGraphObject, Self, AIndex);
        Result := True;
      end;
    end;
  end;
end;

function TEvsGraphLink.Unhook(AGraphObject: TEvsGraphObject): integer;
begin
  Result := -1;
  if Assigned(AGraphObject) then
  begin
    if fSource = AGraphObject then
    begin
      fSource := nil;
      SourceID := 0;
      Result := 0;
      AGraphObject.LinkOutputList.Remove(Self);
    end;
    if fTarget = AGraphObject then
    begin
      fTarget := nil;
      TargetID := 0;
      Result := PointCount - 1;
      AGraphObject.LinkInputList.Remove(Self);
    end;
  end;
  if Result >= 0 then
  begin
    Changed([gcData]);
    Owner.DoObjectUnhook(AGraphObject, Self, Result);
  end;
end;

function TEvsGraphLink.Unhook(AIndex: integer): boolean;
begin
  Result := False;
  if AIndex = 0 then
    Result := (Unhook(Source) >= 0)
  else if AIndex = PointCount - 1 then
    Result := (Unhook(Target) >= 0);
end;

function TEvsGraphLink.CanLink(ASource, ATarget: TEvsGraphObject): boolean;
begin
  Result := False;
  CheckingLink := True;
  try
    if (ASource <> ATarget) and CanHook(0, ASource) and
      CanHook(PointCount - 1, ATarget) then
    begin
      Result := True;
      Owner.DoCanLinkObjects(Self, ASource, ATarget, Result);
    end;
  finally
    CheckingLink := False;
  end;
end;

function TEvsGraphLink.Link(ASource, ATarget: TEvsGraphObject): boolean;
begin
  Result := False;
  if CanLink(ASource, ATarget) then
  begin
    BeginUpdate;
    try
      if ASource <> Source then
      begin
        Unhook(Source);
        if PointCount < 1 then
          InsertPoint(0, ASource.FixHookAnchor);
        fSource := ASource;
        SourceID := ASource.ID;
        ASource.LinkOutputList.Add(Self);
        Changed([gcView, gcData, gcDependency]);
        Owner.DoObjectHook(ASource, Self, 0);
      end;
      if ATarget <> Target then
      begin
        Unhook(Target);
        if PointCount < 2 then
          AddPoint(ATarget.FixHookAnchor);
        fTarget := ATarget;
        TargetID := ATarget.ID;
        ATarget.LinkInputList.Add(Self);
        Changed([gcView, gcData, gcDependency]);
        Owner.DoObjectHook(ATarget, Self, PointCount - 1);
      end;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TEvsGraphLink.UpdateDependencies;
var
  OldPt: TPoint;
  Recheck: boolean;
  RecheckCount: integer;
  StartPt, EndPt: TPoint;
begin
  if not UpdatingEndPoints and (PointCount >= 2) and
    (Assigned(Source) or Assigned(Target)) then
  begin
    UpdatingEndPoints := True;
    try
      Recheck := False;
      StartPt := Points[0];
      EndPt := Points[PointCount - 1];
      if Assigned(Source) then
      begin
        if gloFixedAnchorStartPoint in LinkOptions then
          fPoints[0] := Source.FixHookAnchor
        else if not Assigned(Target) or (PointCount > 2) then
          fPoints[0] := Source.RelativeHookAnchor(fPoints[1])
        else
        begin
          fPoints[0] := Source.RelativeHookAnchor(Target.FixHookAnchor);
          if Target is TEvsGraphLink then
            Recheck := True;
        end;
      end;
      if Assigned(Target) then
      begin
        if gloFixedAnchorEndPoint in LinkOptions then
          fPoints[PointCount - 1] := Target.FixHookAnchor
        else if not Assigned(Source) or (PointCount > 2) then
          fPoints[PointCount - 1] := Target.RelativeHookAnchor(fPoints[PointCount - 2])
        else
        begin
          fPoints[PointCount - 1] := Target.RelativeHookAnchor(Source.FixHookAnchor);
          if Source is TEvsGraphLink then
            Recheck := True;
        end;
      end;
      RecheckCount := 0;
      while Recheck and (RecheckCount < 5) do
      begin
        Recheck := False;
        OldPt := fPoints[0];
        fPoints[0] := Source.RelativeHookAnchor(fPoints[1]);
        Recheck := Recheck or not EqualPoint(OldPt, fPoints[0]);
        OldPt := fPoints[PointCount - 1];
        fPoints[PointCount - 1] := Target.RelativeHookAnchor(fPoints[PointCount - 2]);
        Recheck := Recheck or not EqualPoint(OldPt, fPoints[PointCount - 1]);
        Inc(RecheckCount);
      end;
      if not EqualPoint(StartPt, Points[0]) or not EqualPoint(EndPt,
        Points[PointCount - 1]) then
        Changed([gcView, gcText, gcPlacement]);
    finally
      UpdatingEndPoints := False;
    end;
  end;
end;

function TEvsGraphLink.UpdateTextPlacement(Recalc: boolean; dX, dY: integer): boolean;
begin
  Result := False;
  if Recalc then begin
    if fTextRegion <> 0 then begin
      DeleteObject(TextRegion);
      fTextRegion := 0;
    end;
    fTextRegion := CreateTextRegion;
    Result := True;
  end else if fTextRegion <> 0 then begin
    Inc(fTextCenter.X, dX);
    Inc(fTextCenter.Y, dY);
    OffsetRgn(fTextRegion, dX, dY);
    Result := True;
  end;
end;

function TEvsGraphLink.CreateTextRegion: HRGN;
const
  cDrawTextFlags = DT_NOPREFIX or DT_END_ELLIPSIS or DT_EDITCONTROL or
    DT_MODIFYSTRING or DT_CALCRECT;
var
  vRgnPts     : array[1..4] of TPoint;
  vLineMargin : integer;
  vLineWidth  : integer;
  vTextRect   : TRect=(Left:0;Top:0;Right:0;Bottom:0);
  vTextOfs    : integer;
  vTmpText    : string;
  vCanvas     : TCanvas;
  vSize       : TSize;
begin
  Result := 0;
  TextToShow := '';
  if (Text <> '') and (PointCount >= 2) then
  begin
    fTextLine := TextPosition;
    if (fTextLine < 0) or (fTextLine >= PointCount - 1) then
    begin
      fTextLine := IndexOfLongestLine;
      if fTextLine < 0 then
        Exit;
    end;
    if fTextLine = 0 then
      vLineMargin := PointStyleOffset(BeginStyle, BeginSize)
    else if fTextLine = PointCount - 2 then
      vLineMargin := PointStyleOffset(EndStyle, EndSize)
    else
      vLineMargin := 0;
    fTextCenter := CenterOfPoints([fPoints[fTextLine], fPoints[fTextLine + 1]]);
    fTextAngle := LineSlopeAngle(fPoints[fTextLine], fPoints[fTextLine + 1]);
    vLineWidth := Trunc(LineLength(fPoints[fTextLine], fPoints[fTextLine + 1]));
    Dec(vLineWidth, Pen.Width + vLineMargin);
    if vLineWidth > 0 then
    begin
      SetRect(vTextRect, 0, 0, vLineWidth, 0);
      vTmpText := Trim(Text);
      SetLength(vTmpText, Length(vTmpText) + 4);
      vCanvas := TEvsCompatibleCanvas.Create;
      try
        vCanvas.Font := Font;
        vSize := vCanvas.TextExtent(vTmpText);
        vTextRect.Bottom := vSize.cy;
        vTmpText := MinimizeText(vCanvas, vTmpText, vTextRect);
      finally
        vCanvas.Free;
      end;
      TextToShow := vTmpText;
      if (TextAngle > Pi / 2) or (TextAngle < -Pi / 2) then
        vTextOfs := vTextRect.Top + (TextSpacing + (Pen.Width + 1) div 2)
      else
        vTextOfs := vTextRect.Top - (TextSpacing + (Pen.Width + 1) div 2);
      fTextCenter := NextPointOfLine(TextAngle - Pi / 2, fTextCenter, vTextOfs);
      fTextCenter := NextPointOfLine(TextAngle, fTextCenter, vLineMargin div 2);
      OffsetRect(vTextRect, fTextCenter.X - vTextRect.Right div 2,
        fTextCenter.Y - vTextRect.Bottom);
      vRgnPts[1] := vTextRect.TopLeft;
      vRgnPts[2] := Types.Point(vTextRect.Right, vTextRect.Top);
      vRgnPts[3] := vTextRect.BottomRight;
      vRgnPts[4] := Types.Point(vTextRect.Left, vTextRect.Bottom);

      if Abs(TextAngle) > Pi / 2 then
        RotatePoints(vRgnPts, TextAngle - Pi, TextCenter)
      else
        RotatePoints(vRgnPts, TextAngle, TextCenter);
      Result := CreatePolygonRgn({$IFNDEF WIN}@{$ENDIF}vRgnPts[1], 4, ALTERNATE);
    end;
  end;
end;

function TEvsGraphLink.HookedPointCount: integer;
begin
  Result := 0;
  if Assigned(Source) then
    Inc(Result);
  if Assigned(Target) then
    Inc(Result);
end;

function TEvsGraphLink.IsFixedPoint(AIndex: integer; AHookedPointsAsFixed: boolean): boolean;
begin
  if (AIndex > 0) and (AIndex < PointCount - 1) then
    Result := (gloFixedBreakPoints in LinkOptions)
  else if (AIndex = 0) and (gloFixedStartPoint in LinkOptions) then
    Result := True
  else if (AIndex = PointCount - 1) and (gloFixedEndPoint in LinkOptions) then
    Result := True
  else if AHookedPointsAsFixed and IsHookedPoint(AIndex) then
    Result := True
  else
    Result := False;
end;

function TEvsGraphLink.IsHookedPoint(AIndex: integer): boolean;
begin
  Result := Assigned(HookedObjectOf(AIndex));
end;

function TEvsGraphLink.HookedObjectOf(AIndex: integer): TEvsGraphObject;
begin
  if AIndex = PointCount - 1 then
    Result := Target
  else if AIndex = 0 then
    Result := Source
  else
    Result := nil;
end;

function TEvsGraphLink.HookedIndexOf(AGraphObject: TEvsGraphObject): integer;
begin
  Result := -1;
  if Assigned(AGraphObject) then
  begin
    if AGraphObject = Source then
      Result := 0
    else if AGraphObject = Target then
      Result := PointCount - 1;
  end;
end;

function TEvsGraphLink.AddPoint(const Pt: TPoint): integer;
begin
  Unhook(Target);
  if Length(fPoints) = fPointCount then
    SetLength(fPoints, fPointCount + 1);
  Result := fPointCount;
  fPoints[Result] := Pt;
  Inc(fPointCount);
  Changed([gcView, gcData, gcText, gcPlacement]);
end;

procedure TEvsGraphLink.InsertPoint(AIndex: integer; const APt: TPoint);
var
  I: integer;
begin
  if AIndex < 0 then
  begin
    AIndex := 0;
    Unhook(AIndex);
  end
  else if AIndex > fPointCount then
    AIndex := fPointCount;
  if Length(fPoints) = fPointCount then
    SetLength(fPoints, fPointCount + 1);
  for I := fPointCount - 1 downto AIndex do
    fPoints[I + 1] := fPoints[I];
  fPoints[AIndex] := APt;
  Inc(fPointCount);
  Changed([gcView, gcData, gcText, gcPlacement]);
end;

procedure TEvsGraphLink.RemovePoint(AIndex: integer);
var
  I: integer;
begin
  if (AIndex >= 0) and (AIndex < fPointCount) then
  begin
    Unhook(AIndex);
    for I := AIndex to fPointCount - 2 do
      fPoints[I] := fPoints[I + 1];
    Dec(fPointCount);
    SetLength(fPoints, fPointCount);
    Changed([gcView, gcData, gcText, gcPlacement]);
  end;
end;

function TEvsGraphLink.IndexOfPoint(const Pt: TPoint; Neighborhood: integer): integer;
var
  I: integer;
  NeighborhoodArea: TRect;
begin
  Result := -1;
  NeighborhoodArea := MakeSquare(Pt, Neighborhood);
  for I := 0 to fPointCount - 1 do
    if PtInRect(NeighborhoodArea, fPoints[I]) then
    begin
      Result := I;
      Break;
    end;
end;

function TEvsGraphLink.AddBreakPoint(const Pt: TPoint): integer;
begin
  Result := IndexOfNearestLine(Pt, Pen.Width div 2 + Owner.MarkerSize) + 1;
  if Result > 0 then
    InsertPoint(Result, Pt);
end;

function TEvsGraphLink.NormalizeBreakPoints(AOptions: TEvsLinkNormalizeOptions): boolean;
var
  I: integer;
  Neighborhood: integer;
  LastAngle, Angle: double;
begin
  Result := False;
  if (PointCount > 2) and (AOptions <> []) then
  begin
    BeginUpdate;
    try
      // Delete breakpoints on same point
      if lnoDeleteSamePoint in AOptions then
      begin
        Neighborhood := NeighborhoodRadius;
        I := 1;
        while I < PointCount do
        begin
          if LineLength(Points[I - 1], Points[I]) <= Neighborhood then
          begin
            if I = PointCount - 1 then
              RemovePoint(I - 1)
            else
              RemovePoint(I);
            Result := True;
          end
          else
            Inc(I);
        end;
      end;
      // Delete breakpoints on a straight line
      if lnoDeleteSameAngle in AOptions then
      begin
        LastAngle := LineSlopeAngle(Points[0], Points[1]);
        I := 2;
        while I < PointCount do
        begin
          Angle := LineSlopeAngle(Points[I - 1], Points[I]);
          if Abs(Angle - LastAngle) < 0.05 * Pi then
          begin
            if I = PointCount - 1 then
              RemovePoint(I - 1)
            else
              RemovePoint(I);
            Result := True;
          end
          else
            Inc(I);
          LastAngle := Angle;
        end;
      end;
    finally
      EndUpdate;
    end;
  end;
end;

function TEvsGraphLink.CanMove: boolean;
begin
  Result := not Assigned(Source) and not Assigned(Target) and not
    (gloFixedStartPoint in LinkOptions) and not (gloFixedBreakPoints in LinkOptions) and
    not (gloFixedEndPoint in LinkOptions);
end;

function TEvsGraphLink.Rotate(const AAngle: double; const AOrigin: TPoint): boolean;
var
  NewPolyline: TPoints;
begin
  Result := False;
  if CanMove and (PointCount > 1) then
  begin
    NewPolyline := Copy(Polyline, 0, PointCount);
    try
      RotatePoints(NewPolyline, AAngle, AOrigin);
      if Owner.GraphConstraints.WithinBounds(NewPolyline) then
      begin
        Polyline := NewPolyline;
        Result := True;
      end;
    finally
      SetLength(NewPolyline, 0);
    end;
  end;
end;

function TEvsGraphLink.Scale(const AFactor: double): boolean;
var
  NewPolyline: TPoints;
begin
  Result := False;
  if CanMove and (PointCount > 1) then
  begin
    NewPolyline := Copy(Polyline, 0, PointCount);
    try
      ScalePoints(NewPolyline, AFactor, CenterOfPoints(NewPolyline));
      if Owner.GraphConstraints.WithinBounds(NewPolyline) then
      begin
        Polyline := NewPolyline;
        Result := True;
      end;
    finally
      SetLength(NewPolyline, 0);
    end;
  end;
end;

procedure TEvsGraphLink.Reverse;
var
  GraphObject: TEvsGraphObject;
  GraphObjectID: integer;
  Pt: TPoint;
  I: integer;
begin
  GraphObject := fSource;
  GraphObjectID := SourceID;
  fSource := fTarget;
  SourceID := TargetID;
  fTarget := GraphObject;
  TargetID := GraphObjectID;
  if (fTextPosition >= 0) and (PointCount > 2) then
    fTextPosition := PointCount - 2 - fTextPosition;
  for I := 0 to (PointCount div 2) - 1 do
  begin
    Pt := fPoints[I];
    fPoints[I] := fPoints[PointCount - 1 - I];
    fPoints[PointCount - 1 - I] := Pt;
  end;
  Changed([gcView, gcData, gcPlacement]);
end;

procedure TEvsGraphLink.SetSource(Value: TEvsGraphObject);
begin
  if Source <> Value then
  begin
    BeginUpdate;
    try
      Unhook(0);
      Hook(0, Value);
    finally
      EndUpdate;
    end;
  end;
end;

procedure TEvsGraphLink.SetTarget(Value: TEvsGraphObject);
begin
  if Target <> Value then
  begin
    BeginUpdate;
    try
      Unhook(PointCount - 1);
      Hook(PointCount - 1, Value);
    finally
      EndUpdate;
    end;
  end;
end;

procedure TEvsGraphLink.SetLinkOptions(Value: TEvsGraphLinkOptions);
begin
  if LinkOptions <> Value then
  begin
    fLinkOptions := Value;
    Changed([gcView, gcData, gcPlacement]);
  end;
end;

procedure TEvsGraphLink.SetTextPosition(Value: integer);
begin
  if TextPosition <> Value then
  begin
    fTextPosition := Value;
    Changed([gcView, gcData, gcText]);
  end;
end;

procedure TEvsGraphLink.SetTextSpacing(Value: integer);
begin
  if TextSpacing <> Value then
  begin
    fTextSpacing := Value;
    Changed([gcView, gcData, gcText]);
  end;
end;

procedure TEvsGraphLink.SetBeginStyle(Value: TEvsLinkBeginEndStyle);
begin
  if BeginStyle <> Value then
  begin
    fBeginStyle := Value;
    Changed([gcView, gcData, gcText]);
  end;
end;

procedure TEvsGraphLink.SetBeginSize(Value: byte);
begin
  if BeginSize <> Value then
  begin
    fBeginSize := Value;
    Changed([gcView, gcData, gcText]);
  end;
end;

procedure TEvsGraphLink.SetEndStyle(Value: TEvsLinkBeginEndStyle);
begin
  if EndStyle <> Value then
  begin
    fEndStyle := Value;
    Changed([gcView, gcData, gcText]);
  end;
end;

procedure TEvsGraphLink.SetEndSize(Value: byte);
begin
  if EndSize <> Value then
  begin
    fEndSize := Value;
    Changed([gcView, gcData, gcText]);
  end;
end;

function TEvsGraphLink.GetPoints(Index: integer): TPoint;
begin
  if (Index < 0) or (Index >= PointCount) then
    raise EEvsPointListError.CreateFmt('Invalid point index. (%d)', [Index]);
  Result := fPoints[Index];
end;

procedure TEvsGraphLink.SetPoints(Index: integer; const Value: TPoint);
begin
  if (Index < 0) or (Index >= PointCount) then
    raise EEvsPointListError.CreateFmt('Invalid point index. (%d)', [Index]);
  if not EqualPoint(fPoints[Index], Value) then
  begin
    Unhook(Index);
    fPoints[Index] := Value;
    Changed([gcView, gcData, gcText, gcPlacement]);
  end;
end;

procedure TEvsGraphLink.SetPolyline(const Value: TPoints);
begin
  if (PointCount <> Length(Value)) or ((PointCount > 0) and not
    CompareMem(@fPoints[0], @Value[0], PointCount * SizeOf(TPoint))) then
  begin
    fPointCount := Length(Value);
    fPoints := Copy(Value, 0, fPointCount);
    Unhook(Source);
    Unhook(Target);
    Changed([gcView, gcData, gcText, gcPlacement]);
  end;
end;

procedure TEvsGraphLink.Loaded;
begin
  inherited Loaded;
  // Backward compatibility
  if (PointCount = 0) and Assigned(Source) and Assigned(Target) then
  begin
    Inc(fPointCount, 2);
    SetLength(fPoints, fPointCount);
    UpdateDependencies;
  end;
end;

procedure TEvsGraphLink.ReplaceID(OldID, NewID: DWORD);
begin
  inherited ReplaceID(OldID, NewID);
  if (SourceID <> 0) and (SourceID = OldID) then
    SourceID := NewID;
  if (TargetID <> 0) and (TargetID = OldID) then
    TargetID := NewID;
end;

procedure TEvsGraphLink.ReplaceObject(OldObject, NewObject: TEvsGraphObject);
begin
  if Source = OldObject then
  begin
    fSource := NewObject;
    SourceID := NewObject.ID;
  end;
  if Target = OldObject then
  begin
    fTarget := NewObject;
    TargetID := NewObject.ID;
  end;
  inherited ReplaceObject(OldObject, NewObject);
end;

procedure TEvsGraphLink.LookupDependencies;
var
  GraphObject: TEvsGraphObject;
begin
  if (SourceID <> 0) and not Assigned(Source) then
  begin
    GraphObject := Owner.FindObjectByID(SourceID);
    if Assigned(GraphObject) then
    begin
      fSource := GraphObject;
      GraphObject.LinkOutputList.Add(Self);
    end;
  end;
  if (TargetID <> 0) and not Assigned(Target) then
  begin
    GraphObject := Owner.FindObjectByID(TargetID);
    if Assigned(GraphObject) then
    begin
      fTarget := GraphObject;
      GraphObject.LinkInputList.Add(Self);
    end;
  end;
  inherited LookupDependencies;
end;

procedure TEvsGraphLink.NotifyDependents(Flag: TEvsGraphDependencyChangeFlag);
begin
  if HookedPointCount > 0 then
    case Flag of
      gdcChanged:
        UpdateDependencies;
      gdcRemoved:
      begin
        Unhook(Source);
        Unhook(Target);
      end;
    end;
  inherited NotifyDependents(Flag);
end;

procedure TEvsGraphLink.UpdateDependencyTo(GraphObject: TEvsGraphObject;
  Flag: TEvsGraphDependencyChangeFlag);
begin
  if HookedIndexOf(GraphObject) >= 0 then
    case Flag of
      gdcChanged:
        UpdateDependencies;
      gdcRemoved:
        Unhook(GraphObject);
    end;
  inherited UpdateDependencyTo(GraphObject, Flag);
end;

procedure TEvsGraphLink.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);
  Filer.DefineProperty('Source', @ReadSource, @WriteSource, Assigned(Source));
  Filer.DefineProperty('Target', @ReadTarget, @WriteTarget, Assigned(Target));
  Filer.DefineBinaryProperty('BreakPoints', @ReadPoints, @WritePoints, PointCount > 0);
  // For backward campatibility
  Filer.DefineProperty('FromNode', @ReadFromNode, nil, False);
  Filer.DefineProperty('ToNode', @ReadToNode, nil, False);
  Filer.DefineProperty('Kind', @ReadKind, nil, False);
  Filer.DefineProperty('ArrowSize', @ReadArrowSize, nil, False);
end;

procedure TEvsGraphLink.ReadSource(Reader: TReader);
begin
  SourceID := Reader.ReadInteger;
end;

procedure TEvsGraphLink.WriteSource(Writer: TWriter);
begin
  Writer.WriteInteger(SourceID);
end;

procedure TEvsGraphLink.ReadTarget(Reader: TReader);
begin
  TargetID := Reader.ReadInteger;
end;

procedure TEvsGraphLink.WriteTarget(Writer: TWriter);
begin
  Writer.WriteInteger(TargetID);
end;

procedure TEvsGraphLink.ReadPoints(Stream: TStream);
begin
  Stream.Read(fPointCount, SizeOf(fPointCount));
  SetLength(fPoints, fPointCount);
  if fPointCount > 0 then
    Stream.Read(fPoints[0], fPointCount * SizeOf(fPoints[0]));
end;

procedure TEvsGraphLink.WritePoints(Stream: TStream);
begin
  Stream.Write(fPointCount, SizeOf(fPointCount));
  if fPointCount > 0 then
    Stream.Write(fPoints[0], fPointCount * SizeOf(fPoints[0]));
end;

//// Obsolete - for backward compatibility
procedure TEvsGraphLink.ReadFromNode(Reader: TReader);
begin
  ReadSource(Reader);
end;

// Obsolete - for backward compatibility
procedure TEvsGraphLink.ReadToNode(Reader: TReader);
begin
  ReadTarget(Reader);
end;

// Obsolete - for backward compatibility
procedure TEvsGraphLink.ReadKind(Reader: TReader);
var
  Kind: string;
begin
  Kind := Reader.ReadIdent;
  if LowerCase(Kind) = 'lkundirected' then
    EndStyle := lsNone
  else if LowerCase(Kind) = 'lkbidirected' then
    BeginStyle := lsArrow;
end;

// Obsolete - for backward compatibility
procedure TEvsGraphLink.ReadArrowSize(Reader: TReader);
var
  ArrowSize: integer;
begin
  ArrowSize := Reader.ReadInteger;
  EndSize := ArrowSize + 2;
  EndSize := ArrowSize + 2;
end;

{$ENDREGION}

{$REGION ' TEvsGraphNode'}

constructor TEvsGraphNode.Create(AOwner: TEvsSimpleGraph);
begin
  inherited Create(AOwner);
  fMargin := 8;
  fAlignment := taCenter;
  fLayout := tlCenter;
  fBackground := TPicture.Create;
  fBackground.OnChange := @BackgroundChanged;
  fNodeOptions := [gnoMovable, gnoResizable, gnoShowBackground ];
end;

constructor TEvsGraphNode.CreateNew(AOwner: TEvsSimpleGraph; const Bounds: TRect);
begin
  Create(AOwner);
  SetBoundsRect(Bounds);
end;

destructor TEvsGraphNode.Destroy;
begin
  if Region <> 0 then
    LCLIntf.DeleteObject(Region);
  fBackground.Free;
  inherited Destroy;
end;

procedure TEvsGraphNode.Assign(Source: TPersistent);
begin
  BeginUpdate;
  try
    inherited Assign(Source);
    if Source is TEvsGraphNode then
      with Source as TEvsGraphNode do
      begin
        Self.Background := Background;
        Self.Alignment := Alignment;
        Self.Layout := Layout;
        Self.Margin := Margin;
        Self.NodeOptions := NodeOptions;
        Self.BackgroundMargins := BackgroundMargins;
        Self.SetBounds(Left, Top, Width, Height);
      end;
  finally
    EndUpdate;
  end;
end;

function TEvsGraphNode.ContainsRect(const Rect: TRect): boolean;
begin
  if Selected then
    Result := inherited ContainsRect(Rect)
  else
    Result := Showing and RectInRegion(Region, Rect);
end;

procedure TEvsGraphNode.QueryVisualRect(out Rect: TRect);
var
  vMargin: integer;
begin
  Rect := BoundsRect;
  if Pen.Style <> psInsideFrame then
  begin
    vMargin := Pen.Width div 2;
    InflateRect(Rect, vMargin, vMargin);
  end;
end;

function TEvsGraphNode.QueryHitTest(const Pt: TPoint): DWORD;
var
  Neighborhood: integer;
begin
  if Selected then
  begin
    Result := GHT_NOWHERE;
    Neighborhood := NeighborhoodRadius;
    if PtInRect(MakeSquare(Types.Point(Left + Width, Top + Height), Neighborhood), Pt) then
      Result := GHT_BOTTOMRIGHT
    else if PtInRect(MakeSquare(Types.Point(Left, Top + Height), Neighborhood), Pt) then
      Result := GHT_BOTTOMLEFT
    else if PtInRect(MakeSquare(Types.Point(Left + Width, Top), Neighborhood), Pt) then
      Result := GHT_TOPRIGHT
    else if PtInRect(MakeSquare(Types.Point(Left, Top), Neighborhood), Pt) then
      Result := GHT_TOPLEFT
    else if PtInRect(MakeSquare(Types.Point(Left + Width div 2, Top + Height),
      Neighborhood), Pt) then
      Result := GHT_BOTTOM
    else if PtInRect(MakeSquare(Types.Point(Left + Width, Top + Height div 2),
      Neighborhood), Pt) then
      Result := GHT_RIGHT
    else if PtInRect(MakeSquare(Types.Point(Left, Top + Height div 2), Neighborhood), Pt) then
      Result := GHT_LEFT
    else if PtInRect(MakeSquare(Types.Point(Left + Width div 2, Top), Neighborhood), Pt) then
      Result := GHT_TOP;
    if Result <> GHT_NOWHERE then
      Exit;
  end;
  Result := inherited QueryHitTest(Pt);
  {$IFDEF LCLGTK2}
  if PtInRect(BoundsRect, Pt) then
    Result := Result or GHT_CLIENT;
  {$ELSE}
  if PtInRegion(Region, Pt.X, Pt.Y) then
    Result := Result or GHT_CLIENT;
  {$ENDIF}
  if (goShowCaption in Options) and PtInRect(TextRect, Pt) then
    Result := Result or GHT_CAPTION;
end;

procedure TEvsGraphNode.SnapHitTestOffset(HT: DWORD; var dX, dY: integer);
var
  Pt: TPoint;
begin
  if (HT and (GHT_BODY_MASK or GHT_SIDES_MASK)) <> 0 then
  begin
    Pt.X := Left;
    Pt.Y := Top;
    if (HT and (GHT_RIGHT or GHT_TOPRIGHT or GHT_BOTTOMRIGHT)) <> 0 then
      Inc(Pt.X, Width);
    if (HT and (GHT_BOTTOM or GHT_BOTTOMLEFT or GHT_BOTTOMRIGHT)) <> 0 then
      Inc(Pt.Y, Height);
    Owner.SnapOffset(Pt, dX, dY);
  end
  else
    inherited SnapHitTestOffset(HT, dX, dY);
end;

function TEvsGraphNode.QueryMobility(HT: DWORD): TEvsObjectSides;
const
  LeftSideHT = GHT_BODY_MASK or GHT_LEFT or GHT_TOPLEFT or GHT_BOTTOMLEFT;
  TopSideHT = GHT_BODY_MASK or GHT_TOP or GHT_TOPLEFT or GHT_TOPRIGHT;
  RightSideHT = GHT_BODY_MASK or GHT_RIGHT or GHT_TOPRIGHT or GHT_BOTTOMRIGHT;
  BottomSideHT = GHT_BODY_MASK or GHT_BOTTOM or GHT_BOTTOMLEFT or GHT_BOTTOMRIGHT;
begin
  if (HT and (GHT_BODY_MASK or GHT_SIDES_MASK)) <> 0 then
  begin
    Result := [];
    if (HT and LeftSideHT) <> 0 then
      Include(Result, osLeft);
    if (HT and TopSideHT) <> 0 then
      Include(Result, osTop);
    if (HT and RightSideHT) <> 0 then
      Include(Result, osRight);
    if (HT and BottomSideHT) <> 0 then
      Include(Result, osBottom);
  end
  else
    Result := inherited QueryMobility(HT);
end;

function TEvsGraphNode.OffsetHitTest(HT: DWORD; dX, dY: integer): boolean;
var
  OldWidth, OldHeight: integer;
begin
  Result := False;
  case HT and (GHT_BODY_MASK or GHT_SIDES_MASK) of
    GHT_CLIENT, GHT_CAPTION, GHT_CLIENT or GHT_CAPTION:
      if gnoMovable in NodeOptions then
      begin
        SetBounds(Left + dX, Top + dY, Width, Height);
        Result := True;
      end;
    GHT_LEFT:
      if gnoResizable in NodeOptions then
      begin
        OldWidth := Width;
        SetBounds(Left, Top, Width - dX, Height);
        SetBounds(Left + (OldWidth - Width), Top, Width, Height);
        Result := True;
      end;
    GHT_RIGHT:
      if gnoResizable in NodeOptions then
      begin
        SetBounds(Left, Top, Width + dX, Height);
        Result := True;
      end;
    GHT_TOP:
      if gnoResizable in NodeOptions then
      begin
        OldHeight := Height;
        SetBounds(Left, Top, Width, Height - dY);
        SetBounds(Left, Top + (OldHeight - Height), Width, Height);
        Result := True;
      end;
    GHT_BOTTOM:
      if gnoResizable in NodeOptions then
      begin
        SetBounds(Left, Top, Width, Height + dY);
        Result := True;
      end;
    GHT_TOPLEFT:
      if gnoResizable in NodeOptions then
      begin
        OldWidth := Width;
        OldHeight := Height;
        SetBounds(Left, Top, Width - dX, Height - dY);
        SetBounds(Left + (OldWidth - Width), Top + (OldHeight - Height), Width, Height);
        Result := True;
      end;
    GHT_TOPRIGHT:
      if gnoResizable in NodeOptions then
      begin
        OldHeight := Height;
        SetBounds(Left, Top, Width + dX, Height - dY);
        SetBounds(Left, Top + (OldHeight - Height), Width, Height);
        Result := True;
      end;
    GHT_BOTTOMLEFT:
      if gnoResizable in NodeOptions then
      begin
        OldWidth := Width;
        SetBounds(Left, Top, Width - dX, Height + dY);
        SetBounds(Left + (OldWidth - Width), Top, Width, Height);
        Result := True;
      end;
    GHT_BOTTOMRIGHT:
      if gnoResizable in NodeOptions then
      begin
        SetBounds(Left, Top, Width + dX, Height + dY);
        Result := True;
      end;
    else
      inherited OffsetHitTest(HT, dX, dY);
  end;
end;

procedure TEvsGraphNode.MoveBy(dX, dY: integer);
begin
  SetBounds(Left + dX, Top + dY, Width, Height);
end;

function TEvsGraphNode.QueryCursor(HT: DWORD): TCursor;
begin
  case HT of
    GHT_CLIENT, GHT_CAPTION, GHT_CLIENT or GHT_CAPTION:
      if (gnoMovable in NodeOptions) and not IsLocked then
        Result := crSizeAll
      else
        Result := crHandPoint;
    GHT_LEFT, GHT_RIGHT:
      if (gnoResizable in NodeOptions) and not IsLocked then
        Result := crSizeWE
      else
        Result := crHandPoint;
    GHT_TOP, GHT_BOTTOM:
      if (gnoResizable in NodeOptions) and not IsLocked then
        Result := crSizeNS
      else
        Result := crHandPoint;
    GHT_TOPLEFT, GHT_BOTTOMRIGHT:
      if (gnoResizable in NodeOptions) and not IsLocked then
        Result := crSizeNWSE
      else
        Result := crHandPoint;
    GHT_TOPRIGHT, GHT_BOTTOMLEFT:
      if (gnoResizable in NodeOptions) and not IsLocked then
        Result := crSizeNESW
      else
        Result := crHandPoint;
    else
      Result := inherited QueryCursor(HT);
  end;
end;

function TEvsGraphNode.BeginFollowDrag(HT: DWORD): boolean;
begin
  if (HT and (GHT_BODY_MASK or GHT_SIDES_MASK)) <> 0 then
    Result := inherited BeginFollowDrag(HT)
  else
    Result := False;
end;

function TEvsGraphNode.CreateClipRgn(ACanvas: TCanvas): HRGN;
var
  XForm: TXForm;
  DevExt: TSize;
  LogExt: TSize;
  Org: TPoint;
begin
  GetViewportExtEx(ACanvas.Handle, @DevExt);
  GetWindowExtEx(ACanvas.Handle, @LogExt);
  GetViewportOrgEx(ACanvas.Handle, @Org);
  with XForm do
  begin
    eM11 := DevExt.CX / LogExt.CX;
    eM12 := 0;
    eM21 := 0;
    eM22 := DevExt.CY / LogExt.CY;
    Owner.GPtoCL(Org);
    eDx  := Org.X;
    eDy  := Org.Y;
  end;

  Result := TransformRgn(Region, XForm);
end;

procedure TEvsGraphNode.QueryMaxTextRect(out Rect: TRect);
var
  TextMargin: integer;
begin
  Rect := BoundsRect;
  if Pen.Style = psInsideFrame then
    TextMargin := Margin + Pen.Width
  else
    TextMargin := Margin + Pen.Width div 2;
  LCLIntf.InflateRect(Rect, -TextMargin, -TextMargin);
end;

procedure TEvsGraphNode.QueryTextRect(out Rect: TRect);
const
  DrawTextFlags = DT_NOPREFIX or DT_EDITCONTROL or DT_CALCRECT;
var
  vOffset: TPoint;
  vMaxTextRect: TRect;
  vCanvas: TCanvas;
begin
  TextToShow := '';
  if (Text <> '') then
  begin
    QueryMaxTextRect(vMaxTextRect);                                              //internal method
    LCLIntf.OffsetRect(vMaxTextRect, -Left, -Top);                               //lclintf used
    vCanvas := TEvsCompatibleCanvas.Create;
    try
      vCanvas.Font := Font;
      TextToShow := MinimizeText(vCanvas, Text, vMaxTextRect);                    //Internal helper
      Rect := vMaxTextRect;
      LCLIntf.DrawText(vCanvas.Handle, PChar(TextToShow), Length(TextToShow),  //calculate the text's rectangle required for painting.
        Rect, Owner.DrawTextBiDiModeFlags(DrawTextFlags));
    finally
      vCanvas.Free;
    end;
    if Rect.Right > vMaxTextRect.Right then
      Rect.Right := vMaxTextRect.Right;
    if Rect.Bottom > vMaxTextRect.Bottom then
      Rect.Bottom := vMaxTextRect.Bottom;
    case Alignment of
      taLeftJustify:
        vOffset.X := 0;
      taRightJustify:
        vOffset.X := vMaxTextRect.Right - Rect.Right;
      else
        vOffset.X := (vMaxTextRect.Right - Rect.Right) div 2;
    end;
    case Layout of
      tlTop:
        vOffset.Y := 0;
      tlBottom:
        vOffset.Y := vMaxTextRect.Bottom - Rect.Bottom;
      else
        vOffset.Y := (vMaxTextRect.Bottom - Rect.Bottom) div 2;
    end;
    OffsetRect(Rect, Left + vOffset.X, Top + vOffset.Y);
  end
  else
    FillChar(Rect, SizeOf(Rect), 0);
end;

procedure TEvsGraphNode.DrawText(aCanvas: TCanvas);
var
  Rect: TRect;
  vTextStyle : TTextStyle;
  vOldColor  : TColor;
begin
  if TextToShow <> '' then
  begin
    Rect                   := TextRect;
    vTextStyle             := aCanvas.TextStyle;
    vTextStyle.Alignment   := Alignment;
    vTextStyle.Layout      := Layout;
    vTextStyle.Opaque      := False;
    vTextStyle.Wordbreak   := True;
    vTextStyle.ShowPrefix  := False;
    vTextStyle.SystemFont  := False;
    vTextStyle.EndEllipsis := False;
    vTextStyle.SingleLine  := False;
    aCanvas.TextRect(Rect, Rect.Left, Rect.Top, TextToShow, vTextStyle);
  end;
end;

procedure TEvsGraphNode.DrawBackground(aCanvas: TCanvas);
var
  ClipRgn: HRGN;
  Bitmap: Graphics.TBitmap;
  Graphic: TGraphic;
  ImageRect: TRect;
  //vPts : array[0..1] of TPoint absolute ImageRect;
begin
  if Background.Graphic <> nil then
  begin
    ImageRect.Left := Left + MulDiv(Width, BackgroundMargins.Left, 100);
    ImageRect.Top := Top + MulDiv(Height, BackgroundMargins.Top, 100);
    ImageRect.Right := Left + Width - MulDiv(Width, BackgroundMargins.Right, 100);
    ImageRect.Bottom := Top + Height - MulDiv(Height, BackgroundMargins.Bottom, 100);
    ClipRgn := CreateClipRgn(aCanvas);
    try
      SelectClipRgn(aCanvas.Handle, ClipRgn);
      try
        Graphic := Background.Graphic;
        Background.OnChange := nil;
        try
          {$IFDEF METAFILE_SUPPORT} //JKOZ:Metafile
          if (Graphic is TMetafile) and (aCanvas is TMetafileCanvas) and
            ((ImageRect.Left >= Screen.Width) or (ImageRect.Top >= Screen.Height)) then
          begin // Workaround Windows bug!
            Bitmap := TBitmap.Create;
            try
              Bitmap.Transparent := True;
              Bitmap.TransparentColor := aCanvas.Brush.Color;
              Bitmap.aCanvas.Brush.Color := aCanvas.Brush.Color;
              Bitmap.Width := ImageRect.Right - ImageRect.Left;
              Bitmap.Height := ImageRect.Bottom - ImageRect.Top;
              Bitmap.PixelFormat := pf32bit;
              Bitmap.aCanvas.StretchDraw(Rect(0, 0, Bitmap.Width,
                Bitmap.Height), Graphic);
              aCanvas.Draw(ImageRect.Left, ImageRect.Top, Bitmap);
            finally
              Bitmap.Free;
            end;
          end
          else
          {$ENDIF}
            aCanvas.StretchDraw(ImageRect, Graphic);
        finally
          Background.OnChange := @BackgroundChanged;
        end;
      finally
        SelectClipRgn(aCanvas.Handle, 0);
      end;
    finally
      DeleteObject(ClipRgn);
    end;
    aCanvas.Brush.Style := bsClear;
    DrawBorder(aCanvas);
  end;
end;

procedure TEvsGraphNode.DrawControlPoints(aCanvas: TCanvas);
var
  Enabled: boolean;
  LP,TP:Integer;
begin
  LP := Left;
  TP := Top;
  Enabled := not IsLocked and (gnoResizable in NodeOptions);
  DrawControlPoint(aCanvas, Types.Point(LP, TP), Enabled);
  DrawControlPoint(aCanvas, Types.Point(LP + Width, TP), Enabled);
  DrawControlPoint(aCanvas, Types.Point(LP, TP + Height), Enabled);
  DrawControlPoint(aCanvas, Types.Point(LP + Width, TP + Height), Enabled);
  DrawControlPoint(aCanvas, Types.Point(LP + Width div 2, TP + Height), Enabled);
  DrawControlPoint(aCanvas, Types.Point(LP + Width, TP + Height div 2), Enabled);
  DrawControlPoint(aCanvas, Types.Point(LP, Tp + Height div 2), Enabled);
  DrawControlPoint(aCanvas, Types.Point(LP + Width div 2, TP), Enabled);
end;

procedure TEvsGraphNode.DrawHighlight(aCanvas: TCanvas);
begin
  DrawBorder(aCanvas);
end;

procedure TEvsGraphNode.DrawBody(aCanvas: TCanvas);
begin
  DrawBorder(aCanvas);
  if gnoShowBackground in NodeOptions then
    DrawBackground(aCanvas);
end;

function TEvsGraphNode.UpdateTextPlacement(Recalc: boolean; dX, dY: integer): boolean;
begin
  if Recalc then
    QueryTextRect(fTextRect)
  else
    LCLIntf.OffsetRect(fTextRect, dX, dY);
  Result := True;
end;

procedure TEvsGraphNode.Initialize;
begin
  if fRegion <> 0 then
    DeleteObject(fRegion);
  fRegion := CreateRegion;
  inherited Initialize;
end;

procedure TEvsGraphNode.BoundsChanged(dX, dY, dCX, dCY: integer);
begin
  if (dCX <> 0) or (dCY <> 0) then begin
    if fRegion <> 0 then DeleteObject(fRegion);
    fRegion := CreateRegion;
  end
  else if (dX <> 0) or (dY <> 0) then OffsetRgn(fRegion, dX, dY);
  inherited BoundsChanged(dX, dY, dCX, dCY);
end;

function TEvsGraphNode.GetCenter: TPoint;
begin
  Result.X := Left + Width div 2;
  Result.Y := Top + Height div 2;
end;

function TEvsGraphNode.FixHookAnchor: TPoint;
begin
  Result := Center;
end;

function TEvsGraphNode.RelativeHookAnchor(RefPt: TPoint): TPoint;
var
  Angle: double;
  Intersects: TPoints;
begin
  Result := FixHookAnchor;
  if not PtInRegion(Region, RefPt.X, RefPt.Y) then
  begin
    Angle := LineSlopeAngle(RefPt, Result);
    Intersects := LinkIntersect(RefPt, Angle);
    try
      if NearestPoint(Intersects, RefPt, Result) < 0 then
        Result := FixHookAnchor;
    finally
      SetLength(Intersects, 0);
    end;
  end;
end;

procedure TEvsGraphNode.CanMoveResize(var NewLeft, NewTop, NewWidth, NewHeight: integer;
  out CanMove, CanResize: boolean);
begin
  CanMove := (gnoMovable in NodeOptions);
  CanResize := (gnoResizable in NodeOptions);
  if NewWidth < Owner.MinNodeSize then
    NewWidth := Owner.MinNodeSize;
  if NewHeight < Owner.MinNodeSize then
    NewHeight := Owner.MinNodeSize;
  with Owner.GraphConstraints do
  begin
    if NewLeft < BoundsRect.Left then
      NewLeft := BoundsRect.Left;
    if NewTop < BoundsRect.Top then
      NewTop := BoundsRect.Top;
    if NewLeft + NewWidth > BoundsRect.Right then
      if NewWidth = Width then
        NewLeft := BoundsRect.Right - NewWidth
      else
        NewWidth := BoundsRect.Right - NewLeft;
    if NewTop + NewHeight > BoundsRect.Bottom then
      if NewHeight = Height then
        NewTop := BoundsRect.Bottom - NewHeight
      else
        NewHeight := BoundsRect.Bottom - NewTop;
  end;
  Owner.DoCanMoveResizeNode(Self, NewLeft, NewTop, NewWidth, NewHeight,
    CanMove, CanResize);
end;

procedure TEvsGraphNode.SetBounds(aLeft, aTop, aWidth, aHeight: integer);
var
  CanMove, CanResize: boolean;
  dX, dY, dCX, dCY: integer;
begin
  CanMoveResize(aLeft, aTop, aWidth, aHeight, CanMove, CanResize);
  if CanMove or CanResize then
  begin
    dX := 0;
    dY := 0;
    if CanMove then
    begin
      dX := aLeft - fLeft;
      fLeft := aLeft;
      dY := aTop - fTop;
      fTop := aTop;
    end;
    dCX := 0;
    dCY := 0;
    if CanResize then
    begin
      dCX := aWidth - fWidth;
      fWidth := aWidth;
      dCY := aHeight - fHeight;
      fHeight := aHeight;
    end;
    if (dX <> 0) or (dY <> 0) or (dCX <> 0) or (dCY <> 0) then
    begin
      BoundsChanged(dX, dY, dCX, dCY);
      Owner.DoNodeMoveResize(Self);
    end;
  end;
end;

procedure TEvsGraphNode.SetBoundsRect(const aRect: TRect);
begin
  with aRect do
    SetBounds(Left, Top, Right - Left, Bottom - Top);
end;

function TEvsGraphNode.GetBoundsRect: TRect;
begin
  Result.Left := Left;
  Result.Top := Top;
  Result.Right := Left + Width;
  Result.Bottom := Top + Height;
end;

procedure TEvsGraphNode.SetLeft(Value: integer);
begin
  if osReading in States then
    fLeft := Value
  else if Left <> Value then
    SetBounds(Value, Top, Width, Height);
end;

procedure TEvsGraphNode.SetTop(Value: integer);
begin
  if osReading in States then
    fTop := Value
  else if Top <> Value then
    SetBounds(Left, Value, Width, Height);
end;

procedure TEvsGraphNode.SetWidth(Value: integer);
begin
  if osReading in States then
    fWidth := Value
  else if Width <> Value then
    SetBounds(Left, Top, Value, Height);
end;

procedure TEvsGraphNode.SetHeight(Value: integer);
begin
  if osReading in States then
    fHeight := Value
  else if Height <> Value then
    SetBounds(Left, Top, Width, Value);
end;

procedure TEvsGraphNode.SetAlignment(Value: TAlignment);
begin
  if Alignment <> Value then
  begin
    fAlignment := Value;
    Changed([gcView, gcData, gcText]);
  end;
end;

procedure TEvsGraphNode.SetLayout(Value: TTextLayout);
begin
  if Layout <> Value then
  begin
    fLayout := Value;
    Changed([gcView, gcData, gcText]);
  end;
end;

procedure TEvsGraphNode.SetMargin(Value: integer);
begin
  if Margin <> Value then
  begin
    fMargin := Value;
    Changed([gcView, gcData, gcText]);
  end;
end;

procedure TEvsGraphNode.SetNodeOptions(Value: TEvsGraphNodeOptions);
begin
  if NodeOptions <> Value then
  begin
    fNodeOptions := Value;
    Changed([gcView, gcData]);
  end;
end;

procedure TEvsGraphNode.SetBackground(Value: TPicture);
begin
  if fBackground <> Value then
    fBackground.Assign(Value);
end;

procedure TEvsGraphNode.SetBackgroundMargins(const Value: TRect);
begin
  if not EqualRect(BackgroundMargins, Value) then
  begin
    fBackgroundMargins := Value;
    Changed([gcView, gcData]);
  end;
end;

procedure TEvsGraphNode.BackgroundChanged(Sender: TObject);
begin
  Changed([gcView, gcData]);
end;

procedure TEvsGraphNode.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);
  Filer.DefineProperty('BackgroundMargins', @ReadBackgroundMargins,
    @WriteBackgroundMargins, not EqualRect(BackgroundMargins, Types.Rect(0, 0, 0, 0)));
end;

procedure TEvsGraphNode.ReadBackgroundMargins(Reader: TReader);
var
  R: TRect;
begin
  R.Left := Reader.ReadInteger;
  R.Top := Reader.ReadInteger;
  R.Right := Reader.ReadInteger;
  R.Bottom := Reader.ReadInteger;
  BackgroundMargins := R;
end;

procedure TEvsGraphNode.WriteBackgroundMargins(Writer: TWriter);
begin
  with BackgroundMargins do
  begin
    Writer.WriteInteger(Left);
    Writer.WriteInteger(Top);
    Writer.WriteInteger(Right);
    Writer.WriteInteger(Bottom);
  end;
end;

{$ENDREGION}

{$REGION ' TPolygonalNode '}
destructor TEvsPolygonalNode.Destroy;
begin
  SetLength(fVertices, 0);
  inherited Destroy;
end;

procedure TEvsPolygonalNode.Initialize;
begin
  DefineVertices(BoundsRect, fVertices);
  inherited Initialize;
end;

procedure TEvsPolygonalNode.BoundsChanged(dX, dY, dCX, dCY: integer);
begin
  if (dCX <> 0) or (dCY <> 0) then
    DefineVertices(BoundsRect, fVertices)
  else if (dX <> 0) or (dY <> 0) then
    OffsetPoints(fVertices, dX, dY);
  inherited BoundsChanged(dX, dY, dCX, dCY);
end;

function TEvsPolygonalNode.LinkIntersect(const LinkPt: TPoint;
  const LinkAngle: double): TPoints;
begin
  Result := IntersectLinePolygon(LinkPt, LinkAngle, Vertices);
end;

function TEvsPolygonalNode.GetCenter: TPoint;
begin
  Result := CenterOfPoints(Vertices);
end;

function TEvsPolygonalNode.CreateRegion: HRGN;
begin
  Result := CreatePolygonRgn({$IFNDEF WIN}@{$ENDIF}FVertices[0], Length(Vertices), WINDING);
end;

procedure TEvsPolygonalNode.DrawBorder(aCanvas: TCanvas);
var
  Tmp : TPoints;
  //vPen :TPen;
  //VBrush : TBrush;
begin
  Tmp := Copy(Vertices,0,Length(Vertices));
  //vPen := aCanvas.Pen;
  //VBrush := aCanvas.Brush;
  aCanvas.Polygon(Tmp);
  SetLength(Tmp,0);
end;

{$ENDREGION}

{$REGION ' TRoundRectangularNode '}

function TEvsRoundRectangularNode.LinkIntersect(const LinkPt: TPoint;
  const LinkAngle: double): TPoints;
var
  S: integer;
begin
  if Width > Height then
    S := Width div 4
  else
    S := Height div 4;
  Result := IntersectLineRoundRect(LinkPt, LinkAngle, BoundsRect, S, S);
end;

function TEvsRoundRectangularNode.CreateRegion: HRGN;
var
  S: integer;
begin
  if Width > Height then
    S := Width div 4
  else
    S := Height div 4;
  Result := CreateRoundRectRgn(Left, Top, Left + Width + 1, Top + Height + 1, S, S);
end;

procedure TEvsRoundRectangularNode.DrawBorder(Canvas: TCanvas);
var
  S: integer;
  LP,TP:integer;
begin
  if Width > Height then S := Width div 4
  else S := Height div 4;
  LP := Left; TP := Top;
  Canvas.RoundRect(LP, TP, LP + Width, TP + Height, S, S);
end;

{$ENDREGION}

{$REGION ' TEllipticNode '}

function TEvsEllipticNode.LinkIntersect(const LinkPt: TPoint;
  const LinkAngle: double): TPoints;
begin
  Result := IntersectLineEllipse(LinkPt, LinkAngle, BoundsRect);
end;

function TEvsEllipticNode.CreateRegion: HRGN;
begin
  Result := CreateEllipticRgn(Left, Top, Left + Width + 1, Top + Height + 1);
end;

procedure TEvsEllipticNode.DrawBorder(Canvas: TCanvas);
var
  TP,LP:Integer;
begin
  TP := Top; LP := Left;
  Canvas.Ellipse(LP, TP, LP + Width, TP + Height);
end;
{$ENDREGION}

{$REGION ' TTriangularNode '}

procedure TEvsTriangularNode.QueryMaxTextRect(out Rect: TRect);
var
  R: TRect;
begin
  with Rect do
  begin
    Left := (Vertices[0].X + Vertices[2].X) div 2;
    Top := (Vertices[0].Y + Vertices[2].Y) div 2;
    Right := (Vertices[0].X + Vertices[1].X) div 2;
    Bottom := Vertices[1].Y;
  end;
  inherited QueryMaxTextRect(R);
  IntersectRect(Rect, R);
end;

procedure TEvsTriangularNode.DefineVertices(const ARect: TRect; var Points: TPoints);
begin
  SetLength(Points, 3);
  with ARect do
  begin
    with Points[0] do
    begin
      X := (Left + Right) div 2;
      Y := Top;
    end;
    with Points[1] do
    begin
      X := Right;
      Y := Bottom;
    end;
    with Points[2] do
    begin
      X := Left;
      Y := Bottom;
    end;
  end;
end;

{$ENDREGION}

{$REGION ' TEvsRectangularNode '}
function TEvsRectangularNode.CreateRegion : HRGN;
begin
  Result := inherited CreateRegion;
end;

procedure TEvsRectangularNode.DefineVertices(const ARect: TRect; var Points: TPoints);
begin
  SetLength(Points, 4);
  Points[0].X := ARect.Left;
  Points[0].Y := ARect.Top;
  Points[1].X := ARect.Right;
  Points[1].Y := ARect.Top;
  Points[2].X := ARect.Right;
  Points[2].Y := ARect.Bottom;
  Points[3].X := ARect.Left;
  Points[3].Y := ARect.Bottom;
end;
{$ENDREGION}

{$REGION ' TEvsRhomboidalNode '}

procedure TEvsRhomboidalNode.QueryMaxTextRect(out Rect: TRect);
var
  R: TRect;
begin
  with Rect do
  begin
    Left := (Vertices[0].X + Vertices[3].X) div 2;
    Top := (Vertices[0].Y + Vertices[3].Y) div 2;
    Right := (Vertices[1].X + Vertices[2].X) div 2;
    Bottom := (Vertices[1].Y + Vertices[2].Y) div 2;
  end;
  inherited QueryMaxTextRect(R);
  IntersectRect(Rect, R);
end;

procedure TEvsRhomboidalNode.DefineVertices(const ARect: TRect; var Points: TPoints);
begin
  SetLength(Points, 4);
  with ARect do
  begin
    with Points[0] do
    begin
      X := (Left + Right) div 2;
      Y := Top;
    end;
    with Points[1] do
    begin
      X := Right;
      Y := (Top + Bottom) div 2;
    end;
    with Points[2] do
    begin
      X := (Left + Right) div 2;
      Y := Bottom;
    end;
    with Points[3] do
    begin
      X := Left;
      Y := (Top + Bottom) div 2;
    end;
  end;
end;

procedure TEvsPentagonalNode.QueryMaxTextRect(out Rect: TRect);
var
  R: TRect;
begin
  with Rect do
  begin
    Left := Vertices[3].X;
    Top := (Vertices[0].Y + Vertices[4].Y) div 2;
    Right := Vertices[2].X;
    Bottom := Vertices[2].Y;
  end;
  inherited QueryMaxTextRect(R);
  IntersectRect(Rect, R);
end;

procedure TEvsPentagonalNode.DefineVertices(const ARect: TRect; var Points: TPoints);
begin
  SetLength(Points, 5);
  with ARect do
  begin
    with Points[0] do
    begin
      X := (Left + Right) div 2;
      Y := Top;
    end;
    with Points[1] do
    begin
      X := Right;
      Y := (Top + Bottom) div 2;
    end;
    with Points[2] do
    begin
      X := Right - (Right - Left) div 4;
      Y := Bottom;
    end;
    with Points[3] do
    begin
      X := Left + (Right - Left) div 4;
      Y := Bottom;
    end;
    with Points[4] do
    begin
      X := Left;
      Y := (Top + Bottom) div 2;
    end;
  end;
end;
{$ENDREGION}

{$REGION ' TEvsHexagonalNode '}

procedure TEvsHexagonalNode.QueryMaxTextRect(out Rect: TRect);
var
  R: TRect;
begin
  with Rect do
  begin
    Left := Vertices[0].X;
    Top := Vertices[0].Y;
    Right := Vertices[3].X;
    Bottom := Vertices[3].Y;
  end;
  inherited QueryMaxTextRect(R);
  IntersectRect(Rect, R);
end;

procedure TEvsHexagonalNode.DefineVertices(const ARect: TRect; var Points: TPoints);
begin
  SetLength(Points, 6);
  with ARect do
  begin
    with Points[0] do
    begin
      X := Left + (Right - Left) div 4;
      Y := Top;
    end;
    with Points[1] do
    begin
      X := Right - (Right - Left) div 4;
      Y := Top;
    end;
    with Points[2] do
    begin
      X := Right;
      Y := (Top + Bottom) div 2;
    end;
    with Points[3] do
    begin
      X := Right - (Right - Left) div 4;
      Y := Bottom;
    end;
    with Points[4] do
    begin
      X := Left + (Right - Left) div 4;
      Y := Bottom;
    end;
    with Points[5] do
    begin
      X := Left;
      Y := (Top + Bottom) div 2;
    end;
  end;
end;

function ColorIsLight(Color: TColor): Boolean;
begin
  Color := ColorToRGB(Color);
  Result := ((Color and $FF) + (Color shr 8 and $FF) + (Color shr 16 and $FF))>= $180;
end;
{$ENDREGION}

{$REGION ' TEVSBezierLink '}

procedure TEVSBezierLink.Changed(aFlags : TEvsGraphChangeFlags);
begin
  inherited;
  if gcView in aFlags  then
    FPolyline := GetBezierPolyline(Polyline);
end;

procedure TEVSBezierLink.DrawBody(aCanvas : TCanvas);
var
  vOldPenStyle     :TPenStyle;
  vOldBrushStyle   :TBrushStyle;
  vModifiedPolyline:TPoints;
  vAngle           :Double;
  vPtRect          :TRect;
  vCntr            :Integer;
  vBckPen          :TPen;
begin
  vModifiedPolyline := nil;
  if PointCount = 1 then
  begin
    vPtRect := MakeSquare(Points[0], Pen.Width div 2);
    while not IsRectEmpty(vPtRect) do begin
      aCanvas.Ellipse(vPtRect.Left, vPtRect.Top, vPtRect.Right, vPtRect.Bottom);
      InflateRect(vPtRect, -1, -1);
    end;
  end
  else if PointCount >= 2 then
  begin
    if (BeginStyle <> lsNone) or (EndStyle <> lsNone) then
    begin
      vOldPenStyle := aCanvas.Pen.Style;
      aCanvas.Pen.Style := psSolid;
      try
        if BeginStyle <> lsNone then
        begin
          if vModifiedPolyline = nil then vModifiedPolyline := Copy(Polyline, 0, PointCount);
          vAngle := LineSlopeAngle(Points[1], Points[0]);
          vModifiedPolyline[0] := DrawPointStyle(aCanvas, Points[0],
            vAngle, BeginStyle, BeginSize);
        end;
        if EndStyle <> lsNone then
        begin
          if vModifiedPolyline = nil then vModifiedPolyline := Copy(Polyline, 0, PointCount);
          vAngle := LineSlopeAngle(Points[PointCount - 2], Points[PointCount - 1]);
          vModifiedPolyline[PointCount - 1] := DrawPointStyle(aCanvas, Points[PointCount - 1],
            vAngle, EndStyle, EndSize);;
        end;
      finally
        aCanvas.Pen.Style := vOldPenStyle;
      end;
    end;
    vOldBrushStyle := aCanvas.Brush.Style;
    vBckPen := TPen.Create;
    vBckPen.Assign(aCanvas.Pen);
    try
      aCanvas.Brush.Style := bsClear;
      if Selected {and ( not Dragging) }then
      begin
        vOldPenStyle := aCanvas.Pen.Style;
        try
          aCanvas.Pen.Style := psDash;
          vPtRect.TopLeft := Points[0];
          vPtRect.BottomRight := Points[1];
          aCanvas.Polyline(PPoint(@vPtRect),2);
          vPtRect.TopLeft := Points[PointCount -2];
          vPtRect.BottomRight := Points[PointCount -1];
          aCanvas.Polyline(PPoint(@vPtRect),2);

          // In case of a multi bezier draw all the in between control lines too. Has never been tested.
          vCntr := 2;
          while vCntr < PointCount - 3 do
          begin
            aCanvas.MoveTo(Points[vCntr].X, Points[vCntr].Y);
            aCanvas.LineTo(Points[vCntr+1].X, Points[vCntr+1].Y);
            Inc(vCntr, 1);
          end;
        finally
          aCanvas.Pen.Style := vOldPenStyle;
        end;
      end;
      if vModifiedPolyline <> nil then begin
        aCanvas.PolyBezier(vModifiedPolyline);
      end else begin
        aCanvas.PolyBezier(Polyline);
      end;
    finally
      aCanvas.Brush.Style := vOldBrushStyle;
      aCanvas.Pen.Assign(vBckPen);
      vBckPen.Free;
    end;
  end;
  vModifiedPolyline := nil;
end;

procedure TEVSBezierLink.DrawHighlight(aCanvas: TCanvas);
var
  vPtRect : TRect;
  vFirst,
  vLast   : Integer;
  vPen    : TPen;
begin
  vPen := TPen.Create;
  try
    vPen.Assign(aCanvas.Pen);
    //if Selected then
    //  aCanvas.pen.Color := FSelectedColor;
    if PointCount > 1 then
    begin
      if (MovingPoint >= 0) and (MovingPoint < PointCount) then
      begin
        if MovingPoint > 0 then
          vFirst := MovingPoint - 1
        else
          vFirst := MovingPoint;
        if MovingPoint < PointCount - 1 then
          vLast := MovingPoint + 1
        else
          vLast := MovingPoint;
        aCanvas.PolyBezier(Copy(Polyline, vFirst, vLast - vFirst + 1));
      end
      else
        aCanvas.PolyBezier(Polyline);
    end
    else if PointCount = 1 then
    begin
      vPtRect := MakeSquare(Points[0], aCanvas.Pen.Width);
      aCanvas.Ellipse(vPtRect.Left, vPtRect.Top, vPtRect.Right, vPtRect.Bottom);
    end;
  finally
    aCanvas.Pen.Assign(vPen);
    vPen.Free;
  end;
end;

procedure TEVSBezierLink.MouseDown(aButton: TMouseButton; aShift: TShiftState;
  const aPt: TPoint);
begin
  inherited;
  if Owner.CommandMode = cmInsertLink then
    FCreateByMouse := True;
end;

function TEVSBezierLink.IndexOfNearestLine(const Pt : TPoint;
  Neighborhood : integer) : integer;
var
  I: integer;
  NearestDistance: double;
  Distance: double;
begin
  Result := -1;
  NearestDistance := MaxDouble;
  for I := 0 to Length(FPolyline) - 2 do
  begin
    Distance := DistanceToLine(FPolyline[I], FPolyline[I + 1], Pt);
    if (Trunc(Distance) <= Neighborhood) and (Distance < NearestDistance) then
    begin
      NearestDistance := Distance;
      Result := I;
    end;
  end;
end;

function TEVSBezierLink.RelativeHookAnchor(RefPt : TPoint) : TPoint;
  function ValidAnchor(Index: integer): boolean;
  var
    GraphObject: TEvsGraphObject;
  begin
    GraphObject := HookedObjectOf(Index);
    Result := not Assigned(GraphObject) or GraphObject.IsLink;
  end;

var
  Pt: TPoint;
  Line: integer;
  Index: integer;
begin
  Line := IndexOfNearestLine(RefPt, MaxInt);
  if Line >= 0 then
  begin
    Pt := NearestPointOnLine(FPolyline[Line], FPolyline[Line + 1], RefPt);
    Index := IndexOfPoint(Pt, NeighborhoodRadius);
    if Index < 0 then
      Result := Pt
    else if ValidAnchor(Index) then
      Result := FPolyline[Index]
    else
    begin
      if (Index = 0) and ValidAnchor(Index + 1) then
        Result := FPolyline[Index + 1]
      else if (Index = Length(FPolyline) - 1) and ValidAnchor(Index - 1) then
        Result := FPolyline[Index - 1]
      else
        Result := FixHookAnchor;
    end;
  end
  else if PointCount = 1 then
    Result := fPoints[0]
  else
    Result := RefPt;
end;

procedure TEVSBezierLink.MouseUp(aButton: TMouseButton; aShift: TShiftState;
  const aPt: TPoint);
function PointsEqual ( pt1, PT2:TPoint):Boolean;
begin
  Result := (pt1.X = pt2.X) and (pt1.Y = PT2.Y);
end;
var
  vStartPt, vEndPt : TPoint;
  vmidPt1, vMidPt2 : TPoint;
begin
  inherited;
  if FCreateByMouse then
  begin
    if Assigned(Source) and (PointsEqual(Points[0], TEvsGraphNode(Source).FixHookAnchor)) then
      vStartPt := Points[1]
    else
      vStartPt := points[0];
    if Assigned(Target) and (PointsEqual(Points[PointCount -1],TEvsGraphNode(Target).FixHookAnchor)) then
      vEndPt := Points[PointCount -2]
    else
      vEndPt := Points[PointCount -1];
    vmidPt1.X := (vEndPT.X - vStartPt.X) div 4;
    vmidpt1.y := (vEndPT.Y - vStartPt.Y) div 4;
    vmidpt2.X := vEndPt.X - vmidPt1.x;
    vMidPt2.Y := vEndPt.Y - vmidPt1.Y;
    vmidpt1.X := vStartPt.X + vmidPt1.x;
    vMidPt1.Y := vStartPt.Y + vmidPt1.Y;
    InsertPoint(1, vmidPt1);
    InsertPoint(2, vMidPt2);
    FCreateByMouse := False;
  end;
end;

function TEVSBezierLink.QueryHitTest(const aPt: TPoint): DWORD;
var
  vNeighborhood : Integer;
  vCntr         : Integer;
  vPtCount      : Integer;
begin
  vNeighborhood := NeighborhoodRadius;
  for vCntr := PointCount - 1 downto 0 do
    if PtInRect(MakeSquare(Points[vCntr], vNeighborhood), aPt) then
    begin
      if Selected then
        Result := GHT_POINT or (vCntr shl 16)
      else
        Result := GHT_CLIENT;
      Exit;
    end;
  vPtCount := Length(FPolyline);
  for vCntr := 0 to vPtCount - 2 do
  begin
    if DistanceToLine(FPolyline[vCntr], FPolyline[vCntr + 1], aPt) <= vNeighborhood then
    begin
      if Selected then
        Result := GHT_LINE or (vCntr shl 16) or GHT_CLIENT
      else
        Result := GHT_CLIENT;
      Exit;
    end;
  end;
  if (TextRegion <> 0) and (goShowCaption in Options) and PtInRegion(TextRegion, aPt.X, aPt.Y) then
    Result := GHT_CAPTION or GHT_CLIENT
  else
    Result := GHT_NOWHERE;
end;

procedure TEVSBezierLink.UpdateChangeMode(aHT: DWORD; aShift: TShiftState);
begin
  inherited UpdateChangeMode(aHT, aShift);
  if ChangeMode = lcmInsertPoint then  // hack to disable adding more points to the curve remove once I ficure out how to proccess the addition.
    ChangeMode := lcmMovePolyline;
end;

{$ENDREGION}

{$REGION ' TEvsPenRecall '}

procedure TEvsPenRecall.SetReference(aValue : TPen);
begin
  if fReference = aValue then Exit;
  Retrieve;
  fReference := aValue;
  Store;
end;

constructor TEvsPenRecall.Create(AReference : TPen);
begin
  inherited Create;
  fReference := AReference;
  FBackup := TPen.Create;
  Store;
end;

destructor TEvsPenRecall.Destroy;
begin
  Retrieve;
  FBackup.Free;
  inherited Destroy;
end;

procedure TEvsPenRecall.Store;
begin
  if Assigned(fReference) then FBackup.Assign(fReference);
end;

procedure TEvsPenRecall.Retrieve;
begin
  if Assigned(fReference) then
    fReference.Assign(FBackup);
end;
{$ENDREGION}

{$REGION ' TEvsBrushRecall '}

procedure TEvsBrushRecall.SetReference(aValue : TBrush);
begin
  if fReference = aValue then Exit;
  Retrieve;
  fReference := aValue;
  Store;
end;

constructor TEvsBrushRecall.Create(AReference : TBrush);
begin
  inherited Create;
  FReference := AReference;
  Store;
end;

destructor TEvsBrushRecall.Destroy;
begin
  Retrieve;
  FBackup.Free;
  inherited Destroy;
end;

procedure TEvsBrushRecall.Store;
begin
  if Assigned(fReference) then FBackup.Assign(FReference);
end;

procedure TEvsBrushRecall.Retrieve;
begin
  if Assigned(fReference) then FReference.Assign(FBackup);
end;

{$ENDREGION}

{$REGION ' TEvsGraphCanvas '}

procedure TEvsGraphCanvas.SetOffsetX(aValue : Double);
begin
  if FOffsetX = aValue then Exit;
  FOffsetX := aValue;
end;

procedure TEvsGraphCanvas.SetOffsetY(aValue : Double);
begin
  if FOffsetY = aValue then Exit;
  FOffsetY := aValue;
end;

procedure TEvsGraphCanvas.SetScaleX(aValue : Double);
begin
  if FScaleX = aValue then Exit;
  FScaleX := aValue;
end;

procedure TEvsGraphCanvas.SetScaleY(aValue : Double);
begin
  if FScaleY = aValue then Exit;
  FScaleY := aValue;
end;

procedure TEvsGraphCanvas.TranslateCoordinates(var InCoords : Array of TPOINT);
var
  vCntr : Integer;
begin
  if (FOffsetX <> 0) or (FOffsetY <> 0) then
    for vCntr := Low(InCoords) to High(InCoords) do begin
      InCoords[vCntr].x := round(InCoords[vCntr].x + FOffsetX);
      InCoords[vCntr].y := round(InCoords[vCntr].y + FOffsetY);
    end;
end;

procedure TEvsGraphCanvas.TranslateCoordinates(var InCoords : PPOINT;
  NumPoints : Integer);
var
  vCntr : Integer;
begin
  for vCntr := 0 to NumPoints -1 do begin
    InCoords[vCntr].X := round(InCoords[vCntr].X + FOffsetX);
    InCoords[vCntr].Y := round(InCoords[vCntr].Y + FOffsetY);
  end;
end;

function TEvsGraphCanvas.TranslatePoints(const InCoords :PPOINT; aNumPts :Integer) :PPOINT;
begin
  GetMem(Result, SizeOf(TPOINT)*aNumPts);
  Move(InCoords^, Result^, SizeOf(TPOINT)*aNumPts);
  TranslateCoordinates(Result, aNumPts);
end;

procedure TEvsGraphCanvas.DoMoveTo(x, y : integer);
var
  vPt : TPoint;
begin
  vPt := classes.Point(x,y);
  TranslateCoordinates(vPt);
  inherited DoMoveTo(vPt.x, vPt.y);
end;

procedure TEvsGraphCanvas.DoLineTo(x, y : integer);
var
  vPt : TPoint;
begin
  vPt := classes.Point(x,y);
  TranslateCoordinates(vPt);
  inherited DoLineTo(vPt.x, vPt.y);
end;

procedure TEvsGraphCanvas.DoLine(x1, y1, x2, y2: integer);
//var
//  vPts : array[0..1] of TPoint;
begin
  //vPts[0] := classes.Point(x1,y1);
  //vPts[1] := classes.Point(x2,y2);
  //TranslateCoordinates(vPts);
  ////----- doline uses moveto & lineto internally which are both translated.
  //inherited DoLine(vPts[0].x, vPts[0].y, vPts[1].x, vPts[1].y);
  inherited;
end;

procedure TEvsGraphCanvas.Arc(ALeft, ATop, ARight, ABottom, Angle16Deg,
  Angle16DegLength : Integer);
var
  vCoords : array[0..1] of TPOINT;
begin
  vCoords[0].x := ALeft;      vCoords[0].y := ATop;
  vCoords[1].x := ARight;     vCoords[1].y := ABottom;
  //vCoords[2].x := Angle16Deg; vCoords[2].y := Angle16DegLength;
  TranslateCoordinates(vCoords);
  inherited Arc(vCoords[0].x, vCoords[0].y, vCoords[1].x, vCoords[1].y, Angle16Deg, Angle16DegLength);
end;

procedure TEvsGraphCanvas.Arc(ALeft, ATop, ARight, ABottom, SX, SY, EX,
  EY : Integer);
var
  vCoords : array[0..3] of TPOINT;
begin
  vCoords[0].x := ALeft;      vCoords[0].y := ATop;
  vCoords[1].x := ARight;     vCoords[1].y := ABottom;
  vCoords[2].x := SX;         vCoords[2].y := SY;
  vCoords[3].x := EX;         vCoords[2].y := EY;
  TranslateCoordinates(vCoords);
  inherited Arc(vCoords[0].x, vCoords[0].y, vCoords[1].x, vCoords[1].y, vCoords[2].x, vCoords[2].x, vCoords[3].x, vCoords[3].x);
end;

procedure TEvsGraphCanvas.BrushCopy(ADestRect : TRect; ABitmap : Graphics.TBitmap;
  ASourceRect : TRect; ATransparentColor : TColor);
var
  vCoords : array[0..2] of TPOINT;
begin
  PRECT(@vCoords[0])^ := ADestRect;
  //PRECT(@vCoords[2])^ := ASourceRect;
  TranslateCoordinates(vCoords);
  inherited BrushCopy(PRECT(@vCoords[0])^, ABitmap, ASourceRect, ATransparentColor);
end;

procedure TEvsGraphCanvas.Chord(x1, y1, x2, y2, Angle16Deg,
  Angle16DegLength : Integer);
var
  vCoords : array[0..1] of TPOINT;
begin
  vCoords[0].x := x1;        vCoords[0].y := y1;
  vCoords[1].x := x2;        vCoords[1].y := y2;
  TranslateCoordinates(vCoords);
  inherited Chord(vCoords[0].x, vCoords[0].y, vCoords[1].x, vCoords[1].y, Angle16Deg, Angle16DegLength);
end;

procedure TEvsGraphCanvas.Chord(x1, y1, x2, y2, SX, SY, EX, EY : Integer);
var
  vCoords : array[0..3] of TPOINT;
begin
  vCoords[0].x := x1; vCoords[0].y := y1;
  vCoords[1].x := x2; vCoords[1].y := y2;
  vCoords[2].x := SX; vCoords[2].y := SY;
  vCoords[3].x := EX; vCoords[2].y := EY;
  TranslateCoordinates(vCoords);
  inherited Chord(vCoords[0].x, vCoords[0].y, vCoords[1].x, vCoords[1].y, vCoords[2].X, vCoords[2].Y, vCoords[3].X, vCoords[3].Y);
end;

procedure TEvsGraphCanvas.CopyRect(const Dest : TRect; SrcCanvas : TCanvas;
  const Source : TRect);
var
  vCoords : array[0..1] of TPOINT;
begin
  pRect(@vCoords[0])^ := Dest;
  TranslateCoordinates(vCoords);
  inherited CopyRect(pRect(@vCoords[0])^, SrcCanvas, Source);
end;

procedure TEvsGraphCanvas.Draw(X, Y : Integer; SrcGraphic : TGraphic);
var
  vCoords : TPOINT;
begin
  vCoords.x := X; vCoords.y := Y;
  TranslateCoordinates(vCoords);
  inherited Draw(vCoords.X, vCoords.Y, SrcGraphic);
end;

procedure TEvsGraphCanvas.DrawFocusRect(const ARect : TRect);
var
  vCoords : array[0..1] of TPOINT;
begin
  pRect(@vCoords[0])^ := ARect;
  TranslateCoordinates(vCoords);
  inherited DrawFocusRect(pRect(@vCoords[0])^);
end;

procedure TEvsGraphCanvas.StretchDraw(const DestRect : TRect;
  SrcGraphic : TGraphic);
var
  vCoords : array[0..1] of TPOINT;
begin
  pRect(@vCoords[0])^ := DestRect;
  TranslateCoordinates(vCoords);
  inherited StretchDraw(pRect(@vCoords[0])^, SrcGraphic);
end;

procedure TEvsGraphCanvas.Ellipse(x1, y1, x2, y2 : Integer);
var
  vCoords : array[0..1] of TPOINT;
begin
  vCoords[0].x := x1; vCoords[0].y := y1;
  vCoords[1].x := x2; vCoords[1].y := y2;
  TranslateCoordinates(vCoords);
  inherited Ellipse(vCoords[0].x, vCoords[0].y, vCoords[1].x, vCoords[1].y);
end;

procedure TEvsGraphCanvas.FillRect(const ARect : TRect);
var
  vCoords : array[0..1] of TPOINT;
begin
  pRect(@vCoords[0])^ := ARect;
  TranslateCoordinates(vCoords);
  inherited FillRect(pRect(@vCoords[0])^);
end;

procedure TEvsGraphCanvas.FloodFill(X, Y : Integer; FillColor : TColor;
  FillStyle : TFillStyle);
var
  vCoords : TPOINT;
begin
  vCoords.x := X; vCoords.y := Y;
  TranslateCoordinates(vCoords);
  inherited FloodFill(vCoords.X, vCoords.Y, FillColor, FillStyle);
end;

procedure TEvsGraphCanvas.Frame3d(var ARect : TRect;
  const FrameWidth : integer; const Style : TGraphicsBevelCut);
var
  vCoords : array[0..1] of TPOINT;
begin
  pRect(@vCoords[0])^ := ARect;
  TranslateCoordinates(vCoords);
  inherited Frame3d(pRect(@vCoords[0])^, FrameWidth, Style);
end;

procedure TEvsGraphCanvas.Frame(const ARect : TRect);
var
  vCoords : array[0..1] of TPOINT;
begin
  pRect(@vCoords[0])^ := ARect;
  TranslateCoordinates(vCoords);
  inherited Frame(pRect(@vCoords[0])^);
end;

procedure TEvsGraphCanvas.FrameRect(const ARect : TRect);
var
  vCoords : array[0..1] of TPOINT;
begin
  pRect(@vCoords[0])^ := ARect;
  TranslateCoordinates(vCoords);
  inherited FrameRect(pRect(@vCoords[0])^);
end;

procedure TEvsGraphCanvas.GradientFill(ARect : TRect; AStart, AStop : TColor; ADirection : TGradientDirection);
var
  vCoords : array[0..1] of TPOINT;
begin
  pRect(@vCoords[0])^ := ARect;
  TranslateCoordinates(vCoords);
  inherited GradientFill(pRect(@vCoords[0])^,AStart, AStop, ADirection);
end;

procedure TEvsGraphCanvas.RadialPie(x1, y1, x2, y2, StartAngle16Deg,
  Angle16DegLength : Integer);
var
  vCoords : array[0..1] of TPOINT;
begin
  vCoords[0].x := x1;        vCoords[0].y := y1;
  vCoords[1].x := x2;        vCoords[1].y := y2;
  TranslateCoordinates(vCoords);
  inherited RadialPie(vCoords[0].x, vCoords[0].y, vCoords[1].x, vCoords[1].y, StartAngle16Deg, Angle16DegLength);
end;

procedure TEvsGraphCanvas.Pie(EllipseX1, EllipseY1, EllipseX2, EllipseY2,
  StartX, StartY, EndX, EndY : Integer);
var
  vCoords : array[0..3] of TPOINT;
begin
  vCoords[0].x := EllipseX1; vCoords[0].y := EllipseY1;
  vCoords[1].x := EllipseX2; vCoords[1].y := EllipseY2;
  vCoords[2].x := StartX;    vCoords[2].y := StartY;
  vCoords[3].x := EndX;      vCoords[2].y := EndY;
  TranslateCoordinates(vCoords);
  inherited Pie(vCoords[0].x, vCoords[0].y, vCoords[1].x, vCoords[1].y, vCoords[2].x, vCoords[2].y, vCoords[3].x, vCoords[2].y);
end;

procedure TEvsGraphCanvas.PolyBezier(Points : PPoint; NumPts : Integer;
  Filled : boolean; Continuous : boolean);
var
  vTmp : PPOINT;
begin
  GetMem(vTmp, SizeOf(TPOINT) * NumPts);
  Move(Points^,vTmp^,sizeof(Tpoint)*NumPts);
  TranslateCoordinates(vTmp, NumPts);
  inherited PolyBezier(vTmp, NumPts, Filled, Continuous);
  Freemem(vTmp)
end;

procedure TEvsGraphCanvas.Polygon(Points : PPoint; NumPts : Integer;
  Winding : boolean);
var
  vTmp : PPOINT;
begin
  GetMem(vTmp,SizeOf(TPOINT) * NumPts);
  Move(Points^,vTmp^,sizeof(Tpoint)*NumPts);
  TranslateCoordinates(vTmp, NumPts);
  inherited Polygon(vTmp, NumPts, Winding);
  Freemem(vTmp)
end;

procedure TEvsGraphCanvas.Polyline(Points : PPoint; NumPts : Integer);
var
  vTmp : PPOINT;
begin
  GetMem(vTmp,SizeOf(TPOINT) * NumPts);
  Move(Points^,vTmp^,sizeof(Tpoint)*NumPts);
  TranslateCoordinates(vTmp, NumPts);
  inherited Polyline(vTmp, NumPts);
  Freemem(vTmp)
end;

constructor TEvsGraphCanvas.Create;
begin
  inherited Create;
end;

constructor TEvsGraphCanvas.Create(aCanvas :TCanvas);
begin
  Create;
  SetHandle(aCanvas.Handle);
  Pen.Assign(aCanvas.Pen);
  Brush.Assign(aCanvas.Brush);
  TextStyle := aCanvas.TextStyle;
end;

procedure TEvsGraphCanvas.Rectangle(X1, Y1, X2, Y2 : Integer);
var
  vCoords : array[0..1] of TPOINT;
begin
  vCoords[0].x := x1;        vCoords[0].y := y1;
  vCoords[1].x := x2;        vCoords[1].y := y2;
  TranslateCoordinates(vCoords);
  inherited Rectangle(vCoords[0].X, vCoords[0].Y, vCoords[1].X, vCoords[1].Y);
end;

procedure TEvsGraphCanvas.RoundRect(X1, Y1, X2, Y2 : Integer; RX, RY : Integer);
var
  vCoords : array[0..1] of TPOINT;
begin
  vCoords[0].x := x1;        vCoords[0].y := y1;
  vCoords[1].x := x2;        vCoords[1].y := y2;
  TranslateCoordinates(vCoords);
  inherited RoundRect(vCoords[0].X, vCoords[0].Y, vCoords[1].X, vCoords[1].Y, RX, RY);
end;

procedure TEvsGraphCanvas.TextOut(X, Y : Integer; const Text : String);
var
  vCoords : TPOINT;
begin
  vCoords.x := X; vCoords.y := Y;
  TranslateCoordinates(vCoords);
  inherited TextOut(vCoords.X, vCoords.Y, Text);
end;

procedure TEvsGraphCanvas.TextRect(ARect : TRect; X, Y : integer;
  const Text : string; const Style : TTextStyle);
var
  vCoords : array[0..2] of TPOINT;
begin
  pRect(@vCoords[0])^ := ARect;
  vCoords[2].x := X; vCoords[2].y := y;
  TranslateCoordinates(vCoords);
  inherited TextRect(pRect(@vCoords[0])^, vCoords[2].X, vCoords[2].Y, Text, Style);
end;

{$ENDREGION}


{$REGION ' TEvsCustomCanvas '}

procedure TEvsCustomCanvas.SetOffsetX(aValue : Double);
begin
  if FOffsetX = aValue then Exit;
  FOffsetX := aValue;
end;

procedure TEvsCustomCanvas.SetOffsetY(aValue : Double);
begin
  if FOffsetY = aValue then Exit;
  FOffsetY := aValue;
end;

procedure TEvsCustomCanvas.SetScaleX(aValue : Double);
begin
  if FScaleX = aValue then Exit;
  FScaleX := aValue;
end;

procedure TEvsCustomCanvas.SetScaleY(aValue : Double);
begin
  if FScaleY = aValue then Exit;
  FScaleY := aValue;
end;

procedure TEvsCustomCanvas.DoMoveTo(x, y : integer);
var
  vPts : TPoint;
begin
  vPts := classes.Point(x,y);
  TranslateCoordinates(vPts);
  inherited DoMoveTo(x, y);
end;

procedure TEvsCustomCanvas.DoLine(x1, y1, x2, y2 : integer);
var
  vPts : array[0..1] of TPoint;
begin
  vPts[0] := classes.Point(x1,y1);
  vPts[1] := classes.Point(x2,y2);
  TranslateCoordinates(vPts);
  inherited DoLine(vPts[0].x, vPts[0].y, vPts[1].x, vPts[1].y);
end;

procedure TEvsCustomCanvas.DoArc(ALeft, ATop, ARight, ABottom, Angle16Deg,
  Angle16DegLength : Integer);
begin
  inherited Arc(ALeft, ATop, ARight, ABottom, Angle16Deg, Angle16DegLength)
end;

procedure TEvsCustomCanvas.DoArc(ALeft, ATop, ARight, ABottom, SX, SY, EX,
  EY : Integer);
begin
  inherited Arc(ALeft,ATop, ARight, ABottom, SX, SY, EX, EY);
end;

procedure TEvsCustomCanvas.DoBrushCopy(ADestRect : TRect;
  ABitmap : Graphics.TBitmap; ASourceRect : TRect; ATransparentColor : TColor);
begin
  inherited BrushCopy(ADestRect, ABitmap, ASourceRect, ATransparentColor);
end;

procedure TEvsCustomCanvas.DoChord(X1, Y1, X2, Y2, Angle16Deg,
  Angle16DegLength : Integer);
begin
  inherited Chord(X1, Y1, X2, Y2, Angle16Deg, Angle16DegLength);
end;

procedure TEvsCustomCanvas.DoChord(X1, Y1, X2, Y2, SX, SY, EX, EY : Integer);
begin
  inherited Chord(X1, Y1, X2, Y2, SX, SY, EX, EY)
end;

procedure TEvsCustomCanvas.DoCopyRect(const Dest : TRect; SrcCanvas : TCanvas;
  const Source : TRect);
begin
  inherited CopyRect(Dest, SrcCanvas, Source);
end;

procedure TEvsCustomCanvas.DoDraw(X, Y : Integer; SrcGraphic : TGraphic);
begin
  inherited Draw(X, Y, SrcGraphic);
end;

procedure TEvsCustomCanvas.DoDrawFocusRect(const ARect : TRect);
begin
  inherited DrawFocusRect(ARect);
end;

procedure TEvsCustomCanvas.DoStretchDraw(const DestRect : TRect;
  SrcGraphic : TGraphic);
begin
  inherited StretchDraw(DestRect, SrcGraphic)
end;

procedure TEvsCustomCanvas.DoEllipse(x1, y1, x2, y2 : Integer);
begin
  inherited Ellipse(x1, y1, x2, y2);
end;

procedure TEvsCustomCanvas.DoFillRect(const ARect : TRect);
begin
  inherited FillRect(ARect);
end;

procedure TEvsCustomCanvas.DoFloodFill(X, Y : Integer; FillColor : TColor;
  FillStyle : TFillStyle);
begin
  inherited FloodFill(X, Y, FillColor, FillStyle);
end;

procedure TEvsCustomCanvas.DoFrame3d(var ARect : TRect;
  const FrameWidth : integer; const Style : TGraphicsBevelCut);
begin
  inherited Frame3d(ARect, FrameWidth, Style)
end;

procedure TEvsCustomCanvas.DoFrame(const ARect : TRect);
begin
  inherited Frame(ARect)
end;

procedure TEvsCustomCanvas.DoFrameRect(const ARect : TRect);
begin
  inherited FrameRect(ARect);
end;

procedure TEvsCustomCanvas.DoGradientFill(ARect : TRect; AStart,
  AStop : TColor; ADirection : TGradientDirection);
begin
  inherited GradientFill(aRect, AStart, AStop, ADirection);
end;

procedure TEvsCustomCanvas.DoRadialPie(X1, Y1, X2, Y2, StartAngle16Deg,
  Angle16DegLength : Integer);
begin
  inherited RadialPie(X1, Y1, X2, Y2, StartAngle16Deg, Angle16DegLength);
end;

procedure TEvsCustomCanvas.DoPie(EllipseX1, EllipseY1, EllipseX2, EllipseY2,
  StartX, StartY, EndX, EndY : Integer);
begin
  inherited Pie(EllipseX1, EllipseY1, EllipseX2, EllipseY2, StartX, StartY, EndX, EndY);
end;

procedure TEvsCustomCanvas.DoRectangle(X1, Y1, X2, Y2 : Integer);
begin
  inherited Rectangle(X1, Y1, X2, Y2);
end;

procedure TEvsCustomCanvas.DoRoundRect(X1, Y1, X2, Y2 : Integer; RX,
  RY : Integer);
begin
  inherited RoundRect(X1, Y1, X2, Y2, RX, RY);
end;

procedure TEvsCustomCanvas.DoTextOut(X, Y : Integer; const Text : String);
begin
  inherited TextOut(X, Y, Text);
end;

procedure TEvsCustomCanvas.DoTextRect(ARect : TRect; X, Y : integer;
  const Text : string; const Style : TTextStyle);
begin
  inherited TextRect(ARect, X, Y, Text, Style);
end;

procedure TEvsCustomCanvas.DoPolyBezier(Points : PPoint; NumPts : Integer;
  Filled : boolean; Continuous : boolean);
begin
  inherited PolyBezier(Points, NumPts, Filled, Continuous);
end;

procedure TEvsCustomCanvas.DoPolygon(Points : PPoint; NumPts : Integer;
  Winding : boolean);
begin
  inherited Polygon(Points, NumPts, Winding);
end;

procedure TEvsCustomCanvas.DoPolyline(Points : PPoint; NumPts : Integer);
begin
  inherited Polyline(Points, NumPts);
end;

procedure TEvsCustomCanvas.TranslateCoordinates(var InCoords : Array of TPOINT);
var
  vCntr : Integer;
  vX,vY   : double;
begin
  for vCntr := Low(InCoords) to High(InCoords) do begin
    vX := InCoords[vCntr].X; vY := InCoords[vCntr].Y;
    if (FScaleX <> 0)  then vX := vX * FScaleX;
    if (FScaleY <> 0)  then vY := vY * FScaleY;
    if (FOffsetX <> 0) then vX := vX + FOffsetX;
    if (FOffsetY <> 0) then vY := vY + FOffsetY;
    //if (FScaleX <> 0) or (FOffsetX <> 0) then InCoords[vCntr].X := round(vX);
    //if (FScaleY <> 0) or (FOffsetY <> 0) then InCoords[vCntr].Y := round(vY);
    InCoords[vCntr].X := round(vX);
    InCoords[vCntr].Y := round(vY);
  end;
end;

procedure TEvsCustomCanvas.TranslateCoordinates(var InCoords : PPOINT;
  NumPoints : Integer);
var
  vCntr : Integer;
begin
  for vCntr := 0 to NumPoints -1 do begin
    InCoords[vCntr].X := round(InCoords[vCntr].X + FOffsetX);
    InCoords[vCntr].Y := round(InCoords[vCntr].Y + FOffsetY);
  end;
end;

procedure TEvsCustomCanvas.Arc(ALeft, ATop, ARight, ABottom, Angle16Deg,
  Angle16DegLength : Integer);
var
  vCoords : array[0..1] of TPOINT;
begin
  vCoords[0].x := ALeft;      vCoords[0].y := ATop;
  vCoords[1].x := ARight;     vCoords[1].y := ABottom;
  //vCoords[2].x := Angle16Deg; vCoords[2].y := Angle16DegLength;
  TranslateCoordinates(vCoords);
  DoArc(vCoords[0].x, vCoords[0].y, vCoords[1].x, vCoords[1].y, Angle16Deg, Angle16DegLength);
end;

procedure TEvsCustomCanvas.Arc(ALeft, ATop, ARight, ABottom, SX, SY, EX,
  EY : Integer);
var
  vCoords : array[0..3] of TPOINT;
begin
  vCoords[0].x := ALeft;      vCoords[0].y := ATop;
  vCoords[1].x := ARight;     vCoords[1].y := ABottom;
  vCoords[2].x := SX;         vCoords[2].y := SY;
  vCoords[3].x := EX;         vCoords[2].y := EY;
  TranslateCoordinates(vCoords);
  DoArc(vCoords[0].x, vCoords[0].y, vCoords[1].x, vCoords[1].y, vCoords[2].x, vCoords[2].x, vCoords[3].x, vCoords[3].x);
end;

procedure TEvsCustomCanvas.BrushCopy(ADestRect : TRect; ABitmap : Graphics.TBitmap;
  ASourceRect : TRect; ATransparentColor : TColor);
var
  vCoords : array[0..2] of TPOINT;
begin
  PRECT(@vCoords[0])^ := ADestRect;
  //PRECT(@vCoords[2])^ := ASourceRect;
  TranslateCoordinates(vCoords);
  DoBrushCopy(PRECT(@vCoords[0])^, ABitmap, ASourceRect, ATransparentColor);
end;

procedure TEvsCustomCanvas.Chord(x1, y1, x2, y2, Angle16Deg,
  Angle16DegLength : Integer);
var
  vCoords : array[0..1] of TPOINT;
begin
  vCoords[0].x := x1;        vCoords[0].y := y1;
  vCoords[1].x := x2;        vCoords[1].y := y2;
  TranslateCoordinates(vCoords);
  DoChord(vCoords[0].x, vCoords[0].y, vCoords[1].x, vCoords[1].y, Angle16Deg, Angle16DegLength);
end;

procedure TEvsCustomCanvas.Chord(x1, y1, x2, y2, SX, SY, EX, EY : Integer);
var
  vCoords : array[0..3] of TPOINT;
begin
  vCoords[0].x := x1; vCoords[0].y := y1;
  vCoords[1].x := x2; vCoords[1].y := y2;
  vCoords[2].x := SX; vCoords[2].y := SY;
  vCoords[3].x := EX; vCoords[2].y := EY;
  TranslateCoordinates(vCoords);
  DoChord(vCoords[0].x, vCoords[0].y, vCoords[1].x, vCoords[1].y, vCoords[2].X, vCoords[2].Y, vCoords[3].X, vCoords[3].Y);
end;

procedure TEvsCustomCanvas.CopyRect(const Dest : TRect; SrcCanvas : TCanvas;
  const Source : TRect);
var
  vCoords : array[0..1] of TPOINT;
begin
  pRect(@vCoords[0])^ := Dest;
  TranslateCoordinates(vCoords);
  DoCopyRect(pRect(@vCoords[0])^, SrcCanvas, Source);
end;

procedure TEvsCustomCanvas.Draw(X, Y : Integer; SrcGraphic : TGraphic);
var
  vCoords : TPOINT;
begin
  vCoords.x := X; vCoords.y := Y;
  TranslateCoordinates(vCoords);
  DoDraw(vCoords.X, vCoords.Y, SrcGraphic);
end;

procedure TEvsCustomCanvas.DrawFocusRect(const ARect : TRect);
var
  vCoords : array[0..1] of TPOINT;
begin
  pRect(@vCoords[0])^ := ARect;
  TranslateCoordinates(vCoords);
  DoDrawFocusRect(pRect(@vCoords[0])^);
end;

procedure TEvsCustomCanvas.StretchDraw(const DestRect : TRect;
  SrcGraphic : TGraphic);
var
  vCoords : array[0..1] of TPOINT;
begin
  pRect(@vCoords[0])^ := DestRect;
  TranslateCoordinates(vCoords);
  DoStretchDraw(pRect(@vCoords[0])^, SrcGraphic);
end;

procedure TEvsCustomCanvas.Ellipse(x1, y1, x2, y2 : Integer);
var
  vCoords : array[0..1] of TPOINT;
begin
  vCoords[0].x := x1; vCoords[0].y := y1;
  vCoords[1].x := x2; vCoords[1].y := y2;
  TranslateCoordinates(vCoords);
  DoEllipse(vCoords[0].x, vCoords[0].y, vCoords[1].x, vCoords[1].y);
end;

procedure TEvsCustomCanvas.FillRect(const ARect : TRect);
var
  vCoords : array[0..1] of TPOINT;
begin
  pRect(@vCoords[0])^ := ARect;
  TranslateCoordinates(vCoords);
  DoFillRect(pRect(@vCoords[0])^);
end;

procedure TEvsCustomCanvas.FloodFill(X, Y : Integer; FillColor : TColor;
  FillStyle : TFillStyle);
var
  vCoords : TPOINT;
begin
  vCoords.x := X; vCoords.y := Y;
  TranslateCoordinates(vCoords);
  DoFloodFill(vCoords.X, vCoords.Y, FillColor, FillStyle);
end;

procedure TEvsCustomCanvas.Frame3d(var ARect : TRect;
  const FrameWidth : integer; const Style : TGraphicsBevelCut);
var
  vCoords : array[0..1] of TPOINT;
begin
  pRect(@vCoords[0])^ := ARect;
  TranslateCoordinates(vCoords);
  DoFrame3d(pRect(@vCoords[0])^, FrameWidth, Style);
end;

procedure TEvsCustomCanvas.Frame(const ARect : TRect);
var
  vCoords : array[0..1] of TPOINT;
begin
  pRect(@vCoords[0])^ := ARect;
  TranslateCoordinates(vCoords);
  DoFrame(pRect(@vCoords[0])^);
end;

procedure TEvsCustomCanvas.FrameRect(const ARect : TRect);
var
  vCoords : array[0..1] of TPOINT;
begin
  pRect(@vCoords[0])^ := ARect;
  TranslateCoordinates(vCoords);
  DoFrameRect(pRect(@vCoords[0])^);
end;

procedure TEvsCustomCanvas.GradientFill(ARect : TRect; AStart, AStop : TColor; ADirection : TGradientDirection);
var
  vCoords : array[0..1] of TPOINT;
begin
  pRect(@vCoords[0])^ := ARect;
  TranslateCoordinates(vCoords);
  DoGradientFill(pRect(@vCoords[0])^,AStart, AStop, ADirection);
end;

procedure TEvsCustomCanvas.RadialPie(x1, y1, x2, y2, StartAngle16Deg,
  Angle16DegLength : Integer);
var
  vCoords : array[0..1] of TPOINT;
begin
  vCoords[0].x := x1;        vCoords[0].y := y1;
  vCoords[1].x := x2;        vCoords[1].y := y2;
  TranslateCoordinates(vCoords);
  DoRadialPie(vCoords[0].x, vCoords[0].y, vCoords[1].x, vCoords[1].y, StartAngle16Deg, Angle16DegLength);
end;

procedure TEvsCustomCanvas.Pie(EllipseX1, EllipseY1, EllipseX2, EllipseY2,
  StartX, StartY, EndX, EndY : Integer);
var
  vCoords : array[0..3] of TPOINT;
begin
  vCoords[0].x := EllipseX1; vCoords[0].y := EllipseY1;
  vCoords[1].x := EllipseX2; vCoords[1].y := EllipseY2;
  vCoords[2].x := StartX;    vCoords[2].y := StartY;
  vCoords[3].x := EndX;      vCoords[2].y := EndY;
  TranslateCoordinates(vCoords);
  DoPie(vCoords[0].x, vCoords[0].y, vCoords[1].x, vCoords[1].y, vCoords[2].x, vCoords[2].y, vCoords[3].x, vCoords[2].y);
end;

procedure TEvsCustomCanvas.PolyBezier(Points : PPoint; NumPts : Integer;
  Filled : boolean; Continuous : boolean);
var
  vTmp : PPOINT;
begin
  GetMem(vTmp, SizeOf(TPOINT) * NumPts);
  try
    Move(Points^,vTmp^,sizeof(Tpoint)*NumPts);
    TranslateCoordinates(vTmp, NumPts);
    DoPolyBezier(vTmp, NumPts, Filled, Continuous);
  finally
    Freemem(vTmp)
  end;
end;

procedure TEvsCustomCanvas.Polygon(Points : PPoint; NumPts : Integer;
  Winding : boolean);
var
  vTmp : PPOINT;
begin
  GetMem(vTmp,SizeOf(TPOINT) * NumPts);
  try
    Move(Points^,vTmp^,sizeof(Tpoint)*NumPts);
    TranslateCoordinates(vTmp, NumPts);
    DoPolygon(vTmp, NumPts, Winding);
  finally
    Freemem(vTmp)
  end;
end;

procedure TEvsCustomCanvas.Polyline(Points : PPoint; NumPts : Integer);
var
  vTmp : PPOINT;
begin
  GetMem(vTmp,SizeOf(TPOINT) * NumPts);
  try
    Move(Points^,vTmp^,sizeof(Tpoint)*NumPts);
    TranslateCoordinates(vTmp, NumPts);
    DoPolyline(vTmp, NumPts);
  finally
    Freemem(vTmp)
  end;
end;

constructor TEvsCustomCanvas.Create;
begin
  inherited Create;
  FOffsetX := 0.0; FOffsetY := 0.0; FScaleX := 0.0; FScaleY := 0.0;
end;

procedure TEvsCustomCanvas.SetTransformation(XScale, YScale, DX, DY : Double);
begin
  FScaleX := XScale; FScaleY := YScale; FOffsetX := DX; FOffsetY := DY;
end;

procedure TEvsCustomCanvas.ClearTransformation;
begin
  SetTransformation(0.0,0.0,0.0,0.0);
end;

procedure TEvsCustomCanvas.Rectangle(X1, Y1, X2, Y2 : Integer);
var
  vCoords : array[0..1] of TPOINT;
begin
  vCoords[0].x := x1; vCoords[0].y := y1;
  vCoords[1].x := x2; vCoords[1].y := y2;
  TranslateCoordinates(vCoords);
  DoRectangle(vCoords[0].X, vCoords[0].Y, vCoords[1].X, vCoords[1].Y);
end;

procedure TEvsCustomCanvas.RoundRect(X1, Y1, X2, Y2 : Integer; RX, RY : Integer);
var
  vCoords : array[0..1] of TPOINT;
begin
  vCoords[0].x := x1; vCoords[0].y := y1;
  vCoords[1].x := x2; vCoords[1].y := y2;
  TranslateCoordinates(vCoords);
  DoRoundRect(vCoords[0].X, vCoords[0].Y, vCoords[1].X, vCoords[1].Y, RX, RY);
end;

procedure TEvsCustomCanvas.TextOut(X, Y : Integer; const Text : String);
var
  vCoords : TPOINT;
begin
  vCoords.x := X; vCoords.y := Y;
  TranslateCoordinates(vCoords);
  DoTextOut(vCoords.X, vCoords.Y, Text);
end;

procedure TEvsCustomCanvas.TextRect(ARect : TRect; X, Y : integer;
  const Text : string; const Style : TTextStyle);
var
  vCoords : array[0..2] of TPOINT;
begin
  pRect(@vCoords[0])^ := ARect;
  vCoords[2].x := X; vCoords[2].y := y;
  TranslateCoordinates(vCoords);
  DoTextRect(pRect(@vCoords[0])^, vCoords[2].X, vCoords[2].Y, Text, Style);
end;

{$ENDREGION}

procedure _RegisterClasses;
begin
  TEvsSimpleGraph.Register(TEvsGraphLink);
  TEvsSimpleGraph.Register(TEVSBezierLink);
  TEvsSimpleGraph.Register(TEvsRectangularNode);
  TEvsSimpleGraph.Register(TEvsRoundRectangularNode);
  TEvsSimpleGraph.Register(TEvsEllipticNode);
  TEvsSimpleGraph.Register(TEvsTriangularNode);
  TEvsSimpleGraph.Register(TEvsRhomboidalNode);
  TEvsSimpleGraph.Register(TEvsPentagonalNode);
  TEvsSimpleGraph.Register(TEvsHexagonalNode);
end;
procedure _UnRegisterClasses;
begin
  TEvsSimpleGraph.Unregister(TEvsGraphLink);
  TEvsSimpleGraph.Unregister(TEVSBezierLink);
  TEvsSimpleGraph.Unregister(TEvsRectangularNode);
  TEvsSimpleGraph.Unregister(TEvsRoundRectangularNode);
  TEvsSimpleGraph.Unregister(TEvsEllipticNode);
  TEvsSimpleGraph.Unregister(TEvsTriangularNode);
  TEvsSimpleGraph.Unregister(TEvsRhomboidalNode);
  TEvsSimpleGraph.Unregister(TEvsPentagonalNode);
  TEvsSimpleGraph.Unregister(TEvsHexagonalNode);
end;

initialization
  // Loads Custom Cursors
  Screen.Cursors[crHandFlat]  := LoadCursor(HInstance, 'SG_HANDFLAT');
  Screen.Cursors[crHandGrab]  := LoadCursor(HInstance, 'SG_HANDGRAB');
  Screen.Cursors[crHandPnt]   := LoadCursor(HInstance, 'SG_HANDPNT');
  Screen.Cursors[crXHair1]    := LoadCursor(HInstance, 'SG_XHAIR1');
  Screen.Cursors[crXHair2]    := LoadCursor(HInstance, 'SG_XHAIR2');
  Screen.Cursors[crXHair3]    := LoadCursor(HInstance, 'SG_XHAIR3');
  Screen.Cursors[crXHairLink] := LoadCursor(HInstance, 'SG_XHAIRLINK');
  // Registers Clipboard Format
  CF_SIMPLEGRAPH := RegisterClipboardFormat('Simple Graph Format');
  // Registers Link and Node classes
  _RegisterClasses;

finalization
  if Assigned(RegisteredLinkClasses) then RegisteredLinkClasses.Free;
  if Assigned(RegisteredNodeClasses) then RegisteredNodeClasses.Free;
end.
