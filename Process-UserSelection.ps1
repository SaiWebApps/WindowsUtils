<#
	.SYNOPSIS
	Prompt user to select an item from a list of items, and process user selection.

	.DESCRIPTION
	Given a list of items, first display "Item #. " + "Item Name" for each item. Then,
	allow the user to select 1 or more items from the list. For the case where the
	user selects multiple items, the user shall also specify a character-delimiter used
	to distinguish each choice.

    .PARAMETER Title
    Heading to display before printing out the list of available choices.

    .PARAMETER Prompt
    Message to display in order to prompt user to select 1+ choices from the list
    of displayed options.

    .PARAMETER Delimiter
    Character separating the user's choices when the user selects multiple items
    from the list of displayed options.
#>
function ProcessUserSelection
{
	Param(
		[Parameter(Mandatory=$True)]
        [array]
        $AvailableChoices,
		
        [string]
        $Title = "Choices",
        
        [string]
        $Prompt = "Select 1+ choices from the list above",
		
        [string]
        $Delimiter = ","
	)

	[array]$results = @()

    # Print the title.
    Write-Host $($Title + "`n")

	# Print the choices.
	$numAvailableChoices = $AvailableChoices.Length
	for ([int]$i = 0; $i -lt $numAvailableChoices; $i++) {
		$choiceNumber = $i + 1
		Write-Host $("`t" + $choiceNumber.ToString() + ". " + $AvailableChoices[$i])
	}
	Write-Host ""

	# Prompt user to select 1+ choices.
	[string]$userChoices = Read-Host $Prompt
	[array]$tokens = $userChoices.Split($Delimiter)
	foreach ($choiceNumStr in $tokens) {
		[int32]$choiceNum =  $([int32]::Parse($choiceNumStr)) - 1
        if ($choiceNum -lt 0 -or $choiceNum -ge $numAvailableChoices) {
            continue
        }
        $results += $AvailableChoices[$choiceNum]
	}

	return $results
}