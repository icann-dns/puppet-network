# @summary struct like object for describing interfaces
type Network::Interface = Struct[
  {
    addr4           => Optional[Variant[Stdlib::IP::Address::V4::CIDR, Array[Stdlib::IP::Address::V4::CIDR]]],
    addr6           => Optional[Variant[Stdlib::IP::Address::V6::CIDR, Array[Stdlib::IP::Address::V6::CIDR]]],
    gw4             => Optional[Stdlib::IP::Address::V4::Nosubnet],
    gw6             => Optional[Stdlib::IP::Address::V6::Nosubnet],
    nameservers     => Optional[Array[Stdlib::IP::Address::V4::Nosubnet]],
    nameservers6    => Optional[Array[Stdlib::IP::Address::V6::Nosubnet]],
    bond_interfaces => Optional[Array[String[1],2]],
    vlans           => Optional[Hash[Integer[1,4096], Network::VlanInterface]],
  }
]
