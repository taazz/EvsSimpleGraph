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
    actExit : TAction;
    actEditCopy : TAction;
    actCopyBmp : TAction;
    actEditDeleteSelected : TAction;
    ActGraphNew : TAction;
    actGraphSave : TAction;
    actGraphSaveAs : TAction;
    actEditCut : TAction;
    actEditSelectAll : TAction;
    actEditPaste : TAction;
    actEditZoomIn: TAction;
    actEditZoomOut: TAction;
    actDebugForm: TAction;
    actGraphOpen : TAction;
    actGraphImport : TAction;
    actEllipse : TAction;
    actHexagonNode : TAction;
    actBezierLink : TAction;
    actGraphPan : TAction;
    actViewGrid : TAction;
    actObjLockNodes : TAction;
    actObjLockLinks : TAction;
    actSelection : TAction;
    actPolyLineLink : TAction;
    actPentagonNode : TAction;
    actRhomboidNode : TAction;
    actTriangularNode : TAction;
    actRoundRectNode : TAction;
    actRectNode : TAction;
    ActionList: TActionList;
    ImageList : TImageList;
    ImageList1: TImageList;
    dlgOpen : TOpenDialog;
    dlgSave : TSaveDialog;
    ToolBar1: TToolBar;
    ToolBar2 : TToolBar;
    ToolButton1 : TToolButton;
    ToolButton10 : TToolButton;
    ToolButton11 : TToolButton;
    ToolButton12 : TToolButton;
    btnCut : TToolButton;
    btnNew : TToolButton;
    btnSaveAs : TToolButton;
    btnSave : TToolButton;
    btnCopy : TToolButton;
    ToolButton13 : TToolButton;
    ToolButton14 : TToolButton;
    tbtnSelection : TToolButton;
    ToolButton16 : TToolButton;
    ToolButton17 : TToolButton;
    ToolButton18 : TToolButton;
    ToolButton19 : TToolButton;
    tbtnRectNode : TToolButton;
    tbtnRoundRectNode : TToolButton;
    tbtnEllipseNode : TToolButton;
    ToolButton2 : TToolButton;
    ToolButton3 : TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    btnPaste: TToolButton;
    btnDelete : TToolButton;
    btnOpen : TToolButton;
    tbtnTRiangularNode : TToolButton;
    ToolButton8 : TToolButton;
    ToolButton9 : TToolButton;
    procedure actBezierLinkExecute(Sender : TObject);
    procedure actBezierLinkUpdate(Sender : TObject);
    procedure actCopyBmpExecute(Sender : TObject);
    procedure actCopyBmpUpdate(Sender : TObject);
    procedure actEllipseExecute(Sender : TObject);
    procedure actEllipseUpdate(Sender : TObject);
    procedure actExitExecute(Sender : TObject);
    procedure actEditCopyExecute(Sender : TObject);
    procedure actEditCopyUpdate(Sender : TObject);
    procedure actEditCutExecute(Sender : TObject);
    procedure actEditCutUpdate(Sender : TObject);
    procedure actEditDeleteSelectedExecute(Sender : TObject);
    procedure actGraphImportExecute(Sender : TObject);
    procedure ActGraphNewExecute(Sender : TObject);
    procedure actGraphSaveAsExecute(Sender : TObject);
    procedure actGraphSaveExecute(Sender : TObject);
    procedure actEditPasteExecute(Sender : TObject);
    procedure actEditPasteUpdate(Sender : TObject);
    procedure actEditSelectAllExecute(Sender : TObject);
    procedure actEditSelectAllUpdate(Sender : TObject);
    procedure actHexagonNodeExecute(Sender : TObject);
    procedure actHexagonNodeUpdate(Sender : TObject);
    procedure actObjLockLinksExecute(Sender : TObject);
    procedure actObjLockLinksUpdate(Sender : TObject);
    procedure actObjLockNodesExecute(Sender : TObject);
    procedure actObjLockNodesUpdate(Sender : TObject);
    procedure actPentagonNodeExecute(Sender : TObject);
    procedure actPentagonNodeUpdate(Sender : TObject);
    procedure actPolyLineLinkExecute(Sender : TObject);
    procedure actPolyLineLinkUpdate(Sender : TObject);
    procedure actRectNodeExecute(Sender : TObject);
    procedure actRectNodeUpdate(Sender : TObject);
    procedure actRhomboidNodeExecute(Sender : TObject);
    procedure actRhomboidNodeUpdate(Sender : TObject);
    procedure actRoundRectNodeExecute(Sender : TObject);
    procedure actRoundRectNodeUpdate(Sender : TObject);
    procedure actSelectionExecute(Sender : TObject);
    procedure actSelectionUpdate(Sender : TObject);
    procedure actTriangularNodeExecute(Sender : TObject);
    procedure actTriangularNodeUpdate(Sender : TObject);
    procedure actViewGridExecute(Sender : TObject);
    procedure actViewGridUpdate(Sender : TObject);
    procedure actZoom1Update(Sender : TObject);
    procedure actEditZoomInExecute(Sender: TObject);
    procedure actEditZoomInUpdate(Sender : TObject);
    procedure actEditZoomOutExecute(Sender: TObject);
    procedure actZoom1Execute(Sender: TObject);
    procedure Action4Execute(Sender: TObject);
    procedure actDebugFormExecute(Sender: TObject);
    procedure actGraphOpenExecute(Sender : TObject);
    procedure actEditZoomOutUpdate(Sender : TObject);
    procedure FormMouseMove(Sender : TObject; Shift : TShiftState; X,
      Y : Integer);
    procedure MenuItem1Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
  private
    { private declarations }
    Test : TEvsSimpleGraph;
    FFileName : String;
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

