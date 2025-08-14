unit Provider.OpenAI.ExecutionEngine;

interface

{$REGION 'Dev notes'}

(*
  Unit: Provider.OpenAI.ExecutionEngine

  Purpose:
    This unit implements the main execution engine for prompt submission and response handling in an OpenAI/GenAI Delphi integration.
    It manages the asynchronous lifecycle of prompt executions, including streaming, event-driven response processing,
    session storage, error management, and UI/interactor feedback.

  Architecture and approach:
    - TPromptExecutionEngine is the key orchestrator for executing user prompts:
        • Handles prompt formatting, parameter building, and contextual instructions (tools, web/file search, reasoning, etc).
        • Coordinates asynchronous streaming of results via the GenAI client, managing cancellation, error chains, file/web search and UI callbacks.
        • Delegates all event processing during response streaming to an event engine manager (IEventEngineManager).
        • Integrates with persistent session objects for chat continuity, storage, and history tracking.
    - Modularity and extensibility:
        • Designed for dependency injection; all external collaborations are interface-driven (GenAI, system prompt builder, etc).
        • Implements async promise patterns for non-blocking UI and workflow chaining.
        • All event/stream-specific logic is delegated to pluggable managers (cf. Provider.OpenAI.StreamEvents).
    - Robust lifecycle management:
        • Explicit control over chat turn creation, prompt history, intermediate/finalization states, cancellation, and error handling.
        • All UI and session feedback is routed explicitly for user experience and recoverability.

  Developer highlights:
    - To use, instantiate TPromptExecutionEngine via IoC or directly, providing required dependencies.
    - Execute() launches a full-featured prompt including streaming, event routing, session and history management.
    - Extendable by customizing IEventEngineManager or session/prompt builders for test or advanced scenarios.
    - Clear segregation of responsibilities for async chain, streaming, session save, and result collection.

  Dependencies:
    - GenAI and GenAI.Types for OpenAI contracts and API streaming.
    - Chat/session managers, prompt builders, output displayers, and cancellation management.
    - Event engine manager (cf. Provider.OpenAI.StreamEvents) for event-based streaming handling.

  This unit is designed for robustness, modularity, and scalability in prompt execution and streaming scenarios,
  enabling maintainable and extensible Delphi OpenAI/GenAI integrations aligned with best architecture practices (SOLID, async, DI).
*)

{$ENDREGION}

uses
  System.SysUtils, System.classes, System.Generics.Collections, System.DateUtils, System.Threading,
  GenAI, GenAI.Types, GenAI.Async.Promise,
  Manager.Intf, Manager.IoC, ChatSession.Controller, Manager.Utf8Mapping,
  Helper.UserSettings, Manager.Types, Provider.InstructionManager, Provider.OpenAI.StreamEvents,
  Helper.TextFile;

