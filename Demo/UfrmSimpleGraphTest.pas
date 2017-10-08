unit UfrmSimpleGraphTest;

{$mode objfpc}{$H+}

interface
{$DEFINE SIMPLEGRAPH_CREATION}
{.$DEFINE GDIPLUS}
uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, LCLType,
  LCLIntf, StdCtrls, ComCtrls, ActnList, Menus, Clipbrd,

  {$IFDEF GDIPLUS} uEvsGDIPlusSGCanvas, {$ENDIF} usimplegraph, ExtCtrls, sqldb;
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

  { TEvsMain }
  TEvsMain = class(TForm)
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
    actEditToFront : TAction;
    actEditToBack : TAction;
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
    dlgOpen : TOpenDialog;
    dlgSave : TSaveDialog;
    Panel1 : TPanel;
    StaticText1 : TStaticText;
    StaticText2 : TStaticText;
    StaticText3 : TStaticText;
    StaticText4 : TStaticText;
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
    ToolButton15 : TToolButton;
    ToolButton16 : TToolButton;
    ToolButton17 : TToolButton;
    ToolButton18 : TToolButton;
    ToolButton19 : TToolButton;
    tbtnRectNode : TToolButton;
    tbtnRoundRectNode : TToolButton;
    tbtnEllipseNode : TToolButton;
    ToolButton2 : TToolButton;
    ToolButton3 : TToolButton;
    ToolButton4 : TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    btnPaste: TToolButton;
    btnDelete : TToolButton;
    btnOpen : TToolButton;
    tbtnTRiangularNode : TToolButton;
    ToolButton7 : TToolButton;
    ToolButton8 : TToolButton;
    ToolButton9 : TToolButton;
    procedure actBezierLinkExecute(Sender : TObject);
    procedure actBezierLinkUpdate(Sender : TObject);
    procedure actCopyBmpExecute(Sender : TObject);
    procedure actCopyBmpUpdate(Sender : TObject);
    procedure actDebugFormUpdate(Sender : TObject);
    procedure actEditToBackExecute(Sender : TObject);
    procedure actEditToBackUpdate(Sender : TObject);
    procedure actEditToFrontExecute(Sender : TObject);
    procedure actEditToFrontUpdate(Sender : TObject);
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
    procedure sgDblClick(Sender:TObject);
    //procedure goDblClick2(Graph: TSimpleGraph; GraphObject: TGraphObject);
  end;

var
  EvsMain : TEvsMain;

implementation
uses {windows, freetype, IniFiles,} uFrmDebug, ufrmnodeproperties, UFrmlinkprop;

{$R *.lfm}
const
  cLinkStart = 1000;

procedure SaveScreenShot(const aFilename:string);
var
  ScreenDC   : HDC;
  SaveBitmap : TBitmap;
  vTmp       : TCustomLabel;
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

{ TEvsMain }

procedure TEvsMain.actEditZoomInExecute(Sender: TObject);
begin
  //if assigned(Test) then Test.ChangeZoomBy(10, UEvsSimpleGraph.zoCenter);
end;

procedure TEvsMain.actZoom1Update(Sender : TObject);
begin
  //if assigned(Test) then actZoom1.Enabled := (Test.Zoom <> 100) else actZoom1.Enabled := False;
end;

procedure TEvsMain.actEditCopyUpdate(Sender : TObject);
begin
  actEditCopy.Enabled := Test.SelectedObjects.Count > 0;
end;

procedure TEvsMain.actEditCutExecute(Sender : TObject);
begin
  actEditCopy.Execute;
  actEditDeleteSelected.Execute;
end;

procedure TEvsMain.actEditCutUpdate(Sender : TObject);
begin
  actEditCut.Enabled := Test.SelectedObjects.Count > 0;
end;

procedure TEvsMain.actEditDeleteSelectedExecute(Sender : TObject);
var
  vCntr : Integer;
begin
  for vCntr := Test.SelectedObjects.Count -1 downto 0 do
    Test.SelectedObjects[vCntr].Delete;
end;

procedure TEvsMain.actGraphImportExecute(Sender : TObject);
begin
  if dlgOpen.Execute then begin
    Test.MergeFromFile(dlgOpen.FileName,10,10);
  end;
end;

