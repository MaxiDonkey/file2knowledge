unit Provider.OpenAI;

interface

{$REGION  'Dev notes : Provider.OpenAI'}

(*
  Unit: Provider.OpenAI

  Purpose:
    This unit serves as the central integration and orchestration point for OpenAI/GenAI capabilities
    within a Delphi application. It manages prompt execution, asynchronous result streaming, session
    tracking, and connects to specialized execution engines and managers via dependency injection (IoC).

  Architecture and approach:
    - TOpenAIProvider acts as the main "facade/orchestrator" for AI interactions:
        - Delegates prompt execution to modular engines (e.g., TPromptExecutionEngine) via interfaces.
        - Exposes clear methods: Execute (streamed mode) and ExecuteSilently (batch/non-streamed mode).
        - Coordinates file/vector store management via dedicated managers, also resolved via IoC.
        - Oversees chat session management, persistent prompt storage, and UI displayer interactions.
    - Supporting engines (IPromptExecutionEngine, etc.) encapsulate the detailed async business logic:
        - Chaining of async requests, event handling, and promise resolution.
        - Handles retrieval of search, reasoning, and annotation results.
        - Supports alternative implementations through DI (tests, mocks, or custom workflows).
    - Dependency Injection (DI) is central:
        - All functional services (store, vector, execution, prompts) are interface-driven and swappable.

  Important:
    - The method InitializeProviderOpenAI *must* be called before instantiating or resolving dependencies
      for TOpenAIProvider or its related services. This ensures all required interfaces and their
      implementations are properly registered within the IoC container for the application's lifetime.

  Developer highlights:
    - Simple integration: just create a TOpenAIProvider, then call Execute or ExecuteSilently as needed.
    - Plug & play with execution engines and managers, configurable through IoC.
    - All file/vector stores and tracking modules are fully interface-based and decoupled.
    - Architecture is modular/testable/maintainable with easy extensibility and proper separation of concerns.

  Dependencies:
    - GenAI and GenAI.Types for OpenAI API contracts.
    - Async promise manager, IoC container, store managers, and session helpers.
    - Execution engines/handlers for specialized streaming and event processing logic.

  This unit is designed for robust, scalable, and best-practice-aligned modular architectures (SOLID/DIP/DI),
  making it easy to maintain, extend, and adapt to new OpenAI and GenAI usage scenarios or workflows.
*)

{$ENDREGION}

uses
  System.SysUtils, System.classes, GenAI, GenAI.Types, GenAI.Async.Promise, GenAI.Exceptions,
  Manager.Intf, Manager.IoC, Provider.OpenAI.FileStore,
  Provider.OpenAI.VectorStore, Provider.OpenAI.ExecutionEngine, Provider.InstructionManager;

