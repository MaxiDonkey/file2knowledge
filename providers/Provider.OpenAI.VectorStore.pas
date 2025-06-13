unit Provider.OpenAI.VectorStore;

interface

{$REGION 'Dev notes : Provider.OpenAI.VectorStore'}

(*
  Unit: Provider.OpenAI.VectorStore

  Purpose:
    Manage creation, retrieval, and deletion of vector stores
    and their associated files via the GenAI client.

  Context & Architecture:
    - Encapsulates all access to the OpenAI VectorStore and VectorStoreFiles services.
    - Provides methods to:
        • Create a vector store or link a file to a vector store.
        • Check for existence of a vector store or linked file.
        • Delete a vector store or remove a file from a store.
    - Uses TPromise for orchestrating async calls and explicitly handles
      404 errors (not found) without throwing uncaught exceptions.
    - Error handling delegates to AlertService for centralized user feedback.

  Key Points:
    - Ensure* methods verify presence and create the resource if needed.
    - Retrieve* methods perform fine-grained lookup with non-blocking error handling.
    - Promises resolve to an empty string when an item is missing, allowing flow continuity.
    - Adheres to SRP: this manager focuses solely on vector access and delegates UI/alerting to AlertService.

  External Dependencies:
    - GenAI (IGenAI)
    - GenAI.Types
    - GenAI.Async.Promise
    - Manager.Intf (IVectorStoreManager)

  Usage:
    Resolve via IoC (singleton) and invoke Ensure*, Retrieve*, Create*, or Delete*
    methods as appropriate. No direct API calls should occur outside this manager.
*)

{$ENDREGION}

uses
  System.SysUtils, GenAI, GenAI.Types, Manager.Intf, GenAI.Async.Promise;

