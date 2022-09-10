function Get-Info {
    param (
        [ValidateNotNullOrEmpty()][string]$InfoSource = "All"
    )

    $UUID = (get-wmiobject Win32_ComputerSystemProduct).UUID.ToString()

    $AllResults = @()

    $AllResults += Get-SystemInformation
    $AllResults += Get-CPUInfo 
    $AllResults += Get-GPUInfo
    $AllResults += Get-VolumeInfo
    $AllResults += Get-Users
    $AllResults += Get-NetworkAdapter
    $AllResults += Get-NetworkAdapterIPConfiguration

    $returnObject = @{}
    $returnObject[$UUID] = $AllResults

    return $returnObject | ConvertTo-Json -Depth 10 

}

function Get-CPUInfo {
    $returnObject = @{}

    $_CmdOutput = Get-WmiObject Win32_Processor | select * 
    $_CmdOutputRows = $_CmdOutput | Measure-Object | Select-Object Count

    if ($_CmdOutputRows.Count -ge 2) {
        $_CmdOutput | foreach {
            $DeviceID = $_.DeviceID.ToString()
            $returnObject.$DeviceID = $_.Name
            $returnObject.$DeviceID.NoOfCores = $_.NumberOfCores
            $returnObject.$DeviceID.NoOfLogicalProc = $_.NumberOfLogicalProcessors
        }
    } else {
        $DeviceID = $_CmdOutput.DeviceID.ToString()
        $returnObject.$DeviceID = @{} 
        $returnObject.$DeviceID.Name = $_CmdOutput.Name
        $returnObject.$DeviceID.NoOfCores = $_CmdOutput.NumberOfCores
        $returnObject.$DeviceID.NoOfLogicalProc = $_CmdOutput.NumberOfLogicalProcessors
    }

    return $returnObject
}

function Get-GPUInfo {
    $returnObject = @{}

    $_CmdOutput = Get-WmiObject Win32_VideoController
    $_CmdOutputRows = $_CmdOutput | Measure-Object | Select-Object Count

    $returnObject["Name"] = $_CmdOutput.Name
    $returnObject["Status"] = $_CmdOutput.Status

    return $returnObject
}

function Get-VolumeInfo {
    $returnObject = @{}

    $_CmdOutput = Get-WmiObject Win32_LogicalDisk
    $_CmdOutputRows = $_CmdOutput | Measure-Object | Select-Object Count

    if ($_CmdOutputRows.Count -ge 2) {
        $_CmdOutput | foreach {
            $DriveName = "Drive"+ $_.DeviceID.Trim(":")
            $returnObject.$DriveName = @{}
            $returnObject.$DriveName.VolumeName = $_.VolumeName
            $returnObject.$DriveName.Size = $_.Size
            $returnObject.$DriveName.FreeSpace = $_.FreeSpace
        }
    } else {
        $returnObject[$_CmdOutput.DeviceID] = @{
            VolumeName = $_CmdOutput.VolumeName
            Size = $_CmdOutput.Size
            FreeSpace = $_CmdOutput.FreeSpace
        }
    }

    return $returnObject
}

function Get-Users {
    $returnObject = @{}

    $_CmdOutput = Get-WmiObject Win32_UserAccount | Select-Object *
    $_CmdOutputRows = $_CmdOutput | Measure-Object | Select-Object Count

    if ($_CmdOutputRows.Count -ge 2) {
        $_CmdOutput | foreach {
            $Name = $_.Name
            $returnObject.$Name = @{}
            $returnObject.$Name.SID = $_.SID
            $returnObject.$Name.Disabled = $_.Disabled
            $returnObject.$Name.LocalAccount = $_.LocalAccount
            $returnObject.$Name.PasswordExpires = $_.PasswordExpires
            $returnObject.$Name.Domain = $_.Domain

        }
    } else {
        $returnObject[$_CmdOutput.Caption] = @{
            SID = $_CmdOutput.SID
            Disabled = $_CmdOutput.Disabled
            LocalAccount = $_CmdOutput.LocalAccount
            PasswordExpires = $_CmdOutput.PasswordExpires
            Domain = $_CmdOutput.Domain

        }
    }
    return $returnObject
}

function Get-NetworkAdapter {
    $returnObject = @{}

    $_CmdOutput = Get-WmiObject -Class win32_networkadapter  | Where-Object { $_.AdapterType -eq "Ethernet 802.3" }  |  select MACAddress,DeviceID,Name
    $_CmdOutputRows = $_CmdOutput | Measure-Object | Select-Object Count

    if ($_CmdOutputRows.Count -ge 2) {
        $_CmdOutput | foreach {
            $DeviceID = $_.DeviceID
            $returnObject.$DeviceID = @{}
            $returnObject.$DeviceID.Name = $_.Name
            $returnObject.$DeviceID.MAC = $_.MACAddress

        }
    } else {
        $Index = $_CmdOutput.DeviceID.ToString()
        $returnObject[$Index] = @{
            Name = $_CmdOutput.Name
            MAC = $_CmdOutput.MACAddress
        }
    }
    return $returnObject
    
}

function Get-NetworkAdapterIPConfiguration {
    $returnObject = @{}

    $_CmdOutput = Get-WmiObject -Class win32_networkadapterconfiguration   | select Index,IPAddress  | where { $_.IPAddress -notlike '' }
    $_CmdOutputRows = $_CmdOutput | Measure-Object | Select-Object Count

    if ($_CmdOutputRows.Count -ge 2) {
        $_CmdOutput | foreach {
            $DeviceID = $_.Index.toString()
            $returnObject.$DeviceID = @{}
            $returnObject.$DeviceID.IPAddress = $_.IPAddress
        }
    } else {
        $Index=$_CmdOutput.Index.tostring()

        $returnObject[$Index] = @{}
        $returnObject[$Index].IPAddress = @()
        
        $_CmdOutput.IPAddress | foreach {
            $returnObject.$Index.IPAddress += $_ 
        }



    }
    return $returnObject
    
}


function Get-SystemInformation {
    $PCSerialNumber = (get-wmiobject Win32_BIOS).SerialNumber.ToString()
    $SystemSKUNumber = (get-wmiobject Win32_ComputerSystem).SystemSKUNumber.ToString()

    $returnObject = @{}
    $returnObject["ComputerName"] = $env:COMPUTERNAME
    $returnObject["BIOSSerialNumber"] = $PCSerialNumber
    $returnObject["SystemSKUNumber"] = $SystemSKUNumber

    return $returnObject
}

Get-Info



