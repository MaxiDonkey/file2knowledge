unit UI.ChatSession.VCL;

interface

{$REGION  'Dev notes : UI.ChatSession.VCL'}

(*
  Unit: UI.ChatSession.VCL

  Purpose:
    Provides the visual layer and controller logic for chat session history management in the File2knowledgeAI project.
    This unit centralizes the UI workflow for browsing, editing, deleting, and organizing persistent multi-turn chat
    histories within a Delphi VCL application, connecting strongly with persistent storage backends.

  Architecture and Design:
    - Exposes the TChatSessionHistoryViewVCL class, responsible for rendering and maintaining interactive chat
      session lists, column sorting, batch and in-place editing, and synchronized state between UI and
      backend session store.
    - Integrates VCL ListView, Button, and Panel controls with rich event handling for operations such as
      batch deletion, inline editing, annotation updates, and context menu commands.
    - Adopts File2knowledgeAI project conventions for extensible, robust, and user-friendly dialog history management.

  Usage:
    - Create a TChatSessionHistoryViewVCL instance, supplying ListView and control references along with
      the persistent chat session interface.
    - Invoke methods like FullRefresh, Refresh, and Repaint to synchronize and update the UI based on
      backend state or user actions.
    - Use public controller methods to support annotation display, batch operations, or to coordinate
      with other modules such as prompt/response viewing and reasoning panels.

  Context:
    This unit is designed for scenarios requiring consistent, reliable, and traceable multi-turn session presentation
    and management—essential for advanced OpenAI workflow support and conversational chaining logic as
    promoted by File2knowledgeAI.

  Conventions follow File2knowledgeAI UI, chaining, and session storage best practices.
*)

{$ENDREGION}

uses
  Winapi.Windows, Winapi.ShellAPI,
  System.SysUtils, System.Classes, System.Threading, System.DateUtils, System.IOUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.ComCtrls, Vcl.Buttons, Vcl.ExtCtrls, Vcl.Menus, Vcl.Forms,
  Manager.Intf, ChatSession.Controller, UI.Styles.VCL, Helper.PopupMenu.VCL;

