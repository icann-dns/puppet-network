# @summary
#   Used to configure networking for linux hosts
class network::linux {
  include ::network

  $interfaces  = $::network::interfaces
  $dummy4      = $::network::dummy4
  $dummy6      = $::network::dummy6
  $sysctl      = $::network::sysctl
  $prefer_ipv4 = $::network::prefer_ipv4
  assert_private()
  create_resources(sysctl, $sysctl)
  ensure_packages(['vlan'])
  file {
    '/etc/hostname':
      content => $::fqdn;
    '/etc/sysctl.d/net.ipv6.conf.interface.accept_ra.conf':
      ensure  => present,
      content => template(
        'network/etc/sysctl.d/net.ipv6.conf.interface.accept_ra.conf.erb'
      );
    '/etc/gai.conf':
      ensure  => present,
      content => template('network/etc/gai.conf.erb');
    '/etc/init.d/networking':
      ensure => present,
      mode   => '0755',
      source => 'puppet:///modules/network/etc/init.d/networking';
    '/usr/local/bin/network_status.sh':
      ensure  => present,
      mode    => '0755',
      content => template('network/usr/local/bin/network_status.sh.erb');
    '/etc/network':
      ensure => directory;
    '/etc/network/interfaces':
      ensure  => present,
      content => template('network/etc/network/interfaces.erb'),
      require => [
        File['/usr/local/bin/network_status.sh'],
        File['/etc/init.d/networking'],
      ];
  }
  exec {'network_ifup_all':
    command     => '/sbin/ifup -a',
    subscribe   => File['/etc/network/interfaces'],
    refreshonly => true,
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
    ],
  }
}
