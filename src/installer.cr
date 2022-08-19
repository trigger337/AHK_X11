def installer_lines
	<<-LINES.split('\n')
	#Persistent
	Gui, Add, Text, x180, AHK_X11`nAutoHotkey for Linux
	Gui, Add, Text, xm0 y100, Installer`n`nNo script specified to execute. You can use AHK_X11 from command line if you want.`nOtherwise, click INSTALL below (recommended). This will install the binary and associate`nall .ahk files with it,so you can double click your scripts for execution.
	Gui, Add, Button, x180 y210 gInstall, %A_Space%%A_Space%%A_Space%->  INSTALL  <-%A_Space%%A_Space%%A_Space%
	Gui, Show, w300 h280
	Return

	Install:

	app_name = ahk_x11
	app_ext = ahk
	app_comment = AutoHotkey for Linux
	binary_dir = %A_Home%/.local/bin
	binary_path = %binary_dir%/ahk_x11
	app_logo = /tmp/tmp_ahk_x11_logo.png

	FileCreateDir, %binary_dir%
	FileCopy, %A_ScriptFullPath%, %binary_path%, 1

	RunWait, xdg-icon-resource install --context mimetypes --size 48 %app_logo% application-x-%app_name%

	FileAppend, <?xml version="1.0" encoding="UTF-8"?><mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info"><mime-type type="application/x-%app_name%"><comment>%app_comment%</comment><icon name="application-x-%app_name%"/><glob pattern="*.%app_ext%"/></mime-type></mime-info>, %app_name%-mime.xml
	RunWait, xdg-mime install %app_name%-mime.xml
	FileDelete, %app_name%-mime.xml
	RunWait, update-mime-database %A_Home%/.local/share/mime

	FileAppend, [Desktop Entry]`n, %app_name%.desktop
	FileAppend, Name=%app_name%`n, %app_name%.desktop
	FileAppend, Exec=%binary_path% `%U`n, %app_name%.desktop
	FileAppend, MimeType=application/x-%app_name%`n, %app_name%.desktop
	FileAppend, Icon=application-x-%app_name%`n, %app_name%.desktop
	FileAppend, Terminal=false`n, %app_name%.desktop
	FileAppend, Type=Application`n, %app_name%.desktop
	FileAppend, Categories=`n, %app_name%.desktop
	FileAppend, Comment=%app_comment%`n, %app_name%.desktop
	RunWait, desktop-file-install --dir=%A_Home%/.local/share/applications %app_name%.desktop
	FileDelete, %app_name%.desktop
	RunWait, update-desktop-database %A_Home%/.local/share/applications
	RunWait, xdg-mime default %app_name%.desktop application/x-%app_name%

	MsgBox, Installation complete. Program will exit.
	ExitApp
	LINES
end