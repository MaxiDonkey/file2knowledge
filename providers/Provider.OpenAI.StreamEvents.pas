unit Provider.OpenAI.StreamEvents;

interface

{$REGION  'Dev notes'}

(*
  Unit: Provider.OpenAI.StreamEvents

  Purpose:
    Centralizes the definition, enumeration, and handling of all possible streaming events
    that can occur during OpenAI/GenAI response processing within a Delphi application.
    Acts as the canonical inventory of API events for the v1/responses OpenAI endpoint.

  Architecture and approach:
    - Declares an exhaustive enumeration (TStreamEventType) mapping directly to all documented and supported OpenAI streaming events.
    - For every event type, provides a dedicated handler class (IStreamEventHandler descendant),
      each serving as a clear extension point for developers to implement custom logic.
    - The TEventExecutionEngine manages registration and dispatch of event handlers; all known event types
      are registered upon initialization for robust, ready-to-extend coverage.
    - By default, most handler classes are empty ("stub classes"), acting as both living documentation
      and a ready-made scaffold for incremental extension by consuming developers.

  Developer highlights:
    - Serves as an up-to-date self-documenting catalogue of all response events accepted by OpenAI v1/responses.
    - Adding or customizing behavior for a given event simply involves implementing or extending the associated handler class.
    - Ensures that as new events are added or API behaviors evolve, the codebase remains discoverable and maintainable,
      with no risk of silent event dropout or gaps in routing.
    - Facilitates onboarding: developers immediately see all extension points and never have to cross-reference external documentation.

  Usage:
    - TEventEngineManager (or compatible manager) inits and registers all handler classes on construction.
    - During response streaming, incoming event chunks are dispatched to the relevant handler based on their type string.
    - No handler may be omitted; every event type has an explicit handler class, empty or otherwise.

  Dependencies:
    - GenAI, GenAI.Types for response stream types and data contracts.
    - Session/displayer managers and mapping helpers for advanced event implementations.

  This unit is designed for exhaustiveness and maintainability, providing a framework (and living map) for
  the full set of OpenAI response events, ready for industrial extension and robust integration.

*)

{$ENDREGION}

uses
  System.SysUtils, System.Classes, Manager.Intf, GenAI, GenAI.Types, ChatSession.Controller,
  Manager.Utf8Mapping, Manager.Types;

