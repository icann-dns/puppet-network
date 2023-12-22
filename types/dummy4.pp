# @summary type to represent IPv4 dummy interfaces
type Network::Dummy4 = Variant[
  Stdlib::IP::Address::V4::Nosubnet,
  Array[Stdlib::IP::Address::V4::Nosubnet],
]