type
  /// <summary>
  /// Provides a VCL-based view and management interface for the chat session history within the File2knowledgeAI application.
  /// </summary>
  /// <remarks>
  /// <para>
  /// <c>TChatSessionHistoryViewVCL</c> encapsulates all visual and logical interactions for browsing, editing, renaming,
  /// deleting, and persisting chat sessions using a ListView and associated UI controls in a Delphi VCL environment.
  /// </para>
  /// <para>
  /// The class integrates tightly with persistent storage backends (via <c>IPersistentChat</c>) and offers advanced
  /// features such as batch deletion, renaming, sortable and refreshable history lists, and in-place annotation display.
  /// </para>
  /// <para>
  /// This implementation is a key part of the user-facing conversation management, supporting robust and user-friendly
  /// manipulation of multi-turn chat session records.
  /// </para>
  /// <para>
  /// Conventions and architectural guidelines follow File2knowledgeAI and OpenAI chaining best practices, ensuring consistency
  /// and extensibility.
  /// </para>
  /// </remarks>
  TChatSessionHistoryViewVCL = class(TInterfacedObject, IChatSessionHistoryView)
  private
    FListView: TListView;
    FOkButton: TSpeedButton;
    FCancelButton: TSpeedButton;
    FileNameCol: TListColumn;
    DateCol: TListColumn;
    FSortColumn: Integer;
    FSortAscending: Boolean;
    FPersistentChat: IPersistentChat;
    FAllowEdit: Boolean;
    FSelected: TChatSession;
    FBtnPanel: TPanel;
    procedure ListViewCompare(Sender: TObject; Item1, Item2: TListItem;
      Data: Integer; var Compare: Integer);
    procedure SetListView(const Value: TListView);
    procedure SetOkButton(const Value: TSpeedButton);
    procedure SetCancelButton(const Value: TSpeedButton);
    procedure SetBtnPanel(const Value: TPanel);
    procedure HideButtons;
    procedure ShowButtons;
    procedure SortInitialize;
    procedure InternalSort(Sender: TObject);
    procedure DeleteSelected;
    procedure ConfigureListViewProperties;
    procedure ConfigureListViewColumns;
    procedure ConfigureListViewEvents;
    procedure ItemRepaint(const Value: TChatTurn);
  protected
    procedure HandleJsonEdition(Sender: TObject);
    procedure HandleRename(Sender: TObject);
    procedure HandleDelete(Sender: TObject);
    procedure HandleOk(Sender: TObject);
    procedure HandleCancel(Sender: TObject);
    procedure HandleListView1KeyPress(Sender: TObject; var Key: Char);
    procedure HandleColumnClick(Sender: TObject; Column: TListColumn);
    procedure HandleClick(Sender: TObject);
    procedure HandleEditing(Sender: TObject; Item: TListItem; var AllowEdit: Boolean);
    procedure HandleEdited(Sender: TObject; Item: TListItem; var S: string);
    procedure HandleDeletion(Sender: TObject; Item: TListItem);
    procedure HandleCancelEdit(Sender: TObject; Item: TListItem);
  public
    /// <summary>
    /// Initializes a new instance of <c>TChatSessionHistoryViewVCL</c> with the specified UI components and chat persistence interface.
    /// </summary>
    /// <param name="AListView">The ListView control to display the chat session history.</param>
    /// <param name="AOkButton">The button control used to confirm actions like deletion.</param>
    /// <param name="ACancelButton">The button control used to cancel ongoing actions.</param>
    /// <param name="ABtnPanel">The panel containing Ok and Cancel buttons for batch operations.</param>
    /// <param name="PersistentChat">Provides persistent storage for chat sessions.</param>
    constructor Create(const AListView: TListView; const AOkButton, ACancelButton: TSpeedButton;
      const ABtnPanel: TPanel; const PersistentChat: IPersistentChat);

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

implementation

uses
  System.Math;

{ TChatSessionHistoryViewVCL }

procedure TChatSessionHistoryViewVCL.ConfigureListViewColumns;
begin
  FListView.Columns.ClearAndResetID;

  FileNameCol := FListView.Columns.Add;
  FileNameCol.Caption := 'Round title';
  FileNameCol.AutoSize := False;
  FileNameCol.Width := FListView.Width;
  FileNameCol.Alignment := taLeftJustify;

  DateCol := FListView.Columns.Add;
  DateCol.Caption := 'Update date';
  DateCol.AutoSize := False;
  DateCol.Width := 160;
  DateCol.Alignment := taCenter;
end;

procedure TChatSessionHistoryViewVCL.ConfigureListViewEvents;
begin
  FListView.OnKeyPress := HandleListView1KeyPress;
  FListView.OnColumnClick := HandleColumnClick;
  FListView.OnClick := HandleClick;
  FListView.OnEdited := HandleEdited;
  FListView.OnEditing := HandleEditing;
  FListView.OnCancelEdit := HandleCancelEdit;
  FListView.OnCompare := ListViewCompare;
end;

procedure TChatSessionHistoryViewVCL.ConfigureListViewProperties;
begin
  {--- Properties }
  FListView.ViewStyle := vsReport;
  FListView.TileOptions.Width := FListView.Width;
  FListView.TileOptions.SizeType := tstFixedWidth;
  FListView.PopupMenu := TPopupMenuHelper.Create(nil)
    .AddItem('JSON &edition', '', HandleJsonEdition)
    .AddItem('&Rename',       '', HandleRename)
    .AddItem('Delete',        '',  HandleDelete)
    .PopupMenu;
  FListView.ShowColumnHeaders := True;
  FListView.RowSelect := True;
  FListView.ShowWorkAreas := True;
  FListView.ViewStyle := vsReport;
