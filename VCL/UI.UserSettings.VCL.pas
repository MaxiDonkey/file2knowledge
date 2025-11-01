unit UI.UserSettings.VCL;

interface

{$REGION  'Dev notes : UI.UserSettings.VCL'}

(*
  Unit: UI.UserSettings.VCL

  Purpose:
    Provides advanced user settings interface logic for Delphi VCL applications.
    This unit dynamically binds visual controls (ComboBox, MaskEdit, Label, etc.)
    to configuration data structures and persistence, relying on dedicated helpers and extenders
    for flexible and robust preference management.

  NOTE ON ARCHITECTURE AND DESIGN CHOICES:
    In line with the project’s pragmatic and demonstrative focus, this unit does NOT adhere to a strict MVC, MVP,
    or MVVM separation. The business logic and UI events are kept close together for clarity, rapid prototyping,
    and ease of onboarding for developers of all backgrounds.

  Technical details:
    - Utilizes a settings introducer record (TSettingsIntroducer, see Introducer.UserSettings.VCL) that centralizes references
      to UI components, promoting structured injection, clarity, and testability.
    - Delegates metadata management (names, defaults, conversions, sets) to centralized record helpers (see Helper.UserSettings).
    - Synchronizes state between the view (Delphi controls) and persistent model via binding logic,
      automatically applying control styles and adapters according to project UI standards.
    - Handles user interaction (value changes, validation, focus, etc.) through isolated, consistent event handlers.
    - Supports live updates of model costs, advanced selections, and structured user changes,
      leveraging an architecture focused on extensibility.
    - Facilitates parameter extension (AI models, proficiency levels, intensity, etc.) by simple edits
      to helpers/enums—no major UI code changes required.

  Dependencies:
    - Requires metadata helpers (Helper.UserSettings) and the UI introducer (Introducer.UserSettings.VCL).
    - Uses the persistence layer (UserSettings.Persistence) for centralized save/restore of settings.
    - Applies UI styles via UI.Styles.VCL and standard VCL units for visual binding.
    - Employs interface resolution and event injection (IoC) as needed.

  Quick start for developers:
    - Prepare a `TSettingsIntroducer` record populated with your form’s controls.
    - Instantiate `TSettingsVCL` with this introducer; all synchronization and settings logic are then handled automatically.
    - Customize or extend settings by simply updating the dedicated helpers/enums—no UI glue code required.
    - Persistence, events, and rendering are fully integrated; focus on your business logic, not on tedious UI/data wiring.

  This unit is designed for maximum scalability—cleanly separating UI injection, business logic,
  persistence, and rendering responsibilities, following the latest Delphi VCL best practices.
*)

{$ENDREGION}

uses
  Winapi.Windows, Winapi.Messages, Winapi.CommCtrl,
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Mask,
  Vcl.Buttons, Vcl.Forms, Vcl.Dialogs,
  Manager.Intf, Manager.IoC, JSON.Resource, UserSettings.Persistence, UI.Styles.VCL,
  Helper.ScrollBoxMouseWheel.VCL, Helper.UserSettings, Introducer.UserSettings.VCL,
  ChatSession.Controller, Manager.WebServices;

