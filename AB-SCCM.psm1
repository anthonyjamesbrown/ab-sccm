function Get-DatabaseData 
{
    <#
        .SYNOPSIS
            Returns data from a database.
        .DESCRIPTION
            This function makes a native SQL client call to a database source.
        .PARAMETER connectionString
            This parameter is a standard datasource connection string.
        .PARAMETER query
            This parameter is the query that will be executed againt the datasource.
    #>
    [CmdletBinding()]
    param (
        [string]$connectionString,
        [string]$query
    ) # end param

    $connection = New-Object -TypeName System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString

    $command = $connection.CreateCommand()
    $command.CommandText = $query

    $adapter = New-Object -TypeName System.Data.SqlClient.SqlDataAdapter $command
    $dataset = New-Object -TypeName System.Data.DataSet
    $adapter.Fill($dataset) | Out-Null

    $dataset.Tables[0]
} # end function Get-DatabaseData

function Invoke-DatabaseQuery 
{
    <#
        .SYNOPSIS
            Executes a SQL command against a database.
        .DESCRIPTION
            This function executes a SQL command using a native SQL client call to a database source.
        .PARAMETER connectionString
            This parameter is a standard datasource connection string.
        .PARAMETER query
            This parameter is the query that will be executed againt the datasource.
    #>
    [CmdletBinding()]
    param (
        [string]$connectionString,
        [string]$query
    ) # end param

    Write-Verbose $query
    $connection = New-Object -TypeName System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString

    $command = $connection.CreateCommand()
    $command.CommandText = $query

    $connection.Open()
    $command.ExecuteNonQuery()

    $connection.close()
} # end function Invoke-DatabaseQuery

function Get-HotFixInstallStatus
{
    <#
        .SYNOPSIS
            Checks if a given Hotfix has been applied to a given server.
        .DESCRIPTION
            This function makes a WMI call to the remote server name that was passed as a
            function parameter.  It calls the Win32_QuickFixEngineering WMI class and queries
            the HotFixID property for the Hotfix ID that was passed as a parameter.  The function
            will return True is the hotfix was found and False if it was not found.
        .PARAMETER ServerName
            This parameter is required to use this function, it is simply the name of the 
            remote server to query against.
        .PARAMETER Hotfix
            This parameter is required to use this function, it is the name of the Hotfix to check for. 
    #>
    param
    (
        [parameter(Mandatory=$true)][string]$ServerName,
        [parameter(Mandatory=$true)][string]$Hotfix
    ) # end param

    try
    {
        $WMIObject = Get-WmiObject -Class Win32_QuickFixEngineering -ComputerName $ServerName -Filter "HotFixID ='$Hotfix'" -ErrorAction Stop
        $Installed = "False"
        foreach($col in $WMIObject)
        {
            if ($col.HotFixID -eq $Hotfix) {$Installed = "True"}         
        }
        return $Installed
    }
    catch
    {
        return "Error: $($_.Exception.Message)"
    }
} # end function Get-HotFixInstallStatus

function Get-HotFixInstallStatusByCollection
{
    param
    (
        [parameter(Mandatory=$true)][string]$CollectionName,
        [parameter(Mandatory=$true)][string]$Hotfix
    ) # end param

    get-CMServerListByCollection "$CollectionName" | % { [pscustomobject]@{ServerName = $_.Name ; HotfixStatus = "$(Get-HotFixInstallStatus -ServerName $_.Name -Hotfix $Hotfix)";} }
} # end function Get-HotFixInstallStatusByCollection

