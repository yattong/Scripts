# Check if vm snapin is loaded
if (!(Get-Module -Name VMware.VimAutomation.Core) -and (Get-Module -ListAvailable -Name VMware.VimAutomation.Core)) {  
    Write-Output "loading the VMware Core Module..."
    Import-Module -Name VMware*.VimAutomation.core
    Import-Module -Name VMware*.VimAutomation.Storage
    Import-Module -Name VMware*.VimAutomation.SDK
    Import-Module -Name VMware*.VimAutomation.Vds
    Import-Module -Name VMware*.VimAutomation.HA
    Import-Module -Name VMware*.VimAutomation.CIS.core
    }

Get-Command *policy*

get-spbm

$tagCat = (Get-TagCategory -Name "Application ID")[1]

$appIDs = @("ALT01D - Alteryx Dev","BAK01P - Commvault Production","BPM01D - BPM - Development","BPM01P - BPM - Production","BPM01U - BPM - UAT","BRA01P - Brainspace - Production","BRA01U - Brainspace - UAT","BTM01D - Business Traveller - Development","BTM01P - Business Traveller - Production","BTM01T - Business Traveller - Test","BTM01U - Business Traveller - UAT","BTN01D - Business Traveller (Novartis) - Development","BTN01T - Business Traveller (Novartis) - Test","BTN01U - Business Traveller (Novartis) - UAT","CBA01P - CyberArk Production","CLR01P - Clearwell - Production","CLR01U - Clearwell - UAT","CRI01P - CRIS Audio","CRS01D - CRS - Development","CRS01P - CRS - Production Instance 1","CRS01U - CRS - UAT","CRS02P - CRS - Production Instance 2","DAT01P - KPMG – National Markets – Data & Analytics Team","DAT01T - Data Generation Tool","DAT01U - Data Generation Tool","DAT02T - Data Analytics Tools - Test(Demo)","DAT02U - Data Analytics Tools - UAT","DTS01P - DT Search - Production","DTS01U - DT Search - UAT","EDM01P - Citrix Jump Server","EFT01D - Globalscape Enhanced File Transfer - Development","EFT01P - Globalscape Enhanced File Transfer - Production","EFT01T - Globalscape Enhanced File Transfer - Test","EFT01U - Globalscape Enhanced File Transfer - UAT","EMX01P - EMX Hub flexible benefits application for production hosted in AWS","GET01P - Global Equity Tracker (GET) - Production","GET01U - Global Equity Tracker (GET) - UAT","GET02U - Global Equity Tracker (GET)  - Regression & Pen Testing","GPM01D - Global Payroll Manager (GPM) - Development","GPM01P - Global Payroll Manager (GPM) - Production","GPM01T - Global Payroll Manager (GPM) - Test","GPM01U - Global Payroll Manager (GPM) - UAT","GPM02U - Global Payrol Manager (GPM) UAT","HRI01P - UBS Mini HRI Shared Database ","HRI01U - UBS Mini HRI Shared Database ","IAM01P - IAM Tools (UBS Dynamo) - Production","IAM01U - IAM Tools (UBS Dynamo) - UAT","LNK01P - LINKE 5.7 - Production","LNK01U - LINKE 5.7 - UAT","LNK02D - LINKE 6.x - Development","LNK02P - LINKE 6.x - Production","LNK02U - LINKE 6.x - UAT","LNK03P - LINKE 5.7 (UBS) - Production","LNK03U - LINKE 5.7 (UBS) - UAT","LNK04P - LINKE 6.x (Zurich, Novartis, JTI, KTools) - Production","LNK04T - LINKE 6.x (Zurich, Novartis) - Test (demo site)","LNK04U - LINKE 6.x (Zurich, Novartis) - UAT","MAV01P - Maven's Kit - Production","MTJ01P - MultiJ - Production","MTJ01U - MultiJ - UAT","NEX01P - Nexidia (HSBC) - Production","NEX01U - Nexidia (HSBC) - UAT","NEX02P - Nexidia (Platform2) - Production","NEX02U - Nexidia (Platform2) - UAT","NEX03P - Nexidia (JPMC) - Production","NEX03U - Nexidia (JPMC) - UAT","NOW01D - ServiceNow Development","NOW01P - ServiceNow Production","NSX01P - NSX Virtual Networking for KPC","OUT01D - OutSystems - Development","OUT01U - Data Analytics Code Dev. Platform","OUT02P - OutSystems Deployment Servers","POR01D - Portal - Development","POR01P - Portal - Production","POR01U - Portal - UAT","PSM01P - CyberArk Privileged Session Manager","QLI01P - Qlikview production CoLo","REL01P - Relativity 9.2 - Production","REL01T - Relativity 9.2 - Test","REL01U - Relativity 9.2 - UAT","RTP01D - RTP - Development","RTP01P - RTP - Production","RTP01T - RTP - Test","RTP01U - RTP - UAT","SAS01P - SAS - Production","SAS01T - SAS - Test","SAS01U - SAS - UAT","SCM01P - SCCM 2012 - Production","SHA01P - Shared Citrix - Production","SHA01T - Shared Citrix - Test","SHA01U - Shared Citrix - UAT","SQL01P - Shared SQL Clusters - Production","SQL01T - SQL server builds in Test","SQL01U - Shared SQL - UAT","SRM01P - Site Recovery Manager Production","TAX01P - Citrix Jump Server - Production","TRS01P - TRS Shared Infrastructure (Production)","TRS01U - TRS Shared Infrastructure (UAT)","UDA01P - Citrix Jump Server - Production","VAR01P - Varonis - Production","VRA01P - vRealize Automation Self-Service IaaS Portal","VUM01P - VMware Update Manager Production","YAL01P - Yale - Production","YAL01T - Yale - Test","YAL01U - Yale - UAT")
foreach ($appID in $appIDs){
    if ($appID.split(" - ")[0].Substring(5,1) -eq "P"){
        Write-Host -ForegroundColor Cyan "Creating vSphere Tag : $($appID.Split(" - ")[0]) with Description $($appID.Split(" - ")[3])"
        New-Tag -Name $appID.split(" - ")[0] -Description $appID.split(" - ")[3] -Category $tagCat
        
    }
}

