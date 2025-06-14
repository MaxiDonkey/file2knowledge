unit Manager.FileUploadID.Controler;

interface

{$REGION  'Dev notes : UI.VectorResourceManager.VCL'}

(*
  Unit: Manager.FileUploadID.Controler

  Purpose:
    Acts as the central manager for all file-to-FileUploadId mappings in the File2knowledgeAI application, coordinating
    UI actions and business logic with persistent vector resource data and server APIs.

  Key roles and responsibilities:
    - Orchestrates the life cycle of file attachments: adding, deleting, and validating synchronization between
      UI state, client-side drafts, and OpenAI-managed vector stores.
    - Maintains reliable “snapshot” and “draft” dictionaries, enabling transactional updates, rollback, and consistency checks.
    - Provides a single point of coordination between the UI.VectorResourceEditor.VCL and lower-level helper
      units for file and dictionary operations.

  Project context:
    - Designed for integration with Helper.FileUploadID.Dictionary and the main vector resource editor UI, ensuring
      maintainability and transparency during prototyping and demos.
    - Clearly documented and organized to support direct onboarding of developers at any level, with clear upgrade paths for
      scaling to more advanced enterprise needs (transaction management, async operations, etc.).
    - Easily extendable for further functionalities such as multi-user synchronization, batch operations, or enhanced
      error handling.
*)

{$ENDREGION}

uses
  System.SysUtils, System.Generics.Collections, Model.VectorResource, Helper.FileUploadID.Dictionary,
  Manager.Intf;

type
  /// <summary>
  /// Central controller for managing associations between file names and FileUploadIds
  /// within the File2knowledgeAI project.
  /// </summary>
  /// <remarks>
  /// This class coordinates file attachment management and state transitions, enabling
  /// the UI to add, remove, and validate files associated with vector resources.
  /// It maintains separate “snapshot” and “draft” dictionaries for transactional safety,
  /// integrates with helper units for dictionary operations, and ensures consistency
  /// between client- and server-side data.
  /// <para>
  /// * Intended for use with Helper.FileUploadID.Dictionary and UI.VectorResourceEditor.VCL.
  /// </para>
  /// </remarks>
  TFileUploadIdController = class(TInterfacedObject, IFileUploadIdController)
  private
    FSnapShot: TDictionary<string, string>;
    FDraft: TDictionary<string, string>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>
    /// Initializes both the snapshot and draft dictionaries with current file names and associated FileUploadIds.
    /// </summary>
    /// <remarks>
    /// Should be called whenever there is a need to synchronize the controller's state with
    /// the persistent data store or to reset after external changes.
    /// </remarks>
    procedure InitDictionaries;

    /// <summary>
    /// Persists the changes made to file and FileUploadId mappings by comparing the snapshot and draft dictionaries.
    /// </summary>
    /// <remarks>
    /// This method applies additions and deletions, and updates the persistent vector resource data accordingly.
    /// May also trigger removal of files from OpenAI vector stores as appropriate.
    /// </remarks>
    procedure SaveChanges;

    /// <summary>
    /// Adds a new file to the draft dictionary, associating it with an (optional) FileUploadId.
    /// </summary>
    /// <param name="FileName">The name of the file to add.</param>
    /// <param name="Proc">A callback procedure to execute after addition (can be <c>nil</c>).</param>
    procedure AddFile(const FileName: string; Proc: TProc);

    /// <summary>
    /// Removes a file from the draft dictionary.
    /// </summary>
    /// <param name="FileName">The name of the file to remove.</param>
    /// <param name="Proc">A callback procedure to execute after removal (can be <c>nil</c>).</param>
    procedure DeleteFile(const FileName: string; Proc: TProc);

    /// <summary>
    /// Gets the number of files currently in the draft dictionary.
    /// </summary>
    /// <returns>The count of files being tracked in the draft state.</returns>
    function DraftCount: Integer;
  end;

implementation

{ TFileUploadIdController }

procedure TFileUploadIdController.AddFile(const FileName: string;
  Proc: TProc);
begin
  FDraft := TFileUploadIdDictionary
    .Create(FDraft)
    .AddOrSetValue(FileName, EmptyStr, Proc)
    .Dictionary;
end;

constructor TFileUploadIdController.Create;
begin
  inherited Create;
  FSnapShot := TDictionary<string, string>.Create;
  FDraft := TDictionary<string, string>.Create;
end;

procedure TFileUploadIdController.DeleteFile(const FileName: string;
  Proc: TProc);
begin
  FDraft := TFileUploadIdDictionary
    .Create(FDraft)
    .Remove(FileName, Proc)
    .Dictionary;
end;

destructor TFileUploadIdController.Destroy;
begin
  FSnapShot.Free;
  FDraft.Free;
  inherited;
end;

function TFileUploadIdController.DraftCount: Integer;
begin
  Result := FDraft.Count;
end;

procedure TFileUploadIdController.InitDictionaries;
begin
  FSnapShot := TFileUploadIdDictionary
    .Create(FSnapShot)
    .Initialize(FileStoreManager.Files, FileStoreManager.FileUploadIds)
    .Dictionary;

  FDraft := TFileUploadIdDictionary
    .Create(FDraft)
    .Initialize(FileStoreManager.Files, FileStoreManager.FileUploadIds)
    .Dictionary;
end;

procedure TFileUploadIdController.SaveChanges;
begin
  var Resources := TVectorResourceList(FileStoreManager.Resources);
  var ItemIndex := FileStoreManager.ItemIndex;
  FDraft := TDictionaryContentComparison
    .Create(FSnapShot, FDraft)
    .Apply(
      procedure (FileName: string; FileUploadId: string)
      begin
        if not FileUploadId.IsEmpty then
        begin
          OpenAI.DeleteVectorStoreFile(Resources.Data[ItemIndex].VectorStoreId, FileUploadId);
          OpenAI.DeleteFile(FileUploadId);
        end;
      end)
    .DraftValidated;

  Resources.Data[ItemIndex].Files := FDraft.Keys.ToArray;
  Resources.Data[ItemIndex].FileUploadId := FDraft.Values.ToArray;
end;

end.