type
  /// <summary>
  /// TOpenAIProvider is the central facade for integrating OpenAI/GenAI APIs into a Delphi application.
  /// It manages prompt submission, asynchronous result streaming, file/vector store management,
  /// and chat session tracking. The class exposes both streamed and non-streamed ("silent") prompt
  /// execution, delegating the core execution logic to injected execution engines.
  /// </summary>
  /// <remarks>
  /// TOpenAIProvider orchestrates business workflows by delegating technical operations
  /// (prompt execution, file uploads, vector linking, etc.) to dedicated service interfaces.
  /// It is designed for extensibility, testability, and modular replacement via dependency injection.
  /// </remarks>
  TOpenAIProvider = class(TInterfacedObject, IAIInteractionManager)
  private
    FClient: IGenAI;
    FFileStoreManager: IFileStoreManager;
    FVectorStoreManager: IVectorStoreManager;
    FPromptExecutionEngine: IPromptExecutionEngine;
    procedure InitializeProviderOpenAI(const GenAIClient: IGenAI);
    procedure HandleError(E: Exception);
    function HandleThenSilently(Value: TResponse): string;
    function HandleThenDeleteResponse(Value: TResponseDelete): string;
    function HandleThenDeleteFile(Value: TDeletion): string;
  protected
    /// <summary>
    /// Deletes a response from the OpenAI backend.
    /// </summary>
    /// <param name="ResponseId">
    /// Unique identifier of the response to be deleted.
    /// </param>
    /// <returns>
    /// A promise (TPromise&lt;string&gt;) that resolves to a confirmation message upon successful deletion,
    /// or is rejected if an error occurs.
    /// </returns>
    function DeleteResponse(ResponseId: string): TPromise<string>;

    /// <summary>
    /// Deletes the association between a file and a vector store.
    /// </summary>
    /// <param name="VectorStoreId">
    /// The identifier of the target vector store.
    /// </param>
    /// <param name="FileId">
    /// The identifier of the file to be unlinked from the vector store.
    /// </param>
    /// <returns>
    /// A promise (TPromise&lt;string&gt;) that resolves to a confirmation message if successful,
    /// or is rejected if an error occurs.
    /// </returns>
    function DeleteVectorStore(const VectorStoreId, FileId: string): TPromise<string>;

    /// <summary>
    /// Removes a vector store from the OpenAI backend.
    /// </summary>
    /// <param name="VectorStoreId">
    /// Unique identifier of the vector store to remove.
    /// </param>
    /// <returns>
    /// A promise (TPromise&lt;string&gt;) that resolves to a confirmation message upon successful removal,
    /// or is rejected if an error occurs.
    /// </returns>
    function RemoveVectorStore(const VectorStoreId: string): TPromise<string>;

    /// <summary>
    /// Deletes a file from the OpenAI backend file store.
    /// </summary>
    /// <param name="FileId">
    /// Identifier of the file to delete.
    /// </param>
    /// <returns>
    /// A promise (TPromise&lt;string&gt;) that resolves to a confirmation message upon successful deletion,
    /// or is rejected if an error occurs.
    /// </returns>
    function DeleteFile(FileId: string): TPromise<string>;

    /// <summary>
    /// Deletes a file that is linked to a vector store.
    /// </summary>
    /// <param name="VectorStoreId">
    /// The identifier of the vector store containing the file.
    /// </param>
    /// <param name="FileId">
    /// The identifier of the file to delete from the vector store.
    /// </param>
    /// <returns>
    /// A promise (TPromise&lt;string&gt;) that resolves to a confirmation message upon successful deletion,
    /// or is rejected if an error occurs.
    /// </returns>
    function DeleteVectorStoreFile(const VectorStoreId, FileId: string): TPromise<string>;
  public
    /// <summary>
    /// Executes a prompt using the default (streamed) execution engine.
    /// This method sends the prompt to OpenAI, streams back the AI response in real-time,
    /// and coordinates UI updates and session storage as configured.
    /// </summary>
    /// <param name="Prompt">
    /// The user's prompt or question to send to OpenAI.
    /// </param>
    /// <returns>
    /// A promise (TPromise&lt;string&gt;) which resolves to the AI response text,
    /// or is rejected upon error or cancellation.
    /// </returns>
    function Execute(const Prompt: string): TPromise<string>;

    /// <summary>
    /// Executes a prompt in "silent" mode, without real-time streaming or UI updates.
    /// This is intended for background queries, system tasks, or non-interactive batch scenarios.
    /// </summary>
    /// <param name="Prompt">
    /// The user's prompt to send to OpenAI.
    /// </param>
    /// <param name="Instructions">
    /// System instructions to provide context or modify the behavior of the AI assistant.
    /// </param>
    /// <returns>
    /// A promise (TPromise&lt;string&gt;) which resolves to the complete AI response text.
    /// </returns>
    function ExecuteSilently(const Prompt, Instructions: string): TPromise<string>;

    /// <summary>
    /// Ensures a file is present in OpenAI storage and is linked to a vector store.
    /// Handles upload if needed, vector store creation if required, and the association/link.
    /// </summary>
    /// <param name="FileName">
    /// Path to the local file to upload, if necessary.
    /// </param>
    /// <param name="FileId">
    /// The OpenAI file identifier (if known or empty if new upload is needed).
    /// </param>
    /// <param name="VectorStoreId">
    /// The vector store identifier (if known or empty to create a new one).
    /// </param>
    /// <returns>
    /// A promise (TPromise&lt;string&gt;) which resolves with concatenated VectorStoreId and FileId,
    /// or is rejected on error.
    /// </returns>
    function EnsureVectorStoreFileLinked(const FileName: string; const FileId: string;
      const VectorStoreId: string): TPromise<string>;

    constructor Create;
  end;

