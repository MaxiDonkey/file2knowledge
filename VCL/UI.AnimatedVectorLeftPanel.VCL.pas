unit UI.AnimatedVectorLeftPanel.VCL;

interface

{$REGION  'Dev notes : UI.AnimatedVectorLeftPanel.VCL'}

(*
  Unit: UI.AnimatedVectorLeftPanel.VCL

  Purpose:
    This unit provides logic and UI integration for a collapsible, animated left panel in a Delphi VCL application.
    The panel is designed to host and display a scrollable list of resource containers (typically AI/vector resource representations),
    supporting animated open/close states, creation of new resource entries, and responsive resizing.
    It enhances the user experience with visual feedback and efficient management of the left navigation/workspace area.

  Technical details:
    - Introduces TLeftPanelControl, encapsulating all behavior for the left panel: expansion/collapse, animation,
      and event-driven UI refresh.
    - Implements asynchronous panel width transitions using TTask and TThread.Queue for smooth, non-blocking animation.
    - Supports four main control buttons: open, close, new-left, new-right. Button appearance and events are managed centrally,
      leveraging custom styling and accessibility hints.
    - Uses a delegate (TProc<TObject>) for reacting to size changes and external UI update requests.
    - The panel interacts with an external resource manager to dynamically instantiate and populate resource containers inside a ScrollBox.
    - All resource loading, assignment, and container selection logic is managed via the `Repaint` and `Refresh` methods,
      ensuring effective UI/data synchronization.
    - Strong separation of concerns: panel animation/UI control is kept independent of the underlying resource models and business logic.

  Dependencies:
    - Delphi VCL visual components: TPanel, TScrollBox, TButton.
    - Requires UI.Container.VCL for the displayed resource containers.
    - Relies on UI.Styles.VCL for consistent button appearance and design guidelines.
    - Uses Manager.Intf for dependency inversion and integration with business logic/managers.
    - System.Threading for concurrent/asynchronous UI transitions.
    - Standard Delphi units for events, messages, and system classes.

  Quick start for developers:
    - Instantiate TLeftPanelControl, providing required button and panel/control references from your form.
    - Call `Refresh` to repopulate the panel; use the State property (opened/closed) for programmatic control of the panel’s display state.
    - Integrate the supplied ProcResize callback to handle dynamic resizing or other UI adjustments in response to panel state changes.
    - Panel population and resource item selection are handled automatically,
      with events wired to trigger new resource creation, selection, and name changes as appropriate.

  This unit is ideal for building modern, interactive navigation or resource selection panels in Delphi VCL applications,
  enabling a dynamic user workspace while keeping logic maintainable and visually smooth.

*)

{$ENDREGION}

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.Threading,
  Vcl.StdCtrls, Vcl.Controls, Vcl.ExtCtrls, VCL.Forms, UI.Container.VCL,
  Manager.Intf, Manager.Types, UI.Styles.VCL;

