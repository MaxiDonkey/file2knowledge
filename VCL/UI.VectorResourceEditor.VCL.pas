unit UI.VectorResourceEditor.VCL;

interface

{$REGION  'Dev notes : UI.VectorResourceEditor.VCL'}

(*
  Unit: UI.VectorResourceEditor.VCL

  Purpose:
    This unit implements the editor UI and supporting business logic for managing (adding, updating, and linking)
    vector resources in a Delphi VCL application, specifically as part of the File2knowledgeAI project.
    It wires up VCL visual controls (scroll boxes, mask edits, list views, panels, etc.)
    and coordinates the interaction between user input, persistent resource data, and vector store uploads.
    The editor is designed for seamless creation, modification, and validation of resource entries,
    including image management and file attachments, with full live feedback and error handling.

  Note on Architecture and Design Choices:
    In line with the project’s pragmatic and demonstrative focus, this unit does NOT adhere to a strict MVC, MVP,
    or MVVM separation. The business logic and UI events are kept close together for clarity, rapid prototyping,
    and ease of onboarding for developers of all backgrounds.
    - All core logic for validating inputs, managing state, performing file operations, and updating the UI
      is bundled within this class for maximum directness and maintainability in a workshop or demo setting.
    - This approach allows fast iteration and a lower entry threshold, while maintaining modularity and extensibility
      for later refactoring if enterprise patterns or further abstraction are needed.
    - Key helpers, IoC integrations, and styling applications provide structure and testability without rigid layering.

  Usage:
    Instantiate the editor with a TVectorResourceEditorIntroducer record containing your form’s VCL controls.
    All event wiring, style application, state management, and error dialogs are handled automatically.
    Editing, saving, refreshing, and file management are supported out of the box for efficient resource indexing.

  Dependencies:
    - VCL controls: TScrollBox, TImage, TMaskEdit, TListView, TPanel, TSpeedButton, etc.
    - Project units: Model.VectorResource, Manager.Intf, Manager.IoC, JSON.Resource, Manager.WebServices, UI.Styles.VCL,
      and several helper units for dialogs, popups, rounded panels, uploads, etc.
*)

{$ENDREGION}

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, System.JSON, System.IOUtils, System.Generics.Collections,
  System.UITypes, System.Threading,
  Vcl.Graphics, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Mask, Vcl.Buttons,
  Vcl.Forms, Vcl.Themes,  Vcl.Dialogs,
  Model.VectorResource, Manager.Intf, Manager.IoC, JSON.Resource, Manager.WebServices,
  UI.Styles.VCL, Vcl.Menus, Helper.ScrollBoxMouseWheel.VCL, Helper.OpenDialog.VCL,
  Helper.FileUploadID.Dictionary, Helper.PanelRoundedCorners.VCL, Helper.PopupMenu.VCL,
  Helper.ListView.VCL, Manager.FileUploadID.Controler;

const
  TIMEOUTPERFILE = 3000;

