unit UI.PromptSelector.VCL;

interface

{$REGION  'Dev notes : UI.PromptSelector.VCL'}

(*
  Unit: UI.PromptSelector.VCL

  Purpose:
    Provides a visual prompt selector control for Delphi VCL applications, enabling users to efficiently browse, select, and display previous prompts (or history items) within the application's interface.
    This unit delivers robust navigation, annotation updates, and user experience improvements for prompt handling scenarios.

  Architecture and Design:
    - Follows project standards for pragmatic, maintainable UI logic without enforcing strict MVC/MVP/MVVM separation, aligning with quick prototyping and developer onboarding priorities.
    - Centralizes all prompt selection, navigation, and annotation-update logic inside a self-contained class (TPromptSelectorVCL).
    - Leverages injected references to core VCL controls (panel, memo, navigation buttons, and labels) for straightforward UI binding and extensibility.
    - Synchronizes selection state with auxiliary components such as the persistent prompt/chat history and file/web/reasoning annotators.
    - Applies UI appearance and interaction standards via dedicated style helpers (see UI.Styles.VCL).

  Technical Features:
    - Supports intuitive navigation through prompt history using up/down buttons and index display.
    - Provides immediate UI feedback and annotation updates as the user selects different prompts.
    - Can be programmatically shown or hidden, and refreshed to synchronize with changing data sources.
    - Minimizes UI state wiring by centralizing refresh and navigation logic.

  Usage:
    - Instantiate TPromptSelectorVCL once with the relevant panel, memo, label, and navigation buttons.
    - Call Update whenever the underlying prompt history changes to refresh the selector.
    - Use the Show, Hide, and ItemIndex members for UI and selection management.

  Dependencies:
    - Requires VCL standard controls, UI.Styles.VCL for styling integration, and prompt/history management components for data linkage.

  This unit is provided as a ready-to-integrate component following File2knowledgeAI UI and architecture conventions, facilitating clear prompt history navigation and extensible, maintainable code structure.
*)

{$ENDREGION}

uses
  System.SysUtils, System.Classes, Winapi.Windows,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.Controls, Vcl.Buttons, Vcl.ExtCtrls,
  Manager.Intf, Manager.Types, Manager.Utf8Mapping,
  UI.Styles.VCL;

type
  /// <summary>
  /// Implements a visual prompt selector component for Delphi VCL applications.
  /// </summary>
  /// <remarks>
  /// <para>
  /// Provides a user interface for navigating and displaying a list of prompts.
  /// Includes up/down navigation buttons, visual feedback, and annotations for prompt history.
  /// </para>
  /// <para>
  /// Follows the application’s UI and style conventions.
  /// </para>
  /// </remarks>
  TPromptSelectorVCL = class(TInterfacedObject, IPromptSelector)
  private
    FPanel: TPanel;
    FPrompt: TMemo;
    FLabel: TLabel;
    FUpButton: TSpeedButton;
    FDownButton: TSpeedButton;
    FItemIndex: Integer;
    FCount: Integer;
    procedure SetPanel(const Value: TPanel);
    procedure SetPrompt(const Value: TMemo);
    procedure SetLabel(const Value: TLabel);
    procedure SetUpButton(const Value: TSpeedButton);
    procedure SetDownButton(const Value: TSpeedButton);
    procedure SetItemIndex(const Value: Integer);
    function GetItemIndex: Integer;
    procedure Refresh;
  protected
    procedure HandleUpButton(Sender: TObject);
    procedure HandleDownButton(Sender: TObject);
    procedure HandlePromptClick(Sender: TObject);
  public
    /// <summary>
    /// Constructs and initializes the prompt selector UI.
    /// </summary>
    /// <param name="APanel">The panel container to host the selector controls.</param>
    /// <param name="APrompt">The TMemo control used to display the prompt text.</param>
    /// <param name="ALabel">The label showing the current prompt index and count.</param>
    /// <param name="AUpButton">Button for navigating to the next prompt in the list.</param>
    /// <param name="ADownButton">Button for navigating to the previous prompt in the list.</param>
    constructor Create(const APanel: TPanel; const APrompt: TMemo; const ALabel: TLabel;
      AUpButton, ADownButton: TSpeedButton);

    /// <summary>
    /// Updates the prompt selector UI to reflect current application state.
    /// </summary>
    /// <remarks>
    /// <para>
    /// Refreshes the display, sets the item count and current index,
    /// and updates all related visual elements according to the prompt data.
    /// </para>
    /// </remarks>
    procedure Update;

    /// <summary>
    /// Hides the prompt selector panel from the user interface.
    /// </summary>
    procedure Hide;

    /// <summary>
    /// Shows the prompt selector panel in the user interface.
    /// </summary>
    procedure Show;

    /// <summary>
    /// Gets or sets the currently selected prompt index.
    /// </summary>
    /// <returns>
    /// The zero-based index of the currently selected prompt.
    /// </returns>
    property ItemIndex: Integer read GetItemIndex write SetItemIndex;
  end;

