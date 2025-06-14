unit UI.AlertService.VCL;

interface

{$REGION  'Dev notes : UI.AlertService.VCL'}

(*
  Unit: UI.AlertService.VCL

  Purpose:
    This unit provides a straightforward alert/warning service for Delphi VCL applications.
    Its goal is to encapsulate user warning display logic, ensuring that all warning messages are presented
    in a consistent, easy-to-maintain way through a single interface.

  Technical details:
    - Defines TAlerteServiceVCL, an implementation of the IAlertService interface.
    - The ShowWarning method uses Delphi's built-in MessageDlg function to present modal warning dialogs.
    - Supports any string message. Called warnings will always use the mtWarning dialog style with a single OK button.
    - Can easily be extended to other alert types (information, error, confirmation) by implementing additional interface methods.

  Dependencies:
    - Delphi VCL Dialogs unit for message display (MessageDlg).
    - Manager.Intf for the IAlertService interface contract.
    - Standard Delphi System.SysUtils and System.UITypes for string and dialog type definitions.

  Quick start for developers:
    - Instantiate TAlerteServiceVCL and call ShowWarning('your message') to display a warning dialog.
    - Integrates seamlessly in VCL applications where centralized or abstracted alert logic is desired.

  This unit is ideal for harmonizing and centralizing alert dialogs in Delphi VCL apps,
  promoting consistency and maintainability.

*)

{$ENDREGION}

uses
  System.SysUtils, System.UITypes, VCL.Dialogs, Manager.Intf;

type
  /// <summary>
  /// Provides a centralized alert and message dialog service for Delphi VCL applications,
  /// implementing the <c>IAlertService</c> interface.
  /// </summary>
  /// <remarks>
  /// <para>
  /// <c>TAlerteServiceVCL</c> is designed to harmonize the handling of user-facing alerts,
  /// ensuring all warnings, errors, informations, and confirmations are presented with a consistent look and
  /// logic throughout a Delphi VCL application.
  /// </para>
  /// <para>
  /// All dialogs are modal and use Delphi’s built-in <c>MessageDlg</c> function. The service supports
  /// warnings, errors, information messages, and confirmation dialogs (Yes/No).
  /// </para>
  /// </remarks>
  TAlerteServiceVCL = class(TInterfacedObject, IAlertService)
  public
    /// <summary>
    /// Displays an error message dialog with an "OK" button.
    /// </summary>
    /// <param name="Msg">
    /// The error message to display.
    /// </param>
    procedure ShowError(const Msg: string);

    /// <summary>
    /// Displays an informational message dialog with an "OK" button.
    /// </summary>
    /// <param name="Msg">
    /// The informational message to display.
    /// </param>
    procedure ShowInformation(const Msg: string);

    /// <summary>
    /// Displays a warning dialog with an "OK" button.
    /// </summary>
    /// <param name="Msg">
    /// The warning message to display.
    /// </param>
    procedure ShowWarning(const Msg: string);

    /// <summary>
    /// Shows a confirmation dialog (Yes/No) and returns the user's selection.
    /// </summary>
    /// <param name="Msg">
    /// The confirmation message to display.
    /// </param>
    /// <returns>
    /// <c>mrYes</c> if the user selects Yes; <c>mrNo</c> if No is selected.
    /// </returns>
    function ShowConfirmation(const Msg: string): Integer;
  end;

implementation

{ TAlerteServiceVCL }

function TAlerteServiceVCL.ShowConfirmation(const Msg: string): Integer;
begin
  Result := MessageDLG(Msg, TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], 0);
end;

procedure TAlerteServiceVCL.ShowError(const Msg: string);
begin
  MessageDLG(Msg, TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], 0);
end;

procedure TAlerteServiceVCL.ShowInformation(const Msg: string);
begin
  MessageDLG(Msg, TMsgDlgType.mtInformation, [TMsgDlgBtn.mbOK], 0);
end;

procedure TAlerteServiceVCL.ShowWarning(const Msg: string);
begin
  MessageDLG(Msg, TMsgDlgType.mtWarning, [TMsgDlgBtn.mbOK], 0);
end;

end.