type
  TOpenCloseState = (opened, closed);

  TLeftPanelControlIntroducer = record
    OpenBtn: TButton;
    CloseBtn: TButton;
    NewLeftBtn: TButton;
    NewRightBtn: TButton;
    Panel: TPanel;
    CaptionPanel: TPanel;
    ScrollBox: TScrollBox;
    class function Empty: TLeftPanelControlIntroducer; static;
  end;

  TLeftPanelControlIntroducerHelper = record Helper for TLeftPanelControlIntroducer
    function SetOpenBtn(Value: TButton): TLeftPanelControlIntroducer; inline;
    function SetCloseBtn(Value: TButton): TLeftPanelControlIntroducer; inline;
    function SetNewLeftBtn(Value: TButton): TLeftPanelControlIntroducer; inline;
    function SetNewRightBtn(Value: TButton): TLeftPanelControlIntroducer; inline;
    function SetPanel(Value: TPanel): TLeftPanelControlIntroducer; inline;
    function SetCaptionPanel(Value: TPanel): TLeftPanelControlIntroducer; inline;
    function SetScrollBox(Value: TScrollBox): TLeftPanelControlIntroducer; inline;
  end;

  /// <summary>
  /// Provides an animated, collapsible left panel control for Delphi VCL applications,
  /// supporting resource navigation, workspace management, and smooth UI transitions.
  /// </summary>
  /// <remarks>
  /// <para>
  /// - The <c>TLeftPanelControl</c> class encapsulates all behaviors, state transitions, and UI interactions
  /// for a left-side navigation or workspace panel in a VCL application. It orchestrates panel animation,
  /// open/close toggling, creation of new resource containers, and event-driven resizing—enabling an efficient,
  /// modern UX for chat, resource, or session navigation scenarios.
  /// </para>
  /// <para>
  /// - The control integrates seamlessly with external business logic and resource managers via dependency
  /// inversion, delegates (TProc&lt;TObject&gt;), and strong separation of concerns. Responsive, asynchronous
  /// animation is implemented using <c>TTask</c> and <c>TThread.Queue</c> for non-blocking UI experience.
  /// </para>
  /// <para>
  /// - Four primary action buttons are managed centrally for open, close, and new-entry creation, all styled
  /// according to File2knowledgeAI and VCL design guidelines.
  /// </para>
  /// Instantiate <c>TLeftPanelControl</c> with required UI component references and resize callback:
  /// <code>
  /// var PanelControl := TLeftPanelControl.Create(Introducer, OnResizeCallback);
  /// PanelControl.Refresh;
  /// PanelControl.State := opened;
  /// </code>
  /// see also "ILeftPanelControl" and "UI.Container.VCL"
  /// </remarks>
  TLeftPanelControl = class(TInterfacedObject, ILeftPanelControl)
  const MINWIDTH = 0;
  const MAXWIDTH = 350;
  private
    FScrollBox: TScrollBox;
    FCloseBtn: TButton;
    FOpenBtn: TButton;
    FNewLeftBnt: TButton;
    FNewRightBtn: TButton;
    FPanel: TPanel;
    FCaptionPanel: TPanel;
    FState: TOpenCloseState;
    FResize: TProc<TObject>;
    procedure SetScrollBox(const Value: TScrollBox);
    procedure SetCloseBtn(const Value: TButton);
    procedure SetOpenBtn(const Value: TButton);
    procedure SetNewLeftBtn(const Value: TButton);
    procedure SetNewRightBtn(const Value: TButton);
    procedure SetPanel(const Value: TPanel);
    procedure SetCaptionPanel(const Value: TPanel);
    procedure SetState(const Value: TOpenCloseState);
    procedure SetButtonProperties(const AButton: TButton; ACaption, AHint: string; AEvent: TNotifyEvent);
  protected
    procedure Effect(Panel: TPanel; const StartW, EndW: Integer);
    procedure AnimatePanelAsync(APanel: TPanel; const TargetWidth: Integer);
    procedure Animation(Panel: TPanel; const StartW, EndW: Integer);

    procedure HandleOpen;
    procedure HandleClose;
    procedure Repaint;
  public
    constructor Create(const Introducer: TLeftPanelControlIntroducer; const ProcResize: TProc<TObject>);

    /// <summary>
    /// Handles panel switch events, toggling the panel between opened and closed states.
    /// </summary>
    /// <param name="Sender">The object that initiated the switch operation (typically a button).</param>
    procedure HandleSwitch(Sender: TObject);

    /// <summary>
    /// Handles creation of a new conversation/resource entry in the panel.
    /// Resets any persistent or selection state and prepares the workspace for a fresh entry.
    /// </summary>
    /// <param name="Sender">The control or component that triggered the new entry action.</param>
    procedure HandleNew(Sender: TObject);

    /// <summary>
    /// Refreshes the contents of the left panel,
    /// repopulating its scroll box with the latest resource containers and updating their states.
    /// </summary>
    procedure Refresh;

    /// <summary>
    /// Selects the resource container by its index in the scroll box,
    /// triggering selection logic and highlighting for navigation or operation.
    /// </summary>
    /// <param name="AIndex">The index of the container to select.</param>
    procedure ItemSelect(const AIndex: Integer);

    /// <summary>
    /// Gets or sets the current opened/closed state of the left panel.
    /// Setting this property programmatically opens or closes the panel with an animated transition.
    /// </summary>
    property State: TOpenCloseState read FState write SetState;
  end;

implementation

{ TLeftPanelControl }

procedure TLeftPanelControl.AnimatePanelAsync(APanel: TPanel;
  const TargetWidth: Integer);
const
  MaxStep = 84;
  MinStep = 4;
  FRAME_PAUSE = 22; // ms
var
  StartWidth, TotalDelta: Integer;
