require 'json'
require 'active_support/all'
require 'rest_client'


module Rundeck
  class Session
    def initialize(server, token)
      @server = server
      @token = token
    end

    attr_reader :server, :token

    def get(url, *keys)
      endpoint = File.join(server, url)
      xml = RestClient.get(endpoint, 'X-Rundeck-Auth-Token'=> token)
      hash = Maybe(Hash.from_xml(xml))
      keys.reduce(hash){|acc, cur| acc && acc[cur]}
    end

    def system_info
      get('api/1/system/info', 'result', 'system')
    end

    def projects
      Project.all(self)
    end
  end
end
