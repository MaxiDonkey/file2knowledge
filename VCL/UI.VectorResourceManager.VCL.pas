unit UI.VectorResourceManager.VCL;

interface

{$REGION  'Dev notes : UI.VectorResourceManager.VCL'}

(*
  Unit: UI.VectorResourceManager.VCL

  Purpose:
    This unit provides a VCL-specific vector resource manager for handling lists of AI resource wrappers
    (such as GenAI, MistralAI, Anthropic, Gemini, etc.). It links data management and persistent storage
    with the creation and interaction of corresponding visual container panels in a VCL application.
    The goal is to streamline the management, visualization, and selection of vector resources, especially
    for demoing or integrating various AI wrapper endpoints in a user interface.

  Technical details:
    - Defines TVectorResourceCore for generic resource list management and TVectorResourceVCL for VCL-adapted presentation.
    - Supplies a factory method for populating UI containers (TContainer) with resource data (name, description, image, etc.),
      supporting dynamic integration into scrollable or list-based visual structures.
    - Implements fluent method chaining for container property assignment (name, image, index, selection callback, etc.).
    - Integrates with persistent JSON storage: loads and saves resource information transparently.
    - Includes methods for easily attaching, updating, selecting, and reloading resource panels, and
      for synchronizing UI state with underlying resource data.

  Dependencies:
    - Requires Model.VectorResource for the underlying data model of resources.
    - Uses UI.Container.VCL for the visual container/panel representation in VCL.
    - Depends on REST.Json and System.JSON for JSON serialization/deserialization.
    - Uses System.IOUtils, System.Classes, System.SysUtils for file and utility operations.
    - Integrates with Manager.Intf for interfacing with the app's broader file store management.

  Quick start for developers:
    - Instantiate a TVectorResourceVCL for automatic loading of resource data and convenient VCL-specific methods.
    - Use the AttachTo method to bind the resource items to a VCL control (like a TScrollBox), with optional
      selection callback.
    - Access and manipulate core data and selection via the provided properties and methods;
      persistence is handled internally.
    - Customize the list of resources, images, and descriptions using the Initialize method or via parameterized
      construction, per your extension needs.

  This unit is designed to make AI-related resource integration and visualization straightforward in Delphi
  VCL applications, prioritizing clarity, maintainability, and ease of adding or updating resource wrappers.
*)

{$ENDREGION}

uses
  System.SysUtils, System.Classes, System.JSON, REST.Json, System.IOUtils, System.Threading,
  Manager.Intf, GenAI.Async.Promise, Model.VectorResource, UI.Container.VCL;

