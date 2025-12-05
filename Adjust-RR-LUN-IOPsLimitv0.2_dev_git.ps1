#Requires -Version 5.1
#Requires -RunAsAdministrator   

<#
.Synopsis
   Change de IOPS LIMIT RR Value
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.AUTHOR
    Juliano Alves de Brito Ribeiro (find me at julianoalvesbr@live.com or https://github.com/julianoabr or https://youtube.com/@powershellchannel)
.VERSION
    0.2
#>
Clear-Host

#VALIDATE MODULE
$moduleExists = Get-Module -Name Vmware.VimAutomation.Core

if ($moduleExists){
    
    Write-Output "The Module Vmware.VimAutomation.Core is already loaded"
    
}#if validate module
else{
    
    Import-Module -Name Vmware.VimAutomation.Core -WarningAction SilentlyContinue -ErrorAction Stop
    
}#else validate module

Set-PowerCLIConfiguration -WebOperationTimeoutSeconds 900 -Verbose -Confirm:$false -ErrorAction Continue

$Script:pathOutput = "$env:SystemDrive\Temp\Report\"

$currentDate = (Get-Date -Format "ddMMyyyy").ToString()

function Pause-PSScript
{

   Read-Host 'Pressione [ENTER] para continuar' | Out-Null

}

#VALIDATE IF OPTION IS NUMERIC
function isNumeric ($x) {
    $x2 = 0
    $isNum = [System.Int32]::TryParse($x, [ref]$x2)
    return $isNum
} #end function is Numeric


#FUNCTION CONNECT TO VCENTER
function Connect-ToVcenterServer
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateSet('Manual','Automatic')]
        $methodToConnect = 'Manual',

        # Param2 help description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [ValidateSet('server1','server2','server3','server4')]
        [System.String]$vCenterToConnect, 
        
        [Parameter(Mandatory=$false,
                   Position=2)]
        [System.String[]]$VCServers, 
                
        [Parameter(Mandatory=$false,
                   Position=3)]
        [ValidateSet('local.domain','local.internal','yourcompany.com','yourmatrix.com')]
        [System.String]$suffix, 

        [Parameter(Mandatory=$false,
                   Position=4)]
        [ValidateSet('80','443')]
        [System.String]$port = '443'
    )

        

    if ($methodToConnect -eq 'Automatic'){
                
        $Script:workingServer = $vCenterToConnect + '.' + $suffix
        
        Disconnect-VIServer -Server * -Confirm:$false -Force -Verbose -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

        $vcInfo = Connect-VIServer -Server $Script:WorkingServer -Port $Port -WarningAction Continue -ErrorAction Stop
           
    
    }#end of If Method to Connect
    else{
        
        Disconnect-VIServer -Server * -Confirm:$false -Force -Verbose -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

        $workingLocationNum = ""
        
        $tmpWorkingLocationNum = ""
        
        $Script:WorkingServer = ""
        
        $i = 0

        #MENU SELECT VCENTER
        foreach ($vcServer in $vcServers){
	   
                $vcServerValue = $vcServer
	    
                Write-Output "            [$i].- $vcServerValue ";	
	            $i++	
                }#end foreach	
                Write-Output "            [$i].- Exit this script ";

                while(!(isNumeric($tmpWorkingLocationNum)) ){
	                $tmpWorkingLocationNum = Read-Host "Type Vcenter Number that you want to connect"
                }#end of while

                    $workingLocationNum = ($tmpWorkingLocationNum / 1)

                if(($WorkingLocationNum -ge 0) -and ($WorkingLocationNum -le ($i-1))  ){
	                $Script:WorkingServer = $vcServers[$WorkingLocationNum]
                }
                else{
            
                    Write-Host "Exit selected, or Invalid choice number. End of Script " -ForegroundColor Red -BackgroundColor White
            
                    Exit;
                }#end of else

        #Connect to Vcenter
        $Script:vcInfo = Connect-VIServer -Server $Script:WorkingServer -Port $port -WarningAction Continue -ErrorAction Continue
  
    
    }#end of Else Method to Connect

}#End of Function Connect to Vcenter

