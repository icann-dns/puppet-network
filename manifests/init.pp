# == Class: network
#
class network (
  Hash             $interfaces       = {},
  Optional[Hash]   $dummy4           = {},
  Optional[Hash]   $dummy6           = {},
  Optional[Hash]   $sysctl           = {},
  Optional[Hash]   $additional_hosts = {},
  Optional[String] $primary          = undef,
  Boolean          $prefer_ipv4      = true,
  Boolean          $purge_hosts      = true,
) {
  resources {'host':
    purge => $purge_hosts,
  }
  $_primary = $primary ? {
    undef   => $::networking['primary'],
    default => $primary,
  }
  $host_entries = {
    'localhost'       => { 'ip' => '127.0.0.1', 'host_aliases' => []},
    'ip6-localhost'   => {
      'ip'           => '::1',
      'host_aliases' => ['localhost', 'ip6-loopback'],
    },
    'ip6-localnet'    => { 'ip' => 'fe00::0'},
    'ip6-mcastprefix' => { 'ip' => 'ff00::0'},
    'ip6-allnodes'    => { 'ip' => 'ff02::1'},
    'ip6-allrouters'  => { 'ip' => 'ff02::2'},
  }
  create_resources(host, $host_entries)
  if $additional_hosts {
    create_resources(host, $additional_hosts)
  }
  # only update hosts if we have a primary interface
  if $_primary {
    $primary_interface = $interfaces[$_primary]
    if $primary_interface['addr4'] {
      host{$::networking['fqdn']:
        ip           => $primary_interface['addr4'].split('/')[0],
        host_aliases => [$::networking['hostname']],
      }
    }
    if $primary_interface['addr6'] {
      host{$::networking['hostname']:
        ip           => $primary_interface['addr6'].split('/')[0],
        host_aliases => [$::networking['fqdn']],
      }
    }
  }
  case $::kernel {
    'Linux': {
      include network::linux
    }
    'FreeBSD': {
      include network::freebsd
    }
    default: {
      warning("${::kernel} not supported")
    }
  }

}
