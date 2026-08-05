# @summary We use this to merge configs vlan configs under the parent interface
# @param interfaces The interfaces hash from the main network class
# @example { eth.10: { addr4 => '192.0.2.1'} } would merge into { eth: { vlans => { 10: { addr4 => '192.0.2.1' } } } }
function network::vlan_merge (
  Hash[String[1],Network::Interface] $interfaces = {},
) {
  $interfaces.reduce({}) |$memo, $pair| {
    $iface = $pair[0]
    $config = $pair[1]
    if $iface =~ /^([^.]+)\.(\d+)$/ {
      $parent = $1
      $vlan_id = Integer($2)
      $parent_config = $memo[$parent] ? {
        Undef   => {},
        default => $memo[$parent],
      }
      $parent_vlans = $parent_config['vlans'] ? {
        Undef   => {},
        default => $parent_config['vlans'],
      }

      $memo + {
        $parent => $parent_config + {
          'vlans' => $parent_vlans + { $vlan_id => $config }
        }
      }
    } else {
      $existing_config = $memo[$iface] ? {
        Undef   => {},
        default => $memo[$iface],
      }

      $memo + { $iface => $existing_config + $config }
    }
  }
}
