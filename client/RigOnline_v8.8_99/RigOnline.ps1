
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

	# запускаем Open Hrdware Monitor или не запущен
	$ProcessName = "openhardwaremonitor"
	if ((Get-Process $ProcessName -ErrorAction SilentlyContinue) -eq $Null) {
		Start-Process -FilePath ".\OpenHardwareMonitor\OpenHardwareMonitor.exe" -Verb RunAs -WindowStyle Minimized
		Start-Sleep 30
	}
	# приоритет
	try {
		(Get-Process -Name $ProcessName).PriorityClass = 'BelowNormal'
	} catch {}

	function Get-WmiCustom([string]$computername,[string]$namespace="root\cimv2",[string]$class,[int]$timeout=15) {

		$ConnectionOptions = new-object System.Management.ConnectionOptions
		$EnumerationOptions = new-object System.Management.EnumerationOptions

		$timeoutseconds = new-timespan -seconds $timeout
		$EnumerationOptions.set_timeout($timeoutseconds)

		$assembledpath = "\" + $computername + "" + $namespace
		# write-host $assembledpath -foregroundcolor yellow

		$Scope = new-object System.Management.ManagementScope $assembledpath, $ConnectionOptions
		$Scope.Connect()

		$querystring = "SELECT * FROM " + $class
		# write-host $querystring

		$searcher = new-object System.Management.ManagementObjectSearcher
		$searcher.set_options($EnumerationOptions)
		$searcher.Query = $querystring
		$searcher.Scope = $Scope

		trap { $_ } $result = $searcher.get()

		try {
			return $result
		} catch {
			return ""
		}
	}

	# если перезагрузка
	if ($Env:restart -eq "1") {

		# количество минут работы рига
		$os = Get-WmiCustom -class win32_operatingsystem -timeout 10
		$uptime = $os.ConvertToDateTime($os.LocalDateTime) - $os.ConvertToDateTime($os.LastBootUptime)
		$t = $uptime.Days * 24 * 60 + $uptime.Hours * 60 + $uptime.Minutes

		# если риг работает меньше 3 минут
		if ($t -lt 3) {
			# отправляем данные на сервис
			try {
				Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.ru/api/?email=$Env:email&secret=$Env:secret&rig=$Env:rig&restart=y" -timeout 10 -outfile .\log.txt
				$str = gc .\log.txt -Encoding utf8 -raw
				if ($str -eq "OK") {
					$out += "OK"
				} else {
					$out += "ERROR: $str"
				}
			} catch {
				$Env:error = 1
			}
			if ($Env:error -eq "1") {
				try {
					Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.xyz/api/?email=$Env:email&secret=$Env:secret&rig=$Env:rig&restart=y" -timeout 10 -outfile .\log.txt
					$str = gc .\log.txt -Encoding utf8 -raw
					if ($str -eq "OK") {
						$out += "OK"
					} else {
						$out += "ERROR: $str"
					}
					$Env:error = 0
				} catch {
					$Env:error = 1
				}
			}
			if ($Env:error -eq "1") {
				$out += "ERROR: FAILED TO GET URL"
			}
		} else {
			$out += "NO NEED TO SEND A REQUEST"
		}
		Write-Host "$out"

	} else {

		# если нет папки логов то создаем
		$logdir = ".\log"
		if (!(Test-Path $logdir)) {
			New-Item -ItemType Directory -Force -Path $logdir | Out-Null
		}
		$logfile = $logdir + "\data_" + (Get-Date).toString("yyyyMMddHHmmss") + ".log"

		# строка для отображения
		$out = ""
		# строка для сервиса
		$result = ""

		# берем имя компьютера
		$name = (Get-WmiCustom -class win32_ComputerSystem -timeout 10).Name
		$out += "ComputerName: " + $name
		$out += "`r`n"
		$result += "CN:" + $name

		# время работы компьютера
		$os = Get-WmiCustom -class win32_operatingsystem -timeout 10
		$uptime = $os.ConvertToDateTime($os.LocalDateTime) - $os.ConvertToDateTime($os.LastBootUptime)
		$out += "UpTime: " + $uptime.Days + " days, " + $uptime.Hours + " hours, " + $uptime.Minutes + " minutes"
		$out += "`r`n"
		$result += "," + "UT:" + $uptime.Days + ":" + $uptime.Hours + ":" + $uptime.Minutes + ":" + $uptime.Seconds

		# берем информацию об оборудовании
		$arResult = Get-WmiCustom -namespace root\openhardwaremonitor -class Hardware | Where-Object {$_.Identifier -like "*cpu*" -or $_.Identifier -like "*gpu*" -or $_.Identifier -like "*mainboard*"} | Sort-Object -Property HardwareType
		if ($arResult.Length -gt 0) {
			$out += "---------------------------"
			$out += "`r`n"
			ForEach($item In $arResult) {
				if (($item.HardwareType -eq "CPU") -or ($item.HardwareType -eq "Mainboard")) {
					$out += $item.HardwareType + ": " + $item.Name
					$result += "," + $item.HardwareType.Substring(0, 1) + ":" + $item.Name.Replace(" ", "_")
				} else {
					$exclude = 0
					if ($Env:exclude) {
						if ($item.Identifier.Split("/")[-1] -eq $Env:exclude) {
							$exclude = 1
						}
					}
					if ($exclude -eq "0") {
						$out += $item.HardwareType + $item.Identifier.Split("/")[-1] + ": " + $item.Name
						$result += "," + $item.HardwareType.Substring(0, 1) + ":" + $item.Identifier.Substring(1, 1) + $item.Identifier.Split("/")[-1] + ":" + $item.Name.Replace(" ", "_")
					}
				}
				$out += "`r`n"
			}
		}

		# берем загрузку процессора
		$arResult = Get-WmiCustom -namespace root\openhardwaremonitor -class Sensor -timeout 10 | Where-Object {($_.Name -Match "Core") -and ($_.SensorType -Match "Load") -and ($_.Identifier -like "*cpu*")} | Sort-Object -Property Parent, SensorType, Name
		if ($arResult.Length -gt 0) {
			$out += "---------------------------"
			$out += "`r`n"
			$out += "CPU Load:"
			$result += "," + "CL:"
			ForEach($item In $arResult) {
				$out += " " + [math]::Round($item.Value) + "%,"
				$result += "" + [math]::Round($item.Value) + ":"
			}
			$out = $out.Substring(0, $out.Length-1)
			$out += "`r`n"
			$result = $result.Substring(0, $result.Length-1)
		}

		# берем температуру процессора
		$arResult = Get-WmiCustom -namespace root\openhardwaremonitor -class Sensor -timeout 10 | Where-Object {$_.SensorType -Match "Temperature"} | Sort-Object -Property Parent, SensorType, Name
		if ($arResult.Length -gt 0) {
			$out += "CPU Temperature:"
			$result += "," + "CT:"
			ForEach($item In $arResult) {
				if ($item.Name -Match "Core" -and $item.Name -NotMatch "GPU") {
					$out += " " + [math]::Round($item.Value) + "C,"
					$result += "" + [math]::Round($item.Value) + ":"
				}
			}
			$out = $out.Substring(0, $out.Length-1)
			$out += "`r`n"
			$result = $result.Substring(0, $result.Length-1)
		}

		# берем статус карт
		$status = @{}
		$isfile = Test-Path "status.json"
		if ($isfile -eq "True") {
			$json = gc .\status.json -Encoding utf8 -raw
			if ($json) {
				(ConvertFrom-Json $json).psobject.properties | foreach { $status[$_.Name] = $_.Value }
			}
		}
		$count_gpu = 0
		$errors = 0

		# берем данные видеокарт
		$arResult = Get-WmiCustom -namespace root\openhardwaremonitor -class Sensor -timeout 10 | Where-Object {($_.SensorType -Match "Temperature" -or $_.SensorType -Match "Clock" -or $_.SensorType -Match "Control" -or $_.SensorType -Match "Load") -and ($_.Identifier -like "*gpu*")} | Sort-Object -Property Parent, Name, SensorType
		if ($arResult.Length -gt 0) {
			$out += "---------------------------"
			$out += "`r`n"
			ForEach($item In $arResult) {
				if (-not($item.Name -eq "GPU Shader") -and -not($item.Name -eq "GPU Video Engine") -and -not($item.Name -eq "GPU Memory Controller") -and -not($item.Name -eq "GPU Memory" -and $item.SensorType -eq "Load")) {
					$exclude = 0
					if ($Env:exclude) {
						if ($item.Parent.Split("/")[-1] -eq $Env:exclude) {
							$exclude = 1
						}
					}
					if ($exclude -eq "0") {
						$out += $item.Parent + ": " + $item.Name + ": " + $item.SensorType + ": " + [math]::Round($item.Value)
						$out += "`r`n"
						$result += "," + $item.Parent.Substring(1, 1) + $item.Parent.Split("/")[-1] + ":" + $item.Name.Substring(4, 1) + ":" + $item.SensorType.Substring(0, 1) + ":" + [math]::Round($item.Value)
						# берем температуру
						if ($item.Name.Substring(4, 1) + $item.SensorType.Substring(0, 1) -eq "CT") {
							$count_gpu++
							$gpu_name = $item.Parent.Substring(1, 1) + $item.Parent.Split("/")[-1]
							$t = [math]::Round($item.Value)
							if ($t -eq 0) {
								# если температура нулевая
								$count_gpu--
							} elseif ($t -lt $Env:mint -or $t -gt $Env:maxt) {
								# если температура вышла за пределы
								if (!$status.$gpu_name) {
									$status += @{$gpu_name = "CHECK"}
								} elseif ($status.$gpu_name -eq "OK") {
									$status.$gpu_name = "CHECK"
								} elseif ($status.$gpu_name -eq "CHECK") {
									$errors++
									$status.$gpu_name = "ERROR"
								}
							} else {
								# если температура в норме
								if (!$status.$gpu_name) {
									$status += @{$gpu_name = "OK"}
								} elseif ($status.$gpu_name -eq "CHECK") {
									$status.$gpu_name = "OK"
								} elseif ($status.$gpu_name -eq "ERROR") {
									$status.$gpu_name = "OK"
								}
							}
						}
					}
				}
			}
			# если есть ошибки по температуре
			if ($errors -gt 0) {
				# если включена опция - рестарт по температуре
				if ($Env:reboot_temp -and $Env:reboot_temp -eq "Y") {
					"" | Out-File reboot_temp.txt
				}
			}
			# если есть изменения по количеству видеокарт
			if ($count_gpu -lt $Env:vcount) {
				if (!$status."vcount") {
					$status += @{"vcount" = "CHECK"}
				} elseif ($status."vcount" -eq "OK") {
					$status."vcount" = "CHECK"
				} elseif ($status."vcount" -eq "CHECK") {
					$status."vcount" = "ERROR"
					# если включена опция - рестарт при отвале карт
					if ($Env:reboot_lost -and $Env:reboot_lost -eq "Y") {
						"" | Out-File reboot_card.txt
					}
				}
			} else {
				if (!$status."vcount") {
					$status += @{"vcount" = "OK"}
				} elseif ($status."vcount" -eq "CHECK") {
					$status."vcount" = "OK"
				} elseif ($status."vcount" -eq "ERROR") {
					$status."vcount" = "OK"
				}
			}
			$status | ConvertTo-Json | Out-File status.json
		}

		# берем хэшрейт
		. .\Hashrate.ps1

		$out += "---------------------------"
		$out += "`r`n"
		$out += "SEND DATA TO RIGONLINE.RU"
		$out += "`r`n"
		#$result | Out-File rigonline.txt
		# отправляем данные на сервис
		try {
			Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.ru/api/?email=$Env:email&secret=$Env:secret&rig=$Env:rig&gpu=$result" -timeout 10 -outfile .\log.txt
			$str = gc .\log.txt -Encoding utf8 -raw
			if ($str -eq "OK") {
				$out += "OK"
			} else {
				$out += "ERROR: $str"
			}
		} catch {
			$Env:error = 1
		}
		if ($Env:error -eq "1") {
			try {
				Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.xyz/api/?email=$Env:email&secret=$Env:secret&rig=$Env:rig&gpu=$result" -timeout 10 -outfile .\log.txt
				$str = gc .\log.txt -Encoding utf8 -raw
				if ($str -eq "OK") {
					$out += "OK"
				} else {
					$out += "ERROR: $str"
				}
				$Env:error = 0
			} catch {
				$Env:error = 1
			}
		}
		if ($Env:error -eq "1") {
			$out += "ERROR: FAILED TO GET URL"
		}
		Write-Host "$out"

		# пишем лог
		$out | Out-File $logfile

		# удаляем старые файлы логов
		try {
			Get-ChildItem -Path $logdir | where {$_.LastWriteTime -lt (Get-Date).addMinutes(-120)} | Remove-Item -Force
		} catch {}

	}
} else {
	Write-Host -ForegroundColor:Red "ERROR: У вас старая версия PowerShell - $v. Необходимо обновить!"
}
Write-Host "`r`n"
Write-Host "---------------------------"

#Start-Sleep 120
