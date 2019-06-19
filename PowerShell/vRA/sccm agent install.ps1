######################################################################################
#
# Author : Yattong Wu
# Date : 21 June 2018
# Version : 1.0
# Purpose : Install SCCM Agent
# Parameters : Username, Password
#
######################################################################################


"DEBUG - Using variables $dml and $fileName and $dmlUser and $dmlFilePath"

try {

# Validate installation files exist

    $error.clear()

    if (!(Test-Path C:\Source\$filename)) {
    Write-Output "Disabling Registry Key to disallow cached credentials `r`n"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "disabledomaincreds" -Value "0"

    Write-Output "Accessing DML... `r`n"
    net use $dml /user:$dmlUser $dmlPassword

    Write-Output "Checking Source Folder Exists... `r`n"
    if (Test-Path C:\Source -Filter "TRUE") {
        Write-Output "C:\Source already exists, ready to start copying files `r`n"
        } else {
        Write-Output "C:\Source does not exist, creating Directory... `r`n"
        mkdir C:\Source
        }

    Write-Output "Checking SCCM Folder Exists... `r`n"
    if (Test-Path C:\Source\SCCM -Filter "TRUE") {
        Write-Output "C:\Source\SCCM already exists, deleting contents..."
        Remove-Item "c:\Source\SCCM\*" -Recurse
        "Ready to start copying files... `r`n"
    } else {
        Write-Output "C:\Source\SCCM does not exist, creating Directory... `r`n"
        mkdir C:\Source\SCCM | Out-Null
    }

    Write-Output "Copying SCCM Agent Binaries... `r`n"
    "DEBUG - perform directory listing of $dml\$dmlFilePath `r`n"
    dir $dml\$dmlFilePath
    Copy-Item $dml\$dmlFilePath\* C:\Source\SCCM\ -Recurse

    Get-ChildItem C:\Source\SCCM | Unblock-File

    Write-Output "Enabling Registry Key to disallow cached credentials `r`n"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "disabledomaincreds" -Value "1"

    net use $dml /d

    } else {
        Write-Output "Installation Files in Source Folder, continue to installation `r`n"

    } 

######### Agent Installation

    $ConnectionAttemptCounter = 0
    $ConnectiontoSCCMSuccess = $false
    While (!$ConnectiontoSCCMSuccess -and $ConnectionAttemptCounter -lt 5) {
        $ConnectionResult = Test-NetConnection manvsccmsha02.kpmgmgmt.com -port 80 -WarningAction SilentlyContinue
        $ConnectionResult
        If ($ConnectionResult.TcpTestSucceeded) {
            "Connection to SCCM MP Successful `r`n"
            $ConnectiontoSCCMSuccess = $true

            $SCCMInstallSuccess = $false
            $SCCMInstallCounter = 0
            while (!$SCCMInstallSuccess -and $SCCMInstallCounter -lt 5) {
                $SCCMInstallCounter++
                "Installing SCCM Agent... `r`n"
                Start-Process "C:\Source\$fileName" -WorkingDirectory c:\ -verb RunAs -Wait -ArgumentList "/mp:manvsccmsha02.kpmgmgmt.com SMSSITECODE=P01 FSP=manvsccmsha02.kpmgmgmt.com /qn"
                "Monitoring the install and waiting until its finished before continuing with final checks `r`n" 
                do {
                $ccmsetup = Get-WmiObject -Class Win32_Service -Filter "Name='CcmSetup'"
                    if ($ccmsetup.State -eq "Running"){
                    sleep 10
                    } #end if
                } while ($ccmsetup -ne $null)
                "Install has completed, checking... `r`n"

                $installResult = Get-WmiObject -Class Win32_Service -Filter "Name='CcmExec'"
                if ($installResult.Status -eq "OK") {
                    Write-Output "SCCM Agent installed Successfully `r`n"
                    $SCCMInstallSuccess = $true
                    exit 0
                } else { #end if
                    Write-Output "SCCM Agent Installation Failed, sleeping 1 min then retrying `r`n"
                    $SCCMInstallSuccess = $false
                    Start-Sleep -s 60
                } #end else
            } #end while
            if ($SCCMInstallCounter -eq 4) {
                "SCCM Install has been attempted $SCCMInstallCounter times. Failing the install `r`n"
                exit 1
            } # end if
        } elseif ($ConnectionAttemptCounter -eq 4) {  #end if
            "SCCM Install has been attempted $ConnectionAttemptCounter times. Failed to connect to SCCM Server on Port 80 `r`n"
            exit 1
        } Else {
            "Connection to SCCM MP Failed, retrying in a few seconds... `r`n"
            Start-Sleep -s 1
            $ConnectionAttemptCounter++
        } #end else
    } #End While

    "Reviewing and clearing errors (Count:$($error.count))  `r`n"
    "Contents of error: $error  `r`n"
    $error[0].exception | fl * -for
    $error.clear

} catch { #end try
    "Error installing SCCM - catch  `r`n"
    $errorcount = $error.count
    "Error Count: $errorcount"
    "Contents of error: $error"
    $error[0].exception | fl * -for

} Finally {
    "Entering Finally secion for cleanup `r`n"
    $error
    "Clearing errors"
    $error.clear()
}