type

  {$REGION 'Types and enumeration'}

  {--- List of events as of 06/15/2023 }
  TStreamEventType = (
    created,
    in_progress,
    completed,
    failed,
    incomplete,
    output_item_added,
    output_item_done,
    content_part_added,
    content_part_done,
    output_text_delta,
    output_text_annotation_added,
    output_text_done,
    refusal_delta,
    refusal_done,
    function_call_arguments_delta,
    function_call_arguments_done,
    file_search_call_in_progress,
    file_search_call_searching,
    file_search_call_completed,
    web_search_call_in_progress,
    web_search_call_searching,
    web_search_call_completed,
    reasoning_summary_part_add,
    reasoning_summary_part_done,
    reasoning_summary_text_delta,
    reasoning_summary_text_done,
    image_generation_call_completed,
    image_generation_call_generating,
    image_generation_call_in_progress,
    image_generation_call_partial_image,
    mcp_call_arguments_delta,
    mcp_call_arguments_done,
    mcp_call_completed,
    mcp_call_failed,
    mcp_call_in_progress,
    mcp_list_tools_completed,
    mcp_list_tools_failed,
    mcp_list_tools_in_progress,
    queued,
    reasoning_delta,
    reasoning_done,
    reasoning_summary_delta,
    reasoning_summary_done,
    error
  );

  TStreamEventTypeHelper = record Helper for TStreamEventType
  const
    StreamEventNames: array[TStreamEventType] of string = (
      'response.created',
      'response.in_progress',
      'response.completed',
      'response.failed',
      'response.incomplete',
      'response.output_item.added',
      'response.output_item.done',
      'response.content_part.added',
      'response.content_part.done',
      'response.output_text.delta',
      'response.output_text.annotation.added',
      'response.output_text.done',
      'response.refusal.delta',
      'response.refusal.done',
      'response.function_call_arguments.delta',
      'response.function_call_arguments.done',
      'response.file_search_call.in_progress',
      'response.file_search_call.searching',
      'response.file_search_call.completed',
      'response.web_search_call.in_progress',
      'response.web_search_call.searching',
      'response.web_search_call.completed',
      'response.reasoning_summary_part.added',
      'response.reasoning_summary_part.done',
      'response.reasoning_summary_text.delta',
      'response.reasoning_summary_text.done',
      'response.image_generation_call.completed',
      'response.image_generation_call.generating',
      'response.image_generation_call.in_progress',
      'response.image_generation_call.partial_image',
      'response.mcp_call.arguments.delta',
      'response.mcp_call.arguments.done',
      'response.mcp_call.completed',
      'response.mcp_call.failed',
      'response.mcp_call.in_progress',
      'response.mcp_list_tools.completed',
      'response.mcp_list_tools.failed',
      'response.mcp_list_tools.in_progress',
      'response.queued',
      'response.reasoning.delta',
      'response.reasoning.done',
      'response.reasoning_summary.delta',
      'response.reasoning_summary.done',
      'error'
    );
  public
    function ToString: string;
    class function FromString(const S: string): TStreamEventType; static;
    class function AllNames: TArray<string>; static;
  end;

  {$ENDREGION}

  {$REGION 'Interfaces'}

  /// <summary>
  ///   Interface for processing specific streaming events emitted during OpenAI/GenAI
  ///   asynchronous response streaming. Each implementation can determine which event type(s)
  ///   it can handle and process chunks accordingly.
  /// </summary>
  /// <remarks>
  ///   <para>
  ///   This interface is used within the event aggregation engine to route streaming event
  ///   chunks to the appropriate handler based on event type. Implementations should define
  ///   the logic required to process a given event type, update output buffers, or manage
  ///   display/UI accordingly.
  ///   </para>
  ///   <para>
  ///   All available OpenAI streaming event types are enumerated in <c>TStreamEventType</c>,
  ///   and one handler per event type is typically registered at initialization.
  ///   </para>
  ///   Example usage:
  ///   <code>
  ///   type
  ///     TMyOutputTextHandler = class(TInterfacedObject, IStreamEventHandler)
  ///       function CanHandle(EventType: TStreamEventType): Boolean;
  ///       function Handle(const Chunk: TResponseStream; var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
  ///     end;
  ///   </code>
  /// </remarks>
  IStreamEventHandler = interface
    /// <summary>
    ///   Indicates whether this handler is able to process the specified streaming event type.
    /// </summary>
    /// <param name="EventType">
    ///   The event type to check for handling capability.
    /// </param>
    /// <returns>
    ///   <c>True</c> if the handler can process the event; otherwise, <c>False</c>.
    /// </returns>
    function CanHandle(EventType: TStreamEventType): Boolean;

    /// <summary>
    ///   Handles a streaming event chunk and applies any necessary update or processing.
    /// </summary>
    /// <param name="Chunk">
    ///   The streaming response chunk data to process.
    /// </param>
    /// <param name="StreamBuffer">
    ///   Reference to the current output buffer, which may be updated.
    /// </param>
    /// <param name="ChunkDisplayedCount">
    ///   Reference to the count of displayed chunks, which may be incremented.
    /// </param>
    /// <returns>
    ///   <c>True</c> if processing can continue, or <c>False</c> to signal termination (e.g., on error).
    /// </returns>
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
  end;

  /// <summary>
  ///   Interface for managing the aggregation and routing of streaming response events
  ///   originating from the OpenAI/GenAI API. Handles delegation of each event chunk to
  ///   the appropriate event handler during asynchronous response streaming.
  /// </summary>
  /// <remarks>
  ///   <para>
  ///   Implementations of this interface act as the central event engine for the
  ///   streaming process, ensuring that every incoming event chunk is processed by its
  ///   corresponding handler (as defined by <c>IStreamEventHandler</c> implementations).
  ///   </para>
  ///   <para>
  ///   Event engines are designed to be extensible and robust, allowing custom logic
  ///   or new event types to be integrated without modifying upstream business logic.
  ///   </para>
  ///   Example usage:
  ///   <code>
  ///   var
  ///     Manager: IEventEngineManager;
  ///   begin
  ///     if not Manager.AggregateStreamEvents(Chunk, Buffer, Count) then
  ///       // Handle error or cancellation
  ///   end;
  ///   </code>
  /// </remarks>
  IEventEngineManager = interface
    ['{ED3CC5EA-EE71-4F45-AAE2-C54BE8A86157}']
    /// <summary>
    ///   Aggregates and processes incoming streaming event chunks from an OpenAI/GenAI response,
    ///   delegating each event to its registered handler.
    /// </summary>
    /// <param name="Chunk">
    ///   The current streaming response event chunk to process.
    /// </param>
    /// <param name="StreamBuffer">
    ///   Reference to the output buffer accumulated during streaming; may be modified by handlers.
    /// </param>
    /// <param name="ChunkDisplayedCount">
    ///   Reference to the count of output/displayed chunks; may be incremented as processing advances.
    /// </param>
    /// <returns>
    ///   <c>True</c> if processing should continue; <c>False</c> to indicate an error or
    ///   instructed termination (e.g., on an error event).
    /// </returns>
    function AggregateStreamEvents(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  {$ENDREGION}

  {$REGION 'Execution engine'}

  TEventExecutionEngine = class
  private
    FHandlers: TArray<IStreamEventHandler>;
  public
    procedure RegisterHandler(AHandler: IStreamEventHandler);
    function AggregateStreamEvents(const Chunk: TResponseStream;
      var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TEventEngineManager = class(TInterfacedObject, IEventEngineManager)
  private
    FEngine: TEventExecutionEngine;
    procedure EventExecutionEngineInitialize;
  public
    constructor Create;
    function AggregateStreamEvents(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
    destructor Destroy; override;
  end;

  {$ENDREGION}

  {$REGION 'Handlers - Status'}

  TSHCreate = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHInProgress = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHCompleted = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHFailed = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHIncomplete = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  {$ENDREGION}

  {$REGION 'Handlers - Output/content'}

  TSHOutputItemAdded = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHOutputItemDone = class(TInterfacedObject, IStreamEventHandler)
  private
    procedure DisplayFileSearchQueries(const Chunk: TResponseStream);
    procedure DisplayFileSearchResults(const Chunk: TResponseStream);
  public
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHContentPartAdded = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHContentPartDone = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHOutputTextDelta = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHOutputTextAnnotationAdded = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHOutputTextDone = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  {$ENDREGION}

  {$REGION 'Handlers - Refusal'}

  TSHRefusalDelta = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHRefusalDone = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  {$ENDREGION}

  {$REGION 'Handlers - Functions'}

  TSHFunctionCallArgumentsDelta = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHFunctionCallArgumentsDone = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  {$ENDREGION}

  {$REGION 'Handlers - File search'}

  TSHFileSearchCallInProgress = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHFileSearchCallSearching = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHFileSearchCallCompleted = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  {$ENDREGION}

  {$REGION 'Handlers - Web search'}

  TSHWebSearchCallInProgress = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHWebSearchCallSearching = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHWebSearchCallCompleted = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  {$ENDREGION}

  {$REGION 'Handlers - Reasoning part I'}

  TSHReasoningSummaryPartAdd = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHReasoningSummaryPartDone = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHReasoningSummaryTextDelta = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHReasoningSummaryTextDone = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  {$ENDREGION}

  {$REGION 'Handlers - Image generation'}

  TSHImageGenerationCallCompleted = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHImageGenerationCallGenerating = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHImageGenerationCallInProgress = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHImageGenerationCallPartialImage = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  {$ENDREGION}

  {$REGION 'Handlers - Remote MCP'}

  TSHMcpCallArgumentsDelta = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHMcpCallArgumentsDone = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHMcpCallCompleted = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHMcpCallFailed = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHMcpCallInProgress = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHMcpListToolsCompleted = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHMcpListToolsFailed = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHMcpListToolsInProgress = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  {$ENDREGION}

  {$REGION 'Handlers - Queued'}

  TSHQueued = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  {$ENDREGION}

  {$REGION 'Handlers - Reasoning part II'}

  TSHReasoningDelta = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHReasoningDone = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHReasoningSummaryDelta = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TSHReasoningSummaryDone = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  {$ENDREGION}

  {$REGION 'Handlers - Error'}

  TSHError = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream;var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  {$ENDREGION}

implementation

{ TStreamEventTypeHelper }

class function TStreamEventTypeHelper.AllNames: TArray<string>;
begin
  SetLength(Result, Ord(High(TResponseStreamType)) + 1);
  for var Item := Low(TStreamEventType) to High(TStreamEventType) do
    Result[Ord(Item)] := StreamEventNames[Item];
end;

class function TStreamEventTypeHelper.FromString(
  const S: string): TStreamEventType;
begin
  for var Item := Low(TStreamEventType) to High(TStreamEventType) do
    if SameText(S, StreamEventNames[Item]) then
      Exit(Item);

  raise Exception.CreateFmt('Unknown response stream type string: %s', [S]);
end;

function TStreamEventTypeHelper.ToString: string;
begin
  Result := StreamEventNames[Self];
end;

{ TEventExecutionEngine }

function TEventExecutionEngine.AggregateStreamEvents(const Chunk: TResponseStream;
  var StreamBuffer: string;
  var ChunkDisplayedCount: Integer): Boolean;
begin
  var EventType := TStreamEventType.FromString(Chunk.&Type.ToString);

  for var Handler in FHandlers do
    if Handler.CanHandle(EventType) then
      begin
        Result := Handler.Handle(Chunk, StreamBuffer, ChunkDisplayedCount);
        Exit;
      end;

      {$REGION 'Dev note'}
       (*
         Not finding a matching event should not, on its own, cause Result to become false.
         It should only be set to false  when an error event is encountered. Otherwise, the
         process would  automatically fail whenever  OpenAI introduced a  new event that we
         haven’t yet handled.
       *)
       {$ENDREGION}
  Result := True;
end;

procedure TEventExecutionEngine.RegisterHandler(AHandler: IStreamEventHandler);
begin
  FHandlers := FHandlers + [AHandler];
end;

{ TSHCreate }

function TSHCreate.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.created;
end;

function TSHCreate.Handle(const Chunk: TResponseStream; var StreamBuffer: string;
  var ChunkDisplayedCount: Integer): Boolean;
begin
  PersistentChat.CurrentPrompt.Id := Chunk.Response.Id;
  ResponseTracking.Add(Chunk.Response.Id);
  Result := True;
end;

{ TSHError }

function TSHError.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.error;
end;

function TSHError.Handle(const Chunk: TResponseStream;var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  PersistentChat.CurrentPrompt.Response := StreamBuffer;
  Result := False;
end;

{ TSHOutputTextDelta }

function TSHOutputTextDelta.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.output_text_delta;
end;

function TSHOutputTextDelta.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
  EdgeDisplayer.HideReasoning;
  var Delta := TUtf8Mapping.CleanTextAsUTF8(Chunk.Delta);
  EdgeDisplayer.DisplayStream(Delta, (ChunkDisplayedCount < 20) );
  ChunkDisplayedCount := ChunkDisplayedCount + 1;
  StreamBuffer := StreamBuffer + Delta;
end;

{ TSHReasoningSummaryTextDelta }

function TSHReasoningSummaryTextDelta.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.reasoning_summary_text_delta;
end;

function TSHReasoningSummaryTextDelta.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
  Selector.ShowPage(psReasoning);
  ReasoningDisplayer.DisplayStream(Chunk.Delta);
end;

{ TSHReasoningSummaryTextDone }

function TSHReasoningSummaryTextDone.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.reasoning_summary_text_done;
end;

function TSHReasoningSummaryTextDone.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
  Selector.ShowPage(psReasoning);
  if ReasoningDisplayer.IsEmpty then
    ReasoningDisplayer.DisplayStream('Empty reasoning item');
end;

{ TSHOutputTextDone }

function TSHOutputTextDone.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.output_text_done;
end;

function TSHOutputTextDone.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
  if PersistentChat.CurrentPrompt.Response.Trim.IsEmpty then
    PersistentChat.CurrentPrompt.Response := Chunk.Text;
end;

{ TSHOutputTextAnnotationAdded }

function TSHOutputTextAnnotationAdded.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.output_text_annotation_added;
end;

function TSHOutputTextAnnotationAdded.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
  if not Chunk.Annotation.Url.IsEmpty then
    begin
      Selector.ShowPage(psWebSearch);
      WebSearchDisplayer.Display(#10'Annotation: ');
      WebSearchDisplayer.Display(
        Format('%s '#10'Indexes = [ start( %d ); end( %d ) ]'#10'Url: %s'#10, [
          Chunk.Annotation.Title,
          Chunk.Annotation.StartIndex,
          Chunk.Annotation.EndIndex,
          Chunk.Annotation.Url
        ])
      );
    end;
  if not Chunk.Annotation.FileId.IsEmpty then
    begin
      Selector.ShowPage(psFileSearch);
      FileSearchDisplayer.Display(#10'Annotation: ');
      FileSearchDisplayer.Display(
        Format('%s [index %d]'#10'%s'#10, [
          Chunk.Annotation.Filename,
          Chunk.Annotation.Index,
          Chunk.Annotation.FileId
        ])
      );
    end;
end;

{ TSHOutputItemDone }

function TSHOutputItemDone.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.output_item_done;
end;

procedure TSHOutputItemDone.DisplayFileSearchQueries(
  const Chunk: TResponseStream);
begin
  if Length(Chunk.Item.Queries) > 0 then
    begin
      FileSearchDisplayer.Display('Queries : '#10);
      var cpt := 1;
      for var Item in Chunk.Item.Queries do
        begin
          FileSearchDisplayer.Display(Format('%d. %s',[cpt, Item]));
          Inc(cpt);
        end;
    end;
end;

procedure TSHOutputItemDone.DisplayFileSearchResults(
  const Chunk: TResponseStream);
begin
  if Length(Chunk.Item.Results) > 0 then
    begin
      FileSearchDisplayer.Display(#10#10'The results of a file search: '#10);
      for var Item in Chunk.Item.Results do
        begin
          FileSearchDisplayer.Display(
            Format('%s'#10'%s [score: %s]'#10, [
              Item.FileId,
              Item.Filename,
              Item.Score.ToString(ffNumber,3,3)
            ])
          );
        end;
    end;
end;

function TSHOutputItemDone.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;

  if Chunk.Item.Id.ToLower.StartsWith('msg_') then
    begin
      if PersistentChat.CurrentPrompt.JsonResponse.Trim.IsEmpty then
        begin
          PersistentChat.CurrentPrompt.JsonResponse := Chunk.JSONResponse;
        end;

      if PersistentChat.CurrentPrompt.Response.Trim.IsEmpty then
        PersistentChat.CurrentPrompt.Response := Chunk.Item.Content[0].Text;
    end
  else
  if Chunk.Item.Id.ToLower.StartsWith('fs_') then
    begin
      PersistentChat.CurrentPrompt.JsonFileSearch := Chunk.JSONResponse;
      Selector.ShowPage(psFileSearch);
      DisplayFileSearchQueries(Chunk);
      DisplayFileSearchResults(Chunk);
    end
  else
  if Chunk.Item.Id.ToLower.StartsWith('ws_') then
    begin
      Selector.ShowPage(psWebSearch);
      PersistentChat.CurrentPrompt.JsonWebSearch := Chunk.JSONResponse;
    end;
end;

{ TEventEngineManager }

function TEventEngineManager.AggregateStreamEvents(
  const Chunk: TResponseStream; var StreamBuffer: string;
  var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := FEngine.AggregateStreamEvents(Chunk, StreamBuffer, ChunkDisplayedCount);
end;

constructor TEventEngineManager.Create;
begin
  inherited Create;
  EventExecutionEngineInitialize;
end;

destructor TEventEngineManager.Destroy;
begin
  FEngine.Free;
  inherited;
end;

procedure TEventEngineManager.EventExecutionEngineInitialize;
begin
  {--- NOTE: TEventEngineManager is a singleton }
  FEngine := TEventExecutionEngine.Create;
  FEngine.RegisterHandler(TSHCreate.Create);
  FEngine.RegisterHandler(TSHInProgress.Create);
  FEngine.RegisterHandler(TSHCompleted.Create);
  FEngine.RegisterHandler(TSHFailed.Create);
  FEngine.RegisterHandler(TSHIncomplete.Create);
  FEngine.RegisterHandler(TSHOutputItemAdded.Create);
  FEngine.RegisterHandler(TSHOutputItemDone.Create);
  FEngine.RegisterHandler(TSHContentPartAdded.Create);
  FEngine.RegisterHandler(TSHContentPartDone.Create);
  FEngine.RegisterHandler(TSHOutputTextDelta.Create);
  FEngine.RegisterHandler(TSHOutputTextAnnotationAdded.Create);
  FEngine.RegisterHandler(TSHOutputTextDone.Create);
  FEngine.RegisterHandler(TSHRefusalDelta.Create);
  FEngine.RegisterHandler(TSHRefusalDone.Create);
  FEngine.RegisterHandler(TSHFunctionCallArgumentsDelta.Create);
  FEngine.RegisterHandler(TSHFunctionCallArgumentsDone.Create);
  FEngine.RegisterHandler(TSHFileSearchCallInProgress.Create);
  FEngine.RegisterHandler(TSHFileSearchCallSearching.Create);
  FEngine.RegisterHandler(TSHFileSearchCallCompleted.Create);
  FEngine.RegisterHandler(TSHWebSearchCallInProgress.Create);
  FEngine.RegisterHandler(TSHWebSearchCallSearching.Create);
  FEngine.RegisterHandler(TSHWebSearchCallCompleted.Create);
  FEngine.RegisterHandler(TSHReasoningSummaryPartAdd.Create);
  FEngine.RegisterHandler(TSHReasoningSummaryPartDone.Create);
  FEngine.RegisterHandler(TSHReasoningSummaryTextDelta.Create);
  FEngine.RegisterHandler(TSHReasoningSummaryTextDone.Create);
  FEngine.RegisterHandler(TSHImageGenerationCallCompleted.Create);
  FEngine.RegisterHandler(TSHImageGenerationCallGenerating.Create);
  FEngine.RegisterHandler(TSHImageGenerationCallInProgress.Create);
  FEngine.RegisterHandler(TSHImageGenerationCallPartialImage.Create);
  FEngine.RegisterHandler(TSHMcpCallArgumentsDelta.Create);
  FEngine.RegisterHandler(TSHMcpCallArgumentsDone.Create);
  FEngine.RegisterHandler(TSHMcpCallCompleted.Create);
  FEngine.RegisterHandler(TSHMcpCallFailed.Create);
  FEngine.RegisterHandler(TSHMcpCallInProgress.Create);
  FEngine.RegisterHandler(TSHMcpListToolsCompleted.Create);
  FEngine.RegisterHandler(TSHMcpListToolsFailed.Create);
  FEngine.RegisterHandler(TSHMcpListToolsInProgress.Create);
  FEngine.RegisterHandler(TSHQueued.Create);
  FEngine.RegisterHandler(TSHReasoningDelta.Create);
  FEngine.RegisterHandler(TSHReasoningDone.Create);
  FEngine.RegisterHandler(TSHReasoningSummaryDelta.Create);
  FEngine.RegisterHandler(TSHReasoningSummaryDone.Create);
  FEngine.RegisterHandler(TSHError.Create);
end;

{ TSHInProgress }

function TSHInProgress.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.in_progress;
end;

function TSHInProgress.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHCompleted }

function TSHCompleted.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.completed;
end;

function TSHCompleted.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHFailed }

function TSHFailed.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.failed;
end;

function TSHFailed.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHIncomplete }

function TSHIncomplete.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.incomplete;
end;

function TSHIncomplete.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHOutputItemAdded }

function TSHOutputItemAdded.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.output_item_added;
end;

function TSHOutputItemAdded.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHContentPartAdded }

function TSHContentPartAdded.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.content_part_added;
end;

function TSHContentPartAdded.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHContentPartDone }

