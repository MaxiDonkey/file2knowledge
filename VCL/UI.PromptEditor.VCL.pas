unit UI.PromptEditor.VCL;

interface

{$REGION  'Dev notes : UI.PromptEditor.VCL'}

{*
  Unit: UI.PromptEditor.VCL

  Description:
    This unit handles prompt editing and asynchronous submission
    using a Promise-based mechanism.
    It provides the TServicePrompt class, which encapsulates all end-user logic,
    enabling:
      - Editing, validating, and submitting a prompt.
      - Launching an asynchronous request to generate a response (e.g., via OpenAI).
      - Automatically detecting when the current chat requires naming (first Q&A or default title)
        and assigning a generated chat title on the fly through a secondary async request if necessary.
    User input and validation are managed through event bindings,
    ensuring a consistent and responsive user experience in the UI.

  Key points:
    - Promise-oriented design, allowing long-running tasks without freezing the UI.
    - Open architecture, making it easy to extend styles or submission behaviors.
    - Automatic contextual chat naming support at the start of a new conversation.

*}

{$ENDREGION}

uses
  System.SysUtils, System.Classes, Winapi.Windows, System.Generics.Collections,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.Controls, Vcl.Buttons, Vcl.Dialogs,
  System.Character, System.UITypes,
  Manager.Intf, GenAI.Async.Promise, Manager.Utf8Mapping, Manager.Types, Helper.UserSettings,
  Manager.IoC, Provider.InstructionManager, UI.Styles.VCL;

const
  NEW_CHAT_TITLE = 'New chat ...';
  NAMING_INSTRUCTION =
    'For each prompt and answer provided, generate in ≤6 words the main idea of the “QR” (question-answer).';

