unit UI.Container.VCL;

interface

{$REGION  'Dev notes : UI.Container.VCL'}

(*
    Note on the Implementation of the Internal Registry in TContainer

    The TContainer class, which inherits from TPanel, includes an internal registry (FRegistry) listing all
    its active instances. This approach addresses the need for simple and efficient tracking of decorative
    panels added to a TScrollBox, without requiring an external, heavier management system that would be
    unsuitable for the intended purpose of the class.

    It's true that this solution departs from strict separation of concerns: the instance tracking logic is
    embedded directly in the purely visual component. However, this compromise is fully intentional:
    TContainer is intended only to decorate a TScrollBox—it should not handle anything beyond its sole and
    specific visual purpose, managed in a straightforward and self-contained way.
    Adding an external manager would unnecessarily complicate things for this particular use case.

    Simple integration and usage
    Lightweight in terms of memory and code management
    Responsibility limited to what is strictly necessary
    This remains an area open for improvement: in a production solution or different context, it could make
    sense to isolate this logic using a dedicated manager or registry, in line with stricter architectural
    principles.
    Nevertheless, this implementation is outside the scope of the current application, which focuses
    primarily on demonstrating best practices regarding the use of the v1/responses endpoint: clarity,
    simplicity, and practical effectiveness in the example.
*)

{$ENDREGION}

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI,
  System.SysUtils, System.Classes, System.Generics.Collections, System.Types,
  Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Graphics, Vcl.Buttons, Vcl.Menus, Vcl.Forms, Vcl.Dialogs,
  Helper.PanelRoundedCorners.VCL, UI.Styles.VCL, Manager.WebServices, Manager.Intf, Manager.Types;

type
  TContainer = class;
  TContainerRegistry = TObjectList<TContainer>;

  TContainer = class(TPanel)
  strict private

    {--- shared registry; lifetime handled by class }
    class var FRegistry: TContainerRegistry;
    class constructor Create;
    class destructor Destroy;

  private
    FThumbnail: TImage;
    FLabel: TLabel;
    FContextPanel: TPanel;
    FPopupMenu: TPopupMenu;
    FIndex: Integer;
    FSelected: Boolean;
    FSelectionProc: TProc<TObject>;
    FGitHubUrl: string;
    FGetitUrl: string;

    procedure CreatePopupMenu;
    procedure CreateThumbnail;
    procedure CreateLabel;
    procedure CreatePanelButton;

    procedure SetCommonEvents(Component: TControl);

    {--- general events Thumbnail, Label }
    procedure HandleMouseEnter(Sender: TObject);
    procedure HandleMouseLeave(Sender: TObject);
    procedure HandleMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer); virtual;

    {--- special PanelButton events }
    procedure HandleContextMouseEnter(Sender: TObject);
    procedure HandleContextMouseLeave(Sender: TObject);
    procedure HandleContextMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);

    {--- Popup menu events }
    procedure HandlePopupMenuPopup(Sender: TObject);
    procedure HandlePopupMenuClose(Sender: TObject);
    procedure HandleGitHubClick(Sender: TObject);
    procedure HandleGetitClick(Sender: TObject);
    procedure HandlePopupMenuModify(Sender: TObject);

    {--- main getters }
    function GetDisplayName: string;
    function GetDescription: string;
    function GetSelected: Boolean;
    function GetGitHubUrl: string;
    function GetGetitUrl: string;

    {--- Add popup menu item }
    procedure AddPopupItem(const ACaption, AShortCut: string;
      AOnClick: TNotifyEvent);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function ApplyImage(const AStream: TStream): TContainer;
    function ApplyName(const AValue: string): TContainer; reintroduce;
    function ApplyDescription(const AValue: string): TContainer;
    function ApplyTop(const AValue: Integer): TContainer;
    function ApplyIndex(const AValue: Integer): TContainer;
    function ApplySelected(const AValue: Boolean): TContainer;
    function ApplyGitHubUrl(const AValue: string): TContainer;
    function ApplyGetitUrl(const AValue: string): TContainer;
    function OnSelect(AProc: TProc<TObject>): TContainer;

    property DisplayName: string read GetDisplayName;
    property Description: string read GetDescription;
    property Index: Integer read FIndex;
    property Selected: Boolean read GetSelected;
    property GitHubUrl: string read GetGitHubUrl;
    property GetitUrl: string read GetGetitUrl;

    class property Items: TContainerRegistry read FRegistry;
    class function ContainerList: TContainerRegistry;
    class procedure ContainerSelect(const Value: Integer);
    class procedure Select(const AIndex: Integer);
    class procedure Unselect(const AIndex: Integer = -1);
  end;

  function GetTopPosition(const Index: Integer): Integer;

implementation

function GetTopPosition(const Index: Integer): Integer;
begin
  Result := 20 + 66 * Index;
end;

