# frozen_string_literal: true

# This function returns a list of IP addresses from the network::interfaces
# and network::dummy4 and network::dummy6 hiera data.
#
# @param send_primary return the primary interface in the response
# @param dummy_name if present returne entries matching the dummy name
# @param send_ipv4 send IPv4 addresses
# @param send_ipv6 send IPv6 addresses
# @param join if present send the result as a joined list using this as a join string
# @return Array returns an array of IP addresses unless join is present when we return a joined string

# @example get_addresses
#   get_addresses()
#
# @example get_addresses with dummy name
#   get_addresses('dummy_name')
#
# @example get_addresses with dummy name and send_primary
#   get_addresses('dummy_name', true)
#
# @example get_addresses with dummy name and send_primary and send_ipv4
#   get_addresses('dummy_name', true, true)
#
# @example get_addresses with dummy name and send_primary and send_ipv4 and send_ipv6
#   get_addresses('dummy_name', true, true, true)
Puppet::Functions.create_function(:'network::get_addresses') do
  dispatch :run do
    param 'Variant[Array[String[1]], String[1]]', :dummy_name
    optional_param 'Boolean', :send_primary
    optional_param 'Boolean', :send_ipv4
    optional_param 'Boolean', :send_ipv6
    optional_param 'String', :join
    return_type 'Variant[Array[String[1]], String[1]]'
  end

  def run(dummy_name, send_primary = true, send_ipv4 = true, send_ipv6 = true, join = nil)
    scope = closure_scope
    addresses              = []
    ipv6_capable           = scope['facts']['ipv6_capable']
    ipv4_capable           = scope['facts']['ipv4_capable']
    ipv4_primary_interface = scope['facts']['ipv4_primary_interface']
    ipv6_primary_interface = scope['facts']['ipv6_primary_interface']
    dummy4                 = call_function('lookup', 'network::dummy4', { 'default_value' => {} })
    dummy6                 = call_function('lookup', 'network::dummy6', { 'default_value' => {} })
    interfaces             = call_function('lookup', 'network::interfaces', { 'default_value' => {} })

    if send_primary
      addresses << interfaces[ipv4_primary_interface]['addr4'].split('/')[0] if !ipv4_primary_interface.nil? && ipv4_capable && send_ipv4 && !interfaces.dig(ipv4_primary_interface, 'addr4').nil?
      addresses << interfaces[ipv6_primary_interface]['addr6'].split('/')[0] if !ipv6_primary_interface.nil? && ipv6_capable && send_ipv6 && !interfaces.dig(ipv6_primary_interface, 'addr6').nil?
    end
    addresses << parse_dummy(dummy_name, dummy4) if ipv4_capable && send_ipv4
    addresses << parse_dummy(dummy_name, dummy6) if ipv6_capable && send_ipv6
    join.nil? ? addresses.flatten : addresses.join(join)
  end

  def parse_dummy(dummy_name, dummy)
    return [] if dummy.nil?

    addresses = []
    Array(dummy_name).each do |name|
      next unless dummy.key?(name)

      Array(dummy[name]).each do |addr|
        addresses << addr.split('/')[0]
      end
    end
    addresses
  end
end
