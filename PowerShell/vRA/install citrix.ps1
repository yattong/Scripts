"DEBUG - Using variables $dml and $fileName and $dmlUser and $dmlFilePath `r`n"

# Validate installation files exist
try {
	
	"Clearing errors"
	$error.clear()
	
    if (!(Test-Path C:\Source\$filename)) {
        "Installation Files not in Source Folder, connecting to repo for files `r`n"

        "Disabling Registry Key to disallow cached credentials `r`n"
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "disabledomaincreds" -Value "0"
       
        "Accessing DML... `r`n"
        net use $dml /user:$dmlUser $dmlPassword

        "Checking Source Folder Exists... `r`n"
        if (Test-Path C:\Source -Filter "TRUE") {
            "C:\Source already exists, ready to start copying files `r`n"
        } else {
            "C:\Source does not exist, creating Directory... `r`n"
            mkdir C:\Source
        }

        "Copying Citrix VDA Binaries... `r`n"
        Copy-Item $dml\$dmlFilePath\$fileName C:\Source
        
        if(Test-Path C:\Source\$filename){
            "Copying Citrix VDA Binaries Successful`r`n"
        } else {
            "Copying Citrix VDA Binaries failed`r`n"
        }

        if ((Get-WmiObject Win32_ComputerSystem).Domain -eq "kpmgprod.com"){
            "Copying Citrix Prod Wallpaper... `r`n"
            Copy-Item $dml\$dmlFilePath\WallPaper\Prod\CorporateWallpaper.jpg C:\Windows
        } else {
            "Copying Citrix Test Wallpaper... `r`n"
            Copy-Item $dml\$dmlFilePath\WallPaper\Test\CorporateWallpaper.jpg C:\Windows
        }
        
        if(Test-Path C:\Windows\CorporateWallpaper.jpg){
            "Copying Citrix Wallpaper Successful`r`n"
        } else {
            "Copying Citrix Wallpaper failed`r`n"
        }

        
        "Enabling Registry Key to disallow cached credentials `r`n"
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "disabledomaincreds" -Value "1"

        net use $dml /d

    } else {
        "Installation Files in Source Folder, continue to installation `r`n"
    
    }
} catch {

}

# Installation 

"Installing Citrix VDA... `r`n"
try {
    Start-Process C:\Source\$fileName -ArgumentList "/COMPONENTS VDA /QUIET /ENABLE_FRAMEHAWK_PORT /ENABLE_REMOTE_ASSISTANCE /ENABLE_REAL_TIME_TRANSPORT /OPTIMIZE " -Wait
	
	"Citrix VDA Installation completed... `r`n"
} catch {
	"Error installing Citrix VDA - catch  `r`n"
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

# Needs Reboot

"Changing Registry Keys to fix Login Screen"
try {
	
	"Clearing errors"
	$error.clear()

	New-ItemProperty -Path "HKLM:\Software\Wow6432node\Citrix\CtxHook\AppInit_DLLS\Multiple Monitor Hook" -Name LogonUIWidth -PropertyType DWORD -Value 300 -Force
	New-ItemProperty -Path "HKLM:\Software\Wow6432node\Citrix\CtxHook\AppInit_DLLS\Multiple Monitor Hook" -Name LogonUIHeight -PropertyType DWORD -Value 200 -Force
	
	"Changing Registry Keys to fix Login Screen Completed"
	
} catch {
	
	"Changing Registry Keys to fix Login Screen Failed"
	$error

} finally {
	
	"Clearing errors"
	$error.clear()
}


# Needs Reboot