#DEFINE VCENTER LIST
$vcServerList = @();

#ADD OR REMOVE VCs        
$vcServerList = ('server1','server2','server3','server4') | Sort-Object


Do
{
 
        $tmpMethodToConnect = Read-Host -Prompt "Type (Manual) if you want to choose VC to Connect. Type (Automatic) if you want to Type the Name of VC to Connect"

        if ($tmpMethodToConnect -notmatch "^(?:manual\b|automatic\b)"){
    
            Write-Host "You typed an invalid word. Type only (manual) or (automatic)" -ForegroundColor White -BackgroundColor Red
    
        }
        else{
    
            Write-Host "You typed a valid word. I will continue =D" -ForegroundColor White -BackgroundColor DarkBlue
    
        }
    
    }While ($tmpMethodToConnect -notmatch "^(?:manual\b|automatic\b)")


if ($tmpMethodToConnect -match "^\bautomatic\b$"){

    $tmpSuffix = Read-Host "Write the suffix of VC that you want to connect (host.intranet or uolcloud.intranet)"

    $tmpVC = Read-Host "Write the hostname of VC that you want to connect"

    Connect-ToVcenterServer -vCenterToConnect $tmpVC -suffix $tmpSuffix -methodToConnect Automatic

}
else{

    Connect-ToVcenterServer -methodToConnect $tmpMethodToConnect -VCServers $vcServerList

}

Write-Output "`n"

Write-Host "SELECT THE CLUSTER THAT YOU WANT TO WORK" -ForegroundColor DarkBlue -BackgroundColor White

Write-Output "`n"

#CREATE CLUSTER LIST
        $vCClusterList = @()
        
        $vCClusterList = (VMware.VimAutomation.Core\Get-Cluster | Select-Object -ExpandProperty Name| Sort-Object)

        $tmpWorkingClusterNum = ""
        
        $Script:WorkingCluster = ""
        
        $i = 0
        

        #CREATE CLUSTER MENU LIST
        foreach ($vCCluster in $vCClusterList){
	   
            $vCClusterValue = $vCCluster
	    
        Write-Output "            [$i].- $vCClusterValue ";	
	    
        $i++	
        
        }#end foreach	
        
        Write-Output "            [$i].- Exit this script ";

        while(!(isNumeric($tmpWorkingClusterNum)) ){
	    
            $tmpWorkingClusterNum = Read-Host "Type the vCenter Cluster Number that you want to Adjust Round Robin"
        
        }#end of while

            $workingClusterNum = ($tmpWorkingClusterNum / 1)

        if(($workingClusterNum -ge 0) -and ($workingClusterNum -le ($i-1))  ){
	        
            $Script:WorkingCluster = $vCClusterList[$workingClusterNum]
        }
        else{
            
            Write-Host "Exit selected, or Invalid choice number. End of Script " -ForegroundColor Red -BackgroundColor White
            
            Exit;
        }#end of else

#get all hosts of selected cluster
$script:allESXiHosts = (VMware.VimAutomation.Core\Get-VMHost -Location $Script:WorkingCluster | Select-Object -ExpandProperty Name | Sort-Object)

#get a single host to get datastores
$script:singleEsxiHost = ($Script:allESXiHosts | Select-Object -First 1)

function AdjustRRLun-IOPSLimit
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateRange(1,1000)]
        [int]$IOPSLimitValue
   
    )

