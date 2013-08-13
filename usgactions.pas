unit usgactions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ActnList, uSimpleGraph;

type
  TCallBackAction=(cbSelect, cbDelete, cbRevSelection, cbUnselect);
  //SimpleGraph : for which simplegraph to get info.
  TEvsGraphAction = Class(TAction)
  private
    FSimpleGraph : TEvsSimpleGraph;
    function GetSimpleGraph : TEvsSimpleGraph;
    procedure SetGraphControl(aValue : TEvsSimpleGraph);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    function SGCallBack(GraphObject: TEvsGraphObject; UserData: integer): boolean;
  public
    constructor Create(AOwner : TComponent); override;
    function HandlesTarget(Target: TObject): Boolean; override;
  published
    property SimpleGraph: TEvsSimpleGraph read GetSimpleGraph write SetGraphControl;
  end;

  TEvsGraphEditAction = Class(TEvsGraphAction)
  public
    procedure UpdateTarget(Target: TObject); override;
  end;

  TEvsGraphSelectAll = Class(TEvsGraphAction)
  public
    procedure ExecuteTarget(Target: TObject); override;
    procedure UpdateTarget(Target: TObject); override;
  end;

  TEvsGraphAlignLeft = class(TEvsGraphEditAction)
  public
    procedure ExecuteTarget(Target : TObject); override;
  end;
  TEvsGraphAlignRight = class(TEvsGraphEditAction)
  public
    procedure ExecuteTarget(Target : TObject); override;
  end;
  TEvsGraphAlignTop = class(TEvsGraphEditAction)
  public
    procedure ExecuteTarget(Target : TObject); override;
  end;
  TEvsGraphAlignBottom = class(TEvsGraphEditAction)
  public
    procedure ExecuteTarget(Target : TObject); override;
  end;
  TEvsGraphAlignHorzCenter = class(TEvsGraphEditAction)
  public
    procedure ExecuteTarget(Target : TObject); override;
  end;
  TEvsGraphAlignVertCenter = class(TEvsGraphEditAction)
  public
    procedure ExecuteTarget(Target : TObject); override;
  end;
  TEvsGraphResizeGreatestWidth = class(TEvsGraphEditAction)
  public
    procedure ExecuteTarget(Target : TObject); override;
  end;
  TEvsGraphResizeSmallestWidth = class(TEvsGraphEditAction)
  public
    procedure ExecuteTarget(Target : TObject); override;
  end;
  TEvsGraphResizeGreatestHeight = class(TEvsGraphEditAction)
  public
    procedure ExecuteTarget(Target : TObject); override;
  end;
  TEvsGraphResizeSmallestHeight = class(TEvsGraphEditAction)
  public
    procedure ExecuteTarget(Target : TObject); override;
  end;

  TEvsGraphReverseSelection = Class(TEvsGraphAction)
  public
    procedure ExecuteTarget(Target: TObject); override;
    procedure UpdateTarget(Target: TObject); override;
  published
    property SimpleGraph;
  end;

  TEvsGraphDeleteSelected = Class(TEvsGraphEditAction)
  public
    procedure ExecuteTarget(Target: TObject); override;
  published
    property SimpleGraph;
  end;

  TEvsGraphCopy = Class(TEvsGraphEditAction)
  public
    procedure ExecuteTarget(Target: TObject); override;
  published
    property SimpleGraph;
  end;

  TEvsGraphCut = Class(TEvsGraphEditAction)
  public
    procedure ExecuteTarget(Target: TObject); override;
  published
    property SimpleGraph;
  end;

  TEvsGraphPaste = Class(TEvsGraphEditAction)
  public
    procedure ExecuteTarget(Target: TObject); override;
    procedure UpdateTarget(Target: TObject); override;
  published
    property SimpleGraph;
  end;

  TEvsGraphNodeAction = Class(TEvsGraphAction)
  private
    FClass : TEvsGraphObjectClass;
    function GetNodeClassName : String;
    function GetNodeClass : TEvsGraphNodeClass;
    procedure SetNodeClassName(aValue : String);
    procedure SetNodeClass(aValue : TEvsGraphNodeClass);
  protected
    property NodeClass:TEvsGraphNodeClass read GetNodeClass write SetNodeClass;
  public
    procedure ExecuteTarget(Target: TObject); override;
    procedure UpdateTarget(Target: TObject); override;
  published
    property SimpleGraph;
    property NodeClassName :String read GetNodeClassName write SetNodeClassName;
  end;

  TEvsGraphLinkAction = Class(TEvsGraphAction)
  private
    FClass : TEvsGraphObjectClass;
    function GetClassName : string;
    function GetLinkClass : TEvsGraphLinkClass;
    procedure SetClassName(aValue : string);
    procedure SetLinkClass(aValue : TEvsGraphLinkClass);
  public
    procedure ExecuteTarget(Target: TObject); override;
    procedure UpdateTarget(Target: TObject); override;
    property LinkClass : TEvsGraphLinkClass read GetLinkClass write SetLinkClass;
  published
    property SimpleGraph;
    property LinkClassName :string read GetClassName write SetClassName;
  end;


