############################################################################
# vGPU System Capcity for PowerCLI Version 1.5
# Copyright (C) 2019-2020 Tony Foster
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

#UPDATE THE STRING BELOW FOR YOUR FILE LOCATION
#Import vGPU supported profiles function
. 'C:\Users\UserName\Desktop\vGPU_Profiles_In_Environment.ps1'

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

	#try{
		# Create a list of GPU Specs
		[System.Collections.ArrayList]$vGPUlist = @()
			#Name, vGPU per GPU, vGPU per Board, physical GPUs per board
			#$obj = [pscustomobject]@{vGPUname="default";vGPUperGPU=0;vGPUperBoard=0; pGPUperBoard=0}; $vGPUlist.add($obj)|out-null #catch any non-defined cards and force them out as zeros
			#echo "trying to get vGPUs"
		$vGPUlist = vGPUsInASystem $vGPULocations #$vGPUHostState #get the list of vGPU Profiles
		#echo $obj
		#help from www.idmworks.com/what-is-the-most-efficient-way-to-create-a-collection-of-objects-in-powershell/
		
		$vGPUType = $vGPUType.ToLower() #Make the string passed lowercase
		
		# Take care of function paramaters
			if("" -eq $vGPULocations){ #if nothing is passed set the value to all clusters
				$vGPULocations = "*"
			} 
			if("" -eq $vGPUHostState){ #if nothing is passed set the value to all states
				$vGPUHostState = "connected,disconnected,notresponding,maintenance"
			}
		
		#Added 8-3-21
		$ProfileInSystem = 0
		foreach ($ProfileToCheck in $vGPUlist.vGPUname){ #check to make sure the requested card is in the system.
			if($vGPUType -eq $ProfileToCheck){
				$ProfileInSystem = 1
				#echo "found card******************************"
				#echo "Looking For: " $vGPUType
				#echo "On Profile: " $ProfileToCheck
				break #Found it no need to keep going
			}
			#else{
			#	echo "No card found"
			#	echo "Looking For: " $vGPUType
			#	echo "On profile: " $ProfileToCheck
			#}
		}
		
		#short circut operations if the profile is not in the system (why do the work if its bound to fail)
		if ($ProfileInSystem -eq 1){
			
			#End add 8-3-21
						
			#Figure out GRID cards in hosts
			#$vmhost.ExtensionData.Config.SharedPassthruGpuTypes
			
			# Create a list of in use vGPUs, this is populated later
			[System.Collections.ArrayList]$GPUCards = @()
			$StartOfProfileColection = Get-Date -Format "HH:mm:ss.ffff"
			echo "Start of GPU collection: " $StartOfProfileColection					
			Try {
				get-vmhost -state $vGPUHostState -location $vGPULocations | Get-VMHostPciDevice -deviceClass DisplayController -Name "NVIDIA Corporation NVIDIATesla*" | ForEach-Object {
					$InForLoop = Get-Date -Format "HH:mm:ss.ffff"
					echo "Time into for loop: " $InForLoop	
					$CurrGPU = ($_.Name -split " ")[3] #only get the last part of the GPU name ie P4
					#write-Host "GPU type: " $CurrGPU 
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
					$PlaceInArray = Get-Date -Format "HH:mm:ss.ffff"
					echo "End of array Entry: " $PlaceInArray	
				}
			}
			Catch {
				write-Host "Error processing GPU cards in hosts"
				return -2 #return an invalid value so user can test
				Break #stop working
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
			
			try{
				$VMs = get-cluster $vGPULocations | Get-vm  #Change from Fabian Lenz (@lenzker) Feb 7, 2020
				foreach($vm in Get-vm "*"){
					$CurrvGPU = $vm.ExtensionData.config.hardware.device.backing.vgpu
					if($CurrvGPU -match "grid"){
						#write-Host "vGPU array: " $ActivevGPUs
						$LocOfvGPU = -1
						if ($null -ne $ActivevGPUs -and @($ActivevGPUs).count -gt 0){ #make sure not working with a null array
							$LocOfvGPU = $ActivevGPUs.vGPUname.indexof($CurrvGPU)
						}
						#write-Host "loc of GPU: "$LocOfvGPU
						if($LocOfvGPU -lt 0){
							if ($vm.powerState -eq "PoweredOff" -or $vm.powerState -eq "Suspended"){ #create with a powered off VM #Added suspended in 1.4
								$obj = [pscustomobject]@{vGPUname=$CurrvGPU;vGPUon=0;vGPUoff=1}; $ActivevGPUs.add($obj)|out-null 
								#write-Host "1vGPU off or suspended: " $vm
								#write-Host "Details: " $ActivevGPUs[$LocOfvGPU]
							}
							else{ #create with assumed powered on VM
								$obj = [pscustomobject]@{vGPUname=$CurrvGPU;vGPUon=1;vGPUoff=0}; $ActivevGPUs.add($obj)|out-null 	
								#write-Host "1vGPU on: " $vm
							}
						}
						else{ 
							if ($vm.powerState -eq "PoweredOff" -or $vm.powerState -eq "Suspended"){ #create with a powered off VM #Added suspended in 1.4
								#write-Host "2vGPU off or suspended: " $vm
								#write-Host "Details: " $ActivevGPUs[$LocOfvGPU]
								$ActivevGPUs[$LocOfvGPU].vGPUoff++
								#write-Host "2vGPU off or suspended: " $vm
							}
							else {
								$ActivevGPUs[$LocOfvGPU].vGPUon++
								#write-Host "2vGPU on: " $vm
							}
						}
					}
				}
			}
			Catch {
				write-Host "Error counting number of active vGPU based VMs"
				return -3 #return an invalid value so user can test
				Break #stop working
			}
			
			#********************************************************
			#Testing objects. Add multiple vGPU profiles in the system both on and off
			#$obj = [pscustomobject]@{vGPUname="grid_p4-1q";vGPUon=5;vGPUoff=0}; $ActivevGPUs.add($obj)|out-null
			#$obj = [pscustomobject]@{vGPUname="grid_p40-1q";vGPUon=5;vGPUoff=0}; $ActivevGPUs.add($obj)|out-null
			#write-Host "Added a grid_p4-1q with 5 VMs on"
			#********************************************************
			
			Try {
				$MyChosenvGPU = $vGPUType #"grid_p4-4q" #what sort of vGPU do we want to see the capacity of
				$MatchingGPU = (($MyChosenvGPU -split "_")[1] -split "-")[0] #only get the half with the GPU name
				$MatchingGPU = $MatchingGPU.ToUpper()
				#write-Host "found the card: " $MatchingGPU
				if($null -ne $GPUCards -and @($GPUCards).count -gt 0){ #make sure not working with a null array

					if($GPUCards.GPUname.indexof($MatchingGPU) -gt -1) { #make sure the card exsists in the system
						$CardsAv = $GPUcards[$GPUCards.GPUname.indexof($MatchingGPU)].GPUcnt #how many cards
						
					}
					else {$CardsAv=0} #if we cant find the card set it to no cards
				}
				else {$CardsAv=0} #If we dont have any GPUs in the array set to 0
			}
			Catch {
				write-Host "Error processing GPU slot matching"
				return -4 #return an invalid value allowing user can test for it
				Break #stop working
			}
			
			Try {
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
			}
			Catch {
				write-Host "Error processing free slots"
				return -5 #return an invalid value so user can test
				Break #stop working
			}

			$vGPUholds = $vGPUlist[$vGPUlist.vGPUname.indexof($MyChosenvGPU)].vGPUperBoard #Find matching vGPU profile, this will be populated unless the code is mucked with
			#write-Host "Cards avalible: " $CardsAv
			#write-Host "vGPU holds: " $vGPUholds
			#write-Host "vGPUs Active: " $vGPUactive
			$RemaingvGPUs = ($CardsAv * $vGPUholds)-$vGPUactive #Total cards avalibe for use times how much they support less whats already on.
			
			#added in version 1.4
			$ActivevGPUs = $null #cleanup afterwards 
			$vGPUlist = $null
			$GPUCards = $null
			#end add
			
			
			#inteligence problem... This doesn't take into account vGPUs spread across multiple cards 
			echo "Profile capacity: "
			return $RemaingvGPUs 
		#Added 8-3-21
		}		
		else {
			#If the profile is not found report it as an error
			write-Host "Specified vGPU profile not found"
			return -6 #Return an invalid value which the user can test for
		}
		#end add
	#}
	#catch {
	#	write-Host "Something went wrong"
	#	return -1 #return an invalid value so user can test
	#	Break #stop working
	#}
}

# Example: vGPUSystemCapacity "grid_p4-2q" "*" "maintenance"

vGPUSystemCapacity "grid_p4-1q" "*" "connected"