procedure TEvsMain.ActGraphNewExecute(Sender : TObject);
begin
  Test.Clear;
  Test.CommandMode := cmEdit;
  //IsReadonly := False;
  dlgSave.FileName := 'Untitled';
  Caption := dlgSave.FileName + ' - ' + Application.Title;
end;

procedure TEvsMain.actGraphSaveAsExecute(Sender : TObject);
begin
  if FFileName <> '' then dlgSave.FileName := FFileName;
  if dlgSave.Execute then begin
    Test.SaveToFile(dlgSave.FileName);
    FFileName := dlgsave.FileName;
  end;
end;

procedure TEvsMain.actGraphSaveExecute(Sender : TObject);
begin
  if FFileName <> '' then Test.SaveToFile(FFileName) else actGraphSaveAs.Execute;
end;

procedure TEvsMain.actEditPasteExecute(Sender : TObject);
begin
  Test.PasteFromClipboard;
end;

procedure TEvsMain.actEditPasteUpdate(Sender : TObject);
begin
  actEditPaste.Enabled := Clipboard.HasFormat(CF_SIMPLEGRAPH);
end;

procedure TEvsMain.actEditSelectAllExecute(Sender : TObject);
var
  vCntr : Integer;
begin
  for vCntr := Test.Objects.Count -1 downto 0 do
    Test.Objects[vCntr].Selected := True;
end;

procedure TEvsMain.actEditSelectAllUpdate(Sender : TObject);
begin
  actEditSelectAll.Enabled := Test.Objects.Count > 0;
end;

procedure TEvsMain.actHexagonNodeExecute(Sender : TObject);
begin
  Test.DefaultNodeClass := TEvsHexagonalNode;
  Test.CommandMode := cmInsertNode;
end;

procedure TEvsMain.actHexagonNodeUpdate(Sender : TObject);
begin
  actHexagonNode.Checked := (Test.CommandMode = cmInsertNode) and (Test.DefaultNodeClass = TEvsHexagonalNode);
end;

procedure TEvsMain.actObjLockLinksExecute(Sender : TObject);
begin
  Test.LockLinks := not Test.LockLinks;
end;

procedure TEvsMain.actObjLockLinksUpdate(Sender : TObject);
begin
  actObjLockLinks.Checked := Test.LockLinks;
end;

procedure TEvsMain.actObjLockNodesExecute(Sender : TObject);
begin
  Test.LockNodes := not Test.LockNodes;
end;

procedure TEvsMain.actObjLockNodesUpdate(Sender : TObject);
begin
  actObjLockNodes.Checked := Test.LockNodes;
end;

procedure TEvsMain.actPentagonNodeExecute(Sender : TObject);
begin
  Test.DefaultNodeClass := TEvsPentagonalNode;
  Test.CommandMode := cmInsertNode;
end;

procedure TEvsMain.actPentagonNodeUpdate(Sender : TObject);
begin
  actPentagonNode.Checked := (Test.CommandMode = cmInsertNode) and (Test.DefaultNodeClass = TEvsPentagonalNode);
end;

procedure TEvsMain.actPolyLineLinkExecute(Sender : TObject);
begin
  Test.DefaultLinkClass := TEvsGraphLink;
  Test.CommandMode := cmInsertLink;
end;

procedure TEvsMain.actPolyLineLinkUpdate(Sender : TObject);
begin
  actPolyLineLink.Checked := (Test.CommandMode = cmInsertLink) and (Test.DefaultLinkClass = TEvsGraphLink);
end;

procedure TEvsMain.actRectNodeExecute(Sender : TObject);
begin
  Test.CommandMode := cmInsertNode;
  Test.DefaultNodeClass := TEvsRectangularNode;
end;

procedure TEvsMain.actRectNodeUpdate(Sender : TObject);
begin
  actRectNode.Checked := (Test.CommandMode = cmInsertNode) and (test.DefaultNodeClass = TEvsRectangularNode);
end;

procedure TEvsMain.actRhomboidNodeExecute(Sender : TObject);
begin
  Test.DefaultNodeClass := TEvsRhomboidalNode;
  Test.CommandMode := cmInsertNode;
end;

procedure TEvsMain.actRhomboidNodeUpdate(Sender : TObject);
begin
  actRhomboidNode.Checked := (Test.CommandMode = cmInsertNode) and (Test.DefaultNodeClass = TEvsRhomboidalNode);