function Reset-CMClientPolicy
{
    <#
        .SYNOPSIS
            Reset the Client's Local Policy
        .DESCRIPTION
            This function makes a WMI call to the remote server name that was passed as a
            function parameter.  This will reset the client policy and force it to redownload from the MP.
        .PARAMETER ServerName
            This parameter is required to use this function, it is simply the name of the 
            remote server to query against.
    #>
    [CmdletBinding()]
    param
    (
        [string]$ComputerName
    ) # end param

    process
    {
        $Computer = $ComputerName
        $WMIPath = "\\" + $Computer + "\root\ccm:SMS_Client"
        $smsClient = [wmiclass] $WMIPath
        $result = $smsClient.ResetPolicy(1)
        $result = $smsClient.RequestMachinePolicy()
        $result = $smsClient.EvaluateMachinePolicy()

        if($Error[0])
        {
            $Output = [pscustomobject]@{'ComputerName' = "$Computer"; 'Status' = 'Error'; 'Error' = "$Error";}
        }
        else
        {
            $Output = [pscustomobject]@{'ComputerName' = "$Computer"; 'Status' = 'Success'; 'Error' = "";}
        } # end if

        Write-Output $Output
    } # end process
} # end function Reset-CMClientPolicy

function Get-CMClientPolicy
{
    <#
        .SYNOPSIS
            Returns a list of CM Policies on the specified server.
        .DESCRIPTION
            This function makes a WMI call to the remote server name that was passed as a
            function parameter.  It calls WMI and returns a list of assigned application policies.
        .PARAMETER ServerName
            This parameter is required to use this function, it is simply the name of the 
            remote server to query against.
    #>
    [CmdletBinding()]
    param
    (
        [String]$ComputerName
    ) # end param

    $namespace = "ROOT\ccm\Policy\Machine\ActualConfig" 
    $classname = "CCM_ApplicationCIAssignment" 

    return (Get-WmiObject -Class $classname -ComputerName $ComputerName -Namespace $namespace) 
} # end function Get-CMClientPolicy

function Get-CMClientPolicyExists
{
    <#
        .SYNOPSIS
            Returns a list of CM Policies on the specified server.
        .DESCRIPTION
            This function makes a WMI call to the remote server name that was passed as a
            function parameter.  It calls WMI and returns a list of assigned application policies.
        .PARAMETER ServerName
            This parameter is required to use this function, it is simply the name of the 
            remote server to query against.
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)][string[]]$ComputerName,
        [String]$NameSearch
    ) # end param

    begin
    {
        $namespace = "ROOT\ccm\Policy\Machine\ActualConfig" 
        $classname = "CCM_ApplicationCIAssignment" 
    } # end begin

    process 
    {
        try
        {
            $Policy = (Get-WmiObject -Class $classname -ComputerName $ComputerName -Namespace $namespace | ? AssignmentName -like "*$NameSearch*" -ErrorAction Stop)

            if($Policy.Count -eq 0) 
            {
                $Output = [pscustomobject]@{'ComputerName' = "$ComputerName"; "Search" = "$NameSearch"; "Result" = 'Not Found'}
            }
            else
            {
                $Output = [pscustomobject]@{'ComputerName' = "$ComputerName"; "Search" = "$NameSearch"; "Result" = 'Found'}
            } # end if
        }
        catch
        {
            $Output = [pscustomobject]@{'ComputerName' = "$ComputerName"; "Search" = "$NameSearch"; "Result" = "$($_.Exception.Message)"}
        } # end try

        Write-Output $Output
    } # end process
} # end function Get-CMClientPolicyExists

function Invoke-CMHardwareInventoryCycle
{
    <#
        .SYNOPSIS
            Invokes a CM client Hardware Inventory Cycle action on a remote client
        .DESCRIPTION
            This function makes a WMI call to the remote server name that was passed as a
            function parameter.  It calls WMI and invokes a client action.
        .PARAMETER ServerName
            This parameter is required to use this function, it is simply the name of the 
            remote server to query against.
        .PARAMETER Full
            This parameter specifies if the cycle should be normal or full.  
            The default is normal.
    #>
    [CmdletBinding()]
    param
    (
        [String]$ComputerName,
        [bool]$Full = $false
    ) # end param

    $strAction = "{00000000-0000-0000-0000-000000000001}"

    if (Test-Connection -computername $ComputerName -count 1 -quiet)
    {
        if ($Full -eq $true)
        {
			$ActionObject = Get-WmiObject -Query "Select * from InventoryActionStatus where InventoryActionID = '$strAction'" -Namespace root\ccm\invagt -ComputerName $ComputerName
			$ActionObject | Remove-WmiObject
        } # end if

		$Error.Clear()
		$WMIPath = "\\" + $ComputerName + "\root\ccm:SMS_Client"
		$SMSwmi = [wmiclass] $WMIPath
        [Void]$SMSwmi.TriggerSchedule($strAction)
        
		if($Error[0])
        {
            $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Error'; 'Error' = "$Error";}
        }
        else
        {
            $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Successful'; 'Error' = "";}
        } # end if
    }
    else
    {
        $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Off'; 'Error' = "";}
    } # end if

	Write-Output $strOutput
} # end function Invoke-CMHardwareInventoryCycle