function TSHContentPartDone.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.content_part_done;
end;

function TSHContentPartDone.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHRefusalDelta }

function TSHRefusalDelta.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.refusal_delta;
end;

function TSHRefusalDelta.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHefusalDone }

function TSHRefusalDone.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.refusal_done;
end;

function TSHRefusalDone.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHFunctionCallArgumentsDelta }

function TSHFunctionCallArgumentsDelta.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.function_call_arguments_delta;
end;

function TSHFunctionCallArgumentsDelta.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHFunctionCallArgumentsDone }

function TSHFunctionCallArgumentsDone.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.function_call_arguments_done;
end;

function TSHFunctionCallArgumentsDone.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHFileSearchCallInProgress }

function TSHFileSearchCallInProgress.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.file_search_call_in_progress;
end;

function TSHFileSearchCallInProgress.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHFileSearchCallSearching }

function TSHFileSearchCallSearching.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.file_search_call_searching;
end;

function TSHFileSearchCallSearching.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHFileSearchCallCompleted }

function TSHFileSearchCallCompleted.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.file_search_call_completed;
end;

function TSHFileSearchCallCompleted.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHWebSearchCallInProgress }

function TSHWebSearchCallInProgress.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.web_search_call_in_progress;
end;

function TSHWebSearchCallInProgress.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHWebSearchCallSearching }

