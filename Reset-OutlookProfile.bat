:: Delete all existing Outlook profiles.
reg.exe delete HKCU\Software\Microsoft\Office\15.0\Outlook\Profiles\Outlook /f

:: Create new "Default" Outlook profile.
reg.exe add HKCU\Software\Microsoft\Office\15.0\Outlook\Profiles\Outlook