implementation
uses Clipbrd;
const
  cNodeClass = True;
  cLinkClass = False;

//function _GraphClassByName(aName:String; ClassType:Boolean=cNodeClass):TEvsGraphObjectClass;
function _GraphClassByName(aName:String; ClassType:Boolean=cNodeClass):TEvsGraphObjectClass;
var
  vCntr : Integer;
begin
  Result := nil;
  if ClassType then begin
    for vCntr := 0 to TEvsSimpleGraph.NodeClassCount -1 do
      if TEvsSimpleGraph.NodeClasses(vCntr).ClassName = aName then begin
        Result := TEvsSimpleGraph.NodeClasses(vCntr);
        Break;
      end;
  end else begin
    for vCntr := 0 to TEvsSimpleGraph.LinkClassCount -1 do
      if TEvsSimpleGraph.LinkClasses(vCntr).ClassName = aName then begin
        Result := TEvsSimpleGraph.LinkClasses(vCntr);
        Break;
      end;
  end;
end;

procedure TEvsGraphAction.SetGraphControl(aValue : TEvsSimpleGraph);
begin
  if FSimpleGraph = aValue then Exit;
  FSimpleGraph := aValue;
end;

function TEvsGraphAction.GetSimpleGraph : TEvsSimpleGraph;
begin
  Result := FSimpleGraph;
end;

procedure TEvsGraphAction.Notification(AComponent : TComponent;
  Operation : TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation=opRemove) and (AComponent=FSimpleGraph) then FSimpleGraph:=Nil;
end;

function TEvsGraphAction.SGCallBack(GraphObject : TEvsGraphObject;
  UserData : integer) : boolean;
var
  vAction :TCallBackAction;
begin
  vAction := TCallBackAction(UserData);
  Result := True;
  case vAction of
    cbSelect       : GraphObject.Selected := True;
    cbDelete       : Result := GraphObject.Delete;
    cbRevSelection : GraphObject.Selected := not GraphObject.Selected;
    cbUnselect     : GraphObject.Selected := False;
  else
    Result := False;
  end;
end;

constructor TEvsGraphAction.Create(AOwner : TComponent);
begin
  inherited Create(AOwner);
  FSimpleGraph := nil;
end;

function TEvsGraphAction.HandlesTarget(Target : TObject) : Boolean;
begin
  Result := (FSimpleGraph<>Nil) and ((FSimpleGraph=Target) or (Target is TEvsSimpleGraph));
end;

{ TEvsGraphEditAction }

procedure TEvsGraphEditAction.UpdateTarget(Target : TObject);
var
  vSG :TEvsSimpleGraph;
begin
  if Assigned(FSimpleGraph) then vSG := FSimpleGraph
  else if Target is TEvsSimpleGraph then vSG:=TEvsSimpleGraph(Target);
  Enabled := Assigned(vSG) and (vSG.SelectedObjects.Count>0);
end;

procedure TEvsGraphSelectAll.ExecuteTarget(Target : TObject);
var
  vSG : TEvsSimpleGraph;
