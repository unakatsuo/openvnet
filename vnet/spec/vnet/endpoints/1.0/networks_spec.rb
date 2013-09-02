# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'
require_relative 'shared_examples'

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/networks" do
  describe "GET /" do
    it_behaves_like "a get call without uuid", "networks", :network
  end

  describe "GET /:uuid" do
    it_behaves_like "a get call with uuid", "networks", "nw", :network
  end

  describe "POST /" do
    accepted_params = {
      :uuid => "nw-test",
      :display_name => "our test network",
      :ipv4_network => "192.168.2.0",
      :ipv4_prefix => 24,
      :domain_name => "vdc.test.domain",
      :network_mode => "virtual",
      :editable => false
    }
    required_params = [:display_name, :ipv4_network]

    it_behaves_like "a post call", "networks", accepted_params, required_params
  end

  describe "DELETE /:uuid" do
    it_behaves_like "a delete call", "networks", "nw", :network, :Network
  end

  describe "PUT /:uuid" do
    accepted_params = {
      :display_name => "our new name for the test network",
      :ipv4_network => "10.0.0.2",
      :ipv4_prefix => 8,
      :domain_name => "new.vdc.test.domain",
      :network_mode => "physical",
      :editable => true
    }

    it_behaves_like "a put call", "networks", "nw", :network,
      accepted_params
  end

end
