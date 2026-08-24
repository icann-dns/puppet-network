# frozen_string_literal: true

require 'spec_helper'

describe 'network::get_addresses' do
  let(:facts) do
    {
      'ipv4_capable' => true,
      'ipv6_capable' => true,
      'ipv4_primary_interface' => 'eth0',
      'ipv6_primary_interface' => 'eth0',
    }
  end

  let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }

  let(:expected_addresses) do
    ['192.0.2.2', '2001:db8::2', '198.51.100.2', '198.51.100.3', '2001:db8:1::2']
  end

  it 'returns the same addresses as the compatibility matrix' do
    is_expected.to run.with_params('dummy0').and_return(expected_addresses)
  end

  it 'applies the same address-family and primary-interface options' do
    is_expected.to run.with_params('dummy0', false, true, false).and_return(
      ['198.51.100.2', '198.51.100.3'],
    )
  end

  it 'returns IPv6 addresses when IPv4 is disabled' do
    is_expected.to run.with_params('dummy0', true, false, true).and_return(
      ['2001:db8::2', '2001:db8:1::2'],
    )
  end

  it 'returns IPv4 addresses when IPv6 is disabled' do
    is_expected.to run.with_params('dummy0', true, true, false).and_return(
      ['192.0.2.2', '198.51.100.2', '198.51.100.3'],
    )
  end

  it 'accepts multiple dummy names and ignores missing names' do
    is_expected.to run.with_params(%w[missing dummy0]).and_return(expected_addresses)
  end

  it 'returns only primary addresses for an unknown dummy name' do
    is_expected.to run.with_params('missing').and_return(
      ['192.0.2.2', '2001:db8::2'],
    )
  end

  it 'returns the same joined representation' do
    is_expected.to run.with_params('dummy0', true, true, true, ',').and_return(expected_addresses.join(','))
  end
end
