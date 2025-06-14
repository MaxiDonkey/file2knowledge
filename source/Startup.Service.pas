unit Startup.Service;

interface

{$REGION  'Dev notes : Startup.Service'}

(*
  Unit: Startup.Service

  Purpose:
    Implements the startup orchestration logic for the File2knowledgeAI application.
    Encapsulates procedures required to initialize UI components, verify system prerequisites,
    handle user notifications, and activate interactive services during the application launch phase.

  Architecture and Design:
    - Exposes the TStartupService class, which manages the asynchronous startup
      sequence via the injected IStartupContext interface.
    - Promotes modular startup flows by separating orchestration logic from UI/component
      details, supporting clean dependency injection and testability.
    - Coordinates interface clearing, form presenting, dependency checks, user alerts,
      error handling, and service prompt focus in accordance with File2knowledgeAI best practices.

  Usage:
    - Instantiate TStartupService with a configured IStartupContext instance at application launch.
    - Call Run to perform the full application startup sequence, including error notifications and
      responsive UI setup.

  Context:
    Designed for use in File2knowledgeAI modules/components requiring reliable, maintainable,
    and extensible startup workflows. Follows clear modular design and documentation conventions
    throughout the codebase.
*)

{$ENDREGION}

uses
  System.Threading, System.SysUtils, System.Classes, System.IOUtils, Winapi.Windows,
  Manager.Intf, Startup.Context;

const
  DLL_ISSUE =
    'To ensure full support for the Edge browser, please copy the "WebView2Loader.dll" file into the executable''s directory.'+ sLineBreak +
    'You can find this file in the project''s DLL folder.';

type
  /// <summary>
  /// Implements the startup workflow for services in the File2knowledgeAI application architecture.
  /// </summary>
  /// <remarks>
  /// <para>
  /// <c>TStartupService</c> coordinates application bootstrapping by using the provided startup context. It manages
  /// UI clearing and presentation, essential resource checks, user notifications, form displaying, error handling, and
  /// service prompt initialization in an asynchronous manner.
  /// </para>
  /// <para>
  /// The class leverages dependency injection through the injected <see cref="IStartupContext"/> interface, ensuring
  /// a clear separation of concerns and improved testability.
  /// </para>
  /// <para>
  /// Typical usage involves instantiating <c>TStartupService</c> with a preconfigured <see cref="IStartupContext"/> and then
  /// invoking <see cref="Run"/> to initialize forms, check runtime prerequisites, and prepare the application interface
  /// for user interaction during startup.
  /// </para>
  /// </remarks>
  TStartupService = class(TInterfacedObject, IStartupService)
  strict private
    FContext: IStartupContext;
  public
    /// <summary>
    /// Initializes a new instance of the <c>TStartupService</c> class with the supplied startup context.
    /// </summary>
    /// <param name="AContext">An instance of <see cref="IStartupContext"/> providing interfaces and procedures
    /// required for structured application startup.</param>
    constructor Create(const AContext: IStartupContext);

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

implementation

{ TStartupService }

constructor TStartupService.Create(const AContext: IStartupContext);
begin
  inherited Create;
  FContext := AContext;
end;

procedure TStartupService.Run;
begin
  TTask.Run(
    procedure()
    begin
      Sleep(800);
      TThread.Queue(nil,
        procedure
        begin
          FContext.GetDisplayer.Clear;
          var AlphablendProc := FContext.GetFormPresenter;
          if Assigned(AlphablendProc) then
            AlphablendProc();
          if not FileExists('WebView2Loader.dll') then
            begin
              AlertService.ShowWarning(DLL_ISSUE);
              var TerminateProc := FContext.GetOnError;
              if Assigned(TerminateProc) then
                TerminateProc();
            end;
          ChatSessionHistoryView.FullRefresh(nil);
          FContext.GetServicePrompt.SetFocus;
          var ResizeProc := FContext.GetResizeProc();
          if Assigned(ResizeProc) then
            ResizeProc();
        end);
    end);
end;

end.