type
  TVectorResourceEditorIntroducer = record
    ScrollBox: TScrollBox;
    Image: TImage;
    Name: TMaskEdit;
    Description: TMaskEdit;
    GithubUrl: TMaskEdit;
    GetitUrl: TMaskEdit;
    Files: TListView;
    VectorStoredId: TMaskEdit;
    TrashButton: TSpeedButton;
    ThumbtackButton: TSpeedButton;
    ConfirmationPanel: TPanel;
    ApplyButton: TSpeedButton;
    CancelButton: TSpeedButton;
    GitHubLabel: TLabel;
    GetitLabel: TLabel;
    WarningPanel: TPanel;
    class function Empty: TVectorResourceEditorIntroducer; static;
  end;

  TVectorResourceEditorIntroducerHelper = record Helper for TVectorResourceEditorIntroducer
    function SetScrollBox(Value: TScrollBox): TVectorResourceEditorIntroducer; inline;
    function SetImage(Value: TImage): TVectorResourceEditorIntroducer; inline;
    function SetName(Value: TMaskEdit): TVectorResourceEditorIntroducer; inline;
    function SetDescription(Value: TMaskEdit): TVectorResourceEditorIntroducer; inline;
    function SetGithub(Value: TMaskEdit): TVectorResourceEditorIntroducer; inline;
    function SetGetit(Value: TMaskEdit): TVectorResourceEditorIntroducer; inline;
    function SetFiles(Value: TListView): TVectorResourceEditorIntroducer; inline;
    function SetVectorStored(Value: TMaskEdit): TVectorResourceEditorIntroducer; inline;
    function SetTrashButton(Value: TSpeedButton): TVectorResourceEditorIntroducer; inline;
    function SetThumbtackButton(Value: TSpeedButton): TVectorResourceEditorIntroducer; inline;
    function SetConfirmationPanel(Value: TPanel): TVectorResourceEditorIntroducer; inline;
    function SetApplyButton(Value: TSpeedButton): TVectorResourceEditorIntroducer; inline;
    function SetCancelButton(Value: TSpeedButton): TVectorResourceEditorIntroducer; inline;
    function SetGitHubLabel(Value: TLabel): TVectorResourceEditorIntroducer; inline;
    function SetGetitLabel(Value: TLabel): TVectorResourceEditorIntroducer; inline;
    function SetWarningPanel(Value: TPanel): TVectorResourceEditorIntroducer; inline;
  end;

  /// <summary>
  /// UI and business logic editor for vector resources in the File2knowledgeAI VCL application.
  /// </summary>
  /// <remarks>
  /// Links, manages, and validates a suite of visual controls for editing and organizing vector-based resources,
  /// including support for file uploads, metadata management, live feedback, error handling, and integration
  /// with the vector store. All resource state mutation and persistence are handled here.
  /// This class does <b>not</b> follow strict MVC/MVP/MVVM separation.
  /// Instead, it intentionally combines UI interaction, validation, and business logic to optimize clarity,
  /// prototyping speed, and onboarding. The internal design remains modular and supports future refactoring/extension
  /// as needed.
  /// <param name="Introducer">Structure containing all required controls for editor operations.</param>
  /// "TVectorResourceEditorIntroducer" and "IVectorResourceEditor"
  /// </remarks>
  TVectorResourceEditorVCL = class(TInterfacedObject, IVectorResourceEditor)
  private
    FImagePath: string;
    FOldImagePath: string;
    FModified: Boolean;
    FImageHasChanged: Boolean;
    FListViewHasChanged: Boolean;
    FListViewPopupMenu: TPopupMenu;
    FScrollBox: TScrollBox;
    FImage: TImage;
    FName: TMaskEdit;
    FDescription: TMaskEdit;
    FGithubUrl: TMaskEdit;
    FGetitUrl: TMaskEdit;
    FFiles: TListView;
    FVectorStoredId: TMaskEdit;
    FTrashButton: TSpeedButton;
    FThumbtackButton: TSpeedButton;
    FConfirmationPanel: TPanel;
    FApplyButton: TSpeedButton;
    FCancelButton: TSpeedButton;
    FGitHubLabel: TLabel;
    FGetitLabel: TLabel;
    FWarningPanel: TPanel;

    function GetWaitDelay: Cardinal;
    procedure SetScrollBox(const Value: TScrollBox);
    procedure SetImage(const Value: TImage);
    procedure SetName(const Value: TMaskEdit);
    procedure SetDescription(const Value: TMaskEdit);
    procedure SetGithubUrl(const Value: TMaskEdit);
    procedure SetGetitUrl(const Value: TMaskEdit);
    procedure SetFiles(const Value: TListView);
    procedure SetVectorStored(const Value: TMaskEdit);
    procedure SetTrashButton(const Value: TSpeedButton);
    procedure SetThumbtackButton(const Value: TSpeedButton);
    procedure SetConfirmationPanel(const Value: TPanel);
    procedure SetApplyButton(const Value: TSpeedButton);
    procedure SetCancelButton(const Value: TSpeedButton);
    procedure SetGitHubLabel(const Value: TLabel);
    procedure SetGetitLabel(const Value: TLabel);
    procedure SetWarningPanel(const Value: TPanel);

    function GetModified: Boolean;
    procedure SetModified(const Value: Boolean);
    function GetConfirmationVisible: Boolean;
    procedure SetConfirmationVisible(const Value: Boolean);
    function GetItemIndex: Integer;
  protected
    procedure LoadDataIntoComponents;
    procedure LeftPanelContentRefresh;
    procedure HandleControlExitAndRefocusPrompt(Sender: TObject);
    procedure HandleLeaveForLabels;
    procedure HandleListViewEditing(Sender: TObject; Item: TListItem; var AllowEdit: Boolean);
    procedure HandleListViewAddFilename(Sender: TObject);
    procedure HandleListViewDelete(Sender: TObject);
    procedure HandleImageLoadFromFile(Sender: TObject);
    procedure HandleImageClick(Sender: TObject);
    procedure HandleConfirmationApply(Sender: TObject);
    procedure HandleConfirmationCancel(Sender: TObject);
    procedure HandleChange(Sender: TObject);
    procedure HandleLabelClick(Sender: TObject);
    procedure HandleMaskEditKeyPressed(Sender: TObject; var Key: Char);
    procedure HandleMaskEditExit(Sender: TObject);
    procedure HandleTrashButtonClick(Sender: TObject);
    procedure HandleThumbtackClick(Sender: TObject);
    procedure HandleOnPopup(Sender: TObject);
    procedure HandleRefresh(Sender: TObject);
    procedure HandleWaitForMessage(Sender: TObject);
  public
    constructor Create(const Introducer: TVectorResourceEditorIntroducer);

    /// <summary>
    /// Updates the modified state of the editor based on user interactions and content changes.
    /// </summary>
    /// <returns>True if the editor is now in a modified state; otherwise, False.</returns>
    function UpdateModified: Boolean;

    /// <summary>
    /// Reloads vector resource data into the UI controls and re-initializes the file management context.
    /// </summary>
    procedure Refresh;

    /// <summary>
    /// Saves any changes made in the editor to the persistent resource data and handles file attachment updates.
    /// </summary>
    procedure SaveChanges;

    /// <summary>
    /// Gets or sets the visibility of the confirmation panel in the UI.
    /// </summary>
    property ConfirmationPanelVisible: Boolean Read GetConfirmationVisible write SetConfirmationVisible;

    /// <summary>
    /// Gets the index of the currently selected vector resource item.
    /// </summary>
    property ItemIndex: Integer read GetItemIndex;

    /// <summary>
    /// Gets or sets whether the editor contains unsaved modifications.
    /// </summary>
    property Modified: Boolean read GetModified write SetModified;
  end;

