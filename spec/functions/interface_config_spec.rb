# frozen_string_literal: true

require 'spec_helper'

describe 'network::interface_config' do
  let(:iface) { 'eth0' }

  let(:config) do
    {
      'addr4' => '192.0.2.2/24',
      'addr6' => '2001:db8::2/64',
      'gw4' => '192.0.2.1',
      'gw6' => '2001:db8::1',
      'nameservers' => ['192.0.2.53'],
      'nameservers6' => ['2001:db8::53'],
      'vlans' => {
        10 => { 'addr4' => '192.0.2.10/24' },
        20 => { 'addr4' => '192.0.2.20/24' },
      },
    }
  end

  it 'builds the expected interface and profile structure with default file prefix' do
    is_expected.to run.with_params(iface, config).and_return(
      {
        'interface' => {
          'filename' => '50-static-eth0',
          'network' => {
            'Match' => {
              'Name' => 'eth0',
            },
            'Network' => {
              'Address' => ['192.0.2.2/24', '2001:db8::2/64'],
              'DNS' => ['192.0.2.53', '2001:db8::53'],
              'VLAN' => ['eth0.10', 'eth0.20'],
              'IPv6AcceptRA' => 'no',
            },
          },
        },
        'profile' => {
          'Network' => {
            'Gateway' => ['192.0.2.1', '2001:db8::1'],
          },
        },
      },
    )
  end

  it 'uses a custom file prefix when provided' do
    is_expected.to run.with_params(iface, config, '10-manual').and_return(
      {
        'interface' => {
          'filename' => '10-manual-eth0',
          'network' => {
            'Match' => {
              'Name' => 'eth0',
            },
            'Network' => {
              'Address' => ['192.0.2.2/24', '2001:db8::2/64'],
              'DNS' => ['192.0.2.53', '2001:db8::53'],
              'VLAN' => ['eth0.10', 'eth0.20'],
              'IPv6AcceptRA' => 'no',
            },
          },
        },
        'profile' => {
          'Network' => {
            'Gateway' => ['192.0.2.1', '2001:db8::1'],
          },
        },
      },
    )
  end

  it 'returns empty arrays for optional unset fields' do
    is_expected.to run.with_params(
      'eth1',
      {
        'addr4' => '198.51.100.2/24',
      },
    ).and_return(
      {
        'interface' => {
          'filename' => '50-static-eth1',
          'network' => {
            'Match' => {
              'Name' => 'eth1',
            },
            'Network' => {
              'Address' => ['198.51.100.2/24'],
              'DNS' => [],
              'VLAN' => [],
              'IPv6AcceptRA' => 'no',
            },
          },
        },
        'profile' => {
          'Network' => {
            'Gateway' => [],
          },
        },
      },
    )
  end
end
