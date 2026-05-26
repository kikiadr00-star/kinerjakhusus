$port = 8082
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()

Write-Host "Server berjalan di http://localhost:$port/"
Write-Host "Silakan buka URL tersebut di browser Anda."
Write-Host "Tekan Ctrl+C untuk berhenti."
[System.Diagnostics.Process]::Start("http://localhost:$port/") | Out-Null

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $localPath = $request.Url.LocalPath.TrimStart('/')
        if ($localPath -eq "") {
            $localPath = "aplikasi_kinerja_madrasah.html"
        }
        
        $filePath = Join-Path (Get-Location).Path $localPath
        $filePath = [System.IO.Path]::GetFullPath($filePath)

        # Basic security check to prevent directory traversal
        if ($filePath.StartsWith((Get-Location).Path)) {
            if (Test-Path $filePath -PathType Leaf) {
                $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
                $contentType = "text/plain"
                switch ($ext) {
                    ".html" { $contentType = "text/html" }
                    ".css"  { $contentType = "text/css" }
                    ".js"   { $contentType = "application/javascript" }
                    ".json" { $contentType = "application/json" }
                    ".png"  { $contentType = "image/png" }
                    ".jpg"  { $contentType = "image/jpeg" }
                    ".svg"  { $contentType = "image/svg+xml" }
                }

                $response.ContentType = $contentType
                $content = [System.IO.File]::ReadAllBytes($filePath)
                $response.ContentLength64 = $content.Length
                $response.OutputStream.Write($content, 0, $content.Length)
                $response.StatusCode = 200
            } else {
                $response.StatusCode = 404
            }
        } else {
            $response.StatusCode = 403
        }

        $response.Close()
    }
}
finally {
    $listener.Stop()
}