implementation

{ TVectorResourceEditorIntroducer }

class function TVectorResourceEditorIntroducer.Empty: TVectorResourceEditorIntroducer;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

{ TVectorResourceEditorIntroducerHelper }

function TVectorResourceEditorIntroducerHelper.SetApplyButton(
  Value: TSpeedButton): TVectorResourceEditorIntroducer;
begin
  Self.ApplyButton := Value;
  Result := Self;
end;

function TVectorResourceEditorIntroducerHelper.SetCancelButton(
  Value: TSpeedButton): TVectorResourceEditorIntroducer;
begin
  Self.CancelButton := Value;
  Result := Self;
end;

function TVectorResourceEditorIntroducerHelper.SetConfirmationPanel(
  Value: TPanel): TVectorResourceEditorIntroducer;
begin
  Self.ConfirmationPanel := Value;
  Result := Self;
end;

function TVectorResourceEditorIntroducerHelper.SetDescription(
  Value: TMaskEdit): TVectorResourceEditorIntroducer;
begin
  Self.Description := Value;
  Result := Self;
end;

function TVectorResourceEditorIntroducerHelper.SetFiles(
  Value: TListView): TVectorResourceEditorIntroducer;
begin
  Self.Files := Value;
  Result := Self;
end;

function TVectorResourceEditorIntroducerHelper.SetGetit(
  Value: TMaskEdit): TVectorResourceEditorIntroducer;
begin
  Self.GetitUrl := Value;
  Result := Self;
end;

function TVectorResourceEditorIntroducerHelper.SetGetitLabel(
  Value: TLabel): TVectorResourceEditorIntroducer;
begin
  Self.GetitLabel := Value;
  Result := Self;
end;

function TVectorResourceEditorIntroducerHelper.SetGithub(
  Value: TMaskEdit): TVectorResourceEditorIntroducer;
begin
  Self.GithubUrl := Value;
  Result := Self;
end;

function TVectorResourceEditorIntroducerHelper.SetGitHubLabel(
  Value: TLabel): TVectorResourceEditorIntroducer;
begin
  Self.GitHubLabel := Value;
  Result := Self;
end;

function TVectorResourceEditorIntroducerHelper.SetImage(
  Value: TImage): TVectorResourceEditorIntroducer;