begin
  StartWidth := APanel.Width;
  TotalDelta := TargetWidth - StartWidth;

  if TotalDelta = 0 then
    Exit;

  TTask.Run(
    procedure
    var
      CurW, Remaining, Step: Integer;
      Ratio: Double;
    begin
      CurW := StartWidth;

      while CurW <> TargetWidth do
        begin
          Remaining := TargetWidth - CurW;
          Ratio := Abs(Remaining) / Abs(TotalDelta);
          Step := Round(MinStep + (MaxStep - MinStep) * Ratio);
          if Step > Abs(Remaining) then
            Step := Abs(Remaining);

          if Remaining < 0 then
            Step := -Step;

          Inc(CurW, Step);

          TThread.Queue(nil,
            procedure
            begin
              APanel.DisableAlign;
              try
                APanel.Parent.DisableAlign;
                try
                  APanel.SetBounds(APanel.Left, APanel.Top, CurW, APanel.Height);
                  APanel.Update;
                  FResize(nil);
                finally
                  APanel.Parent.EnableAlign;
                end;
              finally
                APanel.EnableAlign;
              end;
            end);

          Sleep(FRAME_PAUSE);
        end;
    end);
end;

procedure TLeftPanelControl.Animation(Panel: TPanel; const StartW,
  EndW: Integer);
begin
  Panel.DisableAlign;
  Panel.Parent.DisableAlign;
  try
    Effect(Panel, StartW, EndW);
  finally
    Panel.Parent.EnableAlign;
    Panel.EnableAlign;
  end;
end;

constructor TLeftPanelControl.Create(const Introducer: TLeftPanelControlIntroducer;
  const ProcResize: TProc<TObject>);
begin
  inherited Create;
  FState := closed;
  SetCloseBtn(Introducer.CloseBtn);
  SetOpenBtn(Introducer.OpenBtn);
  SetNewLeftBtn(Introducer.NewLeftBtn);
  SetNewRightBtn(Introducer.NewRightBtn);
  SetPanel(Introducer.Panel);
  SetCaptionPanel(Introducer.CaptionPanel);
  SetScrollBox(Introducer.ScrollBox);
  FResize := ProcResize;
end;

procedure TLeftPanelControl.Effect(Panel: TPanel; const StartW, EndW: Integer);
var
  Step   : Integer;
  CurW   : Integer;
begin
  if StartW = EndW then
    Exit;

  if StartW < EndW then
    Step := 6 else
    Step := -6;
  CurW := StartW;
  while CurW <> EndW do
    begin
      Inc(CurW, Step);
      if (Step > 0) and (CurW > EndW) or
         (Step < 0) and (CurW < EndW) then
        CurW := EndW;
      Panel.Width := CurW;
      Panel.Update;
      Sleep(12);
    end;
end;

procedure TLeftPanelControl.SetButtonProperties(const AButton: TButton; ACaption,
  AHint: string; AEvent: TNotifyEvent);
begin
  TAppStyle.ApplyAnimatedVectorLeftPanelButtonStyle(AButton,
    procedure
    begin
      AButton.Caption := ACaption;
      AButton.Hint := AHint;
      AButton.OnClick := AEvent;
    end);
end;

procedure TLeftPanelControl.SetCaptionPanel(const Value: TPanel);
begin
  FCaptionPanel := Value;
end;

procedure TLeftPanelControl.SetCloseBtn(const Value: TButton);
begin
  FCloseBtn := Value;
  SetButtonProperties(FCloseBtn, '', 'Hide the panel  F9', HandleSwitch);
end;

procedure TLeftPanelControl.SetNewLeftBtn(const Value: TButton);
begin
  FNewLeftBnt := Value;
  SetButtonProperties(FNewLeftBnt, '', 'New conversation  Ctrl+N', HandleNew);
end;

procedure TLeftPanelControl.SetNewRightBtn(const Value: TButton);
begin
  FNewRightBtn := Value;
  SetButtonProperties(FNewRightBtn, '', 'New conversation  Ctrl+N', HandleNew);
end;

procedure TLeftPanelControl.SetOpenBtn(const Value: TButton);
begin
  FOpenBtn := Value;
  SetButtonProperties(FOpenBtn, '', 'Show the panel  F9', HandleSwitch);
end;

procedure TLeftPanelControl.SetPanel(const Value: TPanel);
begin
  FPanel := Value;
  FPanel.Width := MINWIDTH;
end;

procedure TLeftPanelControl.SetScrollBox(const Value: TScrollBox);
begin
  FScrollBox := Value;
end;

procedure TLeftPanelControl.SetState(const Value: TOpenCloseState);
begin
  FState := Value;
  case FState of
    opened: HandleOpen;
    closed: HandleClose;
  end;
end;

procedure TLeftPanelControl.HandleClose;
begin
  FCaptionPanel.Visible := True;
  FCloseBtn.Visible := False;
  FNewLeftBnt.Visible := False;
  AnimatePanelAsync(FPanel, MINWIDTH);
end;