end;

constructor TChatSessionHistoryViewVCL.Create(const AListView: TListView;
  const AOkButton, ACancelButton: TSpeedButton; const ABtnPanel: TPanel;
  const PersistentChat: IPersistentChat);
begin
  inherited Create;
  FPersistentChat := PersistentChat;
  SetListView(AListView);
  SetOkButton(AOkButton);
  SetCancelButton(ACancelButton);
  SetBtnPanel(ABtnPanel);
  SortInitialize;
end;

procedure TChatSessionHistoryViewVCL.DeleteSelected;
begin
  {--- Flag used to identify the screenplay cleaning }
  var Matched := false;

  {--- Delete checked items }
  for var i := FListView.Items.Count - 1 downto 0 do
    begin
      var Item := FListView.Items[i];
      if Item.Checked then
        begin
          if not Matched then
            begin
              Matched := TChatSession(Item.Data) = PersistentChat.CurrentChat;
              if Matched then
                begin
                  for var Turn in PersistentChat.CurrentChat.Data do
                    OpenAI.DeleteResponse(Turn.Id);
                end;
            end;
          HandleDeletion(nil, Item);
        end;
    end;

  {--- Export conversations to JSON }
  PersistentChat.SaveToFile;

  {--- screen display clear if necessary }
  if Matched then
    LeftPanelControl.HandleNew(nil);
end;

procedure TChatSessionHistoryViewVCL.FullRefresh(Sender: TObject);
begin
  FPersistentChat.LoadFromFile;
  Refresh(Sender);
end;

procedure TChatSessionHistoryViewVCL.HandleCancel(Sender: TObject);
begin
  try
    {--- uncheck the check boxes }
    for var Item in FListView.Items do
      Item.Checked := False;

    {-- Hide th ok and cancel button }
    HideButtons;

    {--- Hide the check boxes }
    FListView.Checkboxes := False;
  finally
    ServicePrompt.SetFocus;
  end;
end;

procedure TChatSessionHistoryViewVCL.HandleCancelEdit(Sender: TObject;
  Item: TListItem);
begin
  HandleCancel(Sender);
end;

procedure TChatSessionHistoryViewVCL.HandleClick(Sender: TObject);
begin
  try
    if Assigned(FListView.Selected) then
      begin
        if PersistentChat.CurrentChat <> FListView.Selected.Data then
          begin
            PersistentChat.CurrentChat := FListView.Selected.Data;
            Repaint(Sender);
          end;
      end;
  finally
    ServicePrompt.SetFocus;
  end;
end;

procedure TChatSessionHistoryViewVCL.HandleColumnClick(Sender: TObject;
  Column: TListColumn);
begin
  try
    if FSortColumn = Column.Index then
      FSortAscending := not FSortAscending
    else
      begin
        FSortColumn := Column.Index;
        FSortAscending := True;
      end;

    try
      FListView.CustomSort(nil, FSortColumn);
    except
    end;
  finally
    ServicePrompt.SetFocus;
  end;
end;

procedure TChatSessionHistoryViewVCL.HandleDelete(Sender: TObject);
begin
  try
    {--- Open Deletion mode: show the ok and cancel button }
    ShowButtons;

    {--- Hide the check boxes }
    FListView.Checkboxes := True;
  finally
    ServicePrompt.SetFocus;
  end;
end;

procedure TChatSessionHistoryViewVCL.HandleDeletion(Sender: TObject; Item: TListItem);
begin
  {--- This message will be permanently removed from persistent storage and the OpenAI dashboard. }
  PersistentChat.Data.Delete(Item.Data,
    procedure (Value: string)
    begin
      {--- remove from the OpenAI dashboard }
      OpenAI.DeleteResponse(Value);
    end);

  {--- Remove the message from the ListView }
  var Index := FListView.Items.IndexOf(Item);
  if Index > -1 then
    FListView.Items.Delete(Index);
end;

