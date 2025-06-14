unit UI.PageSelector.VCL;

interface

{$REGION  'Dev notes : UI.PageSelector.VCL'}

(*
  Unit: UI.PageSelector.VCL

  Purpose:
    This unit implements the logic for a UI page selection component in a Delphi VCL application.
    It provides a streamlined way to navigate between key pages (such as Chat History, File Search,
    Web Search, Reasoning, and Settings) using a ComboBox as selector linked to a TPageControl, with
    enhanced visual feedback through associated icons and a styled Label.

  Technical details:
    - Defines the TPageSelector enum and its helper for easy retrieval of string names, icons, default page,
      and conversion between enum and indices.
    - The TSelectorVCL class encapsulates the ComboBox, PageControl, and Label, wiring their behaviors
      and appearance to provide a seamless page selection experience.
    - Uses event handlers to synchronize ComboBox selection with TabControl pages and updates the Label
      to the selected page name.
    - Leverages custom styles from TAppStyle for unified UI appearance and behavior.
    - All setup logic (event wiring, populating ComboBox, default settings) is handled in class setters,
      making it easy to integrate or extend.

  Dependencies:
    - Uses `UI.Styles.VCL` for custom UI theming and styling applied to the selector controls.
    - Standard Delphi VCL controls: TComboBox, TPageControl, TLabel, etc.
    - `Manager.Intf` for integrating with broader application interfaces or infrastructure.

  Quick start for developers:
    - Instantiate TSelectorVCL, providing it with the target ComboBox, PageControl, and Label from your form.
    - The selector will automatically initialize, populate, and synchronize the UI elements.
    - Page changes in the ComboBox will activate the corresponding tab in the PageControl and update the label.
    - Extend the TPageSelector enum or its helper if you wish to add new pages or customize icons/names.

  This unit is intended to simplify the integration of a modern, visually consistent, and easily maintainable
  page selector in cross-page Delphi VCL applications.

*)

{$ENDREGION}

uses
  Winapi.Windows, Winapi.Messages, Winapi.CommCtrl,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  Manager.Intf, Manager.Types, UI.Styles.VCL;

type
  /// <summary>
  /// Provides a unified, visually enhanced page selector component for Delphi VCL applications, enabling
  /// streamlined navigation between application pages such as Chat History, File Search, Web Search,
  /// Reasoning, and Settings.
  /// </summary>
  /// <remarks>
  /// <para>
  /// <c>TSelectorVCL</c> encapsulates the logic and user interface wiring required to synchronize a
  /// see "Vcl.StdCtrls.TComboBox", "Vcl.ComCtrls.TPageControl" and "Vcl.StdCtrls.TLabel"/> for seamless
  /// page selection.
  /// It leverages custom styles and icons for improved user experience and maintainability.
  /// </para>
  /// <para>
  /// Selecting a page via the ComboBox updates the PageControl and Label automatically, and all event
  /// handling and initialization are managed internally for easy integration. The class supports extension
  /// through enumeration updates for new pages or icons.
  /// </para>
  /// <para>
  /// TSelectorVCL follows File2knowledgeAI interface conventions and is intended for use in multi-page VCL
  /// applications that require quick, user-friendly page navigation.
  /// </para>
  /// </remarks>
  TSelectorVCL = class(TInterfacedObject, ISelector)
  private
    FComboBox: TComboBox;
    FPageControl: TPageControl;
    FLabel: TLabel;
    FCurrentPage: TPageSelector;
    FUpdating: Boolean;
    procedure SetCombobox(const Value: TComboBox);
    procedure SetPageControl(const Value: TPageControl);
    procedure SetLabel(const Value: TLabel);
    function GetActivePage: TPageSelector;
  protected
    procedure SetActivePage(const Page: TPageSelector);
    procedure HandleComboBoxChange(Sender: TObject);
    procedure HandleComboBoxCloseUp(Sender: TObject);
    procedure HandleOnActivePage(PageSelected: TPageSelector);
  public
    /// <summary>
    /// Creates an instance of <c>TSelectorVCL</c> for managing UI page selection in a VCL application.
    /// </summary>
    /// <param name="ACombobox">
    /// The <see cref="Vcl.StdCtrls.TComboBox"/> used for page selection.
    /// </param>
    /// <param name="APageControl">
    /// The <see cref="Vcl.ComCtrls.TPageControl"/> representing the application pages.
    /// </param>
    /// <param name="ALabel">
    /// The <see cref="Vcl.StdCtrls.TLabel"/> providing visual feedback for the selected page.
    /// </param>
    constructor Create(const ACombobox: TComboBox; const APageControl: TPageControl;
      const ALabel: TLabel);

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

