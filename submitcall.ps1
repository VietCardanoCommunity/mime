# Path file CSV
$csvPath = "D:\midnight\chuasubmit.csv"

# Đọc CSV
$rows = Import-Csv -Path $csvPath

foreach ($row in $rows) {

    # Nếu đã OK thì bỏ qua
    if ($row.status -eq "OK") {
        Write-Host "⏭️ Skip OK: $($row.address)"
        continue
    }

    $address   = $row.address
    $challenge = $row.challengeid
    $nonce     = $row.nounce
    $url = "https://scavenger.prod.gd.midnighttge.io/solution/$address/$challenge/$nonce"

    Write-Host "🚀 Calling API: $url"

    try {
        $response = Invoke-WebRequest -Uri $url -Method POST -Body '{}' -ContentType 'application/json' -ErrorAction Stop

        Write-Host "📩 Response Code: $($response.StatusCode)"
        Write-Host "📨 Body: $($response.Content)"

        if ($response.StatusCode -eq 201 -or $response.StatusCode -eq 200) {
            $row.status = "OK"
            Write-Host "✅ Thành công: $address"
        } else {
            $row.status = "FAILED"
            Write-Host "❌ Failed: $($response.StatusCode)"
        }
    }
    catch {
        $row.status = "ERROR"
        Write-Host "🚫 Exception: $($_.Exception.Message)"
    }

    # Random delay 10–20 giây
    $delay = Get-Random -Minimum 10 -Maximum 20
    Write-Host "⏳ Chờ $delay giây..."
    Start-Sleep -Seconds $delay
}

# Ghi lại CSV
$rows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

Write-Host "🎯 DONE ✅"
