# @summary Used to configure networking for linux hosts
# @param vlan_id The vlan id to configure
# @param iface The name of the interface to configure
# @param config The config hash for the interface to configure
define network::linux::networkd::vlan (
  Integer $vlan_id,
  String $iface = $name,
  Network::Interface $config = {},
) {
  assert_private()
  # Neet to create netdev
  $_vlan_netdev_interface = {
    'filename' => "30-netdev-${iface}",
    'netdev' => {
      'NetDev' => {
        'Name' => $iface,
        'Kind' => 'vlan',
      },
      'VLAN' => {
        'Id' => $vlan_id,
      },
    },
  }
  systemd::networkd::interface { "netdev-${iface}":
    interface => $_vlan_netdev_interface,
  }

  # Create the interface config
  $_vlan_config = network::interface_config($iface, $config, '50-vlan')
  systemd::networkd::interface { "vlan-${iface}":
    interface       => $_vlan_config['interface'],
    network_profile => $_vlan_config['profile'],
  }
}
