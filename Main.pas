unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.CommCtrl, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Winapi.WebView2, Winapi.ActiveX, Vcl.Edge, Vcl.ExtCtrls, System.Threading, System.UITypes,
  Vcl.ComCtrls, Vcl.Imaging.pngimage, Vcl.Mask, Vcl.Buttons, System.NetEncoding, System.DateUtils,
  REST.Json, REST.Json.Types, System.JSON,


  GenAI, GenAI.Types, Helper.PanelRoundedCorners.VCL, Helper.ScrollBoxMouseWheel.VCL,
  GenAI.Async.Promise, Vcl.Menus, Vcl.WinXCtrls;

const
  PROMPT_MAX_WIDTH = 800;
  PROMPT_MIN_HEIGHT = 128;

type
  TForm1 = class(TForm)
    Panel9: TPanel;
    Panel2: TPanel;
    Panel6: TPanel;
    Button4: TButton;
    Panel7: TPanel;
    Panel8: TPanel;
    ScrollBox1: TScrollBox;
    Panel1: TPanel;
    Panel3: TPanel;
    Panel5: TPanel;
    Panel4: TPanel;
    Panel10: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Panel12: TPanel;
    Panel11: TPanel;
    RichEdit1: TRichEdit;
    Panel13: TPanel;
    Panel14: TPanel;
    Panel15: TPanel;
    Panel16: TPanel;
    EdgeBrowser1: TEdgeBrowser;
    PageControl1: TPageControl;
    FileSearchSheet: TTabSheet;
    Panel17: TPanel;
    Memo1: TMemo;
    HistorySheet: TTabSheet;
    Panel18: TPanel;
    ListView1: TListView;
    Button6: TButton;
    ReasoningSheet: TTabSheet;
    WebSearchSheet: TTabSheet;
    Memo2: TMemo;
    Memo3: TMemo;
    Panel19: TPanel;
    ComboBox1: TComboBox;
    Label4: TLabel;
    SettingsSheet: TTabSheet;
    ScrollBox2: TScrollBox;
    Label5: TLabel;
    ComboBox2: TComboBox;
    Panel20: TPanel;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    Label6: TLabel;
    MaskEdit1: TMaskEdit;
    Label7: TLabel;
    Label8: TLabel;
    MaskEdit2: TMaskEdit;
    Label9: TLabel;
    ComboBox3: TComboBox;
    Label10: TLabel;
    ComboBox4: TComboBox;
    Label11: TLabel;
    Label12: TLabel;
    SpeedButton6: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton4: TSpeedButton;
    SpeedButton5: TSpeedButton;
    Panel21: TPanel;
    Memo4: TMemo;
    Panel22: TPanel;
    Label13: TLabel;
    SpeedButton7: TSpeedButton;
    SpeedButton8: TSpeedButton;
    Panel23: TPanel;
    Label14: TLabel;
    Panel24: TPanel;
    Button3: TButton;
    Button7: TButton;
    VectorStoreSheet: TTabSheet;
    ScrollBox3: TScrollBox;
    Image1: TImage;
    MaskEdit3: TMaskEdit;
    MaskEdit4: TMaskEdit;
    MaskEdit5: TMaskEdit;
    MaskEdit6: TMaskEdit;
    ListView2: TListView;
    Label15: TLabel;
    MaskEdit7: TMaskEdit;
    SpeedButton9: TSpeedButton;
    Label16: TLabel;
    Panel25: TPanel;
    SpeedButton12: TSpeedButton;
    SpeedButton13: TSpeedButton;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label20: TLabel;
    ComboBox5: TComboBox;
    Label21: TLabel;
    ComboBox6: TComboBox;
    Label22: TLabel;
    ComboBox7: TComboBox;
    Label23: TLabel;
    Label24: TLabel;
    Label25: TLabel;
    Label26: TLabel;
    Label27: TLabel;
    MaskEdit8: TMaskEdit;
    MaskEdit9: TMaskEdit;
    Label28: TLabel;
    Label29: TLabel;
    Label30: TLabel;
    ComboBox8: TComboBox;
    Label31: TLabel;
    SpeedButton10: TSpeedButton;
    Panel26: TPanel;
    SpeedButton11: TSpeedButton;
    Label32: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormResize(Sender: TObject);
    procedure Label2Click(Sender: TObject);
  private
    FInit: Boolean;
    procedure InitState;
    procedure RegisterIniAndSettings;
    procedure SetupAndPromptApiKey;
    procedure RegisterOtherServices;
    procedure ResolveServices;
    procedure RegisterStartupContextAndService;
    procedure InitFormConstraintsAndUI;
  public
  end;

