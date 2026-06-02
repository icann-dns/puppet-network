# @summary
#   Used to configure networking for linux hosts
# @param packages An array of packages to ensure are installed.
class network::linux (
  Array[String] $packages = ['vlan', 'ifupdown', 'resolvconf'],
) {
  include network

  $interfaces  = $network::interfaces
  $dummy4      = $network::dummy4
  $dummy6      = $network::dummy6
  $sysctl      = $network::sysctl
  $prefer_ipv4 = $network::prefer_ipv4
  assert_private()
  create_resources(sysctl, $sysctl)
  ensure_packages($packages)

  if $facts['systemd'] {
    service { ['systemd-networkd', 'systemd-networkd.socket', 'networkd-dispatcher', 'systemd-networkd-wait-online']:
      enable  => mask,
    }
  }

  file {
    '/etc/hostname':
      content => $facts['networking']['fqdn'];
    '/etc/sysctl.d/net.ipv6.conf.interface.accept_ra.conf':
      ensure  => file,
      content => template(
        'network/etc/sysctl.d/net.ipv6.conf.interface.accept_ra.conf.erb'
      );
    '/etc/gai.conf':
      ensure  => file,
      content => template('network/etc/gai.conf.erb');
    '/etc/init.d/networking':
      ensure => file,
      mode   => '0755',
      source => 'puppet:///modules/network/etc/init.d/networking';
    '/usr/local/bin/network_status.sh':
      ensure  => file,
      mode    => '0755',
      content => template('network/usr/local/bin/network_status.sh.erb');
    '/etc/network':
      ensure => directory;
    '/etc/network/interfaces':
      ensure  => file,
      content => template('network/etc/network/interfaces.erb');
  }
  exec { 'network_ifup_all':
    command     => '/sbin/ifup -a --ignore-errors',
    subscribe   => File['/etc/network/interfaces'],
    refreshonly => true,
    require     => Package[$packages],
  }

  service { 'networking':
    ensure    => running,
    enable    => true,
    provider  => base,
    status    => '/usr/local/bin/network_status.sh',
    stop      => '/etc/init.d/networking stop',
    start     => '/etc/init.d/networking restart',
    restart   => '/etc/init.d/networking restart',
    subscribe => File['/etc/network/interfaces'],
    require   => [
      File['/usr/local/bin/network_status.sh'],
      File['/etc/init.d/networking'],
      File['/etc/network/interfaces'],
      Package[$packages],
    ],
  }
}
