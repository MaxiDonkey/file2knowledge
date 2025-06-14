unit Displayer.Memo.VCL;

interface

{$REGION  'Dev notes : Displayer.Memo.VCL'}

(*
  Unit: Displayer.Memo.VCL

  Purpose:
    This unit provides a simple, robust mechanism for displaying and streaming text output (such as annotations,
    logs, or chat history) within a Delphi VCL TMemo control. It abstracts display operations for both
    line-oriented and stream-oriented text, supporting smooth user interaction and scroll-to-bottom behaviors.

  Technical details:
    - Implements TMemoDisplayerVCL, adhering to the IAnnotationsDisplayer interface for standardized output logic.
    - Supports two main display modes: `Display` (for splitting and appending lines of text) and
      `DisplayStream` (for raw or formatted streaming/appending of text blocks).
    - Handles common newline and line break formats, ensuring text is appended with proper formatting and readability.
    - Provides automatic scrolling to the bottom or caret after each display for optimal user experience.
    - The Clear method clears all lines in the target TMemo.
    - Construction requires a TMemo instance, which can be styled or managed externally as desired.

  Dependencies:
    - Delphi VCL TMemo (Vcl.StdCtrls) for text display.
    - Manager.Intf for interface-based integration.
    - Standard Delphi system units for string, class, and Windows message handling.

  Quick start for developers:
    - Instantiate TMemoDisplayerVCL with the target TMemo control.
    - Use Display to append (and split) text as new lines; use DisplayStream for raw or streaming inserts.
    - Use Clear to reset the display.
    - No setup or teardown logic required—ideal for lightweight, drop-in annotation or logging panels.

  This unit is designed for clarity and minimalism, making text and annotation display effortless
  in Delphi VCL apps, whether for user interaction, logging, or developer-facing output.
*)

{$ENDREGION}

uses
  System.SysUtils, System.Classes, Winapi.Messages, Winapi.Windows, Vcl.StdCtrls,
  Vcl.Controls, Manager.Intf;

type
  /// <summary>
  /// Concrete implementation of <see cref="IAnnotationsDisplayer"/> for Delphi VCL applications,
  /// enabling streamlined display, streaming, and management of text content in a TMemo control.
  /// </summary>
  /// <remarks>
  /// <para>
  /// <c>TMemoDisplayerVCL</c> encapsulates robust logic for appending, streaming, and clearing
  /// annotation, log, or chat text in VCL TMemo components. It handles both line-oriented and raw
  /// streaming input, ensures proper handling of line breaks, and provides built-in methods for
  /// scroll-to-top and scroll-to-end behaviors, greatly enhancing user experience.
  /// </para>
  /// <para>
  /// This class is ideally suited for lightweight annotation panels, logging windows, or any scenario
  /// where clear, formatted, and live-updating text output is required in Delphi VCL applications.
  /// External styling and memo control management are fully supported through dependency injection
  /// of the target TMemo instance.
  /// </para>
  /// </remarks>
  TMemoDisplayerVCL = class(TInterfacedObject, IAnnotationsDisplayer)
  private
    FMemo: TMemo;
    function GetText: string;
  public
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

    constructor Create(AMemo: TMemo);
  end;

implementation

{ TMemoDisplayerVCL }

procedure TMemoDisplayerVCL.Clear;
begin
  FMemo.Lines.Clear;
end;

constructor TMemoDisplayerVCL.Create(AMemo: TMemo);
begin
  inherited Create;
  FMemo := AMemo;
end;

procedure TMemoDisplayerVCL.Display(const AText: string);
begin
  if not Assigned(FMemo) then
    Exit;

  FMemo.Lines.BeginUpdate;
  try
    var Lines := AText.Split([sLineBreak, #10]);
    if Length(Lines) > 0 then
      begin
        for var L in Lines do
          FMemo.Lines.Add(L);
      end
    else
      begin
        FMemo.Lines.Add(AText);
      end;
    FMemo.Perform(WM_VSCROLL, SB_BOTTOM, 0);
  finally
    FMemo.Lines.EndUpdate;
  end;
end;

procedure TMemoDisplayerVCL.DisplayStream(const AText: string);
begin
  if not Assigned(FMemo) then
    Exit;

  var Txt := AText;

  Txt := StringReplace(AText, '\n', sLineBreak, [rfReplaceAll]);
  Txt := StringReplace(Txt, #10,  sLineBreak, [rfReplaceAll]);

  FMemo.Lines.BeginUpdate;
  try
    FMemo.SelStart   := FMemo.GetTextLen;
    FMemo.SelLength  := 0;
    FMemo.SelText    := Txt;
  finally
    FMemo.Lines.EndUpdate;
  end;

  FMemo.Perform(EM_SCROLLCARET, 0, 0);
end;

function TMemoDisplayerVCL.GetText: string;
begin
  Result := FMemo.Lines.Text;
end;

function TMemoDisplayerVCL.IsEmpty: Boolean;
begin
  Result := FMemo.Lines.Text.Trim.IsEmpty;
end;

procedure TMemoDisplayerVCL.ScrollToEnd;
begin
  FMemo.Perform(WM_VSCROLL, SB_BOTTOM, 0);
end;

procedure TMemoDisplayerVCL.ScrollToTop;
begin
  FMemo.Perform(WM_VSCROLL, SB_TOP, 0);
end;

end.
