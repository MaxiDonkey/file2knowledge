unit Displayer.Edge.VCL;

interface

{$REGION  'Dev notes : Displayer.Edge.VCL'}

(*
  Unit: Displayer.Edge.VCL

  Purpose:
    This unit implements a flexible, browser-based display layer for chat and AI interactions in Delphi VCL applications,
    leveraging Microsoft’s Edge (WebView2) component. It enables rich, styled markdown and reasoning output,
    user prompts, and integrates copy-to-clipboard and JSON messaging for code samples and dynamic UI actions.

  Technical details:
    - Provides TEdgeDisplayerVCL, which encapsulates all logic for rendering and interacting with chat UI via a TEdgeBrowser.
    - Supports both appending of markdown (via Display/DisplayStream) and explicit injection of user prompts and reasoning UI elements.
    - Handles HTML/JS string escaping for seamless injection, and allows custom script hooks for extended rendering.
    - Processes incoming WebView2 JSON messages for UI events (such as copy-to-clipboard on code samples).
    - Asynchronous UI/JS updates are handled with event callback registration for navigation, message reception, and browser initialization.
    - Enables visual refresh features (Clear, Show, Hide, ScrollToEnd/Top) and dynamically tracks prompt count for responsive layouts.
    - Employs robust error-handling and initialization logic to synchronize WebView state and avoid rendering out-of-order.
    - Encapsulates HTML and JavaScript template injection (loading, styling, etc.) for maintainable and extensible UI control.
    - Helper (TEscapeHelper) provides static methods for safe HTML and JS escaping.

  Dependencies:
    - TEdgeBrowser (Vcl.Edge, WebView2 API) for browser engine.
    - Manager.Intf, Manager.IoC for business logic integration and dependency handling.
    - Helper.WebView2.VCL for convenience functions around Edge.
    - System.JSON for message parsing, clipboard and standard Delphi IO for text/code interoperability.
    - System.Threading, System.SysUtils, System.Classes for async and file operations.
    - Vcl.Clipbrd for clipboard integration.
    - Standard Delphi units for VCL controls and messaging.

  Quick start for developers:
    - Instantiate TEdgeDisplayerVCL, binding it to a form-placed TEdgeBrowser and (optionally) a resize event.
    - Use Display/DisplayStream to append markdown or feedback, Prompt to inject new user prompts, and Show/Hide/Clear for basic visibility.
    - All rendering and copy events are handled internally; extend or customize by overriding code copy events or injection templates as needed.
    - Wire up the control with other application logic via Manager.Intf for integrated, context-aware chat interfaces.

  This unit enables modern, interactive, and visually rich chat and output panels within Delphi VCL apps,
  leveraging the flexibility of HTML/CSS/JS while tightly integrating with native Delphi data and event flows.

*)

{$ENDREGION}

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.JSON,
  Winapi.WebView2, Winapi.ActiveX, Vcl.Edge, System.IOUtils,
  Manager.Intf, Manager.IoC, Helper.WebView2.VCL, VCL.Clipbrd,

  System.Net.HttpClient, System.Net.HttpClientComponent, System.NetEncoding;

