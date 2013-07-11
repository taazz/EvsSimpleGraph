unit UfrmSimpleGraphTest;

{$mode objfpc}{$H+}

interface
{$DEFINE SIMPLEGRAPH_CREATION}
uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, LMessages, LCLType,
  LCLIntf, StdCtrls, ComCtrls, ActnList, Menus,

  UEvsSimpleGraph;

type

  { TTestForm }

  TTestForm = class(TForm)
  private
    fTest : TComboBox;
  public
    constructor Create(TheOwner : TComponent); override;
  end;

  { TForm1 }

  TForm1 = class(TForm)
    actZoomIn: TAction;
    actZoomOut: TAction;
    actZoom1: TAction;
    actDebugForm: TAction;
    actLoad : TAction;
    ActionList1: TActionList;
    ImageList1: TImageList;
    MenuItem1 : TMenuItem;
    MenuItem2 : TMenuItem;
    MenuItem3 : TMenuItem;
    MenuItem4 : TMenuItem;
    MenuItem5 : TMenuItem;
    MenuItem6 : TMenuItem;
    OpenDialog1 : TOpenDialog;
    pmnuGraphClasses: TPopupMenu;
    pmnuZoom : TPopupMenu;
    dlgSave : TSaveDialog;
    ToolBar1: TToolBar;
    ToolButton1 : TToolButton;
    ToolButton2 : TToolButton;
    ToolButton3 : TToolButton;
    ToolButton4 : TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton9 : TToolButton;
    procedure actZoom1Update(Sender : TObject);
    procedure actZoomInExecute(Sender: TObject);
    procedure actZoomInUpdate(Sender : TObject);
    procedure actZoomOutExecute(Sender: TObject);
    procedure actZoom1Execute(Sender: TObject);
    procedure Action4Execute(Sender: TObject);
    procedure actDebugFormExecute(Sender: TObject);
    procedure actLoadExecute(Sender : TObject);
    procedure actZoomOutUpdate(Sender : TObject);
    procedure FormMouseMove(Sender : TObject; Shift : TShiftState; X,
      Y : Integer);
    procedure MenuItem1Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure MenuItem6Click(Sender : TObject);
    procedure ToolButton3Click(Sender : TObject);
    procedure ToolButton4Click(Sender : TObject);
  private
    { private declarations }
    Test : TEvsSimpleGraph;
    //FTemp : TScrollingWinControl
  protected
    //procedure WMPaint(var Message: TLMPaint); message LM_PAINT;
    procedure Print(const aMsg:string);
  public
    { public declarations }
    constructor Create(aOwner:TComponent);override;
    procedure goDblClick(Graph: TEvsSimpleGraph; GraphObject: TEvsGraphObject);
  end;

var
  Form1 : TForm1; 

implementation
uses {windows, freetype, IniFiles,} uFrmDebug, UEvsMisc, uevsRegionTests,
  uEvsBackupClasses;

{$R *.lfm}
const
  cLinkStart = 1000;

procedure SaveScreenShot(const aFilename:string);
var
  ScreenDC   : HDC;
  SaveBitmap : TBitmap;
  SB         : TScrollBar;
begin
  SaveBitmap := TBitmap.Create;
  try
    SaveBitmap.SetSize(Screen.Width, Screen.Height);
    ScreenDC := GetDC(0);
    try
      SaveBitmap.LoadFromDevice(ScreenDC);
    finally
      ReleaseDC(0, ScreenDC);
    end;
    SaveBitmap.SaveToFile(aFilename);
  finally
    SaveBitmap.Free;
  end;
end;

{ TForm1 }

procedure TForm1.actZoomInExecute(Sender: TObject);
begin
  Test.ChangeZoomBy(10, zoCenter);
  //windows.WNDPROC;
end;

procedure TForm1.actZoom1Update(Sender : TObject);
begin
  actZoom1.Enabled := (Test.Zoom <> 100);
end;

procedure TForm1.actZoomInUpdate(Sender : TObject);
begin
  actZoomIn.Enabled := (Test.Zoom < High(TZoom));
end;

procedure TForm1.actZoomOutExecute(Sender: TObject);
begin
  Test.ChangeZoomBy(-10, zoCenter);
end;

procedure TForm1.actZoom1Execute(Sender: TObject);
begin
  Test.ChangeZoom(100, zoTopLeft);
end;

procedure TForm1.Action4Execute(Sender: TObject);
begin
  test.DefaultNodeClass:=TEvsHexagonalNode;
  test.CommandMode:=cmInsertNode;
end;

procedure TForm1.actDebugFormExecute(Sender: TObject);
var
  Tmp : TForm = nil;

begin
  Tmp:= dbgFrm;

  if Tmp.Visible then
    Tmp.Hide
  else begin
    Tmp.PopupMode   := pmExplicit;
    Tmp.PopupParent := Self;
    Tmp.Show;
  end;

end;

procedure TForm1.actLoadExecute(Sender : TObject);
begin
  if OpenDialog1.Execute then Test.LoadFromFile(OpenDialog1.FileName);
end;

