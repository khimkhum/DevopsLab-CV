$ErrorActionPreference = 'Stop'
$labExitCode = 1
$labLogDir = 'F:\Devops_Lab\.artifacts'

New-Item -ItemType Directory -Path $labLogDir -Force | Out-Null
Start-Transcript -Path "$labLogDir\windows-startup.log" -Append | Out-Null

try {
    Write-Output "Launcher started: $(Get-Date -Format o)"
    $labDockerExe = Join-Path $env:LOCALAPPDATA `
        'Programs\DockerDesktop\Docker Desktop.exe'

    if (-not (Test-Path -LiteralPath $labDockerExe)) {
        throw "Docker Desktop executable not found: $labDockerExe"
    }

    if (-not (Get-Process -Name 'Docker Desktop' -ErrorAction SilentlyContinue)) {
        Write-Output "Starting Docker Desktop..."
        Start-Process -FilePath $labDockerExe -WindowStyle Hidden
    }
    else {
        Write-Output "Docker Desktop process already exists."
    }
    Write-Output "Starting Ubuntu and Bash..."

    & "$env:SystemRoot\System32\wsl.exe" `
        -d Ubuntu `
        -u khimkum `
        --cd /mnt/f/Devops_Lab `
        --exec /bin/bash /mnt/f/Devops_Lab/scripts/start-on-login.sh

    $labExitCode = $LASTEXITCODE
    Write-Output "WSL exited with code: $labExitCode"
}
catch {
    Write-Output "Launcher error: $($_.Exception.Message)"
}
finally {
    Stop-Transcript | Out-Null
}

exit $labExitCode