begin
  Self.Image := Value;
  Result := Self;
end;

function TVectorResourceEditorIntroducerHelper.SetName(
  Value: TMaskEdit): TVectorResourceEditorIntroducer;
begin
  Self.Name := Value;
  Result := Self;
end;

function TVectorResourceEditorIntroducerHelper.SetScrollBox(
  Value: TScrollBox): TVectorResourceEditorIntroducer;
begin
  Self.ScrollBox := Value;
  Result := Self;
end;

function TVectorResourceEditorIntroducerHelper.SetThumbtackButton(
  Value: TSpeedButton): TVectorResourceEditorIntroducer;
begin
  Self.ThumbtackButton := Value;
  Result := Self;
end;

function TVectorResourceEditorIntroducerHelper.SetTrashButton(
  Value: TSpeedButton): TVectorResourceEditorIntroducer;
begin
  Self.TrashButton := Value;
  Result := Self;
end;

function TVectorResourceEditorIntroducerHelper.SetVectorStored(
  Value: TMaskEdit): TVectorResourceEditorIntroducer;
begin
  Self.VectorStoredId := Value;
  Result := Self;
end;

function TVectorResourceEditorIntroducerHelper.SetWarningPanel(
  Value: TPanel): TVectorResourceEditorIntroducer;
begin
  Self.WarningPanel := Value;
  Result := Self;
end;

{ TVectorResourceEditorVCL }

constructor TVectorResourceEditorVCL.Create(
  const Introducer: TVectorResourceEditorIntroducer);
begin
  inherited Create;
  FImageHasChanged := False;
  FListViewHasChanged := False;

  SetScrollBox(Introducer.ScrollBox);
  SetImage(Introducer.Image);
  SetName(Introducer.Name);
  SetDescription(Introducer.Description);
  SetGithubUrl(Introducer.GithubUrl);
  SetGetitUrl(Introducer.GetitUrl);
  SetFiles(Introducer.Files);
  SetVectorStored(Introducer.VectorStoredId);
  SetTrashButton(Introducer.TrashButton);
  SetThumbtackButton(Introducer.ThumbtackButton);
  SetConfirmationPanel(Introducer.ConfirmationPanel);
  SetApplyButton(Introducer.ApplyButton);
  SetCancelButton(Introducer.CancelButton);
  SetGitHubLabel(Introducer.GitHubLabel);
  SetGetitLabel(Introducer.GetitLabel);
  SetWarningPanel(Introducer.WarningPanel);
end;

function TVectorResourceEditorVCL.GetConfirmationVisible: Boolean;
begin
  Result := FConfirmationPanel.Visible;
end;

function TVectorResourceEditorVCL.GetItemIndex: Integer;
begin
  Result := FileStoreManager.ItemIndex;
end;

function TVectorResourceEditorVCL.GetModified: Boolean;
begin
  Result := FModified;
end;

procedure TVectorResourceEditorVCL.HandleChange(Sender: TObject);
begin
  UpdateModified;
end;

procedure TVectorResourceEditorVCL.HandleConfirmationApply(Sender: TObject);
begin
  SaveChanges;
  HandleWaitForMessage(Sender);
end;

procedure TVectorResourceEditorVCL.HandleConfirmationCancel(Sender: TObject);
begin
  if FImagePath <> FOldImagePath then
    begin
      if FOldImagePath.IsEmpty then
        FImage.Picture.LoadFromFile('..\..\logos\NoImage.png')
      else
        FImage.Picture.LoadFromFile(FOldImagePath);
    end;
  Refresh;
  ConfirmationPanelVisible := False;
  ServicePrompt.SetFocus;
end;

procedure TVectorResourceEditorVCL.HandleImageClick(Sender: TObject);
begin
  FImage.PopupMenu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
end;

procedure TVectorResourceEditorVCL.HandleImageLoadFromFile(Sender: TObject);
var
  FileName: string;
begin
  if FileStoreManager.ImagePath.IsEmpty then
    FileName := '..\..\logos'
  else
    FileName := FileStoreManager.ImagePath;

  if TOpenDialogHelper.Create(nil)
       .Filter('Network Graphics (*.png)|*.png')
       .InitialDir(FileName)
       .Execute(FileName)
    then
      begin
        FImagePath := FileName;
        FImage.Picture.LoadFromFile(FImagePath);
        UpdateModified;
      end;
  ServicePrompt.SetFocus;
