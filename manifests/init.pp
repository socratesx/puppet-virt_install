# Main init class
class virt_install {
    include virt_install::libvirt_setup
    include virt_install::net_conf
    include virt_install::vm_provisioner
#    include virt_install::undefine

}