var
  Form1: TForm1;

implementation

uses
  System.Math,
  Manager.IoC, Manager.Intf, Manager.TemplateProvider, Manager.Types,
  Startup.Context, Startup.Service, ChatSession.Controller, UserSettings.Persistence,
  Provider.OpenAI,
  CancellationButton.VCL, Displayer.Edge.VCL, Displayer.Memo.VCL,
  UI.AlertService.VCL, UI.PromptEditor.VCL, UI.AnimatedVectorLeftPanel.VCL,
  UI.VectorResourceManager.VCL, UI.Container.VCL, UI.ChatSession.VCL, UI.PageSelector.VCL,
  UI.UserSettings.VCL, UI.PromptSelector.VCL, UI.ServiceFeatureSelector.VCL,
  UI.VectorResourceEditor.VCL, Introducer.UserSettings.VCL, Provider.ResponseIdTracker,
  Model.VectorResource, Manager.FileUploadID.Controler, Manager.WebServices;

{$R *.dfm}

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not HttpMonitoring.IsBusy;
  if not CanClose then
    MessageDLG(
      'Requests are still in progress. Please wait for them to complete before closing the application."',
      TMsgDlgType.mtInformation, [TMsgDlgBtn.mbOK], 0);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  {--- Initializes internal form state variables and flags. }
  InitState;

  {--- Registers persistent ini-based and advanced user settings into IoC. }
  RegisterIniAndSettings;

  {--- Resolves settings instances and prompts for API key if missing. }
  SetupAndPromptApiKey;

  {--- Registers all additional application services and managers into IoC. }
  RegisterOtherServices;

  {--- Resolves registered services into concrete instance variables. }
  ResolveServices;

  {--- Registers startup logic/services and main startup context. }
  RegisterStartupContextAndService;

  {--- Sets form UI constraints, default sizes, and initial UI state. }
  InitFormConstraintsAndUI;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  DisableAlign;
  try
    {--- Retrieve width for displaying the Edge browser and prompting service }
    var Delta := Width - Panel2.Width - Panel4.Width - 10;

    {--- Reposition or resize the "prompting service" component }
    Panel11.Width := Min(Delta - 15, PROMPT_MAX_WIDTH);
    var Margin := (Delta - Panel11.Width) div 2;
    Panel13.Width := Margin;

    {--- Reposition or resize the "Edge browser" component }
    EdgeBrowser1.Width := Min(Delta - 15, PROMPT_MAX_WIDTH);
    Panel15.Width := (Delta - EdgeBrowser1.Width) div 2;

    if EdgeDisplayer.PromptCount = 0 then
      {--- vertical centering when no conversation is detected }
      Panel3.Height := (Height + PROMPT_MIN_HEIGHT) div 2 - 40
    else
      {--- The prompt editor is moved back to the bottom of the window as soon as a conversation is detected}
      Panel3.Height := PROMPT_MIN_HEIGHT;
  finally
    EnableAlign;
  end;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  if FInit then
    begin
      FInit := False;

      {--- Run the startup service }
      IoC.Resolve<IStartupService>.Run;
    end;
end;

procedure TForm1.InitFormConstraintsAndUI;
begin
  {--- Main form constraints }
  var Rect := Screen.MonitorFromWindow(Handle).WorkAreaRect;
  Constraints.MaxWidth := Rect.Width;
  Constraints.MinWidth := 870;
  Constraints.MaxHeight := Rect.Height;
  Constraints.MinHeight := 370;

  {--- Mouse-wheel scrolling helper for TScrollBox
       Allows a TScrollBox to react to the mouse wheel}
  ScrollBox1.EnableMouseWheelScroll;

  {--- Add rounded corners to the panel containing the prompt editor }
  Panel11.SetRoundedCorners(36, 36);

  {--- Dynamically populate a TScrollBox with items from TAppFileStoreManager }
  LeftPanelControl.Refresh;

  {--- Sets the initial active page/tab to the chat session history view on startup. }
  PageControl1.ActivePage := HistorySheet;

  Width := 1540;
  Height := 890;
