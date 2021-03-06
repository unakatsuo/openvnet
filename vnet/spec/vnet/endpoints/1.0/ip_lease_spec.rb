# -*- coding: utf-8 -*-

require 'spec_helper'
require 'vnet'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe '/ip_leases' do
  before(:each) { use_mock_event_handler }

  let(:api_suffix)  { 'ip_leases' }
  let(:fabricator)  { :ip_lease }
  let(:model_class) { Vnet::Models::IpLease }

  include_examples 'GET /'
  include_examples 'GET /:uuid'
  include_examples 'DELETE /:uuid'

  describe 'DELETE /uuid' do
    describe 'event handler' do
      let!(:object) { Fabricate(fabricator) }
      let(:request_params) { object }

      it 'handles a single event' do
        delete "ip_leases/#{object.canonical_uuid}"
        expect(last_response).to succeed
        expect(MockEventHandler.handled_events.size).to eq 1
      end
    end
  end

  describe 'PUT /' do
    accepted_params = {
      :enable_routing => true,
    }
    uuid_params = []

    include_examples 'PUT /:uuid', accepted_params, uuid_params
  end

  describe 'POST /' do
    let!(:interface) { Fabricate(:interface, uuid: 'if-test') }
    let!(:mac_lease) { Fabricate(:mac_lease_free, uuid: 'ml-test', interface: interface) }
    let!(:network) { Fabricate(:network) { uuid 'nw-test' } }

    accepted_params = {
      :uuid => 'il-lease',
      :interface_uuid => 'if-test',
      :mac_lease_uuid => 'ml-test',
      :network_uuid => 'nw-test',
      :ipv4_address => '192.168.1.10',
      :enable_routing => true,
    }
    required_params = [:network_uuid, :ipv4_address]
    uuid_params = [:uuid, :interface_uuid, :mac_lease_uuid, :network_uuid,]

    include_examples 'POST /', accepted_params, required_params, uuid_params

    describe 'event handler' do
      let(:request_params) { accepted_params }

      it 'handles expected events' do
        expect(last_response).to succeed
        expect(MockEventHandler.handled_events.size).to eq 2
      end
    end
  end

  describe 'PUT /:uuid/attach' do
    let(:api_postfix)  { 'attach' }

    let(:fabricator)  { :ip_lease_free }

    let!(:interface) { Fabricate(:interface, uuid: 'if-test') }
    let!(:mac_lease) { Fabricate(:mac_lease_free, uuid: 'ml-test', interface: interface) }

    accepted_params = {
      interface_uuid: 'if-test',
      mac_lease_uuid: 'ml-test'
    }
    required_params = [:interface_uuid]

    include_examples 'PUT /:uuid/postfix', accepted_params, required_params
  end

end
