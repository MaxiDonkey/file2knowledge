unit ChatSession.Controller;

interface

{$REGION  'Dev notes : ChatSession.Controller'}

(*
  Unit: ChatSession.Controller

  Purpose:
    This unit provides the infrastructure for managing chat sessions, including persistence and
    chaining of exchanges (prompts/responses) with direct support for JSON formatting.
    It centralizes the creation, modification, and saving of chat sessions, allowing an artificial
    intelligence application or a user assistant to keep conversation history in a structured form.

  Technical details:
    - Based on TJSONResource inheritance, it benefits from automated JSON serialization/deserialization via RTTI.
    - Uses a "chainable" pattern (TJSONChain) to dynamically apply modifications to session or chat turn
      properties (prompt/response).
    - Offers clear structures for a session (TChatSession), a turn (TChatTurn), a list of sessions
      (TChatSessionList), as well as centralized access through the IPersistentChat interface.
    - Supports editing metadata (title, timestamps) and provides helpers for renaming, deleting, or saving sessions.
    - Easily extendable by adding properties, which can be managed through RTTI manipulation
      (no need to write new setters for each field).

  Dependencies:
    - Unit JSON.Resource: provides the base (TJSONResource), JSON file handling, and RTTI chaining (TJSONChain).
    - REST.Json, REST.Json.Types, REST.JsonReflect: used for object<->JSON conversion.
    - System.Generics.Collections: for typed lists.
    - System.IOUtils: for physical JSON file management.
    - GenAI, GenAI.Types: for possible integration with AI modules or generation models (project-specific).
    - JSON.Resource.Lists: for advanced support of serializable collections.

  Getting started:
    - Instantiate or use TPersistentChat (or the IPersistentChat interface) to manage sessions and turns.
    - All data access and modifications can be performed through the chain (.Chain.Apply(...)), or directly
      via public properties for simple access.
    - Save and load using SaveToFile/LoadFromFile methods, or transparently via the TJSONResource structure.

  This unit is designed to let any developer persist and manipulate chat histories easily,
  regardless of the target business layer (bot, assistant, support, etc.).
*)

{$ENDREGION}

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.IOUtils,
  REST.Json, REST.Json.Types, System.JSON, REST.JsonReflect,
  GenAI, GenAI.Types, JSON.Resource, JSON.Resource.Lists;

