# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  module PortPhysical
    include Constants

    attr_accessor :hw_addr

    def flow_options
      flow_options ||= {:cookie => self.port_number | 0x100000000}
    end

    def install
      flows = []

      flows << Flow.create(TABLE_CLASSIFIER,   3, {:in_port => self.port_number, :eth_type => 0x0806}, {}, flow_options.merge(:goto_table => TABLE_ARP_ANTISPOOF))
      flows << Flow.create(TABLE_CLASSIFIER,   2, {:in_port => self.port_number}, {}, flow_options.merge(:goto_table => TABLE_PHYSICAL_DST))

      flows << Flow.create(TABLE_PHYSICAL_DST, 1, {:eth_dst => self.hw_addr}, {}, flow_options_load_port(TABLE_PHYSICAL_SRC))

      # flows << Flow.create(TABLE_PHYSICAL_SRC, 5, {:eth_src => self.hw_addr}, {}, flow_options)
      # flows << Flow.create(TABLE_PHYSICAL_SRC, 5, {:eth_type => 0x0800, :ipv4_src => IPAddr.new('192.168.60.200')}, {}, flow_options)
      # flows << Flow.create(TABLE_PHYSICAL_SRC, 4, {:in_port => self.port_number}, {}, flow_options.merge(:goto_table => TABLE_METADATA_ROUTE))

      flows << Flow.create(TABLE_PHYSICAL_SRC, 4, {
                             :in_port => self.port_number,
                             :eth_src => self.hw_addr,
                             :eth_type => 0x0800,
                             :ipv4_src => IPAddr.new('192.168.60.200')
                           }, {}, flow_options.merge(:goto_table => TABLE_METADATA_ROUTE))
      flows << Flow.create(TABLE_PHYSICAL_SRC, 3, {
                             :in_port => self.port_number,
                             :eth_src => self.hw_addr
                           }, {}, flow_options.merge(:goto_table => TABLE_METADATA_ROUTE))

      #
      # ARP routing table
      #
      flows << Flow.create(TABLE_ARP_ANTISPOOF, 1, {:in_port => self.port_number, :eth_type => 0x0806}, {}, flow_options.merge(:goto_table => TABLE_ARP_ROUTE))
      flows << Flow.create(TABLE_ARP_ROUTE, 1, {:eth_type => 0x0806, :arp_tpa => IPAddr.new('192.168.60.200')}, {:output => self.port_number}, flow_options)

      flows << Flow.create(TABLE_MAC_ROUTE,      1, {:eth_dst => self.hw_addr}, {:output => self.port_number}, flow_options)
      flows << Flow.create(TABLE_METADATA_ROUTE, 0, {:metadata => self.port_number, :metadata_mask => 0xffffffff}, {:output => self.port_number}, flow_options)

      self.datapath.add_flows(flows)
    end

  end

end