# @summary Used to configure networking for linux hosts using ifupdown`
# @param packages An array of packages to ensure are installed.
class network::linux::ifupdown (
  Array[String] $packages = ['ifupdown', 'resolvconf'],
) {
  assert_private()

  $interfaces  = $network::interfaces
  $dummy4      = $network::dummy4
  $dummy6      = $network::dummy6

  service { ['systemd-networkd', 'systemd-networkd.socket']:
    ensure   => 'stopped',
    enable   => mask,
    provider => 'systemd',
  }
  stdlib::ensure_packages($packages)

  file {
    default:
      ensure => file;
    # TODO: might need to move this to linux but i suspect we can set directly in networkd
    '/etc/sysctl.d/net.ipv6.conf.interface.accept_ra.conf':
      content => template(
        'network/etc/sysctl.d/net.ipv6.conf.interface.accept_ra.conf.erb'
      );
    '/etc/init.d/networking':
      mode   => '0755',
      source => 'puppet:///modules/network/etc/init.d/networking';
    '/usr/local/bin/network_status.sh':
      mode    => '0755',
      content => template('network/usr/local/bin/network_status.sh.erb');
    '/etc/network':
      ensure => directory;
    '/etc/network/interfaces':
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
