# @summary Used to configure networking for linux hosts
# @param networkd if true then the system will use systemd-networkd to manage interfaces instead of if
class network::linux (
  Boolean $networkd = $network::networkd,
) {
  assert_private()

  stdlib::ensure_packages('vlan')

  include network

  $sysctl = $network::sysctl
  $prefer_ipv4 = $network::prefer_ipv4
  $network_class = $networkd.bool2str('network::linux::networkd', 'network::linux::ifupdown')
  $before_services = $network::before_services

  if $networkd and $before_services {
    Service['systemd-networkd'] -> Service[$before_services]
  } else {
    # We need to override the systemd file to ensure a dummy interface is created when the module os loaded.
    unless $network::dummy4.empty() and $network::dummy6.empty() {
      file { '/etc/modprobe.d/systemd.conf':
        ensure  => file,
        mode    => '0644',
        content => "options bonding max_bonds=0\n",
        before  => Kmod::Load['dummy'],
      }
      kmod::load { 'dummy':
        before => Service['networking'],
      }
    }
    kmod::load { '8021q':
      before => Service['networking'],
    }
    if $before_services {
      Service['networking'] -> Service[$before_services]
    }
  }

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
