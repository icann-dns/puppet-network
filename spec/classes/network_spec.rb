# frozen_string_literal: true

require 'spec_helper'

describe 'network' do
  let(:node) { 'network.example.com' }

  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  # This will need to get moved
  # it { pp catalogue.resources }
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:params) do
        {
          interfaces: {
            'eth0' => {
              'addr4' => '192.0.2.2/24',
              'gw4' => '192.0.2.1',
              'addr6' => '2001:db8::2/64',
              'gw6' => '2001:db8::2',
            },
            'eth1' => {
              'addr4' => '192.0.2.3/24',
              'addr6' => '2001:db8::3/64',
            },
          },
        }
      end

      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }

        case facts[:kernel]
        when 'FreeBSD'
          it { is_expected.to contain_class('network::freebsd') }
          it { is_expected.not_to contain_class('network::linux') }
        else
          it { is_expected.not_to contain_class('network::freebsd') }
          it { is_expected.to contain_class('network::linux') }
        end
        it { is_expected.to contain_resources('host').with_purge(true) }

        it do
          is_expected.to contain_host('network.example.com').with(
            ip: '192.0.2.2',
            host_aliases: ['network'],
          )
        end

        it do
          is_expected.to contain_host('network').with(
            ip: '2001:db8::2',
            host_aliases: ['network.example.com'],
          )
        end
      end

      describe 'Change Defaults' do
        context 'additional_hosts' do
          before do
            params.merge!(
              additional_hosts: {
                'test.example.com' => {
                  'host_aliases' => ['test'],
                  'ip' => '192.0.2.3',
                },
              },
            )
          end

          it { is_expected.to compile }

          it do
            is_expected.to contain_host('test.example.com').with(
              ip: '192.0.2.3',
              host_aliases: ['test'],
            )
          end
        end

        context 'primary' do
          before { params.merge!(primary: 'eth1') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_host('network.example.com').with(
              ip: '192.0.2.3',
              host_aliases: ['network'],
            )
          end

          it do
            is_expected.to contain_host('network').with(
              ip: '2001:db8::3',
              host_aliases: ['network.example.com'],
            )
          end
        end

        context 'purge_hosts' do
          before { params.merge!(purge_hosts: false) }

          it { is_expected.to compile }
          it { is_expected.not_to contain_resources('host').with_purge(true) }
        end
      end

      describe 'check bad type' do
        context 'interfaces' do
          before { params.merge!(interfaces: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'dummy4' do
          before { params.merge!(dummy4: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'dummy6' do
          before { params.merge!(dummy6: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'sysctl' do
          before { params.merge!(sysctl: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'additional_hosts' do
          before { params.merge!(additional_hosts: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'primary' do
          before { params.merge!(primary: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'prefer_ipv4' do
          before { params.merge!(prefer_ipv4: 'foobar') }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'purge_hosts' do
          before { params.merge!(purge_hosts: 'foobar') }

          it { is_expected.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