end;

procedure TForm1.InitState;
begin
  FInit := True;
end;

procedure TForm1.Label2Click(Sender: TObject);
begin
  TWebUrlManager.Open('https://github.com/MaxiDonkey/file2knowledge')
end;

procedure TForm1.RegisterIniAndSettings;
begin
  {--- Registers persistent storage for loading/saving user settings (file-based configuration). }
  IoC.RegisterType<IIniSettings>(
    function: IIniSettings
    begin
      Result := TIniSettings.Create;
    end,
    TLifetime.Singleton
  );

  {--- Registers advanced user settings management (proficiency, model, API key). }
  IoC.RegisterType<ISettings>(
    function: ISettings
    begin
      var Introducer := TSettingsIntroducer.Empty
        .SetScrollBox(ScrollBox2)
        .SetProficiency(ComboBox2)
        .SetProficiencyLabel(Label7)
        .SetPreferenceName(MaskEdit1)
        .SetAPIKey(MaskEdit2)
        .SetSearchModel(ComboBox3)
        .SetSearchModelCost(Label11)
        .SetReasoningModel(ComboBox4)
        .SetReasoningModelCost(Label12)
        .SetReasoningEffort(Combobox5)
        .SetReasoningSummary(Combobox6)
        .SetWebContextSize(Combobox7)
        .SetTimeOut(Combobox8)
        .SetCountry(MaskEdit8)
        .SetCity(MaskEdit9)
        .SetClearResponseButton(SpeedButton11)
        .SetDashBoardLabel(Label32);
      Result := TSettingsVCL.Create(Introducer);
    end,
    TLifetime.Singleton
  );
end;