type
  /// <summary>
  ///   Main execution engine for OpenAI/GenAI prompt submission and streaming response
  ///   management within a Delphi application. Handles the full lifecycle of a prompt request,
  ///   including asynchronous API calls, streaming response processing, session tracking,
  ///   storage, and user interface integration.
  /// </summary>
  /// <remarks>
  ///   <para>
  ///   This class serves as the core orchestrator for all prompt execution workflows:
  ///   - Constructs prompt parameters (tools, reasoning, context, etc.) according to application settings.
  ///   - Manages integration with the GenAI client for both synchronous and asynchronous operations.
  ///   - Delegates streaming event processing to an event engine manager (<c>IEventEngineManager</c>),
  ///     which routes each event to registered event handlers.
  ///   - Tracks and persists session state, including chat history and streaming buffers.
  ///   - Coordinates error and cancellation handling for robust, user-friendly UX.
  ///   </para>
  ///   <para>
  ///   Designed for extensibility and modularity via dependency injection; can be replaced or extended
  ///   for custom scenarios, alternative engines, or unit testing.
  ///   </para>
  ///   Example usage:
  ///   <code>
  ///   var
  ///     Engine: IPromptExecutionEngine;
  ///   begin
  ///     Engine := TPromptExecutionEngine.Create(GenAIClient, SystemPromptBuilder);
  ///     Engine.Execute('Tell me a joke').&Then(
  ///       procedure(Response: string)
  ///       begin
  ///         ShowMessage(Response);
  ///       end
  ///     );
  ///   end;
  ///   </code>
  /// </remarks>
  TPromptExecutionEngine = class(TInterfacedObject, IPromptExecutionEngine)
  strict private
    procedure TurnUpdate;
    procedure ServiceClearUI;
    function UpdateAnnotation(const Displayer: IAnnotationsDisplayer): string;
    function CreateStreamParamsConfigurator(const Turn: TChatTurn): TProc<TResponsesParams>;
    function CreateErrorHandlerCallback(const StreamBuffer: string): TFunc<TObject, string, string>;
    function CreateCancellationHandlerCallback(const StreamBuffer: string): TFunc<TObject, string>;
  private
    /// <summary>
    /// The GenAI client instance used for all API communications.
    /// </summary>
    FClient: IGenAI;

    /// <summary>
    /// The builder instance for creating system/contextual prompts to send with user prompts.
    /// </summary>
    FSystemPromptBuilder: ISystemPromptBuilder;

    /// <summary>
    /// The event engine manager responsible for routing and processing streaming events during AI response flows.
    /// </summary>
    FEventEngineManager: IEventEngineManager;

    /// <summary>
    /// Builds the reasoning parameters structure used for advanced reasoning models.
    /// </summary>
    /// <returns>
    /// A fully populated <c>TReasoningParams</c> instance.
    /// </returns>
    function CreateReasoningEffortParams: TReasoningParams;

    /// <summary>
    /// Constructs the parameters for web search tool integration, selecting the preview/search tool type.
    /// </summary>
    /// <returns>
    /// An initialized <c>THostedToolParams</c> object ready for use in request configuration.
    /// </returns>
    function BuildWebSearchToolChoiceParams: THostedToolParams;

    /// <summary>
    /// Creates and configures file search tool parameters, supplying vector store identifiers if available.
    /// </summary>
    /// <returns>
    /// A <c>TResponseToolParams</c> object containing file search configuration.
    /// </returns>
    function CreateWebSearchToolParamsWithContext: TResponseToolParams;

    /// <summary>
    /// Creates and configures web search tool parameters, optionally including user geolocation context.
    /// </summary>
    /// <returns>
    /// A <c>TResponseToolParams</c> object for web search tool configuration.
    /// </returns>
    function CreateFileSearchToolParamsWithStore: TResponseToolParams;

    /// <summary>
    ///   Finalizes the current chat turn, updating stored search and reasoning results and saving session state.
    /// </summary>
    procedure FinalizeTurn;

    /// <summary>
    ///   Adds a new chat turn to the persistent session, stamping it with the current timestamp.
    /// </summary>
    /// <returns>
    ///   The new <c>TChatTurn</c> object representing the prompt/response exchange.
    /// </returns>
    function AddChatTurnWithTimestamp: TChatTurn;

    /// <summary>
    /// Event handler invoked at the start of a chat turn,
    /// used to reset UI state and displayers before streaming begins.
    /// </summary>
    /// <param name="Sender">
    /// The caller context for the start event (typically async engine or UI).
    /// </param>
    procedure OnTurnStart(Sender: TObject);

    /// <summary>
    /// Event handler invoked after a successful completion of a chat turn,
    /// finalizing UI and session state and saving results to storage.
    /// </summary>
    /// <param name="Sender">
    /// The sender of the completion notification (engine, promise, etc.).
    /// </param>
    function OnTurnSuccess(Sender: TObject): string;

    /// <summary>
    /// Event handler triggered when an error occurs during prompt execution or streaming.
    /// Finalizes state and displays an error message.
    /// </summary>
    /// <param name="Sender">
    /// The sender context of the error event.
    /// </param>
    /// <param name="Error">
    /// Description of the error encountered.
    /// </param>
    procedure OnTurnError(Sender: TObject; Error: string);

    /// <summary>
    /// Event handler triggered when the current chat turn is cancelled by the user or system.
    /// Cleans up UI state, flags cancellation, and persists session data.
    /// </summary>
    /// <param name="Sender">
    /// The context object triggering cancellation.
    /// </param>
    procedure OnTurnCancelled(Sender: TObject);

    /// <summary>
    /// Determines whether the current chat turn should be canceled and updates the UI if so.
    /// </summary>
    /// <returns>
    /// <c>True</c> if a cancellation has been requested; otherwise, <c>False</c>.
    /// </returns>
    /// <remarks>
    /// Used as the OnDoCancel callback during streaming.
    /// When <c>True</c>, it hides the reasoning bubble and displays an "Operation canceled" message.
    /// </remarks>
    function OnTurnDoCancel: Boolean;

    /// <summary>
    /// Initializes the HTTP client’s response timeout based on the current application settings.
    /// </summary>
    /// <remarks>
    /// Reads the timeout value from <c>Settings.TimeOut</c>, converts it into a cardinal number,
    /// and assigns it to the underlying GenAI client’s <c>HttpClient.ResponseTimeout</c> property.
    /// </remarks>
    procedure InitClientTimeOut;

    /// <summary>
    /// Configures the chat turn before execution by enabling storage and assigning the user prompt.
    /// </summary>
    /// <param name="Turn">The chat turn object that will be populated with the prompt and marked for storage.</param>
    /// <param name="Prompt">The text of the user’s prompt to send to the AI engine.</param>
    /// <remarks>
    /// Sets <c>Turn.Storage</c> to <c>True</c> and assigns <c>Turn.Prompt</c> to the provided <c>Prompt</c> string.
    /// This ensures the prompt is stored and ready for processing by the execution engine.
    /// </remarks>
    procedure ConfigureRequest(const Turn: TChatTurn; const Prompt: string);

    /// <summary>
    /// Creates and configures an asynchronous streaming request for the specified chat turn.
    /// </summary>
    /// <param name="Turn">
    /// The <c>TChatTurn</c> instance that contains the prompt text and storage flag;
    /// this turn will be used to build request parameters and track response progress.
    /// </param>
    /// <returns>
    /// A <c>TPromise&lt;string&gt;</c> that resolves with the AI’s full response text when streaming completes,
    /// or is rejected if an error or cancellation occurs.
    /// </returns>
    /// <remarks>
    /// - Evaluates active feature flags (reasoning, web search, file search) to choose the correct AI model and tools.
    /// - Sets <c>Params.Input</c> to <c>Turn.Prompt</c> and <c>Params.Instructions</c> via the system‐prompt builder.
    /// - Configures <c>Params.Tools</c> based on context (web search or file search) when reasoning is disabled.
    /// - Enables streaming (<c>Params.Stream(True)</c>) and persistence (<c>Params.Store(Turn.Storage)</c>),
    ///   linking to a previous response ID if one exists.
    /// - Serializes the prompt into <c>Turn.JsonPrompt</c> and immediately saves the chat to disk.
    /// - Assigns callbacks (<c>OnStart</c>, <c>OnProgress</c>, <c>OnSuccess</c>, <c>OnError</c>, <c>OnDoCancel</c>, <c>OnCancellation</c>)
    ///   to drive UI updates, error handling, and finalization logic as chunks stream in.
    /// </remarks>
    function BuildStreamPromise(const Turn: TChatTurn): TPromise<string>;

  public
    /// <summary>
    /// Submits a prompt for execution via the OpenAI/GenAI engine, handling streaming
    /// of results, session management, and output tracking.
    /// </summary>
    /// <param name="Prompt">
    /// The user's prompt or question to be sent to the AI for completion or answer.
    /// </param>
    /// <returns>
    /// A <c>TPromise&lt;string&gt;</c> that resolves asynchronously with the AI's response text,
    /// or is rejected if an error or cancellation occurs.
    /// </returns>
    function Execute(const Prompt: string): TPromise<string>;

    constructor Create(const GenAIClient: IGenAI; const AystemPromptBuilder: ISystemPromptBuilder);
  end;