function Invoke-CMDiscoveryDataCollectionCycle
{
    <#
        .SYNOPSIS
            Invokes a CM client Discovery Data Collection Cycle action on a remote client
        .DESCRIPTION
            This function makes a WMI call to the remote server name that was passed as a
            function parameter.  It calls WMI and invokes a client action.
        .PARAMETER ServerName
            This parameter is required to use this function, it is simply the name of the 
            remote server to query against.
        .PARAMETER Full
            This parameter specifies if the cycle should be normal or full.  
            The default is normal.
    #>
    [CmdletBinding()]
    param
    (
        [String]$ComputerName,
        [bool]$Full = $false
    ) # end param

    $strAction = "{00000000-0000-0000-0000-000000000003}"

    if (Test-Connection -computername $ComputerName -count 1 -quiet)
    {
        if ($Full -eq $true)
        {
			$ActionObject = Get-WmiObject -Query "Select * from InventoryActionStatus where InventoryActionID = '$strAction'" -Namespace root\ccm\invagt -ComputerName $ComputerName
			$ActionObject | Remove-WmiObject
        } # end if

		$Error.Clear()
		$WMIPath = "\\" + $ComputerName + "\root\ccm:SMS_Client"
		$SMSwmi = [wmiclass] $WMIPath
        [Void]$SMSwmi.TriggerSchedule($strAction)
        
		if($Error[0])
        {
            $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Error'; 'Error' = "$Error";}
        }
        else
        {
            $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Successful'; 'Error' = "";}
        } # end if
	} else {
        $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Off'; 'Error' = "";}
    } # end if

	Write-Output $strOutput
} # end function Invoke-CMDiscoveryDataCollectionCycle

function Invoke-CMSoftwareInventoryCycle
{
    <#
        .SYNOPSIS
            Invokes a CM client Software Inventory Cycle action on a remote client
        .DESCRIPTION
            This function makes a WMI call to the remote server name that was passed as a
            function parameter.  It calls WMI and invokes a client action.
        .PARAMETER ServerName
            This parameter is required to use this function, it is simply the name of the 
            remote server to query against.
        .PARAMETER Full
            This parameter specifies if the cycle should be normal or full.  
            The default is normal.
    #>
    [CmdletBinding()]
    param
    (
        [String]$ComputerName,
        [bool]$Full = $false
    ) # end if

    $strAction = "{00000000-0000-0000-0000-000000000002}"

    if(Test-Connection -computername $ComputerName -count 1 -quiet)
    {
        if ($Full -eq $true)
        {
			$ActionObject = Get-WmiObject -Query "Select * from InventoryActionStatus where InventoryActionID = '$strAction'" -Namespace root\ccm\invagt -ComputerName $ComputerName
			$ActionObject | Remove-WmiObject
        } # end if

		$Error.Clear()
		$WMIPath = "\\" + $ComputerName + "\root\ccm:SMS_Client"
		$SMSwmi = [wmiclass] $WMIPath
        [Void]$SMSwmi.TriggerSchedule($strAction)
        
		if($Error[0])
        {
            $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Error'; 'Error' = "$Error";}
        }
        else
        {
            $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Successful'; 'Error' = "";}
        } # end if
    }
    else
    {
        $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Off'; 'Error' = "";}
    } # end if

	Write-Output $strOutput
} # end function Invoke-CMSoftwareInventoryCycle