end;

procedure TVectorResourceEditorVCL.HandleLabelClick(Sender: TObject);
begin
  if Sender is TLabel then
    begin
      case (Sender as TLabel).Tag of
        1 : TWebUrlManager.Open(FGithubUrl.Text);
        2 : TWebUrlManager.Open(FGetitUrl.Text);
      end;
    end;
  ServicePrompt.SetFocus;
end;

procedure TVectorResourceEditorVCL.HandleControlExitAndRefocusPrompt(Sender: TObject);
begin
  ServicePrompt.SetFocus;
end;

procedure TVectorResourceEditorVCL.HandleLeaveForLabels;
begin
  for var i := 0 to FScrollBox.ControlCount - 1 do
    if FScrollBox.Controls[i] is TLabel then
      (FScrollBox.Controls[i] as TLabel).OnClick := HandleControlExitAndRefocusPrompt;
end;

procedure TVectorResourceEditorVCL.HandleListViewAddFilename(Sender: TObject);
var
  FileName: string;
begin

  if Length(FileStoreManager.Files) >= 5 then
    begin
      AlertService.ShowWarning('You have reached the maximum allowed number of five files.');
      Exit;
    end;

  if not Assigned(FFiles.ItemFocused) then
    FileName := '..\..\data'
  else
    FileName := FFiles.ItemFocused.Caption;

  if TOpenDialogHelper.Create(nil)
       .Filter(
         'text (*.txt)|*.txt|' +
         'markdown (*.md)|*.md|' +
         'text & markdown (*.txt;*.md)|*.txt;*.md|' +
         'PDF files (*.pdf)|*.pdf|' +
         'office document (*.doc;*.docx;*.pptx)|*.doc;*.docx;*.pptx|' +
         'text/x-c (*.c)|*.c|' +
         'text/x-c++ (*.cpp)|*.cpp|' +
         'text/x-csharp (*.cs)|*.cs|' +
         'text/css (*.css)|*.css|' +
         'Msword (*.doc)|*.doc|' +
         'office document (*.docx)|*.docx|' +
         'Golang (*.go)|*.go|' +
         'Html (*.html)|*.html|' +
         'Java (*.java)|*.java|' +
         'Javascript (*.js)|*.js|' +
         'Json (*.json)|*.json|' +
         'Php (*.php)|*.php|' +
         'office document (*.pptx)|*.pptx|' +
         'Python (*.py)|*.py|' +
         'Ruby (*.rb)|*.rb|' +
         'application/x-sh (*.sh)|*.sh|' +
         'text/x-tex (*.tex)|*.tex|' +
         'Typescript (*.ts)|*.ts|')
       .InitialDir(FileName)
       .FilterIndex(3)
       .Execute(FileName)
    then
      if not TListViewHelper.Create(FFiles).CaptionExists(Filename) then
        begin
          FileUploadIdController.AddFile(FileName,
            procedure
            begin
              TListViewHelper.Create(FFiles).Add(FileName);
              FListViewHasChanged := True;
              UpdateModified;
            end)
        end;
  ServicePrompt.SetFocus;
end;

procedure TVectorResourceEditorVCL.HandleListViewDelete(Sender: TObject);
begin
  if not Assigned(FFiles.ItemFocused) then
    Exit;

  var ValidationMessage :=
    Format('Confirm removal of links to the file :'#10#10'%s',
           [FFiles.ItemFocused.Caption]);

  if AlertService.ShowConfirmation(ValidationMessage) = mrYes then
    begin
      FileUploadIdController.DeleteFile(FFiles.ItemFocused.Caption,
        procedure
        begin
          TListViewHelper.Create(FFiles).DeleteSelected;
          FListViewHasChanged := True;
          UpdateModified;
          ServicePrompt.SetFocus;
        end);
    end;
end;

procedure TVectorResourceEditorVCL.HandleListViewEditing(Sender: TObject;
  Item: TListItem; var AllowEdit: Boolean);
begin
  AllowEdit := False;
end;

procedure TVectorResourceEditorVCL.HandleMaskEditExit(Sender: TObject);
begin
  ServicePrompt.SetFocus;
end;

procedure TVectorResourceEditorVCL.HandleMaskEditKeyPressed(Sender: TObject;
  var Key: Char);
