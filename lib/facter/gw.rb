Facter.add('gateway') do
  gw = `ip route show`[%r{default.*}][%r{\d+\.\d+\.\d+\.\d}]
  setcode do
    gw
  end
end
