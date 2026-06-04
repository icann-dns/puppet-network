# @summary Used to configure networking for linux hosts
# @param iface The name of the interface to configure
# @param config The config hash for the interface to configure
define network::linux::networkd::static (
  String            $iface = $name,
  Network::Interface $config = {},
) {
  assert_private()
  $_config = network::interface_config($iface, $config)
  systemd::networkd::interface { "static-${iface}":
    interface       => $_config['interface'],
    network_profile => $_config['profile'],
  }
}
