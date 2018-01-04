program SimpleGraphBuilder;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, memdslaz, UfrmSimpleGraphTest, uFrmDebug, ufrmnodeproperties,
  UFrmlinkprop, usimplegraph, uevsIDChecks, uEvsObjectList;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TEvsMain, EvsMain);
  Application.Run;
end.

