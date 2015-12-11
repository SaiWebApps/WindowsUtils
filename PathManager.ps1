# Imports
using namespace System.Collections.Generic;
. "$PSScriptRoot\ProcessUserSelection.ps1"

# Create $profile dir if it doesn't exist.
[string]$profileDir = [String]::Join("", $profile[0..$profile.LastIndexOf("\")])
if (!$(Test-Path $profileDir)) {
    md $profileDir
}

# Constants
[string]$PATH_DELIMITER = ";"

[string]$TITLE = "Do you wish to"
[array]$CHOICES = @("add items to the path?", "delete items from the path?", "sort the elements in the path?")
[string]$PROMPT = "Enter 1, 2, or 3"

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

function AddToPath
{
	Param(
		[Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$AppendStr,
		
        [int]$Index = -1
	)

    [string]$newPath = $(GetPath) + ";" + $AppendStr

    # If a valid index was specified, then insert $AppendStr at that location.
	if ($Index -ge 0 -and $Index -le $fileList.Count) {
        [List[string]]$fileList = GetListOfFilesInPath
		$fileList.Insert($Index, $AppendStr)
        $newPath = [String]::Join($PATH_DELIMITER, $(UniquifyFileList -FileList $fileList))
	}

    echo $('$env:Path="' + $newPath + '"') > $profile
    . $profile
}

function DeleteElementFromPath
{
	Param(
        [string]$Index,
        [string]$TargetPathElement,
        [int]$IndexOffset
	)

	[List[string]]$fileList = GetListOfFilesInPath

    [int]$indexVal = -1
    [bool]$parsedIndexSuccessfully = [Int32]::TryParse($Index.Trim(), [ref] $indexVal)
    $indexVal -= $IndexOffset
    if ($indexVal -ge $IndexOffset -and $indexVal -lt $fileList.Count) {
        $fileList.RemoveAt($indexVal)
    }
    if ($TargetPathElement -and $fileList.Contains($TargetPathElement)) {
    	$fileList.Remove($TargetPathElement)
    }

	[string]$newPath = [String]::Join($PATH_DELIMITER, $fileList)
    echo $('$env:Path="' + $newPath + '"') > $profile
    . $profile
}

function DeleteFromPath
{
    Param(
        [string]$Indices,
        [string]$TargetPathElements,
        [int]$IndexOffset = 0
    )

    if ($Indices -and $IndexOffset) { 
        $Indices.Split($PATH_DELIMITER) | % { 
            DeleteElementFromPath -Index $_ -IndexOffset $IndexOffset 
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
        [int]$addToSpecificIndex = Read-Host "Add to Index"
        [string]$pathsToAdd = Read-Host "Enter (semicolon-delimited) absolute path(s)"
        AddToPath -AppendStr $pathsToAdd -Index $($addToSpecificIndex - 1)
    }

    $CHOICES[1] 
    { 
        [string]$deleteFromIndices = Read-Host "Delete from index (or semicolon-delimited indices)"
        [string]$targetPaths = Read-Host "Delete (semicolon-delimited) path elements"
        DeleteFromPath -TargetPathElement $targetPaths -Indices $deleteFromIndices -IndexOffset 1
    }

    $CHOICES[2] { SortPath }

    default { throw "Please press 1 or 2." }
}

echo "`n********AFTER********"
PrintFilesInPath