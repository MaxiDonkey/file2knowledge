unit Helper.FileUploadID.Dictionary;

interface

{$REGION  'Dev notes : Helper.FileUploadID.Dictionary'}

(*
  Unit: Helper.FileUploadID.Dictionary

  Purpose:
    Provides robust and verifiable encapsulation for managing associations between filenames and FileUploadIds,
    which is essential for the effective and consistent handling of files linked to vector stores in the File2knowledgeAI project.

  Key roles and concerns:
    - Proactive duplicate detection (with a dedicated exception), ensuring data structure reliability both client- and server-side.
    - Atomic operations on typed dictionaries (add, remove, synchronized initialization), facilitating synchronization
      with OpenAI and the user interface.
    - Lays the groundwork for “snapshot” file comparison, enabling validation, persistence, and transactional rollback/restoration
      when UI-side modifications occur.

  Project context:
    - Designed for close use with Manager.FileUploadID.Controler and UI.VectorResourceEditor.VCL.
    - Documented and architected for quick onboarding by developers of all levels, while remaining extensible
      for enterprise needs (e.g., locking, async operations, rollback, etc.).
    - Extensible structure allowing for future validation logic or additional dictionary manipulation methods if necessary.
*)

{$ENDREGION}

uses
  System.Generics.Collections, System.SysUtils;

type
  EStringArrayDuplicateItem  = class(Exception);
  EFileUploadDictionaryMissing  = class(Exception);

  TArrayString = record
  public
    class procedure DuplicateExists(const Values: TArray<string>); static;
  end;

  /// <summary>
  /// Encapsulates a typed dictionary mapping file names to FileUploadIds,
  /// providing safe, atomic operations for file management within the File2knowledgeAI application.
  /// </summary>
  /// <remarks>
  /// Enables initialization, addition, removal, and retrieval of file-to-id associations,
  /// with built-in duplicate detection and validation for consistent client/server synchronization.
  /// Designed for integration with higher-level controllers and UI components managing file attachments
  /// and vector store operations.
  /// </remarks>
  TFileUploadIdDictionary = record
  private
    FDictionary: TDictionary<string, string>;
  public
    constructor Create(const ADictionary: TDictionary<string, string>);

    /// <summary>
    /// Initializes the dictionary contents from provided parallel arrays of file names and FileUploadIds.
    /// </summary>
    /// <param name="FileNames">The array of file names.</param>
    /// <param name="FileUploadIds">The array of corresponding FileUploadIds.</param>
    /// <returns>The updated TFileUploadIdDictionary instance.</returns>
    function Initialize(const FileNames: TArray<string>; const FileUploadIds: TArray<string>): TFileUploadIdDictionary;

    /// <summary>
    /// Adds or updates an entry in the dictionary, associating a file name with a FileUploadId.
    /// Optionally executes a callback after completion.
    /// </summary>
    /// <param name="FileName">The name of the file to add or update.</param>
    /// <param name="FileUploadId">The FileUploadId to associate with the file.</param>
    /// <param name="Proc">Optional callback procedure to execute after the operation.</param>
    /// <returns>The updated TFileUploadIdDictionary instance.</returns>
    function AddOrSetValue(const FileName: string; const FileUploadId: string; Proc: TProc = nil): TFileUploadIdDictionary;

    /// <summary>
    /// Removes an entry from the dictionary by file name.
    /// Optionally executes a callback after removal.
    /// </summary>
    /// <param name="FileName">The name of the file to remove.</param>
    /// <param name="Proc">Optional callback procedure to execute after the operation.</param>
    /// <returns>The updated TFileUploadIdDictionary instance.</returns>
    function Remove(const FileName: string; Proc: TProc = nil): TFileUploadIdDictionary;

    /// <summary>
    /// Retrieves the internal dictionary of file-to-FileUploadId mappings.
    /// </summary>
    /// <returns>The managed TDictionary instance.</returns>
    function Dictionary: TDictionary<string, string>;
  end;

  /// <summary>
  /// Provides comparison and synchronization logic between two dictionaries representing file-to-FileUploadId mappings,
  /// supporting transactional change detection, validation, and restoration in the File2knowledgeAI project.
  /// </summary>
  /// <remarks>
  /// Designed to facilitate snapshot/draft diffing, cleanup of lost or detached items, and callback-driven operations
  /// for deletion, validation, or rollback scenarios. Intended for internal use by controller and UI classes when
  /// managing file attachments or persisting changes to vector resource metadata.
  /// </remarks>
  TDictionaryContentComparison = record
  private
    FSnapshot: TDictionary<string, string>;
    FDraft: TDictionary<string, string>;
    procedure HandleLostItem(const FileName, FileUploadId: string; Proc: TProc<string, string>);
  public
    constructor Create(const ASnapshot, ADraft: TDictionary<string, string>);

    /// <summary>
    /// Iterates over the snapshot dictionary, calling the given procedure for each item that is missing or mismatched in the draft.
    /// </summary>
    /// <param name="Proc">A callback taking (FileName, FileUploadId) to execute for each lost or detached association.</param>
    /// <returns>The current TDictionaryContentComparison instance for chaining.</returns>
    function Apply(Proc: TProc<string, string>): TDictionaryContentComparison;

    /// <summary>
    /// Applies a visual or validation-oriented callback to allow UI components or external handlers to update in response to restoration.
    /// </summary>
    /// <param name="Proc">A callback procedure with no parameters to execute after restoration.</param>
    /// <returns>The current TDictionaryContentComparison instance for chaining.</returns>
    function Restore(Proc: TProc): TDictionaryContentComparison;

    /// <summary>
    /// Returns the validated draft dictionary, representing the current synchronized state after changes and checks.
    /// </summary>
    /// <returns>The draft dictionary containing file-to-FileUploadId mappings.</returns>
    function DraftValidated: TDictionary<string, string>;
  end;