type
  /// <summary>
  /// A record providing static property name constants used for JSON serialization keys
  /// and chained RTTI property access within chat session and turn objects.
  /// </summary>
  /// <remarks>
  /// <para>
  /// - These string constants correspond to the property names of chat session and turn data
  /// such as Id, Title, CreatedAt, ModifiedAt, Prompt, Response, Storage flags, and various
  /// JSON encoded fields (JsonPrompt, JsonResponse, JsonFileSearch, JsonWebSearch, JsonFunctionCall).
  /// </para>
  /// <para>
  /// - This record facilitates consistent use of property names across the application, avoiding
  /// hardcoded literals and enabling fluent "chain" property mutation via RTTI.
  /// </para>
  /// </remarks>
  TChatSessionProp = record
    class function Data: string; static; inline;
    class function CreatedAt: string; static; inline;
    class function ModifiedAt: string; static; inline;
    class function Title: string; static; inline;
    class function Id: string; static; inline;
    class function Storage: string; static; inline;
    class function Prompt: string; static; inline;
    class function Response: string; static; inline;
    class function FileSearch: string; static; inline;
    class function WebSearch: string; static; inline;
    class function Reasoning: string; static; inline;
    class function JsonPrompt: string; static; inline;
    class function JsonResponse: string; static; inline;
    class function JsonFileSearch: string; static; inline;
    class function JsonWebSearch: string; static; inline;
    class function JsonFunctionCall: string; static; inline;
  end;

  /// <summary>
  /// Represents a single turn or exchange in a chat session, containing
  /// the prompt (user input), response (AI output), and related metadata.
  /// </summary>
  /// <remarks>
  /// Inherits from TJSONResource to support automatic JSON serialization and deserialization.
  /// Stores unique identifier, flags for persistence, raw and JSON-encoded prompt and response,
  /// as well as JSON search results and function call data associated with the turn.
  /// This class serves as the fundamental data unit for storing user-AI interactions.
  /// </remarks>
  TChatTurn = class(TJSONResource)
  strict private
    FId: string;
    FStorage: boolean;
    FPrompt: string;
    FResponse: string;
    FFileSearch: string;
    FWebSearch: string;
    FReasoning: string;
    FJsonPrompt: string;
    FJsonResponse: string;
    FJsonFileSearch: string;
    FJsonWebSearch: string;
    FJsonFunctionCall: string;
  public
    ///<summary> Unique identifier of the chat turn. </summary>
    property Id: string read FId write FId;

    ///<summary> Indicates whether this turn should be stored persistently. </summary>
    property Storage: boolean read FStorage write FStorage;

    ///<summary> Text of the user's prompt or question. </summary>
    property Prompt: string read FPrompt write FPrompt;

    ///<summary> Text of the AI's response to the prompt. </summary>
    property Response: string read FResponse write FResponse;

    ///<summary> Text of the AI's response to the FileSearch text. </summary>
    property FileSearch: string read FFileSearch write FFileSearch;

    ///<summary> Text of the AI's response to the WebSearch text. </summary>
    property WebSearch: string read FWebSearch write FWebSearch;

    ///<summary> Text of the AI's response to the reasoning text. </summary>
    property Reasoning: string read FReasoning write FReasoning;

    ///<summary> JSON-formatted detailed data about the prompt. </summary>
    property JsonPrompt: string read FJsonPrompt write FJsonPrompt;

    ///<summary> JSON-formatted detailed data about the response. </summary>
    property JsonResponse: string read FJsonResponse write FJsonResponse;

    ///<summary> JSON string representing file search results related to this turn. </summary>
    property JsonFileSearch: string read FJsonFileSearch write FJsonFileSearch;

    ///<summary> JSON string representing web search results related to this turn. </summary>
    property JsonWebSearch: string read FJsonWebSearch write FJsonWebSearch;

    ///<summary> JSON string containing function call information from AI output. </summary>
    property JsonFunctionCall: string read FJsonFunctionCall write FJsonFunctionCall;
  end;

  /// <summary>
  /// Represents a chat session containing multiple chat turns (exchanges),
  /// with editable metadata such as title, creation, and modification timestamps.
  /// </summary>
  /// <remarks>
  /// <para>
  /// Inherits from TJSONListParams with TChatTurn items to facilitate JSON serialization
  /// and deserialization of the entire session along with its constituent turns.
  /// </para>
  /// <para>
  /// Provides chainable methods for fluent setting of properties like Title, CreatedAt,
  /// and ModifiedAt. Supports saving the current chat session state persistently.
  /// </para>
  /// This class acts as the container for a full conversation history and its management.
  /// </remarks>
  TChatSession = class(TJSONListParams<TChatSession, TChatTurn>)
  strict private
    FCreatedAt: Int64;
    FModifiedAt: Int64;
    FTitle: string;
  public
    ///<summary> Sets the Title property and returns the current instance for chaining. </summary>
    ///<param name="Value"> The new title of the chat session. </param>
    function ApplyTitle(const Value: string): TChatSession;

    ///<summary> Sets the CreatedAt timestamp and returns the current instance for chaining. </summary>
    ///<param name="Value"> The creation timestamp in Int64 format. </param>
    function ApplyCreatedAt(const Value: Int64): TChatSession;

    ///<summary> Sets the ModifiedAt timestamp and returns the current instance for chaining. </summary>
    ///<param name="Value"> The modification timestamp in Int64 format. </param>
    function ApplyModifiedAt(const Value: Int64): TChatSession;

    /// <summary>
    /// Returns ChatTurn count
    /// </summary>
    function Count: Integer;

    ///<summary> Saves the current chat session's state persistently. </summary>
    ///<returns> The current instance for method chaining. </returns>
    function SaveCurrentChat: TChatSession;

    ///<summary> Timestamp indicating when the session was created. </summary>
    property CreatedAt: Int64 read FCreatedAt write FCreatedAt;

    ///<summary> Timestamp indicating the last modification date of the session. </summary>
    property ModifiedAt: Int64 read FModifiedAt write FModifiedAt;

    ///<summary>T he title of the chat session, typically user-editable. </summary>
    property Title: string read FTitle write FTitle;

    destructor Destroy; override;
  end;

  /// <summary>
  /// Represents a list of chat sessions, managing multiple conversations.
  /// </summary>
  /// <remarks>
  /// Inherits from TJSONListParams specialized for handling TChatSession objects.
  /// Provides singleton access via the Instance method, enabling centralized management
  /// of all chat sessions.
  /// Supports loading and reloading from JSON files with Reload, and saving data to disk.
  /// Offers operations such as Delete and Rename to manage chat sessions by item or index.
  /// Ensures persistence of chat session data with automatic JSON serialization.
  /// </remarks>
  TChatSessionList = class(TJSONListParams<TChatSessionList, TChatSession>)
  strict private
    /// <summary>
    /// Internal singleton instance.
    /// </summary>
    class var FInstance: TChatSessionList;
  public
    /// <summary>
    /// Gets the singleton instance of the chat session list.
    /// Loads the list from default JSON file if necessary.
    /// </summary>
    class function Instance: TChatSessionList; static;

    /// <summary>
    /// Reloads the chat session list from the specified JSON file or default file if omitted.
    /// Frees the previous instance and reloads it from storage.
    /// </summary>
    /// <param name="FileName">Optional JSON file name to load from.</param>
    /// <returns>The reloaded singleton instance.</returns>
    class function Reload(const FileName: string = ''): TChatSessionList; static;

    /// <summary>
    /// Returns the default JSON file name used for storing the chat sessions.
    /// </summary>
    class function JsonFileName: string;

    /// <summary>
    /// Deletes a chat session item.
    /// Calls the provided callback procedure for each stored chat turn's ID before deletion.
    /// </summary>
    /// <param name="Item">The chat session object to delete.</param>
    /// <param name="ParamProc">A callback procedure receiving each stored chat turn ID.</param>
    /// <returns>The chat session list instance for chaining.</returns>
    function Delete(const Item: TObject; ParamProc: TProc<string>): TChatSessionList; overload;

    /// <summary>
    /// Renames a chat session by its index in the list.
    /// Changes the session's title to the specified new title.
    /// </summary>
    /// <param name="Index">The index of the chat session to rename.</param>
    /// <param name="NewTitle">The new title to assign.</param>
    /// <returns>The chat session list instance for chaining.</returns>
    function Rename(const Index: Integer; NewTitle: string): TChatSessionList; overload;

    /// <summary>
    /// Renames a chat session given its object instance.
    /// Changes the session's title to the specified new title.
    /// </summary>
    /// <param name="Item">The chat session object to rename.</param>
    /// <param name="NewTitle">The new title to assign.</param>
    /// <returns>The chat session list instance for chaining.</returns>
    function Rename(const Item: TObject; NewTitle: string): TChatSessionList; overload;

    destructor Destroy; override;
  end;

  /// <summary>
  /// Interface for managing persistent chat sessions and prompts.
  /// </summary>
  /// <remarks>
  /// <para>
  /// This interface provides methods and properties to handle the lifecycle of chat sessions,
  /// including adding new chats and prompts, loading and saving chat data from/to files,
  /// and clearing the current chat state. It abstracts access to a collection of chat sessions
  /// and allows setting or retrieving the current chat session and prompt.
  /// </para>
  /// <para>
  /// Typical usage involves managing chat histories with persistence, enabling features like
  /// session switching, prompt additions, and file-based storage for conversation history.
  /// </para>
  /// </remarks>
  IPersistentChat = interface
    ['{7278ECC9-D702-4EC3-88E6-54B97732B7F5}']
    procedure SetCurrentChat(const Value: TChatSession);
    function GetData: TChatSessionList;
    function GetCurrentChat: TChatSession;
    function GetCurrentPrompt: TChatTurn;
    /// <summary>
    /// Adds a new chat session to the collection and sets it as current.
    /// </summary>
    /// <returns>The newly created TChatSession instance.</returns>
    function AddChat: TChatSession;

    /// <summary>
    /// Adds a new prompt (turn) to the current chat session.
    /// If no current chat exists, one is created automatically.
    /// </summary>
    /// <returns> The newly created TChatTurn instance representing the prompt.</returns>
    function AddPrompt: TChatTurn;

    /// <summary>
    /// Loads chat session data from a JSON file.
    /// </summary>
    /// <param name="FileName">Optional file name to load from. If empty, uses default storage.</param>
    /// <returns> Result of the load operation as a string, typically a status or file path.</returns>
    function LoadFromFile(FileName: string = ''): string;

    /// <summary>
    /// Returns session count
    /// </summary>
    function Count: Integer;

    /// <summary>
    /// Saves the current chat session data to a JSON file.
    /// </summary>
    /// <param name="FileName"> Optional file name to save to. If empty, uses default storage.</param>
    procedure SaveToFile(FileName: string = '');

    /// <summary>
    /// Clears the current chat and prompt references, effectively resetting the chat state.
    /// </summary>
    procedure Clear;

    /// <summary>
    /// Returns the list of ResponseIds
    /// </summary>
    function GetResponseIds: TArray<string>;

    /// <summary>
    /// Gets the full collection of chat sessions.
    /// </summary>
    property Data: TChatSessionList read GetData;

    /// <summary>
    /// Gets or sets the current active chat session.
    /// </summary>
    property CurrentChat: TChatSession read GetCurrentChat write SetCurrentChat;

    /// <summary>
    /// Gets the current prompt (turn) within the active chat session.
    /// </summary>
    property CurrentPrompt: TChatTurn read GetCurrentPrompt;
  end;

  TPersistentChat = class(TInterfacedObject, IPersistentChat)
  private
    FData: TChatSessionList;
    FCurrentChat: TChatSession;
    FCurrentPrompt: TChatTurn;
    function GetData: TChatSessionList;
    function GetCurrentChat: TChatSession;
    function GetCurrentPrompt: TChatTurn;
    procedure SetCurrentChat(const Value: TChatSession);
  public
    function AddChat: TChatSession;
    function AddPrompt: TChatTurn;
    function LoadFromFile(FileName: string = ''): string;
    procedure SaveToFile(FileName: string = '');
    procedure Clear;
    function Count: Integer;
    function GetResponseIds: TArray<string>;
    property Data: TChatSessionList read GetData;
    property CurrentChat: TChatSession read GetCurrentChat write SetCurrentChat;
    property CurrentPrompt: TChatTurn read GetCurrentPrompt;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  Manager.Intf;

