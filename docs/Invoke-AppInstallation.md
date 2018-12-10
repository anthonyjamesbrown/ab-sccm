---
external help file: AB-SCCM-help.xml
Module Name: AB-SCCM
online version:
schema: 2.0.0
---

# Invoke-AppInstallation

## SYNOPSIS
Invoke Application install

## SYNTAX

```
Invoke-AppInstallation [-Computername] <String> [-AppName] <String> [-Method] <String> [<CommonParameters>]
```

## DESCRIPTION
This function makes a WMI call to the remote server name that was passed as a
function parameter. 
This will invoke an application installation.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Computername
This parameter is required to use this function, it is simply the name of the 
remote server to query against.

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

### -AppName
This parameter is the name of the application to invoke the install action on.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Method
This parameter specifies either the Install or Uninstall method for the install action.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
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
