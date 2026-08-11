# @summary Used to configure networking for linux hosts
# @param networkd if true then the system will use systemd-networkd to manage interfaces instead of if
class network::linux (
  Boolean $networkd = false,
) {
  assert_private()

  stdlib::ensure_packages('vlan')

  include network

  $sysctl      = $network::sysctl
  $prefer_ipv4 = $network::prefer_ipv4
  $network_class = $networkd.bool2str('network::linux::networkd', 'network::linux::ifupdown')

  # We don;t make use of either theses services regarless of the network manager
  service { ['networkd-dispatcher', 'systemd-networkd-wait-online']:
    ensure   => 'stopped',
    enable   => 'mask',
    provider => 'systemd',  # required for CI
    before   => File['/etc/cloud', '/etc/netplan'],
  }
  file { ['/etc/cloud', '/etc/netplan']:
    ensure  => absent,
    recurse => true,
    force   => true,
    require => Class[$network_class],

  }
  package { ['cloud-init', 'netplan-generator']:
    ensure => 'purged',
    before => Class[$network_class],
  }

  exec { 'updatehostname':
    command     => "/bin/hostnamectl set-hostname ${facts['networking']['fqdn']}",
    refreshonly => true,
  }

  file {
    default:
      ensure => file;
    '/etc/hostname':
      content => $facts['networking']['fqdn'],
      notify  => Exec['updatehostname'];
    '/etc/gai.conf':
      content => template('network/etc/gai.conf.erb');
  }

  create_resources(sysctl, $sysctl)
  include $network_class
}
