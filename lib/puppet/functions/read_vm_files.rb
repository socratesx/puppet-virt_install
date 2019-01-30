Puppet::Functions.create_function(:read_vm_files) do
  dispatch :read do
    param 'String', :vm_files_dir
  end

  def read(vm_files_dir)
    vms_dict = {}
    paths = Dir[vm_files_dir + '*']
    paths.each do |vm_file|
      vm = YAML.safe_load(File.open(vm_file))
      key = File.basename(vm_file, 'yaml')
      vms_dict[key] = vm
    end
    vms_dict
  end
end