begin
  if Assigned(FSimpleGraph) then vSG:=FSimpleGraph
  else if (Target is TEvsSimpleGraph) then vSG:= TEvsSimpleGraph(Target);
  vSG.ForEachObject(@SGCallBack,Integer(cbSelect));
end;

procedure TEvsGraphSelectAll.UpdateTarget(Target : TObject);
var
  vSg : TEvsSimpleGraph;
begin
  vSg := FSimpleGraph;
  if not Assigned(vSg) and (Target is TEvsSimpleGraph) then vSg:= TEvsSimpleGraph(Target);
  Enabled := Assigned(vSg) and ((vSg.Objects.Count > 0) and (vSg.SelectedObjects.Count<>vSg.Objects.Count))
end;

{ TEvsGraphReverseSelection }

procedure TEvsGraphReverseSelection.ExecuteTarget(Target : TObject);
var
  vSG :TEvsSimpleGraph;
begin
  if Assigned(FSimpleGraph) then vSG := FSimpleGraph
  else if Target is TEvsSimpleGraph then vSG:=TEvsSimpleGraph(Target);
  if Assigned(Vsg) then vSG.ForEachObject(@SGCallBack, Integer(cbRevSelection));
end;

procedure TEvsGraphReverseSelection.UpdateTarget(Target : TObject);
var
  vSG :TEvsSimpleGraph;
begin
  if Assigned(FSimpleGraph) then vSG := FSimpleGraph
  else if Target is TEvsSimpleGraph then vSG:=TEvsSimpleGraph(Target);
  Enabled := Assigned(vSG) and (vSG.objects.Count > 0) and (vSG.SelectedObjects.Count > 0);
end;

{ TEvsGraphDeleteSelected }

procedure TEvsGraphDeleteSelected.ExecuteTarget(Target : TObject);
var
  vSG :TEvsSimpleGraph;
begin
  if Assigned(FSimpleGraph) then vSG := FSimpleGraph
  else if Target is TEvsSimpleGraph then vSG:=TEvsSimpleGraph(Target);
  if Assigned(vSG) then vSG.ForEachObject(@SGCallBack, Integer(cbDelete), True)
end;

{ TEvsGraphCopy }

procedure TEvsGraphCopy.ExecuteTarget(Target : TObject);
var
  vSG :TEvsSimpleGraph;
begin
  if Assigned(FSimpleGraph) then vSG := FSimpleGraph
  else if Target is TEvsSimpleGraph then vSG:=TEvsSimpleGraph(Target);
  if Assigned(vSG) then vSG.CopyToClipboard;
end;

{ TEvsGraphCut }

procedure TEvsGraphCut.ExecuteTarget(Target : TObject);
var
  vSG :TEvsSimpleGraph;
begin
  if Assigned(FSimpleGraph) then vSG := FSimpleGraph
  else if Target is TEvsSimpleGraph then vSG:=TEvsSimpleGraph(Target);
  if Assigned(vSG) then begin
    vSG.CopyToClipboard;
    vsg.ForEachObject(@SGCallBack, Integer(cbDelete), True);
  end;
end;

{ TEvsGraphPaste }

procedure TEvsGraphPaste.ExecuteTarget(Target : TObject);
var
  vSG :TEvsSimpleGraph;
begin
  if Assigned(FSimpleGraph) then vSG := FSimpleGraph
  else if Target is TEvsSimpleGraph then vSG:=TEvsSimpleGraph(Target);
  if Assigned(vSG) then vSG.PasteFromClipboard;
end;

procedure TEvsGraphPaste.UpdateTarget(Target : TObject);
var
  vSG :TEvsSimpleGraph;
begin
  if Assigned(FSimpleGraph) then vSG := FSimpleGraph
  else if Target is TEvsSimpleGraph then vSG:=TEvsSimpleGraph(Target);
  Enabled := Assigned(vSG) and Clipboard.HasFormat(CF_SIMPLEGRAPH);
end;

{ TEvsGraphNode }

function TEvsGraphNodeAction.GetNodeClass : TEvsGraphNodeClass;
begin
  Result := TEvsGraphNodeClass(FClass);