implementation

{ TOpenAIProvider }

function TOpenAIProvider.EnsureVectorStoreFileLinked(const FileName, FileId,
  VectorStoreId: string): TPromise<string>;
{$REGION 'limitation restricts to five files'}
(*
   A current limitation restricts processing to five files, due to constraints in the Delphi compiler.
   Specifically, the compiler is unable to perform self-invocation within recursively nested closures
   when using a promise-based mechanism.

   The ideal solution would involve implementing parallel file processing using promises, with structured
   output tracking. This enhancement is planned for a future release.

   The current implementation leads to a pyramid of doom due to deeply nested closures and lack of proper
   promise chaining. :(
*)
{$ENDREGION}
var
  LFileId: string;
  LVectorStoreId: string;
begin
  if not FileExists(FileName) then
    begin
      Result := TPromise<string>.Resolved('');
      Exit;
    end;

  LFileId := FileId;
  LVectorStoreId := VectorStoreId;

  Result :=
    {--- Checks if the file already exists on the remote FileStore. }
    FFileStoreManager.EnsureFileId(FileName, LFileId)
      .&Then<string>(
        function (Value: string): string
        begin
          Result := Value;
          {--- If not found, upload (via EnsureFileId); otherwise, keep the existing id. }
          LFileId := Value;
        end)
      .&Then(
        function (Value: string): TPromise<string>
        begin
          {--- Checks if the vector store exists (otherwise creates it). }
          Result := FVectorStoreManager.EnsureVectorStoreId(LVectorStoreId);
        end)
      .&Then<string>(
        function (Value: string): string
        begin
          Result := Value;
          {--- Retaining the id of the newly created or existing vector store. }
          LVectorStoreId := Value;
        end)
      .&Then(
        function (Value: string): TPromise<string>
        begin
          {--- Check that this file is linked to this vector store (create the link if necessary). }
          Result := FVectorStoreManager.EnsureVectorStoreFileId(LVectorStoreId, LFileId);
        end)
      .&Then(
        function (Value: string): TPromise<string>
        begin
          {--- Final resolution: the promise returns the two concatenated ids. }
          Result := TPromise<string>.Resolved(LVectorStoreId + #10 + LFileId);
        end)
      .&Catch(HandleError);
end;

constructor TOpenAIProvider.Create;
begin
  {$REGION  'Dev notes'}
  (*
    IMPORTANT: This class is designed to be used as a singleton.

    - Only one instance of TOpenAIProvider should exist in the application lifecycle.
    - All dependent services and interfaces (file store manager, vector store manager, prompt execution engine, etc.)
      are registered and resolved via the IoC container, which ensures that they are also managed as singletons.
    - Instantiating multiple TOpenAIProvider objects may result in conflicting registrations or
      unexpected behavior, as the underlying services are not intended for multi-instance use.
    - Before creating TOpenAIProvider, always ensure that InitializeProviderOpenAI has been called
      with a valid IGenAI client to properly register all required dependencies in the IoC.
    - The singleton pattern centralizes OpenAI API access, state, and resource coordination, improving
      stability, maintainability, and resource usage throughout the application.
  *)
  {$ENDREGION}
  inherited;
  FClient := IoC.Resolve<IGenAI>;
  InitializeProviderOpenAI(FClient);
  FFileStoreManager := IoC.Resolve<IFileStoreManager>;
  FVectorStoreManager := IoC.Resolve<IVectorStoreManager>;
  FPromptExecutionEngine := IoC.Resolve<IPromptExecutionEngine>;
end;

function TOpenAIProvider.DeleteFile(FileId: string): TPromise<string>;
begin
  Result := FClient.Files
    .AsyncAwaitDelete(FileId)
    .&Then<string>(HandleThenDeleteFile)
    .&Catch(HandleError);
end;

function TOpenAIProvider.DeleteResponse(ResponseId: string): TPromise<string>;
begin
  ResponseTracking.RemoveId(ResponseId);
  Result := FClient.Responses
    .AsyncAwaitDelete(ResponseId)
    .&Then<string>(HandleThenDeleteResponse)
    .&Catch(HandleError);
end;

function TOpenAIProvider.DeleteVectorStore(const VectorStoreId,
  FileId: string): TPromise<string>;
begin
  Result := FVectorStoreManager.DeleteVectorStoreFile(VectorStoreId, FileId);
end;

function TOpenAIProvider.DeleteVectorStoreFile(const VectorStoreId,
  FileId: string): TPromise<string>;
begin
  Result := FVectorStoreManager.DeleteVectorStoreFile(VectorStoreId, FileId)
end;

function TOpenAIProvider.Execute(const Prompt: string): TPromise<string>;
begin
  Result := FPromptExecutionEngine.Execute(Prompt);
end;

function TOpenAIProvider.ExecuteSilently(const Prompt, Instructions: string): TPromise<string>;
begin
  Result := FClient.Responses.AsyncAwaitCreate(
      procedure (Params: TResponsesParams)
      begin
         Params.Model(Settings.SearchModel);
         Params.Input(Prompt);
         Params.Instructions(Instructions);
         Params.Store(False);
         Params.Stream(False);
      end)
   .&Then<string>(HandleThenSilently)
   .&Catch(HandleError);
end;

procedure TOpenAIProvider.HandleError(E: Exception);
begin
  if not E.Message.StartsWith('error 404') then
    begin
      AlertService.ShowError(E.ClassName + ' : ' + E.Message);
    end;
end;

function TOpenAIProvider.HandleThenDeleteFile(Value: TDeletion): string;
begin
  Result := Value.Id + ' deleted';
end;

function TOpenAIProvider.HandleThenDeleteResponse(
  Value: TResponseDelete): string;
begin
  Result := Value.Id + ' deleted';
end;

function TOpenAIProvider.HandleThenSilently(Value: TResponse): string;
begin
  for var Item in Value.Output do
    for var SubItem in Item.Content do
      Result := Result + SubItem.Text;
end;

procedure TOpenAIProvider.InitializeProviderOpenAI(const GenAIClient: IGenAI);
begin
  IoC.RegisterType<ISystemPromptBuilder>(
    function: ISystemPromptBuilder
    begin
      Result := TSystemPromptBuilder.Create;
    end,
    TLifetime.Singleton
  );

  IoC.RegisterType<IPromptExecutionEngine>(
    function: IPromptExecutionEngine
    begin
      Result := TPromptExecutionEngine.Create(GenAIClient, IoC.Resolve<ISystemPromptBuilder>);
    end,
    TLifetime.Singleton
  );

  IoC.RegisterType<IFileStoreManager>(
    function: IFileStoreManager
    begin
      Result := TFileStoreManager.Create(GenAIClient);
    end,
    TLifetime.Singleton
  );

  IoC.RegisterType<IVectorStoreManager>(
    function: IVectorStoreManager
    begin
      Result := TVectorStoreManager.Create(GenAIClient);
    end,
    TLifetime.Singleton
  );
end;

function TOpenAIProvider.RemoveVectorStore(const VectorStoreId: string): TPromise<string>;
begin
  Result := FVectorStoreManager.DeleteVectorStore(VectorStoreId);
end;

end.

