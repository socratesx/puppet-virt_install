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
- init: Default class, if the user use include-like statements the class by default will call all subclasses, except undefine.
  - Parameters: None
- libvirt_setup: This class is responsible for installing the libvirt hypervisor to the host and enabling its daemon.
  - Parameters:  
    - $iso_path:   A string representing the folder of the boot images (isos) a VM may need to boot during the runtime. By default, it       gets the value of libvirt_boot_image_folder variable found in the data/common.yaml
    - $disk_path: A String representing the folder that will contain the VM disk image files. By default, it gets the defined value of libvirt_vm_disk_folder variable in data/common.yaml
- net_conf: The network cofiguration class that will create a bridge interface and attach the current primary interface to the bridge.
  - Parameters:
    - $br_name: A String representing the name of the bridge, e.g. 'br0'. If not set when using the class, it will check the common.yaml and will use the "virt_install::net_conf::vm_host_br_name" value.
    -  $def_iface: A String representing the interface name that will be added to the bridge. It defaults to the value of the facter's primary interface and can be overriden either directly or in the common.yaml file by changing the "virt_install::net_conf::vm_host_br_if" variable. 
- vm_provisioner: The class the provisions new VMs either from inline declared Hash or from the yaml files, located in data/vms/. 
  - Parameters:
    -  $vms: A dictionary that contains the vm definitions as key-value pairs. The key is a reference value of the VM and the value is another dict  containing the virt-intall options as keys and the corresponding arguments as values. The Hash has the following form: 
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
  -  $boot_imgs: A String that represents the folder were the iso boot images will reside on the target machine so they can be used during VM installation. By default, it will use the parameter value on data/common.yaml file.
- undefine: Taking the same arguments as the previous class but reversing the action. This class destroys and undefines existing VMs on target.
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
<b> cdrom </b>
This option defines a bootable image file that the VM will use to boot during boot-time. 
It takes the following argument types:
  - URLS: It downloads the image file from the network, it support ftp, http & https. If the file is compressed then it will decompress the image file and move it to the boot folder specified by the libvirt_boot_image_folder variable found in data/common.yaml
  - Absolute Paths: If an absolute path is passed, then the module will look for the image filename in files/ directory and will copy it to the path that is passed.
  - Filename: This indicated an isofile that is already contained in files/ directory. In this case it will copy the file on the the default boot directory provided by libvirt_boot_image_folder variable found in data/common.yaml.
  
  (to be continued...)