procedure TForm1.actEditZoomInExecute(Sender: TObject);
begin
  //if assigned(Test) then Test.ChangeZoomBy(10, UEvsSimpleGraph.zoCenter);
end;

procedure TForm1.actZoom1Update(Sender : TObject);
begin
  //if assigned(Test) then actZoom1.Enabled := (Test.Zoom <> 100) else actZoom1.Enabled := False;
end;

procedure TForm1.actEditCopyUpdate(Sender : TObject);
begin
  actEditCopy.Enabled := Test.SelectedObjects.Count > 0;
end;

procedure TForm1.actEditCutExecute(Sender : TObject);
begin
  actEditCopy.Execute;
  actEditDeleteSelected.Execute;
end;

procedure TForm1.actEditCutUpdate(Sender : TObject);
begin
  actEditCut.Enabled := Test.SelectedObjects.Count > 0;
end;

procedure TForm1.actEditDeleteSelectedExecute(Sender : TObject);
var
  vCntr : Integer;
begin
  for vCntr := Test.SelectedObjects.Count -1 downto 0 do
    Test.SelectedObjects[vCntr].Delete;
end;

procedure TForm1.actGraphImportExecute(Sender : TObject);
begin
  if dlgOpen.Execute then begin
    Test.MergeFromFile(dlgOpen.FileName,10,10);
  end;
end;

procedure TForm1.ActGraphNewExecute(Sender : TObject);
begin
  Test.Clear;
  Test.CommandMode := cmEdit;
  //IsReadonly := False;
  dlgSave.FileName := 'Untitled';
  Caption := dlgSave.FileName + ' - ' + Application.Title;
end;

procedure TForm1.actGraphSaveAsExecute(Sender : TObject);
begin
  if FFileName <> '' then dlgSave.FileName := FFileName;
  if dlgSave.Execute then begin
    Test.SaveToFile(dlgSave.FileName);
    FFileName := dlgsave.FileName;
  end;
end;

procedure TForm1.actGraphSaveExecute(Sender : TObject);
begin
  if FFileName <> '' then Test.SaveToFile(FFileName) else actGraphSaveAs.Execute;
end;

procedure TForm1.actEditPasteExecute(Sender : TObject);
begin
  Test.PasteFromClipboard;
end;

procedure TForm1.actEditPasteUpdate(Sender : TObject);
begin
  actEditPaste.Enabled := Clipboard.HasFormat(CF_SIMPLEGRAPH);
end;

procedure TForm1.actEditSelectAllExecute(Sender : TObject);
var
  vCntr : Integer;
begin
  for vCntr := Test.Objects.Count -1 downto 0 do
    Test.Objects[vCntr].Selected := True;
end;

procedure TForm1.actEditSelectAllUpdate(Sender : TObject);
begin
  actEditSelectAll.Enabled := Test.Objects.Count > 0;
end;

procedure TForm1.actHexagonNodeExecute(Sender : TObject);
begin
  Test.DefaultNodeClass := TEvsHexagonalNode;
  Test.CommandMode := cmInsertNode;
end;

procedure TForm1.actHexagonNodeUpdate(Sender : TObject);
begin
  actHexagonNode.Checked := (Test.CommandMode = cmInsertNode) and (Test.DefaultNodeClass = TEvsHexagonalNode);
end;

procedure TForm1.actObjLockLinksExecute(Sender : TObject);
begin
  Test.LockLinks := not Test.LockLinks;
end;

procedure TForm1.actObjLockLinksUpdate(Sender : TObject);
begin
  actObjLockLinks.Checked := Test.LockLinks;
end;

procedure TForm1.actObjLockNodesExecute(Sender : TObject);
begin
  Test.LockNodes := not Test.LockNodes;
end;

procedure TForm1.actObjLockNodesUpdate(Sender : TObject);
begin
  actObjLockNodes.Checked := Test.LockNodes;
end;

procedure TForm1.actPentagonNodeExecute(Sender : TObject);
begin
  Test.DefaultNodeClass := TEvsPentagonalNode;
  Test.CommandMode := cmInsertNode;
end;

