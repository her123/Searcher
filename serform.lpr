program serform;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}


uses
{$IFNDEF FPC}
{$ELSE}
  Interfaces,
{$ENDIF}
  Forms,
  main in 'main.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Searcher';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
