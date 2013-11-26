# Inspired by Mark Embling
# http://www.markembling.info/view/my-ideal-powershell-prompt-with-git-integration
function Set-VcsStatusSettings {
    [CmdletBinding()]
param(
    [ConsoleColor]$DefaultForegroundColor    = $Host.UI.RawUI.ForegroundColor,
    [ConsoleColor]$DefaultBackgroundColor    = $Host.UI.RawUI.BackgroundColor,

    # Retrieval settings
    [Switch]$EnablePromptStatus        = !$Global:GitMissing,
    [Switch]$EnableFileStatus          = $true,
    [Switch]$ShowStatusWhenZero        = $true,
    [String[]]$RepositoriesInWhichToDisableFileStatus = @( ), # Array of repository paths

    #Before prompt
    [String]$BeforeText                      = ' [',
    [ConsoleColor]$BeforeForegroundColor     = $([ConsoleColor]::Yellow),
    [ConsoleColor]$BeforeBackgroundColor     = $DefaultBackgroundColor,

    #After prompt
    [String]$AfterText                       = '] ',
    [ConsoleColor]$AfterForegroundColor      = $([ConsoleColor]::Yellow),
    [ConsoleColor]$AfterBackgroundColor      = $DefaultBackgroundColor,

    # Branches
    [ConsoleColor]$BranchForegroundColor       = $([ConsoleColor]::Cyan),
    [ConsoleColor]$BranchBackgroundColor       = $DefaultBackgroundColor,
    # Current branch when not updated
    [ConsoleColor]$BranchBehindForegroundColor = $([ConsoleColor]::DarkRed),
    [ConsoleColor]$BranchBehindBackgroundColor = $DefaultBackgroundColor,
    # Current branch when we're both
    [ConsoleColor]$BranchBeheadForegroundColor = $([ConsoleColor]::Yellow),
    [ConsoleColor]$BranchBeheadBackgroundColor = $DefaultBackgroundColor,

    # Working DirectoryColors
    [String]$AddedStatusPrefix                       = ' +',
    [ConsoleColor]$AddedLocalForegroundColor      = $([ConsoleColor]::DarkRed),
    [ConsoleColor]$AddedLocalBackgroundColor      = $DefaultBackgroundColor,

    [String]$ModifiedStatusPrefix                    = ' ~',
    [ConsoleColor]$ModifiedLocalForegroundColor   = $([ConsoleColor]::DarkRed),
    [ConsoleColor]$ModifiedLocalBackgroundColor   = $DefaultBackgroundColor,

    [String]$DeletedStatusPrefix                     = ' -',
    [ConsoleColor]$DeletedLocalForegroundColor    = $([ConsoleColor]::DarkRed),
    [ConsoleColor]$DeletedLocalBackgroundColor    = $DefaultBackgroundColor,

    [String]$UntrackedStatusPrefix                   = ' !',
    [ConsoleColor]$UntrackedLocalForegroundColor  = $([ConsoleColor]::DarkRed),
    [ConsoleColor]$UntrackedLocalBackgroundColor  = $DefaultBackgroundColor,

    # Git Specific ============================
    # Current branch when we need to push
    [ConsoleColor]$BranchAheadForegroundColor  = $([ConsoleColor]::Green),
    [ConsoleColor]$BranchAheadBackgroundColor  = $DefaultBackgroundColor,

    [String]$DelimText                       = ' |',
    [ConsoleColor]$DelimForegroundColor      = $([ConsoleColor]::Yellow),
    [ConsoleColor]$DelimBackgroundColor      = $DefaultBackgroundColor,

    [String]$UnmergedStatusPrefix                    = ' ?',
    [ConsoleColor]$UnmergedLocalBackgroundColor   = $([ConsoleColor]::DarkRed),
    [ConsoleColor]$UnmergedLocalForegroundColor   = $DefaultBackgroundColor,

    [String]$BeforeIndexText                 = "",
    [ConsoleColor]$BeforeIndexForegroundColor= $([ConsoleColor]::DarkGreen),
    [ConsoleColor]$BeforeIndexBackgroundColor= $DefaultBackgroundColor,

    [ConsoleColor]$IndexForegroundColor      = $([ConsoleColor]::DarkGreen),
    [ConsoleColor]$IndexBackgroundColor      = $DefaultBackgroundColor,

    [Switch]$AutoRefreshIndex          = $true,

    [string]$EnableWindowTitle         = 'posh~git ~ '

)

    if($global:VcsStatusSettings) {
        ## Sync the Background Colors: 
        ## If the DefaultBackgroundColor is changed
        if($PSBoundParameters.ContainsKey("DefaultBackgroundColor") -and ($global:VcsStatusSettings.DefaultBackgroundColor -ne $DefaultBackgroundColor)) {
            ## Any other background colors
            foreach($Background in $global:VcsStatusSettings.PsObject.Properties | Where { $_.Name -like "*BackgroundColor"} | % { $_.Name }) {
                # Which haven't been set
                if(!$PSBoundParameters.ContainsKey($Background)) {
                    if((!$global:VcsStatusSettings.$Background) -or ($global:VcsStatusSettings.$Background -eq $global:VcsStatusSettings.DefaultBackgroundColor)) {
                        # And are currently synced with the DefaultBackgroundColor
                        $PSBoundParameters.Add($Background, $DefaultBackgroundColor)
                    }
                }
            }
        }

        foreach($key in $PSBoundParameters.Keys) {
            $global:VcsStatusSettings | Add-Member NoteProperty $key $PSBoundParameters.$key -Force
        }
        ## Git Specific: Set them if they've never been set:
        if(!(Get-Member -In $global:VcsStatusSettings -Name BranchAheadForegroundColor)){
            $global:VcsStatusSettings | Add-Member NoteProperty BranchAheadForegroundColor $BranchAheadForegroundColor -Force
            $global:VcsStatusSettings | Add-Member NoteProperty BranchAheadBackgroundColor $BranchAheadBackgroundColor -Force

            $global:VcsStatusSettings | Add-Member NoteProperty DelimText $DelimText -Force
            $global:VcsStatusSettings | Add-Member NoteProperty DelimForegroundColor $DelimForegroundColor -Force
            $global:VcsStatusSettings | Add-Member NoteProperty DelimBackgroundColor $DelimBackgroundColor -Force

            $global:VcsStatusSettings | Add-Member NoteProperty UnmergedStatusPrefix $UnmergedStatusPrefix -Force
            $global:VcsStatusSettings | Add-Member NoteProperty UnmergedLocalBackgroundColor $UnmergedLocalBackgroundColor -Force
            $global:VcsStatusSettings | Add-Member NoteProperty UnmergedLocalForegroundColor $UnmergedLocalForegroundColor -Force

            $global:VcsStatusSettings | Add-Member NoteProperty BeforeIndexText $BeforeIndexText -Force
            $global:VcsStatusSettings | Add-Member NoteProperty BeforeIndexForegroundColor $BeforeIndexForegroundColor -Force
            $global:VcsStatusSettings | Add-Member NoteProperty BeforeIndexBackgroundColor $BeforeIndexBackgroundColor -Force

            $global:VcsStatusSettings | Add-Member NoteProperty IndexForegroundColor $IndexForegroundColor -Force
            $global:VcsStatusSettings | Add-Member NoteProperty IndexBackgroundColor $IndexBackgroundColor -Force


            $global:VcsStatusSettings | Add-Member NoteProperty ShowStatusWhenZero $ShowStatusWhenZero -Force

            $global:VcsStatusSettings | Add-Member NoteProperty AutoRefreshIndex $AutoRefreshIndex -Force

            $global:VcsStatusSettings | Add-Member NoteProperty EnableWindowTitle $EnableWindowTitle -Force
        }


    } else {
        $global:VcsStatusSettings = New-Object PSObject -Property @{
            DefaultBackgroundColor = $DefaultBackgroundColor
            # Retreival settings
            EnablePromptStatus = $EnablePromptStatus
            EnableFileStatus = $EnableFileStatus
            RepositoriesInWhichToDisableFileStatus = $RepositoriesInWhichToDisableFileStatus       

            #Before prompt        
            BeforeText = $BeforeText
            BeforeForegroundColor = $BeforeForegroundColor
            BeforeBackgroundColor = $BeforeBackgroundColor

            #After prompt
            AfterText = $AfterText
            AfterForegroundColor = $AfterForegroundColor
            AfterBackgroundColor = $AfterBackgroundColor

            BranchForegroundColor = $BranchForegroundColor
            BranchBackgroundColor = $BranchBackgroundColor
            BranchAheadForegroundColor = $BranchAheadForegroundColor
            BranchAheadBackgroundColor = $BranchAheadBackgroundColor
            BranchBehindForegroundColor = $BranchBehindForegroundColor
            BranchBehindBackgroundColor = $BranchBehindBackgroundColor

            BranchBeheadForegroundColor = $BranchBeheadForegroundColor
            BranchBeheadBackgroundColor = $BranchBeheadBackgroundColor

            # WorkingColors
            AddedStatusPrefix = $AddedStatusPrefix
            AddedLocalForegroundColor    = $AddedLocalForegroundColor   
            AddedLocalBackgroundColor    = $AddedLocalBackgroundColor   
            
            ModifiedStatusPrefix = $ModifiedStatusPrefix
            ModifiedLocalForegroundColor = $ModifiedLocalForegroundColor
            ModifiedLocalBackgroundColor = $ModifiedLocalBackgroundColor
            
            DeletedStatusPrefix = $DeletedStatusPrefix
            DeletedLocalForegroundColor  = $DeletedLocalForegroundColor 
            DeletedLocalBackgroundColor  = $DeletedLocalBackgroundColor 
            
            UntrackedStatusPrefix = $UntrackedStatusPrefix
            UntrackedLocalForegroundColor = $UntrackedLocalForegroundColor
            UntrackedLocalBackgroundColor = $UntrackedLocalBackgroundColor

            Debug = $DebugPreference -eq "Continue"

            #Delimiter
            DelimText = $DelimText
            DelimForegroundColor = $DelimForegroundColor
            DelimBackgroundColor = $DelimBackgroundColor

            UnmergedStatusPrefix = $UnmergedStatusPrefix
            UnmergedLocalBackgroundColor = $UnmergedLocalBackgroundColor
            UnmergedLocalForegroundColor = $UnmergedLocalForegroundColor

            BeforeIndexText = $BeforeIndexText
            BeforeIndexForegroundColor = $BeforeIndexForegroundColor
            BeforeIndexBackgroundColor = $BeforeIndexBackgroundColor

            IndexForegroundColor = $IndexForegroundColor
            IndexBackgroundColor = $IndexBackgroundColor


            ShowStatusWhenZero = $ShowStatusWhenZero

            AutoRefreshIndex = $AutoRefreshIndex

            EnableWindowTitle         = $EnableWindowTitle
        }
    }

    # Keep track of the DEFAULT background color....
    if(!$Script:CurrentBackgroundColor -or $PSBoundParameters.ContainsKey("DefaultBackgroundColor")) {
        $Script:CurrentBackgroundColor = $DefaultBackgroundColor
    }
}