type
  EFileCountNull = class(Exception);

  TVectorResourceCore = class(TInterfacedObject)
  private
    FVectorResourceList: TVectorResourceList;
    function GetData(Index: Integer): TVectorResourceItem;
  protected
    procedure Initialize; virtual; abstract;
  public
    procedure Clear;
    property Data[Index: Integer]: TVectorResourceItem read GetData;
    constructor Create;
    destructor Destroy; override;
  end;

  /// <summary>
  /// Provides a VCL-specific vector resource manager to handle and visualize lists of AI resource wrappers,
  /// including GenAI, MistralAI, Anthropic, Gemini, and others. This class links data management and
  /// persistent storage with the creation and interaction of corresponding visual container panels in a VCL
  /// (Visual Component Library) application. TVectorResourceVCL streamlines management, visualization, and
  /// selection of vector resources, making it ideal for integrating and showcasing diverse AI wrapper
  /// endpoints.
  /// </summary>
  /// <remarks>
  /// <para>
  /// - TVectorResourceVCL inherits from TVectorResourceCore to extend generic resource list features and
  /// implements IAppFileStoreManager for integrated persistent file store handling.
  /// </para>
  /// <para>
  /// - Core features include dynamic population of VCL container controls (such as TContainer) with resource
  /// data and images, support for method chaining on UI assignments, full transparency for JSON-based
  /// persistent storage, and efficient methods to attach, update, select, and reload resource panels while
  /// keeping UI state synchronized.
  /// </para>
  /// <para>
  /// - TVectorResourceVCL depends on Model.VectorResource for data representation, UI.Container.VCL for visual
  /// integration, REST.Json and System.JSON for JSON serialization, System.IOUtils and System.Classes for file
  /// operations, and Manager.Intf for broader file store use.
  /// </para>
  /// <para>
  /// - Typical usage involves instantiating TVectorResourceVCL to automatically load data from storage, binding
  /// visual resource items to a VCL control (such as TScrollBox) with an optional selection callback, and
  /// invoking provided methods to manipulate resource data, visuals, and persistence. Initialization
  /// customizes the resource list, images, and descriptions according to application context.
  /// </para>
  /// </remarks>
  TVectorResourceVCL = class(TVectorResourceCore, IAppFileStoreManager)
  private
    FVectorStore: string;
    TFileUploadIdTemp: TArray<string>;
    function GetItemIndex: Integer;
    procedure SetItemIndex(const Value: Integer);
    function GetName: string;
    procedure SetName(const Value: string);
    function GetVectorStore: string;
    procedure SetVectorStore(const Value: string);
    function GetDescription: string;
    function GetGitHub: string;
    function GetGetit: string;
    function GetFiles: TArray<string>;
    function GetResources: TObject;
    function GetImagePath: string;
    function GetUploadIds: TArray<string>;
  protected
    procedure Initialize; override;
    function LoadFromFile(FileName: string = ''): string;

    function HandleFileStep(const Value: string; Index, Step: Integer): string;
    function GetFileName(const Index, Step: Integer): string;
    function GetFileUploadId(const Index, Step: Integer): string;
    procedure EnsureFilesCountNotNull(const Index: Integer);
    procedure EnsureFilesExists(const Index: Integer); overload;
    procedure EnsureFilesExists(const FileNames: TArray<string>); overload;

  public
    /// <summary>
    /// Sets the selected resource index and updates the corresponding UI container selection.
    /// </summary>
    /// <param name="Value">
    /// The zero-based index of the resource to select.
    /// </param>
    procedure Select(const Value: Integer);

    /// <summary>
    /// Initializes the resource manager with default values and updates the current resource state.
    /// </summary>
    /// <returns>
    /// Returns the current instance to support method chaining.
    /// </returns>
    function DefaultValues: IAppFileStoreManager;

    /// <summary>
    /// Loads resource values from persistent storage and updates the current resource state.
    /// </summary>
    /// <returns>
    /// Returns the current instance to support method chaining.
    /// </returns>
    function LoadValues: IAppFileStoreManager;

    /// <summary>
    /// Attaches resource containers to the specified VCL component, optionally binding a click event handler for resource selection.
    /// </summary>
    /// <param name="Value">
    /// The VCL component (such as a TScrollBox) to which resources will be attached.
    /// </param>
    /// <param name="OnClickProc">
    /// Optional procedure to invoke when a resource container is selected.
    /// </param>
    /// <returns>
    /// Returns the current instance to support method chaining.
    /// </returns>
    function AttachTo(const Value: TComponent; const OnClickProc: TProc<TObject> = nil): IAppFileStoreManager;

    /// <summary>
    /// Determines if the persistent JSON storage file for resources exists on disk.
    /// </summary>
    /// <returns>
    /// True if the JSON file exists; otherwise, False.
    /// </returns>
    function JSONExists: Boolean;

    /// <summary>
    /// Reloads the resource list from persistent storage.
    /// </summary>
    procedure Reload;

    /// <summary>
    /// Saves the current resource list to persistent storage.
    /// </summary>
    /// <param name="FileName">
    /// Optional file name to use for saving. If blank, the default file is used.
    /// </param>
    procedure SaveToFile(FileName: string = '');

    /// <summary>
    /// Adds a file to the currently selected resource's file list.
    /// </summary>
    /// <param name="FileName">
    /// The name or path of the file to add.
    /// </param>
    procedure AddFile(const FileName: string);

    /// <summary>
    /// Deletes the file pair at the specified index from the currently selected resource.
    /// </summary>
    /// <param name="index">
    /// The zero-based index of the file pair to delete.
    /// </param>
    procedure DeleteFile(index: Integer);

    /// <summary>
    /// Updates the state for the currently selected resource by re-linking it with the vector store and persisting changes.
    /// </summary>
    procedure UpdateCurrent;

    /// <summary>
    /// Pings the selected vector store by ensuring that the associated files are linked and valid.
    /// </summary>
    /// <returns>
    /// Returns a promise containing the vector store identifier string.
    /// </returns>
    function PingVectorStore: TPromise<string>;

    /// <summary>
    /// Gets or sets the index of the currently selected resource item.
    /// </summary>
    property ItemIndex: Integer read GetItemIndex write SetItemIndex;

    /// <summary>
    /// Gets the image path associated with the currently selected resource.
    /// </summary>
    property ImagePath: string read GetImagePath;

    /// <summary>
    /// Gets or sets the name of the currently selected resource.
    /// </summary>
    property Name: string read GetName write SetName;

    /// <summary>
    /// Gets the description of the currently selected resource.
    /// </summary>
    property Description: string read GetDescription;

    /// <summary>
    /// Gets the GitHub URL associated with the currently selected resource.
    /// </summary>
    property GitHub: string read GetGitHub;

    /// <summary>
    /// Gets the GetIt URL associated with the currently selected resource.
    /// </summary>
    property Getit: string read GetGetit;

    /// <summary>
    /// Gets the list of file paths associated with the currently selected resource.
    /// </summary>
    property Files: TArray<string> read GetFiles;

    /// <summary>
    /// Gets the list of file upload identifiers for the currently selected resource.
    /// </summary>
    property FileUploadIds: TArray<string> read GetUploadIds;

    /// <summary>
    /// Gets the resources object representing the complete resource list.
    /// </summary>
    property Resources: TObject read GetResources;

    /// <summary>
    /// Gets or sets the vector store identifier for the selected resource.
    /// </summary>
    property VectorStore: string read GetVectorStore write SetVectorStore;
  end;