implementation

{ TPromptSelectorVCL }

constructor TPromptSelectorVCL.Create(const APanel: TPanel;
  const APrompt: TMemo; const ALabel: TLabel; AUpButton,
  ADownButton: TSpeedButton);
begin
  inherited Create;
  SetPanel(APanel);
  SetPrompt(APrompt);
  SetLabel(ALabel);
  SetUpButton(AUpButton);
  SetDownButton(ADownButton);
end;

function TPromptSelectorVCL.GetItemIndex: Integer;
begin
  Result := FItemIndex;
end;

procedure TPromptSelectorVCL.HandleDownButton(Sender: TObject);
begin
  if ItemIndex > 0 then
    begin
      ItemIndex := ItemIndex - 1;
      Refresh;
    end;
  ServicePrompt.SetFocus;
end;

procedure TPromptSelectorVCL.HandlePromptClick(Sender: TObject);
begin
  ServicePrompt.SetFocus;
end;

procedure TPromptSelectorVCL.HandleUpButton(Sender: TObject);
begin
  if ItemIndex < FCount - 1 then
    begin
      ItemIndex := ItemIndex + 1;
      Refresh;
    end;
  ServicePrompt.SetFocus;
end;

procedure TPromptSelectorVCL.Hide;
begin
  FPanel.Visible := False;
end;

procedure TPromptSelectorVCL.Refresh;
begin
  var CurrentPrompt := PersistentChat.CurrentChat.Data[PromptSelector.ItemIndex];
  ChatSessionHistoryView.UpdateAnnotation(FileSearchDisplayer, CurrentPrompt.FileSearch);
  ChatSessionHistoryView.UpdateAnnotation(WebSearchDisplayer, CurrentPrompt.WebSearch);
  ChatSessionHistoryView.UpdateAnnotation(ReasoningDisplayer, CurrentPrompt.Reasoning);
end;

procedure TPromptSelectorVCL.SetDownButton(const Value: TSpeedButton);
begin
  FDownButton := Value;
  TAppStyle.ApplyPromptSelectorDownButtonStyle(Value,
    procedure
    begin
      FDownButton.OnClick := HandleDownButton;
    end);
end;

procedure TPromptSelectorVCL.SetItemIndex(const Value: Integer);
begin
  FItemIndex := Value;
  if FItemIndex < 0 then
    FItemIndex := 0;
  if FItemIndex >= FCount  then
    FItemIndex := FCount - 1;

  FLabel.Caption := Format('Prompt %d/%d', [FItemIndex + 1, FCount]);
  FPrompt.Lines.Text := PersistentChat.CurrentChat.Data[FItemIndex].Prompt;
  FPanel.Visible := True;
end;

procedure TPromptSelectorVCL.SetLabel(const Value: TLabel);
begin
  FLabel := Value;
  TAppStyle.ApplyPromptSelectorLabelStyle(Value);
end;

procedure TPromptSelectorVCL.SetPanel(const Value: TPanel);
begin
  FPanel := Value;
  TAppStyle.ApplyPromptSelectorPanelStyle(FPanel);
end;

procedure TPromptSelectorVCL.SetPrompt(const Value: TMemo);
begin
  FPrompt := Value;
  TAppStyle.ApplyPromptSelectorMemoStyle(Value,
    procedure
    begin
      FPrompt.OnClick := HandlePromptClick;
    end);
end;

procedure TPromptSelectorVCL.SetUpButton(const Value: TSpeedButton);
begin
  FUpButton := Value;
  TAppStyle.ApplyPromptSelectorUpButtonStyle(Value,
    procedure
    begin
      FUpButton.OnClick := HandleUpButton;
    end);
end;

procedure TPromptSelectorVCL.Show;
begin
  FPanel.Visible := True;
end;

procedure TPromptSelectorVCL.Update;
begin
  if PersistentChat.Count = 0 then
    begin
      FItemIndex := -1;
      FCount := 0;
      FPanel.Visible := False;
    end
  else
    begin
      if Assigned(PersistentChat.CurrentChat) then
        begin
          FCount := PersistentChat.CurrentChat.Count;
          ItemIndex := FCount - 1;
        end
      else
        begin
          FPanel.Visible := False;
        end;
    end;
end;

end.
