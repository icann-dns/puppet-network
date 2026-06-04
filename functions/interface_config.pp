function network::interface_config (
  String $iface,
  Network::Interface $config,
  String $file_prefix = '50-static',
) >> Hash {
  $file_name = "${file_prefix}-${iface}"
  $_gatewey = [$config['gw4'], $config['gw6']].filter |$v| { $v =~ NotUndef }
  $_addresses = [$config['addr4'], $config['addr6']].filter |$v| { $v =~ NotUndef }
  $_nameservers = [$config['nameservers'], $config['nameservers6']].flatten.filter |$v| { $v =~ NotUndef }
  $_vlans = $config['vlans'] ? {
    Undef   => [],
    # TODO: this can go back to integer once PR is merged
    default => $config['vlans'].keys().map |$vlan_id| { String($vlan_id) },
  }
  # The systemd::networkd::interface will gracefully handle empty values
  $_profile = {
    'Network' => {
      'Gateway' => $_gatewey,
    },
  }
  $_interface = {
    'filename' => $file_name,
    'network' => {
      'Match' => {
        'Name' => $iface,
      },
      'Network' => {
        'Address' => $_addresses,
        'DNS'     => $_nameservers,
        'VLAN'    => $_vlans,
      },
    },
  }
  $_config = {
    'interface' => $_interface,
    'profile'   => $_profile,
  }
  return $_config
}