implementation

{ TVectorResourceCore }

procedure TVectorResourceCore.Clear;
begin
  FVectorResourceList.Clear;
end;

constructor TVectorResourceCore.Create;
begin
  inherited Create;
  FVectorResourceList := TVectorResourceList.Reload;
end;

destructor TVectorResourceCore.Destroy;
begin
  FVectorResourceList.Free;
  inherited;
end;

function TVectorResourceCore.GetData(Index: Integer): TVectorResourceItem;
begin
  Result := FVectorResourceList.Data[Index];
end;

{ TVectorResourceVCL }

procedure TVectorResourceVCL.AddFile(const FileName: string);
begin
  Data[ItemIndex].Files := Data[ItemIndex].Files + [FileName];
end;

function TVectorResourceVCL.AttachTo(const Value: TComponent;
  const OnClickProc: TProc<TObject>): IAppFileStoreManager;
begin
  for var item := 0 to Length(FVectorResourceList.Data)-1 do
    TContainer.Create(Value)
      .ApplyTop(GetTopPosition(item))
      .ApplyIndex(item)
      .ApplyImage(FVectorResourceList.Data[item].GetImageStream)
      .ApplyName(FVectorResourceList.Data[item].Name)
      .ApplyDescription(FVectorResourceList.Data[item].Description)
      .ApplyGitHubUrl(FVectorResourceList.Data[item].Github)
      .ApplyGetitUrl(FVectorResourceList.Data[item].Getit)
      .OnSelect(OnClickProc);
  Result := Self;
end;

function TVectorResourceVCL.DefaultValues: IAppFileStoreManager;
begin
  Initialize;
  UpdateCurrent;
  Result := Self;
end;

procedure TVectorResourceVCL.DeleteFile(index: Integer);
begin
  Data[ItemIndex].DeleteFilePair(index);
end;

procedure TVectorResourceVCL.EnsureFilesCountNotNull(const Index: Integer);
begin
  if Length(Data[Index].Files) = 0 then
    raise EFileCountNull.Create(Format('No files exists for vector store "%s"', [Name]));
