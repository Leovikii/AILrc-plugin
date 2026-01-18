library AILrc_plugin;

uses
  apiPlugin,
  uPlugin in 'uPlugin.pas',
  uTypes in 'uTypes.pas',
  uUtils in 'uUtils.pas',
  uController in 'uController.pas';

{$R *.res}

function AIMPPluginGetHeader(out Header: IAIMPPlugin): HRESULT; stdcall;
begin
  try
    Header := TAIMPLifecyclePlugin.Create;
    Result := S_OK;
  except
    Result := E_UNEXPECTED;
  end;
end;

exports
  AIMPPluginGetHeader;

begin
end.
