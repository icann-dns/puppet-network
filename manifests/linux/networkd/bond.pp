# @summary Used to configure networking for linux hosts
# @param interfaces The list of interfaces to include in the bond
# @param iface The name of the interface to configure
define network::linux::networkd::bond (
  Array[String[1]]  $interfaces,
  String            $iface = $name,
) {
  assert_private()
  $_bond_interface = {
    'filename' => "30-netdev-${iface}",
    'netdev' => {
      'NetDev' => {
        'Name' => $iface,
        'Kind' => 'bond',
      },
      'Bond' => {
        'Mode' => '802.3ad',
        'MIIMonitorSec' => 0.1,  # 100ms
        'LACPTransmitRate' => 'fast',
        'TransmitHashPolicy' => 'layer3+4',
      },
    },
  }
  systemd::networkd::interface { "netdev-${iface}":
    interface => $_bond_interface,
  }
  $interfaces.each |$bond_iface| {
    $_bond_member_interface = {
      'filename' => "30-netdev-${bond_iface}",
      'network' => {
        'Match' => {
          'Name' => $bond_iface,
        },
        'Network' => {
          'Bond' => $iface,
          'IPv6AcceptRA' => 'no',
        },
      },
    }
    systemd::networkd::interface { "${iface}-${bond_iface}":
      interface => $_bond_member_interface,
    }
  }
}