end;

procedure TVectorResourceVCL.EnsureFilesExists(const FileNames: TArray<string>);
begin
  for var Item in FileNames do
    if not FileExists(Item) then
      raise Exception.CreateFmt(
         'Error: File "%s" not found' + sLineBreak +
         'vector store not valid for "%s"',
         [Item, Name]);
end;

procedure TVectorResourceVCL.EnsureFilesExists(const Index: Integer);
begin
  EnsureFilesExists(Data[Index].Files);
end;

function TVectorResourceVCL.GetDescription: string;
begin
  Result := Data[ItemIndex].Description;
end;

function TVectorResourceVCL.GetFileName(const Index, Step: Integer): string;
begin
  if Length(Data[Index].Files) > Step + 1 then
    Result := Data[Index].Files[Step + 1]
  else
    Result := EmptyStr;
end;

function TVectorResourceVCL.GetFiles: TArray<string>;
begin
  Result := Data[ItemIndex].Files;
end;

function TVectorResourceVCL.GetFileUploadId(const Index, Step: Integer): string;
begin
  if Length(Data[Index].FileUploadId) > Step then
    Result := Data[Index].FileUploadId[Step]
  else
    Result := EmptyStr;
end;

function TVectorResourceVCL.GetGetit: string;
begin
  Result := Data[ItemIndex].Getit;
end;

function TVectorResourceVCL.GetGitHub: string;
begin
  Result := Data[ItemIndex].Github;
end;

function TVectorResourceVCL.GetImagePath: string;
begin
  Result := Data[ItemIndex].Image;
end;

function TVectorResourceVCL.GetItemIndex: Integer;
begin
  Result := FVectorResourceList.ItemIndex;
end;

function TVectorResourceVCL.GetName: string;
begin
  Result := Data[ItemIndex].Name;
end;

function TVectorResourceVCL.GetResources: TObject;
begin
  Result := FVectorResourceList;
end;

function TVectorResourceVCL.GetUploadIds: TArray<string>;
begin
  Result := Data[Itemindex].FileUploadId;
end;

function TVectorResourceVCL.GetVectorStore: string;
begin
  Result := FVectorStore;
end;

function TVectorResourceVCL.HandleFileStep(const Value: string; Index,
  Step: Integer): string;
var
  Buffer: TArray<string>;