# Make sure this runs at least once (when the module is initially imported)
Set-VcsStatusSettings

$WindowTitleSupported = $true
if ((get-host).Name -eq "Package Manager Host") {
    $WindowTitleSupported = $false
}

function Write-Prompt($Object, $ForegroundColor, $BackgroundColor = -1) {
    if ($BackgroundColor -lt 0) {
        Write-Host $Object -NoNewLine -ForegroundColor $ForegroundColor
    } else {
        Write-Host $Object -NoNewLine -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
    }
}

function Write-GitStatus($status) {
    $s = $global:VcsStatusSettings
    if ($status -and $s) {
        Write-Prompt $s.BeforeText -BackgroundColor $s.BeforeBackgroundColor -ForegroundColor $s.BeforeForegroundColor

        $branchBackgroundColor = $s.BranchBackgroundColor
        $branchForegroundColor = $s.BranchForegroundColor
        if ($status.BehindBy -gt 0 -and $status.AheadBy -gt 0) {
            # We are behind and ahead of remote
            $branchBackgroundColor = $s.BranchBeheadBackgroundColor
            $branchForegroundColor = $s.BranchBeheadForegroundColor
        } elseif ($status.BehindBy -gt 0) {
            # We are behind remote
            $branchBackgroundColor = $s.BranchBehindBackgroundColor
            $branchForegroundColor = $s.BranchBehindForegroundColor
        } elseif ($status.AheadBy -gt 0) {
            # We are ahead of remote
            $branchBackgroundColor = $s.BranchAheadBackgroundColor
            $branchForegroundColor = $s.BranchAheadForegroundColor
        }

        Write-Prompt $status.Branch -BackgroundColor $branchBackgroundColor -ForegroundColor $branchForegroundColor

        if($s.EnableFileStatus -and $status.HasIndex) {
            Write-Prompt $s.BeforeIndexText -BackgroundColor $s.BeforeIndexBackgroundColor -ForegroundColor $s.BeforeIndexForegroundColor

            if($s.ShowStatusWhenZero -or $status.Index.Added) {
              Write-Prompt "$($s.AddedStatusPrefix)$($status.Index.Added.Count)" -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor
            }
            if($s.ShowStatusWhenZero -or $status.Index.Modified) {
              Write-Prompt "$($s.ModifiedStatusPrefix)$($status.Index.Modified.Count)" -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor
            }
            if($s.ShowStatusWhenZero -or $status.Index.Deleted) {
              Write-Prompt "$($s.DeletedStatusPrefix)$($status.Index.Deleted.Count)" -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor
            }

            if ($status.Index.Unmerged) {
                Write-Prompt "$($s.UnmergedStatusPrefix)$($status.Index.Unmerged.Count)" -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor
            }

            if($status.HasWorking) {
                Write-Prompt $s.DelimText -BackgroundColor $s.DelimBackgroundColor -ForegroundColor $s.DelimForegroundColor
            }
        }

        if($s.EnableFileStatus -and $status.HasWorking) {
            if($s.ShowStatusWhenZero -or $status.Working.Added) {
              Write-Prompt "$($s.AddedStatusPrefix)$($status.Working.Added.Count)" -BackgroundColor $s.AddedLocalBackgroundColor -ForegroundColor $s.AddedLocalForegroundColor
            }
            if($s.ShowStatusWhenZero -or $status.Working.Modified) {
              Write-Prompt "$($s.ModifiedStatusPrefix)$($status.Working.Modified.Count)" -BackgroundColor $s.ModifiedLocalBackgroundColor -ForegroundColor $s.ModifiedLocalForegroundColor
            }
            if($s.ShowStatusWhenZero -or $status.Working.Deleted) {
              Write-Prompt "$($s.DeletedStatusPrefix)$($status.Working.Deleted.Count)" -BackgroundColor $s.DeletedLocalBackgroundColor -ForegroundColor $s.DeletedLocalForegroundColor
            }

            if ($status.Working.Unmerged) {
                Write-Prompt "$($s.UnmergedStatusPrefix)$($status.Working.Unmerged.Count)" -BackgroundColor $s.UnmergedLocalBackgroundColor -ForegroundColor $s.UnmergedLocalForegroundColor
            }
        }

        if ($status.HasUntracked) {
            Write-Prompt $s.UntrackedStatusPrefix -BackgroundColor $s.UntrackedLocalBackgroundColor -ForegroundColor $s.UntrackedLocalForegroundColor
        }

        Write-Prompt $s.AfterText -BackgroundColor $s.AfterBackgroundColor -ForegroundColor $s.AfterForegroundColor

        if ($WindowTitleSupported -and $s.EnableWindowTitle) {
            if( -not $Global:PreviousWindowTitle ) {
                $Global:PreviousWindowTitle = $Host.UI.RawUI.WindowTitle
            }
            $repoName = Split-Path -Leaf (Split-Path $status.GitDir)
            $prefix = if ($s.EnableWindowTitle -is [string]) { $s.EnableWindowTitle } else { '' }
            $Host.UI.RawUI.WindowTitle = "$prefix$repoName [$($status.Branch)]"
        }
    } elseif ( $Global:PreviousWindowTitle ) {
        $Host.UI.RawUI.WindowTitle = $Global:PreviousWindowTitle
    }
}

if(!(Test-Path Variable:Global:VcsPromptStatuses)) {
    $Global:VcsPromptStatuses = @()
}

function Global:Write-VcsStatus { $Global:VcsPromptStatuses | foreach { & $_ } }

# Add scriptblock that will execute for Write-VcsStatus
$Global:VcsPromptStatuses += {
    $Global:GitStatus = Get-GitStatus
    Write-GitStatus $GitStatus
}
# but we don't want any duplicate hooks (if people import the module twice)
$Global:VcsPromptStatuses = @( $Global:VcsPromptStatuses | Select -Unique )
