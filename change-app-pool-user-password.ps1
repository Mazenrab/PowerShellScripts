# Параметры
$credentials = (Get-Credential -Message "Введите новую учётную запись. Проверка корректности не проводится!").GetNetworkCredential()

$targetUser = $credentials.UserName

# Импорт модуля
Import-Module WebAdministration

Write-Host "=== Начало обновления паролей App Pool ===" -ForegroundColor Cyan

# Получаем все пулы для указанного пользователя
$appPoolsToUpdate = @()

# Обновляем ВСЕ пулы для этого пользователя
$allPools = Get-ChildItem IIS:\AppPools
foreach ($pool in $allPools) {    
    if ($pool.processModel.userName -eq $targetUser) {
        $appPoolsToUpdate += $pool.Name
    }
}

if ($appPoolsToUpdate.Count -eq 0) {
    Write-Host "App Pool для обновления не найдены" -ForegroundColor Yellow
    exit
}

Write-Host "Будут обновлены следующие App Pool:" -ForegroundColor Green
$appPoolsToUpdate | ForEach-Object { Write-Host "  - $_" }

# Подтверждение
$confirmation = Read-Host "`nПродолжить обновление пароля? (Y/N)"
if ($confirmation -ne 'Y' -and $confirmation -ne 'y') {
    Write-Host "Обновление отменено" -ForegroundColor Yellow
    exit
}

# Логирование
$logFile = "C:\Temp\AppPool_Password_Update_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
"=== Лог обновления паролей App Pool ===" | Out-File $logFile
"Дата: $(Get-Date)" | Out-File $logFile -Append
"Пользователь: $targetUser" | Out-File $logFile -Append
"`n" | Out-File $logFile -Append

# Обновление паролей
$successCount = 0
$errorCount = 0

foreach ($appPoolName in $appPoolsToUpdate) {
    try {
        Write-Host "`nОбработка: $appPoolName" -ForegroundColor Cyan
        
        # Проверяем существование пула
        $pool = Get-Item "IIS:\AppPools\$appPoolName" -ErrorAction Stop
        
        # Сохраняем текущие настройки
        $currentUser = $pool.processModel.userName
        
        # Обновляем пароль
        Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name processModel -Value @{userName=$targetUser;password=$credentials.Password;identitytype=3}
        
        Write-Host "  ✓ Пароль обновлен" -ForegroundColor Green
        
        # Перезапускаем пул
        Restart-WebAppPool -Name $appPoolName -ErrorAction Stop
        Write-Host "  ✓ App Pool перезапущен" -ForegroundColor Green
        
        # Логируем успех
        "[УСПЕХ] $appPoolName - пароль обновлен и пул перезапущен" | Out-File $logFile -Append
        $successCount++
        
        # Небольшая пауза между обработкой пулов
        Start-Sleep -Seconds 2
        
    } catch {
        $errorMsg = "Ошибка при обработке $appPoolName : $_"
        Write-Host "  ✗ $errorMsg" -ForegroundColor Red
        "[ОШИБКА] $errorMsg" | Out-File $logFile -Append
        $errorCount++
    }
}

# Итоги
Write-Host "`n=== Результаты обновления ===" -ForegroundColor Cyan
Write-Host "Успешно обновлено: $successCount" -ForegroundColor Green
Write-Host "С ошибками: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Host "Лог сохранен: $logFile" -ForegroundColor Yellow

# Перезапуск IIS (опционально)
$restartIIS = Read-Host "`nПерезапустить IIS полностью? (Y/N)"
if ($restartIIS -eq 'Y' -or $restartIIS -eq 'y') {
    try {
        iisreset
        Write-Host "IIS перезапущен" -ForegroundColor Green
        "[ИНФО] IIS перезапущен" | Out-File $logFile -Append
    } catch {
        Write-Host "Ошибка при перезапуске IIS: $_" -ForegroundColor Red
    }
}