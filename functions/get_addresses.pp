function network::get_addresses(
  Variant[Array[String[1]], String[1]] $dummy_name,
  Boolean $send_primary = true,
  Boolean $send_ipv4 = true,
  Boolean $send_ipv6 = true,
  Optional[String] $join = undef,
) >> Variant[Array[String[1]], String[1]] {
  $ipv6_capable = $facts['ipv6_capable']
  $ipv4_capable = $facts['ipv4_capable']
  $ipv4_primary_interface = $facts['ipv4_primary_interface']
  $ipv6_primary_interface = $facts['ipv6_primary_interface']
  $dummy4 = lookup('network::dummy4', { 'default_value' => {} })
  $dummy6 = lookup('network::dummy6', { 'default_value' => {} })
  $interfaces = lookup('network::interfaces', { 'default_value' => {} })

  $primary_addresses = if $send_primary {
    [
      if $ipv4_primary_interface =~ NotUndef and $ipv4_capable and $send_ipv4 and $interfaces[$ipv4_primary_interface] =~ Hash and $interfaces[$ipv4_primary_interface]['addr4'] =~ NotUndef {
        $interfaces[$ipv4_primary_interface]['addr4'].split('/')[0]
      },
      if $ipv6_primary_interface =~ NotUndef and $ipv6_capable and $send_ipv6 and $interfaces[$ipv6_primary_interface] =~ Hash and $interfaces[$ipv6_primary_interface]['addr6'] =~ NotUndef {
        $interfaces[$ipv6_primary_interface]['addr6'].split('/')[0]
      },
    ].filter |$address| { $address =~ NotUndef }
  } else {
    []
  }

  $dummy_names = Array($dummy_name)
  $dummy4_addresses = if $ipv4_capable and $send_ipv4 {
    $dummy_names.map |$name| {
      if $dummy4 =~ Hash and $dummy4[$name] =~ NotUndef {
        Array($dummy4[$name]).flatten.map |$address| { $address.split('/')[0] }
      } else {
        []
      }
    }.flatten
  } else {
    []
  }
  $dummy6_addresses = if $ipv6_capable and $send_ipv6 {
    $dummy_names.map |$name| {
      if $dummy6 =~ Hash and $dummy6[$name] =~ NotUndef {
        Array($dummy6[$name]).flatten.map |$address| { $address.split('/')[0] }
      } else {
        []
      }
    }.flatten
  } else {
    []
  }

  $addresses = $primary_addresses + $dummy4_addresses + $dummy6_addresses
  if $join =~ NotUndef {
    $addresses.join($join)
  } else {
    $addresses
  }
}
