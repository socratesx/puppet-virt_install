###############################################################################
# VM Provisioner:                                                             #
# This class provision new VMs with the virt-install utility.                 #
#                                                                             #
# Parameters:                                                                 # 
#                                                                             #
# 1. $vms: A dictionary that contains the vm definitions as key-value pairs.  #
#    The key is a reference value of the VM and the value is another dict     #
#    containing the virt-intall options as keys and the corresponding         #
#    arguments as values. The Hash has the follwoing form                     #
#                                                                             #
#    {'VM1': {'opt1': 'arg1', 'opt2':'arg2',...},                             #
#     'VM2': {'opt1': 'arg1', 'opt2': 'arg2', ...},                           #
#      :                                                                      #
#     'VMn': {'opt1': 'arg1', 'opt2': 'arg2', ...}                            #
#    }                                                                        #
#                                                                             #
#    VMn: unique key names for each VM                                        #
#    optn: virt-install option name                                           #
#    argn: virt-install option argument                                       #
#                                                                             #
#    By default, the class uses the module's custom function to return the    #
#    parameter after parsing all the yaml files in data/vms folder.           #
#                                                                             #
# 2. $boot_imgs: A String that represents the folder were the iso boot images #
#    will reside on the target machine so they can be used during VM          #
#    installation.                                                            #
#                                                                             #
#    By default, it will use the parameter value on data/common.yaml file.    #
#                                                                             #
############################################################################### 

class virt_install::vm_provisioner (
    $vms = read_vm_files(lookup(virt_install::vm_provisioner::vm_data_dir)),
    $boot_imgs = lookup(virt_install::libvirt_setup::libvirt_boot_image_folder))
{
    $vms.keys.each | $key | {
        $vm_name =  $vms[$key]['name']
        if $vms[$key]['cdrom']{
            $cdrom = $vms[$key]['cdrom']
        }
        if $vms[$key]['disk']{
            $vm_disks = $vms[$key]['disk']
        }
        if $vms[$key]['filesystem']{
            $filesystems = $vms[$key]['filesystem']
        }
        
        if $cdrom {
            $cdrom_arg=basename($cdrom)
            notify{ $vm_name:
                message => 'cdrom argument is defined, checking its type...'
            }
            $ext=match($cdrom_arg, '\..{1,3}\z')
            if $ext[0] in ['.gz', '.bz2', '.zip'] {
                $is_compressed = true
                $iso_filename = basename($cdrom,$ext[0])
                notify{ $cdrom:
                    message => 'cdrom argument is compressed'
                }

            }
            else{
                $is_compressed = false
                $iso_filename = $cdrom_arg
            }
            if is_absolute_path($cdrom){
                notify{ $cdrom:
                    message => "Copying iso file to ${cdrom}"
                }
                
                exec {"check_file_${cdrom_arg}":
                    command => '/bin/true',
                    onlyif  => "/usr/bin/test ! -e  ${cdrom}",
                }
                file{ $cdrom:
                    ensure  => present,
                    group   => 'libvirt',
                    owner   => 'root',
                    source  => "puppet:///modules/virt_install/${cdrom_arg}",
                    require => Exec["check_file_${cdrom_arg}"],
                    links   => 'follow'
                }
            }
            else {

                exec {"check_file_${cdrom_arg}":
                    command => '/bin/true',
                    onlyif  => "/usr/bin/test 
                        ! -e ${$boot_imgs}${cdrom_arg}",
                }
                file{ "${$boot_imgs}${cdrom_arg}":
                    ensure  => present,
                    group   => 'libvirt',
                    owner   => 'root',
                    source  => "puppet:///modules/virt_install/${cdrom_arg}",
                    require => Exec["check_file_${cdrom_arg}"],
                    links   => 'follow'
                }

            }
            
            if match($cdrom, '^(ftp|http)') {
                notify { $cdrom:
                    message => 'URL detected, downloading...'
                }
                $url = true
            }
            else{
                $url = false
            }
            if $cdrom_arg == $cdrom {
                $source = "${boot_imgs}${cdrom}"
                $filename = true
            }
            else {
                $source = $cdrom
                $filename = false
            }
            
            if ! Archive[ $cdrom ]{
                archive { $cdrom:
                    source       => $source,
                    path         => "${boot_imgs}${cdrom_arg}",
                    user         => 'root',
                    group        => 'libvirt',
                    extract_path => $boot_imgs,
                    provider     => 'wget',
                    extract      => $is_compressed,
                    cleanup      => $is_compressed,
                    creates      => "${boot_imgs}${iso_filename}",
                }
                notify { $cdrom_arg:
                    message => "The iso file is in ${boot_imgs}${cdrom_arg}"
                }
            }

        }
        if $vm_disks and $vm_disks != 'none' {
            $vm_disks.each | $disk | {
                $disk_path =  match($disk, '\A[.]*[^,]*')[0]
                $disk_dir =  match ($disk_path, '\A.*\/')[0]
                $disk_name = basename($disk_path)
                exec { "Create ${disk_name} Directory":
                    command => "mkdir -p ${disk_dir}",
                    user    => 'root',
                    group   => 'libvirt',
                    creates => $disk_dir,
                    path    => ['/bin/'],
                }

                if !('size=' in $disk){
                    if !('/dev/' in $disk){
                        
                        notify{ $disk_name:
                            message => "Disk File Exists, copying to ${disk_path}"
                        }
                        
                        file { $disk_path:
                            ensure => file,
                            source => "puppet:///modules/virt_install/${$disk_name}",
                        }
                    }
                }
                else {
                    notify{ $disk_path:
                        message => 'A new disk file will be created'
                    }
                }
            }
        }
        
        if $filesystems {
            
            if $filesystems =~ Tuple {
                $filesystems.each | $filesys | {
                    $host_folder = match($filesys,'^[\w\/]*')[0]
                    exec{"$::{host_folder}_for_$::{key}":
                        command => '/bin/true',
                        onlyif  => "/usr/bin/test ! -e ${$host_folder}"
                        
                    }
                    file{ $host_folder:
                        ensure  => directory,
                        owner   => 'root',
                        group   => 'libvirt',
                        require => Exec["$::{host_folder}_for_$::{key}"]
                    }
                }
            }
            else {
                $host_folder = match($filesystems,'^[\w\/]*')[0]
                exec{"${host_folder}_for_${key}":
                    command => '/bin/true',
                    onlyif  => "/usr/bin/test ! -e ${$host_folder}"

                }
                if ! Exec["${host_folder}_for_${key}"] {
                    file{ $host_folder:
                        ensure  => directory,
                        owner   => 'root',
                        group   => 'libvirt',
                        require => Exec["${host_folder}_for_${key}"]
                    }
                }

            }
        }
        
            
        if $url {
            $new = regsubst( join_keys_to_values($vms[$key], ' ').join(' --'),
                '(http|ftp)\S*',
                "${boot_imgs}${iso_filename}")
        }
        elsif $filename {
            $new = regsubst( join_keys_to_values($vms[$key], ' ').join(' --'),
                $iso_filename,
                "${boot_imgs}${iso_filename}")
        }
        else {
            $new =  join_keys_to_values($vms[$key], ' ').join(' --')
        }
        
        notify {$new:}
        exec{ "virt-install --${new}":
            user   => 'root',
            group  => 'libvirt',
            path   => ['/usr/bin/'],
            onlyif => "/bin/bash -c '! virsh domstate ${$vms[$key]['name']}' "
        }
    }
}