end;

procedure TEvsMain.actRoundRectNodeExecute(Sender : TObject);
begin
  Test.DefaultNodeClass := TEvsRoundRectangularNode;
  Test.CommandMode := cmInsertNode;
end;

procedure TEvsMain.actRoundRectNodeUpdate(Sender : TObject);
begin
  actRoundRectNode.Checked := (Test.CommandMode = cmInsertNode) and (Test.DefaultNodeClass = TEvsRoundRectangularNode);
end;

procedure TEvsMain.actSelectionExecute(Sender : TObject);
begin
  Test.CommandMode := cmEdit;
end;

procedure TEvsMain.actSelectionUpdate(Sender : TObject);
begin
  actSelection.Checked := Test.CommandMode in [cmEdit, cmViewOnly];
end;

procedure TEvsMain.actTriangularNodeExecute(Sender : TObject);
begin
  Test.DefaultNodeClass := TEvsTriangularNode;
  test.CommandMode := cmInsertNode;
end;

procedure TEvsMain.actTriangularNodeUpdate(Sender : TObject);
begin
  actTriangularNode.Checked := (Test.CommandMode = cmInsertNode) and (test.DefaultNodeClass =TEvsTriangularNode);
end;

procedure TEvsMain.actViewGridExecute(Sender : TObject);
begin
  Test.ShowGrid := not Test.ShowGrid;
end;

procedure TEvsMain.actViewGridUpdate(Sender : TObject);
begin
  actViewGrid.Checked := Test.ShowGrid;
end;

procedure TEvsMain.actEditCopyExecute(Sender : TObject);
begin
  Test.CopyToClipboard;
end;

procedure TEvsMain.actCopyBmpUpdate(Sender : TObject);
begin
  actCopyBmp.Enabled := test.SelectedObjects.Count>0;
end;

procedure TEvsMain.actDebugFormUpdate(Sender : TObject);
begin
  actDebugForm.Checked := dbgFrm.Visible;
end;

procedure TEvsMain.actEditToBackExecute(Sender : TObject);
var
  vCntr : Integer;
begin
  for vCntr := test.SelectedObjects.Count -1 downto 0 do
     Test.SelectedObjects[vCntr].SendToBack;
end;

procedure TEvsMain.actEditToBackUpdate(Sender : TObject);
begin
  actEditToBack.Enabled := test.SelectedObjects.Count > 0;
end;

procedure TEvsMain.actEditToFrontExecute(Sender : TObject);
var
  vCntr : Integer;
begin
  for vCntr := 0 to test.SelectedObjects.Count -1 do
     Test.SelectedObjects[vCntr].BringToFront;
end;

procedure TEvsMain.actEditToFrontUpdate(Sender : TObject);
begin
  actEditToFront.Enabled := test.SelectedObjects.Count > 0;
end;

procedure TEvsMain.actEllipseExecute(Sender : TObject);
begin
  test.DefaultNodeClass := TEvsEllipticNode;
  test.CommandMode := cmInsertNode;
end;

procedure TEvsMain.actEllipseUpdate(Sender : TObject);
begin
  actEllipse.Checked := (Test.CommandMode = cmInsertNode) and (Test.DefaultNodeClass = TEvsEllipticNode);
end;

procedure TEvsMain.actExitExecute(Sender : TObject);
begin
  Close;
end;

procedure TEvsMain.actCopyBmpExecute(Sender : TObject);
var
  vTmp : TEvsGraphClipboardFormats;
begin
  vTmp := Test.ClipboardFormats;
  Test.ClipboardFormats := [cfBitmap];
  Test.CopyToClipboard();
  Test.ClipboardFormats := vTmp;
end;

procedure TEvsMain.actBezierLinkExecute(Sender : TObject);
begin
  Test.DefaultLinkClass := TEVSBezierLink;
  Test.CommandMode := cmInsertLink;
end;

procedure TEvsMain.actBezierLinkUpdate(Sender : TObject);
begin
  actBezierLink.Checked := (Test.CommandMode = cmInsertLink) and (Test.DefaultLinkClass = TEVSBezierLink);
end;

procedure TEvsMain.actEditZoomInUpdate(Sender : TObject);
begin
  //actEditZoomIn.Enabled := assigned(test) and (Test.Zoom < High(TZoom));
