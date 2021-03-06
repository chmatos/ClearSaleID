require 'savon'
require 'nori'

module Clearsale
  class Connector
    NAMESPACE =  "http://www.clearsale.com.br/integration"

    URLs = {
      "homolog"    => 'http://homologacao.clearsale.com.br/integracaov2/service.asmx',
      "production" => 'https://integracao.clearsale.com.br/service.asmx'
    }

    def self.build(env = Clearsale::Config.env)
      url = URLs[env]
      proxy = Clearsale::Config.proxy
      new url, proxy
    end

    def initialize(endpoint_url, proxy=nil)
      @token = Clearsale::Config.entity_code

      namespaces = {
          'xmlns:soap' => "http://www.w3.org/2003/05/soap-envelope",
          'xmlns:xsd'  => "http://www.w3.org/2001/XMLSchema" ,
          'xmlns:xsi'  => "http://www.w3.org/2001/XMLSchema-instance" ,
          'xmlns:int'  => "http://www.clearsale.com.br/integration",
      }

      savon_options = {:endpoint => endpoint_url, :namespace => NAMESPACE,
                       :namespaces => namespaces, :convert_request_keys_to => :snakecase }

      savon_options[:proxy]  = proxy if proxy
      savon_options[:log]    = Clearsale::Config.log
      savon_options[:logger] = Clearsale::Config.logger
      savon_options[:read_timeout] = Clearsale::Config.read_timeout if Clearsale::Config.read_timeout.present?
      savon_options[:open_timeout] = Clearsale::Config.open_timeout if Clearsale::Config.open_timeout.present?

      @client = Savon.client(savon_options)
    end

    def do_request(method, request)
      namespaced_request = append_namespace('int', request)
      arguments = namespaced_request.merge({'int:entityCode' => @token})

      response = @client.call(method, :message => arguments, :soap_action => "#{NAMESPACE}/#{method}")

      extract_response_xml(method, response.to_hash)
    end

    def extract_response_xml(method, response)
      results = response.fetch(:"#{method.snakecase}_response", {})
      response_xml = results.fetch(:"#{method.snakecase}_result", {}).to_s

      Nori.new(:parser => :nokogiri, :convert_tags_to => lambda { |tag| tag.snakecase.to_sym }).parse(response_xml.gsub(/^<\?xml.*\?>/, ''))
    end

    def append_namespace(namespace, hash)
      Hash[hash.map {|key, value| ["#{namespace}:#{key}", value]}]
    end
  end
end