type
  TCopyActionType = procedure (Lang, Code: string) of object;

  TEscapeHelper = record
  public
    class function EscapeJSString(const S: string): string; static;
    class function EscapeHTML(const S: string): string; static;
  end;

  /// <summary>
  /// Implements a rich, browser-based display layer for chat and AI interactions within Delphi VCL applications.
  /// Leverages Microsoft Edge (WebView2) to provide styled markdown, prompts, reasoning display, clipboard integration,
  /// and dynamic UI actions, all encapsulated for seamless use in modern desktop apps.
  /// </summary>
  /// <remarks>
  /// TEdgeDisplayerVCL is designed for flexible chat and code interaction panels in Delphi VCL.
  /// It enables markdown rendering, user prompt injection, copying code samples, and bidirectional JSON messaging with the browser UI.
  /// The control is event-driven and async-ready, cleanly separating rendering logic from business/data layers and
  /// supporting robust template and event overrides.
  /// </remarks>
  /// <example>
  /// Typical usage:
  /// <code>
  /// var Displayer: TEdgeDisplayerVCL;
  /// Displayer := TEdgeDisplayerVCL.Create(TEdgeBrowserComponent, OnResizeHandler);
  /// Displayer.Display('**Hello!** This is markdown.');
  /// Displayer.Prompt('User typed message');
  /// Displayer.ShowReasoning; // Show AI thinking indicator
  /// Displayer.HideReasoning; // Hide it when done
  /// </code>
  /// </example>
  /// <seealso cref="TEdgeBrowser"/>
  /// <seealso cref="Manager.Intf"/>
  /// <seealso cref="Helper.WebView2.VCL"/>
  /// <seealso cref="TEscapeHelper"/>
  TEdgeDisplayerVCL = class(TInterfacedObject, IDisplayer)
  private
    FBrowser: TEdgeBrowser;
    FInitialNavigation: Boolean;
    FBrowserInitialized: Boolean;
    FStreamContent: string;
    FOnCodeCopied: TCopyActionType;
    FPromptCount: Integer;
    FOnResize: TProc<TObject>;
    FReasoningVisible: Boolean;
    procedure DoNavigationCompleted(Sender: TCustomEdgeBrowser;
      IsSuccess: Boolean; WebErrorStatus: COREWEBVIEW2_WEB_ERROR_STATUS);
    procedure DoWebMessageReceived(Sender: TCustomEdgeBrowser;
      Args: TWebMessageReceivedEventArgs);
    procedure EdgeBrowser1CreateWebViewCompleted(Sender: TCustomEdgeBrowser; AResult: HRESULT);
    procedure SetPromptCount(const Value: Integer);
    function GetPromptCount: Integer;
    function GetHeightAfter(Bias: Integer = 300): Integer;
  protected
    procedure CodeCopyEvent(Lang, Code: string); virtual;
    function ExecuteScript(const Script: string): Boolean;
  public
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
    property PromptCount: Integer read GetPromptCount write SetPromptCount;

    /// <summary>
    /// Initializes a new instance of the <c>TEdgeDisplayerVCL</c> class, binding it to the Edge browser control.
    /// </summary>
    /// <param name="ABrowser">
    /// The Edge browser control component (TEdgeBrowser) used for display.
    /// </param>
    /// <param name="ResizeEvent">
    /// An optional procedure called when the display is resized.
    /// </param>
    constructor Create(const ABrowser: TEdgeBrowser; const ResizeEvent: TProc<TObject>);
  end;

implementation

{ TEdgeDisplayerVCL }

procedure TEdgeDisplayerVCL.BeginUpdateControl;
begin
  SendMessage(FBrowser.Handle, WM_SETREDRAW, WPARAM(False), 0);
end;

procedure TEdgeDisplayerVCL.Clear;
const
  SPACER_DELETE =
    'var el=document.getElementById("edge-spacer");' +
    'if(el){el.remove();}';
begin
  ExecuteScript(SPACER_DELETE);
  FStreamContent := EmptyStr;
  DisplayStream(EmptyStr);
  ResponseTracking.Clear;
  PromptCount := 0;
  Hide;
end;

procedure TEdgeDisplayerVCL.CodeCopyEvent(Lang, Code: string);
begin
  Clipboard.AsText := Code;
end;

constructor TEdgeDisplayerVCL.Create(const ABrowser: TEdgeBrowser;
  const ResizeEvent: TProc<TObject>);
begin
  inherited Create;
  FBrowser := ABrowser;
  FOnResize := ResizeEvent;
  FInitialNavigation := False;
  FBrowserInitialized := False;
  FReasoningVisible := False;
  FOnCodeCopied := CodeCopyEvent;
  FBrowser.OnNavigationCompleted := DoNavigationCompleted;
  FBrowser.OnWebMessageReceived := DoWebMessageReceived;
  FBrowser.OnCreateWebViewCompleted := EdgeBrowser1CreateWebViewCompleted;
  FBrowser.Navigate('about:blank');
  FBrowser.Visible := False;