{ TPersistentChat }

function TPersistentChat.AddChat: TChatSession;
begin
  Result := FData.AddItem;
  FCurrentChat := Result;
end;

function TPersistentChat.AddPrompt: TChatTurn;
begin
  if not Assigned(FCurrentChat) then
    FCurrentChat := FData.AddItem;
  FCurrentPrompt := FCurrentChat.AddItem;
  Result := FCurrentPrompt;
end;

procedure TPersistentChat.Clear;
begin
  FCurrentChat := nil;
  FCurrentPrompt := nil;
end;

function TPersistentChat.Count: Integer;
begin
  Result := Length(Data.Data);
end;

constructor TPersistentChat.Create;
begin
  inherited Create;
  FData := TChatSessionList.ReLoad;
end;

destructor TPersistentChat.Destroy;
begin
  FData.Free;
  inherited;
end;

function TPersistentChat.GetCurrentChat: TChatSession;
begin
  Result := FCurrentChat;
end;

function TPersistentChat.GetCurrentPrompt: TChatTurn;
begin
  Result := FCurrentPrompt;
end;

function TPersistentChat.GetData: TChatSessionList;
begin
  Result := FData;
end;

function TPersistentChat.GetResponseIds: TArray<string>;
begin
  for var Session in FData.Data do
   for var Turn in Session.Data do
     begin
       if Length(Result) = 0 then
         Result := [Turn.Id]
       else
         Result := Result + [Turn.Id];
     end;
