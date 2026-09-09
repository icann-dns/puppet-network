# frozen_string_literal: true

require 'spec_helper'

describe 'network::linux' do
  let(:node) { 'network.example.com' }
  let(:params) do
    {}
  end

  let(:pre_condition) do
    <<-NETWORK
    class {'network':
      networkd => true,
      interfaces => {
        'bond0' => {
          'addr4' => '192.0.2.2/24',
          'gw4' => '192.0.2.1',
          'addr6' => '2001:db8::2/64',
          'gw6' => '2001:db8::1',
          'nameservers' => ['8.8.8.8'],
          'nameservers6' => ['2001:4860:4860::8888'],
          'bond_interfaces' => ['eth0', 'eth1'],
        },
        'eth2.100' => {
          'addr4' => '10.0.0.2/24',
          'addr6' => '2001:db8:1::2/64',
        },
        'eth2' => {
          'addr4' => ['192.0.2.3/24', '192.0.2.4/24'],
          'addr6' => ['2001:db8::3/64'],
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
        'operatingsystem' => 'Ubuntu',
        'operatingsystemrelease' => ['22.04'],
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

      describe 'standard config' do
        describe 'resource creation' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_file('/etc/init.d/networking').with_ensure('absent') }
          it { is_expected.to contain_file('/etc/network/interfaces').with_ensure('absent') }
          it { is_expected.to contain_file('/usr/local/bin/network_status.sh').with_ensure('absent') }
          it { is_expected.to contain_service('networking').with(ensure: 'stopped', enable: 'mask') }
          it { is_expected.to contain_network__linux__networkd__static('bond0') }
          it { is_expected.to contain_network__linux__networkd__bond('bond0').with(interfaces: %w[eth0 eth1]) }
          it { is_expected.to contain_network__linux__networkd__static('eth2') }
          it { is_expected.to contain_network__linux__networkd__vlan('eth2.100').with(vlan_id: 100) }

          it do
            is_expected.to contain_network__linux__networkd__dummy('lo-anycast-ips')
              .with(
                ips: [
                  '192.0.2.53/32', '192.0.2.80/32', '192.0.2.43/32',
                  '2001:db8::53/128', '2001:db8::80/128', '2001:db8::443/128',
                ],
              )
          end
        end

        describe 'generated systemd-networkd interfaces' do
          it 'creates bond interface config with both v4 and v6 gateways and nameservers' do
            is_expected.to contain_systemd__networkd__interface('static-bond0').with(
              interface: {
                'filename' => '50-static-bond0',
                'network' => {
                  'Match' => { 'Name' => 'bond0' },
                  'Network' => {
                    'Address' => ['192.0.2.2/24', '2001:db8::2/64'],
                    'DNS' => ['8.8.8.8', '2001:4860:4860::8888'],
                    'VLAN' => [],
                    'IPv6AcceptRA' => 'no',
                  },
                },
              },
              network_profile: {
                'Network' => {
                  'Gateway' => ['192.0.2.1', '2001:db8::1'],
                },
              },
            )
          end

          it 'creates the bond netdev and member configs' do
            is_expected.to contain_systemd__networkd__interface('netdev-bond0').with(
              interface: {
                'filename' => '30-netdev-bond0',
                'netdev' => {
                  'NetDev' => {
                    'Name' => 'bond0',
                    'Kind' => 'bond',
                  },
                  'Bond' => {
                    'Mode' => '802.3ad',
                    'MIIMonitorSec' => 0.1,
                    'LACPTransmitRate' => 'fast',
                    'TransmitHashPolicy' => 'layer3+4',
                  },
                },
              },
            )

            is_expected.to contain_systemd__networkd__interface('bond0-eth0').with(
              interface: {
                'filename' => '30-netdev-eth0',
                'network' => {
                  'Match' => { 'Name' => 'eth0' },
                  'Network' => {
                    'Bond' => 'bond0',
                    'IPv6AcceptRA' => 'no',
                  },
                },
              },
            )
          end

          it 'creates a vlan netdev and interface config with the vlan id' do
            is_expected.to contain_systemd__networkd__interface('netdev-eth2.100').with(
              interface: {
                'filename' => '30-netdev-eth2.100',
                'netdev' => {
                  'NetDev' => {
                    'Name' => 'eth2.100',
                    'Kind' => 'vlan',
                  },
                  'VLAN' => { 'Id' => 100 },
                },
              },
            )

            is_expected.to contain_systemd__networkd__interface('vlan-eth2.100').with(
              interface: {
                'filename' => '50-vlan-eth2.100',
                'network' => {
                  'Match' => { 'Name' => 'eth2.100' },
                  'Network' => {
                    'Address' => ['10.0.0.2/24', '2001:db8:1::2/64'],
                    'DNS' => [],
                    'VLAN' => [],
                    'IPv6AcceptRA' => 'no',
                  },
                },
              },
              network_profile: {
                'Network' => {
                  'Gateway' => [],
                },
              },
            )
          end

          it 'assigns all anycast addresses to loopback' do
            is_expected.to contain_systemd__networkd__interface('lo-anycast-ips').with(
              interface: {
                'filename' => '10-lo-anycast-ips',
                'network' => {
                  'Match' => { 'Name' => 'lo' },
                  'Network' => {
                    'Address' => [
                      '192.0.2.53/32', '192.0.2.80/32', '192.0.2.43/32',
                      '2001:db8::53/128', '2001:db8::80/128', '2001:db8::443/128',
                    ],
                    'IPv6AcceptRA' => 'no',
                  },
                },
              },
            )
          end

          it 'multiple IP addresses on same interface' do
            is_expected.to contain_systemd__networkd__interface('static-eth2').with(
              interface: {
                'filename' => '50-static-eth2',
                'network' => {
                  'Match' => { 'Name' => 'eth2' },
                  'Network' => {
                    'Address' => ['192.0.2.3/24', '192.0.2.4/24', '2001:db8::3/64'],
                    'DNS' => [],
                    # TODO: need to make sure this is correct, but it seems like the VLAN should be on the eth2.100 interface, not eth2
                    'VLAN' => ['eth2.100'],
                    'IPv6AcceptRA' => 'no',
                  },
                },
              },
              network_profile: { 'Network' => { 'Gateway' => [] } },
            )
          end
        end
      end
    end
  end
end
