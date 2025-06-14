unit UI.ServiceFeatureSelector.VCL;

interface

{$REGION  'Dev notes : UI.ServiceFeatureSelector.VCL'}

(*
  Unit: UI.ServiceFeatureSelector.VCL

  Purpose:
    This unit implements the interface and business logic for dynamically managing the activation,
    deactivation, and presentation of File2knowledgeAI's main search features within a modern
    Delphi VCL application.
    It connects the visual service bar buttons (web search, file search, reasoning, etc.) to the
    project’s internal mode logic.
    The goal: to centralize and standardize the handling, synchronization, and display of service
    states (Web Search, File Search, Reasoning) while providing immediate user feedback and
    a consistent UX.

  Note on Architecture and Design Choices:
    Following the project’s pragmatic tradition, this unit favors self-contained, straightforward,
    and readable code: UI event handling, service state management, and UI effects are grouped
    together for easy iteration, demos, and rapid onboarding.
    This approach increases clarity while allowing for extensibility (adding modes, new buttons, or
    custom styles).
    The design remains modular enough for future refactoring, should stricter architectural patterns
    (MVC/MVP/MVVM) become necessary.
    The use of record helpers for interfaces and centralization of captions/hints ensures scalability
    and possible multilingual support, with built-in testability.

  Usage:
    Instantiate the selector with your VCL buttons (TSpeedButton) and the main caption label.
    All event wiring, state management, and UI updates are handled automatically to enable
    one-click mode switching and immediate UX enhancement.

  Dependencies:
    - VCL controls: TSpeedButton, TLabel, etc.
    - Project units: Manager.Intf, Manager.IoC, Manager.Types, UI.Styles.VCL
    - Internal helpers for mode management, styles, and UI callbacks.

  File2knowledgeAI project context:
    This unit embodies the best practice of centralizing feature toggling and UX synchronization
    around the new v1/responses endpoint and the product’s multimodal capabilities.
*)

{$ENDREGION}

uses
  Winapi.Windows, Winapi.Messages, Winapi.CommCtrl,
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Buttons, Vcl.StdCtrls,
  Manager.Intf, Manager.IoC, Manager.Types, UI.Styles.VCL;