end;

function TPersistentChat.LoadFromFile(FileName: string): string;
begin
  FData := TChatSessionList.Reload(FileName);
end;

procedure TPersistentChat.SaveToFile(FileName: string);
begin
  FData.Save(FileName);
end;

procedure TPersistentChat.SetCurrentChat(const Value: TChatSession);
begin
  FCurrentChat := Value;
end;

{ TChatSession }

function TChatSession.ApplyCreatedAt(const Value: Int64): TChatSession;
begin
  CreatedAt := Value;
  Result := Self;
end;

function TChatSession.ApplyModifiedAt(const Value: Int64): TChatSession;
begin
  ModifiedAt := Value;
  Result := Self;
end;

function TChatSession.ApplyTitle(const Value: string): TChatSession;
begin
  Title := Value;
  Result := Self;
end;

function TChatSession.Count: Integer;
begin
  Result := Length(Data);
end;

destructor TChatSession.Destroy;
begin
  Clear;
  inherited;
end;

function TChatSession.SaveCurrentChat: TChatSession;
begin
  if Assigned(PersistentChat) and Assigned(PersistentChat.CurrentChat) then
    PersistentChat.CurrentChat.Save;
  Result := Self;
end;

{ TChatSessionList }

function TChatSessionList.Delete(const Item: TObject;
  ParamProc: TProc<string>): TChatSessionList;
