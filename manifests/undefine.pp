###############################################################################
#   Undefine:                                                                 #
#   A simple class for destroying & undefining Libvirt domains.               #
#                                                                             #
#   Description:                                                              #
#   The class checks first if the VM exist and then if they are runing. Then  #
#   it destroys the VMs and then it undefines them.                           #
#                                                                             #
#   Parameters:                                                               #
#   $vms: A dictionary that contains the VM names in the form                 #
#   {'VM1': {'name': 'VM1_name'},                                             # 
#    'VM2': {'name': 'VM2_name'},                                             #
#     :                                                                       #
#    'VMn': {'name': 'VMn_name}                                               #
#   }                                                                         #
#                                                                             #
#   VMn: A unique key name for each VM                                        #
#   name: The keyword 'name'.                                                 #
#   VM_name: The corresponding name of the VM.                                #
#                                                                             #
#   If this parameter is not passed then it defaults to the VMs defined in    #
#   the data/vms/*.yaml files                                                 #
#                                                                             #
###############################################################################
  
class virt_install::undefine (
Hash $vms= read_vm_files(lookup(virt_install::vm_provisioner::vm_data_dir)) )

{
    $vms.keys.each | $key | {
        $vm_name=$vms[$key]['name']

        exec{"virsh destroy ${vm_name}":
            user   => 'root',
            group  => 'libvirt',
            path   => ['/usr/bin/','/bin/'],
            onlyif => [ "/bin/bash -c ' virsh domstate ${vms[$key]['name']}' ",
                        "/bin/bash -c 'virsh domstate ${vms[$key]['name']} |
                        grep 'running'' "]
        } ->
        
        exec{"virsh undefine ${vm_name}":
            user   => 'root',
            group  => 'libvirt',
            path   => ['/usr/bin/','/bin/'],
            onlyif => [ "/bin/bash -c ' virsh domstate ${vms[$key]['name']}' ",
                        "/bin/bash -c 'virsh domstate ${vms[$key]['name']} |
                        grep 'shut off'' "]
        }


    }

}
