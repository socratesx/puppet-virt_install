################################################################################
#   Libvirt Setup:                                                             #
#   This class that installs the necessary packages, ensures that the defined  #
#   directories exist, and add the 'root' user in the libvirt group for a      #
#   minimal working Libvirt Environment.                                       #
#                                                                              #
#   Description:                                                               #
#   This class is optional, and it prepares a host to run as a kvm host with   #
#   Libvirt. The resulting action of this class is a host that will run the    #
#   Libvirtd service, ready to provision new VMs.                              #
#                                                                              #
#   Parameters:                                                                #
#   $iso_path:  A string representing the folder of the boot images (isos)     #
#               a VM may need to boot during the runtime. By default, it       #
#               gets the value of libvirt_boot_image_folder variable found in  #
#               data/common.yaml                                               #
#   $disk_path: A String representing the folder that will contain the VM disk #
#               image files. By default, it gets the defined value of          #
#               libvirt_vm_disk_folder variable in data/common.yaml            #
################################################################################

class virt_install::libvirt_setup(
    $iso_path=lookup(virt_install::libvirt_setup::libvirt_boot_image_folder),
    $disk_path=lookup(virt_install::libvirt_setup::libvirt_vm_disk_folder) )
{

        $packages=lookup(virt_install::libvirt_setup::packages)
        if $::facts['os']['name'] == 'Ubuntu' {
            notify{'Ubuntu OS detected, enabling universe repo':}
            exec{'add-apt-repository universe':
                path=> ['/usr/bin/', '/bin/']

            }
        }

        notify{'Begining installation of necessary packages':}
        package{ $packages:
            ensure => present,
        }

      ->group{'libvirt':
            ensure  => present,
            members => [ 'root' ]
        }

      ->file{[$iso_path, $disk_path]:
            ensure => directory,
            owner  => 'root',
            group  => 'libvirt',
            notify => Service['libvirtd']
        }
        notify{'Starting and enabling service libvirtd':}

        service{'libvirtd':
            ensure => running,
            enable => true,
        }
        notify{'Libvirt installation completed.':}

}
