# Dosya yolu ve izleme dosyası tanımları
$dinlenecekDosya = "C:\deneme\deneme.txt"
$backupDosya = "C:\deneme\deneme_backup.txt"

# İlk dosya durumunu yedekle
Copy-Item -Path $dinlenecekDosya -Destination $backupDosya -Force

# Değişiklik zaman damgası
$lastChangeTime = Get-Date

# FileSystemWatcher nesnesini oluşturma
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = (Get-Item $dinlenecekDosya).DirectoryName
$watcher.Filter = (Get-Item $dinlenecekDosya).Name
$watcher.IncludeSubdirectories = $false  # Sadece belirtilen dosyayı izle
$watcher.NotifyFilter = [System.IO.NotifyFilters]'LastWrite, FileName, DirectoryName'

# E-posta gönderme işlevi tanımlama
function Send-Email {
    param (
        [string]$changeDetails,
        [string]$path,
        [DateTime]$timestamp
    )

    # E-posta gönderme
    $smtpServer = "smtp.gmail.com"
    $smtpPort = 587
    $smtpFrom = "sezeraksoy53@gmail.com" # Birden fazla alıcı eklemek için @("mail@mail.com", "mail2@mail.com")
    $smtpTo = "sezeraksoy@hotmail.com"
    $messageSubject = "Dosya Değişikliği Tespiti"
    $messageBody = @"
<html>
<head>
<style>
    body { font-family: 'Courier New', Courier, monospace; }
    .added { background-color: #d4fcbc; }
    .deleted { background-color: #fbc2c4; }
    .changed { background-color: #fff2b4; }
</style>
</head>
<body>
    <h2>Dosya: $path</h2>
    <h3>Değişiklikler:</h3>
    <pre>$changeDetails</pre>
    <h3>Değişiklik Zamanı: $timestamp</h3>
</body>
</html>
"@
    $smtpUsername = "sezeraksoy53@gmail.com"  # Gmail hesabının e-posta adresi
    $smtpPassword = "UygulamaŞifresi"         # Gmail uygulama şifresi

    $message = New-Object Net.Mail.MailMessage
    $message.From = $smtpFrom
    $message.To.Add($smtpTo)
    $message.Subject = $messageSubject
    $message.Body = $messageBody
    $message.IsBodyHtml = $true

    $smtp = New-Object Net.Mail.SmtpClient($smtpServer, $smtpPort)
    $smtp.EnableSsl = $true
    $smtp.Credentials = New-Object System.Net.NetworkCredential($smtpUsername, $smtpPassword)
    $smtp.Send($message)

    Write-Host "E-posta gönderildi: $messageSubject"
}

# Dosya karşılaştırma işlevi
function Compare-Files {
    param (
        [string]$oldFile,
        [string]$newFile
    )

    $oldContent = Get-Content $oldFile
    $newContent = Get-Content $newFile

    $differences = Compare-Object -ReferenceObject $oldContent -DifferenceObject $newContent -PassThru

    $changeDetails = ""
    foreach ($diff in $differences) {
        if ($diff.SideIndicator -eq '=>') {
            $changeDetails += "<span class='added'>Eklendi: $($diff)</span><br>"
        } elseif ($diff.SideIndicator -eq '<=') {
            $changeDetails += "<span class='deleted'>Silindi: $($diff)</span><br>"
        } else {
            $changeDetails += "<span class='changed'>Değiştirildi: $($diff)</span><br>"
        }
    }

    return $changeDetails
}

# Olay işleme işlevi tanımlama
$action = {
    $path = $Event.SourceEventArgs.FullPath
    $timestamp = Get-Date

    # Değişiklik olayları arasında en az 5 saniye bekleme
    $timeSinceLastChange = ($timestamp - $lastChangeTime).TotalSeconds
    if ($timeSinceLastChange -lt 5) {
        return
    }

    # Değişiklik detaylarını karşılaştır
    $changeDetails = Compare-Files -oldFile $backupDosya -newFile $path

    # Değişiklik varsa logla ve e-posta gönder
    if ($changeDetails) {
        $logline = "$timestamp, Değişiklikler: $changeDetails, $path"
        Add-Content "C:\denemelog\IzlemeLogu.txt" -Value $logline

        Write-Host "Dosya değişikliği algılandı: $logline"

        # E-posta gönderme
        Send-Email -changeDetails $changeDetails -path $path -timestamp $timestamp

        # Dosyanın yeni durumunu yedekle
        Copy-Item -Path $path -Destination $backupDosya -Force

        # Son değişiklik zamanını güncelle
        $lastChangeTime = $timestamp
    }
}

# Değişiklik olaylarını dinlemek için kayıt işlevlerini tanımlama
Register-ObjectEvent $watcher "Changed" -Action $action
Register-ObjectEvent $watcher "Created" -Action $action
Register-ObjectEvent $watcher "Deleted" -Action $action

Write-Host "Dosya değişikliklerini izlemek için PowerShell scripti başlatıldı..."

# FileSystemWatcher'ı etkinleştirme
$watcher.EnableRaisingEvents = $true

# Sonsuz döngüde scriptin çalışmasını sağlamak için bekletme
while ($true) {
    Start-Sleep -Seconds 5  # Scriptin sürekli çalışmasını sağlamak için uyku modunda bekletme
}
