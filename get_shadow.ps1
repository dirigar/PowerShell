# получить теневые копии
function Get-ShadowCopy
{
    [CmdletBinding()]
      param
      (
        [Parameter(
         ValueFromPipeline=$True,
         ValueFromPipelineByPropertyName=$True)]
         [Alias('PSComputerName')] [string]$ComputerName = $env:COMPUTERNAME

      )
begin
{
    if ($PSBoundParameters.Verbose) {$VerbosePreference = "Continue"}# необходимо для Write-Verbose версия 2.0
}
process
    {

        $ShadowCopyes = gwmi win32_shadowcopy -comp $ComputerName;
        $Volumes = gwmi win32_volume -comp $ComputerName | select DeviceID,DriveLetter;

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