type
  /// <summary>
  /// Main controller for binding user setting UI controls to persistent user settings in a Delphi VCL application.
  /// </summary>
  /// <para>
  /// TSettingsVCL is responsible for synchronizing UI components—such as ComboBoxes, MaskEdits, and Labels—with the underlying settings model.
  /// It handles loading and saving of persistent settings, applies UI styles, and manages user interactions and validation for all user setting controls.
  /// </para>
  /// <para>
  /// The class delegates metadata lookups and option management to dedicated helpers and uses a structured introducer record to cleanly inject UI controls.
  /// It also manages dynamic updates of dependent UI elements, such as model cost displays, as users modify their preferences.
  /// </para>
  /// <para>
  /// All user settings page logic is centralized in this class to maximize maintainability, robustness, and extensibility.
  /// </para>
  TSettingsVCL = class(TInterfacedObject, ISettings)
  private
    FLock: Boolean;
    FSettings: TSettings;
    FScrollBox: TScrollBox;
    FProficiency: TComboBox;
    FPreferenceName: TMaskEdit;
    FProficiencyLabel: TLabel;
    FAPIKey: TMaskEdit;
    FSearchModel: TComboBox;
    FSearchModelCost: TLabel;
    FReasoningModel: TComboBox;
    FReasoningModelCost: TLabel;
    FModelCosts: TModelCosts;
    FReasoningEffort: TComboBox;
    FReasoningSummary: TComboBox;
    FWebContextSize: TComboBox;
    FTimeOut: TComboBox;
    FCountry: TMaskEdit;
    FCity: TMaskEdit;
    FVerbosity: TComboBox;
    FClearResponseButton: TSpeedButton;
    FDashBoardLabel: TLabel;
    procedure ReloadFromJSONFile;
    procedure SearchModelCostUpdate;
    procedure ReasoningModelCostUpdate;
    procedure SetScrollBox(const Value: TScrollBox);
    procedure SetProficiency(const Value: TComboBox);
    procedure SetPreferenceName(const Value: TMaskEdit);
    procedure SetProficiencyLabel(const Value: TLabel);
    procedure SetAPIKey(const Value: TMaskEdit);
    procedure SetSearchModel(const Value: TComboBox);
    procedure SetSearchModelCost(const Value: TLabel);
    procedure SetReasoningModel(const Value: TComboBox);
    procedure SetReasoningModelCost(const Value: TLabel);
    procedure SetReasoningEffort(const Value: TComboBox);
    procedure SetReasoningSummary(const Value: TComboBox);
    procedure SetWebContextSize(const Value: TComboBox);
    procedure SetTimeOut(const Value: TComboBox);
    procedure SetCountry(const Value: TMaskEdit);
    procedure SetCity(const Value: TMaskEdit);
    procedure SetVerbosity(const Value: TComboBox);
    procedure SetClearResponseButton(const Value: TSpeedButton);
    procedure SetDashBoardLabel(const Value: TLabel);

    procedure InitializeComponent(Component: TControl; ChangeHandler: TNotifyEvent = nil);
  protected
    procedure HandleLeaveForLabels;
    procedure HandleLeave(Sender: TObject);
    procedure HandleMaskEditKeyPress(Sender: TObject; var Key: Char);
    procedure HandleProficiencyChange(Sender: TObject);
    procedure HandlePreferenceNameChange(Sender: TObject);
    procedure HandleAPIKeyChange(Sender: TObject);
    procedure HandleSearchModelChange(Sender: TObject);
    procedure HandleReasoningModelChange(Sender: TObject);
    procedure HandleReasoningEffortChange(Sender: TObject);
    procedure HandleReasoningSummaryChange(Sender: TObject);
    procedure HandleWebContextSizeChange(Sender: TObject);
    procedure HandleTimeOutChange(Sender: TObject);
    procedure HandleCountryChange(Sender: TObject);
    procedure HandleCityChange(Sender: TObject);
    procedure HandleVerbosityChange(Sender: TObject);
    procedure HandleMaskEditKeyPressed(Sender: TObject; var Key: Char);
    procedure HandleMaskEditExit(Sender: TObject);
    procedure HandleClearResponseIds(Sender: TObject);
    procedure HandleDashboard(Sender: TObject);
  public
    /// <summary>
    /// Prompts the user to enter their OpenAI API key if it is not already set.
    /// <para>
    /// If no API key is present, displays a dialog for user input,
    /// saves the entered key to persistent settings, and updates the application state accordingly.
    /// </para>
    /// </summary>
    procedure InputAPIKey;

    /// <summary>
    /// Synchronizes the UI controls with the current persistent user settings.
    /// <para>
    /// Updates all UI elements to reflect values from the persistent settings model,
    /// applies display updates (such as model costs), and ensures all modifications are saved.
    /// </para>
    /// </summary>
    procedure Update;

    /// <summary>
    /// Returns the textual representation of the currently selected user proficiency level.
    /// <para>
    /// Retrieves the current selection from the proficiency ComboBox and
    /// converts it to its display string using the helper for proficiency levels.
    /// </para>
    /// </summary>
    function ProficiencyToString: string;

    /// <summary>
    /// Gets the user's screen name as displayed in the application's UI.
    /// <para>
    /// Returns the value of the preference name loaded from the settings model.
    /// </para>
    /// </summary>
    function UserScreenName: string;

    /// <summary>
    /// Returns the identifier of the currently selected search model.
    /// <para>
    /// Gets the search model chosen in the UI or persisted in the user settings.
    /// </para>
    /// </summary>
    function SearchModel: string;

    /// <summary>
    /// Returns the identifier of the currently selected reasoning model.
    /// <para>
    /// Gets the reasoning model chosen in the UI or persisted in the user settings.
    /// </para>
    /// </summary>
    function ReasoningModel: string;

    /// <summary>
    /// Returns the currently stored OpenAI API key.
    /// <para>
    /// Provides access to the API key stored in the settings, without prompting the user.
    /// </para>
    /// </summary>
    function APIKey: string;

    /// <summary>
    /// Gets the selected value for reasoning effort.
    /// </summary>
    /// <returns>
    /// The current reasoning effort value from settings.
    /// </returns>
    function ReasoningEffort: string;

    /// <summary>
    /// Gets the selected value for reasoning summary.
    /// </summary>
    /// <returns>
    /// The current reasoning summary value from settings.
    /// </returns>
    function ReasoningSummary: string;

    /// <summary>
    /// Gets the configured web search context size.
    /// </summary>
    /// <returns>
    /// The current web context size from settings.
    /// </returns>
    function WebContextSize: string;

    /// <summary>
    /// Gets the timeout configuration for user operations.
    /// </summary>
    /// <returns>
    /// The current timeout value from settings.
    /// </returns>
    function TimeOut: string;

    /// <summary>
    /// Gets the configured country string.
    /// </summary>
    /// <returns>
    /// The country value from user settings.
    /// </returns>
    function Country: string;

    /// <summary>
    /// Gets the configured city string.
    /// </summary>
    /// <returns>
    /// The city value from user settings.
    /// </returns>
    function City: string;

    /// <summary>
    /// Constrains the verbosity of the model's response. Lower values will result in more concise
    /// responses, while higher values will result in more verbose responses. Currently supported
    /// values are low, medium, and high.
    /// </summary>
    function Verbosity: string;

    /// <summary>
    /// Indicates if a summary is to be used for the current user configuration.
    /// </summary>
    /// <returns>
    /// True if the summary is enabled; otherwise, False.
    /// </returns>
    function UseSummary: Boolean;

    constructor Create(const Introducer: TSettingsIntroducer);
    destructor Destroy; override;
  end;