type
  /// <summary>
  /// Manages the lifecycle and file associations of vector stores in the OpenAI backend.
  /// </summary>
  /// <remarks>
  /// Encapsulates creation, retrieval, linking, and deletion of vector stores and their associated files
  /// via the GenAI client. Uses promise-based asynchronous calls to handle API interactions, converting
  /// 404 (not found) errors into empty results for callers to decide on resource creation.
  /// Errors other than 404 are forwarded to <see cref="HandleError"/> for centralized reporting.
  /// Designed as a singleton service resolved through dependency injection, adhering to SOLID principles
  /// for modularity and testability.
  /// </remarks>
  TVectorStoreManager = class(TInterfacedObject, IVectorStoreManager)
  private
    FClient: IGenAI;
    procedure HandleError(E: Exception);
    function HandleThenVectorStore(Value: TVectorStore): string;
    function HandleThenVectorStoreFile(Value: TVectorStoreFile): string;
    function HandleThenDeleteVectorStoreFile(Value: TDeletion): string;
  public
    {--- Vector store }

    /// <summary>
    /// Asynchronously retrieves the ID of the specified vector store.
    /// </summary>
    /// <param name="Value">
    /// The ID of the vector store to look up. If this string is empty, the method will
    /// still resolve gracefully without creating a new store.
    /// </param>
    /// <returns>
    /// A <c>TPromise&lt;string&gt;</c> which resolves to the existing vector store ID,
    /// or to an empty string if the store does not exist (including 404 errors) or if
    /// the input value is empty.
    /// </returns>
    /// <remarks>
    /// Uses a custom promise wrapper to intercept 404 errors and convert them into
    /// a successful resolution with an empty string, allowing callers to decide
    /// whether to create a new vector store.
    /// </remarks>
    function RetrieveVectorStoreId(const Value: string): TPromise<string>;

    /// <summary>
    /// Creates a new vector store in the OpenAI backend.
    /// </summary>
    /// <returns>
    /// A <c>TPromise&lt;string&gt;</c> that resolves to the identifier of the newly created
    /// vector store.
    /// </returns>
    /// <remarks>
    /// Invokes the GenAI client's vector store creation API with default parameters.
    /// Any errors are caught and forwarded to <see cref="HandleError"/> for centralized handling.
    /// </remarks>
    function CreateVectorStore: TPromise<string>;

    /// <summary>
    /// Ensures that a valid vector store exists for the given identifier.
    /// </summary>
    /// <param name="VectorStoreId">
    /// The identifier of an existing vector store.
    /// If this string is empty or does not correspond to an existing store, a new one will be created.
    /// </param>
    /// <returns>
    /// A <c>TPromise&lt;string&gt;</c> which resolves to the identifier of the confirmed or newly created vector store.
    /// </returns>
    /// <remarks>
    /// - If <paramref name="VectorStoreId"/> is empty, invokes <see cref="CreateVectorStore"/> immediately.
    /// - Otherwise, attempts to retrieve the store; on 404 (not found) or empty result, falls back to creation.
    /// - Any other errors are propagated to <see cref="HandleError"/> for centralized handling.
    /// </remarks>
    function EnsureVectorStoreId(const VectorStoreId: string): TPromise<string>;

    {--- Vector store file }

    /// <summary>
    /// Asynchronously retrieves the linkage ID for a file within a specific vector store.
    /// </summary>
    /// <param name="VectorStoreId">
    /// The identifier of the vector store to query.
    /// </param>
    /// <param name="FileId">
    /// The identifier of the file whose association you want to retrieve.
    /// </param>
    /// <returns>
    /// A <c>TPromise&lt;string&gt;</c> that resolves to the vector‐store‐file association ID
    /// if found, or to an empty string if the association does not exist (including 404 errors).
    /// </returns>
    /// <remarks>
    /// <para>
    /// - Uses a custom promise wrapper to catch 404 (not found) errors and convert them into
    ///   a successful resolution with an empty string, enabling callers to decide whether
    ///   to create the association.
    /// </para>
    /// <para>
    /// - Other errors are propagated to <see cref="HandleError"/> for centralized handling.
    /// </para>
    /// </remarks>
    function RetrieveVectorStoreFileId(const VectorStoreId: string; const FileId: string): TPromise<string>;

    /// <summary>
    /// Creates a new file association within the specified vector store.
    /// </summary>
    /// <param name="VectorStoreId">
    /// The identifier of the vector store to which the file will be linked.
    /// </param>
    /// <param name="FileId">
    /// The identifier of the file to link into the vector store.
    /// </param>
    /// <returns>
    /// A <c>TPromise&lt;string&gt;</c> that resolves to the identifier of the newly created
    /// vector‐store‐file link.
    /// </returns>
    /// <remarks>
    /// <para>
    /// - Invokes the GenAI client's VectorStoreFiles create API for the given store and file IDs.
    /// </para>
    /// <para>
    /// - On success, extracts and returns the association ID via <see cref="HandleThenVectorStoreFile"/>.
    /// </para>
    /// <para>
    /// - Any errors (other than 404) are forwarded to <see cref="HandleError"/> for centralized handling.
    /// </para>
    /// </remarks>
    function CreateVectorStoreFile(const VectorStoreId: string; const FileId: string): TPromise<string>;

    /// <summary>
    /// Ensures that a link between the specified file and vector store exists.
    /// </summary>
    /// <param name="VectorStoreId">
    /// The identifier of the target vector store.
    /// </param>
    /// <param name="FileId">
    /// The identifier of the file to associate with the vector store.
    /// </param>
    /// <returns>
    /// A <c>TPromise&lt;string&gt;</c> which resolves to:
    /// <para>
    /// - the existing association ID if the link is already present, or
    /// </para>
    /// <para>
    /// - a newly created association ID if the link was missing.
    /// </para>
    /// </returns>
    /// <remarks>
    /// <para>
    /// - First calls <see cref="RetrieveVectorStoreFileId"/> to check for an existing link.
    /// </para>
    /// <para>
    /// - If no association is found (empty result or 404), invokes <see cref="CreateVectorStoreFile"/>.
    /// </para>
    /// <para>
    /// - Errors other than 404 are propagated to <see cref="HandleError"/> for centralized handling.
    /// </para>
    /// </remarks>
    function EnsureVectorStoreFileId(const VectorStoreId, FileId: string): TPromise<string>;

    /// <summary>
    /// Asynchronously deletes the association between a file and the specified vector store.
    /// </summary>
    /// <param name="VectorStoreId">
    /// The identifier of the vector store from which the file association will be removed.
    /// </param>
    /// <param name="FileId">
    /// The identifier of the file to unlink from the vector store.
    /// </param>
    /// <returns>
    /// A <c>TPromise&lt;string&gt;</c> that resolves to a confirmation message (typically "deleted")
    /// when the association has been removed successfully.
    /// </returns>
    /// <remarks>
    /// <para>
    /// - Invokes the GenAI client's VectorStoreFiles delete API via <c>AsyncAwaitDelete</c>.
    /// </para>
    /// <para>
    /// - On success, the association ID is passed to <see cref="HandleThenDeleteVectorStoreFile"/>
    ///   to format the confirmation message.
    /// </para>
    /// <para>
    /// - Any exceptions (other than 404) are caught and forwarded to <see cref="HandleError"/>
    ///   for centralized error reporting.
    /// </para>
    /// </remarks>
    function DeleteVectorStoreFile(const VectorStoreId, FileId: string): TPromise<string>;

    /// <summary>
    /// Asynchronously deletes the specified vector store from the OpenAI backend.
    /// </summary>
    /// <param name="VectorStoreId">
    /// The identifier of the vector store to remove.
    /// </param>
    /// <returns>
    /// A <c>TPromise&lt;string&gt;</c> that resolves to a confirmation message (typically "deleted")
    /// when the vector store has been removed successfully.
    /// </returns>
    /// <remarks>
    /// <para>
    /// - Invokes the GenAI client's VectorStore delete API via <c>AsyncAwaitDelete</c>.
    /// </para>
    /// <para>
    /// - On success, matches the deleted store ID and returns "deleted".
    /// </para>
    /// <para>
    /// - Any exceptions (other than 404) are caught and forwarded to <see cref="HandleError"/>
    ///   for centralized error reporting.
    /// </para>
    /// </remarks>
    function DeleteVectorStore(const VectorStoreId: string): TPromise<string>;

    constructor Create(const GenAIClient: IGenAI);
  end;

