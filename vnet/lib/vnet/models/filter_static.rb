# -*- coding: utf-8 -*-

module Vnet::Models

  # TODO: Refactor.

  class FilterStatic < Base
    plugin :paranoia_is_deleted

    many_to_one :filter
    # TODO: Association needed:

    def ipv4_src_address_s
      self.ipv4_src_address && parse_ipv4(self.ipv4_src_address)
    end

    def ipv4_dst_address_s
      self.ipv4_dst_address && parse_ipv4(self.ipv4_dst_address)
    end

    def validate
      errors.add(:ipv4_src_prefix, "out of range: '#{self.ipv4_src_prefix}'") if !(0..32).member?(self.ipv4_src_prefix)
      errors.add(:ipv4_dst_prefix, "out of range: '#{self.ipv4_dst_prefix}'") if !(0..32).member?(self.ipv4_dst_prefix)
      errors.add(:protocol, "unknown protocol: '#{self.protocol}'") if !protocol_included(["tcp", "udp", "icmp", "arp", "all"])

      if protocol_included(["tcp", "udp"])
        errors.add(:port_src, "not in valid range: '#{self.port_src}'") if !(0..0xffff).member?(self.port_src)
        errors.add(:port_dst, "not in valid range: '#{self.port_dst}'") if !(0..0xffff).member?(self.port_dst)
      elsif protocol_included(["arp", "icmp", "all"])
        errors.add(:port_src, "needs to be nil") if !self.port_src.nil?
        errors.add(:port_dst, "needs to be nil") if !self.port_dst.nil?
      elsif protocol_included(["arp", "all"])
        errors.add(:ipv4_src_address, "address needs to be 0") if (self.ipv4_src_address > 0) # needs inspection
        errors.add(:ipv4_dst_address, "address needs to be 0") if (self.ipv4_dst_address > 0) # needs inspection
      end

      errors.add(:ipv4_dst_prefix, "needs to be 0") if ipv4_dst_prefix != 0 && self.ipv4_dst_address == 0
      errors.add(:ipv4_src_prefix, "needs to be 0") if ipv4_src_prefix != 0 && self.ipv4_src_address == 0
    end

    private

    def parse_ipv4(ipv4)
      IPAddress::IPv4::parse_u32(ipv4).to_s
    end

    def protocol_included(protocols = [])
      return protocols.include? self.protocol
    end

  end

end
