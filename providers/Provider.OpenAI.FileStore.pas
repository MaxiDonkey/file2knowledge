unit Provider.OpenAI.FileStore;

interface

{$REGION 'dev notes : Provider.OpenAI.FileStore'}

(*
  Unit: Provider.OpenAI.FileStore

  Purpose:
    Handle uploading, existence-checking, and ID management of files
    in OpenAI’s file store via the GenAI client.

  Context & Architecture:
    - Wraps access to the OpenAI Files API.
    - Provides methods to:
        • Check if a specific file (by name and ID) is already uploaded.
        • Upload a file asynchronously if it’s not present.
        • Ensure that a file ID is available for a given filename.
    - Uses TPromise for asynchronous workflows and clean chaining of operations.
    - Centralized error handling via AlertService to report exceptions.

  Key Points:
    - CheckFileUploaded lists user_data files and matches on filename & ID.
    - UploadFileAsync performs the actual upload with the correct purpose.
    - EnsureFileId combines check + upload in a single fluent promise chain.
    - Promises bubble errors to HandleError, preventing unhandled exceptions.

  External Dependencies:
    - GenAI (IGenAI)
    - GenAI.Types
    - GenAI.Async.Promise
    - Manager.Intf (IFileStoreManager)
    - AlertService for UI feedback

  Usage:
    Register via IoC as a singleton, then call:
      • EnsureFileId to get or create the file ID.
      • CheckFileUploaded to verify presence without uploading.
      • UploadFileAsync to force a new upload.
    No direct API calls should be made outside this manager.
*)

{$ENDREGION}

uses
  System.SysUtils, GenAI, GenAI.Types, Manager.Intf, GenAI.Async.Promise;

type
  /// <summary>
  /// Manages uploading, existence checks, and identifier resolution for files
  /// in the OpenAI file store via the GenAI client.
  /// </summary>
  /// <remarks>
  /// Encapsulates all interactions with the OpenAI Files API, providing asynchronous
  /// methods to list existing user_data files, upload new files, and ensure that
  /// a valid remote file ID is available for a given local filename.
  /// Uses TPromise for fluent chaining of operations and forwards non-404 errors
  /// to <see cref="HandleError"/> for centralized reporting.
  /// Designed to be registered as a singleton service via IoC, adhering to SOLID principles
  /// for testability and modularity.
  /// </remarks>
  TFileStoreManager = class(TInterfacedObject, IFileStoreManager)
  private
    FClient: IGenAI;
    procedure HandleError(E: Exception);
    function HandleThenUploadFile(Value: TFile): string;
  public
    /// <summary>
    /// Asynchronously checks whether a file with the specified name and identifier
    /// already exists in the OpenAI file store.
    /// </summary>
    /// <param name="FileName">
    /// The full path or name of the local file to verify in the remote store.
    /// Only the filename portion is compared against stored entries.
    /// </param>
    /// <param name="Id">
    /// The expected remote file identifier. If a stored entry matches both the filename
    /// and this ID, the method resolves to this ID.
    /// </param>
    /// <returns>
    /// A <c>TPromise&lt;string&gt;</c> that resolves to the matching file ID if found,
    /// or to an empty string if no matching upload entry exists.
    /// </returns>
    /// <remarks>
    /// <para>
    /// - Retrieves the list of user_data files via <c>AsyncAwaitList</c> on the GenAI client.
    /// </para>
    /// <para>
    /// - Performs a case-insensitive filename match using <c>ExtractFileName</c>.
    /// </para>
    /// <para>
    /// - Any exceptions are forwarded to <see cref="HandleError"/> for centralized reporting.
    /// </para>
    /// </remarks>
    function CheckFileUploaded(const FileName, Id: string): TPromise<string>;

    /// <summary>
    /// Asynchronously uploads the specified local file to the OpenAI file store.
    /// </summary>
    /// <param name="FileName">
    /// The full path or name of the local file to upload.
    /// </param>
    /// <returns>
    /// A <c>TPromise&lt;string&gt;</c> that resolves to the identifier of the newly uploaded file.
    /// </returns>
    /// <remarks>
    /// <para>
    /// - Invokes the GenAI client's <c>AsyncAwaitUpload</c> method with purpose set to "user_data".
    /// </para>
    /// <para>
    /// - On success, extracts and returns the <c>Id</c> from the <c>TFile</c> response.
    /// </para>
    /// <para>
    /// - Any exceptions during upload are forwarded to <see cref="HandleError"/> for centralized reporting.
    /// </para>
    /// </remarks>
    function UploadFileAsync(const FileName: string): TPromise<string>;

    /// <summary>
    /// Ensures that the specified file is present in the OpenAI file store.
    /// </summary>
    /// <param name="FileName">
    /// The full path or name of the local file to verify or upload.
    /// </param>
    /// <param name="Id">
    /// The known remote file identifier, if any.
    /// If this is empty or no matching entry is found, the file will be uploaded.
    /// </param>
    /// <returns>
    /// A <c>TPromise&lt;string&gt;</c> that resolves to the existing or newly created file ID.
    /// </returns>
    /// <remarks>
    /// <para>
    /// - Internally calls <see cref="CheckFileUploaded"/> to look for an existing upload.
    /// </para>
    /// <para>
    /// - If no match is found, invokes <see cref="UploadFileAsync"/> to upload the file.
    /// </para>
    /// <para>
    /// - Any errors are caught and forwarded to <see cref="HandleError"/> for centralized reporting.
    /// </para>
    /// </remarks>
    function EnsureFileId(const FileName: string; const Id: string): TPromise<string>;

    constructor Create(const GenAIClient: IGenAI);
  end;

implementation

{ TFileStoreManager }

function TFileStoreManager.CheckFileUploaded(const FileName,
  Id: string): TPromise<string>;
begin
  Result := FClient.Files
    .AsyncAwaitList
    .&Then<string>(
      function (Value: TFiles): string
      begin
        Result := EmptyStr;
        for var Item in Value.Data do
          if (Item.Purpose = TFilesPurpose.user_data) and
             SameText(Item.Filename, ExtractFileName(FileName)) and
             (Item.Id = Id) then
            begin
              Exit(Id)
            end;
      end)
    .&Catch(HandleError);
end;

constructor TFileStoreManager.Create(const GenAIClient: IGenAI);
begin
  inherited Create;
  FClient := GenAIClient;
end;

function TFileStoreManager.EnsureFileId(const FileName,
  Id: string): TPromise<string>;
begin
  {--- Ensure the presence of the specified file on the FTP server. }
  Result := CheckFileUploaded(FileName, Id)
    .&Then(
      function(Value: string): TPromise<string>
      begin
        if Value.IsEmpty then
          {--- The file does not exist. Upload the file and obtain its ID. }
          Exit(UploadFileAsync(FileName))
        else
          {--- The file exists, so do nothing }
          Exit(TPromise<string>.Resolved(Value));
      end);
end;

procedure TFileStoreManager.HandleError(E: Exception);
begin
  AlertService.ShowError(E.Message);
end;

function TFileStoreManager.HandleThenUploadFile(Value: TFile): string;
begin
  Result := Value.Id;
end;

function TFileStoreManager.UploadFileAsync(
  const FileName: string): TPromise<string>;
begin
  Result := FClient.Files
    .AsyncAwaitUpload(
        procedure (Params: TFileUploadParams)
        begin
          Params.&File(FileName);
          Params.Purpose('user_data');
        end)
    .&Then<string>(HandleThenUploadFile)
    .&Catch(HandleError);
end;

end.
