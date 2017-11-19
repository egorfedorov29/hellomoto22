
function Get-Hashrate([string]$out,[string]$result,[string]$num,[string]$coin,[string]$pool,[string]$address,[string]$worker,[string]$pool_email,[string]$api,[string]$secret,[string]$id) {

	# ошибка
	$error = 0

	$out += "---------------------------"
	$out += "`r`n"
	$out += "GET HASRATE (COIN " + $num + ")"
	$out += "`r`n"
	$out += "---------------------------"
	$out += "`r`n"
	if ($coin -ne "nice") {
		$out += "COIN: " + $coin
		$out += "`r`n"
	}
	$out += "POOL: " + $pool
	$out += "`r`n"
	if ($address -ne "") {
		$out += "ADDRESS: " + $address
		$out += "`r`n"
	}
	if ($api -ne "") {
		$out += "API KEY: " + $api
		$out += "`r`n"
	}
	if ($secret -ne "") {
		$out += "API SECRET: " + $secret
		$out += "`r`n"
	}
	if ($id -ne "") {
		$out += "USER ID: " + $id
		$out += "`r`n"
	}
	$out += "WORKER: " + $worker
	if ($coin -ne "nice") {
		$out += "`r`n"
	}

	# исходим от монеты и пула
	switch ($coin) {
		"nice" {
			switch ($pool) {
				"nicehash.com" {
					# алгоритмы
					$a = @{}
					$a = $a + @{"0" = "Scrypt"}
					$a = $a + @{"1" = "SHA256"}
					$a = $a + @{"2" = "ScryptNf"}
					$a = $a + @{"3" = "X11"}
					$a = $a + @{"4" = "X13"}
					$a = $a + @{"5" = "Keccak"}
					$a = $a + @{"6" = "X15"}
					$a = $a + @{"7" = "Nist5"}
					$a = $a + @{"8" = "NeoScrypt"}
					$a = $a + @{"9" = "Lyra2RE"}
					$a = $a + @{"10" = "WhirlpoolX"}
					$a = $a + @{"11" = "Qubit"}
					$a = $a + @{"12" = "Quark"}
					$a = $a + @{"13" = "Axiom"}
					$a = $a + @{"14" = "Lyra2REv2"}
					$a = $a + @{"15" = "ScryptJaneNf16"}
					$a = $a + @{"16" = "Blake256r8"}
					$a = $a + @{"17" = "Blake256r14"}
					$a = $a + @{"18" = "Blake256r8vnl"}
					$a = $a + @{"19" = "Hodl"}
					$a = $a + @{"20" = "DaggerHashimoto"}
					$a = $a + @{"21" = "Decred"}
					$a = $a + @{"22" = "CryptoNight"}
					$a = $a + @{"23" = "Lbry"}
					$a = $a + @{"24" = "Equihash"}
					$a = $a + @{"25" = "Pascal"}
					$a = $a + @{"26" = "X11Gost"}
					$a = $a + @{"27" = "Sia"}
					$a = $a + @{"28" = "Blake2s"}
					$a = $a + @{"29" = "Skunk"}
					# берем алгоритмы из кэша
					try {
						$algos = Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.ru/api/get.php?type=pool&method=stats.provider.ex&address=$address" -timeout 10
						$algos = [String]$algos
					} catch {
						$error = 1
					}
					if ($error -eq "1") {
						try {
							$algos = Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.xyz/api/get.php?type=pool&method=stats.provider.ex&address=$address" -timeout 10
							$algos = [String]$algos
							$error = 0
						} catch {
							$error = 1
						}
					}
					if ($error -eq "1" -or $algos -eq "NO") {
						# берем алгоритмы по API
						try {
							$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://api.nicehash.com/api?method=stats.provider.ex&addr=$address" -timeout 10 | ConvertFrom-Json
							$error = 0
						} catch {
							$error = 1
							$out += "`r`n"
							$out += "ERROR: FAILED TO GET URL"
						}
						# если получили ответ от апи
						if (-not $error) {
							# если АПИ вернуло ошибку
							if ($arResult.result.error) {
								$out += "`r`n"
								$out += "ERROR1: " + $arResult.result.error
								$error = 1
							} else {
								# отправляем данные в кэш
								$algos = ""
								if ($arResult.result.current.Length -gt 0) {
									# проходим по всем алгоритмам
									foreach ($item In $arResult.result.current) {
										if ($item.data[0]."a") {
											$algos += [String]$item.algo + ":" + $item.suffix + ","
										}
									}
								}
								if ($algos.Length -gt 0) {
									$algos = $algos.Substring(0, $algos.Length-1)
								}
								$cacheerror = 0
								try {
									Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.ru/api/set.php?type=pool&email=$Env:email&secret=$Env:secret&method=stats.provider.ex&address=$address&data=$algos" -timeout 10
								} catch {
									$cacheerror = 1
								}
								if ($cacheerror -eq "1") {
									try {
										Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.xyz/api/set.php?type=pool&email=$Env:email&secret=$Env:secret&method=stats.provider.ex&address=$address&data=$algos" -timeout 10
										$cacheerror = 0
									} catch {
										$cacheerror = 1
									}
								}
							}
						}
					}
					if (-not $error) {
						# если есть активные алгоритмы
						if ($algos -ne "") {
							$result += "," + "HN" + $num + ":"
							# проходим по всем алгоритмам
							$algos = $algos.Split(",");
							foreach ($item In $algos) {
								$arr = $item.Split(":")
								$algo = $arr[0]
								$suffix = $arr[1]
								# берем воркеров конкретного алгоритма из кэша
								try {
									$workers = Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.ru/api/get.php?type=pool&method=stats.provider.workers&address=$address&algo=$algo" -timeout 10
									$workers = [String]$workers
									$error = 0
								} catch {
									$error = 1
								}
								if ($error -eq "1") {
									try {
										$workers = Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.xyz/api/get.php?type=pool&method=stats.provider.workers&address=$address&algo=$algo" -timeout 10
										$workers = [String]$workers
										$error = 0
									} catch {
										$error = 1
									}
								}
								if ($error -eq "1" -or $workers -eq "NO") {
									# берем воркеров конкретного алгоритма по API
									try {
										Start-Sleep -s 1
										$arWorkers = Invoke-WebRequest -UseBasicParsing -Uri "https://api.nicehash.com/api?method=stats.provider.workers&addr=$address&algo=$algo" -timeout 10 | ConvertFrom-Json
										$error = 0
									} catch {
										$out += "`r`n"
										$out += "ERROR (" + $a."$algo" +"): FAILED TO GET URL"
										$error = 1
									}
									# если получили ответ от апи
									if (-not $error) {
										# если АПИ вернуло ошибку
										if ($arWorkers.result.error) {
											$out += "`r`n"
											$out += "ERROR2: " + $arWorkers.result.error
											$error = 1
										} else {
											# отправляем данные в кэш
											$workers = ""
											if ($arWorkers.result.workers.Length -gt 0) {
												# проходим по всем воркерам
												foreach ($item2 In $arWorkers.result.workers) {
													$workers += [String]$item2[0] + ":" + [String]$item2[1]."a" + ","
												}
											}
											if ($workers.Length -gt 0) {
												$workers = $workers.Substring(0, $workers.Length-1)
											}
											$cacheerror = 0
											try {
												Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.ru/api/set.php?type=pool&email=$Env:email&secret=$Env:secret&method=stats.provider.workers&address=$address&algo=$algo&data=$workers" -timeout 10
											} catch {
												$cacheerror = 1
											}
											if ($cacheerror -eq "1") {
												try {
													Invoke-WebRequest -UseBasicParsing -Uri "https://rigonline.xyz/api/set.php?type=pool&email=$Env:email&secret=$Env:secret&method=stats.provider.workers&address=$address&algo=$algo&data=$workers" -timeout 10
													$cacheerror = 0
												} catch {
													$cacheerror = 1
												}
											}
										}
									}
								}
								if (-not $error) {
									# если есть активные воркеры
									if ($workers -ne "") {
										# проходим по всем воркерам
										$workers = $workers.Split(",");
										foreach ($arWorker In $workers) {
											$arr = $arWorker.Split(":")
											$name = $arr[0]
											$h = $arr[1]
											# если воркер совпадает
											if ($name -eq $worker) {
												$ah = [math]::Round($h, 2)
												$out += "`r`n"
												$out += "HASHRATE (" + $a."$algo" + "): "
												$out += $ah
												$out += " " + $suffix + "/s"
												$result += $a."$algo" + "_" + $suffix + "_"
												$result += $ah
												$result += ":"
											}
										}
									}
								}
							}
						} else {
							$out += "`r`n"
							$out += "ERROR: NO ACTIVE ALGO"
						}
					}
				}
				default {
					$out += "`r`n"
					$out += "ERROR: POOL NOT SUPPORTED"
				}
			}
		}
		"eth" {
			switch ($pool) {
				"ethermine.org" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://api.ethermine.org/miner/:$address/worker/:$worker/currentStats" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.status -eq "OK") {
							if ($arResult.data -ne "NO DATA") {
								$rh = [math]::Round($arResult.data.reportedHashrate / 1000 / 1000, 2)
								$ch = [math]::Round($arResult.data.currentHashrate / 1000 / 1000, 2)
								$ah = [math]::Round($arResult.data.averageHashrate / 1000 / 1000, 2)
								$out += "HASHRATE (REPORTED): "
								$out += $rh
								$out += " MH/s"
								$out += "`r`n"
								$out += "HASHRATE (CURRENT): "
								$out += $ch
								$out += " MH/s"
								$out += "`r`n"
								$out += "HASHRATE (AVERAGE): "
								$out += $ah
								$out += " MH/s"
								$result += "," + "H" + $num + ":" + $coin + "_mhs_"
								$result += $rh
								$result += "_"
								$result += $ch
								$result += "_"
								$result += $ah
							} else {
								$out += "ERROR: NO DATA"
							}
						} else {
							$out += "ERROR"
						}
					}
				}
				"ethpool.org" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://api.ethpool.org/miner/:$address/worker/:$worker/currentStats" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.status -eq "OK") {
							if ($arResult.data -ne "NO DATA") {
								$rh = [math]::Round($arResult.data.reportedHashrate / 1000 / 1000, 2)
								$ch = [math]::Round($arResult.data.currentHashrate / 1000 / 1000, 2)
								$ah = [math]::Round($arResult.data.averageHashrate / 1000 / 1000, 2)
								$out += "HASHRATE (REPORTED): "
								$out += $rh
								$out += " MH/s"
								$out += "`r`n"
								$out += "HASHRATE (CURRENT): "
								$out += $ch
								$out += " MH/s"
								$out += "`r`n"
								$out += "HASHRATE (AVERAGE): "
								$out += $ah
								$out += " MH/s"
								$result += "," + "H" + $num + ":" + $coin + "_mhs_"
								$result += $rh
								$result += "_"
								$result += $ch
								$result += "_"
								$result += $ah
							} else {
								$out += "ERROR: NO DATA"
							}
						} else {
							$out += "ERROR"
						}
					}
				}
				"dwarfpool.com" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://dwarfpool.com/eth/api?wallet=$address&email=$pool_email" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.error -ne "True") {
							$rh = "-"
							$ch = [math]::Round($arResult.workers.$worker.hashrate, 2)
							$ah = [math]::Round($arResult.workers.$worker.hashrate_calculated, 2)
							$out += "HASHRATE (CURRENT): "
							$out += $ch
							$out += " MH/s"
							$out += "`r`n"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " MH/s"
							$result += "," + "H" + $num + ":" + $coin + "_mhs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: " + $arResult.error_code
						}
					}
				}
				"eth.nanopool.org" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://api.nanopool.org/v1/eth/avghashrateworkers/$address/1" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.status -eq "true") {
							foreach ($arWorker In $arResult.data) {
								if ($arWorker.worker -eq $worker) {
									$ch = [math]::Round($arWorker.hashrate, 2)
								}
							}
						}
						# берем hashrate по API
						try {
							$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://api.nanopool.org/v1/eth/avghashrateworkers/$address/6" -timeout 10 | ConvertFrom-Json
						} catch {
							$error = 1
							$out += "ERROR: FAILED TO GET URL"
						}
						if (-not $error) {
							# если есть данные
							if ($arResult.status -eq "true") {
								foreach ($arWorker In $arResult.data) {
									if ($arWorker.worker -eq $worker) {
										$ah = [math]::Round($arWorker.hashrate, 2)
									}
								}
							}
							if ($ch -ne $null -and $ah -ne $null) {
								$rh = "-"
								$out += "HASHRATE (CURRENT): "
								$out += $ch
								$out += " MH/s"
								$out += "`r`n"
								$out += "HASHRATE (AVERAGE): "
								$out += $ah
								$out += " MH/s"
								$result += "," + "H" + $num + ":" + $coin + "_mhs_"
								$result += $rh
								$result += "_"
								$result += $ch
								$result += "_"
								$result += $ah
							} else {
								$out += "ERROR: NO DATA"
							}
						}
					}
				}
				"ethermine.ru" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://ethermine.ru/api/accounts/$address" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult) {
							if ($arResult.workers.$worker) {
								$rh = [math]::Round($arResult.workers.$worker.hr / 1000 / 1000, 2)
								$ch = "-"
								$ah = [math]::Round($arResult.workers.$worker.hr2 / 1000 / 1000, 2)
								$out += "HASHRATE (REPORTED): "
								$out += $rh
								$out += " MH/s"
								$out += "`r`n"
								$out += "HASHRATE (AVERAGE): "
								$out += $ah
								$out += " MH/s"
								$result += "," + "H" + $num + ":" + $coin + "_mhs_"
								$result += $rh
								$result += "_"
								$result += $ch
								$result += "_"
								$result += $ah
							} else {
								$out += "ERROR: NO WORKER"
							}
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				"etherdig.net" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://etherdig.net/api/accounts/$address" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult) {
							if ($arResult.workers.$worker) {
								$rh = [math]::Round($arResult.workers.$worker.hr / 1000 / 1000, 2)
								$ch = "-"
								$ah = [math]::Round($arResult.workers.$worker.hr2 / 1000 / 1000, 2)
								$out += "HASHRATE (REPORTED): "
								$out += $rh
								$out += " MH/s"
								$out += "`r`n"
								$out += "HASHRATE (AVERAGE): "
								$out += $ah
								$out += " MH/s"
								$result += "," + "H" + $num + ":" + $coin + "_mhs_"
								$result += $rh
								$result += "_"
								$result += $ch
								$result += "_"
								$result += $ah
							} else {
								$out += "ERROR: NO WORKER"
							}
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				"www2.coinmine.pl" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://www2.coinmine.pl/eth/index.php?page=api&action=getuserworkers&api_key=$api&id=$id" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.getuserworkers) {
							foreach ($arWorker In $arResult.getuserworkers.data) {
								if ($arWorker.username -eq $worker) {
									$ah = [math]::Round($arWorker.hashrate / 1000, 2)
								}
							}
						}
						if ($ah -ne $null) {
							$rh = "-"
							$ch = "-"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " MH/s"
							$result += "," + "H" + $num + ":" + $coin + "_mhs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				"miningpoolhub.com" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://ethereum.miningpoolhub.com/index.php?page=api&action=getuserworkers&api_key=$api&id=$id" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.getuserworkers) {
							foreach ($arWorker In $arResult.getuserworkers.data) {
								if ($arWorker.username -eq $worker) {
									$ah = [math]::Round($arWorker.hashrate / 1000, 2)
								}
							}
						}
						if ($ah -ne $null) {
							$rh = "-"
							$ch = "-"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " MH/s"
							$result += "," + "H" + $num + ":" + $coin + "_mhs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				"antpool.com" {
					# берем hashrate по API
					$nonce = [String](Get-Date -UFormat %s -Millisecond 0)
					$message = $id + $api + $nonce
					$hmacsha = New-Object System.Security.Cryptography.HMACSHA256
					$hmacsha.key = [Text.Encoding]::UTF8.GetBytes($secret)
					$signature = $hmacsha.ComputeHash([Text.Encoding]::UTF8.GetBytes($message))
					$signature = [BitConverter]::ToString($signature)
					$signature = $signature.Replace("-", "").ToUpper()
					$coinu = $coin.ToUpper()
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://antpool.com/api/workers.htm?key=$api&nonce=$nonce&signature=$signature&coin=$coinu" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.code -eq "0" -and $arResult.message -eq "ok") {
							foreach ($arWorker In $arResult.data.rows) {
								if ($arWorker.worker -eq $worker) {
									$ch = [math]::Round([float]$arWorker.last10m, 2)
									$ah = [math]::Round([float]$arWorker.last1d, 2)
								}
							}
						} else {
							$out += "ERROR: " + $arResult.message
							$error = 1
						}
						if ($ch -ne $null -and $ah -ne $null) {
							$rh = "-"
							$out += "HASHRATE (CURRENT): "
							$out += $ch
							$out += " MH/s"
							$out += "`r`n"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " MH/s"
							$result += "," + "H" + $num + ":" + $coin + "_mhs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							if (-not $error) {
								$out += "ERROR: NO DATA"
							}
						}
					}
				}
				default {
					$out += "ERROR: POOL NOT SUPPORTED"
				}
			}
		}
		"etc" {
			switch ($pool) {
				"etc.ethermine.org" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://api-etc.ethermine.org/miner/:$address/worker/:$worker/currentStats" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.status -eq "OK") {
							if ($arResult.data -ne "NO DATA") {
								$rh = [math]::Round($arResult.data.reportedHashrate / 1000 / 1000, 2)
								$ch = [math]::Round($arResult.data.currentHashrate / 1000 / 1000, 2)
								$ah = [math]::Round($arResult.data.averageHashrate / 1000 / 1000, 2)
								$out += "HASHRATE (REPORTED): "
								$out += $rh
								$out += " MH/s"
								$out += "`r`n"
								$out += "HASHRATE (CURRENT): "
								$out += $ch
								$out += " MH/s"
								$out += "`r`n"
								$out += "HASHRATE (AVERAGE): "
								$out += $ah
								$out += " MH/s"
								$result += "," + "H" + $num + ":" + $coin + "_mhs_"
								$result += $rh
								$result += "_"
								$result += $ch
								$result += "_"
								$result += $ah
							} else {
								$out += "ERROR: NO DATA"
							}
						} else {
							$out += "ERROR"
						}
					}
				}
				"dwarfpool.com" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://dwarfpool.com/etc/api?wallet=$address&email=$pool_email" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.error -ne "True") {
							$rh = "-"
							$ch = [math]::Round($arResult.workers.$worker.hashrate, 2)
							$ah = [math]::Round($arResult.workers.$worker.hashrate_calculated, 2)
							$out += "HASHRATE (CURRENT): "
							$out += $ch
							$out += " MH/s"
							$out += "`r`n"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " MH/s"
							$result += "," + "H" + $num + ":" + $coin + "_mhs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: " + $arResult.error_code
						}
					}
				}
				"etc.nanopool.org" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://api.nanopool.org/v1/etc/avghashrateworkers/$address/1" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.status -eq "true") {
							foreach ($arWorker In $arResult.data) {
								if ($arWorker.worker -eq $worker) {
									$ch = [math]::Round($arWorker.hashrate, 2)
								}
							}
						}
						# берем hashrate по API
						try {
							$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://api.nanopool.org/v1/etc/avghashrateworkers/$address/6" -timeout 10 | ConvertFrom-Json
						} catch {
							$error = 1
							$out += "ERROR: FAILED TO GET URL"
						}
						if (-not $error) {
							# если есть данные
							if ($arResult.status -eq "true") {
								foreach ($arWorker In $arResult.data) {
									if ($arWorker.worker -eq $worker) {
										$ah = [math]::Round($arWorker.hashrate, 2)
									}
								}
							}
							if ($ch -ne $null -and $ah -ne $null) {
								$rh = "-"
								$out += "HASHRATE (CURRENT): "
								$out += $ch
								$out += " MH/s"
								$out += "`r`n"
								$out += "HASHRATE (AVERAGE): "
								$out += $ah
								$out += " MH/s"
								$result += "," + "H" + $num + ":" + $coin + "_mhs_"
								$result += $rh
								$result += "_"
								$result += $ch
								$result += "_"
								$result += $ah
							} else {
								$out += "ERROR: NO DATA"
							}
						}
					}
				}
				"www2.coinmine.pl" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://www2.coinmine.pl/etc/index.php?page=api&action=getuserworkers&api_key=$api&id=$id" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.getuserworkers) {
							foreach ($arWorker In $arResult.getuserworkers.data) {
								if ($arWorker.username -eq $worker) {
									$ah = [math]::Round($arWorker.hashrate / 1000, 2)
								}
							}
						}
						if ($ah -ne $null) {
							$rh = "-"
							$ch = "-"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " MH/s"
							$result += "," + "H" + $num + ":" + $coin + "_mhs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				"miningpoolhub.com" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://ethereum-classic.miningpoolhub.com/index.php?page=api&action=getuserworkers&api_key=$api&id=$id" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.getuserworkers) {
							foreach ($arWorker In $arResult.getuserworkers.data) {
								if ($arWorker.username -eq $worker) {
									$ah = [math]::Round($arWorker.hashrate / 1000, 2)
								}
							}
						}
						if ($ah -ne $null) {
							$rh = "-"
							$ch = "-"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " MH/s"
							$result += "," + "H" + $num + ":" + $coin + "_mhs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				default {
					$out += "ERROR: POOL NOT SUPPORTED"
				}
			}
		}
		"zec" {
			switch ($pool) {
				"zcash.flypool.org" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://api-zcash.flypool.org/miner/:$address/worker/:$worker/currentStats" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.status -eq "OK") {
							if ($arResult.data -ne "NO DATA") {
								$rh = [math]::Round($arResult.data.reportedHashrate, 2)
								$ch = [math]::Round($arResult.data.currentHashrate, 2)
								$ah = [math]::Round($arResult.data.averageHashrate, 2)
								$out += "HASHRATE (CURRENT): "
								$out += $ch
								$out += " Sol/s"
								$out += "`r`n"
								$out += "HASHRATE (AVERAGE): "
								$out += $ah
								$out += " Sol/s"
								$result += "," + "H" + $num + ":" + $coin + "_sols_"
								$result += $rh
								$result += "_"
								$result += $ch
								$result += "_"
								$result += $ah
							} else {
								$out += "ERROR: NO DATA"
							}
						} else {
							$out += "ERROR"
						}
					}
				}
				"dwarfpool.com" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://dwarfpool.com/zec/api?wallet=$address&email=$pool_email" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
					# если есть данные
						if ($arResult.error -ne "True") {
							$rh = "-"
							$ch = [math]::Round($arResult.workers.$worker.hashrate, 2)
							$ah = [math]::Round($arResult.workers.$worker.hashrate_calculated, 2)
							$out += "HASHRATE (CURRENT): "
							$out += $ch
							$out += " Sol/s"
							$out += "`r`n"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " Sol/s"
							$result += "," + "H" + $num + ":" + $coin + "_sols_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: " + $arResult.error_code
						}
					}
				}
				"zec.nanopool.org" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://api.nanopool.org/v1/zec/avghashrateworkers/$address/1" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.status -eq "true") {
							foreach ($arWorker In $arResult.data) {
								if ($arWorker.worker -eq $worker) {
									$ch = [math]::Round($arWorker.hashrate, 2)
								}
							}
						}
						# берем hashrate по API
						try {
							$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://api.nanopool.org/v1/zec/avghashrateworkers/$address/6" -timeout 10 | ConvertFrom-Json
						} catch {
							$error = 1
							$out += "ERROR: FAILED TO GET URL"
						}
						if (-not $error) {
							# если есть данные
							if ($arResult.status -eq "true") {
								foreach ($arWorker In $arResult.data) {
									if ($arWorker.worker -eq $worker) {
										$ah = [math]::Round($arWorker.hashrate, 2)
									}
								}
							}
							if ($ch -ne $null -and $ah -ne $null) {
								$rh = "-"
								$out += "HASHRATE (CURRENT): "
								$out += $ch
								$out += " Sol/s"
								$out += "`r`n"
								$out += "HASHRATE (AVERAGE): "
								$out += $ah
								$out += " Sol/s"
								$result += "," + "H" + $num + ":" + $coin + "_sols_"
								$result += $rh
								$result += "_"
								$result += $ch
								$result += "_"
								$result += $ah
							} else {
								$out += "ERROR: NO DATA"
							}
						}
					}
				}
				"www2.coinmine.pl" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://www2.coinmine.pl/zec/index.php?page=api&action=getuserworkers&api_key=$api&id=$id" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.getuserworkers) {
							foreach ($arWorker In $arResult.getuserworkers.data) {
								if ($arWorker.username -eq $worker) {
									$ah = [math]::Round($arWorker.hashrate, 2)
								}
							}
						}
						if ($ah -ne $null) {
							$rh = "-"
							$ch = "-"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " Sol/s"
							$result += "," + "H" + $num + ":" + $coin + "_sols_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				"zec.suprnova.cc" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://zec.suprnova.cc/index.php?page=api&action=getuserworkers&api_key=$api&id=$id" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.getuserworkers) {
							foreach ($arWorker In $arResult.getuserworkers.data) {
								if ($arWorker.username -eq $worker) {
									$ah = [math]::Round($arWorker.hashrate, 2)
								}
							}
						}
						if ($ah -ne $null) {
							$rh = "-"
							$ch = "-"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " Sol/s"
							$result += "," + "H" + $num + ":" + $coin + "_sols_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				"miningpoolhub.com" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://zcash.miningpoolhub.com/index.php?page=api&action=getuserworkers&api_key=$api&id=$id" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.getuserworkers) {
							foreach ($arWorker In $arResult.getuserworkers.data) {
								if ($arWorker.username -eq $worker) {
									$ah = [math]::Round($arWorker.hashrate * 1000, 2)
								}
							}
						}
						if ($ah -ne $null) {
							$rh = "-"
							$ch = "-"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " Sol/s"
							$result += "," + "H" + $num + ":" + $coin + "_sols_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				"antpool.com" {
					# берем hashrate по API
					$nonce = [String](Get-Date -UFormat %s -Millisecond 0)
					$message = $id + $api + $nonce
					$hmacsha = New-Object System.Security.Cryptography.HMACSHA256
					$hmacsha.key = [Text.Encoding]::UTF8.GetBytes($secret)
					$signature = $hmacsha.ComputeHash([Text.Encoding]::UTF8.GetBytes($message))
					$signature = [BitConverter]::ToString($signature)
					$signature = $signature.Replace("-", "").ToUpper()
					$coinu = $coin.ToUpper()
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://antpool.com/api/workers.htm?key=$api&nonce=$nonce&signature=$signature&coin=$coinu" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.code -eq "0" -and $arResult.message -eq "ok") {
							foreach ($arWorker In $arResult.data.rows) {
								if ($arWorker.worker -eq $worker) {
									$ch = [math]::Round([float]$arWorker.last10m * 1000 * 1000, 2)
									$ah = [math]::Round([float]$arWorker.last1d * 1000 * 1000, 2)
								}
							}
						} else {
							$out += "ERROR: " + $arResult.message
							$error = 1
						}
						if ($ch -ne $null -and $ah -ne $null) {
							$rh = "-"
							$out += "HASHRATE (CURRENT): "
							$out += $ch
							$out += " Sol/s"
							$out += "`r`n"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " Sol/s"
							$result += "," + "H" + $num + ":" + $coin + "_sols_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							if (-not $error) {
								$out += "ERROR: NO DATA"
							}
						}
					}
				}
				default {
					$out += "ERROR: POOL NOT SUPPORTED"
				}
			}
		}
		"xmr" {
			switch ($pool) {
				"dwarfpool.com" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://dwarfpool.com/xmr/api?wallet=$address&email=$pool_email" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.error -ne "True") {
							$rh = "-"
							$ch = [math]::Round($arResult.workers.$worker.hashrate * 1000, 2)
							$ah = [math]::Round($arResult.workers.$worker.hashrate_calculated * 1000, 2)
							$out += "HASHRATE (CURRENT): "
							$out += $ch
							$out += " H/s"
							$out += "`r`n"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " H/s"
							$result += "," + "H" + $num + ":" + $coin + "_hs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: " + $arResult.error_code
						}
					}
				}
				"xmr.nanopool.org" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://api.nanopool.org/v1/xmr/avghashrateworkers/$address/1" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.status -eq "true") {
							foreach ($arWorker In $arResult.data) {
								if ($arWorker.worker -eq $worker) {
									$ch = [math]::Round($arWorker.hashrate, 2)
								}
							}
						}
						# берем hashrate по API
						try {
							$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://api.nanopool.org/v1/xmr/avghashrateworkers/$address/6" -timeout 10 | ConvertFrom-Json
						} catch {
							$error = 1
							$out += "ERROR: FAILED TO GET URL"
						}
						if (-not $error) {
							# если есть данные
							if ($arResult.status -eq "true") {
								foreach ($arWorker In $arResult.data) {
									if ($arWorker.worker -eq $worker) {
										$ah = [math]::Round($arWorker.hashrate, 2)
									}
								}
							}
							if ($ch -ne $null -and $ah -ne $null) {
								$rh = "-"
								$out += "HASHRATE (CURRENT): "
								$out += $ch
								$out += " H/s"
								$out += "`r`n"
								$out += "HASHRATE (AVERAGE): "
								$out += $ah
								$out += " H/s"
								$result += "," + "H" + $num + ":" + $coin + "_hs_"
								$result += $rh
								$result += "_"
								$result += $ch
								$result += "_"
								$result += $ah
							} else {
								$out += "ERROR: NO DATA"
							}
						}
					}
				}
				"minemonero.pro" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://api.minemonero.pro/miner/$address/stats/$worker" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.hash) {
							$rh = [math]::Round($arResult.hash, 2)
						}
						# берем hashrate по API
						try {
							$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://api.minemonero.pro/miner/$address/chart/hashrate/$worker" -timeout 10 | ConvertFrom-Json
						} catch {
							$error = 1
							$out += "ERROR: FAILED TO GET URL"
						}
						if (-not $error) {
							# если есть данные
							if ($arResult) {
								$c = 0
								$ah = 0
								foreach ($arStat In $arResult) {
									$c = $c + 1
									$ah = $ah + [math]::Round($arStat.hs, 2)
								}
								$ah = [math]::Round($ah / $c, 2)
							}
							if ($rh -ne $null -and $ah -ne $null) {
								$ch = "-"
								$out += "HASHRATE (REPORTED): "
								$out += $rh
								$out += " H/s"
								$out += "`r`n"
								$out += "HASHRATE (AVERAGE): "
								$out += $ah
								$out += " H/s"
								$result += "," + "H" + $num + ":" + $coin + "_hs_"
								$result += $rh
								$result += "_"
								$result += $ch
								$result += "_"
								$result += $ah
							} else {
								$out += "ERROR: NO DATA"
							}
						}
					}
				}
				"miningpoolhub.com" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://monero.miningpoolhub.com/index.php?page=api&action=getuserworkers&api_key=$api&id=$id" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.getuserworkers) {
							foreach ($arWorker In $arResult.getuserworkers.data) {
								if ($arWorker.username -eq $worker) {
									$ah = [math]::Round($arWorker.hashrate, 2)
								}
							}
						}
						if ($ah -ne $null) {
							$rh = "-"
							$ch = "-"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " H/s"
							$result += "," + "H" + $num + ":" + $coin + "_hs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				"xmr.suprnova.cc" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://xmr.suprnova.cc/index.php?page=api&action=getuserworkers&api_key=$api&id=$id" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.getuserworkers) {
							foreach ($arWorker In $arResult.getuserworkers.data) {
								if ($arWorker.username -eq $worker) {
									$ah = [math]::Round($arWorker.hashrate, 2)
								}
							}
						}
						if ($ah -ne $null) {
							$rh = "-"
							$ch = "-"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " H/s"
							$result += "," + "H" + $num + ":" + $coin + "_hs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				default {
					$out += "ERROR: POOL NOT SUPPORTED"
				}
			}
		}
		"exp" {
			switch ($pool) {
				"dwarfpool.com" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://dwarfpool.com/exp/api?wallet=$address&email=$pool_email" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.error -ne "True") {
							$rh = "-"
							$ch = [math]::Round($arResult.workers.$worker.hashrate, 2)
							$ah = [math]::Round($arResult.workers.$worker.hashrate_calculated, 2)
							$out += "HASHRATE (CURRENT): "
							$out += $ch
							$out += " MH/s"
							$out += "`r`n"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " MH/s"
							$result += "," + "H" + $num + ":" + $coin + "_mhs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: " + $arResult.error_code
						}
					}
				}
				"www2.coinmine.pl" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://www2.coinmine.pl/exp/index.php?page=api&action=getuserworkers&api_key=$api&id=$id" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.getuserworkers) {
							foreach ($arWorker In $arResult.getuserworkers.data) {
								if ($arWorker.username -eq $worker) {
									$ah = [math]::Round($arWorker.hashrate / 1000, 2)
								}
							}
						}
						if ($ah -ne $null) {
							$rh = "-"
							$ch = "-"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " MH/s"
							$result += "," + "H" + $num + ":" + $coin + "_mhs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				"miningpoolhub.com" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://expanse.miningpoolhub.com/index.php?page=api&action=getuserworkers&api_key=$api&id=$id" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.getuserworkers) {
							foreach ($arWorker In $arResult.getuserworkers.data) {
								if ($arWorker.username -eq $worker) {
									$ah = [math]::Round($arWorker.hashrate / 1000, 2)
								}
							}
						}
						if ($ah -ne $null) {
							$rh = "-"
							$ch = "-"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " MH/s"
							$result += "," + "H" + $num + ":" + $coin + "_mhs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				"expmine.pro" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://expmine.pro/api/accounts/$address" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.workers.$worker) {
							$ch = [math]::Round($arResult.workers.$worker.hr / 1000 / 1000, 2)
							$ah = [math]::Round($arResult.workers.$worker.hr2 / 1000 / 1000, 2)
						}
						if ($ah -ne $null) {
							$rh = "-"
							$out += "HASHRATE (CURRENT): "
							$out += $ch
							$out += " MH/s"
							$out += "`r`n"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " MH/s"
							$result += "," + "H" + $num + ":" + $coin + "_mhs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				default {
					$out += "ERROR: POOL NOT SUPPORTED"
				}
			}
		}
		"grs" {
			switch ($pool) {
				"dwarfpool.com" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://dwarfpool.com/grs/api?wallet=$address&email=$pool_email" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.error -ne "True") {
							$rh = "-"
							$ch = [math]::Round($arResult.workers.$worker.hashrate, 2)
							$ah = [math]::Round($arResult.workers.$worker.hashrate_calculated, 2)
							$out += "HASHRATE (CURRENT): "
							$out += $ch
							$out += " MH/s"
							$out += "`r`n"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " MH/s"
							$result += "," + "H" + $num + ":" + $coin + "_mhs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: " + $arResult.error_code
						}
					}
				}
				"www2.coinmine.pl" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://www2.coinmine.pl/grs/index.php?page=api&action=getuserworkers&api_key=$api&id=$id" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.getuserworkers) {
							foreach ($arWorker In $arResult.getuserworkers.data) {
								if ($arWorker.username -eq $worker) {
									$ah = [math]::Round($arWorker.hashrate / 1000, 2)
								}
							}
						}
						if ($ah -ne $null) {
							$rh = "-"
							$ch = "-"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " MH/s"
							$result += "," + "H" + $num + ":" + $coin + "_mhs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				"miningpoolhub.com" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://groestlcoin.miningpoolhub.com/index.php?page=api&action=getuserworkers&api_key=$api&id=$id" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.getuserworkers) {
							foreach ($arWorker In $arResult.getuserworkers.data) {
								if ($arWorker.username -eq $worker) {
									$ah = [math]::Round($arWorker.hashrate / 1000, 2)
								}
							}
						}
						if ($ah -ne $null) {
							$rh = "-"
							$ch = "-"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " MH/s"
							$result += "," + "H" + $num + ":" + $coin + "_mhs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				default {
					$out += "ERROR: POOL NOT SUPPORTED"
				}
			}
		}
		"pasc" {
			switch ($pool) {
				"pasc.nanopool.org" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://api.nanopool.org/v1/pasc/avghashrateworkers/$address/1" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.status -eq "true") {
							foreach ($arWorker In $arResult.data) {
								if ($arWorker.worker -eq $worker) {
									$ch = [math]::Round($arWorker.hashrate, 2)
								}
							}
						}
						# берем hashrate по API
						try {
							$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://api.nanopool.org/v1/pasc/avghashrateworkers/$address/6" -timeout 10 | ConvertFrom-Json
						} catch {
							$error = 1
							$out += "ERROR: FAILED TO GET URL"
						}
						if (-not $error) {
							# если есть данные
							if ($arResult.status -eq "true") {
								foreach ($arWorker In $arResult.data) {
									if ($arWorker.worker -eq $worker) {
										$ah = [math]::Round($arWorker.hashrate, 2)
									}
								}
							}
							if ($ch -ne $null -and $ah -ne $null) {
								$rh = "-"
								$out += "HASHRATE (CURRENT): "
								$out += $ch
								$out += " MH/s"
								$out += "`r`n"
								$out += "HASHRATE (AVERAGE): "
								$out += $ah
								$out += " MH/s"
								$result += "," + "H" + $num + ":" + $coin + "_mhs_"
								$result += $rh
								$result += "_"
								$result += $ch
								$result += "_"
								$result += $ah
							} else {
								$out += "ERROR: NO DATA"
							}
						}
					}
				}
				default {
					$out += "ERROR: POOL NOT SUPPORTED"
				}
			}
		}
		"sia" {
			switch ($pool) {
				"sia.nanopool.org" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://api.nanopool.org/v1/sia/avghashrateworkers/$address/1" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.status -eq "true") {
							foreach ($arWorker In $arResult.data) {
								if ($arWorker.worker -eq $worker) {
									$ch = [math]::Round($arWorker.hashrate, 2)
								}
							}
						}
						# берем hashrate по API
						try {
							$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://api.nanopool.org/v1/sia/avghashrateworkers/$address/6" -timeout 10 | ConvertFrom-Json
						} catch {
							$error = 1
							$out += "ERROR: FAILED TO GET URL"
						}
						if (-not $error) {
							# если есть данные
							if ($arResult.status -eq "true") {
								foreach ($arWorker In $arResult.data) {
									if ($arWorker.worker -eq $worker) {
										$ah = [math]::Round($arWorker.hashrate, 2)
									}
								}
							}
							if ($ch -ne $null -and $ah -ne $null) {
								$rh = "-"
								$out += "HASHRATE (CURRENT): "
								$out += $ch
								$out += " MH/s"
								$out += "`r`n"
								$out += "HASHRATE (AVERAGE): "
								$out += $ah
								$out += " MH/s"
								$result += "," + "H" + $num + ":" + $coin + "_mhs_"
								$result += $rh
								$result += "_"
								$result += $ch
								$result += "_"
								$result += $ah
							} else {
								$out += "ERROR: NO DATA"
							}
						}
					}
				}
				"siamining.com" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://siamining.com/api/v1/addresses/$address/workers" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult) {
							foreach ($arWorker In $arResult) {
								if ($arWorker.name -eq "$worker") {
									$ch = [math]::Round($arWorker.intervals[0].hash_rate / 1000 / 1000, 2)
									$ah = [math]::Round($arWorker.intervals[3].hash_rate / 1000 / 1000, 2)
								}
							}
						}
						if ($ch -ne $null -and $ah -ne $null) {
							$rh = "-"
							$out += "HASHRATE (CURRENT): "
							$out += $ch
							$out += " MH/s"
							$out += "`r`n"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " MH/s"
							$result += "," + "H" + $num + ":" + $coin + "_mhs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				"miningpoolhub.com" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://siacoin.miningpoolhub.com/index.php?page=api&action=getuserworkers&api_key=$api&id=$id" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.getuserworkers) {
							foreach ($arWorker In $arResult.getuserworkers.data) {
								if ($arWorker.username -eq $worker) {
									$ah = [math]::Round($arWorker.hashrate / 1000, 2)
								}
							}
						}
						if ($ah -ne $null) {
							$rh = "-"
							$ch = "-"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " MH/s"
							$result += "," + "H" + $num + ":" + $coin + "_mhs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				default {
					$out += "ERROR: POOL NOT SUPPORTED"
				}
			}
		}
		"lbc" {
			switch ($pool) {
				"www2.coinmine.pl" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://www2.coinmine.pl/lbc/index.php?page=api&action=getuserworkers&api_key=$api&id=$id" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.getuserworkers) {
							foreach ($arWorker In $arResult.getuserworkers.data) {
								if ($arWorker.username -eq $worker) {
									$ah = [math]::Round($arWorker.hashrate / 1000, 2)
								}
							}
						}
						if ($ah -ne $null) {
							$rh = "-"
							$ch = "-"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " MH/s"
							$result += "," + "H" + $num + ":" + $coin + "_mhs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				"lbry.suprnova.cc" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://lbry.suprnova.cc/index.php?page=api&action=getuserworkers&api_key=$api&id=$id" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.getuserworkers) {
							foreach ($arWorker In $arResult.getuserworkers.data) {
								if ($arWorker.username -eq $worker) {
									$ah = [math]::Round($arWorker.hashrate / 1000, 2)
								}
							}
						}
						if ($ah -ne $null) {
							$rh = "-"
							$ch = "-"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " MH/s"
							$result += "," + "H" + $num + ":" + $coin + "_mhs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				default {
					$out += "ERROR: POOL NOT SUPPORTED"
				}
			}
		}
		"dcr" {
			switch ($pool) {
				"www2.coinmine.pl" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://www2.coinmine.pl/dcr/index.php?page=api&action=getuserworkers&api_key=$api&id=$id" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.getuserworkers) {
							foreach ($arWorker In $arResult.getuserworkers.data) {
								if ($arWorker.username -eq $worker) {
									$ah = [math]::Round($arWorker.hashrate / 1000, 2)
								}
							}
						}
						if ($ah -ne $null) {
							$rh = "-"
							$ch = "-"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " MH/s"
							$result += "," + "H" + $num + ":" + $coin + "_mhs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				"dcr.suprnova.cc" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://dcr.suprnova.cc/index.php?page=api&action=getuserworkers&api_key=$api&id=$id" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.getuserworkers) {
							foreach ($arWorker In $arResult.getuserworkers.data) {
								if ($arWorker.username -eq $worker) {
									$ah = [math]::Round($arWorker.hashrate / 1000, 2)
								}
							}
						}
						if ($ah -ne $null) {
							$rh = "-"
							$ch = "-"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " MH/s"
							$result += "," + "H" + $num + ":" + $coin + "_mhs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				default {
					$out += "ERROR: POOL NOT SUPPORTED"
				}
			}
		}
		"zen" {
			switch ($pool) {
				"zen.suprnova.cc" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://zen.suprnova.cc/index.php?page=api&action=getuserworkers&api_key=$api&id=$id" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.getuserworkers) {
							foreach ($arWorker In $arResult.getuserworkers.data) {
								if ($arWorker.username -eq $worker) {
									$ah = [math]::Round($arWorker.hashrate / 1000, 2)
								}
							}
						}
						if ($ah -ne $null) {
							$rh = "-"
							$ch = "-"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " H/s"
							$result += "," + "H" + $num + ":" + $coin + "_hs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				"zenmine.pro" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://zenmine.pro/api/accounts/$address" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.workers.$worker) {
							$ch = [math]::Round($arResult.workers.$worker.hr, 2)
							$ah = [math]::Round($arResult.workers.$worker.hr2, 2)
						}
						if ($ah -ne $null) {
							$rh = "-"
							$out += "HASHRATE (CURRENT): "
							$out += $ch
							$out += " MH/s"
							$out += "`r`n"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " H/s"
							$result += "," + "H" + $num + ":" + $coin + "_hs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				# "zhash.pro" {
				# 	# берем hashrate по API
				# 	try {
				# 		$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://zhash.pro/api/worker_stats?$address" -timeout 10 | ConvertFrom-Json
				# 	} catch {
				# 		$error = 1
				# 		$out += "ERROR: FAILED TO GET URL"
				# 	}
				# 	if (-not $error) {
				# 		# если есть данные
				# 		if ($arResult.workers."$arrdess.$worker") {
				# 			$ah = [math]::Round($arResult.workers."$address.$worker".hashrate, 2)
				# 		}
				# 		if ($ah -ne $null) {
				# 			$rh = "-"
				# 			$ch = "-"
				# 			$out += "HASHRATE (AVERAGE): "
				# 			$out += $ah
				# 			$out += " H/s"
				# 			$result += "," + "H" + $num + ":" + $coin + "_hs_"
				# 			$result += $rh
				# 			$result += "_"
				# 			$result += $ch
				# 			$result += "_"
				# 			$result += $ah
				# 		} else {
				# 			$out += "ERROR: NO DATA"
				# 		}
				# 	}
				# }
				default {
					$out += "ERROR: POOL NOT SUPPORTED"
				}
			}
		}
		"sib" {
			switch ($pool) {
				"sib.suprnova.cc" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://sib.suprnova.cc/index.php?page=api&action=getuserworkers&api_key=$api&id=$id" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.getuserworkers) {
							foreach ($arWorker In $arResult.getuserworkers.data) {
								if ($arWorker.username -eq $worker) {
									$ah = [math]::Round($arWorker.hashrate / 1000, 2)
								}
							}
						}
						if ($ah -ne $null) {
							$rh = "-"
							$ch = "-"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " MH/s"
							$result += "," + "H" + $num + ":" + $coin + "_mhs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				default {
					$out += "ERROR: POOL NOT SUPPORTED"
				}
			}
		}
		"mona" {
			switch ($pool) {
				"mona.suprnova.cc" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://mona.suprnova.cc/index.php?page=api&action=getuserworkers&api_key=$api&id=$id" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.getuserworkers) {
							foreach ($arWorker In $arResult.getuserworkers.data) {
								if ($arWorker.username -eq $worker) {
									$ah = [math]::Round($arWorker.hashrate / 1000, 2)
								}
							}
						}
						if ($ah -ne $null) {
							$rh = "-"
							$ch = "-"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " KH/s"
							$result += "," + "H" + $num + ":" + $coin + "_khs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				default {
					$out += "ERROR: POOL NOT SUPPORTED"
				}
			}
		}
		"sigt" {
			switch ($pool) {
				"sigt.suprnova.cc" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://sigt.suprnova.cc/index.php?page=api&action=getuserworkers&api_key=$api&id=$id" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.getuserworkers) {
							foreach ($arWorker In $arResult.getuserworkers.data) {
								if ($arWorker.username -eq $worker) {
									$ah = [math]::Round($arWorker.hashrate / 1000, 2)
								}
							}
						}
						if ($ah -ne $null) {
							$rh = "-"
							$ch = "-"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " MH/s"
							$result += "," + "H" + $num + ":" + $coin + "_mhs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				default {
					$out += "ERROR: POOL NOT SUPPORTED"
				}
			}
		}
		"zcl" {
			switch ($pool) {
				"miningpoolhub.com" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://zclassic.miningpoolhub.com/index.php?page=api&action=getuserworkers&api_key=$api&id=$id" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.getuserworkers) {
							foreach ($arWorker In $arResult.getuserworkers.data) {
								if ($arWorker.username -eq $worker) {
									$ah = [math]::Round($arWorker.hashrate, 2)
								}
							}
						}
						if ($ah -ne $null) {
							$rh = "-"
							$ch = "-"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " H/s"
							$result += "," + "H" + $num + ":" + $coin + "_hs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				"zcl.suprnova.cc" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://zcl.suprnova.cc/index.php?page=api&action=getuserworkers&api_key=$api&id=$id" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.getuserworkers) {
							foreach ($arWorker In $arResult.getuserworkers.data) {
								if ($arWorker.username -eq $worker) {
									$ah = [math]::Round($arWorker.hashrate, 2)
								}
							}
						}
						if ($ah -ne $null) {
							$rh = "-"
							$ch = "-"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " H/s"
							$result += "," + "H" + $num + ":" + $coin + "_hs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				"www2.coinmine.pl" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://www2.coinmine.pl/zcl/index.php?page=api&action=getuserworkers&api_key=$api&id=$id" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.getuserworkers) {
							foreach ($arWorker In $arResult.getuserworkers.data) {
								if ($arWorker.username -eq $worker) {
									$ah = [math]::Round($arWorker.hashrate, 2)
								}
							}
						}
						if ($ah -ne $null) {
							$rh = "-"
							$ch = "-"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " H/s"
							$result += "," + "H" + $num + ":" + $coin + "_hs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				# "zhash.pro" {
				# 	# берем hashrate по API
				# 	try {
				# 		$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://zhash.pro/api/worker_stats?$address" -timeout 10 | ConvertFrom-Json
				# 	} catch {
				# 		$error = 1
				# 		$out += "ERROR: FAILED TO GET URL"
				# 	}
				# 	if (-not $error) {
				# 		# если есть данные
				# 		if ($arResult.workers."$arrdess.$worker") {
				# 			$ah = [math]::Round($arResult.workers."$address.$worker".hashrate, 2)
				# 		}
				# 		if ($ah -ne $null) {
				# 			$rh = "-"
				# 			$ch = "-"
				# 			$out += "HASHRATE (AVERAGE): "
				# 			$out += $ah
				# 			$out += " H/s"
				# 			$result += "," + "H" + $num + ":" + $coin + "_hs_"
				# 			$result += $rh
				# 			$result += "_"
				# 			$result += $ch
				# 			$result += "_"
				# 			$result += $ah
				# 		} else {
				# 			$out += "ERROR: NO DATA"
				# 		}
				# 	}
				# }
				default {
					$out += "ERROR: POOL NOT SUPPORTED"
				}
			}
		}
		"xzc" {
			switch ($pool) {
				"miningpoolhub.com" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "https://zcoin.miningpoolhub.com/index.php?page=api&action=getuserworkers&api_key=$api&id=$id" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult.getuserworkers) {
							foreach ($arWorker In $arResult.getuserworkers.data) {
								if ($arWorker.username -eq $worker) {
									$ah = [math]::Round($arWorker.hashrate, 2)
								}
							}
						}
						if ($ah -ne $null) {
							$rh = "-"
							$ch = "-"
							$out += "HASHRATE (AVERAGE): "
							$out += $ah
							$out += " KH/s"
							$result += "," + "H" + $num + ":" + $coin + "_khs_"
							$result += $rh
							$result += "_"
							$result += $ch
							$result += "_"
							$result += $ah
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				default {
					$out += "ERROR: POOL NOT SUPPORTED"
				}
			}
		}
		"whl" {
			switch ($pool) {
				"whale.minerpool.net" {
					# берем hashrate по API
					try {
						$arResult = Invoke-WebRequest -UseBasicParsing -Uri "http://whale.minerpool.net/api/accounts/$address" -timeout 10 | ConvertFrom-Json
					} catch {
						$error = 1
						$out += "ERROR: FAILED TO GET URL"
					}
					if (-not $error) {
						# если есть данные
						if ($arResult) {
							if ($arResult.workers.$worker) {
								$rh = [math]::Round($arResult.workers.$worker.hr / 1000 / 1000, 2)
								$ch = "-"
								$ah = [math]::Round($arResult.workers.$worker.hr2 / 1000 / 1000, 2)
								$out += "HASHRATE (REPORTED): "
								$out += $rh
								$out += " MH/s"
								$out += "`r`n"
								$out += "HASHRATE (AVERAGE): "
								$out += $ah
								$out += " MH/s"
								$result += "," + "H" + $num + ":" + $coin + "_mhs_"
								$result += $rh
								$result += "_"
								$result += $ch
								$result += "_"
								$result += $ah
							} else {
								$out += "ERROR: NO WORKER"
							}
						} else {
							$out += "ERROR: NO DATA"
						}
					}
				}
				default {
					$out += "ERROR: POOL NOT SUPPORTED"
				}
			}
		}
		default {
			$out += "ERROR: COIN NOT SUPPORTED"
		}
	}
	$out += "`r`n"
	$r = @{}
	$r += @{"out" = $out}
	$r += @{"result" = $result}
	return $r
}

