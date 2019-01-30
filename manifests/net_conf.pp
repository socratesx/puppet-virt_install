################################################################################
# VM Host Network Configuration Class - Setup Bridge Networking                #
#                                                                              #
# A class that provides the required minimum network configuration for         #
# libvirt VMs. This class is optional and it is required only in the case of   #
# fresh OS installs or target that have no Bridge Interfaces.                  #
#                                                                              #
# By default, the class will check if the primary interface's name matches     #
# the user defined Bridge name, defined in data/common.yaml. If this is true   #
# it will not perform any changes. Else, it will setup a new bridge interface  #
# and attach the current primary in the new bridge.                            #
#                                                                              #
# WARNING!!: If the target machine has already a bridge interface working,     #
# you must use the same name in the corresponding variable in common.yaml,     #
# otherwise this class will mess the network configuration of the target.      #
# Apart from this, the vm_provisioner class will fail as it will try to use    #
# the variable's bridge name as well when invoking the virt-install commands.  #
#                                                                              #
# Parameters:                                                                  #
#                                                                              #
# 1. $br_name: A String representing the name of the bridge, e.g. 'br0'.       #
#    If not set when using the class, it will check the common.yaml and will   #
#    use the "virt_install::net_conf::vm_host_br_name" value.                  #
#                                                                              #
# 2. $def_iface: A String representing the interface name that will be added   #
#    to the bridge. It defaults to the value of the facter's primary interface #
#    and can be overriden either directly or in the common.yaml file by        #
#    changing the "virt_install::net_conf::vm_host_br_if" variable.            #
################################################################################

class virt_install::net_conf(
$br_name = lookup(virt_install::net_conf::vm_host_br_name),
$def_iface = lookup(virt_install::net_conf::vm_host_br_if),
){

    if $br_name != $::facts['networking']['primary']{
        if $::facts['os']['family'] == 'Debian' {
            if $::facts['os']['distro']['codename'] == 'bionic' {
                notify{'Setting up  Bridge network with Netplan':}
                if $::facts['networking']['primary'] != $br_name{
                    file {'/etc/cloud/cloud.cfg.d/
                            99-disable-network-config.cfg':
                            ensure  =>'file',
                            content => 'network: {config: disabled}',
                    }

                    file {'/etc/netplan/10-bridge_config.yaml':
                            ensure  => 'file',
                            content => epp('virt_install/bridge_conf.epp'),
                    }

                    file {'/etc/netplan/50-cloud-init.yaml':
                            ensure =>'absent',
                    }
                    exec {'netplan apply':
                            path => [ '/usr/sbin/' , '/bin/' , '/sbin/' ],
                            user => 'root',
                    }
                    notify{'Netplan Restarted...
                    Network ocnfiguration completed':}
                }
            }
            else{
                notify {'Debian Family OS detected,
                creating /etc/network/interfaces file': }
                file { '/etc/network/interfaces':
                    ensure  => file,
                    content => epp('virt_install/net_debian.epp')
                }

              ->exec { "ip addr flush dev ${def_iface} &&
                        systemctl restart networking":
                    path => ['/sbin/', '/usr/sbin/', '/bin/']
                }
                notify {'Networking restarted...
                Network configuration completed.': }
            }
        }

        elsif $::facts['os']['family'] == 'RedHat' {
            notify {'RedHat Family OS detected,
            creating network-scripts files': }
            file { "/etc/sysconfig/network-scripts/ifcfg-${br_name}":
                ensure  => file,
                content => epp('virt_install/br_centos.epp'),

            }
          ->file { "/etc/sysconfig/network-scripts/ifcfg-${def_iface}":
                ensure  => file,
                content => epp('virt_install/iface_centos.epp'),
                notify  => Service['network']
            }

            service { 'network':
                ensure => running,
                enable => true,
            }
            notify {'Network restarted...
            Network configuration completed.': }

        }
        else{

            fail( 'unsupported OS Family detected')

        }

    }
    else{
        notify{' The primary interface is already a bridge.
        Ignoring net config!':}
    }

}