type
  TChainMode = (cmOpen, cmClose);

  TChainModeHelper = record Helper for TChainMode
  private
    const
      Icons: array[TChainMode] of string = (
        '', ''
      );
      Hints: array[TChainMode] of string = (
        'Disable File_search tool F6',
        'Enable File_search tool F6'
      );
  public
    function ToIcon: string;
    function ToHint: string;
    class function FromBoolean(Value: Boolean): TChainMode; static;
  end;

  TWebSearchHint = (wbEnable, wbDisable);

  TWebSearchHintHelper = record Helper for TWebSearchHint
  private
    const
      Hints: array[TWebSearchHint] of string = (
        'Enable Web Search F5',
        'Disable Web Search F5'
      );
  public
    function ToHint: string;
    class function FromBoolean(Value: Boolean): TWebSearchHint; static;
  end;

  TReasoningHint = (rEnable, rDisable);

  TReasoningHintHelper = record Helper for TReasoningHint
  private
     const
      Hints: array[TReasoningHint] of string = (
        'Enable Reasoning'#10'File_search disable F7',
        'Disable Reasoning'#10'File_search enable F7'
      );
  public
    function ToHint: string;
    class function FromBoolean(Value: Boolean): TReasoningHint; static;
  end;

  TMainCaptionType = (
    mcFileSearchActive,
    mcWebFileSearchActive,
    mcFileSearchDisabled,
    mcWebSearchActive,
    mcReasoningActive);

  TMainCaptionTypeHelper = record Helper for TMainCaptionType
  private
    const
      Labels: array[TMainCaptionType] of string = (
       'File Search Only',
       'Web && File Search',
       'File Search Disabled',
       'Web Search Only',
       'Reasoning Mode (Web && File Search Disabled)'
      );
  public
    function ToString: string;
    class function FromFeatureModes(Value: TFeatureModes): TMainCaptionType; static;
  end;


  /// <summary>
  /// UI and logic orchestrator for File2knowledgeAI main feature toggles in a Delphi VCL application.
  /// </summary>
  /// <remarks>
  /// TServiceFeatureSelector centralizes all event wiring, state management, and UI feedback related
  /// to toggling the core service modes—Web Search, File Search, and Reasoning.
  /// Through its constructor, you bind VCL controls (TSpeedButton and TLabel) for immediate
  /// synchronization of internal states with user-facing UI elements and captions.
  ///
  /// This class streamlines user experience by ensuring that visual control state, feature mode, and
  /// contextual hints/captions always remain coherent, and that switching one feature correctly
  /// updates the others as per the service logic.
  ///
  /// <para>
  /// The pragmatic, consolidated design emphasizes demo-readiness, maintainability, and fast
  /// onboarding, while still allowing for later modularization if stricter architectural separation is
  /// needed.
  /// </para>
  /// <para>
  /// This implementation is core to File2knowledgeAI's best practice of keeping dynamic UX features
  /// (mode switching, feature availability, etc.) synchronized with business logic and endpoint capabilities.
  /// </para>
  ///
  /// <param name="AWebSearchButton">Button to activate/deactivate Web Search mode.</param>
  /// <param name="ADisableFileSearchButton">Button to enable/disable File Search mode.</param>
  /// <param name="AReasoningButton">Button to enable/disable Reasoning mode (which also disables
  /// Web Search).</param>
  /// <param name="ACaptionLabel">Label control for displaying the current main caption, reflecting
  /// combined feature state.</param>
  /// </remarks>
  TServiceFeatureSelector = class(TInterfacedObject, IServiceFeatureSelector)
  private
    FWebSearchButton: TSpeedButton;
    FDisableFileSearchButton: TSpeedButton;
    FReasoningButton: TSpeedButton;
    FCaptionLabel: TLabel;
    procedure SetWebSearchButton(const Value: TSpeedButton);
    procedure SetDisableFileSearchButton(const Value: TSpeedButton);
    procedure SetReasoningButton(const Value: TSpeedButton);
    procedure SetCaptionLabel(const Value: TLabel);
    function GetFeatureModes: TFeatureModes;
    procedure HandleWebSearchButtonClick(Sender: TObject);
    procedure HandleDisableFileSearchButtonClick(Sender: TObject);
    procedure HandleReasoningButtonClick(Sender: TObject);
    procedure HintAndCaptionUpdate;
    procedure HandleCaptionOnMouseEnter(Sender: TObject);
    procedure HandleCaptionOnMouseLeave(Sender: TObject);
    procedure HandleCaptionOnMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Activate(const Value: TSpeedButton);
  public
    constructor Create(const AWebSearchButton, ADisableFileSearchButton, AReasoningButton: TSpeedButton;
      const ACaptionLabel: TLabel);

    /// <summary>
    /// Programmatically toggles the Web Search mode, updating both internal state and UI accordingly.
    /// </summary>
    procedure SwitchWebSearch;

    /// <summary>
    /// Programmatically toggles the File Search feature disable mode, updating internal state and the UI.
    /// </summary>
    procedure SwitchDisableFileSearch;

    /// <summary>
    /// Programmatically toggles the Reasoning mode, enforcing the required disabling of Web Search and updating the UI.
    /// </summary>
    procedure SwitchReasoning;

    /// <summary>
    /// Gets the current combination of feature modes (Web Search, File Search Disabled, Reasoning)
    /// as reflected by the UI state of the corresponding buttons.
    /// </summary>
    property FeatureModes: TFeatureModes read GetFeatureModes;
  end;

implementation

{ TServiceFeatureSelector }

procedure TServiceFeatureSelector.Activate(const Value: TSpeedButton);
begin
  Value.Down := not Value.Down;
  Value.Click;
end;

constructor TServiceFeatureSelector.Create(const AWebSearchButton,
  ADisableFileSearchButton, AReasoningButton: TSpeedButton;
  const ACaptionLabel: TLabel);
begin
  inherited Create;
  SetWebSearchButton(AWebSearchButton);
  SetDisableFileSearchButton(ADisableFileSearchButton);
  SetReasoningButton(AReasoningButton);
  SetCaptionLabel(ACaptionLabel);
  HintAndCaptionUpdate;
end;

function TServiceFeatureSelector.GetFeatureModes: TFeatureModes;
begin
  Result := [];
  if FWebSearchButton.Down then
    Result := Result + [sf_webSearch];
  if FDisableFileSearchButton.Down then
    Result := Result + [sf_fileSearchDisabled];
  if FReasoningButton.Down then
    Result := Result + [sf_reasoning];
end;

procedure TServiceFeatureSelector.HandleCaptionOnMouseEnter(Sender: TObject);
begin
  FCaptionLabel.Font.Style := [fsBold,fsUnderline];
  FCaptionLabel.Cursor := crHandPoint;
end;

procedure TServiceFeatureSelector.HandleCaptionOnMouseLeave(Sender: TObject);
begin
  FCaptionLabel.Font.Style := [fsBold];
  FCaptionLabel.Cursor := crDefault;