implementation

{ TSettingsVCL }

function TSettingsVCL.APIKey: string;
begin
  Result := FSettings.APIKey;
end;

function TSettingsVCL.City: string;
begin
  Result := FSettings.City;
end;

function TSettingsVCL.Country: string;
begin
  Result := FSettings.Country;
end;

constructor TSettingsVCL.Create(const Introducer: TSettingsIntroducer);
begin
  inherited Create;
  FModelCosts := TModelCosts.Create;
  FLock := True;
  try
    SetScrollBox(Introducer.ScrollBox);
    SetProficiency(Introducer.Proficiency);
    SetProficiencyLabel(Introducer.ProficiencyLabel);
    SetPreferenceName(Introducer.PreferenceName);
    SetAPIKey(Introducer.APIKey);
    SetSearchModel(Introducer.SearchModel);
    SetSearchModelCost(Introducer.SearchModelCost);
    SetReasoningModel(Introducer.ReasoningModel);
    SetReasoningModelCost(Introducer.ReasoningModelCost);
    SetReasoningEffort(Introducer.ReasoningEffort);
    SetReasoningSummary(Introducer.ReasoningSummary);
    SetWebContextSize(Introducer.WebContextSize);
    SetTimeOut(Introducer.TimeOut);
    SetCountry(Introducer.Country);
    SetCity(Introducer.City);
    SetVerbosity(Introducer.Verbosity);
    SetClearResponseButton(Introducer.ClearResponseButton);
    SetDashBoardLabel(Introducer.DashBoardLabel);
  finally
    FLock := False;
  end;
  Update;
end;

destructor TSettingsVCL.Destroy;
begin
  FModelCosts.Free;
  inherited;
end;

function TSettingsVCL.ReasoningSummary: string;
begin
  Result := FSettings.ReasoningSummary;
end;

procedure TSettingsVCL.HandleAPIKeyChange(Sender: TObject);
begin
  if not FLock then
    begin
      FSettings.Chain.Apply(TSettingsProp.APIKey, FAPIKey.Text).Save;
      OpenAI := IoC.Resolve<IAIInteractionManager>('openAI');
      LeftPanelControl.Refresh;
    end;
end;

