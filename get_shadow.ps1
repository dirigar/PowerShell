# get shadow copy ntfs volume by wmi query
function Get-ShadowCopy
{
    [CmdletBinding()]
    param (
        [Parameter(
            ValueFromPipeline=$True,
            ValueFromPipelineByPropertyName=$True)]
        [Alias('PSComputerName')]
        [string]$ComputerName = $env:COMPUTERNAME
    )
    begin {
        if ($PSBoundParameters.Verbose) {$VerbosePreference = "Continue"}
    }
    process {
            if ($_ -ne $null) {
                if ($_.GetType().fullname -eq "Microsoft.ActiveDirectory.Management.ADComputer") { $ComputerName = $_.Name; }
                if ($_.GetType().fullname -eq "Quest.ActiveRoles.ArsPowerShellSnapIn.Data.ArsComputerObject") { $ComputerName = $_.Name; }
            }
            $ShadowCopyes = gwmi win32_shadowcopy -comp $ComputerName;
            $Volumes = gwmi win32_volume -comp $ComputerName | select DeviceID, DriveLetter;

            $ShadowCopyes `
            | select @{n="drive";e={
                    $id = $_.VolumeName;
                    $Volumes | where { $_.deviceID -eq $id} | select -ExpandProperty driveletter;
                }}, 
                @{n="date"; e = {
                    [datetime]::ParseExact($_.installDate.Split(".")[0], "yyyyMMddHHmmss", $null)
                }},
                DeviceObject
    }
    end {}
}