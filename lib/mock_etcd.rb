require 'mock_etcd/version'
require 'mock_etcd/client'

module MockEtcd
  def self.client(opts = {})
    MockEtcd::Client.new(opts) do |config|
      yield config if block_given?
    end
  end
end