procedure TSettingsVCL.HandleCityChange(Sender: TObject);
begin
  if not FLock then
    FSettings.Chain
      .Apply(TSettingsProp.City, FCity.Text).Save;
end;

procedure TSettingsVCL.HandleClearResponseIds(Sender: TObject);
begin
  var Message :=
    'Please note that this operation will delete orphaned responses and clean up your OpenAI dashboard.' + sLineBreak +
    'Do you confirm this action?';
  if AlertService.ShowConfirmation(Message) = mrYes then
    begin
      for var id in ResponseTracking.GetOrphans(PersistentChat.GetResponseIds) do
        OpenAI.DeleteResponse(id);
    end;
end;

procedure TSettingsVCL.HandleCountryChange(Sender: TObject);
begin
  if not FLock then
    FSettings.Chain
      .Apply(TSettingsProp.Country, FCountry.Text).Save;
end;

procedure TSettingsVCL.HandleDashboard(Sender: TObject);
begin
  TWebUrlManager.Open('https://platform.openai.com/logs');
end;

procedure TSettingsVCL.HandleLeave(Sender: TObject);
begin
  ServicePrompt.SetFocus;
end;

procedure TSettingsVCL.HandleLeaveForLabels;
begin
  for var i := 0 to FScrollBox.ControlCount - 1 do
    if FScrollBox.Controls[i] is TLabel then
      (FScrollBox.Controls[i] as TLabel).OnClick := HandleLeave;
end;

procedure TSettingsVCL.HandleMaskEditExit(Sender: TObject);
begin
  ServicePrompt.SetFocus;
end;

procedure TSettingsVCL.HandleMaskEditKeyPress(Sender: TObject; var Key: Char);
begin
  case Ord(Key) of
    VK_RETURN:
      begin
        ServicePrompt.SetFocus;
        Key := #0;
      end;
  end;
end;

procedure TSettingsVCL.HandleMaskEditKeyPressed(Sender: TObject; var Key: Char);
begin
  if Ord(Key) = VK_RETURN then
    begin
      ServicePrompt.SetFocus;
      Key := #0;
    end;
end;

procedure TSettingsVCL.HandlePreferenceNameChange(Sender: TObject);
begin
  if not FLock then
    FSettings.Chain
      .Apply(TSettingsProp.PreferenceName, FPreferenceName.Text).Save;
end;

procedure TSettingsVCL.HandleProficiencyChange(Sender: TObject);
begin
  if not FLock then
    begin
      FSettings.Chain
        .Apply(TSettingsProp.Proficiency, FProficiency.Text)
        .Save;
      FProficiencyLabel.Caption := ProficiencyToString;
    end;
end;

procedure TSettingsVCL.HandleReasoningEffortChange(Sender: TObject);
begin
  if not FLock then
    begin
      FSettings.Chain
        .Apply(TSettingsProp.ReasoningEffort, FReasoningEffort.Text)
        .Save;
    end;
end;

procedure TSettingsVCL.HandleReasoningModelChange(Sender: TObject);
begin
  if not FLock then
    begin
      FSettings.Chain
        .Apply(TSettingsProp.ReasoningModel, FReasoningModel.Text)
        .Save;
      ReasoningModelCostUpdate;
    end;
end;

procedure TSettingsVCL.HandleReasoningSummaryChange(Sender: TObject);
begin
  if not FLock then
    begin
      FSettings.Chain
        .Apply(TSettingsProp.ReasoningSummary, FReasoningSummary.Text)
        .Save;
    end;
end;

procedure TSettingsVCL.HandleSearchModelChange(Sender: TObject);
begin
  if not FLock then
    begin
      FSettings.Chain
        .Apply(TSettingsProp.SearchModel, FSearchModel.Text)
        .Save;
      SearchModelCostUpdate;
    end;
end;

procedure TSettingsVCL.HandleTimeOutChange(Sender: TObject);
begin
  if not FLock then
    begin
      FSettings.Chain
        .Apply(TSettingsProp.TimeOut, FTimeOut.Text)
        .Save;
    end;
end;

procedure TSettingsVCL.HandleVerbosityChange(Sender: TObject);
begin
  if not FLock then
    FSettings.Chain
      .Apply(TSettingsProp.Verbosity, FVerbosity.Text).Save;
end;