implementation

{ TSelectorVCL }

constructor TSelectorVCL.Create(const ACombobox: TComboBox;
  const APageControl: TPageControl; const ALabel: TLabel);
begin
  inherited Create;
  FCurrentPage := TPageSelector.Default;
  FUpdating := False;

  SetCombobox(ACombobox);
  for var i := 0 to FComboBox.Items.Count-1 do
  Assert(FComboBox.Items[i] = TPageSelector(i).ToIcon,
    Format('Combo[%d] <> Enum icon', [i]));

  SetPageControl(APageControl);
  Assert(FPageControl.PageCount = TPageSelector.Count,
    'Enum <> PageControl : update either');

  SetLabel(ALabel);
end;

function TSelectorVCL.GetActivePage: TPageSelector;
begin
  Result := FCurrentPage;
end;

procedure TSelectorVCL.HandleComboBoxChange(Sender: TObject);
begin
  SetActivePage(TPageSelector.IconToPage(FComboBox.Text));
end;

procedure TSelectorVCL.HandleComboBoxCloseUp(Sender: TObject);
begin
  ServicePrompt.SetFocus;
end;

procedure TSelectorVCL.HandleOnActivePage(PageSelected: TPageSelector);
begin
  if PageSelected in ResponsesPages then
    PromptSelector.Update else
    PromptSelector.Hide;

  case PageSelected of
    psHistoric: ;
    psFileSearch: ;
    psWebSearch: ;
    psReasoning: ;
    psVectorFile: VectorResourceEditor.Refresh;
    psSettings: ;
  end;
end;

procedure TSelectorVCL.SetActivePage(const Page: TPageSelector);
begin
  if FUpdating or (Page = FCurrentPage) then Exit;

  FUpdating := True;
  try
    FCurrentPage := Page;
    FLabel.Caption := Page.ToString;
    HandleOnActivePage(FCurrentPage);
    FComboBox.ItemIndex := Page.IndexOf;
    FPageControl.ActivePageIndex := Page.IndexOf;
  finally
    FUpdating := False;
  end;
end;

procedure TSelectorVCL.SetCombobox(const Value: TComboBox);
begin
  FComboBox := Value;
  TAppStyle.ApplyPageSelectorComboBoxStyleBig(Value,
    procedure
    begin
      FComboBox.Items.Text := TPageSelector.AllIcons;
      FComboBox.ItemIndex := TPageSelector.Default.IndexOf;
      FComboBox.DropDownCount := TPageSelector.Count;

      FComboBox.OnChange := HandleComboBoxChange;
      FComboBox.OnCloseUp := HandleComboBoxCloseUp;
    end);
end;

procedure TSelectorVCL.SetLabel(const Value: TLabel);
begin
  FLabel := Value;
  TAppStyle.ApplyPageSelectorLabelStyle(Value);
end;

procedure TSelectorVCL.SetPageControl(const Value: TPageControl);
begin
  FPageControl := Value;
end;

procedure TSelectorVCL.ShowPage(const Page: TPageSelector);
begin
  var LPage := Page;
  if TThread.Current.ThreadID = MainThreadID then
    SetActivePage(LPage)
  else
    TThread.Queue(nil,
      procedure begin SetActivePage(LPage); end);
end;

end.

