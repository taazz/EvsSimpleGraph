unit uReg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, usimplegraph, PropEdits;
type
  TEvsGraphLinkProperty = class(TStringPropertyEditor)
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const NewValue: ansistring); override;
  end;

  TEvsGraphNodeProperty = class(TStringPropertyEditor)
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const NewValue: ansistring); override;
  end;

procedure Register;

implementation
uses
  ActnList,usgactions, LResources;

procedure Register;
begin
  RegisterComponents('Misc',[TEvsSimpleGraph]);

  RegisterActions('SimpleGraph',[TEvsGraphCopy, TEvsGraphCut, TEvsGraphDeleteSelected,
                                 TEvsGraphPaste, TEvsGraphReverseSelection,TEvsGraphSelectAll,
                                 TEvsGraphNodeAction, TEvsGraphLinkAction,
                                 TEvsGraphAlignBottom, TEvsGraphAlignHorzCenter,
                                 TEvsGraphAlignLeft,TEvsGraphAlignRight,
                                 TEvsGraphAlignTop, TEvsGraphAlignVertCenter,
                                 TEvsGraphResizeGreatestHeight,TEvsGraphResizeGreatestWidth,
                                 TEvsGraphResizeSmallestHeight,TEvsGraphResizeSmallestWidth],nil);

  RegisterPropertyEditor(TypeInfo(string),TEvsGraphLinkAction,'LinkClassName',TEvsGraphLinkProperty);
  RegisterPropertyEditor(TypeInfo(string),TEvsGraphNodeAction,'NodeClassName',TEvsGraphNodeProperty);
end;


{ TEvsGraphLinkProperty }

function TEvsGraphLinkProperty.GetAttributes : TPropertyAttributes;
begin
  Result := [paMultiSelect, paSortList, paValueList, paPickList, paRevertable];
end;

procedure TEvsGraphLinkProperty.GetValues(Proc : TGetStrProc);
var
  vCntr : Integer;
begin
  for vCntr := 0 to TEvsSimpleGraph.LinkClassCount -1 do begin
    Proc(TEvsSimpleGraph.LinkClasses(vCntr).ClassName);
  end;
end;

procedure TEvsGraphLinkProperty.SetValue(const NewValue : ansistring);
begin
  SetStrValue(NewValue);
end;

{ TEvsGraphNodeProperty }

function TEvsGraphNodeProperty.GetAttributes : TPropertyAttributes;
begin
  Result := [paMultiSelect, paSortList, paValueList, paPickList, paRevertable];
end;

procedure TEvsGraphNodeProperty.GetValues(Proc : TGetStrProc);
var
  vCntr : Integer;
begin
  for vCntr := 0 to TEvsSimpleGraph.NodeClassCount -1 do begin
    Proc(TEvsSimpleGraph.NodeClasses(vCntr).ClassName);
  end;
end;

procedure TEvsGraphNodeProperty.SetValue(const NewValue : ansistring);
begin
  SetStrValue(NewValue);
end;

Initialization
  {$I SG.lrs}
end.

