# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers
describe 'network::linux' do
  let(:node) { 'network.example.com' }
  let(:params) do
    {}
  end

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
        'net.core.somaxconn' => {
          'value' => '1024',
          'ensure' => 'present',
        },
      }
    }
    NETWORK
  end

  test_on = {
    supported_os: [
      {
        'operatingsystem'        => 'Ubuntu',
        'operatingsystemrelease' => ['20.04'],
      },
    ],
  }
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  # This will need to get moved
  # it { pp catalogue.resources }
  on_supported_os(test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:ping) { 'ping -q -W 1 -c 1 -I' }
      let(:ping6) { 'ping6 -q -W 1 -c 1 -I' }
      let(:loopback) { 'lo' }

      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }

        it do
          is_expected.to contain_file('/etc/hostname').with(
            content: 'network.example.com'
          )
        end

        it do
          is_expected.to contain_file(
            '/etc/sysctl.d/net.ipv6.conf.interface.accept_ra.conf'
          ).with_ensure('file').with_content(
            %r{net.ipv6.conf.eth0.accept_ra = 0}
          ).with_content(
            %r{net.ipv6.conf.eth1.accept_ra = 0}
          )
        end

        it do
          is_expected.to contain_file('/etc/gai.conf').with_ensure(
            'file'
          ).with_content(
            %r{precedence ::ffff:0:0/96 100}
          )
        end

        it do
          is_expected.to contain_file('/etc/init.d/networking').with(
            ensure: 'file',
            mode: '0755',
            source: 'puppet:///modules/network/etc/init.d/networking'
          )
        end

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
          is_expected.to contain_file('/etc/network').with(
            ensure: 'directory'
          )
        end

        it do
          is_expected.to contain_file('/etc/network/interfaces').with(
            ensure: 'file'
          ).with_content(
            %r{auto eth0}
          ).with_content(
            %r{auto eth1}
          ).with_content(
            %r{
            iface\seth0\sinet\sstatic
            \s+address\s192.0.2.2/24
            \s+\#This\sis\signored\sif\sunbound\sis\sinstalled
            \s+dns-nameservers\s8.8.8.8
            \s+dns-search\sexample.com
            \s+gateway\s192.0.2.1
            }x
          ).with_content(
            %r{
            iface\seth1\sinet\sstatic
            \s+address\s192.0.2.3/24
            \s+dns-search\sexample.com
            }x
          ).with_content(
            %r{
            iface\seth0\sinet6\sstatic
            \s+address\s2001:db8::2/64
            \s+\#This\sis\signored\sif\sunbound\sis\sinstalled
            \s+dns-nameservers\s2001:4860:4860::8888
            \s+gateway\s2001:db8::1
            }x
          ).with_content(
            %r{
            iface\seth1\sinet6\sstatic
            \s+address\s2001:db8::3/64
            }x
          ).with_content(
            %r{
            iface\sdummy0\sinet\sstatic
            \s+address\s192.0.2.53/32
            }x
          ).with_content(
            %r{
            iface\sdummy0:0\sinet\sstatic
            \s+address\s192.0.2.80/32
            }x
          ).with_content(
            %r{
            iface\sdummy0:1\sinet\sstatic
            \s+address\s192.0.2.43/32
            }x
          ).with_content(
            %r{
            iface\sdummy0\sinet6\sstatic
            \s+\#dns:
            \s+address\s2001:db8::53/128
            \s+\#http:
            \s+post-up\sip\s-f\sinet6\saddr\sadd\s2001:db8::80/128\sdev\sdummy0
            \s+pre-down\sip\s-f\sinet6\saddr\sdel\s2001:db8::80/128\sdev\sdummy0
            \s+\#http:
            \s+post-up\sip\s-f\sinet6\saddr\sadd\s2001:db8::443/128\sdev\sdummy0
            \s+pre-down\sip\s-f\sinet6\saddr\sdel\s2001:db8::443/128\sdev\sdummy0
            }x
          )
        end

        it do
          is_expected.to contain_exec('network_ifup_all').with(
            command: '/sbin/ifup -a --ignore-errors',
            subscribe: 'File[/etc/network/interfaces]',
            refreshonly: true
          )
        end

        it do
          is_expected.to contain_service('networking').with(
            ensure: 'running',
            enable: true,
            provider: 'base',
            status: '/usr/local/bin/network_status.sh',
            stop: '/etc/init.d/networking stop',
            start: '/etc/init.d/networking restart',
            restart: '/etc/init.d/networking restart',
            subscribe: 'File[/etc/network/interfaces]'
          )
        end
      end

      describe 'change defalts' do
        context 'change prefer_ipv4, no nameserver with vlan' do
          let(:pre_condition) do
            <<-NETWORK
            class {'network':
              interfaces => {
                'eth0' => {
                  'addr4' => '192.0.2.2/24',
                  'gw4' => '192.0.2.1',
                },
                'eth0.42' => {
                  'addr4' => '192.0.2.42/24',
                  'vlan_raw_device' => 'eth0',
                }
              },
              sysctl => {
                'net.core.somaxconn' => { 'value' => '1024' },
              },
              prefer_ipv4 => false,
            }
            NETWORK
          end

          it do
            is_expected.to contain_file('/etc/gai.conf').with_ensure(
              'file'
            ).without_content(
              %r{precedence ::ffff:0:0/96 100}
            )
          end

          it do
            is_expected.to contain_file('/etc/network/interfaces').with_content(
              %r{
              iface\seth0\sinet\sstatic
              \s+address\s192.0.2.2/24
              \s+dns-search\sexample.com
              \s+gateway\s192.0.2.1
              }x
            ).with_content(
              %r{
              iface\seth0.42\sinet\sstatic
              \s+address\s192.0.2.42/24
              \s+dns-search\sexample.com
              \s+vlan-raw-device\seth0
              }x
            )
          end
        end
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
