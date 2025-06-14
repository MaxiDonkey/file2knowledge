unit Startup.Context;

interface

{$REGION  'Dev notes : Startup.Context'}

(*
  Unit: Startup.Context

  Purpose:
    Provides a centralized and structured initialization context for application startup in the File2knowledgeAI project.
    Encapsulates core interfaces and procedures such as user interface display, service prompts, resizing logic,
    form presentation, and error handling. Enables configuration-driven bootstrapping and supports
    dependency injection for all key startup services.

  Architecture and Design:
    - Exposes the TStartupContext class, which aggregates interfaces and callbacks required during startup.
    - Supports clean separation of startup concerns and enhances testability by allowing granular injection of dependencies.
    - Promotes flexibility and modularity for customizing application bootstrapping logic.

  Usage:
    - Instantiate TStartupContext with required interfaces and procedures when launching application services or forms.
    - Access provided methods to retrieve associated startup dependencies for use throughout the application initialization process.

  Context:
    Intended for use within modules and components that require well-structured and maintainable startup workflows,
    particularly where reuse and customization of initialization logic are priorities in the File2knowledgeAI ecosystem.

  Conventions follow File2knowledgeAI best practices for modular design, maintainability, and clear documentation.
*)

{$ENDREGION}

uses
  Manager.Intf, System.SysUtils;

type
  /// <summary>
  /// Provides the initialization context for application startup in the File2knowledgeAI architecture.
  /// </summary>
  /// <remarks>
  /// <para>
  /// - <c>TStartupContext</c> centralizes key interfaces and procedures required during the application startup phase.
  /// It enables configuration-driven bootstrapping by encapsulating dependencies needed to present forms, handle errors,
  /// service prompts, display UI components, and perform layout resizing operations.
  /// </para>
  /// <para>
  /// - This class supports dependency injection for core startup activities, ensuring a clean separation of concerns and
  /// enhanced testability of startup workflows. It is designed for flexibility, allowing custom startup behavior by
  /// providing implementations of the interfaces and procedures through its constructor.
  /// </para>
  /// <para>
  /// - Typical usage involves creating an instance of <c>TStartupContext</c> with appropriate interface and callback
  /// parameters when initializing forms or services in File2knowledgeAI modules.
  /// </para>
  /// </remarks>
  /// <param name="ADisplayer">The displayer interface for UI output handling.</param>
  /// <param name="AServicePrompt">The interface responsible for prompting user actions or services at startup.</param>
  /// <param name="AResizeProc">A procedure to execute dynamic window or layout resizing.</param>
  /// <param name="AFormPresenter">A procedure delegate to launch or display the main application form.</param>
  /// <param name="AOnError">A procedure to handle and display errors encountered during startup.</param>
  TStartupContext = class(TInterfacedObject, IStartupContext)
  private
    FDisplayer : IDisplayer;
    FServicePrompt : IServicePrompt;
    FResizeProc : TProc;
    FFormPresenter : TProc;
    FOnError: TProc;
    function GetDisplayer: IDisplayer;
    function GetServicePrompt: IServicePrompt;
    function GetResizeProc: TProc;
    function GetFormPresenter: TProc;
    function GetOnError: TProc;
  public
    /// <summary>
    /// Initializes a new instance of the <c>TStartupContext</c> class with specified service interfaces and startup procedures.
    /// </summary>
    /// <param name="ADisplayer">Provides the user interface display logic at application startup.</param>
    /// <param name="AServicePrompt">Supplies prompt and user interaction capabilities for initial service operations.</param>
    /// <param name="AResizeProc">A procedure reference for handling dynamic layout or window resizing during startup.</param>
    /// <param name="AFormPresenter">A procedure for presenting or launching the main application form.</param>
    /// <param name="AOnError">A procedure reference responsible for error notification and handling at startup.</param>
    /// <remarks>
    /// Use this constructor to inject all required dependencies and customizable procedures needed for the application's startup workflow. This enables flexible initialization, unit testing, and clear separation of startup responsibilities within the File2knowledgeAI project.
    /// </remarks>
    constructor Create(const ADisplayer: IDisplayer;
      const AServicePrompt: IServicePrompt; const AResizeProc: TProc;
      const AFormPresenter: TProc; const AOnError: TProc);
  end;

implementation

{ TStartupContext }

constructor TStartupContext.Create(const ADisplayer: IDisplayer;
  const AServicePrompt: IServicePrompt; const AResizeProc: TProc;
  const AFormPresenter: TProc; const AOnError: TProc);
begin
  inherited Create;
  FDisplayer := ADisplayer;
  FServicePrompt := AServicePrompt;
  FResizeProc := AResizeProc;
  FFormPresenter := AFormPresenter;
  FOnError := AOnError;
end;

function TStartupContext.GetDisplayer: IDisplayer;
begin
  Result := FDisplayer;
end;

function TStartupContext.GetFormPresenter: TProc;
begin
  Result := FFormPresenter;
end;

function TStartupContext.GetOnError: TProc;
begin
  Result := FOnError;
end;

function TStartupContext.GetResizeProc: TProc;
begin
  Result := FResizeProc;
end;

function TStartupContext.GetServicePrompt: IServicePrompt;
begin
  Result := FServicePrompt;
end;

end.