procedure TForm1.RegisterOtherServices;
begin
  {--- Registers GenAI core interface for prompt execution and vector management. }
  IoC.RegisterType<IGenAI>(
    function: IGenAI
    begin
      Result := TGenAIFactory.CreateInstance(Settings.APIKey);
    end,
    TLifetime.Transient
  );

  {--- Registers alert service for displaying errors, information and confirmations to the user. }
  IoC.RegisterType<IAlertService>(
    function: IAlertService
    begin
      Result := TAlerteServiceVCL.Create;
    end,
    TLifetime.Transient
  );

  {--- Registers central template provider for HTML/JS templates for chat UI and v1/responses endpoint. }
  IoC.RegisterType<ITemplateProvider>(
    function: ITemplateProvider
    begin
      Result := TEdgeInjection.Create;
    end,
    TLifetime.Transient
  );

  {---- Registers browser-based markdown/chat output renderer for user-AI conversations. }
  IoC.RegisterType<IDisplayer>('browser',
    function: IDisplayer
    begin
      Result := TEdgeDisplayerVCL.Create(EdgeBrowser1, FormResize);
    end,
    TLifetime.Transient
  );

  {--- Registers TMemo annotation displayer for file search results. }
  IoC.RegisterType<IAnnotationsDisplayer>('file_search',
    function: IAnnotationsDisplayer
    begin
      Result := TMemoDisplayerVCL.Create(Memo1);
    end,
    TLifetime.Transient
  );

  {--- Registers TMemo annotation displayer for web search outputs. }
  IoC.RegisterType<IAnnotationsDisplayer>('web_search',
    function: IAnnotationsDisplayer
    begin
      Result := TMemoDisplayerVCL.Create(Memo2);
    end,
    TLifetime.Transient
  );

  {--- Registers TMemo annotation displayer for reasoning/AI logs. }
  IoC.RegisterType<IAnnotationsDisplayer>('reasoning',
    function: IAnnotationsDisplayer
    begin
      Result := TMemoDisplayerVCL.Create(Memo3);
    end,
    TLifetime.Transient
  );

  {--- Registers cancellation handler for managing async operation interruption. }
  IoC.RegisterType<ICancellation>(
    function: ICancellation
    begin
      Result := TCancellationVCL.Create(SpeedButton6);
    end,
    TLifetime.Singleton
  );

  {--- Registers panel control manager for the animated left navigation/resources panel. }
  IoC.RegisterType<ILeftPanelControl>(
    function: ILeftPanelControl
    begin
      var Introducer := TLeftPanelControlIntroducer.Empty
        .SetOpenBtn(Button3)
        .SetCloseBtn(Button4)
        .SetNewLeftBtn(Button6)
        .SetNewRightBtn(Button7)
        .SetPanel(Panel2)
        .SetCaptionPanel(Panel24)
        .SetScrollBox(ScrollBox1);
      Result := TLeftPanelControl.Create(Introducer, FormResize);
    end,
    TLifetime.Singleton
  );

  {--- Registers page selector manager for navigation between main application tabs. }
  IoC.RegisterType<ISelector>(
    function: ISelector
    begin
      Result := TSelectorVCL.Create(ComboBox1, PageControl1, Label4);
    end,
    TLifetime.Singleton
  );

  {--- Registers main AI prompt execution and OpenAI vector store operations. }
  IoC.RegisterType<IAIInteractionManager>('openAI',
    function: IAIInteractionManager
    begin
      Result := TOpenAIProvider.Create;
    end,
    TLifetime.Singleton
  );

  {--- Registers service for managing the user prompt editor and async submission. }
  IoC.RegisterType<IServicePrompt>(
    function: IServicePrompt
    begin
      Result := TServicePrompt.Create(RichEdit1, SpeedButton6);
    end,
    TLifetime.Transient
  );

  {--- Registers "manager for the persistent list" of vector AI resources. }
  IoC.RegisterType<IAppFileStoreManager>(
    function: IAppFileStoreManager
    begin
      Result := TVectorResourceVCL.Create;
    end,
    TLifetime.Singleton
  );

  {--- Registers persistent chat/session history manager. }
  IoC.RegisterType<IPersistentChat>(
    function: IPersistentChat
    begin
      Result := TPersistentChat.Create;
    end,
    TLifetime.Singleton
  );

  {--- Retrieves and assigns the singleton persistent chat/session manager instance. }
  PersistentChat := IoC.Resolve<IPersistentChat>;

  {--- Registers main history view for chat session navigation and visualization. }
  IoC.RegisterType<IChatSessionHistoryView>(
    function: IChatSessionHistoryView
    begin
      Result := TChatSessionHistoryViewVCL.Create(ListView1, SpeedButton1, SpeedButton2, Panel20, PersistentChat);
    end,
    TLifetime.Singleton
  );

  {--- Registers v1/responses OpenAI conversation ID tracking for chaining/multi-turn. }
  IoC.RegisterType<IOpenAIChatTracking>(
    function: IOpenAIChatTracking
    begin
      Result := TOpenAIChatTracking.Create(nil);
    end,
    TLifetime.Singleton
  );

  {--- Registers "selector for enabling/disabling" web search, file search, and reasoning }
  IoC.RegisterType<IServiceFeatureSelector>(
    function: IServiceFeatureSelector
    begin
      Result := TServiceFeatureSelector.Create(SpeedButton3, SpeedButton4, SpeedButton5, Label14);
    end,
    TLifetime.Singleton
  );

  {--- Registers prompt selector for managing multi-prompt navigation/history inside the UI. }
  IoC.RegisterType<IPromptSelector>(
    function: IPromptSelector
    begin
      Result := TPromptSelectorVCL.Create(Panel21, Memo4, Label13, SpeedButton7, SpeedButton8);
    end,
    TLifetime.Singleton
  );

  {--- Registers controller for mapping file names to upload IDs in vector resources. }
  IoC.RegisterType<IFileUploadIdController>(
    function: IFileUploadIdController
    begin
      Result := TFileUploadIdController.Create;
    end,
    TLifetime.Singleton
  );

  {--- Registers resource editor for managing and synchronizing vector resource data. }
  IoC.RegisterType<IVectorResourceEditor>(
    function: IVectorResourceEditor
    begin
      var Introducer := TVectorResourceEditorIntroducer.Empty
        .SetScrollBox(ScrollBox3)
        .SetImage(Image1)
        .SetName(MaskEdit3)
        .SetDescription(MaskEdit4)
        .SetGithub(MaskEdit5)
        .SetGetit(MaskEdit6)
        .SetFiles(ListView2)
        .SetVectorStored(MaskEdit7)
        .SetTrashButton(SpeedButton9)
        .SetThumbtackButton(SpeedButton10)
        .SetConfirmationPanel(Panel25)
        .SetApplyButton(SpeedButton12)
        .SetCancelButton(SpeedButton13)
        .SetGitHubLabel(Label17)
        .SetGetitLabel(Label18)
        .SetWarningPanel(Panel26);
      Result := TVectorResourceEditorVCL.Create(Introducer);
    end,
    TLifetime.Singleton
  );