class constructor TContainer.Create;
begin
  {--- Single registry for all instances – list does NOT own the items }
  FRegistry := TContainerRegistry.Create(False);
end;

class destructor TContainer.Destroy;
begin
  FreeAndNil(FRegistry);
end;

class function TContainer.ContainerList: TContainerRegistry;
begin
  Result := FRegistry;
end;

class procedure TContainer.ContainerSelect(const Value: Integer);
begin
  if FRegistry.Count > 0 then
    FRegistry[0].Select(Value);
end;

constructor TContainer.Create(AOwner: TComponent);
begin
  Assert(AOwner is TWinControl, 'AOwner must be a TWinControl');
  inherited Create(AOwner);

  {--- foundation panel }
  Parent := TWinControl(AOwner);
  TAppStyle.ApplyContainerCorePanelStyle(Self,
    procedure
    begin
      Width := 320;
      Height := 58;
      SetCommonEvents(Self);

      {--- PopupMenu
           NOTE: The context menu should be instantiated only once, not for each panel. }
      CreatePopupMenu;

      {--- Hosted controls }
      CreateThumbnail;
      CreateLabel;
      CreatePanelButton;
    end);

  {--- Register instance }
  FRegistry.Add(Self);
end;

procedure TContainer.CreatePopupMenu;
begin
  FPopupMenu := TPopupMenu.Create(Application);
  FPopupMenu.OnPopup := HandlePopupMenuPopup;
  FPopupMenu.OnClose := HandlePopupMenuClose;
  AddPopupItem('GitHub', '', HandleGitHubClick);
  AddPopupItem('Getit', '', HandleGetitClick);
  AddPopupItem('Modify', '', HandlePopupMenuModify);
end;

destructor TContainer.Destroy;
begin
  FRegistry.Remove(Self);
  inherited;
end;

procedure TContainer.AddPopupItem(const ACaption, AShortCut: string;
  AOnClick: TNotifyEvent);
begin
  var Item := TMenuItem.Create(FPopupMenu);
  Item.Caption := ACaption;
  Item.ShortCut := TextToShortCut(AShortCut);
  Item.OnClick := AOnClick;
  FPopupMenu.Items.Add(Item);
end;

procedure TContainer.CreateThumbnail;
begin
  {--- The image container }
  var LPanel := TPanel.Create(Self);
  LPanel.Parent := Self;
  TAppStyle.ApplyContainerBackgroundPanelStyle(LPanel,
    procedure
    begin
      LPanel.SetBounds(8, 4, 50, 50);
    end);

  {--- The image with the rounded edges }
  FThumbnail := TImage.Create(LPanel);
  FThumbnail.Parent := LPanel;
  TAppStyle.ApplyContainerImageStyle(FThumbnail,
    procedure
    begin
      SetCommonEvents(FThumbnail);
    end);
end;

procedure TContainer.CreateLabel;
begin
  FLabel := TLabel.Create(Self);
  FLabel.Parent := Self;
  TAppStyle.ApplyContainerLabelStyle(FLabel,
    procedure
    begin
      FLabel.SetBounds(70, 14, 150, 24);
      FLabel.Transparent := True;
      SetCommonEvents(FLabel);
    end);
end;

procedure TContainer.HandleMouseEnter(Sender: TObject);
begin
  Color := TAppStyle.ApplyContainerMouseEnterColor;
  FLabel.Font.Color := clBlack;
end;

procedure TContainer.HandleMouseLeave(Sender: TObject);
begin
  if not FSelected then
    begin
      Color := TAppStyle.ApplyContainerMouseLeaveColor;
      FLabel.Font.Color := clWhite;
    end;
end;

procedure TContainer.HandlePopupMenuClose(Sender: TObject);
begin

end;

procedure TContainer.HandlePopupMenuModify(Sender: TObject);
begin
  Selector.ShowPage(psVectorFile);
end;

procedure TContainer.HandlePopupMenuPopup(Sender: TObject);
begin
  if FGitHubUrl.Trim.IsEmpty then
    FPopupMenu.Items[0].Enabled := False;

  if FGetitUrl.Trim.IsEmpty then
    FPopupMenu.Items[1].Enabled := False;
end;

procedure TContainer.HandleContextMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  var P := ClientToScreen(Point(Left + Width + 18, Height div 2));
  FPopupMenu.Popup(P.X, P.Y);
end;

procedure TContainer.HandleContextMouseEnter(Sender: TObject);
begin
  FContextPanel.Font.Color := clWhite;
end;

procedure TContainer.HandleContextMouseLeave(Sender: TObject);
begin
  FContextPanel.Font.Color := clBlack;
end;

procedure TContainer.HandleGetitClick(Sender: TObject);
begin
  TWebUrlManager.Open(FGetitUrl);
end;

