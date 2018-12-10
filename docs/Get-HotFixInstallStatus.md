---
external help file: AB-SCCM-help.xml
Module Name: AB-SCCM
online version:
schema: 2.0.0
---

# Get-HotFixInstallStatus

## SYNOPSIS
Checks if a given Hotfix has been applied to a given server.

## SYNTAX

```
Get-HotFixInstallStatus [-ServerName] <String> [-Hotfix] <String> [<CommonParameters>]
```

## DESCRIPTION
This function makes a WMI call to the remote server name that was passed as a
function parameter. 
It calls the Win32_QuickFixEngineering WMI class and queries
the HotFixID property for the Hotfix ID that was passed as a parameter. 
The function
will return True is the hotfix was found and False if it was not found.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -ServerName
This parameter is required to use this function, it is simply the name of the 
remote server to query against.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Hotfix
This parameter is required to use this function, it is the name of the Hotfix to check for.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
