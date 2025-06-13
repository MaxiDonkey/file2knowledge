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
  {--- List of events as of 05/15/2023 }
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
      'error'
    );
  public
    function ToString: string;
    class function FromString(const S: string): TStreamEventType; static;
    class function AllNames: TArray<string>; static;
  end;

  {--- Interfaces }

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

  {--- Engine and Engine manager **********************************************}

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

  {--- Events *****************************************************************}

  TEHCreate = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TEHInProgress = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TEHCompleted = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TEHFailed = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TEHIncomplete = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TEHOutputItemAdded = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TEHOutputItemDone = class(TInterfacedObject, IStreamEventHandler)
  private
    procedure DisplayFileSearchQueries(const Chunk: TResponseStream);
    procedure DisplayFileSearchResults(const Chunk: TResponseStream);
  public
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TEHContentPartAdded = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TEHContentPartDone = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TEHOutputTextDelta = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TEHOutputTextAnnotationAdded = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TEHOutputTextDone = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TEHRefusalDelta = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TEHRefusalDone = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TEHFunctionCallArgumentsDelta = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TEHFunctionCallArgumentsDone = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TEHFileSearchCallInProgress = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TEHFileSearchCallSearching = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TEHFileSearchCallCompleted = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TEHWebSearchCallInProgress = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TEHWebSearchCallSearching = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TEHWebSearchCallCompleted = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TEHReasoningSummaryPartAdd = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TEHReasoningSummaryPartDone = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TEHReasoningSummaryTextDelta = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TEHReasoningSummaryTextDone = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream; var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

  TEHError = class(TInterfacedObject, IStreamEventHandler)
    function CanHandle(EventType: TStreamEventType): Boolean;
    function Handle(const Chunk: TResponseStream;var StreamBuffer: string;
      var ChunkDisplayedCount: Integer): Boolean;
  end;

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

  {--- Not finding a matching event should not, on its own, cause Result to become false.
       It should only be set to false  when an error event is encountered. Otherwise, the
       process would  automatically fail whenever  OpenAI introduced a  new event that we
       haven’t yet handled. }
  Result := True;
end;

procedure TEventExecutionEngine.RegisterHandler(AHandler: IStreamEventHandler);
begin
  FHandlers := FHandlers + [AHandler];
end;

{ TEHCreate }

function TEHCreate.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.created;
end;

function TEHCreate.Handle(const Chunk: TResponseStream; var StreamBuffer: string;
  var ChunkDisplayedCount: Integer): Boolean;
begin
  PersistentChat.CurrentPrompt.Id := Chunk.Response.Id;
  ResponseTracking.Add(Chunk.Response.Id);
  Result := True;
end;

{ TEHError }

function TEHError.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.error;
end;