# первая монета
if (($Env:coin1 -and $Env:pool1 -and $Env:address1 -and $Env:worker1) -or ($Env:coin1 -and $Env:pool1 -and $Env:api1 -and $Env:id1 -and $Env:worker1) -or ($Env:coin1 -and $Env:pool1 -and $Env:api1 -and $Env:secret1 -and $Env:id1 -and $Env:worker1)) {
	$arResult = Get-Hashrate -out $out -result $result -num "1" -coin $Env:coin1 -pool $Env:pool1 -address $Env:address1 -worker $Env:worker1 -pool_email $Env:pool_email1 -api $Env:api1 -secret $Env:secret1 -id $Env:id1
	$out = $arResult."out"
	$result = $arResult."result"
}

# вторая монета
if (($Env:coin2 -and $Env:pool2 -and $Env:address2 -and $Env:worker2) -or ($Env:coin2 -and $Env:pool2 -and $Env:api2 -and $Env:id2 -and $Env:worker2) -or ($Env:coin2 -and $Env:pool2 -and $Env:api2 -and $Env:secret2 -and $Env:id2 -and $Env:worker2)) {
	$arResult = Get-Hashrate -out $out -result $result -num "2" -coin $Env:coin2 -pool $Env:pool2 -address $Env:address2 -worker $Env:worker2 -pool_email $Env:pool_email2 -api $Env:api2 -secret $Env:secret2 -id $Env:id2
	$out = $arResult."out"
	$result = $arResult."result"
}
