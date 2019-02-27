# vGPUCapacity
Power CLI function that determines the NVIDIA vGPU carrying capacity of a vSphere environment.

For more details on this fuction see my blog post on it's initial publishing: https://www.wondernerd.net/blog/number-of-vgpus-available-in-vsphere/

The bulk of the script file is a function that does all the heavy lifting. The function, vGPUSystemCapacity, takes three arguments. One is required, and the other two are optional. The function returns the number of VMs that can be started with the given profile and if an error were to occur it would return a -1 value.

vPGUSystemCapacity vGPUType as String [vGPULocations as string] [vGPUHostState as string {connected,disconnected,notresponding,maintenance}] 
returns int [-1 on error]

The required argument is a string corresponding to the vGPU profile in the format of “grid_p40-2q” The format is “grid_” followed by the physical GPU type “p40” followed by a dash followed by the vGPU profile “2q.” The vGPU profiles can be found in the NVIDIA vGPU User Guide. This is shown in the following example of a function call requesting the results of a “grid_p40-2q” vGPU profile:

vGPUSystemCapacity "grid_p40-2q"

200

Invalid vGPU profiles do not cause errors, so if you were to pass the function a value of “ColdPizza” for a vGPU card type the function will return a 0 value as the system can not support any “ColdPizza” type vGPUs.

vGPUSystemCapacity "ColdPizza"

0

When the function is called with two arguments, the second argument is a string that corosponds the the VIcontainer[] object (ie cluster) you want to calculate the carrying capacity of. For example if I have a cluster named “production” I would pass that to the function as it’s second argument when using the function. You can also pass a wild card character to capture all valid VIcontainers[]. When no argument is passed for the second argument an “*” is the default value. This is to include everything in the vSphere environment. The example below builds on the previous example capturing only vGPUs in the cluster “production.” You can read more about the VIcontainer type on PowerCLI cmdlet reference.

vGPUSystemCapacity "grid_p40-4q" "Production"

100

The third variation of the function takes into account the host state when calculating the carrying capacity. The third value is a VMHostState[] value that is passed to the function as a string. The valid values for host state are “connected”, “disconnected”, “notresponding”, and “maintenance”. You can read about these in the PowerCLI cmdlet reference document as well. The cool thing about these states is you can string them together as a comma delimited list to capture multiple state types all at once. When no string is passed the function defaults to “connected,disconnected,notresponding,maintenance” and will gather all host states. continuing on from our previous example, if we wanted to see the vGPU carrying capacity for connected hosts and hosts in maintenance mode we would use a function like this.

vGPUSystemCapacity "grid_p40-4q" "Production" "connected,maintenance"

80

I built and tested this function on VMware PowerCLI 11.0.0 build 10380590 and on PowerShell 5.1.14409.1005. It should be backwards compatible several generations back to the point that the vGPU device backing was added in PowerCLI. Though I’m not sure when that was.
