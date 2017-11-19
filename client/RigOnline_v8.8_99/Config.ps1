
# приоритет
try {
	(Get-Process -Id $pid).PriorityClass = 'BelowNormal'
} catch {}

# set TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$v = $PSVersionTable.PSVersion.Major
if ($v -gt 3) {

	# если есть изменение паузы, то удаляем его
	if ((Test-Path ".\p.txt")) {
		Remove-Item -Path ".\p.txt" -Force | Out-Null
	}

	# ошибка
	$Env:error = 0

	# строка для отображения
	$out = ""

	# качаем конфиг с сервера
	try {
		Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.ru/api/get.php?type=config&email=$Env:email&rig=$Env:rig" -timeout 10 -outfile .\config.ini
		$out += "UPDATE DONE"
	} catch {
		$Env:error = 1
	}
	if ($Env:error -eq "1") {
		try {
			Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.xyz/api/get.php?type=config&email=$Env:email&rig=$Env:rig" -timeout 10 -outfile .\config.ini
			$out += "UPDATE DONE"
			$Env:error = 0
		} catch {
			$Env:error = 1
		}
	}
	if ($Env:error -eq "1") {
		$out += "ERROR: FAILED TO UPDATE CONFIG"
	}
	Write-Host "$out"
} else {
	Write-Host -ForegroundColor:Red "ERROR: У вас старая версия PowerShell - $v. Необходимо обновить!"
}
Write-Host "`r`n"
Write-Host "---------------------------"

#Start-Sleep 120
