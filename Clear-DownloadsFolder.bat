set downloads_dir=%USERPROFILE%\Downloads\*
set downloads_dir_contents=%downloads_dir%.*

:: Delete all directories and subdirectories in Downloads, 
:: along with the files that they contain.
for /d %%i in (%downloads_dir%) do rd /S /Q %%i

:: Delete all files in root (Downloads) directory.
del /S /Q %downloads_dir_contents%