type
  /// <summary>
  /// Implements the IServicePrompt interface to manage prompt editing, validation,
  /// and asynchronous submission for AI responses within a VCL application.
  /// </summary>
  /// <remarks>
  /// This class encapsulates the end-user logic, binding to a TRichEdit editor
  /// and a validation button, managing user input, and launching asynchronous
  /// requests to a prompt engine such as OpenAI. It supports automatic chat naming
  /// on the first question-answer exchange or when the default title is present.
  /// </remarks>
  TServicePrompt = class(TInterfacedObject, IServicePrompt)
  private
    ///<summary> Reference to the text editor control used for prompt input. </summary>
    FEditor: TRichEdit;

    ///<summary> Reference to the validation button control. </summary>
    FValidation: TSpeedButton;

    ///<summary>
    /// Stores the accumulated prompt text used during the Deep Research process.
    ///</summary>
    ///<remarks>
    /// Holds intermediate user input between the clarification and final research
    /// phases, allowing multi-step asynchronous analysis before resetting at completion.
    ///</remarks>
    FDeepResearchPrompt: string;

    ///<summary>
    /// Provides access to the system prompt builder used to generate structured instructions.
    ///</summary>
    ///<remarks>
    /// Used to retrieve predefined or dynamic system prompts, particularly for
    /// Deep Research operations, ensuring consistent instruction formatting
    /// across asynchronous requests.
    ///</remarks>
    FSystemPromptBuilder: ISystemPromptBuilder;

    procedure SetEditor(const Value: TRichEdit);
    procedure SetValidation(const Value: TSpeedButton);
    function GetText: string;
    procedure SetText(const Value: string);
    procedure SetEvents(Component: TControl);

    ///<summary> Determines whether the current chat requires automatic naming. </summary>
    ///<returns> True if naming is required; otherwise, False. </returns>
    function NeedToName: Boolean;

    ///<summary> Prepares the naming prompt combining the prompt and response text. </summary>
    ///<param name="Value"> Incoming response text. </param>
    ///<param name="Text"> Original prompt text. </param>
    ///<returns> A formatted string used to request automatic chat naming. </returns>
    function PrepareNamingPromt(const Value, Text: string): string;

    /// <summary> Gets the instruction text used during automatic naming. </summary>
    function GetNamingInstructions: string;

    /// <summary>
    /// Handles the main asynchronous prompt submission process.
    /// </summary>
    /// <param name="Sender">
    /// The control that triggered the execution.
    /// </param>
    /// <remarks>
    /// Validates file and vector-store linkage, then sends the user prompt asynchronously
    /// through <c>OpenAI.Execute</c>. If chat naming is required, a secondary asynchronous
    /// request generates and applies a title using <c>OpenAI.ExecuteSilently</c>.
    /// Errors are caught and displayed, and focus is restored to the editor.
    /// </remarks>
    procedure HandleMainProcess(Sender: TObject);

    /// <summary>
    /// Handles the asynchronous submission process for Deep Research mode.
    /// </summary>
    /// <param name="Sender">
    /// The control that triggered the execution.
    /// </param>
    /// <remarks>
    /// Manages a two-phase Deep Research workflow. The first submission sends the initial
    /// clarifying request via <c>OpenAI.ExecuteClarifying</c>. The second combines the
    /// accumulated prompt with generated instructions and executes an in-depth request
    /// using <c>OpenAI.ExecuteSilently</c>. If naming is required, an additional
    /// asynchronous call generates and applies a chat title. Errors are handled gracefully,
    /// reasoning indicators are updated accordingly, and focus is returned to the editor.
    /// </remarks>
    procedure HandleDeepResearchProcess(Sender: TObject);

  protected
    ///<summary> Handles key down events in the editor control. </summary>
    ///<param name="Sender"> The source of the event. </param>
    ///<param name="Key"> The key code pressed. </param>
    ///<param name="Shift"> The state of shift keys. </param>
    procedure HandleKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState); virtual;

    ///<summary> Executes the prompt submission asynchronously when triggered.</summary>
    ///<param name="Sender"> The source of the execution event. </param>
    procedure Execute(Sender: TObject);

    /// <summary>
    /// Validates whether the main process can be executed.
    /// </summary>
    /// <remarks>
    /// Checks the current file and vector-store linkage. If the linkage is broken,
    /// prompts the user for confirmation to reestablish it. When confirmed and files
    /// are available, triggers a vector-store ping before proceeding. Returns True
    /// if execution can continue, otherwise False.
    /// </remarks>
    function CanExecute: Boolean;

  public
    ///<summary> Constructor for TServicePrompt requiring editor and validation button. </summary>
    ///<param name="AEditor"> The TRichEdit component used for input. </param>
    ///<param name="AButtonValidation"> The button to validate and submit the prompt. </param>
    constructor Create(const AEditor: TRichEdit; const AButtonValidation: TSpeedButton);

    ///<summary>
    /// Clears the current prompt text from the editor.
    /// </summary>
    procedure Clear;

    ///<summary>
    /// Sets focus to the prompt editor control.
    ///</summary>
    procedure SetFocus;

    ///<summary>
    /// Gets the bound editor control.
    ///</summary>
    property Editor: TRichEdit read FEditor;

    ///<summary>
    /// Gets or sets the prompt text.
    ///</summary>
    property Text: string read GetText write SetText;

    ///<summary>
    /// Gets the validation button control.
    ///</summary>
    property Validation: TSpeedButton read FValidation;
  end;

implementation

{ TServicePrompt }

