####################
#
#  Script to find EDM Users that have attempted to log on since 3/11/17
#
# 

# File Output of Script
$outFile = "KPC EDM User Attempted logins Export $(Get-Date -Format "yyyy-MM-dd") v0.1.csv"

# Set Date Variable
$date = [datetime]"12/08/17"

# Get all EDM Users from OU
$users = @()
$users += (Get-ADUser -server PRDVDOMSHA01.kpmgprod.com -SearchBase "OU=External,OU=Users,OU=KPMGC2,DC=kpmgprod,DC=com" -SearchScope Subtree -Properties * -Filter {(LastLogonDate -ge $date) -or (PasswordLastSet -ge $date)} | sort)
$users += (Get-ADUser -server PRDVDOMSHA01.kpmgprod.com -SearchBase "OU=Internal,OU=Users,OU=KPMGC2,DC=kpmgprod,DC=com" -SearchScope Subtree -Properties * -Filter {(LastLogonDate -ge $date) -or (PasswordLastSet -ge $date)} | sort)

# Get Locked Users
$lockedOutUsers = @()
$lockedOutUsers += (Search-ADAccount -Server kpmgprod.com -SearchBase "OU=External,OU=Users,OU=KPMGC2,DC=kpmgprod,DC=com" -SearchScope Subtree -LockedOut -UsersOnly)
$lockedOutUsers += (Search-ADAccount -Server kpmgprod.com -SearchBase "OU=Internal,OU=Users,OU=KPMGC2,DC=kpmgprod,DC=com" -SearchScope Subtree -LockedOut -UsersOnly)
foreach ($lockedOutUser in $lockedOutUsers){
    $users += Get-ADUser -Server kpmgprod.com $lockedOutUser.SamAccountName -Properties *
}

# Format Report
$newData = @()
$newData += ("Users`tFirstName`tLastName`tDisplayName`tDescription`tEmail`tDepartment`tLastLogonDate`tPasswordLastSet`tLockedOut")

# Find Users
foreach ($user in $users){ 
    $newData += ("$($user.SamAccountName)`t$($user.GivenName)`t$($user.Surname)`t$($user.DisplayName)`t$($user.Description)`t$($user.emailAddress)`t$($user.Department)`t$($user.LastLogonDate)`t$($user.PasswordLastSet)`t$($user.LockedOut)")
}

# Export data to file
$newData > $outFile