end;

procedure TForm1.RegisterStartupContextAndService;
begin
  {--- Service registration for the startup context }
  IoC.RegisterType<IStartupContext>(
    function: IStartupContext
    begin
      Result := TStartupContext.Create(
        EdgeDisplayer,
        ServicePrompt,
        procedure
        begin
          Self.FormResize(nil);
        end,
        procedure
        begin
          Self.AlphaBlend := False;
        end,
        procedure
        begin
          Application.Terminate;
        end);
    end,
    TLifetime.Singleton
  );

  {--- Service registration for the startup service }
  IoC.RegisterType<IStartupService>(
    function: IStartupService
    begin
      Result := TStartupService.Create(IoC.Resolve<IStartupContext>);
    end,
    TLifetime.Singleton
  );
end;

procedure TForm1.ResolveServices;
begin
  {--- Assigns alert and dialog service for error/info/warning/confirmation messages. }
  AlertService := IoC.Resolve<IAlertService>;

  {--- Assigns central template provider for UI HTML/JS templates. }
  TemplateProvider := IoC.Resolve<ITemplateProvider>;

  {--- Assigns markdown/chat renderer for conversational AI output (Edge/WebView2). }
  EdgeDisplayer := IoC.Resolve<IDisplayer>('browser');

  {--- Assigns annotation/text displayer for file search TMemo presentation. }
  FileSearchDisplayer := IoC.Resolve<IAnnotationsDisplayer>('file_search');

  {--- Assigns annotation/text displayer for web search TMemo presentation. }
  WebSearchDisplayer := IoC.Resolve<IAnnotationsDisplayer>('web_search');

  {--- Assigns annotation/text displayer for AI reasoning/logs TMemo presentation. }
  ReasoningDisplayer := IoC.Resolve<IAnnotationsDisplayer>('reasoning');

  {--- Assigns cancellation manager for async operations. }
  Cancellation := IoC.Resolve<ICancellation>;

  {--- Assigns manager for animated left navigation/resources panel. }
  LeftPanelControl := IoC.Resolve<ILeftPanelControl>;

  {--- Assigns prompt editor and async prompt management service. }
  ServicePrompt := IoC.Resolve<IServicePrompt>;

  {--- Assigns page selector for navigation between main application areas/tabs. }
  Selector := IoC.Resolve<ISelector>;

  {--- Assigns OpenAI/GenAI interaction manager (prompt, file, and vector operations). }
  OpenAI := IoC.Resolve<IAIInteractionManager>('openAI');

  {--- Assigns vector resource list manager (persistent storage of AI resource). }
  FileStoreManager := IoC.Resolve<IAppFileStoreManager>;

  {--- Assigns chat session/history view for navigating/conversational history. }
  ChatSessionHistoryView := IoC.Resolve<IChatSessionHistoryView>;

  {--- Assigns conversation ID tracker (for v1/responses chaining). }
  ResponseTracking := IoC.Resolve<IOpenAIChatTracking>;

  {--- Assigns prompt selector for prompt navigation/history inside the UI. }
  PromptSelector := IoC.Resolve<IPromptSelector>;

  {--- Assigns feature selector for toggling web search, file search, and reasoning modes. }
  ServiceFeatureSelector := IoC.Resolve<IServiceFeatureSelector>;

  {--- Assigns editor for managing and synchronizing vector resource data. }
  VectorResourceEditor := IoC.Resolve<IVectorResourceEditor>;

  {--- Assigns controller for mapping file names to upload IDs in vector resources. }
  FileUploadIdController := IoC.Resolve<IFileUploadIdController>;
end;

procedure TForm1.SetupAndPromptApiKey;
begin
  {--- Assigns persistent storage manager for user and app settings (file-based). }
  IniSettings := IoC.Resolve<IIniSettings>;

  {--- Assigns advanced settings management for UI/user config and API key. }
  Settings := IoC.Resolve<ISettings>;

  {--- Prompts the user for the OpenAI API key if not set, and updates settings. }
  Settings.InputAPIKey;
end;

initialization
  ReportMemoryLeaksOnShutdown := True;
end.
