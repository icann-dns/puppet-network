# == Class: network
#
class network::freebsd {
  include ::network

  $interfaces  = $::network::interfaces
  $dummy4      = $::network::dummy4
  $dummy6      = $::network::dummy6
  $sysctl      = $::network::sysctl

  # create_resources(sysctl, $sysctl)

  file { '/usr/local/bin/network_status.sh':
    ensure  => present,
    mode    => '0755',
    content => template('network/usr/local/bin/network_status.sh.erb'),
  }
  file { '/etc/rc.conf.d/network':
    ensure  => present,
    content => template('network/etc/rc.conf.d/network.erb'),
  }

  service { 'networking':
    ensure    => running,
    name      => 'netif',
    enable    => true,
    provider  => base,
    status    => '/usr/local/bin/network_status.sh',
    stop      => '/etc/rc.d/netif stop',
    start     => '/etc/rc.d/netif start',
    restart   => '/etc/rc.d/netif start &>/dev/null',
    subscribe => File['/etc/rc.conf.d/network'],
    require   => [
      File['/etc/rc.conf.d/network'],
      File['/usr/local/bin/network_status.sh'],
    ],
  }
  service { 'routing':
    ensure    => running,
    enable    => true,
    provider  => base,
    status    => '/usr/bin/true',
    stop      => '/etc/rc.d/routing stop',
    start     => '/etc/rc.d/routing start',
    restart   => '/etc/rc.d/routing restart  &>/dev/null',
    subscribe => Service['networking'],
    require   => [
      File['/usr/local/bin/network_status.sh'],
    ],
  }
}
