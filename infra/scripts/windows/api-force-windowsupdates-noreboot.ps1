function Show-Response
{
	param (
		[Parameter(Mandatory = $True)]
		[string]$Message,
		[Parameter(Mandatory = $false)]
		[ValidateSet("Cyan", "Magenta", "Red", "Blue", "White", "Green", "Yellow")]
		[string]$ForegroundColor,
		[Parameter(Mandatory = $false)]
		[string]$EventLogName
	)
	switch ($ForegroundColor)
	{
		"Green" {
			Write-Host "  - $($Message)" -ForegroundColor $ForegroundColor
			$EventID = "3000"
			$EntryType = "SuccessAudit"
		}
		"Red" {
			Write-Host " ->> $($Message)" -ForegroundColor $ForegroundColor
			$EventID = "3666"
			$EntryType = "Error"
		}
		"Magenta" {
			Write-Host " - $($Message)" -ForegroundColor $ForegroundColor
			$EventID = "3000"
			$EntryType = "Information"
		}
		"Cyan" {
			Write-Host " - $($Message)" -ForegroundColor $ForegroundColor
			$EventID = "3000"
			$EntryType = "Information"
		}
		"Yellow" {
			Write-Host " ->> $($Message)" -ForegroundColor $ForegroundColor
			$EventID = "3002"
			$EntryType = "Warning"
		}
		"White" {
			Write-Host "   - $($Message)" -ForegroundColor $ForegroundColor
			$EventID = "3000"
			$EntryType = "Information"
		}
		Default { Write-Host "$($Message)" -ForegroundColor Gray }
	}
	$EventLogName = "ecm-updates"
	if ($EventLogName.Length -ge 8)
	{
		if ([Security.Principal.WindowsIdentity]::GetCurrent().Claims.Value.Contains('S-1-5-32-544'))
		{
			$EventLogFound = [System.Diagnostics.EventLog]::Exists("$EventLogName");
			if (!$EventLogFound)
			{
				New-EventLog -Source "$($EventLogName)" -LogName "$($EventLogName)"
			}

			$EventLogFound = [System.Diagnostics.EventLog]::Exists("$EventLogName");
			if ($EventLogFound -and $EventID -and $EntryType)
			{
				Write-EventLog -LogName $EventLogName -Source "$($EventLogName)" -EventID "$($EventID)" -EntryType $EntryType -Message "$($Message)"
			}
		}
	}
	#	Send-SlackMsg -Text '$($Message)' -Channel 12345 -ID 1 -Timeout 10
}

function Test-RegistryKey
{
	[OutputType('bool')]
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Key
	)

	$ErrorActionPreference = 'Stop'

	if (Get-Item -Path $Key -ErrorAction Ignore)
	{
		$true
	}
}
function Test-RegistryValue
{
	[OutputType('bool')]
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Key,
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Value
	)

	$ErrorActionPreference = 'Stop'

	if (Get-ItemProperty -Path $Key -Name $Value -ErrorAction Ignore)
	{
		$true
	}
}

