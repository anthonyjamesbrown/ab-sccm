---
external help file: AB-SCCM-help.xml
Module Name: AB-SCCM
online version:
schema: 2.0.0
---

# Invoke-CMDiscoveryDataCollectionCycle

## SYNOPSIS
Invokes a CM client Discovery Data Collection Cycle action on a remote client

## SYNTAX

```
Invoke-CMDiscoveryDataCollectionCycle [[-ComputerName] <String>] [[-Full] <Boolean>] [<CommonParameters>]
```

## DESCRIPTION
This function makes a WMI call to the remote server name that was passed as a
function parameter. 
It calls WMI and invokes a client action.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -ComputerName
{{Fill ComputerName Description}}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Full
This parameter specifies if the cycle should be normal or full.
 
The default is normal.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: False
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
