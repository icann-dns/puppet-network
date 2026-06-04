# @summary Used to configure networking for linux hosts
class network::linux::networkd {
  assert_private()

  $dummy4      = $network::dummy4
  $dummy6      = $network::dummy6

  # We need to parse out the vlan interfaces
  $interfaces  = $network::interfaces

  # We only neeed the ip addresses
  $dummy_ips4 = $dummy4.values.flatten.map |$ip| { "${ip}/32" }
  $dummy_ips6 = $dummy6.values.flatten.map |$ip| { "${ip}/128" }
  $dummy_ips = $dummy_ips4 + $dummy_ips6

  $_interfaces = network::vlan_merge($interfaces)

  # clean up from ifupdown
  file { ['/etc/init.d/networking', '/usr/local/bin/network_status.sh', '/etc/network/interfaces']:
    ensure => absent,
  }
  service { 'networking':
    ensure => 'stopped',
    enable => mask,
  }
  $_interfaces.each |$iface, $config| {
    if 'vlans' in $config {
      $_netdev_config = network::interface_config($iface, $config, '30-static')
      systemd::networkd::interface { "static-${iface}":
        interface       => $_netdev_config['interface'],
        network_profile => $_netdev_config['profile'],
      }
      $config['vlans'].each |$vlan_id, $vlan_config| {
        network::linux::networkd::vlan { "${iface}.${vlan_id}":
          vlan_id => $vlan_id,
          config  => $vlan_config,
        }
      }
    } else {
      network::linux::networkd::static { $iface:
        config => $config,
      }
    }
  }
  unless $dummy_ips.empty {
    network::linux::networkd::dummy { 'lo-anycast-ips':
      ips => $dummy_ips,
    }
  }
}