begin
  if Ord(Key) = VK_RETURN then
    begin
      ServicePrompt.SetFocus;
      Key := #0;
    end;
end;

procedure TVectorResourceEditorVCL.HandleOnPopup(Sender: TObject);
begin
  FFiles.PopupMenu.Items[4].Enabled := FileStoreManager.VectorStore.Trim.IsEmpty;
end;

procedure TVectorResourceEditorVCL.HandleRefresh(Sender: TObject);
begin
  HandleWaitForMessage(Sender);
end;

procedure TVectorResourceEditorVCL.HandleThumbtackClick(Sender: TObject);
begin
  if FileStoreManager.VectorStore.Trim.IsEmpty or
     (AlertService.ShowConfirmation('Confirm the removal of all links to the files.') = mrNo) then
    begin
      ServicePrompt.SetFocus;
      Exit;
    end;

  for var Item in FileStoreManager.FileUploadIds do
    OpenAI.DeleteVectorStore(FileStoreManager.VectorStore, Item)
      .&Then<string>(
        function (Value: string): string
        begin
          FileStoreManager.VectorStore := '';
          FileStoreManager.SaveToFile;
          Refresh;
          ServicePrompt.SetFocus;
        end)
      .&Catch(
        procedure(E: Exception)
        begin
          AlertService.ShowWarning('Error : ' + E.Message);
          ServicePrompt.SetFocus;
        end);
end;

procedure TVectorResourceEditorVCL.HandleTrashButtonClick(Sender: TObject);
begin
  if FileStoreManager.VectorStore.Trim.IsEmpty or
     (AlertService.ShowConfirmation('Confirm the complete deletion of the vector.') = mrNo) then
    begin
      ServicePrompt.SetFocus;
      Exit;
    end;

  OpenAI.RemoveVectorStore(FileStoreManager.VectorStore)
    .&Then<string>(
      function (Value: string): string
      begin
        FileStoreManager.VectorStore := '';
        FileStoreManager.SaveToFile;
        Refresh;
        ServicePrompt.SetFocus;
      end)
    .&Catch(
      procedure(E: Exception)
      begin
        AlertService.ShowWarning('Error : ' + E.Message);
        ServicePrompt.SetFocus;
      end);
end;

procedure TVectorResourceEditorVCL.HandleWaitForMessage(Sender: TObject);
begin
  FWarningPanel.Visible := FListViewHasChanged;
  FFiles.PopupMenu := nil;
  TTask.Run(
    procedure()
    begin
      Sleep(GetWaitDelay);
      TThread.Queue(nil,
        procedure
        begin
          Refresh;
          FFiles.PopupMenu := FListViewPopupMenu;
          FWarningPanel.Visible := False;
        end)
    end);
  ConfirmationPanelVisible := False;
end;

function TVectorResourceEditorVCL.UpdateModified: Boolean;
begin
  Modified :=
    (FImagePath <> FileStoreManager.ImagePath) or
    (FName.Text <> FileStoreManager.Name) or
    (FDescription.Text <> FileStoreManager.Description) or
    (FGithubUrl.Text <> FileStoreManager.Github) or
    (FGetitUrl.Text <> FileStoreManager.Getit) or
    FImageHasChanged or
    FListViewHasChanged;
  Result := Modified;
end;

procedure TVectorResourceEditorVCL.LeftPanelContentRefresh;
begin
  TTask.Run(
    procedure()
    begin
      Sleep(50);
      TThread.Queue(nil,
        procedure
        begin
          LeftPanelControl.Refresh;
        end)
    end);
end;

procedure TVectorResourceEditorVCL.LoadDataIntoComponents;
begin
  if not FileStoreManager.JSONExists then
    Exit;

  FileStoreManager.Reload;
  FImageHasChanged := False;
  FListViewHasChanged := False;
  FImagePath := FileStoreManager.ImagePath;
  FOldImagePath := FImagePath;
  if not FImagePath.Trim.IsEmpty and FileExists(FImagePath) then
    FImage.Picture.LoadFromFile(FImagePath);
  FName.Text := FileStoreManager.Name;
  FDescription.Text := FileStoreManager.Description;
  FGithubUrl.Text := FileStoreManager.Github;
  FGetitUrl.Text := FileStoreManager.Getit;
  FVectorStoredId.Text := FileStoreManager.VectorStore;
end;