function Invoke-CMFileCollectionCycle
{
    <#
        .SYNOPSIS
            Invokes a CM client File Collection Cycle action on a remote client
        .DESCRIPTION
            This function makes a WMI call to the remote server name that was passed as a
            function parameter.  It calls WMI and invokes a client action.
        .PARAMETER ServerName
            This parameter is required to use this function, it is simply the name of the 
            remote server to query against.
        .PARAMETER Full
            This parameter specifies if the cycle should be normal or full.  
            The default is normal.
    #>
    [CmdletBinding()]
    param
    (
        [String]$ComputerName,
        [bool]$Full = $false
    ) # end param

    $strAction = "{00000000-0000-0000-0000-000000000010}"

    if(Test-Connection -computername $ComputerName -count 1 -quiet)
    {
        if ($Full -eq $true)
        {
			$ActionObject = Get-WmiObject -Query "Select * from InventoryActionStatus where InventoryActionID = '$strAction'" -Namespace root\ccm\invagt -ComputerName $ComputerName
			$ActionObject | Remove-WmiObject
        } # end if

		$Error.Clear()
		$WMIPath = "\\" + $ComputerName + "\root\ccm:SMS_Client"
		$SMSwmi = [wmiclass] $WMIPath
        [Void]$SMSwmi.TriggerSchedule($strAction)
        
		if($Error[0])
        {
            $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Error'; 'Error' = "$Error";}
        }
        else
        {
            $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Successful'; 'Error' = "";}
        } # end if
    }
    else
    {
        $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Off'; 'Error' = "";}
    } # end if

	Write-Output $strOutput
} # end function Invoke-CMFileCollectionCycle

function Invoke-CMApplicationDeploymentEvaluationCycle
{
    <#
        .SYNOPSIS
            Invokes a CM client Application Deployment Evaluation Cycle action on a remote client
        .DESCRIPTION
            This function makes a WMI call to the remote server name that was passed as a
            function parameter.  It calls WMI and invokes a client action.
        .PARAMETER ServerName
            This parameter is required to use this function, it is simply the name of the 
            remote server to query against.
    #>
    [CmdletBinding()]
    param
    (
        [String]$ComputerName
    ) # end param

    $strAction = "{00000000-0000-0000-0000-000000000121}"

    if(Test-Connection -computername $ComputerName -count 1 -quiet)
    {
		$Error.Clear()
		$WMIPath = "\\" + $ComputerName + "\root\ccm:SMS_Client"
		$SMSwmi = [wmiclass] $WMIPath
        [Void]$SMSwmi.TriggerSchedule($strAction)
        
		if($Error[0])
        {
            $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Error'; 'Error' = "$Error";}
        }
        else
        {
            $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Successful'; 'Error' = "";}
        } # end if
    }
    else
    {
        $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Off'; 'Error' = "";}
    } # end if

	Write-Output $strOutput
} # end function Invoke-CMApplicationDeploymentEvaluationCycle

function Invoke-CMMachinePolicyCycle
{
    <#
        .SYNOPSIS
            Invokes a CM client Machine Policy Cycle action on a remote client
        .DESCRIPTION
            This function makes a WMI call to the remote server name that was passed as a
            function parameter.  It calls WMI and invokes a client action.
        .PARAMETER ServerName
            This parameter is required to use this function, it is simply the name of the 
            remote server to query against.
    #>
    [CmdletBinding()]
    param
    (
        [String]$ComputerName
    ) # end param

    $strAction = "{00000000-0000-0000-0000-000000000021}"

    if(Test-Connection -computername $ComputerName -count 1 -quiet)
    {
		$Error.Clear()
		$WMIPath = "\\" + $ComputerName + "\root\ccm:SMS_Client"
		$SMSwmi = [wmiclass] $WMIPath
        [Void]$SMSwmi.TriggerSchedule($strAction)
        
		if($Error[0])
        {
            $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Error'; 'Error' = "$Error";}
        }
        else
        {
            $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Successful'; 'Error' = "";}
        } # end if
    }
    else
    {
        $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Off'; 'Error' = "";}
    } # end if

	Write-Output $strOutput
} # function Invoke-CMMachinePolicyCycle

