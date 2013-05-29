# -*- coding: utf-8 -*-

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'vnmgr'
require 'rack/cors'
require 'dcell'

config_dir="/etc/wakame-vnet/"
conf = Vnmgr::Endpoints::V10::VNetAPI.load_conf(File.join(config_dir, 'common.conf'), File.join(config_dir, 'vnmgr.conf')

if defined?(::Unicorn)
  require 'unicorn/oob_gc'
  use Unicorn::OobGC
end

if conf.data_access_proxy == :dba
  DCell.start(:id => conf.node_name, :addr => "tcp://#{conf.ip}:#{conf.port}",
  :registry => {
    :adapter => 'redis',
    :host => conf.redis_host,
    :port => conf.redis_port
  })
end

map '/api' do
  use Rack::Cors do
    allow do
      origins '*'
      resource '*', :headers => :any, :methods => [:get, :post, :put, :delete, :options]
    end
  end

  run Vnmgr::Endpoints::V10::VNetAPI.new
end
