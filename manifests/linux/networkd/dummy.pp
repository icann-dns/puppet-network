# @summary Used to configure networking for linux hosts
# @param ips The list of IP addresses to configure on the dummy interface
define network::linux::networkd::dummy (
  Array[Stdlib::IP::Address, 1] $ips = [],
) {
  assert_private()
  systemd::networkd::interface { $name:
    interface => {
      'filename' => "10-${name}",
      'network'  => {
        'Match'   => {
          'Name' => 'lo',
        },
        'Network' => {
          'Address'      => $ips,
          'IPv6AcceptRA' => 'no',
        },
      },
    },
  }
}