function Invoke-CMSoftwareMeteringCycle
{
    <#
        .SYNOPSIS
            Invokes a CM client Software Metering Cycle action on a remote client
        .DESCRIPTION
            This function makes a WMI call to the remote server name that was passed as a
            function parameter.  It calls WMI and invokes a client action.
        .PARAMETER ServerName
            This parameter is required to use this function, it is simply the name of the 
            remote server to query against.
    #>
    [CmdletBinding()]
    param
    (
        [String]$ComputerName
    ) # end param

    $strAction = "{00000000-0000-0000-0000-000000000031}"

    if(Test-Connection -computername $ComputerName -count 1 -quiet)
    {
		$Error.Clear()
		$WMIPath = "\\" + $ComputerName + "\root\ccm:SMS_Client"
		$SMSwmi = [wmiclass] $WMIPath
        [Void]$SMSwmi.TriggerSchedule($strAction)
        
		if($Error[0])
        {
            $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Error'; 'Error' = "$Error";}
        }
        else
        {
            $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Successful'; 'Error' = "";}
        } # end if
    }
    else
    {
        $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Off'; 'Error' = "";}
    } # end if

	Write-Output $strOutput
} # end function Invoke-CMSoftwareMeteringCycle

function Invoke-CMSoftwareUpdatesDeploymentEvaluationCycle
{
    <#
        .SYNOPSIS
            Invokes a CM client Software Updates Deployment Evaluation Cycle action on a remote client
        .DESCRIPTION
            This function makes a WMI call to the remote server name that was passed as a
            function parameter.  It calls WMI and invokes a client action.
        .PARAMETER ServerName
            This parameter is required to use this function, it is simply the name of the 
            remote server to query against.
    #>

    [CmdletBinding()]
    param
    (
        [String]$ComputerName
    ) # end param

    $strAction = "{00000000-0000-0000-0000-000000000108}"

    if(Test-Connection -computername $ComputerName -count 1 -quiet)
    {
		$Error.Clear()
		$WMIPath = "\\" + $ComputerName + "\root\ccm:SMS_Client"
		$SMSwmi = [wmiclass] $WMIPath
        [Void]$SMSwmi.TriggerSchedule($strAction)
        
		if($Error[0])
        {
            $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Error'; 'Error' = "$Error";}
        }
        else
        {
            $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Successful'; 'Error' = "";}
        } # end if
    }
    else
    {
        $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Off'; 'Error' = "";}
    } # end if

	Write-Output $strOutput
} # end function Invoke-CMSoftwareUpdatesDeploymentEvaluationCycle

function Invoke-CMSoftwareUpdatesScanCycle
{
    <#
        .SYNOPSIS
            Invokes a CM client Software Updates Scan Cycle action on a remote client
        .DESCRIPTION
            This function makes a WMI call to the remote server name that was passed as a
            function parameter.  It calls WMI and invokes a client action.
        .PARAMETER ServerName
            This parameter is required to use this function, it is simply the name of the 
            remote server to query against.
    #>
    [CmdletBinding()]
    param
    (
        [String]$ComputerName
    ) # end param

    $strAction = "{00000000-0000-0000-0000-000000000113}"

    if(Test-Connection -computername $ComputerName -count 1 -quiet)
    {
		$Error.Clear()
		$WMIPath = "\\" + $ComputerName + "\root\ccm:SMS_Client"
		$SMSwmi = [wmiclass] $WMIPath
        [Void]$SMSwmi.TriggerSchedule($strAction)
        
		if($Error[0])
        {
            $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Error'; 'Error' = "$Error";}
        }
        else
        {
            $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Successful'; 'Error' = "";}
        } # end if
    }
    else
    {
        $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Off'; 'Error' = "";}
    } # end if

	Write-Output $strOutput
} # end function Invoke-CMSoftwareUpdatesScanCycle