end;

function TEdgeDisplayerVCL.Display(const AText: string): string;
begin
  try
    {--- Accumulate the Markdown stream }
    FStreamContent := FStreamContent + AText + sLineBreak + sLineBreak;
    Result := FStreamContent;

    {--- Do nothing until the component is ready }
    if not FBrowserInitialized then
      Exit;

    {--- Prepare and inject the JS script for Markdown rendering and adding buttons }
    ExecuteScript(
      Format(TemplateProvider.DisplayTemplate, [TEscapeHelper.EscapeJSString(FStreamContent)])
    );
    ScrollToEnd(False);
  except
    {--- Temporaire pour contrer l'erreur RSS-391 }
  end;
end;

function TEdgeDisplayerVCL.DisplayStream(const AText: string; Scroll: Boolean): string;
begin
  try
    {--- Accumulates the flow }
    FStreamContent := FStreamContent + AText;
    Result := FStreamContent;

    {--- Injects the script }
    ExecuteScript(
      Format(TemplateProvider.DisplayTemplate, [TEscapeHelper.EscapeJSString(FStreamContent)])
    );
    if Scroll then
      ScrollToAfterEnd(GetHeightAfter(300), False);
  except
    {--- Temporaire pour contrer l'erreur RSS-391 }
  end;
end;

procedure TEdgeDisplayerVCL.ScrollToAfterEnd(SizeAfter: Integer; Smooth: Boolean = True);
const
  FREE_SPACE =
    'var spacer = document.getElementById(''edge-spacer'');' +
    'if (!spacer) {' +
    '  spacer = document.createElement(''div'');' +
    '  spacer.id = ''edge-spacer'';' +
    '  document.body.appendChild(spacer);' +
    '}' +
    'spacer.style.height = ''%dpx'';';
  SCROLL_SMOOTH =
    'setTimeout(() => { window.scrollTo({ top: document.body.scrollHeight, behavior: "smooth" }); }, 0);';
  SCROLL =
    'setTimeout(() => { window.scrollTo({ top: document.body.scrollHeight}); }, 0);';
var
  js: string;
  jsscroll: string;
begin
  if SizeAfter > 0 then
    js := Format(FREE_SPACE, [SizeAfter]);

  if Smooth then
    jsscroll := SCROLL_SMOOTH
  else
    jsscroll := SCROLL;

  if js.IsEmpty then
    js := jsscroll
  else
    js := js + jsscroll;

  ExecuteScript(js);
end;

procedure TEdgeDisplayerVCL.ScrollToEnd(Smooth: Boolean = False);
const
  SPACER_DELETE =
    'var el=document.getElementById("edge-spacer");' +
    'if(el){el.remove();}';
  SCROLL_SMOOTH =
    'setTimeout(() => { window.scrollTo({ top: document.body.scrollHeight, behavior: "smooth" }); }, 0);';
  SCROLL =
    'setTimeout(() => { window.scrollTo({ top: document.body.scrollHeight}); }, 0);';
begin
  if Smooth then
    ExecuteScript(SPACER_DELETE + SCROLL_SMOOTH)
  else
    ExecuteScript(SPACER_DELETE + SCROLL);
end;

procedure TEdgeDisplayerVCL.ScrollToTop;
begin
  ExecuteScript('window.scrollTo(0, 0), , behavior: "smooth";');
end;

procedure TEdgeDisplayerVCL.SetPromptCount(const Value: Integer);
begin
  FPromptCount := Value;
  if Assigned(FOnResize) then
    FOnResize(Self);
end;

procedure TEdgeDisplayerVCL.Show;
begin
  if not FBrowser.Visible then
    FBrowser.Visible := True;
end;

procedure TEdgeDisplayerVCL.ShowReasoning;
begin
  if FReasoningVisible then
    Exit;

  FReasoningVisible := True;
  var cpt := 0;
  if FBrowserInitialized then
    while not ExecuteScript(TemplateProvider.ReasoningTemplate) and (cpt < 15) do
      begin
        Inc(cpt);
      end;
  ScrollToAfterEnd(GetHeightAfter(400), False);
end;

procedure TEdgeDisplayerVCL.DoNavigationCompleted(Sender: TCustomEdgeBrowser;
  IsSuccess: Boolean; WebErrorStatus: COREWEBVIEW2_WEB_ERROR_STATUS);
begin
  if not IsSuccess then Exit;
  if not FInitialNavigation then
  begin
    Sender.NavigateToString(TemplateProvider.InitialHtml);
    FInitialNavigation := True;
    Exit;
  end;
end;

procedure TEdgeDisplayerVCL.DoWebMessageReceived(
  Sender: TCustomEdgeBrowser;
  Args: TWebMessageReceivedEventArgs);
var
  WebArgs: ICoreWebView2WebMessageReceivedEventArgs;
  pMsg: PWideChar;
  rawJson: string;
  jsonVal: TJSONValue;
  jo: TJSONObject;
begin
  {--- Retrieves the interface }
  WebArgs := Args as ICoreWebView2WebMessageReceivedEventArgs;

  {--- Calls the Get_WebMessageAsJson method to get the JSON }
  if WebArgs.Get_WebMessageAsJson(pMsg) <> S_OK then
    Exit;
  try
    rawJson := pMsg;
  finally
    CoTaskMemFree(pMsg);
  end;

  {--- Now we can test the "ready" message }
  if SameText(rawJson, '"ready"') then
  begin
    FBrowserInitialized := True;

    {--- Re-injects accumulated content on backspace }
    if FStreamContent <> '' then
      ExecuteScript(
        Format(TemplateProvider.DisplayTemplate, [TEscapeHelper.EscapeJSString(FStreamContent)]));
    Exit;
  end;

  {--- Treat the object directly }
  jsonVal := TJSONObject.ParseJSONValue(rawJson);
  try
    if (jsonVal is TJSONObject) then
    begin
      jo := jsonVal as TJSONObject;
      if jo.GetValue<string>('event') = 'copy' then
      begin
        if Assigned(FOnCodeCopied) then
          FOnCodeCopied(
            jo.GetValue<string>('lang'),
            jo.GetValue<string>('text')
          );
        Exit;
      end;
    end;
  finally
    jsonVal.Free;
  end;
end;

procedure TEdgeDisplayerVCL.EdgeBrowser1CreateWebViewCompleted(
  Sender: TCustomEdgeBrowser; AResult: HRESULT);
var
  Ctrl2      : ICoreWebView2Controller2;
  BaseCtrl   : ICoreWebView2Controller;
  WebView    : ICoreWebView2;
  Col        : TCOREWEBVIEW2_COLOR;
  js         : WideString;
begin
  if AResult <> S_OK then
    Exit;

  {--- Transparent background at controller level (alpha=0) }
  if (Sender as TEdgeBrowser)
     .ControllerInterface
     .QueryInterface(IID_ICoreWebView2Controller2, Ctrl2) = S_OK then
  begin
    Col.A := 0; Col.R := 0; Col.G := 0; Col.B := 0;
    Ctrl2.put_DefaultBackgroundColor(Col);
  end;

  {--- Gets the ICoreWebView2 interface }
  BaseCtrl := (Sender as TEdgeBrowser).ControllerInterface;
  if BaseCtrl.Get_CoreWebView2(WebView) = S_OK then
  begin
    {--- JS to inject (force CSS background) }
    js :=
      'const s=document.createElement("style");' +
      's.textContent=' +
      '"html,body{background-color:#272727!important;}";' +
      'document.head.appendChild(s);';

    {--- we pass PWideChar(js) and nil to avoid having a callback }
    WebView.AddScriptToExecuteOnDocumentCreated(PWideChar(js), nil);
  end;
end;

procedure TEdgeDisplayerVCL.EndUpdateControl;
begin
  SendMessage(FBrowser.Handle, WM_SETREDRAW, WPARAM(True), 0);
  FBrowser.Invalidate;
  FBrowser.Perform(WM_PAINT, 0, 0);
end;

function TEdgeDisplayerVCL.ExecuteScript(const Script: string): Boolean;
begin
  try
    FBrowser.ExecuteScript(Script);
    Exit(True);
  except
    {--- Silent Exception - To avoid RSS-391 error for unpatched 12.1 }
    Exit(False);
  end;
end;

function TEdgeDisplayerVCL.GetHeightAfter(Bias: Integer): Integer;
begin
  Result := FBrowser.Height (*div 2*) - Bias;
  if Result < 0 then
    Result := 0;
end;

function TEdgeDisplayerVCL.GetPromptCount: Integer;
begin
  Result := FPromptCount;
end;

procedure TEdgeDisplayerVCL.Hide;
begin
  FBrowser.Visible := False;
end;

procedure TEdgeDisplayerVCL.HideReasoning;
const
  LOADING = '<div id="loadingBubble" class="chat-bubble assistant loading">Developing a response</div>';
  Script_js = '(() => { const el = document.getElementById("loadingBubble"); if (el) el.remove(); })();';
begin
  if not FBrowserInitialized or not FReasoningVisible then
    Exit;

  ScrollToAfterEnd(GetHeightAfter(400), False);
  var cpt := 0;
  try
    while not ExecuteScript(Script_js) and (cpt <= 15) do
      begin
        Inc(cpt);
      end;

    FStreamContent := StringReplace(FStreamContent, LOADING, '', [rfReplaceAll, rfIgnoreCase]);
  finally
    FReasoningVisible := False;
  end;
end;

procedure TEdgeDisplayerVCL.Prompt(const AText: string);
begin
  if not FBrowserInitialized then
    {--- the browser is not ready yet }
    Exit;

  PromptCount := PromptCount + 1;

  FStreamContent := FStreamContent + sLineBreak +
    Format('<div class="chat-bubble user" style="white-space:pre-wrap;">%s</div>',
           [TEscapeHelper.EscapeHTML(AText)]) +
    sLineBreak;

  {--- Building and injecting the JS that creates the user bubble }
  if not AText.Trim.IsEmpty then
    ExecuteScript(
      Format(TemplateProvider.PromptTemplate, [TEscapeHelper.EscapeJSString(AText)])
    );
end;

{ TEscapeHelper }

class function TEscapeHelper.EscapeHTML(const S: string): string;
const
  Entities: array[0..4] of array[0..1] of string = (
    ('&', '&amp;'),
    ('<', '&lt;'),
    ('>', '&gt;'),
    ('"', '&quot;'),
    ('''', '&#39;')
  );
var
  i: Integer;
begin
  Result := S;
  for i := Low(Entities) to High(Entities) do
    Result := Result.Replace(Entities[i][0], Entities[i][1], [rfReplaceAll]);
end;

class function TEscapeHelper.EscapeJSString(const S: string): string;
var
  i: Integer;
  c: Char;
begin
  Result := '"';
  for i := 1 to Length(S) do
  begin
    c := S[i];
    case c of
      '"': Result := Result + '\"';
      '\': Result := Result + '\\';
      '/': Result := Result + '\/';
      #8: Result := Result + '\b';
      #9: Result := Result + '\t';
      #10: Result := Result + '\n';
      #11: Result := Result + '\v';
      #12: Result := Result + '\f';
      #13: Result := Result + '\r';
    else
      if (Ord(c) < 32) or (Ord(c) > 126) then
        Result := Result + '\u' + IntToHex(Ord(c), 4)
      else
        Result := Result + c;
    end;
  end;
  Result := Result + '"';
end;

end.
