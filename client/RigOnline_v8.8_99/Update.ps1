
# приоритет
try {
	(Get-Process -Id $pid).PriorityClass = 'BelowNormal'
} catch {}

# set TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$v = $PSVersionTable.PSVersion.Major
if ($v -gt 3) {

	# ошибка
	$Env:error = 0

	# строка для отображения
	$out = ""

	# проверяем обновления и загружаем их
	$version = [double](gc .\version.txt -Encoding utf8 -raw).Trim()
	try {
		Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.ru/app/version.txt" -timeout 10 -outfile .\log.txt
	} catch {
		$Env:error = 1
	}
	if ($Env:error -eq "1") {
		try {
			Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.xyz/app/version.txt" -timeout 10 -outfile .\log.txt
			$Env:error = 0
		} catch {
			$Env:error = 1
		}
	}
	if ($Env:error -eq "0") {
		$version_last = [double](gc .\log.txt -Encoding utf8 -raw).Trim()
		if($version_last -gt $version){
			$version_new = $version + 0.1
			$dv = [string]$version
			if($dv.Contains(".")){$dv = ""} else {$dv = ".0"}
			$dvn = [string]$version_new
			if($dvn.Contains(".")){$dvn = ""} else {$dvn = ".0"}
			$out += "UPDATE $version$dv -> $version_new$dvn"
			$out += "`r`n"
			$Env:error = 0
			try {
				Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.ru/app/$version_new$dvn/RigOnline.bat" -timeout 10 -outfile .\RigOnline.bat
			} catch {
				$Env:error = 1
			}
			if ($Env:error -eq "1") {
				try {
					Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.xyz/app/$version_new$dvn/RigOnline.bat" -timeout 10 -outfile .\RigOnline.bat
				} catch {}
			}
			$Env:error = 0
			try {
				Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.ru/app/$version_new$dvn/Config.ps1" -timeout 10 -outfile .\Config.ps1
			} catch {
				$Env:error = 1
			}
			if ($Env:error -eq "1") {
				try {
					Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.xyz/app/$version_new$dvn/Config.ps1" -timeout 10 -outfile .\Config.ps1
				} catch {}
			}
			$Env:error = 0
			try {
				Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.ru/app/$version_new$dvn/Hashrate.ps1" -timeout 10 -outfile .\Hashrate.ps1
			} catch {
				$Env:error = 1
			}
			if ($Env:error -eq "1") {
				try {
					Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.xyz/app/$version_new$dvn/Hashrate.ps1" -timeout 10 -outfile .\Hashrate.ps1
				} catch {}
			}
			$Env:error = 0
			try {
				Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.ru/app/$version_new$dvn/Miner.ps1" -timeout 10 -outfile .\Miner.ps1
			} catch {
				$Env:error = 1
			}
			if ($Env:error -eq "1") {
				try {
					Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.xyz/app/$version_new$dvn/Miner.ps1" -timeout 10 -outfile .\Miner.ps1
				} catch {}
			}
			$Env:error = 0
			try {
				Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.ru/app/$version_new$dvn/RigOnline.ps1" -timeout 10 -outfile .\RigOnline.ps1
			} catch {
				$Env:error = 1
			}
			if ($Env:error -eq "1") {
				try {
					Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.xyz/app/$version_new$dvn/RigOnline.ps1" -timeout 10 -outfile .\RigOnline.ps1
				} catch {}
			}
			$Env:error = 0
			try {
				Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.ru/app/$version_new$dvn/Tasks.ps1" -timeout 10 -outfile .\Tasks.ps1
			} catch {
				$Env:error = 1
			}
			if ($Env:error -eq "1") {
				try {
					Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.xyz/app/$version_new$dvn/Tasks.ps1" -timeout 10 -outfile .\Tasks.ps1
				} catch {}
			}
			$Env:error = 0
			try {
				Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.ru/app/$version_new$dvn/Update.ps1" -timeout 10 -outfile .\Update.ps1
			} catch {
				$Env:error = 1
			}
			if ($Env:error -eq "1") {
				try {
					Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.xyz/app/$version_new$dvn/Update.ps1" -timeout 10 -outfile .\Update.ps1
				} catch {}
			}
			$out += "UPDATE DONE"
			$version_new = [string]$version_new + $dvn
			$version_new | Out-File version.txt
			"" | Out-File p.txt
		} else {
			$dv = [string]$version
			if($dv.Contains(".")){$dv = ""} else {$dv = ".0"}
			$out += "YOU HAVE LAST VERSION - $version$dv"
		}
	} else {
		$out += "ERROR: FAILED TO CHECK UPDATE"
	}
	Write-Host "$out"
} else {
	Write-Host -ForegroundColor:Red "ERROR: У вас старая версия PowerShell - $v. Необходимо обновить!"
}
Write-Host "`r`n"
Write-Host "---------------------------"

#Start-Sleep 120