procedure TVectorResourceEditorVCL.Refresh;
begin
  LoadDataIntoComponents;
  FileUploadIdController.InitDictionaries;
  TListViewHelper.Refresh(FFiles);
  UpdateModified;
end;

procedure TVectorResourceEditorVCL.SaveChanges;
begin
  var Resources := TVectorResourceList(FileStoreManager.Resources);

  {--- Process on main datas }
  Resources.Data[ItemIndex].Image := FImagePath;
  Resources.Data[ItemIndex].Name := FName.Text;
  Resources.Data[ItemIndex].Description := FDescription.Text;
  Resources.Data[ItemIndex].Github := FGithubUrl.Text;
  Resources.Data[ItemIndex].Getit := FGetitUrl.Text;

  {--- Process on Datas from ListView }
  if FListViewHasChanged then
    begin
      FileUploadIdController.SaveChanges;
    end;

  FileStoreManager.SaveToFile;
  LeftPanelContentRefresh;
  ServicePrompt.SetFocus;
end;

procedure TVectorResourceEditorVCL.SetApplyButton(const Value: TSpeedButton);
begin
  FApplyButton := Value;
  TAppStyle.ApplyVectorResourceEditorConfirmationButtonStyle(Value,
    procedure
    begin
      FApplyButton.Caption := '&Apply';
      FApplyButton.OnClick := HandleConfirmationApply;
    end);
end;

procedure TVectorResourceEditorVCL.SetCancelButton(const Value: TSpeedButton);
begin
  FCancelButton := Value;
  TAppStyle.ApplyVectorResourceEditorConfirmationButtonStyle(Value,
    procedure
    begin
      FCancelButton.Caption := '&Cancel';
      FCancelButton.OnClick := HandleConfirmationCancel;
    end);
end;

procedure TVectorResourceEditorVCL.SetConfirmationPanel(const Value: TPanel);
begin
  FConfirmationPanel := Value;
  TAppStyle.ApplyVectorResourceEditorConfirmationPanelStyle(Value,
    procedure
    begin
      FConfirmationPanel.Visible := False;
    end);
end;

procedure TVectorResourceEditorVCL.SetConfirmationVisible(const Value: Boolean);
begin
  FConfirmationPanel.Visible := Value;
end;

procedure TVectorResourceEditorVCL.SetDescription(const Value: TMaskEdit);
begin
  FDescription := Value;
  TAppStyle.ApplyVectorResourceEditorMaskEditDarkStyle(Value,
    procedure
    begin
      FDescription.TextHint := 'set description';
      FDescription.MaxLength := 512;

      FDescription.OnChange := HandleChange;
      FDescription.OnKeyPress := HandleMaskEditKeyPressed;
      FDescription.OnExit := HandleMaskEditExit;
    end);
end;

procedure TVectorResourceEditorVCL.SetFiles(const Value: TListView);
begin
  FFiles := Value;
  TAppStyle.ApplyVectorResourceEditorListviewStyle(Value,
    procedure
    begin
      FListViewPopupMenu := TPopupMenuHelper.Create(nil)
        .AddItem('Add filename', '', HandleListViewAddFilename)
        .AddItem('Delete', '', HandleListViewDelete)
        .AddItem('Refresh', '', HandleRefresh)
        .AddItem('-', '', nil)
        .AddItem('Link all to vector store', '' , HandleConfirmationApply)
        .PopupMenu;

      FFiles.PopupMenu := FListViewPopupMenu;
      FFiles.PopupMenu.OnPopup := HandleOnPopup;

      FFiles.OnEditing := HandleListViewEditing;
      FFiles.OnExit := HandleMaskEditExit;
      FFiles.OnClick := HandleControlExitAndRefocusPrompt;
    end);
end;

procedure TVectorResourceEditorVCL.SetGetitUrl(const Value: TMaskEdit);
begin
  FGetitUrl := Value;
  TAppStyle.ApplyVectorResourceEditorMaskEditDarkStyle(Value,
    procedure
    begin
      FGetitUrl.TextHint := 'set GetitUrl url';
      FGetitUrl.OnChange := HandleChange;

      FGetitUrl.OnKeyPress := HandleMaskEditKeyPressed;
      FGetitUrl.OnExit := HandleMaskEditExit;
    end);
end;