function Invoke-CMWindowsInstallerSourceListUpdateCycle
{
    <#
        .SYNOPSIS
            Invokes a CM client Windows Installer Source List Cycle action on a remote client
        .DESCRIPTION
            This function makes a WMI call to the remote server name that was passed as a
            function parameter.  It calls WMI and invokes a client action.
        .PARAMETER ServerName
            This parameter is required to use this function, it is simply the name of the 
            remote server to query against.
    #>

    [CmdletBinding()]
    param
    (
        [String]$ComputerName
    ) # end param

    $strAction = "{00000000-0000-0000-0000-000000000032}"

    if(Test-Connection -computername $ComputerName -count 1 -quiet)
    {
		$Error.Clear()
		$WMIPath = "\\" + $ComputerName + "\root\ccm:SMS_Client"
		$SMSwmi = [wmiclass] $WMIPath
        [Void]$SMSwmi.TriggerSchedule($strAction)
        
		if($Error[0])
        {
            $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Error'; 'Error' = "$Error";}
        }
        else
        {
            $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Successful'; 'Error' = "";}
        } # end if
    }
    else
    {
        $strOutput = [pscustomobject]@{'ComputerName' = "$ComputerName"; 'Status' = 'Off'; 'Error' = "";}
    } # end if

	Write-Output $strOutput
} # end function Invoke-CMWindowsInstallerSourceListUpdateCycle

function Get-CMServerData
{
    <#
        .SYNOPSIS
            Pull server data from the CM Database.
        .DESCRIPTION
            This function will return all of the current server records from the SCCM Database with several useful pieces of data.
    #>
    [CmdletBinding()]
    Param()

    $SqlQuery = @"
        Select 
        a.Name0 As ServerName,
        (Select Top 1 IPAddress0 from v_GS_NETWORK_ADAPTER_CONFIGURATION Where IPEnabled0 = 1 and ResourceID = a.ResourceID) As IP,
        c.Caption0 As OS,
        a.description0 As [AD Description],
        a.AD_Site_Name0 As [AD Site],
        ClientStatus=(case when a.Client0 = 1 then 'Installed' else 'Not Installed' end),
        ActiveStatus=(case when a.Active0 = 1 then 'Active' else 'Not Active' end),
        VM=(case when a.Is_Virtual_Machine0 = 1 then 'Virtual' else 'Physical' end),
        d.Model0 As Model,
        c.TotalVisibleMemorySize0 As RAM
        from v_R_SYSTEM a Left Join v_GS_Operating_System c On a.ResourceID = c.ResourceID
        Left Join v_GS_COMPUTER_SYSTEM d On a.ResourceID = d.ResourceID
        Where a.Operating_System_Name_and0 like '%Server%'
        Order By ServerName ASC
"@
    $ServerList = Get-DatabaseData -verbose -connectionString (Get-CMConnectionString) -query $SqlQuery
    $ServerList | Write-Output
} # end function Get-CMServerData

function Get-CMServerListByCollection
{
    <#
        .SYNOPSIS
            Pull server data from the CM Database.
        .DESCRIPTION
            This function will return all of the current server records from the SCCM Database with several useful pieces of data.
    #>
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory=$true)][string]$CollectionName
    ) # end param

    $SqlQuery = @"
        select 
              System.Name0 As Name, 
              FCM.collectionID,
              VColl.CollectionName,
              VColl.CollectionComment
        from 
        v_R_System System
        left join v_fullcollectionmembership FCM on FCM.resourceid = System.resourceid 
        left join v_Collections VColl on FCM.collectionID = VColl.SiteID

        Where VColl.CollectionName = '$CollectionName'
        Order by System.Name0 ASC
"@
    $ServerList = Get-DatabaseData -verbose -connectionString (Get-CMConnectionString) -query $SqlQuery
    $ServerList | Write-Output
} # end function Get-CMServerListByCollection

function Get-CMDuplicates
{
    <#
        .SYNOPSIS
            Pull a list of duplicate device entries in the SCCM database.
        .DESCRIPTION
            This function will return all of the SCCM devices that have more than one entry, good for finding device duplicates.
    #>
    [CmdletBinding()]
    Param()
    $SqlQuery = @"
        Select 
        Name0 As ServerName, Count(Name0) As Count
        from v_R_SYSTEM 
        Group By Name0
        Order By ServerName ASC
"@
    $ServerList = Get-DatabaseData -verbose -connectionString (Get-CMConnectionString) -query $SqlQuery
    $ServerList | ? count -gt 1 | Write-Output
} # end function Get-CMDuplicates

