# Imports
using namespace System.Collections.Generic;
. "$PSScriptRoot\Process-UserSelection.ps1"

# Create $profile dir if it doesn't exist.
[string]$profileDir = [String]::Join("", $profile[0..$profile.LastIndexOf("\")])
if (!$(Test-Path $profileDir)) {
    [void](md $profileDir)
}

# Constants
[string]$PATH_DELIMITER = ";"

[string]$TITLE = "Do you wish to"
[array]$CHOICES = @("add items to the path?", "delete items from the path?", "sort the elements in the path?", "update an item in the path?")
[string]$PROMPT = "Enter 1, 2, 3, or 4"

# Helper functions
function GetPath
{
    return $($env:Path)
}

function GetListOfFilesInPath
{
	[string[]]$filesInPath = $(GetPath).Split($PATH_DELIMITER)
	return $(New-Object List[string](, $filesInPath))
}

function UniquifyFileList
{
    Param(
        [List[string]]$FileList
    )

    [List[string]]$uniqueFiles = New-Object List[string]
    [Dictionary[string, int]]$fileNameToIndex = @{}

    $FileList | % {
        $fileNameToIndex[$_] = $FileList.IndexOf($_)
    }
    $(New-Object SortedSet[int](, $fileNameToIndex.Values)) | % {
        $uniqueFiles.Add($FileList[$_])
    }
    
    return $(New-Object List[string](, $uniqueFiles)) 
}

function PrintFilesInPath
{
    [List[string]]$filesInPath = GetListOfFilesInPath
    $filesInPathStr = $filesInPath | % { 
        "`n`t" + $($filesInPath.IndexOf($_) + 1).ToString() + ". " + $_
    }
    echo $("Files in Path:" + $filesInPathStr + "`n")
}

function WriteToProfile
{
    Param(
        [List[string]]$NewListOfFiles
    )

    [string]$newPath = [String]::Join($PATH_DELIMITER, $(UniquifyFileList -FileList $NewListOfFiles))
    echo $('$env:Path="' + $newPath + '"') > $profile
    . $profile
}

function AddToPath
{
	Param(
		[Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$AppendStr,
		
        [int]$Index = -1,
        [int]$IndexOffset = 1
	)

    [List[string]]$fileList = GetListOfFilesInPath
    [int]$numFilesInPath = $fileList.Count

    # Adjust Index by IndexOffset, and verify that it's valid.
    # If it is negative or greater than the number of files in the path,
    # then it is out of bounds and is therefore invalid.
    # In that case, set it to the number of files in the path, so that we
    # add $AppendStr to the end of the current path.
    $Index -= $IndexOffset
    if ($Index -lt 0 -or $Index -gt $numFilesInPath) {
        $Index = $numFilesInPath
    }

    $fileList.Insert($Index, $AppendStr)
    WriteToProfile -NewListOfFiles $fileList
}

function DeleteElementFromPath
{
	Param(
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$TargetPathElement
	)

	[List[string]]$fileList = GetListOfFilesInPath
    if ($fileList.Contains($TargetPathElement)) {
    	$fileList.Remove($TargetPathElement)
    }

	WriteToProfile -NewListOfFiles $fileList
}

function DeleteFromPath
{
    Param(
        [string]$Indices,
        [int]$IndexOffset = 1,
        [string]$TargetPathElements
    )

    [List[string]]$files = GetListOfFilesInPath
    [int]$numFilesInPath = $files.Count

    $Indices = $Indices.Trim()
    $TargetPathElements = $TargetPathElements.Trim()

    if ($Indices) {
        $Indices.Split($PATH_DELIMITER) | ? {
            [int]$temp = -1;
            [bool]$parsedSuccessfully = [Int]::TryParse($_, [ref]$temp);
            $temp -= $IndexOffset;
            $parsedSuccessfully -and $temp -ge 0 -and $temp -lt $numFilesInPath
        } | % {
            [int]$index = [Int]::Parse($_) - $IndexOffset;
            [string]$target = $files[$index];
            DeleteElementFromPath -TargetPathElement $target
        }
    }
    if ($TargetPathElements) {
        $TargetPathElements.Split($PATH_DELIMITER) | % { 
            DeleteElementFromPath -TargetPathElement $_ 
        }
    }
}

function SortPath
{
    [List[string]]$fileList = $(GetListOfFilesInPath)
    $fileList.Sort()
    WriteToProfile -NewListOfFiles $fileList
}

function UpdateItemInPath
{
    Param(
        [Parameter(Mandatory=$True)]
        [int]$Index,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$NewValue
    )

    [List[string]]$fileList = $(GetListOfFilesInPath)
    if ($Index -lt 0 -or $Index -ge $fileList.Count) {
        return
    }
    $fileList.RemoveAt($Index)
    $fileList.Insert($Index, $NewValue)

    [string]$newPath = [String]::Join($PATH_DELIMITER, $fileList)
    echo $('$env:Path="' + $newPath + '"') > $profile
    . $profile
}

# Main
echo "********BEFORE********"
PrintFilesInPath

[string]$addOrDeleteUserSelection = ProcessUserSelection -Title $TITLE -AvailableChoices $CHOICES -Prompt $PROMPT
switch($addOrDeleteUserSelection)
{
    $CHOICES[0] 
    {
        [int]$addToSpecificIndex = Read-Host "Add to index"
        [string]$pathsToAdd = Read-Host "Enter (semicolon-delimited) absolute path(s)"
        AddToPath -AppendStr $pathsToAdd -Index $addToSpecificIndex
    }

    $CHOICES[1] 
    { 
        [string]$deleteFromIndices = Read-Host "Delete from index (or semicolon-delimited indices)"
        [string]$targetPaths = Read-Host "Delete (semicolon-delimited) path elements"
        DeleteFromPath -TargetPathElement $targetPaths -Indices $deleteFromIndices
    }

    $CHOICES[2] { SortPath }

    $CHOICES[3]
    {
        [int]$index = Read-Host "Update item at index"
        [string]$newValue = Read-Host "Enter new value"
        UpdateItemInPath -Index $($index - 1) -NewValue $newValue
    }

    default { throw "Please press 1 or 2." }
}

echo "`n********AFTER********"
PrintFilesInPath