procedure TVectorResourceEditorVCL.SetGetitLabel(const Value: TLabel);
begin
  FGetitLabel := Value;
  TAppStyle.ApplyVectorResourceEditorLabelStyle(Value,
    procedure
    begin
      FGetitLabel.Tag := 2;

      FGetitLabel.OnClick := HandleLabelClick;
    end);
end;

procedure TVectorResourceEditorVCL.SetGithubUrl(const Value: TMaskEdit);
begin
  FGithubUrl := Value;
  TAppStyle.ApplyVectorResourceEditorMaskEditDarkStyle(Value,
    procedure
    begin
      FGithubUrl.TextHint := 'set GithubUrl url';
      FGithubUrl.OnChange := HandleChange;

      FGithubUrl.OnKeyPress := HandleMaskEditKeyPressed;
      FGithubUrl.OnExit := HandleMaskEditExit;
    end);
end;

procedure TVectorResourceEditorVCL.SetGitHubLabel(const Value: TLabel);
begin
  FGitHubLabel := Value;
  TAppStyle.ApplyVectorResourceEditorLabelStyle(Value,
    procedure
    begin
      FGitHubLabel.Tag := 1;

      FGitHubLabel.OnClick := HandleLabelClick;
    end);
end;

procedure TVectorResourceEditorVCL.SetImage(const Value: TImage);
begin
  FImage := Value;
  TAppStyle.ApplyVectorResourceEditorImageStyle(Value,
    procedure
    begin
      FImage.PopupMenu := TPopupMenuHelper.Create(nil)
        .AddItem('Load from file', '', HandleImageLoadFromFile)
        .PopupMenu;

      FImage.OnClick := HandleImageClick;
    end);
end;

procedure TVectorResourceEditorVCL.SetModified(const Value: Boolean);
begin
  FModified := Value;
  ConfirmationPanelVisible := Value;
end;

procedure TVectorResourceEditorVCL.SetName(const Value: TMaskEdit);
begin
  FName := Value;
  TAppStyle.ApplyVectorResourceEditorMaskEditTitleStyle(Value,
    procedure
    begin
      FName.TextHint := 'set link name';
      FName.OnChange := HandleChange;

      FName.OnKeyPress := HandleMaskEditKeyPressed;
      FName.OnExit := HandleMaskEditExit;
    end);
end;

procedure TVectorResourceEditorVCL.SetScrollBox(const Value: TScrollBox);
begin
  FScrollBox := Value;
  TAppStyle.ApplyVectorResourceEditorScrollBoxStyle(Value,
    procedure
    begin
      FScrollBox.EnableMouseWheelScroll;
      FScrollBox.OnClick := HandleControlExitAndRefocusPrompt;
      HandleLeaveForLabels;
    end);
end;

procedure TVectorResourceEditorVCL.SetThumbtackButton(
  const Value: TSpeedButton);
begin
  FThumbtackButton := Value;
  TAppStyle.ApplyVectorResourceEditorThumbtackButtonStyle(Value,
    procedure
    begin
      FThumbtackButton.OnClick := HandleThumbtackClick;
    end);
end;

procedure TVectorResourceEditorVCL.SetTrashButton(const Value: TSpeedButton);
begin
  FTrashButton := Value;
  TAppStyle.ApplyVectorResourceEditorTrashButtonStyle(Value,
    procedure
    begin
      FTrashButton.OnClick := HandleTrashButtonClick;
    end);
end;

procedure TVectorResourceEditorVCL.SetVectorStored(const Value: TMaskEdit);
begin
  FVectorStoredId := Value;
  TAppStyle.ApplyVectorResourceEditorMaskEditDarkStyle(Value,
    procedure
    begin
      FVectorStoredId.TextHint := 'no id defined';
      FVectorStoredId.ReadOnly := True;

      FVectorStoredId.OnExit := HandleMaskEditExit;
    end);
end;

procedure TVectorResourceEditorVCL.SetWarningPanel(const Value: TPanel);
begin
  FWarningPanel := Value;
  TAppStyle.ApplyVectorResourceEditorWarningPanelStyle(Value,
    procedure
    begin
      FWarningPanel.SetRoundedCorners(18, 18);
    end);
end;

function TVectorResourceEditorVCL.GetWaitDelay: Cardinal;
begin
  Result := (TIMEOUTPERFILE * FileUploadIdController.DraftCount) * Integer(FListViewHasChanged) + 500;
end;

end.