function TSHWebSearchCallSearching.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.web_search_call_searching;
end;

function TSHWebSearchCallSearching.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHWebSearchCallCompleted }

function TSHWebSearchCallCompleted.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.web_search_call_completed;
end;

function TSHWebSearchCallCompleted.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHReasoningSummaryPartAdd }

function TSHReasoningSummaryPartAdd.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.reasoning_summary_part_add;
end;

function TSHReasoningSummaryPartAdd.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHReasoningSummaryPartDone }

function TSHReasoningSummaryPartDone.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.reasoning_summary_part_done;
end;

function TSHReasoningSummaryPartDone.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHImageGenerationCallCompleted }

function TSHImageGenerationCallCompleted.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.image_generation_call_completed;
end;

function TSHImageGenerationCallCompleted.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHImageGenerationCallGenerating }

function TSHImageGenerationCallGenerating.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.image_generation_call_generating;
end;

function TSHImageGenerationCallGenerating.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHImageGenerationCallInProgress }

function TSHImageGenerationCallInProgress.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.image_generation_call_in_progress;
end;

function TSHImageGenerationCallInProgress.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHImageGenerationCallPartialImage }

function TSHImageGenerationCallPartialImage.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.image_generation_call_partial_image;
end;

function TSHImageGenerationCallPartialImage.Handle(
  const Chunk: TResponseStream; var StreamBuffer: string;
  var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHMcpCallArgumentsDelta }

