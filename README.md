# Puppet Module: virt_install
A simple module to manage Libvirt Installation, minimal network configuration and VM provisioning

<h2> Description </h2>

This puppet module can execute the following tasks:
- Install libvirt packages per OS and configure libvirtd service to run on startup
- Create a minimal network configuration for libvirt. It creates a Bridge interface and attaches the primary interface to it.
- Define new VMs declared either from yaml files, each file one VM declaration, or from inline Hash variable.
- Undefine existing VMs.

<h3>Classes</h3>

The following classes are included:

- <b>init</b>: Default class, if the user use include-like statements the class by default will call all subclasses, except undefine.
  - Parameters: None
  
- <b>libvirt_setup</b>: This class is responsible for installing the libvirt hypervisor to the host and enabling its daemon.
  - Parameters:  
    - $iso_path:   A string representing the folder of the boot images (isos) a VM may need to boot during the runtime. By default, it       gets the value of libvirt_boot_image_folder variable found in the data/common.yaml
    - $disk_path: A String representing the folder that will contain the VM disk image files. By default, it gets the defined value of libvirt_vm_disk_folder variable in data/common.yaml

- <b>net_conf</b>: The network cofiguration class that will create a bridge interface and attach the current primary interface to the bridge.
  - Parameters:
    - $br_name: A String representing the name of the bridge, e.g. 'br0'. If not set when using the class, it will check the common.yaml and will use the "virt_install::net_conf::vm_host_br_name" value.
    -  $def_iface: A String representing the interface name that will be added to the bridge. It defaults to the value of the facter's primary interface and can be overriden either directly or in the common.yaml file by changing the "virt_install::net_conf::vm_host_br_if" variable. 

- <b>vm_provisioner</b>: The class the provisions new VMs either from inline declared Hash or from the yaml files, located in data/vms/. 
  - Parameters:
    - $vms: A dictionary that contains the vm definitions as key-value pairs. The key is a reference value of the VM and the value is another dict  containing the virt-intall options as keys and the corresponding arguments as values. The Hash has the following form: 
      ```
      {'VM1': {'opt1': 'arg1', 'opt2': 'arg2', ...},                             
       'VM2': {'opt1': 'arg1', 'opt2': 'arg2', ...},                           
         :                                                                      
       'VMn': {'optn': 'argn', 'optn': 'argn', ...}                            
      }  
      ```
      VMn: unique key names for each VM                                        
      optn: virt-install option name                                           
      argn: virt-install option argument                                       
      By default, the class uses the module's custom function read_vm_files() to return the parameter after parsing all the yaml files in data/vms folder.
	  
    - $boot_imgs: A String that represents the folder were the iso boot images will reside on the target machine so they can be used during VM installation. By default, it will use the parameter value on data/common.yaml file.

