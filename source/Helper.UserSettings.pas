unit Helper.UserSettings;

interface

{$REGION  'Dev notes : Helper.UserSettings'}

(*
  Unit: Helper.UserSettings

  Purpose:
    Provides centralized helpers and metadata for user settings types and enums
    used throughout the application (such as AI model types, proficiency levels, intensities, summaries, and timeouts).
    This unit encapsulates string conversions, default values, option lists, and utility operations—
    supporting clear, maintainable, and scalable settings logic for both UI and backend.

  Technical details:
    - Defines and extends key enums with helper records for display, parsing, indexing, and defaults (e.g., `TModelTypeHelper`, `TProficiencyLevelHelper`).
    - Aggregates name arrays, default selections, icon representations, and provides methods for retrieving allowed values and string conversions.
    - Includes a dedicated `TModelCosts` class for model token cost calculation and formatted output.
    - Supports settings logic extension uniformly, from adding new options to managing localized labels or costs.

  Usage:
    - Use enum helpers for clean conversion and UI rendering logic (e.g., for ComboBox population, settings serialization, etc.).
    - Query model costs, allowed values, or icons via the provided helper methods.
    - Extend user settings simply by updating these helpers, reducing code duplication across the codebase.

  This unit helps ensure a single source of truth for user settings metadata, decoupling display and logic,
  and fostering extensibility throughout the application.
*)

{$ENDREGION}

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  TModelType = (mtSearch, mtReasoning);

  TModelTypeHelper = record helper for TModelType
  private
    const
      ModelNames: array[TModelType] of TArray<string> = (
        {--- mtSearch }
        ['gpt-4o', 'gpt-4o-mini', 'gpt-4.1', 'gpt-4.1-mini', 'gpt-4.1-nano'],
        {--- mtReasoning }
        ['o1', 'o1-pro', 'o3', 'o3-mini', 'o4-mini']
      );

      DefaultModels: array[TModelType] of string = (
        {--- mtSearch }
        'gpt-4.1-mini',
        {--- mtReasoning }
        'o4-mini'
      );

  public
    function GetModelNames: TArray<string>;
    function GetDefaultModel: string;
    function IndexOfModel(const ModelName: string): Integer;
  end;

  TProficiencyLevel = (plJunior, plIntermediate, plSenior, plLeadDev, plArchitect);

  TProficiencyLevelHelper = record helper for TProficiencyLevel
  private
    const
      Names: array[TProficiencyLevel] of string = (
        'Delphi Dev – Junior',
        'Delphi Dev – Intermediate',
        'Delphi Dev – Senior',
        'Lead Dev Delphi',
        'Delphi Software Architect'
      );

      Icons: array[TProficiencyLevel] of string = (
        '', '', '', '', ''
      );

      DefaultLevel = plIntermediate;
  public
    function ToString: string;
    function ToIcon: string;
    class function FromIndex(Index: Integer): TProficiencyLevel; static;
    class function Default: TProficiencyLevel; static;
    class function Count: Integer; static;
    class function AllIcons: string; static;
  end;

  TModelCosts = class
  private
    FCosts: TDictionary<Integer, TArray<string>>;
    const TOKEN_COST_PATTERN = 'Per 1M tokens Input: %s output: %s';
  public
    constructor Create;
    destructor Destroy; override;
    function GetCost(ModelType: TModelType; Index: Integer): string;
  end;

  TIntensity = (iyLow, iyMedium, iyHigh);

  TIntensityHelper = record Helper for TIntensity
  private
    const
      Intensities : array[TIntensity] of string = (
        'Low', 'Medium', 'High'
      );
     DefaultIntensity = iyMedium;
  public
    function ToString: string;
    class function Default: TIntensity; static;
    class function FromIndex(Index: Integer): TIntensity; static;
    class function Count: Integer; static;
    class function AllIntensities: string; static;
  end;

  TSummary = (syNone, syDetailed);

  TSummaryHelper = record Helper for TSummary
  private
    const
      Summaries : array[TSummary] of string = (
        'None', 'Detailed'
      );
      DefaultSummary = syNone;
  public
    function ToString: string;
    class function Default: TSummary; static;
    class function FromIndex(Index: Integer): TSummary; static;
    class function Count: Integer; static;
    class function AllSummaries: string; static;
  end;

  TTimeOut = (t30s, t60s, t5m, t10m, t20m, t30m, t60m, t5h, t12h, t24h);

  TTimeOutHelper = record Helper for TTimeOut
  private
    const
      TimeOuts : array[TTimeOut] of string = (
        '30 seconds' , '60 seconds' ,
        '5 minutes' , '10 minutes' , '20 minutes' , '30 minutes' , '60 minutes' ,
        '5 hours' , '12 hours' , '24 hours'
      );

      Timeoutms : array[TTimeOut] of Cardinal = (
        30000, 60000,
        300000, 600000, 1200000, 1800000, 3600000,
        18000000, 43200000, 86400000
      );

      DefaultTimeOut = t30s;
  public
    function ToString: string;
    function ToMilliseconds: Cardinal;
    class function Default: TTimeOut; static;
    class function FromIndex(Index: Integer): TTimeOut; static;
    class function TextToCardinal(const Text: string): Cardinal; static;
    class function Count: Integer; static;
    class function AllTimeOuts: string; static;
  end;

implementation

{ TModelTypeHelper }

function TModelTypeHelper.GetDefaultModel: string;
begin
  Result := DefaultModels[Self];
end;

function TModelTypeHelper.GetModelNames: TArray<string>;
begin
  Result := ModelNames[Self];