implementation

{ TVectorStoreManager }

constructor TVectorStoreManager.Create(const GenAIClient: IGenAI);
begin
  inherited Create;
  FClient := GenAIClient;
end;

function TVectorStoreManager.CreateVectorStore: TPromise<string>;
begin
  Result := FClient.VectorStore
    .AsyncAwaitCreate(
        procedure (Params: TVectorStoreCreateParams)
        begin
          Params.Name('Helper for wrapper Assistant');
        end)
    .&Then<string>(HandleThenVectorStore)
    .&Catch(HandleError);
end;

function TVectorStoreManager.CreateVectorStoreFile(const VectorStoreId,
  FileId: string): TPromise<string>;
begin
  Result := FClient.VectorStoreFiles
    .AsyncAwaitCreate(
        VectorStoreId,
        procedure (Params: TVectorStoreFilesCreateParams) begin
          Params.FileId(FileId);
        end)
    .&Then<string>(HandleThenVectorStoreFile)
    .&Catch(HandleError);
end;

function TVectorStoreManager.DeleteVectorStore(
  const VectorStoreId: string): TPromise<string>;
begin
  Result := FClient.VectorStore
    .AsyncAwaitDelete(VectorStoreId)
    .&Then<string>(
      function (Value: TDeletion): string
      begin
        if VectorStoreId = Value.Id then
          Result := 'deleted';
      end)
    .&Catch(HandleError);
end;

function TVectorStoreManager.DeleteVectorStoreFile(const VectorStoreId,
  FileId: string): TPromise<string>;
begin
  Result := FClient.VectorStoreFiles
    .AsyncAwaitDelete(VectorStoreId, FileId)
    .&Then<string>(HandleThenDeleteVectorStoreFile)
    .&Catch(HandleError);
end;

function TVectorStoreManager.EnsureVectorStoreFileId(const VectorStoreId,
  FileId: string): TPromise<string>;
begin
  {--- Ensure the presence of the vectorStoreId and the FileId in the vector store file. }
  Result := RetrieveVectorStoreFileId(VectorStoreId, FileId)
    .&Then(
      function (Value: string): TPromise<string>
      begin
        if Value.Trim.IsEmpty then
          Result := CreateVectorStoreFile(VectorStoreId, FileId)
        else
          {--- The Id exists, so do nothing }
          Result := TPromise<string>.Resolved('exists');
      end)