begin
  Buffer := Value.Split([#10]);
  if Step = 0 then
    begin
      Data[Index].VectorStoreId := Buffer[0];
      TFileUploadIdTemp := [Buffer[1]];
      FVectorStore := Buffer[0];
    end
  else
    begin
      if Length(Buffer) > 1 then
        begin
          TFileUploadIdTemp := TFileUploadIdTemp + [Buffer[1]];
        end;
    end;
  Result := GetFileName(Index, Step);
end;

procedure TVectorResourceVCL.Initialize;
begin
  FVectorResourceList.Chain
    .Apply(TVectorResourceListProp.ItemIndex, 0)
    .Apply(TVectorResourceListProp.Data, [
       function: TVectorResourceItem
       begin
         Result := TVectorResourceItem.Create;
         Result.Image := '..\..\logos\OpenAILogo.png';
         Result.Name := 'GenAI';
         Result.Description := 'Delphi Wrapper for OpenAI';
         Result.Github := 'https://github.com/MaxiDonkey/DelphiGenAI';
         Result.Getit := 'https://getitnow.embarcadero.com/genai-optimized-openai-integration-wrapper/';
         Result.Files := ['..\..\data\GenAI_documentation.txt'];
       end,
       function: TVectorResourceItem
       begin
         Result := TVectorResourceItem.Create;
         Result.Image := '..\..\logos\MistralAILogo.png';
         Result.Name := 'MistralAI';
         Result.Description := 'Delphi Wrapper for MistralAI';
         Result.Github := 'https://github.com/MaxiDonkey/DelphiMistralAI';
         Result.Getit := 'https://getitnow.embarcadero.com/mistralai-wrapper/';
         Result.Files := ['..\..\data\MistralAI_documentation.txt'];
       end,
       function: TVectorResourceItem
       begin
         Result := TVectorResourceItem.Create;
         Result.Image := '..\..\logos\Anthropic.png';
         Result.Name := 'Anthropic';
         Result.Description := 'Delphi Wrapper for Anthropic (Claude)';
         Result.Github := 'https://github.com/MaxiDonkey/DelphiAnthropic';
         Result.Getit := 'https://getitnow.embarcadero.com/anthropic-api-wrapper-for-delphi/';
         Result.Files := ['..\..\data\Anthropic_documentation.txt'];
       end,
       function: TVectorResourceItem
       begin
         Result := TVectorResourceItem.Create;
         Result.Image := '..\..\logos\GeminiLogo.png';
         Result.Name := 'Gemini';
         Result.Description := 'Delphi Wrapper for Gemini';
         Result.Github := 'https://github.com/MaxiDonkey/DelphiGemini';
         Result.Getit := 'https://getitnow.embarcadero.com/gemini-api-wrapper-for-delphi/';
         Result.Files := ['..\..\data\Gemini_documentation.txt'];
       end,
       function: TVectorResourceItem
       begin
         Result := TVectorResourceItem.Create;
         Result.Image := '..\..\logos\Deepseek_logo.png';
         Result.Name := 'Deepseek';
         Result.Description := 'Delphi Wrapper for Deepseek';
         Result.Github := 'https://github.com/MaxiDonkey/DelphiDeepseek';
         Result.Getit := 'https://getitnow.embarcadero.com/deepseek-api-wrapper-for-delphi/';
         Result.Files := ['..\..\data\Deepseek_documentation.txt'];
       end,
       function: TVectorResourceItem
       begin
         Result := TVectorResourceItem.Create;
         Result.Image := '..\..\logos\GroqCloudLogo.png';
         Result.Name := 'Groq cloud';
         Result.Description := 'Delphi Wrapper for Groq cloud';
         Result.Github := 'https://github.com/MaxiDonkey/DelphiGroqCloud';
         Result.Getit := 'https://getitnow.embarcadero.com/groqcloud-api-wrapper-for-delphi/';
         Result.Files := ['..\..\data\GroqCloud_documentation.txt'];
       end,
       function: TVectorResourceItem
       begin
         Result := TVectorResourceItem.Create;
         Result.Image := '..\..\logos\HuggingFaceLogo.png';
         Result.Name := 'Hugging Face';
         Result.Description := 'Delphi Wrapper for Hugging Face';
         Result.Github := 'https://github.com/MaxiDonkey/DelphiHuggingFace';
         Result.Getit := 'https://getitnow.embarcadero.com/hugging-face-api-wrapper-for-delphi/';
         Result.Files := ['..\..\data\HugginFace_documentation.txt'];
       end,
       function: TVectorResourceItem
       begin
         Result := TVectorResourceItem.Create;
         Result.Image := '..\..\logos\StabilityAILogo.png';
         Result.Name := 'Stability AI';
         Result.Description := 'Delphi Wrapper for StabilityAI';
         Result.Github := 'https://github.com/MaxiDonkey/DelphiStabilityAI';
         Result.Getit := 'https://getitnow.embarcadero.com/stability-ai-api-wrapper-for-delphi/';
         Result.Files := ['..\..\data\StabilityAI_documentation.txt'];
       end,
       function: TVectorResourceItem
       begin
         Result := TVectorResourceItem.Create;
         Result.Image := '..\..\logos\File2knowledge_logo.png';
         Result.Name := 'file2knowledge';
         Result.Description := 'GenAI implementation project through File2knowledge to highlight best practices around the v1/responses endpoint';
         Result.Github := 'https://github.com/MaxiDonkey/file2knowledge';
         Result.Getit := '';
         Result.Files := ['..\..\data\File2knowledge_documentation.txt', '..\..\data\GenAI_documentation.txt'];
       end
    ]);
end;

function TVectorResourceVCL.JSONExists: Boolean;
begin
  Result := FileExists(TVectorResourceList.DefaultFileName);
end;

function TVectorResourceVCL.LoadFromFile(FileName: string): string;
begin
  FVectorResourceList := TVectorResourceList.Reload;
end;

function TVectorResourceVCL.LoadValues: IAppFileStoreManager;
begin
  LoadFromFile;
  UpdateCurrent;
  Result := Self;
end;

function TVectorResourceVCL.PingVectorStore: TPromise<string>;
var
  FileName: string;
begin
  var Index := ItemIndex;

  try
    EnsureFilesCountNotNull(index);
    EnsureFilesExists(Index);
  except
    on E: Exception do
      begin
        var Error := AcquireExceptionObject;
        var Promise := TPromise<string>.Resolved('',
          procedure
          begin
            var ErrorMsg := (Error as Exception).Message;
            AlertService.ShowError(ErrorMsg);
            Error.Free;
          end);
        Exit(Promise);
      end;
  end;

  FVectorStore := Data[ItemIndex].VectorStoreId;
  FileName := Data[Index].Files[0];
  TFileUploadIdTemp := [];
  Result := OpenAI.EnsureVectorStoreFileLinked(FileName, GetFileUploadId(Index, 0), Data[Index].VectorStoreId)
    .&Then<string>(
     function (Value: string): string
      begin
        Result := HandleFileStep(Value, Index, 0);
      end)
    .&Then(
      function (Value: string): TPromise<string>
      begin
        if Value.IsEmpty then
          Result := TPromise<string>.Resolved(FVectorStore)
        else
          Result :=  OpenAI.EnsureVectorStoreFileLinked(Value,
                       GetFileUploadId(Index, 1),
                       Data[Index].VectorStoreId)
      end)
    .&Then<string>(
     function (Value: string): string
      begin
        Result := HandleFileStep(Value, Index, 1);
      end)
    .&Then(
      function (Value: string): TPromise<string>
      begin
        if Value.IsEmpty then
          Result := TPromise<string>.Resolved(FVectorStore)
        else
          Result := OpenAI.EnsureVectorStoreFileLinked(Value,
                      GetFileUploadId(Index, 2),
                      Data[Index].VectorStoreId)
      end)
    .&Then<string>(
     function (Value: string): string
      begin
        Result := HandleFileStep(Value, Index, 2);
      end)
    .&Then(
      function (Value: string): TPromise<string>
      begin
        if Value.IsEmpty then
          Result := TPromise<string>.Resolved(FVectorStore)
        else
          Result := OpenAI.EnsureVectorStoreFileLinked(Value,
                      GetFileUploadId(Index, 3),
                      Data[Index].VectorStoreId)
      end)
    .&Then<string>(
     function (Value: string): string
      begin
        Result := HandleFileStep(Value, Index, 3);
      end)
    .&Then(
      function (Value: string): TPromise<string>
      begin
        if Value.IsEmpty then
          Result := TPromise<string>.Resolved(FVectorStore)
        else
          Result := OpenAI.EnsureVectorStoreFileLinked(Value,
                      GetFileUploadId(Index, 4),
                      Data[Index].VectorStoreId)
      end)
    .&Then<string>(
     function (Value: string): string
      begin
        Data[Index].FileUploadId := TFileUploadIdTemp;
        SaveToFile;
        Result := FVectorStore;
      end)
end;

procedure TVectorResourceVCL.Reload;
begin
  LoadFromFile;
end;

procedure TVectorResourceVCL.SaveToFile(FileName: string);
begin
  FVectorResourceList.Save;
end;

procedure TVectorResourceVCL.Select(const Value: Integer);
begin
  TContainer.ContainerSelect(Value);
end;

procedure TVectorResourceVCL.SetItemIndex(const Value: Integer);
begin
  FVectorResourceList.ItemIndex := Value;
end;

procedure TVectorResourceVCL.SetName(const Value: string);
begin
  Data[ItemIndex].Name := Value;
end;

procedure TVectorResourceVCL.SetVectorStore(const Value: string);
begin
  FVectorStore := Value;
end;

procedure TVectorResourceVCL.UpdateCurrent;
begin
  PingVectorStore;
end;

end.