- <b>undefine</b>: Taking the same arguments as the previous class but reversing the action. This class destroys and undefines existing VMs on target.
   -  $vms: A dictionary that contains the VM names in the form:
      ```
      {'VM1': {'name': 'VM1_name'},                                             
       'VM2': {'name': 'VM2_name'},                                             
        :                                                                       
       'VMn': {'name': 'VMn_name'}                                              
      }                                                                         
     ``` 
     VMn: A unique key name for each VM                                        
     name: The keyword 'name'.                                                 
     VM_name: The corresponding name of the VM.                                

     If this parameter is not passed then it defaults to the VMs defined in    
     the data/vms/*.yaml files


<h2> Usage </h2>

The intended usage of the module is by defining yaml files and changing the default parameters on data/common.yaml files. The first thing, after reading the readme file, a user must do is to see the files in data/ folder. From there he/she can define new VMs and change the default parameters to suit their needs in their environment. 

The classes can be used autonomously by declaring them using the resource-like declaration style:

```
class { 'virt_install::undefine':}
```

The above example will look for the default values in data/vms folder and will undefine all the VMs included there. You can override the default like the following:

```
class { 'virt_install::undefine':
          vms => { vm1 => {'name' => 'VM_NAME'} }        
      }
```

This time only the VM_NAME will be undefined from the target host.

The module intended usage is to mass provision libvirt domains by declaring each resource in the data/vms/ folder. This folder may contain any number of YAML files that each one contains key:value pairs of the virt-install utility where key = option and value = arguments. You can include any supported option of the virt-install utility. Options that take no arguments, like the --noautoconsole can be specified with an empty string as a value. 

<h3> The Special Arguments: cdrom, disk, & network </h3>

These options have extended functionality over the original virt-install utility:

<h4> cdrom </h4>

This option defines a bootable image file that the VM will use to boot during boot-time. 
It takes the following argument types:

  - <b>URLS</b>: It downloads the image file from the network, it support ftp, http & https. If the file is compressed then it will decompress the image file and move it to the boot folder specified by the libvirt_boot_image_folder variable found in data/common.yaml

  - <b>Absolute Paths</b>: If an absolute path is passed, then the module will look for the image filename in files/ directory and will copy it to the path that is passed. It is required that the user have added manually the file in the files/ folder.Normally, this type should handle also symlinks but in my case this wasn't possible.

  - <b>Filenames</b>: If just a filename is passed then the module checks for that file in files/ directory and then it copies it to the default boot directory provided by libvirt_boot_image_folder variable found in data/common.yaml. It is required that the user have added manually the file in the files/ folder. Normally, this type should handle also symlinks but in my case this wasn't possible.

<h4> disk </h4>

This is a list option in VM definition file. Each item represent a disk argument, something like the following:

```
disk:
  - '/disk_path/a_new_disk.qcow2,bus=virtio'
  - '/dev/sdb,bus=virtio'
  - 'disk_path/an_existing_disk.qcow2,bus=virtio'
```

During runtime, the above will be converted to:

```
{...} --disk /vm-images/pfsense/pfsense.qcow2,bus=virtio --disk /dev/sdb,bus=virtio {...}
```

If the 'size=' disk option is specified, like the first item above, the virt-install will create a new disk file. On the contrary, if the 'size=' is omitted then the virt-install assumes that the disk file is an existing file in the specified path. In this case the user must have included the disk file in the files/ folder. During runtime the module will check for the 'an_existing_disk.qcow2' file and will copy it to the specified folder, so the virt-install will detected it when invoked to the target.

<h4> network </h4>

Similarly with the disk option, the network is also defined as a list. And this is becasue a VM can have multiple NICs defined like the following example:

```
network:
  - 'bridge=br0,model=virtio'
  - 'bridge=br0,model=virtio'
```

During runtime, the above will be converted to

```
{...} --network bridge=br0,model=virtio --network bridge=br0,model=virtio {...}
```

<h2> Examples </h2>

For this example I include my use case scenario, consisting one Storage VM and one Firewall, using the free open source Xigmanas and pfSense respectively. 
Assuming that there are two VM definition files in data/vms like the following:

```
#data/vms/pfsense.yaml
---
name: 'pfSense'
vcpus: '1,maxvcpus=2'
cpu: host
memory: '512,maxmemory=768'
os-variant: freebsd10
boot: hd,cdrom,menu=on
disk:
  - "/vm-images/pfsense/pfsense.qcow2,bus=virtio"
network:
  - 'bridge=br0,model=virtio'
  - 'bridge=br0,model=virtio'
graphics: vnc,listen=0.0.0.0,port=-1
virt-type: kvm
noautoconsole: ''
hvm: ''
autostart: ''

#data/vms/xigmanas.yaml
---
name: Xigmanas
vcpus: '2,maxvcpus=4'
cpu: host
memory: '512,maxmemory=768'
os-variant: freebsd10
boot: hd,cdrom,menu=on
cdrom: 'https://downloads.sourceforge.net/project/xigmanas/XigmaNAS-11.2.0.4/11.2.0.4.6315/XigmaNAS-x64-LiveCD-11.2.0.4.6315.iso'
disk:
  - '/vm-images/xigmanas/xigmanas.qcow2,size=10,bus=virtio'
  - '/dev/sdb,bus=virtio'
  - '/dev/sdc,bus=virtio'
network:
  - bridge=br0,model=virtio
graphics: vnc,listen=0.0.0.0,port=-1
virt-type: kvm
noautoconsole: ''
hvm: ''
autostart: ''

```

We can install these vms to an already working host by just using the following code in a manifest:

```
class { 'virt_install::vm_provisioner':}
```

We can also undefine them

```
 class { 'virt_install::undefine':}
```

If we have an empty host just after OS installation :

```
include virt_install
```

or a more complicated manifest:


```
node default {
    include virt_install
}

node ubuntu18.soc.home {
    class { 'virt_install::libvirt_setup':}
    class { 'virt_install::net_conf':}
    $new_container= {
        connect    => 'lxc:///',
        name       => 'container',
        memory     => '128',
        filesystem => ['/bin/,/bin/', '/home/socratesx,/mnt/home', '/root,/mnt/root', '/root/test_lxc,/test'],
        init       => '/bin/sh'
    }
    $vms = {
        'container1' => $new_container
    }
    class { 'virt_install::vm_provisioner':
        vms => $vms
    }
}

node debian.soc.home {
    $new_demo = {
        name    => 'demo',
        memory  => '512',
        disk    => ['/VMs/demodisk.qcow2,size=1'],
        import  => ''
    }
    $vms = {
        'vm1' => $new_demo
    }
    class { 'virt_install::vm_provisioner':
        vms => $vms
    }
}

```

The above manifest, will configure ubuntu18 as a new libvirt kvm-host, will enable a bridge interface and define a new lxc container 
as described in $container1 hash. Notice that the new container definition will override the default $vms parameter, so the yaml files in data/vms will not have any effect to this host.

The debian node is already a libvirt host running VMs, but it will just provision a new demo VM as described in the $new_demo hash. 

Every other node will run the default module's init.pp which calls all classes and installs the VMs in the data/VMs folder.
