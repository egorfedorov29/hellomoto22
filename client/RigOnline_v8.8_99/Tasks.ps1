
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

	# берем перезагрузку по температуре
	$isfile = Test-Path "reboot_temp.txt"
	if ($isfile -ne "True") {
		$reboot_temp = 0
		$isfileCheck = Test-Path "before_reboot_temp.txt"
		if ($isfileCheck -ne "True") {
		} else {
			Remove-Item before_reboot_temp.txt
		}
	} else {
		# проверяем батник
		$isfileBat = Test-Path "tools\before_reboot_temp.bat"
		if ($isfileBat -ne "True") {
			$reboot_temp = 1
		} else {
			$isfileCheck = Test-Path "before_reboot_temp.txt"
			if ($isfileCheck -ne "True") {
				$reboot_temp = 0
				# запускаем скрипт
				Start-Process "tools\before_reboot_temp.bat"
				"" | Out-File before_reboot_temp.txt
				# правим статусы, чтобы при следующей проверке поймать ошибку
				$status = @{}
				$isfileStatus = Test-Path "status.json"
				if ($isfileStatus -eq "True") {
					$json = gc .\status.json -Encoding utf8 -raw
					if ($json) {
						(ConvertFrom-Json $json).psobject.properties | foreach { if ($_.Name -ne "vcount") {$status[$_.Name] = "CHECK"} else {$status[$_.Name] = $_.Value} }
					}
				}
				$status | ConvertTo-Json | Out-File status.json
			} else {
				$reboot_temp = 1
				Remove-Item before_reboot_temp.txt
			}
		}
		Remove-Item reboot_temp.txt
	}

	# берем перезагрузку по видеокартам
	$isfile = Test-Path "reboot_card.txt"
	if ($isfile -ne "True") {
		$reboot_card = 0
		$isfileCheck = Test-Path "before_reboot_card.txt"
		if ($isfileCheck -ne "True") {
		} else {
			Remove-Item before_reboot_card.txt
		}
	} else {
		# проверяем батник
		$isfileBat = Test-Path "tools\before_reboot_card.bat"
		if ($isfileBat -ne "True") {
			$reboot_card = 1
		} else {
			$isfileCheck = Test-Path "before_reboot_card.txt"
			if ($isfileCheck -ne "True") {
				$reboot_card = 0
				# запускаем скрипт
				Start-Process "tools\before_reboot_card.bat"
				"" | Out-File before_reboot_card.txt
				# правим статусы, чтобы при следующей проверке поймать ошибку
				$status = @{}
				$isfileStatus = Test-Path "status.json"
				if ($isfileStatus -eq "True") {
					$json = gc .\status.json -Encoding utf8 -raw
					if ($json) {
						(ConvertFrom-Json $json).psobject.properties | foreach { if ($_.Name -eq "vcount") {$status[$_.Name] = "CHECK"} else {$status[$_.Name] = $_.Value} }
					}
				}
				$status | ConvertTo-Json | Out-File status.json
			} else {
				$reboot_card = 1
				Remove-Item before_reboot_card.txt
			}
		}
		Remove-Item reboot_card.txt
	}

	# проверка заданий
	$Env:error = 0
	try {
		Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.ru/api/get.php?type=tasks&email=$Env:email&rig=$Env:rig" -timeout 10 -outfile .\log.txt
	} catch {
		$Env:error = 1
	}
	if ($Env:error -eq "1") {
		try {
			Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.xyz/api/get.php?type=tasks&email=$Env:email&rig=$Env:rig" -timeout 10 -outfile .\log.txt
			$Env:error = 0
		} catch {
			$Env:error = 1
		}
	}
	if ($Env:error -eq "1") {
		$out += "ERROR: FAILED TO CHECK TASKS"
	} else {
		$tasks = gc .\log.txt -Encoding utf8 -raw
		if ($tasks -eq "NO") {
			$out += "YOU DONT HAVE TASKS"
		} else {
			$tasks = $tasks | ConvertFrom-Json
			if ($tasks.MU -eq "Y" -or $tasks.MR -eq "Y") {
				# закрываем майнер
				try {
					Get-Process "$Env:miner_process" -ErrorAction SilentlyContinue | Stop-Process -Force
				} catch {}
				"" | Out-File p.txt
			}
			if ($tasks.MU -eq "Y") {
				# если есть задача - обновить майнер
				$out += "MINER UPDATE"
				$Env:error = 0
				try {
					Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.ru/api/get.php?type=minerbat&email=$Env:email&rig=$Env:rig" -timeout 10 -outfile .\miner.bat
				} catch {
					$Env:error = 1
				}
				if ($Env:error -eq "1") {
					try {
						Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.xyz/api/get.php?type=minerbat&email=$Env:email&rig=$Env:rig" -timeout 10 -outfile .\miner.bat
					} catch {}
				}
				$Env:error = 0
				try {
					Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.ru/api/get.php?type=minerini&email=$Env:email&rig=$Env:rig" -timeout 10 -outfile .\miner.ini
				} catch {
					$Env:error = 1
				}
				if ($Env:error -eq "1") {
					try {
						Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.xyz/api/get.php?type=minerini&email=$Env:email&rig=$Env:rig" -timeout 10 -outfile .\miner.ini
					} catch {}
				}
			} elseif ($tasks.MR -eq "Y") {
				# если есть задача - закрыть майнер
				$out += "MINER CLOSE"
				try {
					Remove-Item ".\miner.ini" -Force
				} catch {}
				try {
					Remove-Item ".\miner.bat.lnk" -Force
				} catch {}
			}
			if ($tasks.R -eq "Y") {
				# если есть задача - перезагрузка
				$out += "RESTART"
				Restart-Computer -Force
			} elseif ($tasks.S -eq "Y") {
				# если есть задача - выключение
				$out += "SHUTDOWN"
				Stop-Computer -Force
			}
		}
	}

	Write-Host "$out"

	# если необходимо перезагрузить при отвале карт и нарушении температуры
	if (($reboot_temp -eq 1) -or ($reboot_card -eq 1)) {
		Write-Host "`r`n"
		Write-Host "---------------------------"
		Write-Host "`r`n"
		Write-Host "RESTART"
		Restart-Computer -Force
	}
} else {
	Write-Host -ForegroundColor:Red "ERROR: У вас старая версия PowerShell - $v. Необходимо обновить!"
}
Write-Host "`r`n"
Write-Host "---------------------------"

#Start-Sleep 120