procedure TSettingsVCL.HandleWebContextSizeChange(Sender: TObject);
begin
  if not FLock then
    begin
      FSettings.Chain
        .Apply(TSettingsProp.WebContextSize, FWebContextSize.Text)
        .Save;
    end;
end;

procedure TSettingsVCL.InitializeComponent(Component: TControl;
  ChangeHandler: TNotifyEvent);
begin
  if Component is TComboBox then
  begin
    TComboBox(Component).OnChange := ChangeHandler;
    TComboBox(Component).OnCloseUp := HandleLeave;
    TComboBox(Component).OnExit := HandleMaskEditExit;
  end
  else if Component is TMaskEdit then
  begin
    TMaskEdit(Component).OnKeyPress := HandleMaskEditKeyPress;
    TMaskEdit(Component).OnChange := ChangeHandler;
    TMaskEdit(Component).OnKeyPress := HandleMaskEditKeyPressed;
    TMaskEdit(Component).OnExit := HandleMaskEditExit;
  end
  else if Component is TLabel then
  begin
    TAppStyle.ApplyUserSettingsLabelStyle(FProficiencyLabel);
  end;
end;

procedure TSettingsVCL.InputAPIKey;
var
  APIKey: string;
begin
  if FSettings.APIKey.Trim.IsEmpty then
    begin
      if InputQuery('OpenAI bearer', 'Please enter your API key', APIKey) then
        begin
          FSettings.Chain.Apply(TSettingsProp.APIKey, APIKey).Save;
          Settings.Update;
        end;
    end;
end;

function TSettingsVCL.ProficiencyToString: string;
begin
  Result := TProficiencyLevel.FromIndex(FProficiency.ItemIndex).ToString;
end;

function TSettingsVCL.ReasoningEffort: string;
begin
  Result := FSettings.ReasoningEffort;
end;

function TSettingsVCL.ReasoningModel: string;
begin
  Result := FSettings.ReasoningModel;
end;

procedure TSettingsVCL.ReasoningModelCostUpdate;
begin
  FReasoningModelCost.Caption := FModelCosts.GetCost(mtReasoning, FReasoningModel.ItemIndex);
end;

procedure TSettingsVCL.ReloadFromJSONFile;
begin
  IniSettings.LoadFromFile;
  FSettings := TSettings(IniSettings.Settings);
  if FSettings.Proficiency.IsEmpty then
    FSettings.Chain.Apply(TSettingsProp.Proficiency, TProficiencyLevel.Default.ToIcon);
  if FSettings.SearchModel.IsEmpty then
    FSettings.Chain.Apply(TSettingsProp.SearchModel, mtSearch.GetDefaultModel);
  if FSettings.ReasoningModel.IsEmpty then
    FSettings.Chain.Apply(TSettingsProp.ReasoningModel, mtReasoning.GetDefaultModel);
  if FSettings.ReasoningEffort.IsEmpty then
    FSettings.Chain.Apply(TSettingsProp.ReasoningEffort, TIntensity.Default.ToString);
  if FSettings.ReasoningSummary.IsEmpty then
    FSettings.Chain.Apply(TSettingsProp.ReasoningSummary, TSummary.Default.ToString);
  if FSettings.WebContextSize.IsEmpty then
    FSettings.Chain.Apply(TSettingsProp.WebContextSize, TIntensity.Default.ToString);
  if FSettings.TimeOut.IsEmpty then
    FSettings.Chain.Apply(TSettingsProp.TimeOut, TTimeOut.Default.ToString);
end;

function TSettingsVCL.SearchModel: string;
begin
  Result := FSettings.SearchModel;
end;

procedure TSettingsVCL.SearchModelCostUpdate;
begin
  FSearchModelCost.Caption := FModelCosts.GetCost(mtSearch, FSearchModel.ItemIndex);
end;

procedure TSettingsVCL.SetAPIKey(const Value: TMaskEdit);
begin
  FAPIKey := Value;
  TAppStyle.ApplyUserSettingsMaskEditStyle(Value,
    procedure
    begin
      InitializeComponent(Value, HandleAPIKeyChange);
    end,
    True);
end;

procedure TSettingsVCL.SetCity(const Value: TMaskEdit);
begin
  FCity := Value;
  TAppStyle.ApplyUserSettingsMaskEditStyle(Value,
    procedure
    begin
      InitializeComponent(Value, HandleCityChange);
    end);
end;

