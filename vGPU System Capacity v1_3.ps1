############################################################################
# vGPU System Capcity for PowerCLI Version 1.3
# Copyright (C) 2019 Tony Foster
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>
############################################################################


Function vGPUSystemCapacity {
	param(
	[Parameter(Mandatory = $true)]
	[string]
	$vGPUType,
	
	[Parameter(Mandatory = $false)]
	[string]
	$vGPULocations,
	
	[Parameter(Mandatory = $false)]
	[string]
	$vGPUHostState
	# Valid states (connected,disconnected,notresponding,maintenance) or comma seperated combination 
	)
	
	# This function takes a string argument of the vGPU value, 
	#  it also takes an optional string argument for the location to querry (VIcontainer[]),
	#  it also takes an optional string argument for hosts state (VMHostState[]) valid values are 
	#  (connected,disconnected,notresponding,maintenance) or a combintation of these values seperated by commas
	#
	# vGPUSystemCapacity "vGPU Type" |"vGPU Location"| |"vGPU Host State"|
	#
	# It will then calculate the remaining number of that vGPU type that can be deployed and returns it.
	# Example: vGPUSystemCapacity "grid_p4-2q"
	#  Will return the number of remaing VMs that can be powered on with that given profile
	# 
	# Example: vGPUSystemCapacity "grid_p4-2q" "Cluster Name"
	#  Will return the number of remaing VMs that can be powered on with that given profile for the given cluster
	#
	# Example: vGPUSystemCapacity "grid_p4-2q" "Cluster Name" "maintenance,disconnected"
	#  Will return the number of remaining VMs that can be powered on with the given profile for the given cluster 
	#   with hosts that are in maintenance or disconnected states.
	#
	# Should an error occur the function will return a -1 value.
	# The function does not take into account, yet, Cards that have multiple GPUs on them
	# The function does not take into account, yet, vGPUs spread across multiple cards and assumes things are placed for density

	try{
		# Create a list of GPU Specs
		[System.Collections.ArrayList]$vGPUlist = @()
			#Name, vGPU per GPU, vGPU per Board, physical GPUs per board
			#P4
			$obj = [pscustomobject]@{vGPUname="grid_p4-8q"; vGPUperGPU=1; vGPUperBoard=1; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_p4-4q";vGPUperGPU=2;vGPUperBoard=2; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_p4-2q";vGPUperGPU=4;vGPUperBoard=4; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_p4-1q";vGPUperGPU=8;vGPUperBoard=8; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			#P40
			$obj = [pscustomobject]@{vGPUname="grid_p40-24q";vGPUperGPU=1;vGPUperBoard=1; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_p40-12q";vGPUperGPU=2;vGPUperBoard=2; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_p40-8q";vGPUperGPU=3;vGPUperBoard=3; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_p40-6q";vGPUperGPU=4;vGPUperBoard=4; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_p40-4q";vGPUperGPU=6;vGPUperBoard=6; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_p40-4q";vGPUperGPU=8;vGPUperBoard=8; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_p40-2q";vGPUperGPU=12;vGPUperBoard=12; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_p40-1q";vGPUperGPU=24;vGPUperBoard=24; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			#M60
			$obj = [pscustomobject]@{vGPUname="grid_m60-8q";vGPUperGPU=1;vGPUperBoard=2; pGPUperBoard=2}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_m60-4q";vGPUperGPU=2;vGPUperBoard=4; pGPUperBoard=2}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_m60-2q";vGPUperGPU=4;vGPUperBoard=8; pGPUperBoard=2}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_m60-1q";vGPUperGPU=8;vGPUperBoard=16; pGPUperBoard=2}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_m60-0q";vGPUperGPU=16;vGPUperBoard=32; pGPUperBoard=2}; $vGPUlist.add($obj)|out-null
			#M10
			$obj = [pscustomobject]@{vGPUname="grid_m10-8q";vGPUperGPU=1;vGPUperBoard=4; pGPUperBoard=4}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_m10-4q";vGPUperGPU=2;vGPUperBoard=8; pGPUperBoard=4}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_m10-2q";vGPUperGPU=4;vGPUperBoard=16; pGPUperBoard=4}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_m10-1q";vGPUperGPU=8;vGPUperBoard=32; pGPUperBoard=4}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_m10-0q";vGPUperGPU=16;vGPUperBoard=64; pGPUperBoard=4}; $vGPUlist.add($obj)|out-null
			#P100 PCIe 128GB
			$obj = [pscustomobject]@{vGPUname="grid_p100c-12q";vGPUperGPU=1;vGPUperBoard=1; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_p100c-6q";vGPUperGPU=2;vGPUperBoard=2; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_p100c-4q";vGPUperGPU=3;vGPUperBoard=3; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_p100c-2q";vGPUperGPU=6;vGPUperBoard=6; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_p100c-1q";vGPUperGPU=12;vGPUperBoard=12; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			#P100 PCIe 16GB
			$obj = [pscustomobject]@{vGPUname="grid_p100-16q";vGPUperGPU=1;vGPUperBoard=1; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_p100-8q";vGPUperGPU=2;vGPUperBoard=2; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_p100-4q";vGPUperGPU=4;vGPUperBoard=4; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_p100-2q";vGPUperGPU=8;vGPUperBoard=8; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_p100-1q";vGPUperGPU=16;vGPUperBoard=16; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			#T4
			$obj = [pscustomobject]@{vGPUname="grid_t4-16q";vGPUperGPU=1;vGPUperBoard=1; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_t4-8q";vGPUperGPU=2;vGPUperBoard=2; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_t4-4q";vGPUperGPU=4;vGPUperBoard=4; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_t4-2q";vGPUperGPU=8;vGPUperBoard=8; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_t4-1q";vGPUperGPU=16;vGPUperBoard=16; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			#V100
			$obj = [pscustomobject]@{vGPUname="grid_v100-16q";vGPUperGPU=1;vGPUperBoard=1; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_v100-8q";vGPUperGPU=2;vGPUperBoard=2; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_v100-4q";vGPUperGPU=4;vGPUperBoard=4; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_v100-2q";vGPUperGPU=8;vGPUperBoard=8; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_v100-1q";vGPUperGPU=16;vGPUperBoard=16; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			#V100 32GB
			$obj = [pscustomobject]@{vGPUname="grid_v100d-32q";vGPUperGPU=1;vGPUperBoard=1; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_v100d-16q";vGPUperGPU=2;vGPUperBoard=2; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_v100d-8q";vGPUperGPU=4;vGPUperBoard=4; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_v100d-4q";vGPUperGPU=8;vGPUperBoard=8; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_v100d-2q";vGPUperGPU=16;vGPUperBoard=16; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="grid_v100d-1q";vGPUperGPU=32;vGPUperBoard=32; pGPUperBoard=1}; $vGPUlist.add($obj)|out-null
			$obj = [pscustomobject]@{vGPUname="default";vGPUperGPU=0;vGPUperBoard=0; pGPUperBoard=0}; $vGPUlist.add($obj)|out-null #catch any non-defined cards and force them out as zeros
		#help from www.idmworks.com/what-is-the-most-efficient-way-to-create-a-collection-of-objects-in-powershell/
		
		# Take care of function paramaters
		if("" -eq $vGPULocations){ #if nothing is passed set the value to all clusters
			$vGPULocations = "*"
		} 
		if("" -eq $vGPUHostState){ #if nothing is passed set the value to all states
			$vGPUHostState = "connected,disconnected,notresponding,maintenance"
		}
		$vGPUType = $vGPUType.ToLower() #Make the string passed lowercase
		
		#Figure out GRID cards in hosts
		# Create a list of in use vGPUs, this is populated later
		[System.Collections.ArrayList]$GPUCards = @()

		get-vmhost -state $vGPUHostState -location $vGPULocations | Get-VMHostPciDevice -deviceClass DisplayController -Name "NVIDIA Corporation NVIDIATesla*" | ForEach-Object {
			$CurrGPU = ($_.Name -split " ")[3] #only get the last part of the GPU name ie P4
			$LocOfGPU = -1
			if($null -ne $GPUCards -and @($GPUCards).count -gt 0){
				$LocOfGPU = $GPUCards.GPUname.indexof($CurrGPU)
			}
			if($LocOfGPU -lt 0){
				#write-Host "no match should add an element"
				$obj = [pscustomobject]@{GPUname=$CurrGPU;GPUcnt=1}; $GPUCards.add($obj)|out-null 
			}
			else{ 
				#write-Host "Matches vGPU should incirment"
				$GPUcards[$LocOfGPU].GPUcnt++
			}
		}
				
		#********************************************************
		#Testing objects. Add multiple cards here
		#$obj = [pscustomobject]@{GPUname="P40";GPUcnt=3}; $GPUCards.add($obj)|out-null
		#write-Host "added a physical GPU"
		#Add extra cards to the first (0) GPU
		#$GPUcards[0].GPUcnt = $GPUcards[0].GPUcnt + 3
		#write-Host "Added 3 additional cards to the first GPU"
		#********************************************************

		
		# Figure out which profiles are at play
		# Create a list of in use vGPUs, this is populated later
		[System.Collections.ArrayList]$ActivevGPUs = @()
		#$obj = [pscustomobject]@{vGPUname="grid_p4-8q";vGPUon=0;vGPUoff=0}; $ActivevGPUs.add($obj)|out-null #primeing object Should not do this


		foreach($vm in Get-vm "*"){
			$CurrvGPU = $vm.ExtensionData.config.hardware.device.backing.vgpu
			if($CurrvGPU -match "grid"){
				$LocOfvGPU = -1
				if ($null -ne $ActivevGPUs -and @($ActivevGPUs).count -gt 0){ #make sure not working with a null array
					$LocOfvGPU = $ActivevGPUs.vGPUname.indexof($CurrvGPU)
				}
				if($LocOfvGPU -lt 0){
					if ($vm.powerState -eq "PoweredOff"){ #create with a powered off VM
						$obj = [pscustomobject]@{vGPUname=$CurrvGPU;vGPUon=0;vGPUoff=1}; $ActivevGPUs.add($obj)|out-null 
					}
					else{ #create with assumed powered on VM
						$obj = [pscustomobject]@{vGPUname=$CurrvGPU;vGPUon=1;vGPUoff=0}; $ActivevGPUs.add($obj)|out-null 				
					}
				}
				else{ 
					if ($vm.powerState -eq "PoweredOff"){ #create with a powered off VM
						$ActivevGPUs[$LocOfvGPU].vGPUoff++
					}
					else {
						$ActivevGPUs[$LocOfvGPU].vGPUon++
					}
				}
			}
		}
		
		#********************************************************
		#Testing objects. Add multiple vGPU profiles in the system both on and off
		#$obj = [pscustomobject]@{vGPUname="grid_p4-1q";vGPUon=5;vGPUoff=0}; $ActivevGPUs.add($obj)|out-null
		#$obj = [pscustomobject]@{vGPUname="grid_p40-1q";vGPUon=5;vGPUoff=0}; $ActivevGPUs.add($obj)|out-null
		#write-Host "Added a grid_p4-1q with 5 VMs on"
		#********************************************************
		
		$MyChosenvGPU = $vGPUType #"grid_p4-4q" #what sort of vGPU do we want to see the capacity of
		$MatchingGPU = (($MyChosenvGPU -split "_")[1] -split "-")[0] #only get the half with the GPU name
		$MatchingGPU = $MatchingGPU.ToUpper()
		if($null -ne $GPUCards -and @($GPUCards).count -gt 0){ #make sure not working with a null array

			if($GPUCards.GPUname.indexof($MatchingGPU) -gt -1) { #make sure the card exsists in the system
				$CardsAv = $GPUcards[$GPUCards.GPUname.indexof($MatchingGPU)].GPUcnt #how many cards
			}
			else {$CardsAv=0} #if we cant find the card set it to no cards
		}
		else {$CardsAv=0} #If we dont have any GPUs in the array set to 0
		
		$vGPUactive=0
		if ($null -ne $ActivevGPUs -and @($ActivevGPUs).count -gt 0){ #make sure not working with a null array
			if($ActivevGPUs.vGPUname.indexof($MyChosenvGPU) -gt -1){ #Check to see if the vGPU is active
				$vGPUactive = $ActivevGPUs[$ActivevGPUs.vGPUname.indexof($MyChosenvGPU)].vGPUon #how many current vGPUs are on
			}
			foreach($vGPU in $ActivevGPUs){
				if ($MatchingGPU.ToLower() -eq (($vGPU.vGPUname -split "_")[1] -split "-")[0]){ #only consider valid GPUs skip the rest
					if ($vGPU.vGPUon -gt 0 -and $vGPU.vGPUname -ne $MyChosenvGPU){ #if vGPUs are on and its not the vGPU being considered
						$CardsAv = $CardsAv - [math]::ceiling($vGPU.vGPUon / $vGPUlist[$vGPUlist.vGPUname.indexof($vGPU.vGPUname)].vGPUperBoard) #figure out how many cards this uses
					}
				}
			}
		}
		else {$vGPUactive=0} #No running vGPUs
		
		$vGPUholds = $vGPUlist[$vGPUlist.vGPUname.indexof($MyChosenvGPU)].vGPUperBoard #Find matching vGPU profile, this will be populated unless the code is mucked with
		$RemaingvGPUs = ($CardsAv * $vGPUholds)-$vGPUactive #Total cards avalibe for use times how much they support less whats already on.

		#inteligence problem... This doesn't take into account vGPUs spread across multiple cards 
		return $RemaingvGPUs 
	}
	catch {
		write-Host "Something went wrong"
		return -1 #return an invalid value so user can test
		Break #stop working
	}
}

# Example: vGPUSystemCapacity "grid_p4-2q" "*" "maintenance"

vGPUSystemCapacity "grid_p4-4Q" "*" "Connected"