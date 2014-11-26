require 'mock_etcd/client'

module Etcd
  def self.client(opts = {})
    @client ||= MockEtcd::Client.new(opts) do |config|
      yield config if block_given?
    end
  end
end