procedure TContainer.HandleGitHubClick(Sender: TObject);
begin
  TWebUrlManager.Open(FGitHubUrl);
end;

procedure TContainer.HandleMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Assigned(FSelectionProc) then
    FSelectionProc(Self);
  FContextPanel.Visible := FSelected;
end;

function TContainer.GetDescription: string;
begin
  Result := FThumbnail.Hint;
end;

function TContainer.GetDisplayName: string;
begin
  Result := FLabel.Caption;
end;

function TContainer.GetGetitUrl: string;
begin
  Result := FGetitUrl;
end;

function TContainer.GetGitHubUrl: string;
begin
  Result := FGitHubUrl;
end;

function TContainer.GetSelected: Boolean;
begin
  Result := FSelected;
end;

class procedure TContainer.Select(const AIndex: Integer);
begin
  Unselect;

  if (AIndex >= 0) and (AIndex < FRegistry.Count) then
    FRegistry[AIndex].ApplySelected(True);
end;

procedure TContainer.CreatePanelButton;
begin
  FContextPanel := TPanel.Create(Self);
  FContextPanel.Parent := Self;
  TAppStyle.ApplyContainerPanelStyle(FContextPanel,
    procedure
    begin
      FContextPanel.PopupMenu := FPopupMenu;
      FContextPanel.SetBounds(Width - 24, 8, 18, 36);
      FContextPanel.Tag := 1;
      SetCommonEvents(FContextPanel);
    end);

end;

procedure TContainer.SetCommonEvents(Component: TControl);
begin
  if not Assigned(Component) then
    Exit;

  if Component is TLabel then
    begin
      TLabel(Component).OnMouseEnter := HandleMouseEnter;
      TLabel(Component).OnMouseLeave := HandleMouseLeave;
      TLabel(Component).OnMouseDown := HandleMouseDown;
    end
  else
  if Component is TImage then
    begin
      TImage(Component).OnMouseEnter := HandleMouseEnter;
      TImage(Component).OnMouseLeave := HandleMouseLeave;
      TImage(Component).OnMouseDown := HandleMouseDown;
    end
  else
  if Component is TPanel then
    begin
      if Component.Tag = 1 then
        begin
          TPanel(Component).OnMouseEnter := HandleContextMouseEnter;
          TPanel(Component).OnMouseLeave := HandleContextMouseLeave;
          TPanel(Component).OnMouseDown := HandleContextMouseDown;
        end
      else
        begin
          TPanel(Component).OnMouseEnter := HandleMouseEnter;
          TPanel(Component).OnMouseLeave := HandleMouseLeave;
          TPanel(Component).OnMouseDown := HandleMouseDown;
        end;
    end
end;

class procedure TContainer.Unselect(const AIndex: Integer);
begin
  if AIndex = -1 then
    begin
      for var Item in FRegistry do
        Item.ApplySelected(False);
    end
  else
    begin
      if (AIndex >= 0) and (AIndex < FRegistry.Count) then
        FRegistry[AIndex].ApplySelected(False);
    end;
end;

function TContainer.ApplyDescription(const AValue: string): TContainer;
begin
  FThumbnail.Hint := AValue;
  Result := Self;
end;

function TContainer.ApplyGetitUrl(const AValue: string): TContainer;
begin
  FGetitUrl := AValue;
  Result := Self;
end;

function TContainer.ApplyGitHubUrl(const AValue: string): TContainer;
begin
  FGitHubUrl := AValue;
  Result := Self;
end;

function TContainer.ApplyImage(const AStream: TStream): TContainer;
begin
  if Assigned(AStream) then
    try
      FThumbnail.Picture.LoadFromStream(AStream);
    finally
      AStream.Free;
    end;
  Result := Self;
end;

function TContainer.ApplyIndex(const AValue: Integer): TContainer;
begin
  FIndex := AValue;
  Result := Self;
end;

function TContainer.ApplyName(const AValue: string): TContainer;
begin
  FLabel.Caption := AValue;
  Result := Self;
end;

function TContainer.ApplySelected(const AValue: Boolean): TContainer;
begin
  FSelected := AValue;

  if AValue then
    begin
      Color := TAppStyle.ApplyContainerMouseEnterColor;
      FLabel.Font.Color := TAppStyle.ApplyContainerFontSelectedColor;
      FContextPanel.Visible := True;
    end
  else
    begin
      Color := TAppStyle.ApplyContainerMouseLeaveColor;
      FLabel.Font.Color := TAppStyle.ApplyContainerFontUnSelectedColor;
      FContextPanel.Visible := False;
    end;

  Result := Self;
end;

function TContainer.ApplyTop(const AValue: Integer): TContainer;
begin
  Top := AValue;
  Result := Self;
end;

function TContainer.OnSelect(AProc: TProc<TObject>): TContainer;
begin
  FSelectionProc := AProc;
  Result := Self;
end;

end.
