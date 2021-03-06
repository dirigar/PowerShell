# Test-Host
Function Test-Host ($Name)
{
    $ping = new-object System.Net.NetworkInformation.Ping
    trap {
        Write-Verbose "Error ping";
        $False;
        continue
    }
    if ($ping.send($Name).Status -eq "Success" ) {
         $True;
    } else {
        Write-Verbose "$ip - not responding" ;
        $False;
    }
}
#===============================================================================1
# Get-Online
function Get-Online {
   <#
  .SYNOPSIS
    Filters the objects that respond to icmp request
  .DESCRIPTION
    Filters the objects that respond to icmp request. Pings only DNS-names.
  .EXAMPLE
    "google.com" | Get-Online
  .EXAMPLE
    PS> [PSCustomObject]@{Computername="ya.ru"} | Get-Online -Verbose
    ПОДРОБНО: ya.ru - Success

    Computername
    ------------
    ya.ru
  .PARAMETER computername
    
  #>
    #[CmdletBinding( SupportsShouldProcess = $true )]
    param
    (
        [parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$true)]
        [string] $ComputerName
        ,[int] $WaitPing_ms = 300
    )
    begin
    {
        $ping = new-object System.Net.NetworkInformation.Ping
        if ($PSBoundParameters.Verbose) {$VerbosePreference = "Continue"}# need for Write-Verbose
    }
    process
    {
        if ($_ -ne $null) {
            if ($_.GetType().fullname -eq "Microsoft.ActiveDirectory.Management.ADComputer") { $ComputerName = $_.Name; }
            if ($_.GetType().fullname -eq "Quest.ActiveRoles.ArsPowerShellSnapIn.Data.ArsComputerObject") { $ComputerName = $_.Name; }
        }
        $dnsName = switch -Regex ($ComputerName) {
                "\w\.\w" { $_;}
                default {$_ + "." + $env:USERDNSDOMAIN;}
        }; 
        try {
            $IpAddress = [System.Net.Dns]::Resolve($dnsName).AddressList[0].IPAddressToString;
        } catch {
            Write-Verbose "Error of resolve DNS-name for ""$ComputerName""";
            return;
        }
        try {
            if ($ping.Send($IpAddress,$WaitPing_ms).Status -eq 0 ) {
                Write-Verbose "$ComputerName - Success";
                $_;
            } else {
                Write-Verbose "$ComputerName - Fail"
            }
        } catch {
            Write-Verbose "Error ping to the $ComputerName";
            return;
        }
    }
    end  { }
}
#==========================================================================================
# ------------get-ping------------------------
# "s1","s2","s3" | get-ping -on
# s1
# s3
function get-ping {
    param (
        [switch]$On,
        [switch]$Off,
        [switch]$All
    )
    $ip=@(
        $input | ? {$_} | % {$_}
    );
    if ($ip.count -eq 0 ) {
        Write-Error "Empy parameters! There is nothing to ping.";
        break;
    }
    $j = Test-Connection -count 1 -ea silentlycontinue -ComputerName $ip -asjob
    Wait-Job $j | out-null
    if ($All -or -not($On -xor $off)){
        Receive-Job $j |
        select address,@{n="IP"; e= {$_.protocoladdress}}, Responsetime,Statuscode
        }
    elseif($On){ Receive-Job $j | ? {$_.Statuscode -eq 0} | %{$_.address} }
    elseif($off){ Receive-Job $j | ? {$_.Statuscode -ne 0} | %{$_.address} }
}