Do {

[int]$userMenuChoice = 0

$lunlist = ""

$waveToAdjust = ""

#MAIN MENU - WHILE YOU DON'T PRESS 4. IT WILL BACK TO MENU      
    Do {
    
    Write-Output "

----------MENU ADJUST ROUND ROBIN IOPS LIMIT----------

The IOPS Limit value will be adjust to: $IOPSLimitValue

1 = Generate Report Before Adjust IOPS Limit
2 = Generate Report After Adjust IOPS LIMIT
3 = Adjusting Round Robin IOPS limit in a Cluster: $Script:WorkingCluster
4 = Exit

------------------------------------------------------"

[int]$userMenuChoice = Read-host -prompt "Select an Option and Press Enter - Only Accept 1,2,3 or 4"

        switch ($userMenuChoice){
        1 {
            
            Write-Host "O relatório será salvo em: $Script:pathOutput" -ForegroundColor White -BackgroundColor Red

            #Datastores
            $dsNameList = @()

            $dsNameList = (VMware.VimAutomation.Core\Get-Vmhost -Name $singleEsxiHost | Get-Datastore  | Where-Object -FilterScript {($PSItem.ExtensionData.Info.Vmfs.Local -eq $false) -and ($psitem.Name -like 'DS_*')} | Select-Object -ExpandProperty Name | Sort-Object)

            $totalDSList = $dsNameList.Count

            Write-Host "I found: $totalDSList Datastores" -ForegroundColor White -BackgroundColor DarkBlue

            $lunNAAList = @()
        
            foreach ($dsName in $dsNameList)
            {
            
                $dsObj = Get-datastore -Name $dsName
            
                $dsNAA = $dsObj.ExtensionData.Info.Vmfs.Extent[0].DiskName

                $lunNAAList += $dsNAA
                           
            }#end of foreach get NAA ID

            $csvFile = $Script:pathOutput + "LUNCONFIG-BEFORE-ADJUST-RR-IOPS-$waveToAdjust-$currentDate.csv"

            #Check to see if the file exists, if it does then overwrite it.
            if (Test-Path $csvfile) {
    
                Write-Output "Overwriting $csvfile ..."
    
                Start-Sleep -Milliseconds 400

                Remove-Item $csvfile -Confirm -Verbose
            }  


            foreach ($esxiHost in $Script:allESXiHosts){
            
                $esxiHostObj = Vmware.VimAutomation.Core\Get-VMHost -Name $esxiHost
               
                foreach ($lunNAA in $lunNAAList){
                    
                    Write-Host "NAA VALUE: $lunNAA" -ForegroundColor White -BackgroundColor DarkGreen

                    Get-ScsiLun -CanonicalName $lunNAA -VmHost $esxiHostObj | Select-Object -Property VmHost,CanonicalName,MultipathPolicy,CommandsToSwitchPath | Export-Csv -NoTypeInformation -Path $csvFile -Append -Verbose
        
                }#end ForeachLuns
        
            }#end ForeachHosts

            explorer $Script:pathOutput
    
    }#end of 1
        2 {
           
            Write-Host "O relatório será salvo em: $Script:pathOutput" -ForegroundColor White -BackgroundColor Red
             
            #Datastores
            $dsNameList = @()

            $dsNameList = (VMware.VimAutomation.Core\Get-Vmhost -Name $singleEsxiHost | Get-Datastore  | Where-Object -FilterScript {($PSItem.ExtensionData.Info.Vmfs.Local -eq $false) -and ($psitem.Name -like 'DS_*')} | Select-Object -ExpandProperty Name | Sort-Object)

            $totalDSList = $dsNameList.Count

            Write-Host "I found: $totalDSList Datastores" -ForegroundColor White -BackgroundColor DarkBlue
            
            $lunNAAList = @()
        
            foreach ($dsName in $dsNameList)
            {
            
                $dsObj = Get-datastore -Name $dsName
            
                $dsNAA = $dsObj.ExtensionData.Info.Vmfs.Extent[0].DiskName

                $lunNAAList += $dsNAA
                           
            }
            
            $csvFile = $Script:pathOutput + "LUNCONFIG-AFTER-ADJUST-RR-IOPS-$waveToAdjust-$currentDate.csv"

            #Check to see if the file exists, if it does then overwrite it.
            if (Test-Path $csvfile) {
    
                Write-Output "Overwriting $csvfile ..."
    
                Start-Sleep -Milliseconds 400

                Remove-Item $csvfile -Confirm -Verbose
            }  


            foreach ($esxiHost in $Script:allESXiHosts){

                $esxiHostObj = Vmware.VimAutomation.Core\Get-VMHost -Name $esxiHost
    
                foreach ($lunNAA in $lunNAAList){

                Write-Host "NAA VALUE: $lunNAA" -ForegroundColor White -BackgroundColor DarkGreen
        
                Get-ScsiLun -CanonicalName $lunNAA -VmHost $esxiHostObj | Select-Object -Property VmHost,CanonicalName,MultipathPolicy,CommandsToSwitchPath | Export-Csv -NoTypeInformation -Path $csvFile -Append -Verbose
        
                }#end ForeachLuns
        
            }#end ForeachHosts

    explorer $Script:pathOutput
    
    }#end of 2
        3 {
        
        Write-Host "Esta opção ajusta o Round Robin para o valor digitado: $intIOPSLimitValue" -ForegroundColor White -BackgroundColor Red
        
        #Datastores
        $dsNameList = @()

        $dsNameList = (VMware.VimAutomation.Core\Get-Vmhost -Name $singleEsxiHost | Get-Datastore  | Where-Object -FilterScript {($PSItem.ExtensionData.Info.Vmfs.Local -eq $false) -and ($psitem.Name -like 'DS_*')} | Select-Object -ExpandProperty Name | Sort-Object)

        $totalDSList = $dsNameList.Count

        Write-Host "I found: $totalDSList Datastores" -ForegroundColor White -BackgroundColor DarkBlue

        $lunNAAList = @()
        
        foreach ($dsName in $dsNameList)
        {
            
            $dsObj = Get-datastore -Name $dsName
            
            $dsNAA = $dsObj.ExtensionData.Info.Vmfs.Extent[0].DiskName

            $lunNAAList += $dsNAA
            
        }
        
        $csvFile = $Script:pathOutput + "LUNCONFIG-ADJUST-RR-IOPS-$waveToAdjust-$currentDate.csv"

        #Check to see if the file exists, if it does then overwrite it.
        if (Test-Path $csvfile) {
    
            Write-Output "Overwriting $csvfile ..."
    
            Start-Sleep -Milliseconds 400

            Remove-Item $csvfile -Confirm -Verbose
        }  


        foreach ($esxiHost in $Script:allESXiHosts){
            
            $esxiHostObj = Vmware.VimAutomation.Core\Get-VMHost -Name $esxiHost

            foreach ($lunNAA in $lunNAAList){
        
                Get-ScsiLun -CanonicalName $lunNAA -VmHost $esxiHostObj | Set-ScsiLun -CommandsToSwitchPath $IOPSLimitValue -Verbose
                
            }#end ForeachLuns
        
        }#end ForeachHosts

        explorer $Script:pathOutput
    
    
    }#end of 3
        4 {
    
            Disconnect-VIServer -Force -Confirm:$false -WarningAction SilentlyContinue -ErrorAction SilentlyContinue

            Write-Output "You choose finish the Script"
    
            Start-Sleep -Seconds 2
    
            Exit


    }#end of 4
        }#end of switch

    }until($userMenuChoice -lt 1 -or $userMenuChoice -gt 4)#end of Do Until

}while ($userMenuChoice -ne 4)#end of Do While


}#End of Function AdjustRRLun-IOPSLimit


$tmpIOPSLimitValue = Read-Host "Digite um valor para ajustar o IOPS Limits (Range aceito: 1 a 1000)" 

$intIOPSLimitValue = ($tmpIOPSLimitValue / 1)

[System.String]$Script:waveToAdjust = Read-Host "Digite o número ou o nome da onda que será ajustada (Exemplo: Onda1, CH-156)"

AdjustRRLun-IOPSLimit -IOPSLimitValue $intIOPSLimitValue
