
# приоритет
try {
	(Get-Process -Id $pid).PriorityClass = 'BelowNormal'
} catch {}

# set TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$v = $PSVersionTable.PSVersion.Major
if ($v -ge 5) {

	# ошибка
	$Env:error = 0

	# строка для отображения
	$out = ""

	if ($Env:miner_name -ne 0) {
		# если больше одного майнера запущено
		if ((Get-Process "$Env:miner_process" -ErrorAction SilentlyContinue).Count -gt 1) {
			try {
				Get-Process "$Env:miner_process" -ErrorAction SilentlyContinue | Stop-Process -Force
			} catch {}
			Start-Sleep 5
		}
		# проверяем запущен майнер или нет
		if ((Get-Process "$Env:miner_process" -ErrorAction SilentlyContinue) -eq $Null) {

			# если нет папки майнеров то создаем
			$minersdir = "$PSScriptRoot\miners"
			if (!(Test-Path $minersdir)) {
				New-Item -ItemType Directory -Force -Path $minersdir | Out-Null
			}

			# если нет папки майнера то качаем майнер и распаковываем
			$minerdir = "$minersdir\$Env:miner_name"
			if (!(Test-Path $minerdir)) {
				# New-Item -ItemType Directory -Force -Path $minerdir | Out-Null
				$out += "`r`n"
				$out += "DOWNLOAD MINER"
				$Env:error = 0
				try {
					Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.ru/app/miners/$Env:miner_name.zip" -timeout 10 -outfile "$minersdir\$Env:miner_name.zip"
				} catch {
					$Env:error = 1
				}
				if ($Env:error -eq "1") {
					try {
						Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.xyz/app/miners/$Env:miner_name.zip" -timeout 10 -outfile "$minersdir\$Env:miner_name.zip"
						$Env:error = 0
					} catch {
						$Env:error = 1
					}
				}
				if ($Env:error -eq "1") {
					$out += "`r`n"
					$out += "ERROR: FILED TO DOWNLOAD MINER"
				} else {
					$out += "`r`n"
					$out += "UNZIP MINER"
					try {
						Expand-Archive "$minersdir\$Env:miner_name.zip" -DestinationPath "$minersdir"
					} catch {
						$out += "`r`n"
						$out += "ERROR: FILED TO UNZIP MINER"
						$Env:error = 1
					}
					try {
						Remove-Item "$minersdir\$Env:miner_name.zip" -Force
					} catch {}
				}
			}

			# переносим батник майнера в папку майнера
			if (Test-Path ".\miner.bat") {
				try {
					Move-Item -Path ".\miner.bat" -Destination "$minerdir\miner.bat" -Force
				} catch {
					$out += "`r`n"
					$out += "ERROR: FILED TO MOVE MINER.BAT TO MINER FOLDER"
					$Env:error = 1
				}
			}

			# создаем ярлык на батник майнера
			if ($Env:error -eq "0") {
				try {
					$objShell = New-Object -ComObject ("WScript.Shell")
					$objShortcut = $objShell.CreateShortcut("$PSScriptRoot\miner.bat.lnk")
					$objShortcut.TargetPath = "$minerdir\miner.bat"
					$objShortcut.WorkingDirectory = "$minerdir"
					$objShortcut.Save()
				} catch {
					$out += "`r`n"
					$out += "ERROR: FILED TO CREATE MINER SHORTCUT"
					$Env:error = 1
				}
			}

			# запускаем майнер
			if ($Env:error -eq "0" -and (Test-Path ".\miner.bat.lnk")) {
				$out += "`r`n"
				$out += "RUN MINER"
				Start-Process "$PSScriptRoot\miner.bat.lnk"
				$out += "`r`n"
				$out += "OK"
				# уведомление о запуске майнера
				if ($Env:miner_id -gt 0) {
					$Env:error = 0
					try {
						Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.ru/api/?email=$Env:email&secret=$Env:secret&rig=$Env:rig&miner=$Env:miner_id" -timeout 10 -outfile .\log.txt
					} catch {
						$Env:error = 1
					}
					if ($Env:error -eq "1") {
						try {
							Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.xyz/api/?email=$Env:email&secret=$Env:secret&rig=$Env:rig&miner=$Env:miner_id" -timeout 10 -outfile .\log.txt
						} catch {}
					}
				}
			}
		} else {
			$out += "`r`n"
			$out += "OK"
		}
	} else {
		$out += "`r`n"
		$out += "MINER NOT SETUP"
	}
	Write-Host "$out"

} else {
	Write-Host -ForegroundColor:Red "ERROR: У вас старая версия PowerShell - $v. Необходимо обновить!"
}
Write-Host "`r`n"
Write-Host "---------------------------"

#Start-Sleep 120