end;

procedure TServiceFeatureSelector.HandleCaptionOnMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Selector.ShowPage(psSettings);
end;

procedure TServiceFeatureSelector.HandleDisableFileSearchButtonClick(
  Sender: TObject);
begin
  HintAndCaptionUpdate;
end;

procedure TServiceFeatureSelector.HandleReasoningButtonClick(Sender: TObject);
begin
  FWebSearchButton.Down := False;
  HintAndCaptionUpdate;
end;

procedure TServiceFeatureSelector.HandleWebSearchButtonClick(Sender: TObject);
begin
  if FReasoningButton.Down then
    FWebSearchButton.Down := False;
  HintAndCaptionUpdate;
end;

procedure TServiceFeatureSelector.HintAndCaptionUpdate;
begin
  FWebSearchButton.Hint := TWebSearchHint.FromBoolean(FWebSearchButton.Down).ToHint;
  FDisableFileSearchButton.Hint := TChainMode.FromBoolean(FDisableFileSearchButton.Down).ToHint;
  FDisableFileSearchButton.Caption := TChainMode.FromBoolean(FDisableFileSearchButton.Down).ToIcon;
  FReasoningButton.Hint :=  TReasoningHint.FromBoolean(FReasoningButton.Down).ToHint;
  FCaptionLabel.Caption := TMainCaptionType.FromFeatureModes(FeatureModes).ToString;
end;

procedure TServiceFeatureSelector.SetCaptionLabel(const Value: TLabel);
begin
  FCaptionLabel := Value;
  TAppStyle.ApplyCaptionLabelStyle(Value,
    procedure
    begin
      FCaptionLabel.OnMouseEnter := HandleCaptionOnMouseEnter;
      FCaptionLabel.OnMouseLeave := HandleCaptionOnMouseLeave;
      FCaptionLabel.OnMouseUp := HandleCaptionOnMouseUp;
    end);
end;

procedure TServiceFeatureSelector.SetDisableFileSearchButton(
  const Value: TSpeedButton);
begin
  FDisableFileSearchButton := Value;
  TAppStyle.ApplyDisableFileSearchButtonStyle(Value,
    procedure
    begin
      FDisableFileSearchButton.OnClick := HandleDisableFileSearchButtonClick;
    end);
end;

procedure TServiceFeatureSelector.SetReasoningButton(const Value: TSpeedButton);
begin
  FReasoningButton := Value;
  TAppStyle.ApplyReasoningButtonStyle(Value,
    procedure
    begin
      FReasoningButton.OnClick := HandleReasoningButtonClick;
    end)
end;

procedure TServiceFeatureSelector.SetWebSearchButton(const Value: TSpeedButton);
begin
  FWebSearchButton := Value;
  TAppStyle.ApplyWebSearchButtonStyle(Value,
    procedure
    begin
      FWebSearchButton.OnClick := HandleWebSearchButtonClick;
    end);
end;

procedure TServiceFeatureSelector.SwitchDisableFileSearch;
begin
  Activate(FDisableFileSearchButton);
end;

procedure TServiceFeatureSelector.SwitchReasoning;
begin
  Activate(FReasoningButton);
end;

procedure TServiceFeatureSelector.SwitchWebSearch;
begin
  Activate(FWebSearchButton);
end;

{ TChainModeHelper }

class function TChainModeHelper.FromBoolean(Value: Boolean): TChainMode;
begin
  Result := TChainMode(Ord(Value));
end;

function TChainModeHelper.ToHint: string;
begin
  Result := Hints[Self];
end;

function TChainModeHelper.ToIcon: string;
begin
  Result := Icons[Self];
end;

{ TWebSearchHintHelper }

class function TWebSearchHintHelper.FromBoolean(Value: Boolean): TWebSearchHint;
begin
  Result := TWebSearchHint(Ord(Value));
end;

function TWebSearchHintHelper.ToHint: string;
begin
  Result := Hints[Self];
end;

{ TReasoningHintHelper }

class function TReasoningHintHelper.FromBoolean(Value: Boolean): TReasoningHint;
begin
  Result := TReasoningHint(Ord(Value));
end;

function TReasoningHintHelper.ToHint: string;
begin
  Result := Hints[Self];
end;

{ TMainCaptionTypeHelper }

class function TMainCaptionTypeHelper.FromFeatureModes(
  Value: TFeatureModes): TMainCaptionType;
begin
  Result := TMainCaptionType(PByte(@Value)^);
end;

function TMainCaptionTypeHelper.ToString: string;
begin
  Result := Labels[Self];
end;

end.