end;

function TVectorStoreManager.EnsureVectorStoreId(
  const VectorStoreId: string): TPromise<string>;
begin
  if VectorStoreId.Trim.IsEmpty then
    Result := CreateVectorStore
  else
    {--- Ensure the presence of the Id in the vector store. }
    Result := RetrieveVectorStoreId(VectorStoreId)
      .&Then(
        function (Value: string): TPromise<string>
        begin
          {--- The Id does not exist. Create the Id and obtain its ID. }
          if Value.Trim.IsEmpty then
            Result := CreateVectorStore
          else
            {--- The Id exists, so do nothing }
            Result := TPromise<string>.Resolved(Value);
        end);
end;

procedure TVectorStoreManager.HandleError(E: Exception);
begin
  AlertService.ShowError(E.Message);
end;

function TVectorStoreManager.HandleThenDeleteVectorStoreFile(
  Value: TDeletion): string;
begin
  Result := 'deleted';
end;

function TVectorStoreManager.HandleThenVectorStore(Value: TVectorStore): string;
begin
  Result := Value.Id;
end;

function TVectorStoreManager.HandleThenVectorStoreFile(
  Value: TVectorStoreFile): string;
begin
  Result := Value.Id;
end;

function TVectorStoreManager.RetrieveVectorStoreFileId(const VectorStoreId,
  FileId: string): TPromise<string>;
{$REGION  'Dev notes'}
(*  Notes :
    1. We are not using the AsyncAwaitRetrieve method here because we want to define an
       onError handler that allows the promise to be resolved explicitly.
*)
{$ENDREGION}
begin
  Result := TPromise<string>.Create(
    procedure(Resolve: TProc<string>; Reject: TProc<Exception>)
    begin
      FClient.VectorStoreFiles.AsynRetrieve(
        VectorStoreId,
        FileId,
        function : TAsynVectorStoreFile
        begin
          Result.OnSuccess :=
            procedure (Sender: TObject; VectorStoreFile: TVectorStoreFile)
            begin
              Resolve(VectorStoreFile.Id);
            end;

          Result.OnError :=
            procedure (Sender: TObject; Error: string)
            begin
              {$REGION  'Dev notes'}
              (* 1. The promise is still resolved, even if no ID is provided or
                    if the vector store file cannot be found, since a new vector
                    store will be created in the next step.
                 2. error 404: when vector store file not found.
              *)
              {$ENDREGION}
              if Error.StartsWith('error 404') then
                Resolve(EmptyStr)
              else
                Reject(Exception.Create(Error));
            end;
        end);
    end);
end;

function TVectorStoreManager.RetrieveVectorStoreId(
  const Value: string): TPromise<string>;
{$REGION  'Dev notes'}
(*  Notes :
    1. Empty string handling (value = '') is retained, even though the EnsureVectorStoreId
       method excludes them to improve processing efficiency.
    2. We are not using the AsyncAwaitRetrieve method here because we want to define an
       onError handler that allows the promise to be resolved explicitly.
*)
{$ENDREGION}
begin
  var EmptyValue := Value.Trim.IsEmpty;
  Result := TPromise<string>.Create(
    procedure(Resolve: TProc<string>; Reject: TProc<Exception>)
    begin
      FClient.VectorStore.AsynRetrieve(Value,
        function : TAsynVectorStore
        begin
          Result.OnSuccess :=
            procedure (Sender: TObject; Vector: TVectorStore)
            begin
              Resolve(Vector.Id);
            end;

          Result.OnError :=
            procedure (Sender: TObject; Error: string)
            begin
              {$REGION  'Dev notes'}
              (* 1. The promise is still resolved, even if no ID is provided or
                    if the vector store cannot be found, since a new vector store
                    will be created in the next step.
                 2. error 404: when vector store not found.
              *)
              {$ENDREGION}
              if EmptyValue or Error.StartsWith('error 404') then
                Resolve(EmptyStr)
              else
                Reject(Exception.Create(Error));
            end;
        end);
    end);
end;

end.