procedure TForm1.actPentagonNodeUpdate(Sender : TObject);
begin
  actPentagonNode.Checked := (Test.CommandMode = cmInsertNode) and (Test.DefaultNodeClass = TEvsPentagonalNode);
end;

procedure TForm1.actPolyLineLinkExecute(Sender : TObject);
begin
  Test.DefaultLinkClass := TEvsGraphLink;
  Test.CommandMode := cmInsertLink;
end;

procedure TForm1.actPolyLineLinkUpdate(Sender : TObject);
begin
  actPolyLineLink.Checked := (Test.CommandMode = cmInsertLink) and (Test.DefaultLinkClass = TEvsGraphLink);
end;

procedure TForm1.actRectNodeExecute(Sender : TObject);
begin
  Test.CommandMode := cmInsertNode;
  Test.DefaultNodeClass := TEvsRectangularNode;
end;

procedure TForm1.actRectNodeUpdate(Sender : TObject);
begin
  actRectNode.Checked := (Test.CommandMode = cmInsertNode) and (test.DefaultNodeClass = TEvsRectangularNode);
end;

procedure TForm1.actRhomboidNodeExecute(Sender : TObject);
begin
  Test.DefaultNodeClass := TEvsRhomboidalNode;
  Test.CommandMode := cmInsertNode;
end;

procedure TForm1.actRhomboidNodeUpdate(Sender : TObject);
begin
  actRhomboidNode.Checked := (Test.CommandMode = cmInsertNode) and (Test.DefaultNodeClass = TEvsRhomboidalNode);
end;

procedure TForm1.actRoundRectNodeExecute(Sender : TObject);
begin
  Test.DefaultNodeClass := TEvsRoundRectangularNode;
  Test.CommandMode := cmInsertNode;
end;

procedure TForm1.actRoundRectNodeUpdate(Sender : TObject);
begin
  actRoundRectNode.Checked := (Test.CommandMode = cmInsertNode) and (Test.DefaultNodeClass = TEvsRoundRectangularNode);
end;

procedure TForm1.actSelectionExecute(Sender : TObject);
begin
  Test.CommandMode := cmEdit;
end;

procedure TForm1.actSelectionUpdate(Sender : TObject);
begin
  actSelection.Checked := Test.CommandMode in [cmEdit, cmViewOnly];
end;

procedure TForm1.actTriangularNodeExecute(Sender : TObject);
begin
  Test.DefaultNodeClass := TEvsTriangularNode;
  test.CommandMode := cmInsertNode;
end;

procedure TForm1.actTriangularNodeUpdate(Sender : TObject);
begin
  actTriangularNode.Checked := (Test.CommandMode = cmInsertNode) and (test.DefaultNodeClass =TEvsTriangularNode);
end;

procedure TForm1.actViewGridExecute(Sender : TObject);
begin
  Test.ShowGrid := not Test.ShowGrid;
end;

procedure TForm1.actViewGridUpdate(Sender : TObject);
begin
  actViewGrid.Checked := Test.ShowGrid;
end;

procedure TForm1.actEditCopyExecute(Sender : TObject);
begin
  Test.CopyToClipboard;
end;

procedure TForm1.actCopyBmpUpdate(Sender : TObject);
begin
  actCopyBmp.Enabled := test.SelectedObjects.Count>0;
end;

procedure TForm1.actEllipseExecute(Sender : TObject);
begin
  test.DefaultNodeClass := TEvsEllipticNode;
  test.CommandMode := cmInsertNode;
end;

procedure TForm1.actEllipseUpdate(Sender : TObject);
begin
  actEllipse.Checked := (Test.CommandMode = cmInsertNode) and (Test.DefaultNodeClass = TEvsEllipticNode);
end;

procedure TForm1.actExitExecute(Sender : TObject);
begin
  Close;
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

procedure TForm1.actBezierLinkExecute(Sender : TObject);
begin
  Test.DefaultLinkClass := TEVSBezierLink;
  Test.CommandMode := cmInsertLink;
end;

procedure TForm1.actBezierLinkUpdate(Sender : TObject);
begin
  actBezierLink.Checked := (Test.CommandMode = cmInsertLink) and (Test.DefaultLinkClass = TEVSBezierLink);
end;

procedure TForm1.actEditZoomInUpdate(Sender : TObject);
begin
  //actEditZoomIn.Enabled := assigned(test) and (Test.Zoom < High(TZoom));
end;

procedure TForm1.actEditZoomOutExecute(Sender: TObject);
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

procedure TForm1.actGraphOpenExecute(Sender : TObject);
begin
  if dlgOpen.Execute then begin
    Test.LoadFromFile(dlgOpen.FileName);
    FFileName := dlgOpen.FileName;
  end;
end;

procedure TForm1.actEditZoomOutUpdate(Sender : TObject);
begin
  //actEditZoomOut.Enabled := (Test.Zoom > Low(TZoom));
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

