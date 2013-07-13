unit UfrmSimpleGraphTest;

{$mode objfpc}{$H+}

interface
{$DEFINE SIMPLEGRAPH_CREATION}
uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, LMessages, LCLType,
  LCLIntf, StdCtrls, ComCtrls, ActnList, Menus, Clipbrd,

  UEvsSimpleGraph;
const
  {$IFDEF  LCLWIN32}
    EvsActiveWidgetSet = 'Win32';
  {$ELSE}
    {$IFDEF LCLQT}
      EvsActiveWidgetSet = 'QT';
    {$ELSE}
      {$IFDEF LCLGTK2}
         EvsActiveWidgetSet = 'GTK2';
      {$ELSE}
         EvsActiveWidgetSet = 'UnSupported';
      {$ENDIF}
    {$ENDIF}
  {$ENDIF}


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
    actCopy : TAction;
    actCopyBmp : TAction;
    actDeleteSelected : TAction;
    actSelectAll : TAction;
    actPaste : TAction;
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
    ToolButton10 : TToolButton;
    ToolButton11 : TToolButton;
    ToolButton12 : TToolButton;
    ToolButton13 : TToolButton;
    ToolButton2 : TToolButton;
    ToolButton3 : TToolButton;
    ToolButton4 : TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8 : TToolButton;
    ToolButton9 : TToolButton;
    procedure actCopyBmpExecute(Sender : TObject);
    procedure actCopyBmpUpdate(Sender : TObject);
    procedure actCopyExecute(Sender : TObject);
    procedure actCopyUpdate(Sender : TObject);
    procedure actDeleteSelectedExecute(Sender : TObject);
    procedure actPasteExecute(Sender : TObject);
    procedure actPasteUpdate(Sender : TObject);
    procedure actSelectAllExecute(Sender : TObject);
    procedure actSelectAllUpdate(Sender : TObject);
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
    procedure ToolButton3Click(Sender : TObject);
  private
    { private declarations }
    Test : TEvsSimpleGraph;
  protected
  public
    { public declarations }
    constructor Create(aOwner:TComponent);override;
    procedure goDblClick(Graph: TEvsSimpleGraph; GraphObject: TEvsGraphObject);
    //procedure goDblClick2(Graph: TSimpleGraph; GraphObject: TGraphObject);
  end;

var
  Form1 : TForm1; 

implementation
uses {windows, freetype, IniFiles,} uFrmDebug;

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
  //if assigned(Test) then Test.ChangeZoomBy(10, UEvsSimpleGraph.zoCenter);
end;

procedure TForm1.actZoom1Update(Sender : TObject);
begin
  //if assigned(Test) then actZoom1.Enabled := (Test.Zoom <> 100) else actZoom1.Enabled := False;
end;

procedure TForm1.actCopyUpdate(Sender : TObject);
begin
  actCopy.Enabled := Test.SelectedObjects.Count > 0;
end;

procedure TForm1.actDeleteSelectedExecute(Sender : TObject);
var
  vCntr : Integer;
begin
  for vCntr := Test.SelectedObjects.Count -1 downto 0 do
    Test.SelectedObjects[vCntr].Delete;
end;

procedure TForm1.actPasteExecute(Sender : TObject);
begin
  Test.PasteFromClipboard;
end;

procedure TForm1.actPasteUpdate(Sender : TObject);
begin
  actPaste.Enabled := Clipboard.HasFormat(CF_SIMPLEGRAPH);
end;

procedure TForm1.actSelectAllExecute(Sender : TObject);
var
  vCntr : Integer;
begin
  for vCntr := Test.Objects.Count -1 downto 0 do
    Test.Objects[vCntr].Selected := True;
end;

procedure TForm1.actSelectAllUpdate(Sender : TObject);
begin
  actSelectAll.Enabled := Test.Objects.Count > 0;
end;

procedure TForm1.actCopyExecute(Sender : TObject);
var
  vTmp : TEvsGraphClipboardFormats;
