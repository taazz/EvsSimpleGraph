unit DesignProp;

{$MODE Delphi}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, UevsSimplegraph, ExtCtrls, StdCtrls, ComCtrls;

type
  TDesignerProperties = class(TForm)
    Grid: TGroupBox;
    ShowGrid: TCheckBox;
    Label1: TLabel;
    SnapToGrid: TCheckBox;
    Colors: TGroupBox;
    Label2: TLabel;
    DesignerBackgroundColor: TPanel;
    Label3: TLabel;
    DesignerMarkerColor: TPanel;
    Label4: TLabel;
    DesignerGridColor: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    Bevel1: TBevel;
    ColorDialog: TColorDialog;
    btnApply: TButton;
    Edit1: TEdit;
    GridSize: TUpDown;
    BackgroundColor: TShape;
    MarkerColor: TShape;
    GridColor: TShape;
    procedure DesignerBackgroundColorClick(Sender: TObject);
    procedure DesignerMarkerColorClick(Sender: TObject);
    procedure DesignerGridColorClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    S: TEvsSimpleGraph;
    procedure ApplyChanges;
  public
    class function Execute(SimpleGraph: TEvsSimpleGraph): Boolean;
  end;

implementation

{$R *.lfm}

{ TDesignerProperties }

class function TDesignerProperties.Execute(SimpleGraph: TEvsSimpleGraph): Boolean;
begin
  Result := False;
  with Create(Application) do
    try
      S := SimpleGraph;
      GridSize.Min := Low(TGridSize);
      GridSize.Max := High(TGridSize);
      SnapToGrid.Checked := SimpleGraph.SnapToGrid;
      ShowGrid.Checked := SimpleGraph.ShowGrid;
      GridSize.Position := SimpleGraph.GridSize;
      BackgroundColor.Brush.Color := SimpleGraph.Color;
      MarkerColor.Brush.Color := SimpleGraph.MarkerColor;
      GridColor.Brush.Color := SimpleGraph.GridColor;
      if ShowModal = mrOK then
      begin
        ApplyChanges;
        Result := True;
      end;
    finally
      Free;
    end;
end;

procedure TDesignerProperties.ApplyChanges;
begin
  S.BeginUpdate;
  try
    S.SnapToGrid := SnapToGrid.Checked;
    S.ShowGrid := ShowGrid.Checked;
    S.GridSize := GridSize.Position;
    S.Color := BackgroundColor.Brush.Color;
    S.MarkerColor := MarkerColor.Brush.Color;
    S.GridColor := GridColor.Brush.Color;
  finally
    S.EndUpdate;
  end;
end;

procedure TDesignerProperties.DesignerBackgroundColorClick(Sender: TObject);
begin
  ColorDialog.Color := BackgroundColor.Brush.Color;
  if ColorDialog.Execute then
    BackgroundColor.Brush.Color := ColorDialog.Color;
end;

procedure TDesignerProperties.DesignerMarkerColorClick(Sender: TObject);
begin
  ColorDialog.Color := MarkerColor.Brush.Color;
  if ColorDialog.Execute then
    MarkerColor.Brush.Color := ColorDialog.Color;
end;

procedure TDesignerProperties.DesignerGridColorClick(Sender: TObject);
begin
  ColorDialog.Color := GridColor.Brush.Color;
  if ColorDialog.Execute then
    GridColor.Brush.Color := ColorDialog.Color;
end;

procedure TDesignerProperties.btnApplyClick(Sender: TObject);
begin
  ApplyChanges;
end;

procedure TDesignerProperties.FormCreate(Sender: TObject);
begin
  SetBounds(Screen.Width - Width - 30, 50, Width, Height);
end;

end.
