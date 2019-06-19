#################################################################################
#
# Author : Yattong Wu
# Date : 5 May 2018
# Version : 1.0
# Purpose : Cleanup after an "SRM Test" NSX load Balancer Failover
# Parameters : Recovery vCenter, AppID
# Assumption : 
#
##################################################################################

param(
    [Parameter(Mandatory=$true)][ValidateSet('prdvvcsha03.kpmgmgmt.com','prdvvcsha04.kpmgmgmt.com')][string]$recoveryVC,
    [Parameter(Mandatory=$true)][string]$appID
)

############ Set Up logging ################
$logdir = "C:\SRM-Logs\$($appID)"
"Checking Source Folder Exists... `r`n"
if (Test-Path $logdir -Filter "TRUE") {
    Write-Output "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : $($logdir) already exists."
} else {
    "$($logdir) does not exist, creating Directory..."
    mkdir $logdir
}
# Enumerate $logfile variable
$logfile = "$($logdir)\$($appID)_NSX_LB_TEST_CLEANUP.log"

############# Start Logging ################
"$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : --------------------- $($appID) DR TEST CLEANUP -------------------------" >> $logfile

########### Derived Variables  #############
# EdgeName will enable search for all LB's for application id
$edgeName = "VEDG$($appID)"

## Try Catch
try {

# Determine Recovery Site
if ($recoveryVC -eq "prdvvcsha04.kpmgmgmt.com"){
    $protectedVC = "prdvvcsha03.kpmgmgmt.com"
    $recoveryNSX = "prdvnsxsha02.kpmgmgmt.com"
    $protectedNSX = "prdvnsxsha01.kpmgmgmt.com"
} else {
    $protectedVC = "prdvvcsha04.kpmgmgmt.com"
    $recoveryNSX = "prdvnsxsha01.kpmgmgmt.com"
    $protectedNSX = "prdvnsxsha02.kpmgmgmt.com"
}

########## Load Modules  ###################
# Load VMware Module
if (!(Get-Module -Name VMware.VimAutomation.Core) -and (Get-Module -ListAvailable -Name VMware.VimAutomation.Core)) {  
    "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : loading the VMware PS Modules..." >> $logfile
    Import-Module -Name VMware*.VimAutomation.core
    Import-Module -Name VMware*.VimAutomation.Storage
    Import-Module -Name VMware*.VimAutomation.SDK
    Import-Module -Name VMware*.VimAutomation.Vds
    Import-Module -Name VMware*.VimAutomation.HA
    Import-Module -Name VMware*.VimAutomation.CIS.core
    }

########## Functions  ######################

# function to shutdown vm's
Function Shutdown ($VMName)
{
	"$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : Shutting Down : $($VMName)" >> $logfile
	$VM = Get-VM -Name $VMName
	if($VM.PowerState -eq "PoweredOn"){
		Shutdown-VMGuest -VM $VMName -confirm:$false | Out-Null
		do{
			Start-Sleep -Seconds 5;
			$VM = Get-VM $VMName
			"$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : $($VM.PowerState)" >> $logfile
		}while($VM.PowerState -eq "PoweredOn");
	}
	"$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : Done Shutting Down : $($VMName)" >> $logfile
}


# C# function to access windows cred manager
[String] $PsCredmanUtils = @"
using System;
using System.Runtime.InteropServices;

namespace PsUtils
{
    public class CredMan
    {
        #region Imports
        // DllImport derives from System.Runtime.InteropServices
        [DllImport("Advapi32.dll", SetLastError = true, EntryPoint = "CredDeleteW", CharSet = CharSet.Unicode)]
        private static extern bool CredDeleteW([In] string target, [In] CRED_TYPE type, [In] int reservedFlag);

        [DllImport("Advapi32.dll", SetLastError = true, EntryPoint = "CredEnumerateW", CharSet = CharSet.Unicode)]
        private static extern bool CredEnumerateW([In] string Filter, [In] int Flags, out int Count, out IntPtr CredentialPtr);

        [DllImport("Advapi32.dll", SetLastError = true, EntryPoint = "CredFree")]
        private static extern void CredFree([In] IntPtr cred);

        [DllImport("Advapi32.dll", SetLastError = true, EntryPoint = "CredReadW", CharSet = CharSet.Unicode)]
        private static extern bool CredReadW([In] string target, [In] CRED_TYPE type, [In] int reservedFlag, out IntPtr CredentialPtr);

        [DllImport("Advapi32.dll", SetLastError = true, EntryPoint = "CredWriteW", CharSet = CharSet.Unicode)]
        private static extern bool CredWriteW([In] ref Credential userCredential, [In] UInt32 flags);
        #endregion

        #region Fields
        public enum CRED_FLAGS : uint
        {
            NONE = 0x0,
            PROMPT_NOW = 0x2,
            USERNAME_TARGET = 0x4
        }

        public enum CRED_ERRORS : uint
        {
            ERROR_SUCCESS = 0x0,
            ERROR_INVALID_PARAMETER = 0x80070057,
            ERROR_INVALID_FLAGS = 0x800703EC,
            ERROR_NOT_FOUND = 0x80070490,
            ERROR_NO_SUCH_LOGON_SESSION = 0x80070520,
            ERROR_BAD_USERNAME = 0x8007089A
        }

        public enum CRED_PERSIST : uint
        {
            SESSION = 1,
            LOCAL_MACHINE = 2,
            ENTERPRISE = 3
        }

        public enum CRED_TYPE : uint
        {
            GENERIC = 1,
            DOMAIN_PASSWORD = 2,
            DOMAIN_CERTIFICATE = 3,
            DOMAIN_VISIBLE_PASSWORD = 4,
            GENERIC_CERTIFICATE = 5,
            DOMAIN_EXTENDED = 6,
            MAXIMUM = 7,      // Maximum supported cred type
            MAXIMUM_EX = (MAXIMUM + 1000),  // Allow new applications to run on old OSes
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct Credential
        {
            public CRED_FLAGS Flags;
            public CRED_TYPE Type;
            public string TargetName;
            public string Comment;
            public DateTime LastWritten;
            public UInt32 CredentialBlobSize;
            public string CredentialBlob;
            public CRED_PERSIST Persist;
            public UInt32 AttributeCount;
            public IntPtr Attributes;
            public string TargetAlias;
            public string UserName;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        private struct NativeCredential
        {
            public CRED_FLAGS Flags;
            public CRED_TYPE Type;
            public IntPtr TargetName;
            public IntPtr Comment;
            public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
            public UInt32 CredentialBlobSize;
            public IntPtr CredentialBlob;
            public UInt32 Persist;
            public UInt32 AttributeCount;
            public IntPtr Attributes;
            public IntPtr TargetAlias;
            public IntPtr UserName;
        }
        #endregion

        #region Child Class
        private class CriticalCredentialHandle : Microsoft.Win32.SafeHandles.CriticalHandleZeroOrMinusOneIsInvalid
        {
            public CriticalCredentialHandle(IntPtr preexistingHandle)
            {
                SetHandle(preexistingHandle);
            }

            private Credential XlateNativeCred(IntPtr pCred)
            {
                NativeCredential ncred = (NativeCredential)Marshal.PtrToStructure(pCred, typeof(NativeCredential));
                Credential cred = new Credential();
                cred.Type = ncred.Type;
                cred.Flags = ncred.Flags;
                cred.Persist = (CRED_PERSIST)ncred.Persist;

                long LastWritten = ncred.LastWritten.dwHighDateTime;
                LastWritten = (LastWritten << 32) + ncred.LastWritten.dwLowDateTime;
                cred.LastWritten = DateTime.FromFileTime(LastWritten);

                cred.UserName = Marshal.PtrToStringUni(ncred.UserName);
                cred.TargetName = Marshal.PtrToStringUni(ncred.TargetName);
                cred.TargetAlias = Marshal.PtrToStringUni(ncred.TargetAlias);
                cred.Comment = Marshal.PtrToStringUni(ncred.Comment);
                cred.CredentialBlobSize = ncred.CredentialBlobSize;
                if (0 < ncred.CredentialBlobSize)
                {
                    cred.CredentialBlob = Marshal.PtrToStringUni(ncred.CredentialBlob, (int)ncred.CredentialBlobSize / 2);
                }
                return cred;
            }

            public Credential GetCredential()
            {
                if (IsInvalid)
                {
                    throw new InvalidOperationException("Invalid CriticalHandle!");
                }
                Credential cred = XlateNativeCred(handle);
                return cred;
            }

            public Credential[] GetCredentials(int count)
            {
                if (IsInvalid)
                {
                    throw new InvalidOperationException("Invalid CriticalHandle!");
                }
                Credential[] Credentials = new Credential[count];
                IntPtr pTemp = IntPtr.Zero;
                for (int inx = 0; inx < count; inx++)
                {
                    pTemp = Marshal.ReadIntPtr(handle, inx * IntPtr.Size);
                    Credential cred = XlateNativeCred(pTemp);
                    Credentials[inx] = cred;
                }
                return Credentials;
            }

            override protected bool ReleaseHandle()
            {
                if (IsInvalid)
                {
                    return false;
                }
                CredFree(handle);
                SetHandleAsInvalid();
                return true;
            }
        }
        #endregion

        #region Custom API
        public static int CredDelete(string target, CRED_TYPE type)
        {
            if (!CredDeleteW(target, type, 0))
            {
                return Marshal.GetHRForLastWin32Error();
            }
            return 0;
        }

        public static int CredEnum(string Filter, out Credential[] Credentials)
        {
            int count = 0;
            int Flags = 0x0;
            if (string.IsNullOrEmpty(Filter) ||
                "*" == Filter)
            {
                Filter = null;
                if (6 <= Environment.OSVersion.Version.Major)
                {
                    Flags = 0x1; //CRED_ENUMERATE_ALL_CREDENTIALS; only valid is OS >= Vista
                }
            }
            IntPtr pCredentials = IntPtr.Zero;
            if (!CredEnumerateW(Filter, Flags, out count, out pCredentials))
            {
                Credentials = null;
                return Marshal.GetHRForLastWin32Error(); 
            }
            CriticalCredentialHandle CredHandle = new CriticalCredentialHandle(pCredentials);
            Credentials = CredHandle.GetCredentials(count);
            return 0;
        }

        public static int CredRead(string target, CRED_TYPE type, out Credential Credential)
        {
            IntPtr pCredential = IntPtr.Zero;
            Credential = new Credential();
            if (!CredReadW(target, type, 0, out pCredential))
            {
                return Marshal.GetHRForLastWin32Error();
            }
            CriticalCredentialHandle CredHandle = new CriticalCredentialHandle(pCredential);
            Credential = CredHandle.GetCredential();
            return 0;
        }

        public static int CredWrite(Credential userCredential)
        {
            if (!CredWriteW(ref userCredential, 0))
            {
                return Marshal.GetHRForLastWin32Error();
            }
            return 0;
        }

        #endregion

        private static int AddCred()
        {
            Credential Cred = new Credential();
            string Password = "Password";
            Cred.Flags = 0;
            Cred.Type = CRED_TYPE.GENERIC;
            Cred.TargetName = "Target";
            Cred.UserName = "UserName";
            Cred.AttributeCount = 0;
            Cred.Persist = CRED_PERSIST.ENTERPRISE;
            Cred.CredentialBlobSize = (uint)Password.Length;
            Cred.CredentialBlob = Password;
            Cred.Comment = "Comment";
            return CredWrite(Cred);
        }

        private static bool CheckError(string TestName, CRED_ERRORS Rtn)
        {
            switch(Rtn)
            {
                case CRED_ERRORS.ERROR_SUCCESS:
                    Console.WriteLine(string.Format("'{0}' worked", TestName));
                    return true;
                case CRED_ERRORS.ERROR_INVALID_FLAGS:
                case CRED_ERRORS.ERROR_INVALID_PARAMETER:
                case CRED_ERRORS.ERROR_NO_SUCH_LOGON_SESSION:
                case CRED_ERRORS.ERROR_NOT_FOUND:
                case CRED_ERRORS.ERROR_BAD_USERNAME:
                    Console.WriteLine(string.Format("'{0}' failed; {1}.", TestName, Rtn));
                    break;
                default:
                    Console.WriteLine(string.Format("'{0}' failed; 0x{1}.", TestName, Rtn.ToString("X")));
                    break;
            }
            return false;
        }

        /*
         * Note: the Main() function is primarily for debugging and testing in a Visual 
         * Studio session.  Although it will work from PowerShell, it's not very useful.
         */
        public static void Main()
        {
            Credential[] Creds = null;
            Credential Cred = new Credential();
            int Rtn = 0;

            Console.WriteLine("Testing CredWrite()");
            Rtn = AddCred();
            if (!CheckError("CredWrite", (CRED_ERRORS)Rtn))
            {
                return;
            }
            Console.WriteLine("Testing CredEnum()");
            Rtn = CredEnum(null, out Creds);
            if (!CheckError("CredEnum", (CRED_ERRORS)Rtn))
            {
                return;
            }
            Console.WriteLine("Testing CredRead()");
            Rtn = CredRead("Target", CRED_TYPE.GENERIC, out Cred);
            if (!CheckError("CredRead", (CRED_ERRORS)Rtn))
            {
                return;
            }
            Console.WriteLine("Testing CredDelete()");
            Rtn = CredDelete("Target", CRED_TYPE.GENERIC);
            if (!CheckError("CredDelete", (CRED_ERRORS)Rtn))
            {
                return;
            }
            Console.WriteLine("Testing CredRead() again");
            Rtn = CredRead("Target", CRED_TYPE.GENERIC, out Cred);
            if (!CheckError("CredRead", (CRED_ERRORS)Rtn))
            {
                Console.WriteLine("if the error is 'ERROR_NOT_FOUND', this result is OK.");
            }
        }
    }
}
"@

Add-Type $PsCredmanUtils


########## Go to Cred Manager to retrieve username & passwords ###################

$creds = [Array]::CreateInstance([PsUtils.CredMan+Credential], 0)
$results = [PsUtils.CredMan]::CredEnum($null, [Ref]$creds)


## Get password for svc_sha_srm
"$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : Getting Username and Password for vCenters" >> $logfile
foreach ($cred in $creds){
    if ($cred.UserName -eq "SVC_SHA_SRM"){
        $vcPassword = $cred.CredentialBlob
        $nsxPassword = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($cred.UserName + ":" + $vcPassword))
    }
}

## Get auth token for nsx api
<#
"Getting Username and Password for NSX API" >> $logfile
foreach ($cred in $creds){
    if ($cred.UserName -eq "nsx"){
        $nsxPassword = $cred.CredentialBlob
    }
}
#>


######################### SRM TEST Recovery Clean Up #############################

######################### if SRM Test DR is LPR -> IXE, Clean up is reverse ####################################

# Disconnect NIC from LBs
if ($recoveryVC -eq "prdvvcsha04.kpmgmgmt.com"){
    ## Connect to NSX
    "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : Pulling List of all Edge Devices..." >> $logfile
    $response = Invoke-WebRequest "https://$($recoveryNSX)/api/4.0/edges" -Headers @{"Authorization"="Basic $($nsxPassword)"}
    #$response.StatusCode
    #$response.Content
    if ($response.StatusCode -eq "200"){
        "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : List of Edge Devices received Successfully" >> $logfile
    } else {
        "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") ERROR : List of Edge Devices received Failed" >> $logfile
    }

    #Enumerate XML obj
    $xmlObj =  New-Object -TypeName System.Xml.XmlDocument
    $xmlObj.LoadXml($response.Content)

    $nsxEdgeIds = @();
    "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : Searching for All APPID Edge Device ID beginning with Edge Name $($edgeName)..." >> $logfile
    foreach ($edge in $xmlObj.pagedEdgeList.edgePage.edgeSummary){
        if ($edge.name.ToString() -like "$($edgeName)*"){
            $edge.name
            $nsxEdgeIds += $edge.objectId
        }
    }

    if ($nsxEdgeIds.Length -gt 0){
        "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : Edge Device IDs for Edge Name $($edgeName) Found" >> $logfile
    } else {
        "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") ERROR : Edge Device IDs for Edge Name $($edgeName) not Found" >> $logfile
    }

    foreach ($nsxEdgeId in $nsxEdgeIds){
        #$nsxEdgeId
        "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : Pulling Edge Device Config..." >> $logfile
        $response = Invoke-WebRequest "https://$($recoveryNSX)/api/4.0/edges/$($nsxEdgeId)" -Headers @{"Authorization"="Basic $($nsxPassword)"}
        #$response.StatusCode
        #$response.Content
        if ($response.StatusCode -match "200"){
            "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : Edge Device Details received Successfully" >> $logfile
        } else {
            "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") ERROR : Edge Device Details received Failed" >> $logfile
        }

        #Enumerate XML obj
        $xmlObj =  New-Object -TypeName System.Xml.XmlDocument
        $xmlObj.LoadXml($response.Content)

        # Change Nic Connection to true
        $xmlObj.edge.vnics.vnic[0].isConnected = "false"
            
        "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : Updating Edge Device with NIC Disconnected..." >> $logfile
        $updateResponse = Invoke-WebRequest "https://$($recoveryNSX)/api/4.0/edges/$($nsxEdgeId)" -Headers @{"Authorization"="Basic $($nsxPassword)"} -Method Put -Body $xmlObj -ContentType "application/xml"
        if ($updateResponse.StatusCode -eq "204"){
            "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : Edge Device NIC Connection Update Successful" >> $logfile
        } else {
            "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") ERROR : Edge Device NIC Connection Update Failed" >> $logfile
        }
    }

    # Power on LB VMs in LPR
    # Connect to vCenter
    "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : Connecting to vCenter : $($protectedVC)" >> $logfile
    $session = Connect-VIServer $protectedVC -User svc_sha_srm@kpmgmgmt.com -Password $vcPassword -ErrorAction Stop

    # logging
    if ($session){
        "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : Connected to vCenter : $($protectedVC)" >> $logfile

        #array of edges
        "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : Searcing for Edges in $($protectedVC)" >> $logfile
        $edges = Get-VM $edgeName* | sort
        "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : Found $($edges.Length) of Edge Devices" >> $logfile

        #Power ON edges
        foreach ($edge in $edges){
            Start-VM $edge
            "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : Powering on : $($edge.name)" >> $logfile
        }

        # Disconnect VC
        Disconnect-VIServer * -Force -Confirm:$false
        "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : Disconnected from vCenter : $($protectedVC)" >> $logfile
    }
}


