This folder should contain any iso boot files or existing disk files that have passed as arguments to cdrom or disk options in the VM yaml definition files in data/vms/ folder.

For example:
If you specify 
```
cdrom: 'boot_image.iso'
```
or 
```
disk:
  - /some_path/disk_file 
```

Make sure that the boot_image.iso or disk_file are contained in this folder. Perhaps, soft links could work but in my case they weren't. 
