unit UserSettings.Persistence;

interface

{$REGION  'Dev notes : UserSettings.Persistence'}

(*
  Unit: UserSettings.Persistence

  Purpose:
    Implements persistent storage, loading, and management of user-specific application settings.
    This unit encapsulates all logic for serializing, deserializing, and versioning user preferences,
    supporting robust profile management, profile switching, and reliable round-tripping to JSON-based storage.

  Description:
    - Defines the <c>TSettings</c> class for structured user configuration with complete property mapping.
    - Supplies <c>TSettingsProp</c>, centralizing property name access for all user settings fields.
    - Provides the <c>TIniSettings</c> class and <c>IIniSettings</c> interface to unify loading, saving, and file management.
    - Leverages JSON serialization for portability, human-readability, and backward compatibility.
    - Supports fluent-style manipulation and chained updates to settings, promoting concise and expressive persistence operations.

  Design Notes:
    - Follows the single-responsibility principle with a clear focus on configuration persistence.
    - Separates storage logic from UI binding and business rules for maintainability.
    - Easily extendable for new configuration needs and model evolution.

  Dependencies:
    - Relies on System.JSON and REST.Json for data conversion.
    - Intended to be used by higher-level modules that orchestrate user experience and interface logic.

  Usage:
    Instantiate or resolve an <c>IIniSettings</c> implementation for your persistence needs,
    and interact fluently with the <c>TSettings</c> object to load, query, modify, or save user configuration.
*)

{$ENDREGION}

uses
  System.SysUtils, System.Classes, System.JSON, REST.Json.Types, REST.Json,
  Manager.Intf, JSON.Resource;

type
  /// <summary>
  /// Encapsulates all persistent application user settings and provides JSON serialization functionality.
  /// </summary>
  /// <remarks>
  /// <c>TSettings</c> contains all configurable end-user properties such as proficiency, model selection,
  /// API key, identity, and localization details.
  /// The class leverages its <c>TJSONResource</c> ancestor to support serialization and deserialization
  /// from JSON, enabling persistent storage and retrieval of user settings.
  /// <para>
  /// Designed as a singleton, this class ensures a single, consistent settings instance is used
  /// throughout the application. It also provides static class methods for loading and reloading
  /// settings data from files.
  /// </para>
  /// </remarks>
  TSettings = class(TJSONResource)
  strict private
    FProficiency: string;
    FPreferenceName: string;
    FApiKey: string;
    FSearchModel: string;
    FReasoningModel: string;
    FReasoningEffort: string;
    FReasoningSummary: string;
    FWebContextSize: string;
    FTimeOut: string;
    FCountry: string;
    FCity: string;
    FVerbosity: string;
    class var FInstance: TSettings;
  public
    property Proficiency: string read FProficiency write FProficiency;
    property PreferenceName: string read FPreferenceName write FPreferenceName;
    property ApiKey: string read FApiKey write FApiKey;
    property SearchModel: string read FSearchModel write FSearchModel;
    property ReasoningModel: string read FReasoningModel write FReasoningModel;
    property ReasoningEffort: string read FReasoningEffort write FReasoningEffort;
    property ReasoningSummary: string read FReasoningSummary write FReasoningSummary;
    property WebContextSize: string read FWebContextSize write FWebContextSize;
    property TimeOut: string read FTimeOut write FTimeOut;
    property Country: string read FCountry write FCountry;
    property City: string read FCity write FCity;
    property Verbosity: string read FVerbosity write FVerbosity;
    class function Instance: TSettings; static;
    class function Reload(const FileName: string = ''): TSettings; static;
    class destructor Destroy;
  end;

  /// <summary>
  /// Centralizes property name constants for all user settings fields.
  /// </summary>
  /// <remarks>
  /// <c>TSettingsProp</c> provides a set of static functions that return string keys corresponding
  /// to each configurable user setting (such as proficiency, API key, model selection, etc.).
  /// Using these constants ensures consistent property access across the application,
  /// supports dynamic binding and persistence layers, and reduces the risk of errors due to typos.
  /// <para>
  /// This record is specifically designed to enable fluent data handling by supporting
  /// chained method calls when applying or manipulating settings properties.
  /// </para>
  /// </remarks>
  TSettingsProp = record
    class function Proficiency: string; static; inline;
    class function PreferenceName: string; static; inline;
    class function APIKey: string; static; inline;
    class function SearchModel: string; static; inline;
    class function ReasoningModel: string; static; inline;
    class function ReasoningEffort: string; static; inline;
    class function ReasoningSummary: string; static; inline;
    class function WebContextSize: string; static; inline;
    class function TimeOut: string; static; inline;
    class function Country: string; static; inline;
    class function City: string; static; inline;
    class function Verbosity: string; static; inline;
  end;

  /// <summary>
  /// Handles the loading, saving, and reloading of user settings from persistent storage.
  /// </summary>
  /// <remarks>
  /// TIniSettings provides a simple interface for reading from and writing to user settings files,
  /// encapsulating the persistent instance of <c>TSettings</c> and supporting serialization to and from files.
  /// </remarks>
  TIniSettings = class(TInterfacedObject, IIniSettings)
  private
    FSettings: TSettings;
    function GetSettings: TObject;
  public
    constructor Create;

    /// <summary>
    /// Reloads the user settings from persistent storage.
    /// </summary>
    /// <remarks>
    /// This method replaces the current settings with those loaded from disk.
    /// Typically used to re-synchronize in-memory settings with external changes.
    /// </remarks>
    procedure Reload;

    /// <summary>
    /// Loads settings from the specified file.
    /// </summary>
    /// <param name="FileName">
    /// The file path of the configuration file to load. If empty, the default settings file is used.
    /// </param>
    /// <returns>
    /// Returns the file path used for loading, or an empty string if the operation fails.
    /// </returns>
    function LoadFromFile(FileName: string = ''): string;

    /// <summary>
    /// Saves the current settings to the specified file.
    /// </summary>
    /// <param name="FileName">
    /// The file path where the configuration should be saved. If empty, the default file is used.
    /// </param>
    procedure SaveToFile(FileName: string = '');

    /// <summary>
    /// Gets the settings object being managed.
    /// </summary>
    /// <returns>
    /// Returns the current settings instance as a <c>TObject</c>.
    /// </returns>
    property Settings: TObject read GetSettings;
  end;

