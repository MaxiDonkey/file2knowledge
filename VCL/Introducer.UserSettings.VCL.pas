unit Introducer.UserSettings.VCL;

interface

{$REGION  'Dev notes : UI.VectorResourceManager.VCL'}

(*
  Unit: Introducer.UserSettings.VCL

  Purpose:
    Provides a structured and type-safe way to aggregate references to relevant VCL controls
    used in the user settings UI. This unit defines the TSettingsIntroducer record, which acts as a container
    for binding UI elements, making initialization and further management of user settings UI logic
    both clean and extensible.

  Technical details:
    - Centralizes references to all settings-related UI controls (ComboBox, Edit, MaskEdit, Label, etc.).
    - Implements a helper record (TSettingsIntroducerHelper) with fluent-style setters for streamlined
      assignment and chaining during form setup.
    - Facilitates clear separation between UI declaration and business logic/controller code, promoting maintainability and reusability.

  Usage:
    - Create and populate a TSettingsIntroducer with relevant controls from your form.
    - Pass it to logic units (such as TSettingsVCL) to link and synchronize the UI without repetitious assignment code.
    - Extend or refactor UI dialogs by updating this introducer, minimizing code changes elsewhere.

*)

{$ENDREGION}

uses
  System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Mask,
  Vcl.Buttons, Vcl.Forms, Vcl.Dialogs;

type
  TSettingsIntroducer = record
    ScrollBox: TScrollBox;
    Proficiency: TComboBox;
    ProficiencyLabel: TLabel;
    PreferenceName: TMaskEdit;
    APIKey: TMaskEdit;
    SearchModel: TComboBox;
    SearchModelCost: TLabel;
    ReasoningModel: TComboBox;
    ReasoningModelCost: TLabel;
    ReasoningEffort: TComboBox;
    ReasoningSummary: TComboBox;
    WebContextSize: TComboBox;
    TimeOut: TComboBox;
    Country: TMaskEdit;
    City: TMaskEdit;
    Verbosity: TComboBox;
    ClearResponseButton: TSpeedButton;
    DashBoardLabel: TLabel;
    class function Empty: TSettingsIntroducer; static;
  end;

  TSettingsIntroducerHelper = record helper for TSettingsIntroducer
    function SetScrollBox(Value: TScrollBox): TSettingsIntroducer; inline;
    function SetProficiency(Value: TComboBox): TSettingsIntroducer; inline;
    function SetProficiencyLabel(Value: TLabel): TSettingsIntroducer; inline;
    function SetPreferenceName(Value: TMaskEdit): TSettingsIntroducer; inline;
    function SetAPIKey(Value: TMaskEdit): TSettingsIntroducer; inline;
    function SetSearchModel(Value: TComboBox): TSettingsIntroducer; inline;
    function SetSearchModelCost(Value: TLabel): TSettingsIntroducer; inline;
    function SetReasoningModel(Value: TComboBox): TSettingsIntroducer; inline;
    function SetReasoningModelCost(Value: TLabel): TSettingsIntroducer; inline;
    function SetReasoningEffort(Value: TComboBox): TSettingsIntroducer; inline;
    function SetReasoningSummary(Value: TComboBox): TSettingsIntroducer; inline;
    function SetWebContextSize(Value: TComboBox): TSettingsIntroducer; inline;
    function SetTimeOut(Value: TComboBox): TSettingsIntroducer; inline;
    function SetCountry(Value: TMaskEdit): TSettingsIntroducer; inline;
    function SetCity(Value: TMaskEdit): TSettingsIntroducer; inline;
    function SetVerbosity(Value: TComboBox): TSettingsIntroducer; inline;
    function SetClearResponseButton(Value: TSpeedButton): TSettingsIntroducer; inline;
    function SetDashBoardLabel(Value: TLabel): TSettingsIntroducer; inline;
  end;

implementation

{ TSettingsIntroducer }

class function TSettingsIntroducer.Empty: TSettingsIntroducer;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

{ TSettingsIntroducerHelper }

function TSettingsIntroducerHelper.SetAPIKey(
  Value: TMaskEdit): TSettingsIntroducer;
begin
  Self.APIKey := Value;
  Result := Self;
end;

function TSettingsIntroducerHelper.SetCity(
  Value: TMaskEdit): TSettingsIntroducer;
begin
  Self.City := Value;
  Result := Self;
end;

function TSettingsIntroducerHelper.SetClearResponseButton(
  Value: TSpeedButton): TSettingsIntroducer;
begin
  Self.ClearResponseButton := Value;
  Result := Self;
end;

function TSettingsIntroducerHelper.SetCountry(
  Value: TMaskEdit): TSettingsIntroducer;
begin
  Self.Country := Value;
  Result := Self;
end;

function TSettingsIntroducerHelper.SetDashBoardLabel(
  Value: TLabel): TSettingsIntroducer;
begin
  Self.DashBoardLabel := Value;
  Result := Self;
end;

function TSettingsIntroducerHelper.SetPreferenceName(
  Value: TMaskEdit): TSettingsIntroducer;
begin
  Self.PreferenceName := Value;
  Result := Self;
end;

function TSettingsIntroducerHelper.SetProficiency(
  Value: TComboBox): TSettingsIntroducer;
begin
  Self.Proficiency := Value;
  Result := Self;
end;

function TSettingsIntroducerHelper.SetProficiencyLabel(
  Value: TLabel): TSettingsIntroducer;
begin
  Self.ProficiencyLabel := Value;
  Result := Self;
end;

function TSettingsIntroducerHelper.SetReasoningEffort(
  Value: TComboBox): TSettingsIntroducer;
begin
  Self.ReasoningEffort := Value;
  Result := Self;
end;

function TSettingsIntroducerHelper.SetReasoningModel(
  Value: TComboBox): TSettingsIntroducer;
begin
  Self.ReasoningModel := Value;
  Result := Self;
end;

function TSettingsIntroducerHelper.SetReasoningModelCost(
  Value: TLabel): TSettingsIntroducer;
begin
  Self.ReasoningModelCost := Value;
  Result := Self;
end;

function TSettingsIntroducerHelper.SetReasoningSummary(
  Value: TComboBox): TSettingsIntroducer;
begin
  Self.ReasoningSummary := Value;
  Result := Self;
end;

function TSettingsIntroducerHelper.SetScrollBox(
  Value: TScrollBox): TSettingsIntroducer;
begin
  Self.ScrollBox := Value;
  Result := Self;
end;

function TSettingsIntroducerHelper.SetSearchModel(
  Value: TComboBox): TSettingsIntroducer;
begin
  Self.SearchModel := Value;
  Result := Self;
end;

function TSettingsIntroducerHelper.SetSearchModelCost(
  Value: TLabel): TSettingsIntroducer;
begin
  Self.SearchModelCost := Value;
  Result := Self;
end;

function TSettingsIntroducerHelper.SetTimeOut(
  Value: TComboBox): TSettingsIntroducer;
begin
  Self.TimeOut := Value;
  Result := Self;
end;

function TSettingsIntroducerHelper.SetVerbosity(
  Value: TComboBox): TSettingsIntroducer;
begin
  Self.Verbosity := Value;
  Result := Self;
end;

function TSettingsIntroducerHelper.SetWebContextSize(
  Value: TComboBox): TSettingsIntroducer;
begin
  Self.WebContextSize := Value;
  Result := Self;
end;

end.
