# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class Datapath < Vnet::Endpoints::ResponseGenerator
    def self.generate(datapath)
      argument_type_check(datapath, Vnet::ModelWrappers::Datapath)
      res = datapath.to_hash
      res[:ipv4_address] = datapath.ipv4_address_s
      res
    end

    def self.networks(object)
      argument_type_check(object,Vnet::ModelWrappers::Datapath)
      {
        :uuid => object.uuid,
        :networks => DatapathNetworkCollection.generate(
          object.batch.datapath_networks.commit
        )
      }
    end
  end

  class DatapathCollection < Vnet::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i| Datapath.generate(i) }
    end
  end
end