begin
  vTmp := Test.ClipboardFormats;
  Test.ClipboardFormats := [cfNative];
  Test.CopyToClipboard();
  Test.ClipboardFormats := vTmp;
end;

procedure TForm1.actCopyBmpUpdate(Sender : TObject);
begin
  actCopyBmp.Enabled := test.SelectedObjects.Count>0;
end;

procedure TForm1.actCopyBmpExecute(Sender : TObject);
var
  vTmp : TEvsGraphClipboardFormats;
begin
  vTmp := Test.ClipboardFormats;
  Test.ClipboardFormats := [cfBitmap];
  Test.CopyToClipboard();
  Test.ClipboardFormats := vTmp;
end;

procedure TForm1.actZoomInUpdate(Sender : TObject);
begin
  //actZoomIn.Enabled := assigned(test) and (Test.Zoom < High(TZoom));
end;

procedure TForm1.actZoomOutExecute(Sender: TObject);
begin
  //if assigned(test) then begin
  //  Test.ChangeZoomBy(-10, UEvsSimpleGraph.zoCenter);
  //end;
end;

procedure TForm1.actZoom1Execute(Sender: TObject);
begin
  //if assigned(Test) then begin
  //  Test.ChangeZoom(100, UEvsSimpleGraph.zoTopLeft);
  //end;
end;

procedure TForm1.Action4Execute(Sender: TObject);
begin
  if assigned(Test) then begin
    test.DefaultNodeClass:=TEvsHexagonalNode;
    test.CommandMode:=UEvsSimpleGraph.cmInsertNode;
  end;
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
  //actZoomOut.Enabled := (Test.Zoom > Low(TZoom));
end;

procedure TForm1.FormMouseMove(Sender : TObject; Shift : TShiftState; X,
  Y : Integer);
begin
  //
  Caption := EvsActiveWidgetSet + ' - ' + Format('Mouse.X %D Mouse.Y %D',[X,Y]);
end;

procedure TForm1.MenuItem1Click(Sender: TObject);
begin
  if Assigned(Test) then begin
    Test.DefaultNodeClass:=TEvsSimpleGraph.NodeClasses(TMenuItem(Sender).Tag-1);
    test.CommandMode:=UEvsSimpleGraph.cmInsertNode;
  end;
end;

procedure TForm1.MenuItem2Click(Sender : TObject);
begin
  if Assigned(Test) then begin
    Test.DefaultLinkClass:=TEvsSimpleGraph.LinkClasses(TMenuItem(Sender).Tag-1-cLinkStart);
    Test.CommandMode:=UEvsSimpleGraph.cmInsertLink;
  end;
end;

procedure TForm1.ToolButton3Click(Sender : TObject);
begin
  if dlgSave.Execute then
    Test.SaveToFile(dlgSave.FileName);
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
  Mnu.Caption:= '-';

  for Cnt := 0 to TEvsSimpleGraph.LinkClassCount -1 do begin
    Mnu := TMenuItem.Create(Self);
    pmnuGraphClasses.Items.Add(Mnu);
    Mnu.Tag := cLinkStart+Cnt+1;
    Mnu.OnClick:=@MenuItem2Click;
    Mnu.Caption:= Copy(TEvsSimpleGraph.LinkClasses(Cnt).ClassName,5,255);
  end;

  Test.OnObjectDblClick := @goDblClick;
  {$ENDIF}

  Caption := caption + '-' + EvsActiveWidgetSet;
end;

procedure TForm1.goDblClick(Graph : TEvsSimpleGraph;
  GraphObject : TEvsGraphObject);
begin
  GraphObject.Text := InputBox(GraphObject.ClassName, 'Enter Caption', GraphObject.Text);
  Self.Visible := True;
  Self.WindowState := wsNormal;
  BringToFront;
end;

//procedure TForm1.goDblClick2(Graph : TSimpleGraph; GraphObject : TGraphObject);
//begin
//  //GraphObject.Text := InputBox(GraphObject.ClassName, 'Enter Caption', GraphObject.Text);
//  //Self.Visible := True;
//  //Self.WindowState := wsNormal;
//  //BringToFront;
//end;

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

