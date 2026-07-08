# frozen_string_literal: true

require 'spec_helper'

describe 'network::vlan_merge' do

  it { is_expected.to run.with_params({}).and_return({}) }

  context 'when only vlan interfaces are given' do
    let(:interfaces) do
      {
        'eth0.10' => {
          'addr4' => '192.0.2.10/24',
        },
        'eth0.20' => {
          'addr4' => '192.0.2.20/24',
        },
      }
    end

    it 'nests vlan configs under the parent interface' do
      is_expected.to run.with_params(interfaces).and_return(
        {
          'eth0' => {
            'vlans' => {
              10 => { 'addr4' => '192.0.2.10/24' },
              20 => { 'addr4' => '192.0.2.20/24' },
            },
          },
        },
      )
    end
  end

  context 'when parent and vlan interfaces are mixed' do
    let(:interfaces) do
      {
        'eth0.10' => {
          'addr4' => '192.0.2.10/24',
        },
        'eth0' => {
          'addr4' => '192.0.2.1/24',
          'gw4' => '192.0.2.254',
        },
        'eth1' => {
          'addr4' => '198.51.100.2/24',
        },
      }
    end

    it 'keeps parent config and merges vlan data' do
      is_expected.to run.with_params(interfaces).and_return(
        {
          'eth0' => {
            'addr4' => '192.0.2.1/24',
            'gw4' => '192.0.2.254',
            'vlans' => {
              10 => { 'addr4' => '192.0.2.10/24' },
            },
          },
          'eth1' => {
            'addr4' => '198.51.100.2/24',
          },
        },
      )
    end
  end
end