end;

procedure TEvsMain.actEditZoomOutExecute(Sender: TObject);
begin
  //if assigned(test) then begin
  //  Test.ChangeZoomBy(-10, UEvsSimpleGraph.zoCenter);
  //end;
end;

procedure TEvsMain.actZoom1Execute(Sender: TObject);
begin
  //if assigned(Test) then begin
  //  Test.ChangeZoom(100, UEvsSimpleGraph.zoTopLeft);
  //end;
end;

procedure TEvsMain.Action4Execute(Sender: TObject);
begin
  if assigned(Test) then begin
    test.DefaultNodeClass:=TEvsHexagonalNode;
    test.CommandMode:=usimplegraph.cmInsertNode;
  end;
end;

procedure TEvsMain.actDebugFormExecute(Sender: TObject);
var
  Tmp : TForm = nil;

begin
  Tmp:= dbgFrm;

  if Tmp.Visible then
    Tmp.Hide
  else begin
    //Tmp.PopupMode   := pmExplicit;
    //Tmp.PopupParent := Self;
    Tmp.Show;
  end;

end;

procedure TEvsMain.actGraphOpenExecute(Sender : TObject);
begin
  if dlgOpen.Execute then begin
    Test.LoadFromFile(dlgOpen.FileName);
    FFileName := dlgOpen.FileName;
  end;
end;

procedure TEvsMain.actEditZoomOutUpdate(Sender : TObject);
begin
  //actEditZoomOut.Enabled := (Test.Zoom > Low(TZoom));
end;

procedure TEvsMain.FormMouseMove(Sender : TObject; Shift : TShiftState; X,
  Y : Integer);
var
  vTmp : TPoint;
begin
  vTmp := Test.ClientToGraph(X,Y);
  Caption := EvsActiveWidgetSet + ' - ' + Format('M.X %D M.Y %D : G.X %D G.Y %D',[X, Y, vTmp.X, vTmp.Y]);
end;

procedure TEvsMain.MenuItem1Click(Sender: TObject);
begin
  if Assigned(Test) then begin
    Test.DefaultNodeClass:=TEvsSimpleGraph.NodeClasses(TMenuItem(Sender).Tag-1);
    test.CommandMode:=usimplegraph.cmInsertNode;
  end;
end;

procedure TEvsMain.MenuItem2Click(Sender : TObject);
begin
  if Assigned(Test) then begin
    Test.DefaultLinkClass:=TEvsSimpleGraph.LinkClasses(TMenuItem(Sender).Tag-1-cLinkStart);
    Test.CommandMode:=usimplegraph.cmInsertLink;
  end;
end;

constructor TEvsMain.Create(aOwner : TComponent);
//VAR
//  tmp : UnicodeString;
//  Mnu : TMenuItem;
  //Cnt: Integer;
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
  Test.OnDblClick := @sgDblClick;
    {$IFDEF GDIPLUS}
    Test.CustomCanvas := TEvsGdiPlusControlCanvas;
    //Test.Canvas.Free;
    //Test.Canvas := TEvsGdiPlusControlCanvas.Create;
    //TControlCanvas(Test.Canvas).Control := Test;
    {$ENDIF}
  {$ENDIF}
  Test.FixedScrollBars := True;
  Caption := caption + '-' + EvsActiveWidgetSet;
  dbgFrm.PopupMode := pmExplicit;
  dbgFrm.PopupParent := Self;
end;

procedure TEvsMain.goDblClick(Graph : TEvsSimpleGraph;
  GraphObject : TEvsGraphObject);
begin
  StaticText4.Caption := IntToStr(GraphObject.ID);
  if Test.SelectedObjects.Count > 0 then begin
    if GraphObject.IsNode then
      TEvsNodeProperties.Execute(Test.SelectedObjects)
    else TEvsLinkProperties.Execute(Test.SelectedObjects);
  end;
end;

procedure TEvsMain.sgDblClick(Sender : TObject);
begin
  StaticText1.Caption := 'Total Objects :'+IntToStr(Test.Objects.Count);
  StaticText2.Caption := 'Links : ' +IntToStr(Test.ObjectsCount(TEvsGraphLink));
  StaticText3.Caption := 'Nodes : ' +IntToStr(Test.ObjectsCount(TEvsGraphNode));
end;

end.