procedure TSettingsVCL.SetClearResponseButton(const Value: TSpeedButton);
begin
  FClearResponseButton := Value;
  if Assigned(Value) then
    Value.OnClick := HandleClearResponseIds;
end;

procedure TSettingsVCL.SetCountry(const Value: TMaskEdit);
begin
  FCountry := Value;
  TAppStyle.ApplyUserSettingsMaskEditStyle(Value,
    procedure
    begin
      InitializeComponent(Value, HandleCountryChange);
    end);
end;

procedure TSettingsVCL.SetDashBoardLabel(const Value: TLabel);
begin
  FDashBoardLabel := Value;
  TAppStyle.ApplyUserSettingsDashboardLabel(Value,
    procedure
    begin
      FDashBoardLabel.Caption := 'Dashboard OpenAI';
      FDashBoardLabel.OnClick := HandleDashboard;
    end);
end;

procedure TSettingsVCL.SetPreferenceName(const Value: TMaskEdit);
begin
  FPreferenceName := Value;
  TAppStyle.ApplyUserSettingsMaskEditStyle(Value,
    procedure
    begin
      InitializeComponent(Value, HandlePreferenceNameChange);
    end);
end;

procedure TSettingsVCL.SetProficiency(const Value: TComboBox);
begin
  FProficiency := Value;
  TAppStyle.ApplyUserSettingsComboBoxStyleStar(Value,
    procedure
    begin
      InitializeComponent(Value, HandleProficiencyChange);
      FProficiency.Items.Text := TProficiencyLevel.AllIcons;
      FProficiency.ItemIndex := Ord(TProficiencyLevel.Default);
      FProficiency.DropDownCount := TProficiencyLevel.Count;
    end);
end;

procedure TSettingsVCL.SetProficiencyLabel(const Value: TLabel);
begin
  FProficiencyLabel := Value;
  TAppStyle.ApplyUserSettingsLabelStyle(Value,
    procedure
    begin
      FProficiencyLabel.Alignment := taRightJustify;

      InitializeComponent(Value, nil);
    end);
end;

procedure TSettingsVCL.SetReasoningEffort(const Value: TComboBox);
begin
  FReasoningEffort := Value;
  TAppStyle.ApplyUserSettingsComboBoxStyle(Value,
    procedure
    begin
      InitializeComponent(Value, HandleReasoningEffortChange);

      FReasoningEffort.Items.Text := TIntensity.AllIntensities;
      FReasoningEffort.ItemIndex := Ord(TIntensity.Default);
      FReasoningEffort.DropDownCount := TIntensity.Count;
    end);
end;

procedure TSettingsVCL.SetReasoningModel(const Value: TComboBox);
begin
  FReasoningModel := Value;
  TAppStyle.ApplyUserSettingsComboBoxStyle(Value,
    procedure
    begin
      InitializeComponent(Value, HandleReasoningModelChange);

      FReasoningModel.Items.AddStrings(mtReasoning.GetModelNames);
      FReasoningModel.ItemIndex := mtReasoning.IndexOfModel(mtReasoning.GetDefaultModel);
      FReasoningModel.DropDownCount := Length(mtReasoning.GetModelNames);
    end);
end;

procedure TSettingsVCL.SetReasoningModelCost(const Value: TLabel);
begin
  FReasoningModelCost := Value;
  TAppStyle.ApplyUserSettingsLabelStyle(Value,
    procedure
    begin
      InitializeComponent(Value, nil);
    end);
end;

procedure TSettingsVCL.SetReasoningSummary(const Value: TComboBox);
begin
  FReasoningSummary := Value;
  TAppStyle.ApplyUserSettingsComboBoxStyle(Value,
    procedure
    begin
      InitializeComponent(Value, HandleReasoningSummaryChange);

      FReasoningSummary.Items.Text := TSummary.AllSummaries;
      FReasoningSummary.ItemIndex := Ord(TSummary.Default);
      FReasoningSummary.DropDownCount := TSummary.Count;
    end);
end;

procedure TSettingsVCL.SetScrollBox(const Value: TScrollBox);
begin
  FScrollBox := Value;
  if not Assigned(Value) then
    Exit;

  FScrollBox.OnClick := HandleLeave;
  FScrollBox.EnableMouseWheelScroll;
  HandleLeaveForLabels;
end;