function TEHError.Handle(const Chunk: TResponseStream;var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  PersistentChat.CurrentPrompt.Response := StreamBuffer;
  Result := False;
end;

{ TEHOutputTextDelta }

function TEHOutputTextDelta.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.output_text_delta;
end;

function TEHOutputTextDelta.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
  EdgeDisplayer.HideReasoning;
  var Delta := TUtf8Mapping.CleanTextAsUTF8(Chunk.Delta);
  EdgeDisplayer.DisplayStream(Delta, (ChunkDisplayedCount < 20) );
  ChunkDisplayedCount := ChunkDisplayedCount + 1;
  StreamBuffer := StreamBuffer + Delta;
end;

{ TEHReasoningSummaryTextDelta }

function TEHReasoningSummaryTextDelta.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.reasoning_summary_text_delta;
end;

function TEHReasoningSummaryTextDelta.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
  Selector.ShowPage(psReasoning);
  ReasoningDisplayer.DisplayStream(Chunk.Delta);
end;

{ TEHReasoningSummaryTextDone }

function TEHReasoningSummaryTextDone.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.reasoning_summary_text_done;
end;

function TEHReasoningSummaryTextDone.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
  Selector.ShowPage(psReasoning);
  if ReasoningDisplayer.IsEmpty then
    ReasoningDisplayer.DisplayStream('Empty reasoning item');
end;

{ TEHOutputTextDone }

function TEHOutputTextDone.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.output_text_done;
end;

function TEHOutputTextDone.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
  if PersistentChat.CurrentPrompt.Response.Trim.IsEmpty then
    PersistentChat.CurrentPrompt.Response := Chunk.Text;
end;

{ TEHOutputTextAnnotationAdded }

function TEHOutputTextAnnotationAdded.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.output_text_annotation_added;
end;

function TEHOutputTextAnnotationAdded.Handle(const Chunk: TResponseStream;
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

{ TEHOutputItemDone }

function TEHOutputItemDone.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.output_item_done;
end;

procedure TEHOutputItemDone.DisplayFileSearchQueries(
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

procedure TEHOutputItemDone.DisplayFileSearchResults(
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

function TEHOutputItemDone.Handle(const Chunk: TResponseStream;
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
      DisplayFileSearchQueries(Chunk);
      DisplayFileSearchResults(Chunk);
    end
  else
  if Chunk.Item.Id.ToLower.StartsWith('ws_') then
    begin
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
  FEngine.RegisterHandler(TEHCreate.Create);
  FEngine.RegisterHandler(TEHInProgress.Create);
  FEngine.RegisterHandler(TEHCompleted.Create);
  FEngine.RegisterHandler(TEHFailed.Create);
  FEngine.RegisterHandler(TEHIncomplete.Create);
  FEngine.RegisterHandler(TEHOutputItemAdded.Create);
  FEngine.RegisterHandler(TEHOutputItemDone.Create);
  FEngine.RegisterHandler(TEHContentPartAdded.Create);
  FEngine.RegisterHandler(TEHContentPartDone.Create);
  FEngine.RegisterHandler(TEHOutputTextDelta.Create);
  FEngine.RegisterHandler(TEHOutputTextAnnotationAdded.Create);
  FEngine.RegisterHandler(TEHOutputTextDone.Create);
  FEngine.RegisterHandler(TEHRefusalDelta.Create);
  FEngine.RegisterHandler(TEHRefusalDone.Create);
  FEngine.RegisterHandler(TEHFunctionCallArgumentsDelta.Create);
  FEngine.RegisterHandler(TEHFunctionCallArgumentsDone.Create);
  FEngine.RegisterHandler(TEHFileSearchCallInProgress.Create);
  FEngine.RegisterHandler(TEHFileSearchCallSearching.Create);
  FEngine.RegisterHandler(TEHFileSearchCallCompleted.Create);
  FEngine.RegisterHandler(TEHWebSearchCallInProgress.Create);
  FEngine.RegisterHandler(TEHWebSearchCallSearching.Create);
  FEngine.RegisterHandler(TEHWebSearchCallCompleted.Create);
  FEngine.RegisterHandler(TEHReasoningSummaryPartAdd.Create);
  FEngine.RegisterHandler(TEHReasoningSummaryPartDone.Create);
  FEngine.RegisterHandler(TEHReasoningSummaryTextDelta.Create);
  FEngine.RegisterHandler(TEHReasoningSummaryTextDone.Create);
  FEngine.RegisterHandler(TEHError.Create);
end;

{ TEHInProgress }

function TEHInProgress.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.in_progress;
end;

function TEHInProgress.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TEHCompleted }

function TEHCompleted.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.completed;
end;

function TEHCompleted.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TEHFailed }

function TEHFailed.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.failed;
end;

function TEHFailed.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TEHIncomplete }

function TEHIncomplete.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.incomplete;
end;

function TEHIncomplete.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TEHOutputItemAdded }

function TEHOutputItemAdded.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.output_item_added;
end;

function TEHOutputItemAdded.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TEHContentPartAdded }

function TEHContentPartAdded.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.content_part_added;
end;

function TEHContentPartAdded.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TEHContentPartDone }

function TEHContentPartDone.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.content_part_done;
end;

function TEHContentPartDone.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TEHRefusalDelta }

function TEHRefusalDelta.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.refusal_delta;
end;

function TEHRefusalDelta.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TEHRefusalDone }

function TEHRefusalDone.CanHandle(EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.refusal_done;
end;

function TEHRefusalDone.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TEHFunctionCallArgumentsDelta }

function TEHFunctionCallArgumentsDelta.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.function_call_arguments_delta;
end;

function TEHFunctionCallArgumentsDelta.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TEHFunctionCallArgumentsDone }

function TEHFunctionCallArgumentsDone.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.function_call_arguments_done;
end;

function TEHFunctionCallArgumentsDone.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TEHFileSearchCallInProgress }

function TEHFileSearchCallInProgress.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.file_search_call_in_progress;
end;

function TEHFileSearchCallInProgress.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TEHFileSearchCallSearching }

function TEHFileSearchCallSearching.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.file_search_call_searching;
end;

function TEHFileSearchCallSearching.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TEHFileSearchCallCompleted }

function TEHFileSearchCallCompleted.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.file_search_call_completed;
end;

function TEHFileSearchCallCompleted.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TEHWebSearchCallInProgress }

function TEHWebSearchCallInProgress.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.web_search_call_in_progress;
end;

function TEHWebSearchCallInProgress.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TEHWebSearchCallSearching }

function TEHWebSearchCallSearching.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.web_search_call_searching;
end;

function TEHWebSearchCallSearching.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TEHWebSearchCallCompleted }

function TEHWebSearchCallCompleted.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.web_search_call_completed;
end;

function TEHWebSearchCallCompleted.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TEHReasoningSummaryPartAdd }

function TEHReasoningSummaryPartAdd.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.reasoning_summary_part_add;
end;

function TEHReasoningSummaryPartAdd.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

{ TEHReasoningSummaryPartDone }

function TEHReasoningSummaryPartDone.CanHandle(
  EventType: TStreamEventType): Boolean;
begin
  Result := EventType = TStreamEventType.reasoning_summary_part_done;
end;

function TEHReasoningSummaryPartDone.Handle(const Chunk: TResponseStream;
  var StreamBuffer: string; var ChunkDisplayedCount: Integer): Boolean;
begin
  Result := True;
end;

end.
