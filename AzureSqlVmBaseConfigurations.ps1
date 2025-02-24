  # Install Chocolatey if not present
  if (!(Get-Command choco.exe -ErrorAction SilentlyContinue)) {
    Write-Output "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Output "Chocolatey installation complete."
} else {
    Write-Output "Chocolatey is already installed."
}
  
# Install .NET Framework 4.8 via Chocolatey if not already installed
$dotNet48Key = "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"
$dotNet48Value = (Get-ItemProperty -Path $dotNet48Key -Name Release -ErrorAction SilentlyContinue).Release
  
if ($dotNet48Value -lt 528040) {
    Write-Output ".NET Framework 4.8 not detected. Installing via Chocolatey..."
    choco install dotnetfx --version=4.8.0.20190930 -y
    Write-Output ".NET Framework 4.8 installation initiated. A reboot will be required."
    
    # Force reboot to complete installation
    Write-Output "Restarting the system to complete .NET installation..."
    Restart-Computer -Force
    exit  # Exit script to let the system reboot and resume manually
} else {
    Write-Output ".NET Framework 4.8 is already installed."
}
  
# Install SQL Server Management Studio (SSMS)
if (!(Get-Command "C:\Program Files (x86)\Microsoft SQL Server Management Studio 20\Common7\IDE\Ssms.exe" -ErrorAction SilentlyContinue)) {
    Write-Output "Installing SSMS via Chocolatey..."
    choco install sql-server-management-studio --yes
    Write-Output "SSMS installation complete."
} else {
    Write-Output "SSMS is already installed."
}

# Install Microsoft Edge if not present
if (!(Get-Command "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" -ErrorAction SilentlyContinue)) {
    Write-Output "Installing Microsoft Edge via Chocolatey..."
    choco install microsoft-edge --yes
    Write-Output "Microsoft Edge installation complete."
} else {
    Write-Output "Microsoft Edge is already installed."
}
  
# Download and restore AdventureWorksLT2019 database
$backupUrl = "https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorksLT2019.bak"
$backupDestination = "C:\AdventureWorksLT2019.bak"
  
if (!(Test-Path $backupDestination)) {
    Write-Output "Downloading AdventureWorksLT2019 backup..."
    Invoke-WebRequest -Uri $backupUrl -OutFile $backupDestination
    Write-Output "Backup downloaded."
} else {
    Write-Output "Backup already exists."
}
 
# Add SSMS shortcut to the desktop
$ssmsPath = "C:\Program Files (x86)\Microsoft SQL Server Management Studio 20\Common7\IDE\Ssms.exe"
$desktopPath = [System.Environment]::GetFolderPath("CommonDesktopDirectory")
$ssmsShortcutPath = Join-Path $desktopPath "SQL Server Management Studio.lnk"
  
if (Test-Path $ssmsPath) {
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($ssmsShortcutPath)
    $shortcut.TargetPath = $ssmsPath
    $shortcut.WorkingDirectory = "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE"
    $shortcut.IconLocation = $ssmsPath
    $shortcut.Save()
    Write-Output "SSMS shortcut added to the desktop."
} else {
    Write-Output "SSMS not found; shortcut not created."
}
  
# Delete the "SQL Server - Getting started.url" from the desktop
$gettingStartedShortcut = "C:\Users\Public\Desktop\SQL Server - Getting started.url"
  
if (Test-Path $gettingStartedShortcut) {
    Remove-Item $gettingStartedShortcut -Force
    Write-Output "'SQL Server - Getting started.url' deleted from the desktop."
} else {
    Write-Output "'SQL Server - Getting started.url' was not found on the desktop."
}
  
# Disable Server Manager from launching at logon for all users
$registryPath = "HKLM:\SOFTWARE\Microsoft\ServerManager"
$registryName = "DoNotOpenServerManagerAtLogon"
  
# Set registry key to disable Server Manager
if (-not (Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force
}
  
Set-ItemProperty -Path $registryPath -Name $registryName -Value 1 -Type DWord
Write-Output "Server Manager will no longer launch at logon."
  
# Install SetDefaultBrowser via Chocolatey after reboot
if (!(Get-Command "SetDefaultBrowser.exe" -ErrorAction SilentlyContinue)) {
    Write-Output "Installing SetDefaultBrowser via Chocolatey..."
    choco install setdefaultbrowser -y
    Write-Output "SetDefaultBrowser installation complete."
} else {
    Write-Output "SetDefaultBrowser is already installed."
}
  
# Set Microsoft Edge as the default browser
Write-Output "Setting Microsoft Edge as the default browser..."
SetDefaultBrowser edge
Write-Output "Microsoft Edge successfully set as the default browser."
  
# Wait for successful SQL connection before trying to restore the database
function Wait-ForSql {
    param(
        [string]$Instance = "localhost",
        [int]$MaxRetries = 5,
        [int]$Delay = 10
    )
    $connected = $false
    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            Invoke-Sqlcmd -ServerInstance $Instance -Database "master" -Query "SELECT 1" -ErrorAction Stop
            $connected = $true
            Write-Host "Successfully connected to SQL instance $Instance."
            break
        } catch {
            Write-Host "SQL not ready yet. Retry #$i..."
            Start-Sleep -Seconds $Delay
        }
    }
    if (-not $connected) {
        throw "Could not connect to SQL instance $Instance after $MaxRetries attempts."
    }
}
  
Wait-ForSql
  
# Restore the AdventureWorks database as "Adatum"
Write-Output "Restoring AdventureWorksLT2019 database..."
Invoke-Sqlcmd -ServerInstance "localhost" -Database "master" -Query "
RESTORE DATABASE Adatum 
FROM DISK = 'C:\AdventureWorksLT2019.bak'
WITH MOVE 'AdventureWorksLT2019_Data' TO 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\Adatum.mdf',
MOVE 'AdventureWorksLT2019_Log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\Adatum_log.ldf',
REPLACE
"
Write-Output "Database restoration complete." 

