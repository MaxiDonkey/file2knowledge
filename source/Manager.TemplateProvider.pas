unit Manager.TemplateProvider;

interface

{$REGION  'Dev notes : Manager.TemplateProvider'}

(*
  DESIGN NOTE:
  ============

  This component dynamically manages template loading for the v1/responses endpoint demo.
  - The "AlwaysReloading" mode (see TemplateAllwaysReloading) is ideal during development:
    it reloads template files on every access, making quick iterations easy without restarting the app.
  - The "NeverReloading" mode (see TemplateNeverReloading) is intended for a more typical/stable use,
    where files are loaded just once for performance.

  No advanced caching logic here—this is intentional:
  goal = clarity & simplicity for the community.

*)

{$ENDREGION}

uses
  System.SysUtils, System.IOUtils, Helper.TextFile, Manager.Intf;

const
  TEMPLATE_PATH = '..\..\template';

type
  TTemplateType = (
    main_html,
    js_response,
    js_prompt,
    js_waitfor);

  TTemplateTypeHelper = record Helper for TTemplateType
  private
    const
      FileNames: array[TTemplateType] of string = (
        'InitialHtml.htm',
        'DisplayTemplate.js',
        'PromptTemplate.js',
        'ReasoningTemplate.js'
      );
  public
    function ToString: string;
  end;

  TEdgeInjection = class(TInterfacedObject, ITemplateProvider)
  private
    FInitialHtml: string;
    FDisplayTemplate: string;
    FReasoningTemplate: string;
    FPromptTemplate: string;
    FAlwaysReloading: Boolean;
    FPath: string;
    function LoadTemplate(const FileName: string): string;
    procedure InitializeTemplates;
    function GetInitialHtml: string;
    function GetDisplayTemplate: string;
    function GetReasoningTemplate: string;
    function GetPromptTemplate: string;
    function GetPath(const Path: string; const BaseDir: string = ''): string;
  public
    constructor Create;

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

implementation

{ TEdgeInjection }

constructor TEdgeInjection.Create;
begin
  inherited Create;
  FPath := TEMPLATE_PATH;
  FAlwaysReloading := False;
  InitializeTemplates;
end;

function TEdgeInjection.GetDisplayTemplate: string;
begin
  if FAlwaysReloading then
    FDisplayTemplate := LoadTemplate(js_response.ToString);
  Result := FDisplayTemplate;
end;

function TEdgeInjection.GetInitialHtml: string;
begin
  if FAlwaysReloading then
    FInitialHtml := LoadTemplate(main_html.ToString);
  Result := FInitialHtml;
end;

function TEdgeInjection.GetPath(const Path, BaseDir: string): string;
begin
  if TPath.IsPathRooted(Path) then
    Result := Path
  else
    if not BaseDir.Trim.IsEmpty then
      Result := TPath.GetFullPath(TPath.Combine(BaseDir, Path))
    else
      Result := TPath.GetFullPath(Path);
end;

function TEdgeInjection.GetPromptTemplate: string;
begin
  if FAlwaysReloading then
    FPromptTemplate := LoadTemplate(js_prompt.ToString);
  Result := FPromptTemplate;
end;

function TEdgeInjection.GetReasoningTemplate: string;
begin
  if FAlwaysReloading then
    FReasoningTemplate := LoadTemplate(js_waitfor.ToString);
  Result := FReasoningTemplate;
end;

procedure TEdgeInjection.InitializeTemplates;
begin
  FInitialHtml := LoadTemplate(main_html.ToString);
  FDisplayTemplate := LoadTemplate(js_response.ToString);
  FPromptTemplate := LoadTemplate(js_prompt.ToString);
  FReasoningTemplate := LoadTemplate(js_waitfor.ToString);
end;

function TEdgeInjection.LoadTemplate(const FileName: string): string;
begin
  var GetHtmlPath := TPath.Combine(GetPath(FPath), FileName);

  Result := TFileIOHelper.LoadFromFile(GetHtmlPath);
end;

procedure TEdgeInjection.SetTemplatePath(const Value: string);
begin
  FPath := Value;
end;

procedure TEdgeInjection.TemplateAllwaysReloading(const APath: string);
begin
  {--- Enable lazy loading - do not reload all models here as this would penalize performance }
  if not APath.Trim.IsEmpty then
    FPath := APath;
  FAlwaysReloading := True;
end;

procedure TEdgeInjection.TemplateNeverReloading;
begin
  FAlwaysReloading := False;
end;

{ TTemplateTypeHelper }

function TTemplateTypeHelper.ToString: string;
begin
  Result := FileNames[Self];
end;

end.
