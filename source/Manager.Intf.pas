unit Manager.Intf;

(*
  Unit: Manager.Intf

  Purpose:
    Defines the set of core interfaces for orchestration, presentation, and management of interactions
    within the File2knowledgeAI architecture. This unit centralizes the contracts for persistence,
    display, prompt management, and advanced handling of resources associated with the
    OpenAI v1/responses endpoint.

  Architecture and Design:
    - Groups interfaces governing prompt editing, conversational display (chat UI, reasoning),
      asynchronous operation management, file and vector handling via OpenAI, as well as
      persistence and navigation of conversation history.
    - Applies OpenAI/GenAI best practices regarding traceability, UI/business logic decoupling,
      reactive programming patterns (Promises), and modularity for scalable robustness.
    - Centralizes domain contracts essential for conversation chaining,
      state tracking (via ResponseId tracking), and comprehensive resource lifecycle control,
      ensuring tight orchestration around the v1/responses workflow.

  Usage:
    - Implement these interfaces to inject services and controllers into the main application (IoC/DI).
    - Enables agile asynchronous flows (prompts, reasoning, file management),
      aligned with the robustness and maintainability requirements of modern GenAI solutions.

  Context:
    This unit is at the core of File2knowledgeAI, ensuring compliance with best practices
    for prompt chaining, advanced vector resource management, and integration
    with the OpenAI v1/responses endpoint. Essential for building traceable,
    persistent, and easily testable conversational applications.

  Conventions follow the File2knowledgeAI project and OpenAI v1/responses standards.
*)

interface

uses
  System.SysUtils, System.Classes, Manager.Types, ChatSession.Controller,
  GenAI.Async.Promise;

