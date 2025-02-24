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
  