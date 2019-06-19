$ErrorActionPreference = 'stop'
$DebugOn = $False

try { 
    $AllDisks = get-disk | where {$_.Path -Like "\\?\scsi*"}
    "Disk layout before changes:"
    $AllDisks

    foreach ($Disk in $AllDisks) {
        #Reset values for each variable
        # Default Allocation Unit Size = 4K
        $AllocationUnitSize = 4096
        $Partition = $Disk | Get-Partition
        $Partition
        "Getting GUID of Partition"
        if ($Partition.Guid -eq $null) {
            $PartGUID = [regex]::match($Partition.AccessPaths, 'Volume({[^}]+})').Groups[1].Value
        }
        else {
            $PartGUID = $Partition.Guid
        }
        "Partition GUID is $PartGUID"

        $DriveLetter = $Partition.DriveLetter
        $PartitionInfo = get-wmiObject Win32_Volume |where {$_.DeviceId -eq "\\?\Volume$PartGUID\"}
        $PartitionInfo
        $DriveLabel = $PartitionInfo.Label
        # Handle a blank drive label
        If ($DriveLabel.length -ne 0) {
            "Drive Label exists. Checking if name contains sql"
            If ($DriveLabel.indexOf("sql") -gt -1) {
                "This is a SQL volume so setting the UnitAllocationSize to 64k"
                $AllocationUnitSize = 65536
            }
        } # end if drive label exists

        If ($Disk.Number -ne "0") {
        $DiskNumber = $Disk.Number
            "Preparing a new partition for Disk Number: $DiskNumber  Drive Letter: $Driveletter label: $DriveLabel and AllocationUnitSize: $AllocationUnitSize"
            "Clear Disk"
            $Disk |Clear-Disk -RemoveData -Confirm:$false
            "Initialize disk"
            Initialize-Disk $Disk.Number -PartitionStyle GPT
            "Create new partition"
            $Disk | New-Partition -UseMaximumSize
            "Get partition info"
            $NewPartition = $Disk | Get-Partition | where {$_.PartitionNumber -eq "2"} 
            "Formatting volume"
            $NewPartition | format-volume  -FileSystem NTFS -AllocationUnitSize $AllocationUnitSize -NewFileSystemLabel $DriveLabel -Confirm:$false
            If ($DriveLetter -match "[A-Za-z]") {
                "Assigning Drive Letter $DriveLetter"
                $NewPartition | Set-Partition -NewDriveLetter $DriveLetter
            }  
            "Clearing values in preparation for next disk"
            Remove-Variable DriveLetter
            Remove-Variable DriveLabel

        } #End if disk number not 0
        Else {"Skipping Drive 0 which is the OS Drive"}
    }
} #end try

catch {
    "###Catch###"
    "Error generated re-partitioning drives"
    $errorcount = $error.count
    "Error Count: $errorcount"
    "Contents of error: $error"
    $error[0].exception | fl * -for
    if ($DebugOn) {
        Start-Sleep -s 6000
    }
    exit 666
}
finally {
    "###Finally Section###"
    "Disk layout after changes:"
    $AllDisks = get-disk | where {$_.Path -Like "\\?\scsi*"}
    $AllDisks
    "Re-partitioning of drives complete"
} #end finally