type
  /// <summary>
  /// Defines a contract for presenting user alerts and dialogs in applications.
  /// </summary>
  /// <remarks>
  /// <para>
  /// The <c>IAlertService</c> interface standardizes the core methods required to notify users of errors,
  /// information, warnings, and to request confirmation via modal dialogs. Implementations allow for
  /// decoupling user interface alert logic from business logic, improving maintainability and testability.
  /// </para>
  /// <para>
  /// Typical usage involves calling the appropriate method to display a message or prompt. The dialog
  /// appearance and interaction specifics (e.g., button arrangement, icons) are determined by the concrete
  /// implementation of the interface.
  /// </para>
  /// </remarks>
  IAlertService = interface
    ['{C4A2BF3D-F124-4E10-B910-A038C4C74AA1}']
    /// <summary>
    /// Displays an error message dialog with an "OK" button.
    /// </summary>
    /// <param name="Msg">
    /// The error message to display.
    /// </param>
    procedure ShowError(const Msg: string);

    /// <summary>
    /// Displays an informational message dialog with an "OK" button.
    /// </summary>
    /// <param name="Msg">
    /// The informational message to display.
    /// </param>
    procedure ShowInformation(const Msg: string);

    /// <summary>
    /// Displays a warning dialog with an "OK" button.
    /// </summary>
    /// <param name="Msg">
    /// The warning message to display.
    /// </param>
    procedure ShowWarning(const Msg: string);

    /// <summary>
    /// Shows a confirmation dialog (Yes/No) and returns the user's selection.
    /// </summary>
    /// <param name="Msg">
    /// The confirmation message to display.
    /// </param>
    /// <returns>
    /// <c>mrYes</c> if the user selects Yes; <c>mrNo</c> if No is selected.
    /// </returns>
    function ShowConfirmation(const Msg: string): Integer;
  end;

  /// <summary>
  /// Defines the contract for template management and retrieval in the File2knowledgeAI architecture.
  /// </summary>
  /// <remarks>
  /// <para>
  /// The <c>ITemplateProvider</c> interface centralizes logic for loading and accessing HTML and JavaScript
  /// templates required by the <c>v1/responses</c> endpoint demo workflow. It supports both
  /// auto-reloading for agile development and one-time loading modes more suitable for production,
  /// in addition to offering full control over the directory path used for template discovery.
  /// </para>
  /// <para>
  /// Implementations of this interface should facilitate seamless switching between on-the-fly updates
  /// and in-memory caching, enabling performance optimization or rapid iteration as needed.
  /// </para>
  /// <para>
  /// Template types exposed include initial HTML rendering, JavaScript for displaying responses,
  /// user prompt input, and system reasoning logic.
  /// </para>
  /// </remarks>
  ITemplateProvider = interface
    ['{3DE4085F-1AE3-4C4D-93D3-BA7130FF5C96}']
    function GetInitialHtml: string;
    function GetDisplayTemplate: string;
    function GetReasoningTemplate: string;
    function GetPromptTemplate: string;

    /// <summary>
    /// Enables automatic reloading of template files from the specified directory on each access.
    /// This is recommended for development or rapid prototyping, as it reflects any changes to the template files immediately.
    /// </summary>
    /// <param name="APath">
    /// Optional path to the directory containing template files. If empty, uses the default template path.
    /// </param>
    procedure TemplateAllwaysReloading(const APath: string = '');

    /// <summary>
    /// Disables automatic reloading, causing all template files to be loaded only once and cached in memory.
    /// This improves performance and stability for production use, but changes to template files require an application restart.
    /// </summary>
    procedure TemplateNeverReloading;

    /// <summary>
    /// Sets the directory path where template files are located.
    /// </summary>
    /// <param name="Value">
    /// The file system path to use for loading template files.
    /// </param>
    procedure SetTemplatePath(const Value: string);

    /// <summary>
    /// Gets the HTML template used for initial page rendering.
    /// </summary>
    /// <returns>
    /// The content of the initial HTML template.
    /// </returns>
    property InitialHtml: string read GetInitialHtml;

    /// <summary>
    /// Gets the JavaScript template used to display OpenAI responses.
    /// </summary>
    /// <returns>
    /// The content of the response display JavaScript template.
    /// </returns>
    property DisplayTemplate: string read GetDisplayTemplate;

    /// <summary>
    /// Gets the JavaScript template used for system reasoning and asynchronous operations.
    /// </summary>
    /// <returns>
    /// The content of the reasoning JavaScript template.
    /// </returns>
    property ReasoningTemplate: string read GetReasoningTemplate;

    /// <summary>
    /// Gets the JavaScript template used for user prompt input.
    /// </summary>
    /// <returns>
    /// The content of the prompt JavaScript template.
    /// </returns>
    property PromptTemplate: string read GetPromptTemplate;
  end;

  /// <summary>
  /// Defines the contract for a chat display component capable of rendering markdown output, user prompts,
  /// and dynamic UI elements for conversational AI interactions in a Delphi VCL application.
  /// </summary>
  /// <remarks>
  /// <para>
  /// The <c>IDisplayer</c> interface exposes a set of methods and properties to enable flexible and interactive
  /// chat user interfaces. It supports rendering markdown and prompt bubbles, managing chat history and prompt counts,
  /// handling visual updates, and displaying reasoning states (such as AI response loading indicators).
  /// </para>
  /// <para>
  /// Implementations of this interface are designed to work seamlessly with modern browser engines like Edge (WebView2)
  /// and to integrate into the File2knowledgeAI conversation pipeline or similar chat solutions.
  /// </para>
  /// </remarks>
  IDisplayer = interface
    ['{D7D47290-0C2F-4A8B-9A54-12EAC9C47387}']
    function GetPromptCount: Integer;

    /// <summary>
    /// Appends the specified text as markdown to the chat display stream.
    /// </summary>
    /// <param name="AText">
    /// The markdown-formatted text to display in the chat interface.
    /// </param>
    /// <returns>
    /// The updated content of the internal display stream.
    /// </returns>
    function Display(const AText: string): string;

    /// <summary>
    /// Appends a flow of markdown text to the display stream, optionally auto-scrolling to the end.
    /// </summary>
    /// <param name="AText">
    /// The markdown-formatted text to append.
    /// </param>
    /// <param name="Scroll">
    /// If True, the display scrolls to after the end; otherwise, it does not scroll. Default is False.
    /// </param>
    /// <returns>
    /// The updated content of the internal display stream.
    /// </returns>
    function DisplayStream(const AText: string; Scroll: Boolean = False): string;

    /// <summary>
    /// Injects a new user prompt bubble into the chat display.
    /// </summary>
    /// <param name="AText">
    /// The user's prompt to be visually represented in the chat UI.
    /// </param>
    procedure Prompt(const AText: string);

    /// <summary>
    /// Scrolls the chat display to the end of the conversation history.
    /// </summary>
    /// <param name="Smooth">
    /// If True, scrolling is animated smoothly; otherwise, it scrolls instantly. Default is False.
    /// </param>
    procedure ScrollToEnd(Smooth: Boolean = False); overload;

    /// <summary>
    /// Scrolls the chat display to a position after the last entry and adds free space.
    /// </summary>
    /// <param name="SizeAfter">
    /// The vertical space in pixels to add after the last chat bubble.
    /// </param>
    /// <param name="Smooth">
    /// If True, performs a smooth animated scroll. Default is True.
    /// </param>
    procedure ScrollToAfterEnd(SizeAfter: Integer; Smooth: Boolean = True); overload;

    /// <summary>
    /// Scrolls to the top of the chat display.
    /// </summary>
    procedure ScrollToTop;

    /// <summary>
    /// Clears the chat history and display content.
    /// </summary>
    procedure Clear;

    /// <summary>
    /// Suspends redrawing of the chat control for batch updates.
    /// </summary>
    procedure BeginUpdateControl;

    /// <summary>
    /// Resumes redrawing of the chat control after batch updates.
    /// </summary>
    procedure EndUpdateControl;

    /// <summary>
    /// Makes the chat display visible.
    /// </summary>
    procedure Show;

    /// <summary>
    /// Hides the chat display from view.
    /// </summary>
    procedure Hide;

    /// <summary>
    /// Displays the reasoning or loading indicator panel in the chat interface, typically used to show
    /// that an AI response is being generated.
    /// </summary>
    procedure ShowReasoning;

    /// <summary>
    /// Hides the reasoning or loading indicator panel from the chat interface, removing any related UI elements.
    /// </summary>
    procedure HideReasoning;

    /// <summary>
    /// Gets or sets the current count of user prompts displayed in the chat.
    /// </summary>
    property PromptCount: Integer read GetPromptCount;
  end;

  /// <summary>
  /// Provides a standardized contract for displaying and managing annotation text output
  /// in Delphi VCL TMemo-based components.
  /// </summary>
  /// <remarks>
  /// <para>
  /// The <c>IAnnotationsDisplayer</c> interface encapsulates methods required to append, stream, and
  /// clear multi-line or block text within a TMemo control. It ensures consistent behavior for
  /// text display, live stream updates, and scroll management in logging, annotation, or chat
  /// scenarios.
  /// </para>
  /// <para>
  /// Typical implementations are designed to support both line-wise display and streaming (partial)
  /// updates, handle multiple newline conventions, and give control over scroll position after updates.
  /// This interface is ideally used to decouple annotation or log presentation logic from UI layers,
  /// improving testability and maintainability.
  /// </para>
  /// </remarks>
  IAnnotationsDisplayer = interface
    ['{3D916867-C036-4530-A708-5BBB89B4DB7B}']
    function GetText: string;

    /// <summary>
    /// Appends the provided text to the associated <see cref="TMemo"/> control, splitting it into lines as needed.
    /// Automatically scrolls to the latest entry.
    /// </summary>
    /// <param name="AText"> The text to display. Each line break will result in a new line in the memo. </param
    procedure Display(const AText: string);

    /// <summary>
    /// Streams raw or pre-formatted text directly into the associated <see cref="TMemo"/> control. Suitable for live updates or appending blocks of text.
    /// Handles both '\n' and line break characters for consistent display.
    /// </summary>
    /// <param name="AText">The raw or formatted text to append to the memo.</param>
    procedure DisplayStream(const AText: string);

    /// <summary>
    /// Clears all text from the associated <see cref="TMemo"/> control, removing all lines.
    /// </summary>
    procedure Clear;

    /// <summary>
    /// Scrolls the memo to the last line, bringing the most recent content into view.
    /// </summary>
    procedure ScrollToEnd;

    /// <summary>
    /// Scrolls the memo to the first line, bringing the earliest content into view.
    /// </summary>
    procedure ScrollToTop;

    /// <summary>
    /// Determines whether the memo is currently empty.
    /// </summary>
    /// <returns>True if there is no text in the memo; otherwise, False.</returns>
    function IsEmpty: Boolean;

    /// <summary>
    /// Retrieves the full text from the associated <see cref="TMemo"/> control as a single string.
    /// </summary>
    property Text: string read GetText;
  end;

  /// <summary>
  /// Defines an interface for managing prompt editing, validation, and asynchronous submission
  /// in an AI-powered application. Implementations should provide mechanisms for text handling,
  /// focus control, and clearing the prompt input, supporting seamless user interaction within the UI.
  /// </summary>
  /// <remarks>
  /// The <c>IServicePrompt</c> interface abstracts the contract for prompt management.
  /// It is suitable for use in both visual and non-visual components where textual user input
  /// is edited, validated, and possibly submitted for AI processing. Implementing classes should
  /// support property persistence and clear/reusable interaction patterns.
  /// </remarks>
  IServicePrompt = interface
    ['{82358F03-34FB-4717-AD02-7365C072207B}']
    function GetText: string;
    procedure SetText(const Value: string);

    ///<summary>
    /// Sets focus to the prompt editor control.
    ///</summary>
    procedure SetFocus;

    ///<summary>
    /// Clears the current prompt text from the editor.
    /// </summary>
    procedure Clear;

    ///<summary>
    /// Gets or sets the prompt text.
    ///</summary>
    property Text: string read GetText write SetText;
  end;

  /// <summary>
  /// Provides an interface for canceling asynchronous operations.
  /// </summary>
  /// <remarks>
  /// <para>
  /// The <c>ICancellation</c> interface defines methods for managing the cancellation state of an
  /// ongoing operation. It allows a client to request cancellation, verify if an operation has been canceled,
  /// and reset the cancellation state for reuse.
  /// </para>
  /// <para>
  /// Implementations of this interface enable graceful interruption of long-running or streaming tasks,
  /// ensuring that resources can be released properly when an operation is aborted.
  /// </para>
  /// </remarks>
  ICancellation = interface
    ['{010DE493-1C25-4CF7-8B78-045E26060EAA}']
    /// <summary>
    /// Marks the cancellation as requested, restores the original button caption and click handler.
    /// </summary>
    procedure Cancel(isDone: Boolean = False);

    /// <summary>
    /// Returns True if a cancellation has been requested; otherwise, returns False.
    /// </summary>
    /// <returns>
    /// True if the user has triggered the cancellation action, otherwise False.
    /// </returns>
    function IsCancelled: Boolean;

    /// <summary>
    /// Prepares the managed button for cancellation use by saving its state,
    /// updating the caption to a cancel glyph, and assigning the cancellation handler.
    /// </summary>
    procedure Reset;
  end;

  /// <summary>
  /// Defines the contract for animated left panel controls within a Delphi VCL application,
  /// supporting panel state management, content navigation, and resource entry workflows.
  /// </summary>
  /// <remarks>
  /// <para>
  /// The <c>ILeftPanelControl</c> interface specifies the core functionalities required for
  /// interactive, stateful workspace or navigation panels used in File2knowledgeAI-based applications.
  /// Implementations should enable smooth toggling, asynchronous UI updates, and dynamic resource management,
  /// in line with modern UX standards and OpenAI best practices for resource/session organization.
  /// </para>
  /// </remarks>
  ILeftPanelControl = interface
    ['{6EE300FC-FE89-4588-9B19-BF01D56A7A0C}']
    /// <summary>
    /// Handles panel switch events, toggling the panel between opened and closed states.
    /// </summary>
    /// <param name="Sender">The object that initiated the switch operation (typically a button).</param>
    procedure HandleSwitch(Sender: TObject);

    /// <summary>
    /// Handles creation of a new conversation/resource entry in the panel.
    /// Resets any persistent or selection state and prepares the workspace for a fresh entry.
    /// </summary>
    /// <param name="Sender">The control or component that triggered the new entry action.</param>
    procedure HandleNew(Sender: TObject);

    /// <summary>
    /// Refreshes the contents of the left panel,
    /// repopulating its scroll box with the latest resource containers and updating their states.
    /// </summary>
    procedure Refresh;

    /// <summary>
    /// Selects the resource container by its index in the scroll box,
    /// triggering selection logic and highlighting for navigation or operation.
    /// </summary>
    /// <param name="AIndex">The index of the container to select.</param>
    procedure ItemSelect(const AIndex: Integer);
  end;

  /// <summary>
  /// IAIInteractionManager defines a contract for executing prompts and managing file/vector store interactions with the OpenAI/GenAI APIs.
  /// </summary>
  /// <remarks>
  /// This interface abstracts the full lifecycle of prompt execution, covering both streamed (real-time) and silent (background) scenarios,
  /// as well as advanced operations for file and vector store management. Its methods enable integration with OpenAI's latest endpoint
  /// (v1/responses), supporting operations such as prompt submission, file uploads, vector store linking, and deletion of entities
  /// (responses, files, vector stores, and associations).
  /// <para>
  /// - The design ensures asynchronous operation through promises, promoting responsive and non-blocking workflows in Delphi applications.
  /// Implementations should be stateless or singleton, injectable via IoC/DI, and focused on best practices for modularity, testability, and decoupling.
  /// </para>
  /// </remarks>
  IAIInteractionManager = interface
    ['{AF0A6D31-0942-42A8-BCAC-225AB375DCDE}']
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
  end;

  /// <summary>
  /// Defines the contract for a page selector component in Delphi VCL applications,
  /// enabling programmatic activation and retrieval of application pages through
  /// a unified interface.
  /// </summary>
  /// <remarks>
  /// <para>
  /// Implementations of <c>ISelector</c> allow clients to activate specific application pages,
  /// synchronize user interface controls such as ComboBox and PageControl,
  /// and query or update the currently active page.
  /// </para>
  /// <para>
  /// This interface is designed to promote separation of page navigation logic from UI implementation,
  /// and supports extensibility for multi-page, modular applications.
  /// </para>
  /// </remarks>
  ISelector = interface
    ['{265B784D-6279-48A3-A3D3-2FB3B3902DFD}']
    function GetActivePage: TPageSelector;
    /// <summary>
    /// Displays and activates the specified page in the selector.
    /// Synchronizes the ComboBox selection, PageControl tab, and Label to reflect the chosen page.
    /// </summary>
    /// <param name="Page">
    /// The <see cref="Manager.Types.TPageSelector"/> value identifying the page to show.
    /// </param>
    procedure ShowPage(const Page: TPageSelector);

    /// <summary>
    /// Gets or sets the currently active page in the selector.
    /// </summary>
    /// <remarks>
    /// Setting this property changes the UI to reflect the active page,
    /// updating the ComboBox, PageControl, and Label accordingly.
    /// </remarks>
    property ActivePage: TPageSelector read GetActivePage write ShowPage;
  end;

  /// <summary>
  /// Provides a standardized contract for managing AI vector resource lists and file-based persistence in
  /// VCL applications.
  /// </summary>
  /// <remarks>
  /// <para>
  /// - The <c>IAppFileStoreManager</c> interface defines methods and properties necessary for loading,
  /// saving, and updating vector resource definitions, as well as managing files and vector store
  /// identifiers associated with each resource. It centralizes business logic for working with resources,
  /// making it easier to maintain, extend, and test resource management code. Implementations of this
  /// interface abstract away interaction with JSON files and UI components, so that business and presentation
  /// logic remain decoupled.
  /// </para>
  /// <para>
  /// - Key responsibilities include the loading of persistent data from disk, attaching vector resource items
  /// to visual container components, synchronizing selection state, updating and persisting resource
  /// attributes, and tracking resource file associations. The interface also exposes methods for advanced
  /// operations such as pinging vector stores, method-chained configuration, and file lifecycle actions,
  /// which all facilitate fluid user experience and robust persistence according to best practices.
  /// </para>
  /// <para>
  /// - IAppFileStoreManager should be used as the foundation for VCL-aware classes orchestrating data, UI, and
  /// file persistence for AI resource lists. This interface enhances scalability and reliability when
  /// integrating new resource providers, data formats, or storage mechanisms in a GenAI VCL application
  /// context.
  /// </para>
  /// </remarks>
  IAppFileStoreManager = interface
    ['{9D25981C-26B4-4B26-8017-9FFA0B542B2F}']
    function GetItemIndex: Integer;
    procedure SetItemIndex(const Value: Integer);
    function GetVectorStore: string;
    procedure SetVectorStore(const Value: string);
    function GetImagePath: string;
    function GetName: string;
    function GetDescription: string;
    function GetGitHub: string;
    function GetGetit: string;
    function GetFiles: TArray<string>;
    function GetUploadIds: TArray<string>;
    function GetResources: TObject;
    procedure SetName(const Value: string);

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

  /// <summary>
  /// Defines the contract for a visual and interactive chat session history view component
  /// in the File2knowledgeAI application.
  /// </summary>
  /// <remarks>
  /// <para>
  /// The <c>IChatSessionHistoryView</c> interface declares the essential operations needed to
  /// present and manage historical multi-turn chat conversations in a user interface.
  /// This includes full reload and refresh capabilities, visual repaints of current sessions,
  /// and support for showing contextual annotations tied to each conversation round.
  /// </para>
  /// <para>
  /// Implementations of this interface handle user-driven updates to the chat history UI,
  /// synchronize with persistent storage layers, and ensure continuity of conversational state.
  /// It plays a central role in providing a seamless, user-friendly experience when navigating
  /// and administrating historical chat data, fully aligned with OpenAI and File2knowledgeAI best practices.
  /// </para>
  /// </remarks>
  IChatSessionHistoryView = interface
    ['{1548AE2E-891D-4C60-9F2E-B2153D861D06}']
    /// <summary>
    /// Fully refreshes the display by reloading all chat session history from the persistent store and updating the ListView.
    /// </summary>
    /// <param name="Sender">The caller or event originator.</param>
    procedure FullRefresh(Sender: TObject);

    /// <summary>
    /// Refreshes the ListView to reflect the current state of the chat session history without reloading from the persistent store.
    /// </summary>
    /// <param name="Sender">The caller or event originator.</param>
    procedure Refresh(Sender: TObject);

    /// <summary>
    /// Repaints all UI elements for the currently selected chat session, optionally invoking specialized rendering for each turn in the conversation.
    /// </summary>
    /// <param name="Sender">The caller or event originator.</param>
    procedure Repaint(Sender: TObject);

    /// <summary>
    /// Updates the specified annotation display component with new text and scrolls to the top.
    /// </summary>
    /// <param name="Annotation">The component responsible for displaying annotations.</param>
    /// <param name="Text">The annotation text to display.</param>
    procedure UpdateAnnotation(const Annotation: IAnnotationsDisplayer; const Text: string);
  end;

  /// <summary>
  /// Interface for tracking OpenAI response IDs to enable conversation chaining using the v1/responses endpoint.
  /// </summary>
  /// <remarks>
  /// <para>
  /// The <c>IOpenAIChatTracking</c> interface defines the contract for components that manage a set of unique response
  /// identifiers (IDs) received from calls to the OpenAI v1/responses endpoint. These IDs are essential for linking user requests
  /// to corresponding responses in persistent, multi-turn conversations.
  /// </para>
  /// <para>
  /// This interface provides methods to add new response IDs, remove them, clear the entire set, and cancel the last operation,
  /// with special focus on supporting robust conversation history and state management for chaining purposes.
  /// </para>
  /// <para>
  /// Implementations of <c>IOpenAIChatTracking</c> make it possible to centralize control of response ID lifecycles,
  /// facilitating traceability, cleanup, and efficient chaining of prompts and responses according to File2knowledgeAI best practices.
  /// </para>
  /// </remarks>
  IOpenAIChatTracking = interface
    ['{3D2883AA-12B8-461C-B1AF-E98B5C18F523}']
    function GetLastId: string;
    /// <summary>
    /// Adds a new ID to the tracking list if it is not empty or already present.
    /// Updates the last tracked ID.
    /// </summary>
    /// <param name="Value">
    /// The unique identifier to add.
    /// </param>
    procedure Add(const Value: string);

    /// <summary>
    /// Deletes the specified ID from tracking by invoking the assigned delete procedure.
    /// </summary>
    /// <param name="Value">
    /// The unique identifier to delete.
    /// </param>
    procedure Delete(const Value: string);

    /// <summary>
    /// Removes all IDs from the tracking list and clears the last tracked ID.
    /// Invokes the assigned delete procedure for each removed ID.
    /// </summary>
    procedure Clear;

    /// <summary>
    /// Cancels the most recent tracking operation and reverts the last tracked ID to the previous one.
    /// If there was only one or no ID tracked, the last ID will be set to an empty string.
    /// </summary>
    procedure Cancel;

    /// <summary>
    /// Remove the responseId from LogId
    /// </summary>
    procedure RemoveId(const ResponseId: string);

    /// <summary>
    /// Get the list of the responseId
    /// </summary>
    function GetLogIds: string;

    /// <summary>
    /// Get the orphaned responseId
    /// </summary>
    function GetOrphans(const SessionIds: TArray<string>): TArray<string>;

    /// <summary>
    /// Gets the last tracked unique identifier.
    /// </summary>
    property LastId: string read GetLastId;
  end;

  /// <summary>
  /// Defines the contract for a prompt selector component in Delphi VCL applications.
  /// </summary>
  /// <remarks>
  /// <para>
  /// Provides an interface for managing navigation and interaction with a collection of prompts within a user interface.
  /// Implementations should supply visual navigation (show/hide capability and index management) along with synchronization to any underlying data source.
  /// </para>
  /// <para>
  /// Designed for use in scenarios where prompts or history items must be browsed and selected by the end-user, with direct integration into VCL forms or panels.
  /// </para>
  /// </remarks>
  IPromptSelector = interface
    ['{D26054D6-D07E-49B8-9ADB-2485D2727296}']
    procedure SetItemIndex(const Value: Integer);
    function GetItemIndex: Integer;
    /// <summary>
    /// Updates the prompt selector UI to reflect current application state.
    /// </summary>
    /// <remarks>
    /// <para>
    /// Refreshes the display, sets the item count and current index,
    /// and updates all related visual elements according to the prompt data.
    /// </para>
    /// </remarks>
    procedure Update;

    /// <summary>
    /// Hides the prompt selector panel from the user interface.
    /// </summary>
    procedure Hide;

    /// <summary>
    /// Shows the prompt selector panel in the user interface.
    /// </summary>
    procedure Show;

    /// <summary>
    /// Gets or sets the currently selected prompt index.
    /// </summary>
    /// <returns>
    /// The zero-based index of the currently selected prompt.
    /// </returns>
    property ItemIndex: Integer read GetItemIndex write SetItemIndex;
  end;

  /// <summary>
  /// Defines the contract for managing the persistence of application user settings.
  /// </summary>
  /// <remarks>
  /// The <c>IIniSettings</c> interface abstracts the operations required to load, save, and reload user settings,
  /// providing unified access to a settings object and supporting file-based serialization.
  /// </remarks>
  IIniSettings = interface
    ['{9FF3D2AC-CB9E-41A7-826B-08797AB4F1EC}']
    function GetSettings: TObject;

    /// <summary>
    /// Reloads the user settings from persistent storage.
    /// </summary>
    /// <remarks>
    /// This method replaces the current settings with those loaded from disk.
    /// Typically used to re-synchronize in-memory settings with external changes.
    /// </remarks>
    procedure Reload;

    /// <summary>
    /// Loads settings from the specified file.
    /// </summary>
    /// <param name="FileName">
    /// The file path of the configuration file to load. If empty, the default settings file is used.
    /// </param>
    /// <returns>
    /// Returns the file path used for loading, or an empty string if the operation fails.
    /// </returns>
    function LoadFromFile(FileName: string = ''): string;

    /// <summary>
    /// Saves the current settings to the specified file.
    /// </summary>
    /// <param name="FileName">
    /// The file path where the configuration should be saved. If empty, the default file is used.
    /// </param>
    procedure SaveToFile(FileName: string = '');

    /// <summary>
    /// Gets the settings object being managed.
    /// </summary>
    /// <returns>
    /// Returns the current settings instance as a <c>TObject</c>.
    /// </returns>
    property Settings: TObject read GetSettings;
  end;

  /// <summary>
  /// Interface for advanced user settings management in the File2knowledgeAI VCL application.
  /// </summary>
  /// <remarks>
  /// <para>
  /// <c>ISettings</c> provides a standardized contract for accessing, updating, and synchronizing
  /// user application's preferences, including AI provider keys, proficiency, search and reasoning models,
  /// and contextual search options. Implementations of this interface coordinate persistent settings
  /// with UI controls, ensuring robust, centralized user configuration management.
  /// </para>
  /// <para>
  /// Key features exposed include programmatic prompting for missing information (such as API keys),
  /// two-way updates between user interface and underlying settings data, as well as
  /// retrieval of values for runtime or business logic use. The interface supports scalable extension for new
  /// preference domains or UI surfaces with minimal code changes, following modern architectural practices
  /// in Delphi VCL projects.
  /// </para>
  /// </remarks>
  ISettings = interface
    ['{E5EB0825-72A4-4F31-8C7E-3B470E83EAE9}']
    /// <summary>
    /// Prompts the user to enter their OpenAI API key if it is not already set.
    /// <para>
    /// If no API key is present, displays a dialog for user input,
    /// saves the entered key to persistent settings, and updates the application state accordingly.
    /// </para>
    /// </summary>
    procedure InputAPIKey;

    /// <summary>
    /// Synchronizes the UI controls with the current persistent user settings.
    /// <para>
    /// Updates all UI elements to reflect values from the persistent settings model,
    /// applies display updates (such as model costs), and ensures all modifications are saved.
    /// </para>
    /// </summary>
    procedure Update;

    /// <summary>
    /// Returns the textual representation of the currently selected user proficiency level.
    /// <para>
    /// Retrieves the current selection from the proficiency ComboBox and
    /// converts it to its display string using the helper for proficiency levels.
    /// </para>
    /// </summary>
    function ProficiencyToString: string;

    /// <summary>
    /// Gets the user's screen name as displayed in the application's UI.
    /// <para>
    /// Returns the value of the preference name loaded from the settings model.
    /// </para>
    /// </summary>
    function UserScreenName: string;

    /// <summary>
    /// Returns the identifier of the currently selected search model.
    /// <para>
    /// Gets the search model chosen in the UI or persisted in the user settings.
    /// </para>
    /// </summary>
    function SearchModel: string;

    /// <summary>
    /// Returns the identifier of the currently selected reasoning model.
    /// <para>
    /// Gets the reasoning model chosen in the UI or persisted in the user settings.
    /// </para>
    /// </summary>
    function ReasoningModel: string;

    /// <summary>
    /// Returns the currently stored OpenAI API key.
    /// <para>
    /// Provides access to the API key stored in the settings, without prompting the user.
    /// </para>
    /// </summary>
    function APIKey: string;

    /// <summary>
    /// Gets the selected value for reasoning effort.
    /// </summary>
    /// <returns>
    /// The current reasoning effort value from settings.
    /// </returns>
    function ReasoningEffort: string;

    /// <summary>
    /// Gets the selected value for reasoning summary.
    /// </summary>
    /// <returns>
    /// The current reasoning summary value from settings.
    /// </returns>
    function ReasoningSummary: string;

    /// <summary>
    /// Gets the configured web search context size.
    /// </summary>
    /// <returns>
    /// The current web context size from settings.
    /// </returns>
    function WebContextSize: string;

    /// <summary>
    /// Gets the timeout configuration for user operations.
    /// </summary>
    /// <returns>
    /// The current timeout value from settings.
    /// </returns>
    function TimeOut: string;

    /// <summary>
    /// Gets the configured country string.
    /// </summary>
    /// <returns>
    /// The country value from user settings.
    /// </returns>
    function Country: string;

    /// <summary>
    /// Gets the configured city string.
    /// </summary>
    /// <returns>
    /// The city value from user settings.
    /// </returns>
    function City: string;

    /// <summary>
    /// Indicates if a summary is to be used for the current user configuration.
    /// </summary>
    /// <returns>
    /// True if the summary is enabled; otherwise, False.
    /// </returns>
    function UseSummary: Boolean;
  end;

  /// <summary>
  /// Interface for managing and switching the main feature modes (Web Search, File Search Disable, Reasoning)
  /// in the File2knowledgeAI application.
  /// </summary>
  /// <remarks>
  /// <para>
  /// <c>IServiceFeatureSelector</c> defines methods to programmatically toggle the primary modes used for search and
  /// reasoning features. Implementations of this interface ensure consistent state management and provide the
  /// capability to synchronize UI elements (such as toggle buttons or labels) with internal feature logic.
  /// </para>
  /// <para>
  /// This interface is intended to standardize the way in which the application activates, deactivates, or combines
  /// its core functional features at runtime, facilitating both user-driven and code-driven feature changes.
  /// </para>
  /// </remarks>
  IServiceFeatureSelector = interface
    ['{C9E6967B-D4A0-4032-9047-D10F4938A2A5}']
    function GetFeatureModes: TFeatureModes;
    /// <summary>
    /// Programmatically toggles the Web Search mode, updating both internal state and UI accordingly.
    /// </summary>
    procedure SwitchWebSearch;

    /// <summary>
    /// Programmatically toggles the File Search feature disable mode, updating internal state and the UI.
    /// </summary>
    procedure SwitchDisableFileSearch;

    /// <summary>
    /// Programmatically toggles the Reasoning mode, enforcing the required disabling of Web Search and updating the UI.
    /// </summary>
    procedure SwitchReasoning;

    /// <summary>
    /// Gets the current combination of feature modes (Web Search, File Search Disabled, Reasoning)
    /// as reflected by the UI state of the corresponding buttons.
    /// </summary>
    property FeatureModes: TFeatureModes read GetFeatureModes;
  end;

  /// <summary>
  /// Interface for resource editor components providing methods to manage and synchronize
  /// vector resource data and related UI controls in the File2knowledgeAI application.
  /// </summary>
  /// <remarks>
  /// Implementations of this interface are responsible for refreshing the editor view and
  /// re-initializing any file attachments or metadata displayed in the UI.
  /// Typical use cases include updating the visible state after data changes or file operations,
  /// and ensuring consistent synchronization between persistent data and user interface components.
  /// </remarks>
  IVectorResourceEditor = interface
    ['{A27DA244-00A9-42C1-8131-E25A1C218F13}']
    /// <summary>
    /// Reloads vector resource data into the UI controls and re-initializes the file management context.
    /// </summary>
    procedure Refresh;
  end;

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
  IFileUploadIdController = interface
    ['{BD051725-EEA5-47CB-8F00-A717F8C477FD}']
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

  {--- Internal For Provider OpenAI }

  IPromptExecutionEngine = interface
    ['{7434A3D6-0DDC-4EB8-BFF6-8984A49FF6AF}']
    function Execute(const Prompt: string): TPromise<string>;
  end;

  IVectorStoreManager = interface
    ['{82FB52F6-F574-45D0-9EF1-8FD048B3DE97}']
    {--- Vector store }
    function EnsureVectorStoreId(const VectorStoreId: string): TPromise<string>;

    {--- Vector store file }
    function EnsureVectorStoreFileId(const VectorStoreId, FileId: string): TPromise<string>;
    function DeleteVectorStoreFile(const VectorStoreId, FileId: string): TPromise<string>;
    function DeleteVectorStore(const VectorStoreId: string): TPromise<string>;
  end;

  IFileStoreManager = interface
    ['{89695EFE-D587-4322-9A79-3D7657A451FE}']
    function CheckFileUploaded(const FileName, Id: string): TPromise<string>;
    function UploadFileAsync(const FileName: string): TPromise<string>;
    function EnsureFileId(const FileName: string; const Id: string): TPromise<string>;
  end;

  ISystemPromptBuilder = interface
    ['{F4C1A33D-A004-4D63-8532-E320731E1082}']
    function BuildSystemPrompt: string;
  end;

  {--- Startup services }

  /// <summary>
  /// Defines the contract for accessing key services and procedures required during application startup in the File2knowledgeAI architecture.
  /// </summary>
  /// <remarks>
  /// <para>
  /// The <c>IStartupContext</c> interface standardizes dependency access for form presentation, prompt services, display management,
  /// layout resizing, and startup error handling. Implementations of this interface provide a consistent, testable, and flexible
  /// mechanism for managing startup workflow elements in modular applications.
  /// </para>
  /// <para>
  /// Its primary purpose is to streamline initialization logic, promote clean architecture, and facilitate the injection of
  /// critical startup dependencies throughout the File2knowledgeAI project.
  /// </para>
  /// </remarks>
  IStartupContext = interface
    ['{DB8C48AF-40D5-472D-A893-86D1FB0B36E0}']
    /// <summary>
    /// Gets the displayer interface used for UI output during startup.
    /// </summary>
    function GetDisplayer: IDisplayer;

    /// <summary>
    /// Gets the service prompt interface responsible for user prompts and startup interactions.
    /// </summary>
    function GetServicePrompt: IServicePrompt;

    /// <summary>
    /// Gets the procedure reference for layout or window resizing operations at startup.
    /// </summary>
    function GetResizeProc: TProc;

    /// <summary>
    /// Gets the procedure reference used to launch or display the main application form.
    /// </summary>
    function GetFormPresenter: TProc;

    /// <summary>
    /// Gets the procedure reference for handling and displaying errors during startup.
    /// </summary>
    function GetOnError: TProc;
  end;

  /// <summary>
  /// Defines a contract for startup services responsible for executing the coordinated
  /// initialization sequence of the File2knowledgeAI application or its modules.
  /// </summary>
  /// <remarks>
  /// <para>
  /// <c>IStartupService</c> encapsulates the startup workflow, ensuring that all required
  /// user interface and system initialization procedures are orchestrated efficiently during application launch.
  /// </para>
  /// <para>
  /// Implementations typically handle UI clearing, main form presentation, environment checks,
  /// user notifications for missing dependencies, error handling upon initialization failures,
  /// session history refresh, focus assignment to service prompts, and layout resizing.
  /// All operations should run asynchronously on the main thread to avoid blocking the user interface.
  /// </para>
  /// </remarks>
  IStartupService = interface
    ['{383FC689-F896-470E-8E56-2F4296953541}']
    /// <summary>
    /// Executes the coordinated startup sequence for the application or module.
    /// </summary>
    /// <remarks>
    /// This method clears the interface, displays the main form, checks for mandatory runtime libraries,
    /// shows user alerts for missing resources, triggers error handling callbacks if needed, refreshes the session
    /// history view, sets focus on the service prompt, and performs dynamic resizing. All operations are queued
    /// asynchronously on the main thread to avoid blocking the UI.
    /// </remarks>
    procedure Run;
  end;