begin
  var Buffer := TChatSession(Item);

  for var Value in Buffer.Data do
    if Value.Storage and Assigned(ParamProc) then
      ParamProc(Value.Id);

  Result := inherited Delete(Item);
end;

destructor TChatSessionList.Destroy;
begin
  Clear;
  inherited;
end;

class function TChatSessionList.Instance: TChatSessionList;
begin
  if not Assigned(FInstance) then
    FInstance := TChatSessionList.Load as TChatSessionList;
  Result := FInstance;
end;

class function TChatSessionList.JsonFileName: string;
begin
  Result := DefaultFileName;
end;

class function TChatSessionList.Reload(
  const FileName: string): TChatSessionList;
begin
  FInstance.Free;
  FInstance := TChatSessionList.Load(FileName) as TChatSessionList;
  Result := FInstance;
end;

function TChatSessionList.Rename(const Item: TObject;
  NewTitle: string): TChatSessionList;
begin
  Result := Rename(ItemCheck(Item).IndexOf(Item), NewTitle);
end;

function TChatSessionList.Rename(const Index: Integer;
  NewTitle: string): TChatSessionList;
begin
  if index > -1 then
    begin
      EnsureIndex(Index).Data[Index].Chain.Apply('title', NewTitle);
    end;
  Result := Self;
end;

{ TChatSessionProp }

class function TChatSessionProp.CreatedAt: string;
begin
  Result := 'createdAt';
end;

class function TChatSessionProp.Data: string;
begin
  Result := 'data';
end;

class function TChatSessionProp.FileSearch: string;
begin
  Result := 'fileSearch';
end;

class function TChatSessionProp.Id: string;
begin
  Result := 'id';
end;

class function TChatSessionProp.JsonFileSearch: string;
begin
  Result := 'jsonFileSearch';
end;

class function TChatSessionProp.JsonFunctionCall: string;
begin
  Result := 'jsonFunctionCall';
end;

class function TChatSessionProp.JsonPrompt: string;
begin
  Result := 'jsonPrompt';
end;

class function TChatSessionProp.JsonResponse: string;
begin
  Result := 'jsonResponse';
end;

class function TChatSessionProp.JsonWebSearch: string;
begin
  Result := 'jsonWebSearch';
end;

class function TChatSessionProp.ModifiedAt: string;
begin
  Result := 'modifiedAt';
end;

class function TChatSessionProp.Prompt: string;
begin
  Result := 'prompt';
end;

class function TChatSessionProp.Reasoning: string;
begin
  Result := 'reasoning';
end;

class function TChatSessionProp.Response: string;
begin
  Result := 'response';
end;

class function TChatSessionProp.Storage: string;
begin
  Result := 'storage';
end;

class function TChatSessionProp.Title: string;
begin
  Result := 'title';
end;

class function TChatSessionProp.WebSearch: string;
begin
  Result := 'webSearch';
end;

end.