implementation

{ TIniSettings }

constructor TIniSettings.Create;
begin
  inherited Create;
  Reload;
end;

function TIniSettings.GetSettings: TObject;
begin
  Result := FSettings;
end;

function TIniSettings.LoadFromFile(FileName: string): string;
begin
  FSettings := TSettings.Reload;
end;

procedure TIniSettings.Reload;
begin
  FSettings := TSettings.Reload;
end;

procedure TIniSettings.SaveToFile(FileName: string);
begin
  FSettings.Save(FileName);
end;

{ TSettings }

class destructor TSettings.Destroy;
begin
  FInstance.Free;
end;

class function TSettings.Instance: TSettings;
begin
  if not Assigned(FInstance) then
    FInstance := TSettings.Load as TSettings;
  Result := FInstance;
end;

class function TSettings.Reload(const FileName: string): TSettings;
begin
  FInstance.Free;
  FInstance := TSettings.Load(FileName) as TSettings;
  Result := FInstance;
end;

{ TSettingsProp }

class function TSettingsProp.APIKey: string;
begin
  Result := 'apiKey';
end;

class function TSettingsProp.City: string;
begin
  Result := 'city';
end;

class function TSettingsProp.Country: string;
begin
  Result := 'country';
end;

class function TSettingsProp.PreferenceName: string;
begin
  Result := 'preferenceName';
end;

class function TSettingsProp.Proficiency: string;
begin
  Result := 'proficiency';
end;

class function TSettingsProp.ReasoningEffort: string;
begin
  Result := 'reasoningEffort';
end;

class function TSettingsProp.ReasoningModel: string;
begin
  Result := 'reasoningModel';
end;

class function TSettingsProp.ReasoningSummary: string;
begin
  Result := 'reasoningSummary';
end;

class function TSettingsProp.SearchModel: string;
begin
  Result := 'searchModel';
end;

class function TSettingsProp.TimeOut: string;
begin
  Result := 'timeOut';
end;

class function TSettingsProp.Verbosity: string;
begin
  Result := 'verbosity';
end;

class function TSettingsProp.WebContextSize: string;
begin
  Result := 'webContextSize';
end;

end.
