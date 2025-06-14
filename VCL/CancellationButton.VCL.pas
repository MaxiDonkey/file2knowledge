unit CancellationButton.VCL;

interface

{$REGION  'Dev notes : CancellationButton.VCL'}

(*
  Unit: CancellationButton.VCL

  Purpose:
    This unit implements a simple, reusable VCL component for managing "cancellation" actions in user interfaces.
    The class TCancellationVCL wraps a TButton, providing mechanisms to detect, reset, and visually signal
    a cancellation request (e.g., to halt long-running or background operations).
    It supports toggling between normal and cancellation states, making it easy to add cancellation logic
    to any interactive workflow.

  Technical details:
    - TCancellationVCL implements ICancellation for standardized cancellation detection and signaling.
    - Manages button text and event handler swapping to represent normal vs cancellation states.
    - Stores and restores the original button caption and OnClick event to ensure seamless UI integration.
    - Uses a custom "cancel" glyph (Unicode character) for visual feedback in cancellation mode.
    - The Reset method initializes the cancellation state and prepares the button for use; Cancel
      returns the button to its original state.
    - Tracks the cancellation state via the FCancelled property, accessible via IsCancelled.

  Dependencies:
    - Delphi VCL TButton for user interaction.
    - UI.Styles.VCL for consistent button styling across the application.
    - Manager.Intf for interface-based interaction with broader application components.
    - Standard System.Classes and Controls for event and type definitions.

  Quick start for developers:
    - Instantiate TCancellationVCL, passing a TButton to its constructor.
    - Call Reset to switch the button into cancellation mode; the button will now display a "cancel" icon
      and respond to clicks by invoking Cancel.
    - Use IsCancelled to check from your workflow logic whether cancellation was requested.
    - When finished or aborting, call Cancel to restore the button to its original caption and behavior.

  This unit is intended for easy drop-in cancellation support in Delphi VCL applications,
  promoting clarity, user feedback, and minimal code coupling for cancellation functionality.
*)

{$ENDREGION}

uses
  System.Classes, Vcl.StdCtrls, Vcl.Controls, Manager.Intf, UI.Styles.VCL, Vcl.Buttons;

type
  /// <summary>
  /// Provides a reusable VCL component for user-initiated cancellation actions in Delphi applications.
  /// <para>
  /// - TCancellationVCL manages a TSpeedButton for workflow cancellation requests. It implements the ICancellation interface
  /// for standardized cancellation signaling and state detection. This class visually indicates the cancellation state,
  /// manages button caption and handler changes, and ensures original button state restoration upon cancellation or reset.
  /// </para>
  /// <remarks>
  /// <para>
  /// - Integrates seamlessly with VCL applications for interactive or long-running operations requiring cancellation support.<br/>
  /// </para>
  /// <para>
  /// - Uses a standard "cancel" glyph and consistent button styling via UI.Styles.VCL.
  /// </para>
  /// <para>
  /// - Original button caption and OnClick event are preserved and restored after cancellation.
  /// </para>
  /// <para>
  /// - The IsCancelled property allows workflow logic to query cancellation state.
  /// </para>
  /// </remarks>
  /// </summary>
  /// <param name="ACancelButton">
  /// The TSpeedButton instance managed for cancellation actions.
  /// </param>
  /// <seealso cref="ICancellation"/>
  /// <seealso cref="Manager.Intf"/>
  TCancellationVCL = class(TInterfacedObject, ICancellation)
  private
    FCancelButton: TSpeedButton;
    FCancelled: Boolean;
    FOldCaption: string;
    FOldOnclick: TNotiFyEvent;
    procedure DoCancelClick(Sender: TObject);
  public
    /// <summary>
    /// Marks the cancellation as requested, restores the original button caption and click handler.
    /// </summary>
    procedure Cancel(isDone: Boolean = False);

    /// <summary>
    /// Returns True if a cancellation has been requested; otherwise, returns False.
    /// </summary>
    /// <returns>
    /// True if the user has triggered the cancellation action, otherwise False.
    /// </returns>
    function IsCancelled: Boolean;

    /// <summary>
    /// Prepares the managed button for cancellation use by saving its state,
    /// updating the caption to a cancel glyph, and assigning the cancellation handler.
    /// </summary>
    procedure Reset;

    /// <summary>
    /// Initializes the cancellation handler for the specified TSpeedButton.
    /// </summary>
    /// <param name="ACancelButton">
    /// The TSpeedButton instance to be managed for cancellation.
    /// </param>
    constructor Create(ACancelButton: TSpeedButton);
  end;

implementation

{ TCancellationVCL }

procedure TCancellationVCL.Cancel(isDone: Boolean);
begin
  if not isDone then
    FCancelled := True;
  FCancelButton.Caption := FOldCaption;
  FCancelButton.OnClick := FOldOnclick;
end;

constructor TCancellationVCL.Create(ACancelButton: TSpeedButton);
begin
  inherited Create;
  FCancelButton := ACancelButton;
  if Assigned(FCancelButton) then
    TAppStyle.ApplyCancellationButtonStyle(FCancelButton)
end;

procedure TCancellationVCL.DoCancelClick(Sender: TObject);
begin
  Cancel;
end;

function TCancellationVCL.IsCancelled: Boolean;
begin
  Result := FCancelled;
end;

procedure TCancellationVCL.Reset;
begin
  FCancelled := False;
  FOldCaption := FCancelButton.Caption;
  FOldOnclick := FCancelButton.OnClick;
  FCancelButton.Caption := '';
  FCancelButton.OnClick := DoCancelClick;
end;

end.