end;

function TEvsGraphNodeAction.GetNodeClassName : String;
begin
  if Assigned(FClass) then
    Result := FClass.ClassName
  else
    Result := '';
end;

procedure TEvsGraphNodeAction.SetNodeClassName(aValue : String);
var
  vTmpClass:TEvsGraphObjectClass;
begin
  vTmpClass := _GraphClassByName(aValue);
  if not Assigned(vTmpClass) then raise EEvsGraphInvalidOperation.CreateFmt('Unknown class %S',[aValue]);
  SetNodeClass(TEvsGraphNodeClass(vTmpClass));
end;

procedure TEvsGraphNodeAction.SetNodeClass(aValue : TEvsGraphNodeClass);
  procedure _SetCaption;
  begin
    Caption := StringReplace(StringReplace(FClass.ClassName,'TEvs','',[rfReplaceAll]),'Node',' Node',[rfReplaceAll]);
  end;
begin
  if TEvsGraphNodeClass(FClass) <> aValue then begin
    FClass := aValue;
    _SetCaption;
  end;
end;

procedure TEvsGraphNodeAction.ExecuteTarget(Target : TObject);
var
  vSG :TEvsSimpleGraph;
begin
  if Assigned(FSimpleGraph) then vSG := FSimpleGraph
  else if Target is TEvsSimpleGraph then vSG:=TEvsSimpleGraph(Target);
  if Assigned(vSG) then begin
    vSG.CommandMode      := cmInsertNode;
    vSG.DefaultNodeClass := TEvsGraphNodeClass(FClass);
  end;
end;

procedure TEvsGraphNodeAction.UpdateTarget(Target : TObject);
var
  vSG :TEvsSimpleGraph;
begin
  if Assigned(FSimpleGraph) then vSG := FSimpleGraph
  else if Target is TEvsSimpleGraph then vSG:=TEvsSimpleGraph(Target);
  Enabled := Assigned(vSG) and (vSG.CommandMode <> cmViewOnly);
  Checked := Enabled and (vSG.CommandMode = cmInsertNode) and (vSG.DefaultNodeClass = TevsGraphNodeClass(FClass));
end;

{ TEvsGraphLinkAction }

function TEvsGraphLinkAction.GetLinkClass : TEvsGraphLinkClass;
begin
  Result := TEvsGraphLinkClass(FClass);
end;

function TEvsGraphLinkAction.GetClassName : string;
begin
  if Assigned(FClass) then Result:= FClass.ClassName
  else Result := '';
end;

procedure TEvsGraphLinkAction.SetClassName(aValue : string);
var
  vTmpClass :TEvsGraphObjectClass;
begin
  vTmpClass := _GraphClassByName(aValue, cLinkClass);
  if not Assigned(vTmpClass) then EEvsGraphInvalidOperation.CreateFmt('Unknown class %S',[aValue]);
  SetLinkClass(TEvsGraphLinkClass(vTmpClass));
end;

procedure TEvsGraphLinkAction.SetLinkClass(aValue : TEvsGraphLinkClass);
  procedure _SetCaption;
  begin
    Caption := StringReplace(StringReplace(FClass.ClassName,'TEvs','',[rfReplaceAll]),'Link',' Link',[rfReplaceAll]);
  end;
begin
  if TEvsGraphLinkClass(FClass) <> aValue then begin
    FClass := aValue;
    _SetCaption;
  end;
end;

procedure TEvsGraphLinkAction.ExecuteTarget(Target : TObject);
var
  vSG :TEvsSimpleGraph;
begin
  if Assigned(FSimpleGraph) then vSG := FSimpleGraph
  else if Target is TEvsSimpleGraph then vSG:=TEvsSimpleGraph(Target);
  if Assigned(vSG) then begin
    vSG.CommandMode      := cmInsertNode;
    vSG.DefaultNodeClass := TEvsGraphNodeClass(FClass);
  end;
end;

procedure TEvsGraphLinkAction.UpdateTarget(Target : TObject);
var
  vSG :TEvsSimpleGraph;
