# @summary struct like object for describing interfaces
type Network::Interface = Struct[
  {
    addr4           => Optional[Stdlib::IP::Address::V4::CIDR],
    addr6           => Optional[Stdlib::IP::Address::V6],
    gw4             => Optional[Stdlib::IP::Address::V4::Nosubnet],
    gw6             => Optional[Stdlib::IP::Address::V6::Nosubnet],
    nameservers     => Optional[Array[Stdlib::IP::Address::V4::Nosubnet]],
    nameservers6    => Optional[Array[Stdlib::IP::Address::V6::Nosubnet]],
    vlan_raw_device => Optional[String[1]],
  }
]
