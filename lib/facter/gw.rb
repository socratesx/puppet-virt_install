Facter.add('gateway') do
  gw = `ip route show`[/default.*/][/\d+\.\d+\.\d+\.\d+/]
  setcode do
      gw
  end
end