function TSHMcpCallArgumentsDelta.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.mcp_call_arguments_delta;
end;

function TSHMcpCallArgumentsDelta.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHMcpCallArgumentsDone }

function TSHMcpCallArgumentsDone.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.mcp_call_arguments_done;
end;

function TSHMcpCallArgumentsDone.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHMcpCallCompleted }

function TSHMcpCallCompleted.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.mcp_call_completed;
end;

function TSHMcpCallCompleted.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHMcpCallFailed }

function TSHMcpCallFailed.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.mcp_call_failed;
end;

function TSHMcpCallFailed.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHMcpCallInProgress }

function TSHMcpCallInProgress.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.mcp_call_in_progress;
end;

function TSHMcpCallInProgress.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHMcpListToolsCompleted }

function TSHMcpListToolsCompleted.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.mcp_list_tools_completed;
end;

function TSHMcpListToolsCompleted.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHMcpListToolsFailed }

function TSHMcpListToolsFailed.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.mcp_list_tools_failed;
end;

function TSHMcpListToolsFailed.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHMcpListToolsInProgress }

function TSHMcpListToolsInProgress.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.mcp_list_tools_in_progress;
end;

function TSHMcpListToolsInProgress.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHQueued }

function TSHQueued.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.queued;
end;

function TSHQueued.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHReasoningDelta }

function TSHReasoningDelta.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.reasoning_delta;
end;

function TSHReasoningDelta.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHReasoningDone }

function TSHReasoningDone.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.reasoning_done;
end;

function TSHReasoningDone.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHReasoningSummaryDelta }

function TSHReasoningSummaryDelta.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.reasoning_summary_delta;
end;

function TSHReasoningSummaryDelta.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TSHReasoningSummaryDone }

function TSHReasoningSummaryDone.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.reasoning_summary_done;
end;

function TSHReasoningSummaryDone.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

end.