procedure TSettingsVCL.SetSearchModel(const Value: TComboBox);
begin
  FSearchModel := Value;
  TAppStyle.ApplyUserSettingsComboBoxStyle(Value,
    procedure
    begin
      InitializeComponent(Value, HandleSearchModelChange);
      FSearchModel.Items.AddStrings(mtSearch.GetModelNames);
      FSearchModel.ItemIndex := mtSearch.IndexOfModel(mtSearch.GetDefaultModel);
      FSearchModel.DropDownCount := Length(mtSearch.GetModelNames);
    end);
end;

procedure TSettingsVCL.SetSearchModelCost(const Value: TLabel);
begin
  FSearchModelCost := Value;
  TAppStyle.ApplyUserSettingsLabelStyle(Value,
    procedure
    begin
      InitializeComponent(Value, nil);
    end);
end;

procedure TSettingsVCL.SetTimeOut(const Value: TComboBox);
begin
  FTimeOut := Value;
  TAppStyle.ApplyUserSettingsComboBoxStyle(Value,
    procedure
    begin
      InitializeComponent(Value, HandleTimeOutChange);

      FTimeOut.Items.Text := TTimeOut.AllTimeOuts;
      FTimeOut.ItemIndex := Ord(TTimeOut.Default);
      FTimeOut.DropDownCount := TTimeOut.Count;
    end);
end;

procedure TSettingsVCL.SetVerbosity(const Value: TComboBox);
begin
  FVerbosity := Value;
  TAppStyle.ApplyUserSettingsComboBoxStyle(Value,
    procedure
    begin
      InitializeComponent(Value, HandleVerbosityChange);

      FVerbosity.Items.Text := TVerbosity.AllVerbosities;
      FVerbosity.ItemIndex := Ord(TVerbosity.Default);
      FVerbosity.DropDownCount := TVerbosity.Count;
    end);
end;

procedure TSettingsVCL.SetWebContextSize(const Value: TComboBox);
begin
  FWebContextSize := Value;
  TAppStyle.ApplyUserSettingsComboBoxStyle(Value,
    procedure
    begin
      InitializeComponent(Value, HandleWebContextSizeChange);

      FWebContextSize.Items.Text := TIntensity.AllIntensities;
      FWebContextSize.ItemIndex := Ord(TIntensity.Default);
      FWebContextSize.DropDownCount := TIntensity.Count;
    end);
end;

function TSettingsVCL.TimeOut: string;
begin
  Result := FSettings.TimeOut;
end;

procedure TSettingsVCL.Update;
begin
  if FLock then Exit;
  
  FLock := True;
  try
    ReloadFromJSONFile;
    FProficiency.ItemIndex := FProficiency.Items.IndexOf(FSettings.Proficiency);
    FPreferenceName.Text := FSettings.PreferenceName;
    FProficiencyLabel.Caption := ProficiencyToString;
    FAPIKey.Text := FSettings.APIKey;
    FSearchModel.ItemIndex := FSearchModel.Items.IndexOf(FSettings.SearchModel);
    SearchModelCostUpdate;
    FReasoningModel.ItemIndex := FReasoningModel.Items.IndexOf(FSettings.ReasoningModel);
    ReasoningModelCostUpdate;
    FReasoningEffort.ItemIndex := FReasoningEffort.Items.IndexOf(FSettings.ReasoningEffort);
    FReasoningSummary.ItemIndex := FReasoningSummary.Items.IndexOf(FSettings.ReasoningSummary);
    FWebContextSize.ItemIndex := FWebContextSize.Items.IndexOf(FSettings.WebContextSize);
    FTimeOut.ItemIndex := FTimeOut.Items.IndexOf(FSettings.TimeOut);
    FCountry.Text := FSettings.Country;
    FCity.Text := FSettings.City;
    FVerbosity.ItemIndex := FVerbosity.Items.IndexOf(FSettings.Verbosity);
    FSettings.Save;
  finally
    FLock := False;
  end;
end;

function TSettingsVCL.UserScreenName: string;
begin
  Result := FSettings.PreferenceName;
end;

function TSettingsVCL.UseSummary: Boolean;
begin
  Result := not FSettings.ReasoningSummary.Trim.ToLower.Contains('none');
end;

function TSettingsVCL.Verbosity: string;
begin
  Result := FSettings.Verbosity;
end;

function TSettingsVCL.WebContextSize: string;
begin
  Result := FSettings.WebContextSize;
end;

end.
