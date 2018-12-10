---
external help file: AB-SCCM-help.xml
Module Name: AB-SCCM
online version:
schema: 2.0.0
---

# Get-CMClientPolicy

## SYNOPSIS
Returns a list of CM Policies on the specified server.

## SYNTAX

```
Get-CMClientPolicy [[-ComputerName] <String>] [<CommonParameters>]
```

## DESCRIPTION
This function makes a WMI call to the remote server name that was passed as a
function parameter. 
It calls WMI and returns a list of assigned application policies.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
