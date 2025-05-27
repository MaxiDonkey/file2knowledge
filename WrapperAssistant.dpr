program WrapperAssistant;

uses
  Vcl.Forms,
  Main in 'Main.pas' {Form1},
  Vcl.Themes,
  Vcl.Styles,
  Helper.ListView.VCL in 'VCL\Helper.ListView.VCL.pas',
  Manager.FileUploadID.controler in 'source\Manager.FileUploadID.controler.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows11 MineShaft');
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