function Get-CMConnectionString
{
    <#
        .SYNOPSIS
            This function returns a connection string for the UCS database.
        .DESCRIPTION
            This function is a easy place to store the connection information for the UCS database.
        .EXAMPLE
            PS C:\PS Script\UCS> Get-UCSConnectionString
            Server=RTCMARLON2012R2;Database=UCS;Integrated Security=true
    #>   
    [CmdletBinding()]
    param()
    $CMDBServer = 'NDCINFSQL001SG2\INF2'
    $CMDBName   = 'CM_PRI'
    $CMConnectionString = "Server=$CMDBServer;Database=$CMDBName;user=CM_Reports;password=Snowm@n1"
    return $CMConnectionString
} # end function Get-CMConnectionString

function Reset-CMClientPolicy2
{
    <#
        .SYNOPSIS
            Reset the Client's Local Policy
        .DESCRIPTION
            This function makes a WMI call to the remote server name that was passed as a
            function parameter.  This will reset the client policy and force it to redownload from the MP.
        .PARAMETER ServerName
            This parameter is required to use this function, it is simply the name of the 
            remote server to query against.
    #>
    [CmdletBinding()]
    param
    (
        [string]$ComputerName
    ) # end param

    process
    {
        $Computer = $ComputerName
        $WMIPath = "\\" + $Computer + "\root\ccm:SMS_Client"
        $smsClient = [wmiclass] $WMIPath
        $null = $smsClient.ResetPolicy(1)
        $null = $smsClient.RequestMachinePolicy()
        $null = $smsClient.EvaluateMachinePolicy()
     
        if($Error[0])
        {
            $Output = [pscustomobject]@{'ComputerName' = "$Computer"; 'Status' = 'Error'; 'Error' = "$Error";}
        }
        else
        {
            $Output = [pscustomobject]@{'ComputerName' = "$Computer"; 'Status' = 'Success'; 'Error' = "";}
        }

        Write-Output $Output
    } # end process
} # end function Reset-CMClientPolicy2

# Modified to use DCOM instead of WS-MAN
function Invoke-AppInstallation  
{  
    <#
        .SYNOPSIS
            Invoke Application install
        .DESCRIPTION
            This function makes a WMI call to the remote server name that was passed as a
            function parameter.  This will invoke an application installation.
        .PARAMETER ComputerName
            This parameter is required to use this function, it is simply the name of the 
            remote server to query against.
        .PARAMETER AppName
            This parameter is the name of the application to invoke the install action on.
        .PARAMETER Method
            This parameter specifies either the Install or Uninstall method for the install action.
    #>
    [CmdletBinding()]  
    param  
    (
        [String][Parameter(Mandatory=$True, Position=1)] $Computername,
        [String][Parameter(Mandatory=$True, Position=2)] $AppName,
        [ValidateSet("Install","Uninstall")][String][Parameter(Mandatory=$True, Position=3)] $Method  
    ) # end param  
   
    begin
    {
        $SO = New-CimSessionOption -Protocol Dcom
        $CIMSession = New-CimSession -ComputerName $Computername -SessionOption $SO 
        $Application = (Get-CimInstance -ClassName CCM_Application -Namespace "root\ccm\clientSDK" -CimSession $CIMSession | Where-Object {$_.Name -like $AppName})  
   
        $Args = @{
            EnforcePreference = [UINT32] 0  
            Id = "$($Application.id)"  
            IsMachineTarget = $Application.IsMachineTarget  
            IsRebootIfNeeded = $False  
            Priority = 'High'  
            Revision = "$($Application.Revision)"
        } # end hash    
    } # end begin 
   
    process   
    {  
        Invoke-CimMethod -Namespace "root\ccm\clientSDK" -ClassName CCM_Application -CimSession $CIMSession -MethodName $Method -Arguments $Args    
    } # end process  
   
    end
    {
        Remove-CimSession -CimSession $CIMSession
    } # end end  
} # end function Invoke-AppInstallation
