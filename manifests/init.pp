# @summary
#   Used to configure networking for linux and freebsd hosts
# @example
#   class { 'network':
#     interfaces           => {
#       'eth0'             => {
#         'addr4'          => '192.0.2.42',
#         'addr6'          => '2001:db8::42',
#         'gw4'            => '192.0.2.1',
#         'gw6'            => '2001:db8::1',
#         'nameservers'    => ['8.8.8.8'],
#         'nameservers6'   => ['2001:4860:4860::8888'],
#       },
#     },
#     dummy4                => {
#       'dns'               => '192.0.2.53',
#       'http'              => ['192.0.2.80', 192.0.2.443'],
#     },
#     dummy6                => {
#       'dns'               => '192.0.2.53',
#       'http'              => ['192.0.2.80', 192.0.2.443'],
#     },
#     sysctl                 => {
#       'net.core.somaxconn' => { 'value' =>'1024' },
#     },
#     additional_hosts       => {
#       'foobar.example.com' => {
#         'ip'               => '192.0.2.254',
#         'host_aliases'     => ['foobar'],
#       },
#     },
#     prefer_ipv4            => false,
#     purge_hosts            => false,
#   }
#
# @param interfaces
#   a hash of interfaces to create
# @param dummy4
#   a hash of ipv4 dummy interfaces to create
# @param dummy6
#   a hash of ipv6 dummy interfaces to create
# @param sysctl
#   a hash of sysctl types to pass to thias/sysctl
# @param additional_hosts
#   a hash of additional `host` type entries to create
# @param prefer_ipv4 
#   if true then the system will prefer IPv4 connections over IPv6
# @param purge_hosts
#   if true purge any `host` entries not managed by puppet
# @param primary the name of the primary interface
class network (
  Boolean                            $prefer_ipv4      = true,
  Boolean                            $purge_hosts      = true,
  Hash[String[1],Network::Interface] $interfaces       = {},
  Hash[String[1], Network::Dummy4]   $dummy4           = {},
  Hash[String[1], Network::Dummy6]   $dummy6           = {},
  Hash                               $sysctl           = {},
  Hash                               $additional_hosts = {},
  Optional[String]                   $primary          = undef,
) {
  resources { 'host':
    purge => $purge_hosts,
  }
  $_primary = $primary ? {
    undef   => $facts['networking']['primary'],
    default => $primary,
  }
  $host_entries = {
    'localhost'       => { 'ip' => '127.0.0.1', 'host_aliases' => [] },
    'ip6-localhost'   => {
      'ip'           => '::1',
      'host_aliases' => ['localhost', 'ip6-loopback'],
    },
    'ip6-localnet'    => { 'ip' => 'fe00::0' },
    'ip6-mcastprefix' => { 'ip' => 'ff00::0' },
    'ip6-allnodes'    => { 'ip' => 'ff02::1' },
    'ip6-allrouters'  => { 'ip' => 'ff02::2' },
  }
  create_resources(host, $host_entries)
  if $additional_hosts {
    create_resources(host, $additional_hosts)
  }
  # only update hosts if we have a primary interface
  if $_primary {
    $primary_interface = $interfaces[$_primary]
    if $primary_interface['addr4'] {
      host { $facts['networking']['fqdn']:
        ip           => $primary_interface['addr4'].split('/')[0],
        host_aliases => [$facts['networking']['hostname']],
      }
    }
    if $primary_interface['addr6'] {
      host { $facts['networking']['hostname']:
        ip           => $primary_interface['addr6'].split('/')[0],
        host_aliases => [$facts['networking']['fqdn']],
      }
    }
  }
  case $facts['kernel'] {
    'Linux': {
      include network::linux
    }
    'FreeBSD': {
      include network::freebsd
    }
    default: {
      warning("${facts['kernel']} not supported")
    }
  }
}
