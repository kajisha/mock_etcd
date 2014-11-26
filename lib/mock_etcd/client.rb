require 'webmock'
require 'etcd/client'

module MockEtcd
  class Client < Etcd::Client
    include WebMock::API

    attr_reader :nodes

    def initialize(opts = {})
      @index = 0
      @nodes = {}

      WebMock.disable_net_connect! allow_localhost: false

      super
    end

    def api_execute(path, method, options = {})
      stub_request! path, method, options

      super
    end

    private

    def stub_request!(path, method, options)
      key = path.split(key_endpoint).last

      case method
      when :get
        stub_get_request key, path, options
      when :post
        stub_post_request key, path, options
      when :put
        stub_put_request key, path, options
      when :delete
        stub_delete_request key, path, options
      end
    end

    def stub_get_request(key, path, options)
      node = find_node(key)
      stub_key_not_found(:get, key, path) and return unless node

      stub_request(:get, uri(path))
        .to_return(status: 200, body: response_body('get', key, node), headers: response_header(node))
    end

    def stub_post_request(key, path, options)
      node = create_node_with_index(key, options[:params][:value])

      stub_request(:post, uri(path))
        .with(body: 'value=' + URI.encode_www_form([options[:params][:value]]))
        .to_return(status: 201, body: response_body('create', key, node), headers: response_header(node))
    end

    def stub_put_request(key, path, options)
      node = create_node(key, options[:params][:value])

      stub_request(:put, uri(path))
        .with(body: 'value=' + URI.encode_www_form([options[:params][:value]]))
        .to_return(status: 200, body: response_body('set', key, node), headers: response_header(node))
    end

    def stub_delete_request(key, path, options)
      node = destroy_node(key)
      stub_key_not_found(:delete, key, path) and return unless node

      stub_request(:delete, uri(path))
        .to_return(status: 200, body: response_body('delete', key, node), headers: response_header(node))
    end

    def stub_key_not_found(method, key, path)
      stub_request(method, uri(path))
        .to_return(status: 404, headers: {'X-Etcd-Index' => @index}, body: response_key_not_found(key))
    end

    def find_node(key)
      @nodes[key]
    end

    def create_node(key, value)
      next_index!

      node = {
        'key' => key,
        'value' => value,
        'modifiedIndex' => @index,
        'createdIndex' => @index
      }

      @nodes[key] = node
    end

    def create_node_with_index(key, value)
      next_index!

      node = {
        'key' => "#{key}/#{@index}",
        'value' => value,
        'modifiedIndex' => @index,
        'createdIndex' => @index
      }

      if @nodes.has_key?(key)
        @nodes[key] << node
      else
        @nodes[key] = [node]
      end

      node
    end

    def destroy_node(key)
      if node = find_node(key)
        node['value'] = nil
      end

      @nodes.delete(key)
    end

    def next_index!
      @index = @index + 1
    end

    def uri(path)
      "http://#{host}:#{port}#{path}"
    end

    def response_body(action, key, node)
      if node.is_a?(Array)
        {
          'action' => action,
          'node' => {
            'key' => key,
            'dir' => true,
            'nodes' => node
          },
          'modifiedIndex' => node.first['modifiedIndex'],
          'createdIndex' => node.first['createdIndex']
        }.to_json
      else
        {
          'action' => action,
          'node' => node
        }.to_json
      end
    end

    def response_key_not_found(key)
      {
        'errorCode' => 100,
        'message' => 'Key not found',
        'cause' => key,
        'index' => @index
      }.to_json
    end

    # FIXME Raft index and Raft term.
    def response_header(node)
      node = node.is_a?(Array) ? node.last : node

      {
        'Content-Type' => 'application/json',
        'X-Etcd-Index' => node['createdIndex'],
        'X-Raft-Index' => 300000 * rand,
        'X-Raft-Term' => 4
      }
    end
  end
end
