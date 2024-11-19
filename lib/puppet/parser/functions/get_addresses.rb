# frozen_string_literal: true

#
# get_addresses.rb
#
# rubocop:disable Metrics/BlockNesting
# rubocop:disable Style/DoubleNegation
module Puppet::Parser::Functions
  newfunction(:get_addresses, type: :rvalue, doc: <<-EOS
    @param send_primary return the primary interface in the response
    @param dummy_name if present returne entries matching the dummy name
    @param send_ipv4 send IPv4 addresses
    @param send_ipv6 send IPv6 addresses
    @param join if present send the result as a joined list using this as a join string
    @return Array returns an array of IP addresses unless join is present when we return a joined string
  EOS
  ) do |args|
    send_primary = true
    dummy_name   = nil
    send_ipv4    = true
    send_ipv6    = true
    join         = nil
    if args.size > 5
      raise(Puppet::ParseError, 'get_addresses(): Wrong number of arguments ' \
                                "given (#{args.size} for <=5 )")
    end
    unless args.empty?
      dummy_name = args[0]
      raise(Puppet::ParseError, "get_addresses(): arg 1 (#{dummy_name} must be string ") \
        unless dummy_name.is_a?(String) || dummy_name.is_a?(Array)
    end
    if args.size > 1
      send_primary = args[1]
      raise(Puppet::ParseError, "get_addresses(): arg 2 (#{send_primary} must be boolean ") unless !!send_primary == send_primary
    end
    if args.size > 2
      send_ipv4 = args[2]
      raise(Puppet::ParseError, "get_addresses(): arg 3 (#{send_ipv4} must be boolean ") unless !!send_ipv4 == send_ipv4
    end
    if args.size > 3
      send_ipv6 = args[3]
      raise(Puppet::ParseError, "get_addresses(): arg 4 (#{send_ipv6} must be boolean ") unless !!send_ipv6 == send_ipv6
    end
    if args.size > 4
      join = args[4]
      raise(Puppet::ParseError, "get_addresses(): arg 5 (#{join} must be String ") unless join.is_a?(String)
    end

    Puppet::Parser::Functions.autoloader.load(:hiera) unless Puppet::Parser::Functions.autoloader.loaded?(:hiera)
    addresses              = []
    ipv6_capable           = lookupvar('ipv6_capable')
    ipv4_capable           = lookupvar('ipv4_capable')
    ipv4_primary_interface = lookupvar('ipv4_primary_interface')
    ipv6_primary_interface = lookupvar('ipv6_primary_interface')
    dummy4                 = call_function('hiera', ['network::dummy4', {}])
    dummy6                 = call_function('hiera', ['network::dummy6', {}])
    interfaces             = call_function('hiera', ['network::interfaces'])
    if send_primary
      addresses << interfaces[ipv4_primary_interface]['addr4'].split('/')[0] if ipv4_primary_interface != :undefined && !ipv4_primary_interface.nil? && ipv4_capable && send_ipv4 && interfaces.key?(ipv4_primary_interface) && interfaces[ipv4_primary_interface].key?('addr4')
      addresses << interfaces[ipv6_primary_interface]['addr6'].split('/')[0] if ipv6_primary_interface != :undefined && !ipv6_primary_interface.nil? && ipv6_capable && send_ipv6 && interfaces.key?(ipv6_primary_interface) && interfaces[ipv6_primary_interface].key?('addr6')
    end
    if dummy_name
      if dummy4 != :undefined && !dummy4.nil? && ipv4_capable && send_ipv4
        if dummy_name.is_a?(String)
          if dummy4.key?(dummy_name)
            if dummy4[dummy_name].is_a?(String)
              addresses << dummy4[dummy_name].split('/')[0]
            elsif dummy4[dummy_name].is_a?(Array)
              dummy4[dummy_name].each do |addr|
                addresses << addr.split('/')[0]
              end
            end
          end
        else
          dummy_name.each do |name|
            next unless name.is_a?(String)

            if dummy4.key?(name)
              if dummy4[name].is_a?(String)
                addresses << dummy4[name].split('/')[0]
              elsif dummy4[name].is_a?(Array)
                dummy4[name].each do |addr|
                  addresses << addr.split('/')[0]
                end
              end
            end
          end
        end
      end
      if dummy6 != :undefined && !dummy6.nil? && ipv6_capable && send_ipv6
        if dummy_name.is_a?(String)
          if dummy6.key?(dummy_name)
            if dummy6[dummy_name].is_a?(String)
              addresses << dummy6[dummy_name].split('/')[0]
            elsif dummy6[dummy_name].is_a?(Array)
              dummy6[dummy_name].each do |addr|
                addresses << addr.split('/')[0]
              end
            end
          end
        else
          dummy_name.each do |name|
            next unless name.is_a?(String)

            if dummy6.key?(name)
              if dummy6[name].is_a?(String)
                addresses << dummy6[name].split('/')[0]
              elsif dummy6[name].is_a?(Array)
                dummy6[name].each do |addr|
                  addresses << addr.split('/')[0]
                end
              end
            end
          end
        end
      end
    end
    if join
      addresses.join(join)
    else
      addresses
    end
  end
end
# rubocop:enable Metrics/BlockNesting
# rubocop:enable Style/DoubleNegation