procedure TChatSessionHistoryViewVCL.HandleEdited(Sender: TObject; Item: TListItem;
  var S: string);
begin
  try
    {--- Rename the current title from the content of the string "S"  }
    PersistentChat.Data.Rename(Item.Data, S);

    {--- Export conversations to JSON }
    PersistentChat.SaveToFile;

    {--- Disable editing mode of Listview }
    FAllowEdit := False;
  finally
    ServicePrompt.SetFocus;
  end;
end;

procedure TChatSessionHistoryViewVCL.HandleEditing(Sender: TObject; Item: TListItem;
  var AllowEdit: Boolean);
begin
  AllowEdit := FAllowEdit;
end;

procedure TChatSessionHistoryViewVCL.HandleJsonEdition(Sender: TObject);
begin
  var JSONPath := TChatSessionList.JsonFileName;

  {--- Generates a unique path in the temporary directory }
  var TempPath := TPath.Combine(
    TPath.GetTempPath,
    Format('Preview_%s_%d.json',
      [ TPath.GetFileNameWithoutExtension(JSONPath), GetTickCount ] )
  );

  {--- Copy the file (overwrite if already present }
  TFile.Copy(JSONPath, TempPath, True);

  {--- Open the copy in Notepad }
  ShellExecute(Application.Handle, 'open', PChar(TempPath), nil, nil, SW_SHOWNORMAL);
end;

procedure TChatSessionHistoryViewVCL.HandleListView1KeyPress(Sender: TObject;
  var Key: Char);
begin
  case Ord(Key) of
    VK_ESCAPE : HandleCancel(nil);
  end;
end;

procedure TChatSessionHistoryViewVCL.HandleOk(Sender: TObject);
begin
  try
    {--- Freeing selected instances and screen display clear if necessary }
    DeleteSelected;

    {--- Hide ok and cancel buttons }
    HideButtons;

    {--- Hide the check boxes }
    FListView.Checkboxes := False;

    {--- Refresh the chat conversations }
    Refresh(Sender);
  finally
    ServicePrompt.SetFocus;
  end;
end;

procedure TChatSessionHistoryViewVCL.HandleRename(Sender: TObject);
begin
  if FListView.ItemIndex > -1 then
    begin
      FAllowEdit := True;
      FListView.Selected.EditCaption;
    end;
end;

procedure TChatSessionHistoryViewVCL.HideButtons;
begin
  FBtnPanel.Visible := False;
end;

procedure TChatSessionHistoryViewVCL.InternalSort(Sender: TObject);
begin
  FSortColumn := 1;
  FSortAscending := True;
  HandleColumnClick(Sender, DateCol);
  if FListView.Items.Count > 0 then
    FListView.ItemIndex := 0;
end;

procedure TChatSessionHistoryViewVCL.ItemRepaint(const Value: TChatTurn);
begin
  if not Value.Response.Trim.IsEmpty then
    begin
      {--- Add the Id response }
      ResponseTracking.Add(Value.Id);

      {--- Edge browser decoration: Promp and Response }
      EdgeDisplayer.Prompt(Value.Prompt);
      EdgeDisplayer.Display(Value.Response);

      {--- Panels decoration: File_search, Web_search, Reasoning }
      UpdateAnnotation(FileSearchDisplayer, Value.FileSearch);
      UpdateAnnotation(WebSearchDisplayer, Value.WebSearch);
      UpdateAnnotation(ReasoningDisplayer, Value.Reasoning);
    end;
end;

procedure TChatSessionHistoryViewVCL.ListViewCompare(Sender: TObject; Item1,
  Item2: TListItem; Data: Integer; var Compare: Integer);
var
  S1, S2: string;
  N1, N2: Double;
  D1, D2: TDateTime;
  FS: TFormatSettings;
begin
  if Data = 0 then
    begin
      S1 := Item1.Caption;
      S2 := Item2.Caption;
    end
  else
    begin
      S1 := Item1.SubItems[Data-1];
      S2 := Item2.SubItems[Data-1];
    end;

  FS := TFormatSettings.Create;
  FS.DateSeparator := '/';

  if Data = 1 then
    begin
      if TryStrToDate(S1, D1, FS) and TryStrToDate(S2, D2, FS) then
        Compare := Sign(D1 - D2)
      else
        Compare := CompareText(S1, S2);
    end
  else
    begin
      if TryStrToFloat(S1, N1) and TryStrToFloat(S2, N2) then
        Compare := Sign(N1 - N2)
      else
        Compare := CompareText(S1, S2);
    end;

  if not FSortAscending then
    Compare := -Compare;
end;

procedure TChatSessionHistoryViewVCL.Refresh(Sender: TObject);
begin
  var List := FPersistentChat.Data;
  FListView.Items.BeginUpdate;
  try
    FListView.Clear;
    for var Item in List.Data do
      begin
        var NewItem := FListView.Items.Insert(0);
        NewItem.Caption := Item.Title;
        NewItem.Data := Item;
        NewItem.SubItems.Add(TDateTime(UnixToDateTime(Item.ModifiedAt, False)).ToString);
      end;
    InternalSort(Sender);
  finally
    FListView.Items.EndUpdate;
  end;
end;

procedure TChatSessionHistoryViewVCL.Repaint(Sender: TObject);
begin
  if Assigned(PersistentChat.CurrentChat) then
    begin
      TTask.Run(
        procedure()
        begin
          TThread.Queue(nil,
            procedure
            begin
              EdgeDisplayer.Hide;
              try
                ResponseTracking.Clear;
                EdgeDisplayer.Clear;
                for var Item in PersistentChat.CurrentChat.Data do
                  begin
                    ItemRepaint(Item);
                  end;
                EdgeDisplayer.ScrollToEnd(True);
                Sleep(150);
              finally
                EdgeDisplayer.Show;
              end;
            end)
        end);
    end;
end;

procedure TChatSessionHistoryViewVCL.SetBtnPanel(const Value: TPanel);
begin
  FBtnPanel := Value;
  TAppStyle.ApplyChatSessionConfirmationPanelStyle(Value,
    procedure
    begin
      FBtnPanel.Visible := False;
    end);
end;

procedure TChatSessionHistoryViewVCL.SetCancelButton(const Value: TSpeedButton);
begin
  FCancelButton := Value;
  TAppStyle.ApplyChatSessionExecuteButtonStyle(Value,
    procedure
    begin
      FCancelButton.Caption := '&Cancel';

      FCancelButton.OnClick := HandleCancel;
    end);
end;

procedure TChatSessionHistoryViewVCL.SetListView(const Value: TListView);
begin
  FListView := Value;
  TAppStyle.ApplyChatSessionListviewStyle(Value,
    procedure
    begin
      ConfigureListViewProperties;
      ConfigureListViewColumns;
      ConfigureListViewEvents;
    end);
end;


procedure TChatSessionHistoryViewVCL.SetOkButton(const Value: TSpeedButton);
begin
  FOkButton := Value;
  TAppStyle.ApplyChatSessionExecuteButtonStyle(Value,
    procedure
    begin
      FOkButton.Caption := '&Ok';

      FOkButton.OnClick := HandleOk;
    end);
end;

procedure TChatSessionHistoryViewVCL.ShowButtons;
begin
  FBtnPanel.Visible := True;
end;

procedure TChatSessionHistoryViewVCL.SortInitialize;
begin
  FSortColumn := -1;
  FSortAscending := True;
  FAllowEdit := False;
  FSelected := nil;
end;

procedure TChatSessionHistoryViewVCL.UpdateAnnotation(
  const Annotation: IAnnotationsDisplayer; const Text: string);
begin
  Annotation.Clear;
  Annotation.Display(Text);
  Annotation.ScrollToTop;
end;

end.