function Test-RegistryValueNotNull
{
	[OutputType('bool')]
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Key,
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Value
	)

	$ErrorActionPreference = 'Stop'

	if (($regVal = Get-ItemProperty -Path $Key -Name $Value -ErrorAction Ignore) -and $regVal.($Value))
	{
		$true
	}
}
Function Test-PendingReboot
{
	$tests = @(
		{ Test-RegistryKey -Key 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending' }
		{ Test-RegistryKey -Key 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootInProgress' }
		{ Test-RegistryKey -Key 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' }
		{ Test-RegistryKey -Key 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackagesPending' }
		{ Test-RegistryKey -Key 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\PostRebootReporting' }
		{ Test-RegistryValueNotNull -Key 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Value 'PendingFileRenameOperations' }
		{ Test-RegistryValueNotNull -Key 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Value 'PendingFileRenameOperations2' }
		{
			'HKLM:\SOFTWARE\Microsoft\Updates' | Where-Object { test-path $_ -PathType Container } | ForEach-Object {
				(Get-ItemProperty -Path $_ -Name 'UpdateExeVolatile' | Select-Object -ExpandProperty UpdateExeVolatile) -ne 0
			}
		}
		{ Test-RegistryValue -Key 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' -Value 'DVDRebootSignal' }
		{ Test-RegistryKey -Key 'HKLM:\SOFTWARE\Microsoft\ServerManager\CurrentRebootAttemps' }
		{ Test-RegistryValue -Key 'HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon' -Value 'JoinDomain' }
		{ Test-RegistryValue -Key 'HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon' -Value 'AvoidSpnSet' }
		{
			('HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName' | Where-Object { test-path $_ } | %{ (Get-ItemProperty -Path $_).ComputerName }) -ne
			('HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName' | Where-Object { Test-Path $_ } | %{ (Get-ItemProperty -Path $_).ComputerName })
		}
		{
			'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Services\Pending' | Where-Object {
				(Test-Path $_) -and (Get-ChildItem -Path $_)
			} | ForEach-Object { $true }
		}
	)
	$PendingReboot = $False
	foreach ($test in $tests)
	{
		if (& $test)
		{
			$PendingReboot = $true
		}
	}
	Return $PendingReboot
}
$RSAT = Get-WindowsCapability -Online | Where-Object { $_.Name -like "Rsat*" -AND $_.State -eq "Installed" }
Show-Response -Message "RSAT count on $($env:COMPUTERNAME) is [$($RSAT.count)]" -ForegroundColor blue
$PendingReboot = Test-PendingReboot
$WindowsVersion = (Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsHardwareAbstractionLayer).WindowsVersion

if ($PendingReboot -eq $False)
{
	$WindowsUpdate = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
	$WindowsUpdateAU = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
	if (!(Test-Path $WindowsUpdate))
	{
		Try { New-Item -Path $WindowsUpdate -Force | Out-Null }
		catch { Show-Response -Message "$($WindowsUpdate) not created, the error was $($_.Exception.Message)" -ForegroundColor red }
	}
	if (!(Test-Path $WindowsUpdateAU))
	{
		Try { New-Item -Path $WindowsUpdateAU -Force | out-null }
		catch { Show-Response -Message "$($WindowsUpdateAU) not created, the error was $($_.Exception.Message)" -ForegroundColor red }
	}

	Show-Response -Message "Verifying windows update registry settings.." -ForegroundColor cyan
	if (Test-Path $WindowsUpdateAU)
	{
		$NoAutoUpdate = (Get-itemproperty -Path $WindowsUpdateAU -Erroraction SilentlyContinue).NoAutoUpdate
		$UseWUServer = (Get-itemproperty -Path $WindowsUpdateAU -Erroraction SilentlyContinue).UseWUServer

		If ($NoAutoUpdate -ne "0")
		{
			Show-Response -Message "NoAutoUpdate is NOT set to 0." -ForegroundColor white
			Try
			{
				New-ItemProperty -Path $WindowsUpdateAU -Name NoAutoUpdate -Value "0" -PropertyType DWORD -Force | Out-Null
				Show-Response -Message "NoAutoUpdate changed to 0" -ForegroundColor green
			}
			Catch
			{
				Show-Response -Message "NoAutoUpdate was not changed, the error was $($_.Exception.Message)" -ForegroundColor red
			}
		}
		If ($UseWUServer -ne "0")
		{
			Show-Response -Message "UseWUServer is not set to 0." -ForegroundColor white
			Try
			{
				New-ItemProperty -Path $WindowsUpdateAU -Name UseWUServer -Value "0" -PropertyType DWORD -Force | Out-Null
				Show-Response -Message "UseWUServer changed to 0" -ForegroundColor green
			}
			Catch
			{
				Show-Response -Message "UseWUServer was not changed the error was $($_.Exception.Message)" -ForegroundColor red
			}
		}
	}
	if (Test-Path $WindowsUpdate)
	{
		$DisableWindowsUpdateAccess = (Get-itemproperty -Path $WindowsUpdate -Erroraction SilentlyContinue).DisableWindowsUpdateAccess
		$DoNotConnectToWindowsUpdateInternetLocations = (Get-itemproperty -Path $WindowsUpdate -Erroraction SilentlyContinue).DoNotConnectToWindowsUpdateInternetLocations
		$WUServer = (Get-itemproperty -Path $WindowsUpdate -Erroraction SilentlyContinue).WUServer
		$WUStatusServer = (Get-itemproperty -Path $WindowsUpdate -Erroraction SilentlyContinue).WUStatusServer
		$WUTargetReleaseVersion = (Get-itemproperty -Path $WindowsUpdate -Erroraction SilentlyContinue).TargetReleaseVersion
		$WUProductVersion = (Get-itemproperty -Path $WindowsUpdate -Erroraction SilentlyContinue).ProductVersion
		$WUTargetReleaseVersionInfo = (Get-itemproperty -Path $WindowsUpdate -Erroraction SilentlyContinue).TargetReleaseVersionInfo
		<#
		"TargetReleaseVersion" = dword:00000001
		"ProductVersion" = "Windows 10"
		"TargetReleaseVersionInfo" = "2004"
		#>
		# Detect OS name/version
		$OSInfo = Get-ComputerInfo | Select-Object -Property OSName, WindowsVersion, WindowsProductName
		$OSName = $OSInfo.OSName
		$OSVersion = $OSInfo.WindowsVersion
		$LatestWin10Target = "22H2"
		$LatestWin11Target = "24H2"

		if ($OSName -like "Microsoft Windows 11*")
		{
			If ($WUTargetReleaseVersion -ne "1")
			{
				Show-Response -Message "TargetReleaseVersion is not set to 1" -ForegroundColor white
				Try
				{
					New-ItemProperty -Path $WindowsUpdate -Name TargetReleaseVersion -Value "1" -PropertyType DWORD -Force | Out-Null
					Show-Response -Message "TargetReleaseVersion changed to 1" -ForegroundColor green
				}
				Catch
				{
					Show-Response -Message "TargetReleaseVersion was not changed the error was $($_.Exception.Message)" -ForegroundColor red
				}
			}
			If ($WUTargetReleaseVersionInfo -ne $LatestWin11Target)
			{
				Show-Response -Message "TargetReleaseversionInfo is not set to $LatestWin11Target" -ForegroundColor white
				Try
				{
					New-ItemProperty -Path $WindowsUpdate -Name TargetReleaseversionInfo -Value $LatestWin11Target -PropertyType String -Force | Out-Null
					Show-Response -Message "TargetReleaseversionInfo changed to $LatestWin11Target" -ForegroundColor green
				}
				Catch
				{
					Show-Response -Message "TargetReleaseVersion was not changed the error was $($_.Exception.Message)" -ForegroundColor red
				}
			}
			If ($WUProductVersion -ne "Windows 11")
			{
				Show-Response -Message "ProductVersion is not set to Windows 11" -ForegroundColor white
				Try
				{
					New-ItemProperty -Path $WindowsUpdate -Name ProductVersion -Value "Windows 11" -PropertyType String -Force | Out-Null
					Show-Response -Message "ProductVersion changed to Windows 11" -ForegroundColor green
				}
				Catch
				{
					Show-Response -Message "ProductVersion was not changed the error was $($_.Exception.Message)" -ForegroundColor red
				}
			}
		}
		elseif ((Get-ComputerInfo).WindowsProductName -eq "Windows 10 Enterprise")
		{
			If ($WUTargetReleaseVersion -ne "1")
			{
				Show-Response -Message "TargetReleaseVersion is not set to 1" -ForegroundColor white
				Try
				{
					New-ItemProperty -Path $WindowsUpdate -Name TargetReleaseVersion -Value "1" -PropertyType DWORD -Force | Out-Null
					Show-Response -Message "TargetReleaseVersion changed to 1" -ForegroundColor green
				}
				Catch
				{
					Show-Response -Message "TargetReleaseVersion was not changed the error was $($_.Exception.Message)" -ForegroundColor red
				}
			}
			If ($WUTargetReleaseVersionInfo -ne "22H2")
			{
				Show-Response -Message "TargetReleaseversionInfo is not set to 22H2" -ForegroundColor white
				Try
				{
					New-ItemProperty -Path $WindowsUpdate -Name TargetReleaseversionInfo -Value "22H2" -PropertyType String -Force | Out-Null
					Show-Response -Message "TargetReleaseversionInfo changed to 22H2" -ForegroundColor green
				}
				Catch
				{
					Show-Response -Message "TargetReleaseVersion was not changed the error was $($_.Exception.Message)" -ForegroundColor red
				}
			}
			If ($WUProductVersion -ne "Windows 10")
			{
				Show-Response -Message "ProductVersion is not set to Windows 10" -ForegroundColor white
				Try
				{
					New-ItemProperty -Path $WindowsUpdate -Name ProductVersion -Value "Windows 10" -PropertyType String -Force | Out-Null
					Show-Response -Message "ProductVersion changed to Windows 10" -ForegroundColor green
				}
				Catch
				{
					Show-Response -Message "ProductVersion was not changed the error was $($_.Exception.Message)" -ForegroundColor red
				}
			}
		}

		If ($DisableWindowsUpdateAccess -ne "0")
		{
			Show-Response -Message "DisableWindowsUpdateAccess is not set to 0" -ForegroundColor white
			Try
			{
				New-ItemProperty -Path $WindowsUpdate -Name DisableWindowsUpdateAccess -Value "0" -PropertyType DWORD -Force | Out-Null
				Show-Response -Message "DisableWindowsUpdateAccess changed to 0" -ForegroundColor green
			}
			Catch
			{
				Show-Response -Message "DisableWindowsUpdateAccess was not changed the error was $($_.Exception.Message)" -ForegroundColor red
			}
		}
		If ($DoNotConnectToWindowsUpdateInternetLocations -ne "0")
		{
			Show-Response -Message "DoNotConnectToWindowsUpdateInternetLocations is not set to 0" -ForegroundColor white
			Try
			{
				New-ItemProperty -Path $WindowsUpdate -Name DoNotConnectToWindowsUpdateInternetLocations -Value "0" -PropertyType DWORD -Force | Out-Null
				Show-Response -Message "DoNotConnectToWindowsUpdateInternetLocations changed to 0" -ForegroundColor green
			}
			Catch
			{
				Show-Response -Message "DoNotConnectToWindowsUpdateInternetLocations was not changed the error was $($_.Exception.Message)" -ForegroundColor red
			}
		}
		if ($WUServer)
		{
			Show-Response -Message "WUServer is set to $($WUServer)" -ForegroundColor white
			Try
			{
				Remove-ItemProperty -Path $WindowsUpdate -Name "WUServer" -ErrorAction SilentlyContinue -Force
				Show-Response -Message "WUServer removed" -ForegroundColor green
			}
			Catch
			{
				Show-Response -Message "WUServer was not removed the error was $($_.Exception.Message)" -ForegroundColor red
			}
		}
		if ($WUStatusServer)
		{
			Show-Response -Message "WUStatusServer is set to $($WUStatusServer)" -ForegroundColor white
			Try
			{
				Remove-ItemProperty -Path $WindowsUpdate -Name "WUStatusServer" -ErrorAction SilentlyContinue -Force
				Show-Response -Message "WUStatusServer removed" -ForegroundColor green
			}
			Catch
			{
				Show-Response -Message "WUStatusServer was not removed the error was $($_.Exception.Message)" -ForegroundColor red
			}
		}
	}
	Show-Response -Message "Checking for windows updates.." -ForegroundColor cyan
	$searchcriteria = "isinstalled=0 and type='Software' and IsAssigned=1"
	$msUpdateSession = New-Object -ComObject Microsoft.Update.Session
	$pendingUpdates = $msUpdateSession.CreateupdateSearcher().Search($searchcriteria).Updates

	Show-Response -Message "System has $($pendingUpdates.Count) pending Windows Updates" -ForegroundColor magenta
	if ($pendingUpdates.Count -ne 0)
	{
		foreach ($pendingUpdate in $pendingUpdates)
		{
			Show-Response -Message "Installing KB$($pendingUpdate.KBArticleIDs) - $($pendingUpdate.title)" -ForegroundColor white
		}

		Try
		{
			$Downloader = $msUpdateSession.CreateUpdateDownloader()
			$Downloader.Updates = $pendingUpdates
			Show-Response -Message "Downloading $($pendingUpdates.Count) Updates" -ForegroundColor white
			$Downloader.Download()
			$Installer = $msUpdateSession.CreateUpdateInstaller()
			$Installer.Updates = $pendingUpdates
			Show-Response -Message "Installing $($pendingUpdates.Count) Updates" -ForegroundColor white
			$Result = $Installer.Install()
			Show-Response -Message "Windows Update completed restart required $($Result.rebootRequired)" -ForegroundColor green
			If ($Result.rebootRequired) { $ExitCode = "3010" }
		}
		Catch
		{
			Show-Response -Message "Windows Update failed with error $($_.Exception.Message)" -ForegroundColor red
		}
	}
}
Else
{
	Show-Response -Message "System has a pending restart, no action taken" | Out-Null
	$ExitCode = "3010"
}
$RSAT = Get-WindowsCapability -Online | Where-Object { $_.Name -like "Rsat*" -AND $_.State -eq "Installed" }
Show-Response -Message "RSAT count [$($RSAT.count)]" -ForegroundColor blue