$appID = "BPM01P - BPM - Production"
$datastores = Get-Datastore -Name "*$($appID.split(" - ")[0])*"

# Tag Datastore

foreach ($appID in $appIDs){
    if ($appID.split(" - ")[0].Substring(5,1) -eq "P"){
        $tag = Get-Tag $appID.split(" - ")[0] -Server prdvvcsha03.kpmgmgmt.com
        $datastores = Get-Datastore -Name "*$($appID.split(" - ")[0])*" -Server prdvvcsha03.kpmgmgmt.com
        if ($datastores){
            foreach ($datastore in $datastores){
                $datastore | New-TagAssignment -Tag $tag

            }
        }
    }
}

Get-Command *tag*

foreach ($datastore in $datastores){
    $datastore | set

}

new-SpbmStoragePolicy -Name LPR-PRD-NEX02P -Server prdvvcsha03.kpmgmgmt.com -RuleSet (New-SpbmRuleSet -Name "Test" -AllOfRules @((New-SpbmRule -AnyOfTags "NEX02P" -Server prdvvcsha03.kpmgmgmt.com)))


get-help New-SpbmRuleSet -Full

# Create Storage Policy based on Tag (always errors)

foreach ($appID in $appIDs){
    # only work on Production AppIDs
    if ($appID.split(" - ")[0].Substring(5,1) -eq "P"){
        $tag = Get-Tag -Name $appID.split(" - ")[0] -Server prdvvcsha04.kpmgmgmt.com
        $spbmRule = New-SpbmRule -AnyOfTags $tag -Server prdvvcsha04.kpmgmgmt.com
        $spbmRuleSet = (New-SpbmRuleSet -AllOfRules $spbmRule)[0]
        New-SpbmStoragePolicy -Name "IXE-PRD-$($appID.split(" - ")[0])" -AnyOfRuleSets $spbmRuleSet[0] -Server prdvvcsha04.kpmgmgmt.com -Description $appID

    }
}


# Set VM to Storage Policy

foreach ($appID in $appIDs){
    # only work on Production AppIDs
    if ($appID.split(" - ")[0].Substring(5,1) -eq "P"){
        $vms = Get-VM "*$($appID.split(" - ")[0])*" -Server prdvvcsha03.kpmgmgmt.com
        foreach ($vm in $vms){
            # Ignore Edge Devices
            if ($vm.Name -notlike "*EDG*"){
                Write-Host -ForegroundColor Cyan "Setting SPBM : LPR-PRD-$($appID.split(" - ")[0]) on $($vm.Name)"
                $vm | Set-SpbmEntityConfiguration -StoragePolicy "LPR-PRD-$($appID.split(" - ")[0])" -Server prdvvcsha03.kpmgmgmt.com
            }
        }
    }
}


# Connect to SRM
$srmConnection = Connect-SrmServer
$srmApi = $srmConnection.ExtensionData

# Create SRM Protection Group

get-srm