end;

function TModelTypeHelper.IndexOfModel(const ModelName: string): Integer;
begin
  Result := TArray.IndexOf<string>(ModelNames[Self], ModelName);
end;

{ TProficiencyLevelHelper }

class function TProficiencyLevelHelper.AllIcons: string;
begin
  Result := String.Join(#10, Icons);
end;

class function TProficiencyLevelHelper.Count: Integer;
begin
  Result := Length(Names);
end;

class function TProficiencyLevelHelper.Default: TProficiencyLevel;
begin
  Result := DefaultLevel;
end;

class function TProficiencyLevelHelper.FromIndex(
  Index: Integer): TProficiencyLevel;
begin
  if (Index >= 0) and (Index < Count) then
    Result := TProficiencyLevel(Index)
  else
    Result := Default;
end;

function TProficiencyLevelHelper.ToIcon: string;
begin
  Result := Icons[Self];
end;

function TProficiencyLevelHelper.ToString: string;
begin
  Result := Names[Self];
end;

{ TModelCosts }

constructor TModelCosts.Create;
begin
  FCosts := TDictionary<Integer, TArray<string>>.Create;

  {--- Costs of research models }
  FCosts.Add(Ord(mtSearch) * 1000 + 0, ['$2.50', '$10.00']);
  FCosts.Add(Ord(mtSearch) * 1000 + 1, ['$0.15', '$0.60']);
  FCosts.Add(Ord(mtSearch) * 1000 + 2, ['$2.00', '$8.00']);
  FCosts.Add(Ord(mtSearch) * 1000 + 3, ['$0.40', '$1.60']);
  FCosts.Add(Ord(mtSearch) * 1000 + 4, ['$0.10', '$0.40']);

  {--- Costs of reasoning models }
  FCosts.Add(Ord(mtReasoning) * 1000 + 0, ['$15.00', '$60.00']);
  FCosts.Add(Ord(mtReasoning) * 1000 + 1, ['$150.00', '$600.00']);
  FCosts.Add(Ord(mtReasoning) * 1000 + 2, ['$10.00', '$40.00']);
  FCosts.Add(Ord(mtReasoning) * 1000 + 3, ['$1.10', '$4.40']);
  FCosts.Add(Ord(mtReasoning) * 1000 + 4, ['$1.10', '$4.40']);
end;

destructor TModelCosts.Destroy;
begin
  FCosts.Free;
  inherited;
end;

function TModelCosts.GetCost(ModelType: TModelType; Index: Integer): string;
var
  CostValues: TArray<string>;
begin
  var Key := Ord(ModelType) * 1000 + Index;
  if FCosts.TryGetValue(Key, CostValues) then
    begin
      if Length(CostValues) = 2 then
        Result := Format(TOKEN_COST_PATTERN, [CostValues[0], CostValues[1]])
      else
        Result := 'Invalid Cost Format';
    end
  else
    Result := 'Unknown Cost';
end;

{ TIntensityHelper }

class function TIntensityHelper.AllIntensities: string;
begin
  Result := String.Join(#10, Intensities);
end;

class function TIntensityHelper.Count: Integer;
begin
  Result := Length(Intensities);
end;

class function TIntensityHelper.Default: TIntensity;
begin
  Result := DefaultIntensity;
end;

class function TIntensityHelper.FromIndex(Index: Integer): TIntensity;
begin
  if (Index >= 0) and (Index < Count) then
    Result := TIntensity(Index)
  else
    Result := Default;
end;

function TIntensityHelper.ToString: string;
begin
  Result := Intensities[Self];
end;

{ TSummaryHelper }

class function TSummaryHelper.AllSummaries: string;
begin
  Result := string.Join(#10, Summaries);
end;

class function TSummaryHelper.Count: Integer;
begin
  Result := Length(Summaries);
end;

class function TSummaryHelper.Default: TSummary;
begin
  Result := DefaultSummary;
end;

class function TSummaryHelper.FromIndex(Index: Integer): TSummary;
begin
  if (Index >= 0) and (Index < Count) then
    Result := TSummary(Index)
  else
    Result := Default;
end;

function TSummaryHelper.ToString: string;
begin
  Result := Summaries[Self];
end;

{ TTimeOutHelper }

class function TTimeOutHelper.AllTimeOuts: string;
begin
  Result := string.Join(#10, TimeOuts);
end;

class function TTimeOutHelper.Count: Integer;
begin
  Result := Length(TimeOuts);
end;

class function TTimeOutHelper.Default: TTimeOut;
begin
  Result := DefaultTimeOut;
end;

class function TTimeOutHelper.FromIndex(Index: Integer): TTimeOut;
begin
  if (Index >= 0) and (Index < Count) then
    Result := TTimeOut(Index)
  else
    Result := Default;
end;

class function TTimeOutHelper.TextToCardinal(const Text: string): Cardinal;
begin
  var NormalizedText := Text.Trim.ToLower;
  for var index := ord(Low(TTimeOut)) to Ord(High(TTimeOut)) do
    if TimeOuts[TTimeOut(index)].Trim.ToLower = NormalizedText then
      Exit(TTimeOut(index).ToMilliseconds);
  raise Exception.CreateFmt('"%s" is not a correct timeout format', [Text]);
end;

function TTimeOutHelper.ToMilliseconds: Cardinal;
begin
  Result := Timeoutms[Self];
end;

function TTimeOutHelper.ToString: string;
begin
  Result := TimeOuts[Self];
end;

end.
