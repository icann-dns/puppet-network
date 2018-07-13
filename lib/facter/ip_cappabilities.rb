# rubocop:disable Style/DoubleNegation
facts = {
  ipv6_capable: false,
  ipv4_capable: false,
  ipv4_primary_interface: nil,
  ipv6_primary_interface: nil,
}
if File.exist? '/etc/rc.conf.d/network'
  File.open('/etc/rc.conf.d/network', 'r') do |f|
    f.each_line do |line|
      next unless line[0..1] == '#:'
      line.strip!
      tokens = line[2..-1].split('=')
      facts[tokens[0].to_sym] = tokens[1]
    end
  end
end
if File.exist? '/proc/net/route'
  File.open('/proc/net/route', 'r') do |f|
    f.each_line do |line|
      tokens = line.split
      if tokens[1] == '0' * 8
        facts[:ipv4_primary_interface] = tokens[0]
        facts[:ipv4_capable]           = true
      end
    end
  end
end
if !@ipv6_primary_interface && File.exist?('/proc/net/if_inet6')
  File.open('/proc/net/if_inet6', 'r') do |f|
    f.each_line do |line|
      tokens = line.split
      if tokens[3] == '00' && tokens[5] != 'dummy0'
        facts[:ipv6_primary_interface] = tokens[5]
        facts[:ipv6_capable]           = true
      end
    end
  end
end
if File.exist? '/proc/net/ipv6_route'
  File.open('/proc/net/ipv6_route', 'r') do |f|
    f.each_line do |line|
      tokens = line.split
      if tokens[0] == ('0' * 32) && tokens[9] != 'lo'
        facts[:ipv6_primary_interface] = tokens[9]
        facts[:ipv6_capable]           = true
      end
    end
  end
end
if File.exist? '/etc/network/interfaces'
  File.open('/etc/network/interfaces', 'r') do |f|
    f.each_line do |line|
      next unless line[0..1] == '#:'
      line.strip!
      tokens = line[2..-1].split('=')
      facts[tokens[0].to_sym] = tokens[1]
    end
  end
end
Facter.add(:ipv6_capable) do
  setcode do
    !!facts[:ipv6_capable]
  end
end
Facter.add(:ipv4_capable) do
  setcode do
    !!facts[:ipv4_capable]
  end
end
Facter.add(:ipv6_primary_interface) do
  setcode do
    facts[:ipv6_primary_interface]
  end
end
Facter.add(:ipv4_primary_interface) do
  setcode do
    facts[:ipv4_primary_interface]
  end
end