implementation

{ TFileUploadIdDictionary }

function TFileUploadIdDictionary.AddOrSetValue(const FileName,
  FileUploadId: string; Proc: TProc): TFileUploadIdDictionary;
begin
  FDictionary.AddOrSetValue(FileName, FileUploadId);
  Result := Self;
  if Assigned(Proc) then
    Proc();
end;

constructor TFileUploadIdDictionary.Create(
  const ADictionary: TDictionary<string, string>);
begin
  if not Assigned(ADictionary) then
    raise EFileUploadDictionaryMissing .Create('ADictionary cannot be nil');
  Self.FDictionary := ADictionary;
end;

function TFileUploadIdDictionary.Remove(
  const FileName: string; Proc: TProc): TFileUploadIdDictionary;
begin
  FDictionary.Remove(FileName);
  Result := Self;
  if Assigned(Proc) then
    Proc();
end;

function TFileUploadIdDictionary.Dictionary: TDictionary<string, string>;
begin
  Result := FDictionary;
end;

function TFileUploadIdDictionary.Initialize(const FileNames,
  FileUploadIds: TArray<string>): TFileUploadIdDictionary;
{--- The FileNames and FileUploadIds lists have no duplicates because they are retrieved from OpenAI's DashBoard. }
begin
  {--- We still check for the existence of duplicates with an exception lebe detected }
  TArrayString.DuplicateExists(FileNames);
  TArrayString.DuplicateExists(FileUploadIds);

  FDictionary.Clear;

  {--- We guarantee a consistent list }
  var CountFile := Length(FileNames);
  var CountIds := Length(FileUploadIds);
  for var i := 0 to CountFile - 1 do
    begin
      if i < CountIds then
        AddOrSetValue(FileNames[i], FileUploadIds[i])
      else
        AddOrSetValue(FileNames[i], EmptyStr)
    end;
  Result := Self;
end;

{ TArrayString }

class procedure TArrayString.DuplicateExists(
  const Values: TArray<string>);
var
  Seen: TDictionary<string, Boolean>;
begin
  Seen := TDictionary<string, Boolean>.Create;
  try
    for var Value in Values do
      begin
        if Seen.ContainsKey(Value) then
          begin
            raise EStringArrayDuplicateItem .CreateFmt('Duplicate item : "%s"', [Value]);
          end
        else
          Seen.Add(Value, True);
      end;
  finally
    Seen.Free;
  end;
end;

{ TDictionaryContentComparison }

function TDictionaryContentComparison.Apply(
  Proc: TProc<string, string>): TDictionaryContentComparison;
begin
  for var Pair in FSnapshot do
    HandleLostItem(Pair.Key, Pair.Value, Proc);
  Result := Self;
end;

constructor TDictionaryContentComparison.Create(const ASnapshot,
  ADraft: TDictionary<string, string>);
begin
  FSnapshot := ASnapshot;
  FDraft := ADraft;
end;

function TDictionaryContentComparison.DraftValidated: TDictionary<string, string>;
begin
  Result := FDraft;
end;

procedure TDictionaryContentComparison.HandleLostItem(const FileName, FileUploadId: string;
  Proc: TProc<string, string>);
var
  Value: string;
begin
  if FDraft.TryGetValue(FileName, Value) then
    begin
      if Value.Trim.IsEmpty then
        FDraft[FileName] := FileUploadId
    end
  else
    begin
      {--- If FileUploadId is not empty, invoke the Proc method (fully asynchronous,
           fire-and-forget) to delete the corresponding file on the server. }
      if Assigned(Proc) then
        try
          Proc(FileName, FileUploadId);
        except
        end;
    end;
end;

function TDictionaryContentComparison.Restore(
  Proc: TProc): TDictionaryContentComparison;
begin
  Result := Self;
  {--- La métdode proc (fire-and forget) ne fera que mettre à jour un composant visuel }
  if Assigned(Proc) then
    Proc();
end;

end.