begin
  if Assigned(FSimpleGraph) then vSG := FSimpleGraph
  else if Target is TEvsSimpleGraph then vSG:=TEvsSimpleGraph(Target);
  Enabled := Assigned(vSG) and (vSG.CommandMode <> cmViewOnly);
  Checked := Enabled and (vSG.CommandMode = cmInsertLink) and (vSG.DefaultLinkClass = TEvsGraphLinkClass(FClass));
end;

{ TevsGraphAlignLeft }

procedure TevsGraphAlignLeft.ExecuteTarget(Target : TObject);
var
  vSg : TEvsSimpleGraph;
begin
  //inherited ExecuteTarget(Target);
  vSg:=FSimpleGraph;
  if not Assigned(vSg) and (Target is TEvsSimpleGraph) then vSg := TEvsSimpleGraph(Target);
  if Assigned(vSg) then vSg.AlignSelection(haLeft, vaNoChange);
end;

{ TEvsGraphAlignRight }

procedure TEvsGraphAlignRight.ExecuteTarget(Target : TObject);
var
  vSg : TEvsSimpleGraph;
begin
  vSg:=FSimpleGraph;
  if not Assigned(vSg) and (Target is TEvsSimpleGraph) then vSg := TEvsSimpleGraph(Target);
  if Assigned(vSg) then vSg.AlignSelection(haRight, vaNoChange);
end;

{ TEvsGraphAlignTop }

procedure TEvsGraphAlignTop.ExecuteTarget(Target : TObject);
var
  vSg : TEvsSimpleGraph;
begin
  vSg:=FSimpleGraph;
  if not Assigned(vSg) and (Target is TEvsSimpleGraph) then vSg := TEvsSimpleGraph(Target);
  if Assigned(vSg) then vSg.AlignSelection(haNoChange, vaTop);
end;

{ TEvsGraphAlignBottom }

procedure TEvsGraphAlignBottom.ExecuteTarget(Target : TObject);
var
  vSg : TEvsSimpleGraph;
begin
  vSg:=FSimpleGraph;
  if not Assigned(vSg) and (Target is TEvsSimpleGraph) then vSg := TEvsSimpleGraph(Target);
  if Assigned(vSg) then vSg.AlignSelection(haNoChange, vaBottom);
end;

{ TEvsGraphAlignHorzCenter }

procedure TEvsGraphAlignHorzCenter.ExecuteTarget(Target : TObject);
var
  vSg : TEvsSimpleGraph;
begin
  vSg:=FSimpleGraph;
  if not Assigned(vSg) and (Target is TEvsSimpleGraph) then vSg := TEvsSimpleGraph(Target);
  if Assigned(vSg) then vSg.AlignSelection(haCenter, vaNoChange);
end;

{ TEvsGraphAlignVertCenter }

procedure TEvsGraphAlignVertCenter.ExecuteTarget(Target : TObject);
var
  vSg : TEvsSimpleGraph;
begin
  vSg:=FSimpleGraph;
  if not Assigned(vSg) and (Target is TEvsSimpleGraph) then vSg := TEvsSimpleGraph(Target);
  if Assigned(vSg) then vSg.AlignSelection(haNoChange, vaCenter);
end;

{ TEvsGraphResizeGreatestWidth }

procedure TEvsGraphResizeGreatestWidth.ExecuteTarget(Target : TObject);
begin
  SimpleGraph.ResizeSelection(roLargest, roNoChange);
end;

{ TEvsGraphResizeSmallestWidth }

procedure TEvsGraphResizeSmallestWidth.ExecuteTarget(Target : TObject);
begin
  SimpleGraph.ResizeSelection(roSmallest, roNoChange);
end;

{ TEvsGraphResizeSmallestHeight }

procedure TEvsGraphResizeSmallestHeight.ExecuteTarget(Target : TObject);
begin
  SimpleGraph.ResizeSelection(roNoChange, roSmallest);
end;

{ TEvsGraphResizeGreatestHeight }

procedure TEvsGraphResizeGreatestHeight.ExecuteTarget(Target : TObject);
begin
  SimpleGraph.ResizeSelection(roNoChange, roLargest);
end;

end.

