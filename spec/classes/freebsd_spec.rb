# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers
describe 'network::freebsd' do
  let(:node) { 'network.example.com' }
  let(:params) do
    {}
  end
  let(:ping) { 'ping -q -W 1 -c 1 -S' }
  let(:ping6) { 'ping6 -q -i 1 -c 1 -I' }
  let(:loopback) { 'lo0' }
  let(:pre_condition) do
    <<-NETWORK
    class {'network':
      interfaces => {
        'eth0' => {
          'addr4' => '192.0.2.2/24',
          'gw4' => '192.0.2.1',
          'addr6' => '2001:db8::2/64',
          'gw6' => '2001:db8::1',
          'nameservers' => ['8.8.8.8'],
          'nameservers6' => ['2001:4860:4860::8888'],
        },
        'eth1' => {
          'addr4' => '192.0.2.3/24',
          'addr6' => '2001:db8::3/64',
        },
      },
      dummy4 => {
        'dns' => '192.0.2.53',
        'http' => ['192.0.2.80', '192.0.2.43'],
      },
      dummy6 => {
        'dns' => '2001:db8::53',
        'http' => ['2001:db8::80', '2001:db8::443'],
      },
      sysctl => {
        'net.core.somaxconn' => { 'value' => '1024' },
      }
    }
    NETWORK
  end

  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  # This will need to get moved
  # it { pp catalogue.resources }
  test_on = {
    supported_os: [
      {
        'operatingsystem'        => 'FreeBSD',
        'operatingsystemrelease' => ['10'],
      },
    ],
  }
  on_supported_os(test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }

        it do
          is_expected.to contain_file('/usr/local/bin/network_status.sh').with(
            ensure: 'file',
            mode: '0755'
          ).with_content(
            %r{#{ping} 127.0.0.1 192.0.2.2 1>/dev/null 2>&1 || exit 1}
          ).with_content(
            %r{#{ping} 127.0.0.1 192.0.2.3 1>/dev/null 2>&1 || exit 1}
          ).with_content(
            %r{#{ping} 192.0.2.2 192.0.2.1 1>/dev/null 2>&1 || exit 1}
          ).with_content(
            %r{#{ping} #{loopback} 2001:2b8:2 1>/dev/null 2>&1 || exit 1}
          ).with_content(
            %r{#{ping} #{loopback} 2001:2b8:3 1>/dev/null 2>&1 || exit 1}
          ).with_content(
            %r{#{ping} eth0 2001:2b8:1 1>/dev/null 2>&1 || exit 1}
          ).with_content(
            %r{#{ping} 127.0.0.1 192.0.2.53 1>/dev/null 2>&1 || exit 1}
          ).with_content(
            %r{#{ping} 127.0.0.1 192.0.2.80 1>/dev/null 2>&1 || exit 1}
          ).with_content(
            %r{#{ping} 127.0.0.1 192.0.2.43 1>/dev/null 2>&1 || exit 1}
          ).with_content(
            %r{#{ping} #{loopback} 2001:2b8:53 1>/dev/null 2>&1 || exit 1}
          ).with_content(
            %r{#{ping} #{loopback} 2001:2b8:80 1>/dev/null 2>&1 || exit 1}
          ).with_content(
            %r{#{ping} #{loopback} 2001:2b8:443 1>/dev/null 2>&1 || exit 1}
          )
        end

        it do
          # rubocop:disable Layout/LineContinuationSpacing
          is_expected.to contain_file('/etc/rc.conf.d/network').with_ensure(
            'file'
          ).with_content(
            %r{hostname="network.example.com"}
          ).with_content(
            %r{ifconfig_eth0="inet 192.0.2.2/24"}
          ).with_content(
            %r{ifconfig_eth1="inet 192.0.2.3/24"}
          ).with_content(
            %r{defaultrouter="192.0.2.1"}
          ).with_content(
            %r{netwait_if=eth0}
          ).with_content(
            %r{netwait_ip=192.0.2.1}
          ).with_content(
            %r{ifconfig_eth0_ipv6="inet6 2001:db8::2/64"}
          ).with_content(
            %r{ipv6_defaultrouter="2001:db8::1"}
          ).with_content(
            %r{ifconfig_eth1_ipv6="inet6 2001:db8::3/64"}
          ).with_content(
            %r{
            ifconfig_lo0_aliases="\\
            \s+inet\s192.0.2.53/32\s\\
            \s+inet\s192.0.2.80/32\s\\
            \s+inet\s192.0.2.43/32\s\\
            \s+inet6\s2001:db8::53/128\s\\
            \s+inet6\s2001:db8::80/128\s\\
            \s+inet6\s2001:db8::443/128"
            }x
          )
          # rubocop:enable Layout/LineContinuationSpacing
        end

        it do
          is_expected.to contain_service('networking').with(
            ensure: 'running',
            name: 'netif',
            enable: true,
            provider: 'base',
            status: '/usr/local/bin/network_status.sh',
            stop: '/etc/rc.d/netif stop',
            start: '/etc/rc.d/netif start',
            restart: '/etc/rc.d/netif start &>/dev/null',
            subscribe: 'File[/etc/rc.conf.d/network]',
            require: [
              'File[/etc/rc.conf.d/network]',
              'File[/usr/local/bin/network_status.sh]',
            ]
          )
        end

        it do
          is_expected.to contain_service('routing').with(
            ensure: 'running',
            enable: true,
            provider: 'base',
            status: '/usr/bin/true',
            stop: '/etc/rc.d/routing stop',
            start: '/etc/rc.d/routing start',
            restart: '/etc/rc.d/routing restart  &>/dev/null',
            subscribe: 'Service[networking]',
            require: ['File[/usr/local/bin/network_status.sh]']
          )
        end
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