procedure TLeftPanelControl.HandleNew(Sender: TObject);
begin
  try
    EdgeDisplayer.Hide;
    PersistentChat.Clear;
    EdgeDisplayer.Clear;
    FileSearchDisplayer.Clear;
    WebSearchDisplayer.Clear;
    ReasoningDisplayer.Clear;
    Selector.ShowPage(psHistoric);
    PromptSelector.Hide;
  finally
    ServicePrompt.SetFocus;
  end;
end;

procedure TLeftPanelControl.HandleOpen;
begin
  FCaptionPanel.Visible := False;
  FCloseBtn.Visible := True;
  FNewLeftBnt.Visible := True;
  AnimatePanelAsync(FPanel, MAXWIDTH);
end;

procedure TLeftPanelControl.HandleSwitch(Sender: TObject);
begin
  try
    State := TOpenCloseState((Integer(State) + 1) mod 2);
  finally
    ServicePrompt.SetFocus;
  end;
end;

procedure TLeftPanelControl.ItemSelect(const AIndex: Integer);
begin
  TContainer.ContainerSelect(AIndex);
end;

procedure TLeftPanelControl.Refresh;
begin
  try
    FScrollBox.Perform(WM_SETREDRAW, WPARAM(FALSE), 0);
    try
      FScrollBox.DisableAlign;
      try
        {--- WEAK POINT: delete then rebuild everything is stupid!!  }
        while FScrollBox.ControlCount > 0 do
          FScrollBox.Controls[0].Free;
        Repaint;
      finally
        FScrollBox.EnableAlign;
      end;
    finally
      FScrollBox.Perform(WM_SETREDRAW, WPARAM(TRUE), 0);
    end;
  finally
    FScrollBox.Realign;
    RedrawWindow(FScrollBox.Handle,
      nil, 0,
      RDW_ERASE or RDW_INVALIDATE or RDW_FRAME or RDW_ALLCHILDREN);
  end;
end;

procedure TLeftPanelControl.Repaint;
begin
  if FileStoreManager.JSONExists then
    try
      FileStoreManager.LoadValues
    except
      FileStoreManager.DefaultValues;
    end
  else
    FileStoreManager.DefaultValues;

  FileStoreManager
    .AttachTo(FScrollBox,
      {--- Method for OnMouseDown event of a TContainer class }
      procedure (Sender: TObject)
      begin
        if Sender is TContainer then
          begin
            var Container := Sender as TContainer;
            if Container.Index = FileStoreManager.ItemIndex then
              Exit;

            LeftPanelControl.HandleNew(nil);
            FileStoreManager.ItemIndex := Container.Index;
            FileStoreManager.Name := Container.DisplayName;
            FileStoreManager.UpdateCurrent;
            Container.Select(FileStoreManager.ItemIndex);
            FileStoreManager.SaveToFile;
          end;
      end);
  ItemSelect(FileStoreManager.ItemIndex);
end;

{ TLeftPanelControlIntroducer }

class function TLeftPanelControlIntroducer.Empty: TLeftPanelControlIntroducer;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

{ TLeftPanelControlIntroducerHelper }

function TLeftPanelControlIntroducerHelper.SetCaptionPanel(
  Value: TPanel): TLeftPanelControlIntroducer;
begin
  Self.CaptionPanel := Value;
  Result := Self;
end;

function TLeftPanelControlIntroducerHelper.SetCloseBtn(
  Value: TButton): TLeftPanelControlIntroducer;
begin
  Self.CloseBtn := Value;
  Result := Self;
end;

function TLeftPanelControlIntroducerHelper.SetNewLeftBtn(
  Value: TButton): TLeftPanelControlIntroducer;
begin
  Self.NewLeftBtn := Value;
  Result := Self;
end;

function TLeftPanelControlIntroducerHelper.SetNewRightBtn(
  Value: TButton): TLeftPanelControlIntroducer;
begin
  Self.NewRightBtn := Value;
  Result := Self;
end;

function TLeftPanelControlIntroducerHelper.SetOpenBtn(
  Value: TButton): TLeftPanelControlIntroducer;
begin
  Self.OpenBtn := Value;
  Result := Self;
end;

function TLeftPanelControlIntroducerHelper.SetPanel(
  Value: TPanel): TLeftPanelControlIntroducer;
begin
  Self.Panel := Value;
  Result := Self;
end;

function TLeftPanelControlIntroducerHelper.SetScrollBox(
  Value: TScrollBox): TLeftPanelControlIntroducer;
begin
  Self.ScrollBox := Value;
  Result := Self;
end;

end.