procedure TForm1.actZoomOutUpdate(Sender : TObject);
begin
  actZoomOut.Enabled := (Test.Zoom > Low(TZoom));
end;

procedure TForm1.FormMouseMove(Sender : TObject; Shift : TShiftState; X,
  Y : Integer);
begin
  //
  Caption := EvsActiveWidgetSet + ' - ' + Format('Mouse.X %D Mouse.Y %D',[X,Y]);
end;

procedure TForm1.MenuItem1Click(Sender: TObject);
begin
  Test.DefaultNodeClass:=TEvsSimpleGraph.NodeClasses(TMenuItem(Sender).Tag-1);
  test.CommandMode:=cmInsertNode;
end;

procedure TForm1.MenuItem2Click(Sender : TObject);
begin
  Test.DefaultLinkClass:=TEvsSimpleGraph.LinkClasses(TMenuItem(Sender).Tag-1-cLinkStart);
  Test.CommandMode:=cmInsertLink;
end;

procedure TForm1.MenuItem6Click(Sender : TObject);
var
  vFrm :TForm3;
begin
  vFrm := TForm3.Create(nil);
  try
    vFrm.ShowModal;
  finally
    vFrm.Free;
  end;
end;

procedure TForm1.ToolButton3Click(Sender : TObject);
begin
  if dlgSave.Execute then
    Test.SaveToFile(dlgSave.FileName);
end;

procedure TForm1.ToolButton4Click(Sender : TObject);
var
  vFrm : TForm;
  vGruard : IGuardian = Nil;
begin
  vFrm := TForm3.Create(Nil);
  Guard(vFrm, vGruard);
  vFrm.ShowModal;
end;

procedure TForm1.Print(const aMsg: string);
begin
  uFrmDebug.EvsDbgPrint(aMsg);
end;

constructor TForm1.Create(aOwner : TComponent);
VAR
  tmp : UnicodeString;
  Mnu : TMenuItem;
  Cnt: Integer;
begin
  inherited Create(Owner);
  {$IFDEF SIMPLEGRAPH_CREATION}
  Test := TEvsSimpleGraph.Create(Self);
  Test.Parent:= Self;
  Test.Width := 300;
  Test.Height := 300;
  Test.Align := alClient;//alRight;
  Test.Color := clWhite;
  //Test.Brush.Color:=clWhite;
  test.BorderStyle:= bsSingle;
  test.ShowGrid:=True;
  Test.DoubleBuffered:=True;
  //Test.HorzScrollBar.Smooth:=True;
  //Test.VertScrollBar.Smooth:=True;
  Test.OnMouseMove := @FormMouseMove;
  Test.HorzScrollBar.Tracking:=True;
  Test.VertScrollBar.Tracking:=True;

  pmnuGraphClasses.Items.Clear;
  for Cnt := 0 to TEvsSimpleGraph.NodeClassCount -1 do begin
    Mnu := TMenuItem.Create(Self);
    pmnuGraphClasses.Items.Add(Mnu);
    Mnu.Tag := Cnt+1;
    Mnu.OnClick:=@MenuItem1Click;
    Mnu.Caption:= Copy(TEvsSimpleGraph.NodeClasses(Cnt).ClassName,5,255);
  end;

  Mnu := TMenuItem.Create(Self);
  pmnuGraphClasses.Items.Add(Mnu);
  //Mnu.Tag := Cnt+1;
  //Mnu.OnClick:=@MenuItem1Click;
  Mnu.Caption:= '-';//Copy(TEvsSimpleGraph.NodeClasses(Cnt).ClassName,5,255);

  for Cnt := 0 to TEvsSimpleGraph.LinkClassCount -1 do begin
    Mnu := TMenuItem.Create(Self);
    pmnuGraphClasses.Items.Add(Mnu);
    Mnu.Tag := cLinkStart+Cnt+1;
    Mnu.OnClick:=@MenuItem2Click;
    Mnu.Caption:= Copy(TEvsSimpleGraph.LinkClasses(Cnt).ClassName,5,255);
  end;

  Test.OnObjectDblClick := @goDblClick;
  {$ENDIF}

  //TestCtrl := TTestControl.Create(Self);
  //TestCtrl.Align:=alClient;
  //TestCtrl.Parent  := Self;
  //TestCtrl.Visible := True;
  Caption := caption +'-' +uevsmisc.EvsActiveWidgetSet;
  Form1.Cursor:=Screen.Cursors[2];
  screen.Cursor:=screen.Cursors[2];
end;

procedure TForm1.goDblClick(Graph : TEvsSimpleGraph;
  GraphObject : TEvsGraphObject);
begin
  GraphObject.Text := InputBox(GraphObject.ClassName, 'Enter Caption', GraphObject.Text);
  Self.Visible := True;
  Self.WindowState := wsNormal;
  BringToFront;
end;

{ TTestForm }

constructor TTestForm.Create(TheOwner : TComponent);
begin
  inherited Create(TheOwner);
  fTest := TComboBox.Create(Self);
  fTest.Left := 100;
  fTest.Top  := 10;
  fTest.Parent := Self;
end;

end.