################################ if SRM Test DR is IXE -> LPR, Clean up is reverse ####################################
# Shutdown LB's in LPR
if($recoveryVC -eq "prdvvcsha03.kpmgmgmt.com"){
    # Connect to vCenter
        
    "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : Connecting to vCenter : $($recoveryVC)" >> $logfile
    $session = Connect-VIServer $recoveryVC -User svc_sha_srm@kpmgmgmt.com -Password $vcPassword -ErrorAction Stop

    # logging
    if ($session){
        "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : Connected to vCenter : $($recoveryVC)" >> $logfile
        
        #array of edges
        "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : Searcing for Edges in $($recoveryVC)" >> $logfile
        $edges = Get-VM $edgeName* | sort
        "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : Found $($edges.Length) of Edge Devices" >> $logfile

        #Shutdown edges
        foreach ($edge in $edges){
            Shutdown $edge
        }

        # Disconnect VC
        Disconnect-VIServer * -Force -Confirm:$false
        "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : Disconnected from vCenter : $($recoveryVC)" >> $logfile
    }

# Connect the LB NIC in IXE

    ## Connect to NSX
    "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : Pulling List of all Edge Devices..." >> $logfile
    $response = Invoke-WebRequest "https://$($protectedNSX)/api/4.0/edges" -Headers @{"Authorization"="Basic $($nsxPassword)"}
    #$response.StatusCode
    #$response.Content
    if ($response.StatusCode -eq "200"){
        "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : List of Edge Devices received Successfully" >> $logfile
    } else {
        "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") ERROR : List of Edge Devices received Failed" >> $logfile
    }

    #Enumerate XML obj
    $xmlObj =  New-Object -TypeName System.Xml.XmlDocument
    $xmlObj.LoadXml($response.Content)

    $nsxEdgeIds = @();
    "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : Searching for All APPID Edge Device ID beginning with Edge Name $($edgeName)..." >> $logfile
    foreach ($edge in $xmlObj.pagedEdgeList.edgePage.edgeSummary){
        if ($edge.name.ToString() -like "$($edgeName)*"){
            "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : Edge Device IDs for Edge Name $($edge.name) Found" >> $logfile
            $nsxEdgeIds += $edge.objectId
        }
    }

    
    foreach ($nsxEdgeId in $nsxEdgeIds){
        #$nsxEdgeId
        "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : Pulling Edge Device Config..." >> $logfile
        $response = Invoke-WebRequest "https://$($protectedNSX)/api/4.0/edges/$($nsxEdgeId)" -Headers @{"Authorization"="Basic $($nsxPassword)"}
        #$response.StatusCode
        #$response.Content
        if ($response.StatusCode -eq "200"){
            "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : Edge Device Details received Successfully" >> $logfile
        } else {
            "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") ERROR : Edge Device Details received Failed" >> $logfile
        }

        #Enumerate XML obj
        $xmlObj =  New-Object -TypeName System.Xml.XmlDocument
        $xmlObj.LoadXml($response.Content)

        # Change Nic Connection to true
        $xmlObj.edge.vnics.vnic[0].isConnected = "true"

        "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : Updating Edge Device with NIC Connected..." >> $logfile
        $updateResponse = Invoke-WebRequest "https://$($protectedNSX)/api/4.0/edges/$($nsxEdgeId)" -Headers @{"Authorization"="Basic $($nsxPassword)"} -Method Put -Body $xmlObj -ContentType "application/xml"
        if ($updateResponse.StatusCode -eq "204"){
            "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : Edge Device NIC Connection Update Successful" >> $logfile
        } else {
            "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") ERROR : Edge Device NIC Connection Update Failed" >> $logfile
        }
    }
}

############# Success Logging ################
"$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") INFO : --------------------- $($env:VMware_RecoveryName.substring(0,6)) TEST DR CLEANUP SUCCESSFUL -------------------------" >> $logfile

} catch {

    ############# Success Logging ################
    "$(Get-Date -Format "[yyyy-MM-dd]HH:mm:ss -") ERROR : $($error)" >>  $logfile
}