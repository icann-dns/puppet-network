# @summary type to represent IPv4 dummy interfaces
type Network::Dummy6 = Variant[
  Stdlib::IP::Address::V6::Nosubnet,
  Array[Stdlib::IP::Address::V6::Nosubnet],
]