implementation

{ TPromptExecutionEngine }

function TPromptExecutionEngine.AddChatTurnWithTimestamp: TChatTurn;
begin
  Result := PersistentChat.AddPrompt;

  if Length(PersistentChat.CurrentChat.Data) = 1 then
    begin
      PersistentChat.CurrentChat.CreatedAt := DateTimeToUnix(Now, False);
      PersistentChat.CurrentChat.Title := 'New chat ...';
    end;

  PersistentChat.CurrentChat.ModifiedAt := DateTimeToUnix(Now, False);
end;

function TPromptExecutionEngine.BuildStreamPromise(
  const Turn: TChatTurn): TPromise<string>;
{$REGION  'Dev notes : Contexte SSE & Streambuffer'}
(*
  - In the context of SSE reception, the promise associated with a canceled operation must be rejected,
    as it is not possible to guarantee the availability of a valid TResponseStream.

  - The "StreamBuffer" variable cannot be declared within the lambda "function TPromiseResponseStream",
    because although it can be captured, it would not have sufficient scope to ensure its integrity
    during the execution of the "OnError" and "OnCancellation" callbacks.
*)
{$ENDREGION}
var
  StreamBuffer: string;
begin
  var DisplayedChunkCount := 0;

  Result := FClient.Responses
    .AsyncAwaitCreateStream(
        CreateStreamParamsConfigurator(Turn),
        function : TPromiseResponseStream
        begin
          Result.Sender := Turn;
          Result.OnStart := OnTurnStart;

          {--- Chunk aggregation and error handling }
          Result.OnProgress :=
            procedure (Sender: TObject; Chunk: TResponseStream)
            begin
              if not FEventEngineManager.AggregateStreamEvents(Chunk, StreamBuffer, DisplayedChunkCount) then
                begin
                  {--- Error Event }
                  ResponseTracking.Cancel;
                  CreateErrorHandlerCallback(StreamBuffer)(Sender, #10#10 + Chunk.Code + ': ' + Chunk.Message);
                end;

              {--- Last event recieved : It will be resolved by default
                   => This implies that the OnSuccess cannot be invoked }
              if Chunk.&Type = TResponseStreamType.completed then
                begin
                  OnTurnSuccess(Sender);
                end;
            end;

          Result.OnError := CreateErrorHandlerCallback(StreamBuffer);
          Result.OnDoCancel := OnTurnDoCancel;
          Result.OnCancellation := CreateCancellationHandlerCallback(StreamBuffer);
        end)
    .&Then<string>(
        function (Value: TResponseStream): string
        begin
          for var Item in Value.Response.Output do
            for var SubItem in Item.Content do
              Result := Result + SubItem.Text;
        end);
end;

function TPromptExecutionEngine.BuildWebSearchToolChoiceParams: THostedToolParams;
begin
  Result := THostedToolParams.Create
    .&Type('web_search_preview')
end;

procedure TPromptExecutionEngine.ConfigureRequest(const Turn: TChatTurn; const Prompt: string);
begin
  Turn.Storage := True;
  Turn.Prompt := Prompt;
end;

constructor TPromptExecutionEngine.Create(const GenAIClient: IGenAI;
  const AystemPromptBuilder: ISystemPromptBuilder);
begin
  inherited Create;
  FClient := GenAIClient;
  FSystemPromptBuilder := AystemPromptBuilder;
  FEventEngineManager := TEventEngineManager.Create;
end;

function TPromptExecutionEngine.CreateCancellationHandlerCallback(
  const StreamBuffer: string): TFunc<TObject, string>;
begin
  Result := function (Sender: TObject): string
    begin
      (Sender as TChatTurn).Response := StreamBuffer + #10#10 + 'Aborted';
      OnTurnCancelled(Sender);
    end;
end;

function TPromptExecutionEngine.CreateFileSearchToolParamsWithStore: TResponseToolParams;
begin
  Result := TResponseFileSearchParams.New;

  if Length(FileStoreManager.VectorStore) > 0 then
    (Result as TResponseFileSearchParams).VectorStoreIds([FileStoreManager.VectorStore]);
end;

function TPromptExecutionEngine.CreateReasoningEffortParams: TReasoningParams;
begin
  {--- Create reasoning effort }
  Result := TReasoningParams.Create.Effort(Settings.ReasoningEffort);

  if Settings.UseSummary then
    Result.Summary(Settings.ReasoningSummary);
end;

function TPromptExecutionEngine.CreateStreamParamsConfigurator(
  const Turn: TChatTurn): TProc<TResponsesParams>;
var
  isGpt5serie: Boolean;
begin
  Result := procedure (Params: TResponsesParams)
    begin
      {--- Evaluate active service-feature flags for this call }
      var hasReasoning := sf_reasoning in ServiceFeatureSelector.FeatureModes;
      var hasWebSearch := sf_webSearch in ServiceFeatureSelector.FeatureModes;
      var fileSearchDisabled := sf_fileSearchDisabled in ServiceFeatureSelector.FeatureModes;
      var hasFileStore := Length(FileStoreManager.VectorStore) > 0;

      {--- Choose the proper AI model (reasoning vs. search) }
      if hasReasoning then
        begin
          isGpt5serie := Settings.ReasoningModel.StartsWith('gpt-5');
          Params.Model(Settings.ReasoningModel);
          Params.Reasoning(CreateReasoningEffortParams);
        end
      else
        begin
          isGpt5serie := Settings.SearchModel.StartsWith('gpt-5');
          {$REGION '400 Bad Request'}
          (*
             If the previous round of the session used a reasoning model, then this round will return:

                 400 Bad Request
                     Reasoning input items can only be provided to a reasoning or computer use model.
                     Remove reasoning items from your input and try again.

             As soon as you chain a reasoning-model call → non-reasoning-model call using previousResponseId,
             all input items—including those labeled type: "reasoning"—get passed back into gpt-4.1, triggering:

               - Reasoning input items can only be provided to a reasoning or computer use model

             Bug reported to OpenAI support on 05/29/2025
             https://community.openai.com/t/400-error-when-chaining-sessions-between-4-1-and-o4-mini/1272381/1
          *)
         {$ENDREGION}
          Params.Model(Settings.SearchModel);
        end;

      if isGpt5serie then
        Params.Text(TTextParams.Create.Verbosity(Settings.Verbosity));

      {--- Set user prompt }
      Params.Input(Turn.Prompt);

      {--- Set developer instructions }
      Params.Instructions(FSystemPromptBuilder.BuildSystemPrompt);

      {--- Set explicit tool choice }
      if hasWebSearch and not isGpt5serie then
        Params.ToolChoice(BuildWebSearchToolChoiceParams);

      {--- Tool selection according to feature flags }
      if not hasReasoning then
        begin
          if not fileSearchDisabled and hasFileStore and hasWebSearch then
            begin
              Params.Tools([
                CreateFileSearchToolParamsWithStore,
                CreateWebSearchToolParamsWithContext
              ]);
            end
          else
            if not fileSearchDisabled and hasFileStore then
              begin
                Params.Tools([ CreateFileSearchToolParamsWithStore ]);
              end
            else if hasWebSearch then
              begin
                Params.Tools([ CreateWebSearchToolParamsWithContext ]);
              end;
        end;

      Params.Include([ TOutputIncluding.file_search_result ]);

      {--- Enable streaming mode }
      Params.Stream(True);

      {--- Enable or disable storage based on configuration }
      Params.Store(Turn.Storage);

      {--- Link the request to a previous response ID }
      if Turn.Storage and not ResponseTracking.LastId.IsEmpty then
        Params.PreviousResponseId(ResponseTracking.LastId);

      {--- Serialize the request to the prompt data collector }
      Turn.JsonPrompt := Params.ToJsonString();

      {--- Persistently save the current turn to JSON }
      PersistentChat.SaveToFile;
    end;
end;

function TPromptExecutionEngine.CreateWebSearchToolParamsWithContext: TResponseToolParams;
begin
  Result := TResponseWebSearchParams.New
    .SearchContextSize(Settings.WebContextSize);

  if not Settings.Country.Trim.IsEmpty or not Settings.City.Trim.IsEmpty then
    (Result as TResponseWebSearchParams)
      .UserLocation(
        TResponseUserLocationParams.New
          .Country(Settings.Country)
          .City(Settings.City)
       );
end;

function TPromptExecutionEngine.Execute(const Prompt: string): TPromise<string>;
begin
  {--- Initialize the HTTP client’s response timeout using the current Settings.TimeOut value }
  InitClientTimeOut;

  {--- Create a new TChatTurn with the current timestamp and add it to the persistent chat session }
  var Turn := AddChatTurnWithTimestamp;

  {--- Mark the turn for storage and assign the user’s prompt text to the turn object }
  ConfigureRequest(Turn, Prompt);

  {--- Build and return the asynchronous streaming promise based on the configured turn }
  Result := BuildStreamPromise(Turn);
end;

procedure TPromptExecutionEngine.FinalizeTurn;
begin
  {--- Update FileSearch annotation in current prompt }
  PersistentChat.CurrentPrompt.FileSearch := UpdateAnnotation(FileSearchDisplayer);

  {--- Update WebSearch annotation in current prompt }
  PersistentChat.CurrentPrompt.WebSearch := UpdateAnnotation(WebSearchDisplayer);

  {--- Update Reasoning annotation in current prompt }
  PersistentChat.CurrentPrompt.Reasoning := UpdateAnnotation(ReasoningDisplayer);

  {--- Service persistent chat : Save to file as JSON }
  PersistentChat.SaveToFile;
end;

function TPromptExecutionEngine.CreateErrorHandlerCallback(
  const StreamBuffer: string): TFunc<TObject, string, string>;
begin
  Result := function (Sender: TObject; Error: string): string
    begin
      (Sender as TChatTurn).Response := StreamBuffer + #10#10 + Error;
      OnTurnError(Sender, Error);
      Result := Error;
    end;
end;

procedure TPromptExecutionEngine.InitClientTimeOut;
begin
  {--- Service GenAI client HTTP: set response timeout from user settings }
  FClient.API.HttpClient.ResponseTimeout := TTimeOut.TextToCardinal(Settings.TimeOut);
end;

procedure TPromptExecutionEngine.OnTurnCancelled(Sender: TObject);
begin
  {--- Service cancellation : disarm cancellation token }
  Cancellation.Cancel;

  {--- Finalize current chat turn (persist annotations, reset cancellation, refresh history view) }
  TurnUpdate;
end;

function TPromptExecutionEngine.OnTurnDoCancel: Boolean;
begin
  Result := Cancellation.IsCancelled;
  if Result then
    begin
      EdgeDisplayer.HideReasoning;
      EdgeDisplayer.Display(#10'Operation canceled');
    end;
end;

procedure TPromptExecutionEngine.OnTurnError(Sender: TObject; Error: string);
begin
  {--- Service tracking : cancel last response Id }
  ResponseTracking.Cancel;

    {--- Service cancellation : disarm cancellation token }
  Cancellation.Cancel(True);

  {--- Finalize current chat turn (persist annotations, reset cancellation, refresh history view) }
  TurnUpdate;

  {--- Service Edge browser : hide reasoning bubble }
  EdgeDisplayer.HideReasoning;

  {--- Service Edge browser : display error message }
  EdgeDisplayer.Display(TUtf8Mapping.CleanTextAsUTF8(Error));
end;

procedure TPromptExecutionEngine.OnTurnStart(Sender: TObject);
begin
  {--- Service cancellation : reset cancellation token }
  Cancellation.Reset;

  {--- Service prompt + Edge browser : display the current user input in the chat bubble }
  EdgeDisplayer.Prompt(ServicePrompt.Text);

  {--- Clear previous annotations/displays for file search, web search and reasoning }
  ServiceClearUI;

  {--- Service Edge browser : show reasoning bubble }
  EdgeDisplayer.ShowReasoning;
end;

function TPromptExecutionEngine.OnTurnSuccess(Sender: TObject): string;
begin
  {--- Service cancellation : disarm cancellation token }
  Cancellation.Cancel(True);

  {--- Finalize current chat turn (persist annotations, reset cancellation, refresh history view) }
  TurnUpdate;

  {--- Service Edge browser: add gap between chat turns }
  EdgeDisplayer.DisplayStream(sLineBreak + sLineBreak);

  {--- Service prompt selector: update prompt navigation/history UI }
  PromptSelector.Update;
end;

procedure TPromptExecutionEngine.ServiceClearUI;
begin
  {--- Service prompt : clear input editor }
  ServicePrompt.Clear;

  {--- Service file search displayer : clear previous file search results }
  FileSearchDisplayer.Clear;

  {--- Service web search displayer : clear previous web search results }
  WebSearchDisplayer.Clear;

  {--- Service reasoning displayer : clear previous reasoning logs }
  ReasoningDisplayer.Clear;
end;

procedure TPromptExecutionEngine.TurnUpdate;
begin
  {--- Finalize current chat turn (persist file/web/reasoning annotations, save session) }
  FinalizeTurn;

  {--- Service chat history view : refresh conversation history UI }
  ChatSessionHistoryView.Refresh(nil);
end;

function TPromptExecutionEngine.UpdateAnnotation(const Displayer: IAnnotationsDisplayer): string;
begin
  if Displayer.Text.IsEmpty then
    Displayer.Display('no item found');

  Result := Displayer.Text;
end;

end.