function TServicePrompt.CanExecute: Boolean;
begin
  if sf_fileSearchDisabled in ServiceFeatureSelector.FeatureModes then
    Exit(True);

  Result := AlertService.ShowConfirmation(
      'Broken link between the file and the vectore store.'#10'Confirm linkage ?') = mrYes;
  if Result then
    begin
      if Length(FileStoreManager.Files) > 0 then
        begin
          FileStoreManager.PingVectorStore
            .&Then<string>(
              function (Value: string): string
              begin
                VectorResourceEditor.Refresh;
                Execute(nil);
              end);
          Exit(False);
        end;
    end
end;

procedure TServicePrompt.Clear;
begin
  Text := EmptyStr;
end;

constructor TServicePrompt.Create(const AEditor: TRichEdit;
  const AButtonValidation: TSpeedButton);
begin
  inherited Create;
  SetEditor(AEditor);
  SetValidation(AButtonValidation);

  IoC.RegisterType<ISystemPromptBuilder>('PromptBuilder',
    function: ISystemPromptBuilder
    begin
      Result := TSystemPromptBuilder.Create;
    end,
    TLifetime.Singleton
  );

  FSystemPromptBuilder := IoC.Resolve<ISystemPromptBuilder>('PromptBuilder');
end;

procedure TServicePrompt.Execute(Sender: TObject);
{$REGION 'dev note'}
(*
  Developer note:
    The Execute method acts as the central entry point for submitting user prompts.
    It determines the execution path based on the currently selected AI model.

    - If the active model is identified as a "Deep Research" model
      (checked via Helper.UserSettings.IsDeepResearchModel), the method
      delegates execution to HandleDeepResearchProcess, which performs
      a two-phase clarification and research flow.
    - Otherwise, it routes the request to HandleMainProcess for standard
      single-phase prompt execution.

    This design cleanly separates logic between normal prompt processing
    and Deep Research workflows while maintaining a unified entry point
    for UI event bindings (keyboard or button triggers).
*)
{$ENDREGION}
begin
  var isDeepResearch := Helper.UserSettings.IsDeepResearchModel(Settings.SearchModel);

  if isDeepResearch then
    HandleDeepResearchProcess(Sender)
  else
    HandleMainProcess(Sender);
end;

function TServicePrompt.GetNamingInstructions: string;
begin
  Result := NAMING_INSTRUCTION;
end;

function TServicePrompt.GetText: string;
begin
  Result := string(TUtf8Mapping.CleanTextAsUTF8(FEditor.Lines.Text));
end;

procedure TServicePrompt.HandleKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case key of
    VK_RETURN:
      begin
        if ssShift in Shift then
          Text.Insert(FEditor.SelStart, #10)
        else
          begin
            Key := 0;
            FEditor.SelStart := Text.Length;
            Execute(Self);
          end;
      end;
    Ord('N'):
      begin
        if ssCtrl in Shift then
          LeftPanelControl.HandleNew(Sender);
      end;
    VK_ESCAPE:
      begin
        LeftPanelControl.HandleNew(Sender);
      end;
    VK_F1:
      begin
        Selector.ShowPage(psFileSearch);
      end;
    VK_F2:
      begin
        Selector.ShowPage(psWebSearch);
      end;
    VK_F3:
      begin
        Selector.ShowPage(psReasoning);
      end;
    VK_F5:
      begin
        ServiceFeatureSelector.SwitchWebSearch;
      end;
    VK_F6:
      begin
        ServiceFeatureSelector.SwitchDisableFileSearch
      end;
    VK_F7:
      begin
        ServiceFeatureSelector.SwitchReasoning;
      end;
    VK_F8:
      begin
        Selector.ShowPage(psSettings);
      end;
    VK_F9:
      begin
        LeftPanelControl.HandleSwitch(Sender);
      end;
  end;
end;

procedure TServicePrompt.HandleMainProcess(Sender: TObject);
var
  Promise: TPromise<string>;
begin
  FDeepResearchPrompt := EmptyStr;

  if FileStoreManager.VectorStore.Trim.IsEmpty and not CanExecute then
    Exit;

  EdgeDisplayer.Show;
  var Prompt := TUtf8Mapping.CleanTextAsUTF8(FEditor.Lines.Text);
  if not string(Prompt).Trim.IsEmpty then
    begin
      Promise := OpenAI.Execute(Prompt);

      if NeedToName then
        begin
          Promise
            .&Then<string>(
              function (Value: string): string
              begin
                Result := PrepareNamingPromt(Value, Text);
              end)
            .&Then(
              function (Value: string): TPromise<string>
              begin
                {--- Find a fileName }
                Result := OpenAI.ExecuteSilently('gpt-4.1-nano', Value, GetNamingInstructions);
              end)
            .&Then<string>(
              function (Value: string): string
              begin
                PersistentChat.CurrentChat.ApplyTitle(Value);
                PersistentChat.SaveToFile;
                ChatSessionHistoryView.Refresh(nil);
              end)
            .&Catch(
              procedure(E: Exception)
              begin
                AlertService.ShowError(E.Message);
              end);
        end;
    end;
  SetFocus;
end;

procedure TServicePrompt.HandleDeepResearchProcess(Sender: TObject);
begin
  {--- We are keeping the stored files to stay in line with the philosophy of the POC. }
  if FileStoreManager.VectorStore.Trim.IsEmpty and not CanExecute then
    Exit;

  EdgeDisplayer.Show;
  var Prompt := TUtf8Mapping.CleanTextAsUTF8(FEditor.Lines.Text);
  if not string(Prompt).Trim.IsEmpty then
    begin
      if FDeepResearchPrompt.IsEmpty then
        begin
          FDeepResearchPrompt := Prompt;
          OpenAI.ExecuteClarifying(Prompt)
            .&Catch(
              procedure(E: Exception)
                begin
                  AlertService.ShowError(E.Message);
                end);
        end
      else
        begin
          var Instructions := FSystemPromptBuilder.GetDeepReseachInstructions;
          FDeepResearchPrompt := FDeepResearchPrompt + Prompt;
          Clear;
          var Promise := OpenAI.ExecuteSilently('gpt-4.1-nano', FDeepResearchPrompt, Instructions);
          EdgeDisplayer.ShowReasoning;

          Promise
            .&Then<string>(
              function (Value: string): string
              begin
                Result := Value;
                EdgeDisplayer.HideReasoning;
              end)
            .&Catch(
              procedure(E: Exception)
              begin
                AlertService.ShowError(E.Message);
                EdgeDisplayer.HideReasoning;
                FDeepResearchPrompt := EmptyStr;
              end);

          Promise
            .&Then<string>(
              function (Value: string): string
              begin
                var DeepPromise := OpenAI.Execute(FDeepResearchPrompt, Value);

                if NeedToName then
                  begin
                    DeepPromise
                      .&Then<string>(
                        function (Value: string): string
                        begin
                          Result := PrepareNamingPromt(Value, Text);
                        end)
                      .&Then(
                        function (Value: string): TPromise<string>
                        begin
                          {--- Find a fileName }
                          Result := OpenAI.ExecuteSilently('gpt-4.1-nano', Value, GetNamingInstructions);
                        end)
                      .&Then<string>(
                        function (Value: string): string
                        begin
                          PersistentChat.CurrentChat.ApplyTitle(Value);
                          PersistentChat.SaveToFile;
                          ChatSessionHistoryView.Refresh(nil);
                        end)
                      .&Catch(
                        procedure(E: Exception)
                        begin
                          AlertService.ShowError(E.Message);
                        end);
                  end;
                FDeepResearchPrompt := EmptyStr;
              end);
        end;
    end;
  SetFocus;
end;

function TServicePrompt.NeedToName: Boolean;
begin
  if not Assigned(PersistentChat.CurrentChat) then
    Exit(False);

  Result := (Length(PersistentChat.CurrentChat.Data) = 1) or
            (PersistentChat.CurrentChat.Title = NEW_CHAT_TITLE);
end;

function TServicePrompt.PrepareNamingPromt(const Value, Text: string): string;
begin
  Result := Format('Question: %s'#10'Response: %s', [Text, Value]);
end;

procedure TServicePrompt.SetEditor(const Value: TRichEdit);
begin
  FEditor := Value;
  TAppStyle.ApplyPromptEditorRichEditStyle(Value,
    procedure
    begin
      FEditor.EditMargins.Left := 16;
      FEditor.EditMargins.Right := 8;
      SetEvents(FEditor);
    end);
end;

procedure TServicePrompt.SetEvents(Component: TControl);
begin
  if not Assigned(Component) then
    Exit;

  if Component is TSpeedButton  then
    begin
      TButton(Component).OnClick := Execute;
    end
  else
  if Component is TRichEdit then
    begin
      TRichEdit(Component).OnKeyDown := HandleKeyDown;
    end;
end;

procedure TServicePrompt.SetFocus;
begin
  FEditor.SetFocus;
end;

procedure TServicePrompt.SetText(const Value: string);
begin
  FEditor.Text := Value;
end;

procedure TServicePrompt.SetValidation(const Value: TSpeedButton);
begin
  FValidation := Value;
  TAppStyle.ApplyPromptEditorButtonStyle(Value,
    procedure
    begin
      SetEvents(FValidation);
    end);
end;

end.
