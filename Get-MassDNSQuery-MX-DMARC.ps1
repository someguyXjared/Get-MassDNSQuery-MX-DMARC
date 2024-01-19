$ErrorActionPreference= 'silentlycontinue'
cls

$Domains = Get-Content .\Domains.txt
$TempDomProps = @{'Domain Name'='';'Type'='';'Host'='';'Preference'='';'Strings'='';}

	$FinalDNSRecords = @()
		
	$DNSServer1 = '8.8.8.8'
	$DNSServer2 = '8.8.4.4'
	$DNStoUse = $DNSServer1
	
	$DNSConnection = Test-Connection $DNSServer1 -quiet
	If ($DNSConnection -eq $False){
		$DNStoUse = $DNSServer2
		$DNSServer = 'Data pulled from 8.8.4.4'
	}

$Domains | %{
	Write-Host 'Checking' $_ -ForegroundColor Cyan
	
	$MXRecords = @()
	$MXRecords = resolve-dnsname -name $_ -Type MX -Server $DNStoUse -NoHostsFile -DNSOnly
	Write-Host '     Getting MX Records' -ForegroundColor Green
	ForEach ($Rec in $MXRecords){
		$TempMXObj = New-Object -TypeName PSObject -Prop $TempDomProps
		$TempMXObj.{Domain Name} = $_
		$TempMXObj.Type = 'MX'
		$TempMXObj.Host = $Rec.NameExchange
		$TempMXObj.Preference = $Rec.Preference
	
		$FinalDNSRecords += $TempMXObj
	
	}
	
	$DMARCRecords = @()
	$DMARCRecords = resolve-dnsname -name _dmarc.$_ -Type TXT -Server $DNStoUse -NoHostsFile -DNSOnly
	Write-Host '     Getting DMARC Records' -ForegroundColor Green
	Write-Host

	ForEach ($Record in $DMARCRecords){
	
		If ($DMARCRecords.strings -like '*DMARC*'){
			$TempDMARCObj = New-Object -TypeName PSObject -Prop $TempDomProps
			$TempDMARCObj.{Domain Name} = $_
			$TempDMARCObj.Type = 'TXT'
			[string] $TXTText = $Record.Strings
			$TempDMARCObj.Strings = $TXTText
			
			$FinalDNSRecords += $TempDMARCObj
		}
	}


	
}

Write-Host 'Exporting DomainDNSQueryResults-MX-DMARC.CSV' -ForegroundColor Yellow
Write-Host
#$FinalDNSRecords | Select 'Domain Name',Type,Host,Preference | Sort 'Domain Name',Type,Preference | Export-CSV .\DomainDNSQueryResults-MX-DMARC.csv -notypeinformation
$FinalDNSRecords | Select 'Domain Name',Type,Host,Preference,Strings | Sort 'Domain Name',Type,Preference | Export-CSV .\DomainDNSQueryResults-MX-DMARC.csv -notypeinformation