var
  /// <summary>
  /// Provides cancellation control for ongoing asynchronous operations.
  /// </summary>
  Cancellation: ICancellation;

  /// <summary>
  /// Provides an implementation of <c>IDisplayer</c> for rendering chat and AI conversational output
  /// using Edge (WebView2) as the display engine within Delphi VCL applications.
  /// </summary>
  /// <remarks>
  /// <para>
  /// <c>EdgeDisplayer</c> enables rich, styled markdown, prompt bubbles, and dynamic UI elements for interactive chat interfaces,
  /// leveraging the flexibility of modern HTML/CSS/JavaScript via the integrated Edge browser component.
  /// </para>
  /// <para>
  /// It acts as the main bridge between the conversational logic and the user, supporting real-time updates,
  /// scrolling, reasoning state UI, and prompt injection—all managed seamlessly within the WebView2 context.
  /// </para>
  /// <para>
  /// This variable forms the standard concrete implementation of <c>IDisplayer</c>
  /// for the File2knowledgeAI application's chat interface.
  /// </para>
  /// </remarks>
  EdgeDisplayer: IDisplayer;

  /// <summary>
  /// Provides a concrete implementation of <c>ITemplateProvider</c> used for managing and supplying
  /// HTML and JavaScript templates in the File2knowledgeAI application.
  /// </summary>
  /// <remarks>
  /// <para>
  /// <c>TemplateProvider</c> acts as the central access point for retrieving UI templates used with the
  /// <c>v1/responses</c> endpoint, including those for initial page rendering, displaying AI responses,
  /// reasoning operations, and user prompt input.
  /// </para>
  /// <para>
  /// By exposing an <c>ITemplateProvider</c> implementation, this variable facilitates template
  /// management, switching between development and production loading modes, and enables consistent
  /// template access throughout the application.
  /// </para>
  /// </remarks>
  TemplateProvider: ITemplateProvider;

  /// <summary>
  /// An implementation of <c>IAnnotationsDisplayer</c> for rendering annotation or file search results
  /// in a TMemo-based VCL component. Used as the primary text output interface in File2knowledgeAI
  /// file search scenarios.
  /// </summary>
  FileSearchDisplayer: IAnnotationsDisplayer;

  /// <summary>
  /// An implementation of <c>IAnnotationsDisplayer</c> designed to present web search output,
  /// live streaming results, or retrieved web content using a TMemo-based VCL component.
  /// Facilitates clear, scrollable display of web-derived annotation or QA text.
  /// </summary>
  WebSearchDisplayer: IAnnotationsDisplayer;

  /// <summary>
  /// An implementation of <c>IAnnotationsDisplayer</c> for outputting AI reasoning,
  /// analysis steps, or justification logs using a TMemo-based VCL component.
  /// Ensures that AI-generated reasoning is rendered clearly and can be easily reviewed in the UI.
  /// </summary>
  ReasoningDisplayer: IAnnotationsDisplayer;

  /// <summary>
  /// IAIInteractionManager defines a contract for executing prompts and managing file/vector store interactions with the OpenAI/GenAI APIs.
  /// </summary>
  /// <remarks>
  /// This interface abstracts the full lifecycle of prompt execution, covering both streamed (real-time) and silent (background) scenarios,
  /// as well as advanced operations for file and vector store management. Its methods enable integration with OpenAI's latest endpoint
  /// (v1/responses), supporting operations such as prompt submission, file uploads, vector store linking, and deletion of entities
  /// (responses, files, vector stores, and associations).
  /// <para>
  /// - The design ensures asynchronous operation through promises, promoting responsive and non-blocking workflows in Delphi applications.
  /// Implementations should be stateless or singleton, injectable via IoC/DI, and focused on best practices for modularity, testability, and decoupling.
  /// </para>
  /// </remarks>
  OpenAI: IAIInteractionManager;

  /// <summary>
  /// Defines an interface for managing prompt editing, validation, and asynchronous submission
  /// in an AI-powered application. Implementations should provide mechanisms for text handling,
  /// focus control, and clearing the prompt input, supporting seamless user interaction within the UI.
  /// </summary>
  /// <remarks>
  /// The <c>IServicePrompt</c> interface abstracts the contract for prompt management.
  /// It is suitable for use in both visual and non-visual components where textual user input
  /// is edited, validated, and possibly submitted for AI processing. Implementing classes should
  /// support property persistence and clear/reusable interaction patterns.
  /// </remarks>
  ServicePrompt: IServicePrompt;

  /// <summary>
  /// Defines the contract for a page selector component in Delphi VCL applications,
  /// enabling programmatic activation and retrieval of application pages through
  /// a unified interface.
  /// </summary>
  /// <remarks>
  /// <para>
  /// Implementations of <c>ISelector</c> allow clients to activate specific application pages,
  /// synchronize user interface controls such as ComboBox and PageControl,
  /// and query or update the currently active page.
  /// </para>
  /// <para>
  /// This interface is designed to promote separation of page navigation logic from UI implementation,
  /// and supports extensibility for multi-page, modular applications.
  /// </para>
  /// </remarks>
  Selector: ISelector;

  /// <summary>
  /// Defines the contract for animated left panel controls within a Delphi VCL application,
  /// supporting panel state management, content navigation, and resource entry workflows.
  /// </summary>
  /// <remarks>
  /// <para>
  /// The <c>ILeftPanelControl</c> interface specifies the core functionalities required for
  /// interactive, stateful workspace or navigation panels used in File2knowledgeAI-based applications.
  /// Implementations should enable smooth toggling, asynchronous UI updates, and dynamic resource management,
  /// in line with modern UX standards and OpenAI best practices for resource/session organization.
  /// </para>
  /// </remarks>
  LeftPanelControl: ILeftPanelControl;

  /// <summary>
  /// Provides a standardized contract for managing AI vector resource lists and file-based persistence in
  /// VCL applications.
  /// </summary>
  /// <remarks>
  /// <para>
  /// - The <c>IAppFileStoreManager</c> interface defines methods and properties necessary for loading,
  /// saving, and updating vector resource definitions, as well as managing files and vector store
  /// identifiers associated with each resource. It centralizes business logic for working with resources,
  /// making it easier to maintain, extend, and test resource management code. Implementations of this
  /// interface abstract away interaction with JSON files and UI components, so that business and presentation
  /// logic remain decoupled.
  /// </para>
  /// <para>
  /// - Key responsibilities include the loading of persistent data from disk, attaching vector resource items
  /// to visual container components, synchronizing selection state, updating and persisting resource
  /// attributes, and tracking resource file associations. The interface also exposes methods for advanced
  /// operations such as pinging vector stores, method-chained configuration, and file lifecycle actions,
  /// which all facilitate fluid user experience and robust persistence according to best practices.
  /// </para>
  /// <para>
  /// - IAppFileStoreManager should be used as the foundation for VCL-aware classes orchestrating data, UI, and
  /// file persistence for AI resource lists. This interface enhances scalability and reliability when
  /// integrating new resource providers, data formats, or storage mechanisms in a GenAI VCL application
  /// context.
  /// </para>
  /// </remarks>
  FileStoreManager: IAppFileStoreManager;

  /// <summary>
  /// Defines a contract for presenting user alerts and dialogs in applications.
  /// </summary>
  /// <remarks>
  /// <para>
  /// The <c>IAlertService</c> interface standardizes the core methods required to notify users of errors,
  /// information, warnings, and to request confirmation via modal dialogs. Implementations allow for
  /// decoupling user interface alert logic from business logic, improving maintainability and testability.
  /// </para>
  /// <para>
  /// Typical usage involves calling the appropriate method to display a message or prompt. The dialog
  /// appearance and interaction specifics (e.g., button arrangement, icons) are determined by the concrete
  /// implementation of the interface.
  /// </para>
  /// </remarks>
  AlertService: IAlertService;

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
  PersistentChat: IPersistentChat;

  /// <summary>
  /// Defines the contract for a visual and interactive chat session history view component
  /// in the File2knowledgeAI application.
  /// </summary>
  /// <remarks>
  /// <para>
  /// The <c>IChatSessionHistoryView</c> interface declares the essential operations needed to
  /// present and manage historical multi-turn chat conversations in a user interface.
  /// This includes full reload and refresh capabilities, visual repaints of current sessions,
  /// and support for showing contextual annotations tied to each conversation round.
  /// </para>
  /// <para>
  /// Implementations of this interface handle user-driven updates to the chat history UI,
  /// synchronize with persistent storage layers, and ensure continuity of conversational state.
  /// It plays a central role in providing a seamless, user-friendly experience when navigating
  /// and administrating historical chat data, fully aligned with OpenAI and File2knowledgeAI best practices.
  /// </para>
  /// </remarks>
  ChatSessionHistoryView: IChatSessionHistoryView;

  /// <summary>
  /// Interface for tracking OpenAI response IDs to enable conversation chaining using the v1/responses endpoint.
  /// </summary>
  /// <remarks>
  /// <para>
  /// The <c>IOpenAIChatTracking</c> interface defines the contract for components that manage a set of unique response
  /// identifiers (IDs) received from calls to the OpenAI v1/responses endpoint. These IDs are essential for linking user requests
  /// to corresponding responses in persistent, multi-turn conversations.
  /// </para>
  /// <para>
  /// This interface provides methods to add new response IDs, remove them, clear the entire set, and cancel the last operation,
  /// with special focus on supporting robust conversation history and state management for chaining purposes.
  /// </para>
  /// <para>
  /// Implementations of <c>IOpenAIChatTracking</c> make it possible to centralize control of response ID lifecycles,
  /// facilitating traceability, cleanup, and efficient chaining of prompts and responses according to File2knowledgeAI best practices.
  /// </para>
  /// </remarks>
  ResponseTracking: IOpenAIChatTracking;

  /// <summary>
  /// Defines the contract for a prompt selector component in Delphi VCL applications.
  /// </summary>
  /// <remarks>
  /// <para>
  /// Provides an interface for managing navigation and interaction with a collection of prompts within a user interface.
  /// Implementations should supply visual navigation (show/hide capability and index management) along with synchronization to any underlying data source.
  /// </para>
  /// <para>
  /// Designed for use in scenarios where prompts or history items must be browsed and selected by the end-user, with direct integration into VCL forms or panels.
  /// </para>
  /// </remarks>
  PromptSelector: IPromptSelector;

  /// <summary>
  /// Defines the contract for managing the persistence of application user settings.
  /// </summary>
  /// <remarks>
  /// The <c>IIniSettings</c> interface abstracts the operations required to load, save, and reload user settings,
  /// providing unified access to a settings object and supporting file-based serialization.
  /// </remarks>
  IniSettings: IIniSettings;

  /// <summary>
  /// Interface for advanced user settings management in the File2knowledgeAI VCL application.
  /// </summary>
  /// <remarks>
  /// <para>
  /// <c>ISettings</c> provides a standardized contract for accessing, updating, and synchronizing
  /// user application's preferences, including AI provider keys, proficiency, search and reasoning models,
  /// and contextual search options. Implementations of this interface coordinate persistent settings
  /// with UI controls, ensuring robust, centralized user configuration management.
  /// </para>
  /// <para>
  /// Key features exposed include programmatic prompting for missing information (such as API keys),
  /// two-way updates between user interface and underlying settings data, as well as
  /// retrieval of values for runtime or business logic use. The interface supports scalable extension for new
  /// preference domains or UI surfaces with minimal code changes, following modern architectural practices
  /// in Delphi VCL projects.
  /// </para>
  /// </remarks>
  Settings: ISettings;

  /// <summary>
  /// Interface for managing and switching the main feature modes (Web Search, File Search Disable, Reasoning)
  /// in the File2knowledgeAI application.
  /// </summary>
  /// <remarks>
  /// <para>
  /// <c>IServiceFeatureSelector</c> defines methods to programmatically toggle the primary modes used for search and
  /// reasoning features. Implementations of this interface ensure consistent state management and provide the
  /// capability to synchronize UI elements (such as toggle buttons or labels) with internal feature logic.
  /// </para>
  /// <para>
  /// This interface is intended to standardize the way in which the application activates, deactivates, or combines
  /// its core functional features at runtime, facilitating both user-driven and code-driven feature changes.
  /// </para>
  /// </remarks>
  ServiceFeatureSelector: IServiceFeatureSelector;

  /// <summary>
  /// Interface for resource editor components providing methods to manage and synchronize
  /// vector resource data and related UI controls in the File2knowledgeAI application.
  /// </summary>
  /// <remarks>
  /// Implementations of this interface are responsible for refreshing the editor view and
  /// re-initializing any file attachments or metadata displayed in the UI.
  /// Typical use cases include updating the visible state after data changes or file operations,
  /// and ensuring consistent synchronization between persistent data and user interface components.
  /// </remarks>
  VectorResourceEditor: IVectorResourceEditor;

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
  FileUploadIdController: IFileUploadIdController;

implementation

end.
