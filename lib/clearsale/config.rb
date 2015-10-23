require 'savon'
require 'nori'

module Clearsale
  class Config
    cattr_accessor :logger, :log, :read_timeout, :open_timeout, :entity_code, :env

    def self.logger
      @@logger ||= Logger.new(STDOUT)
    end

    def self.log
      @@log.nil? ? true : @@log
    end

    def self.entity_code
      @@entity_code.nil? || ENV['CLEARSALE_ENTITYCODE']
    end

    def self.env
      @@entity_code.nil? || ENV['CLEARSALE_ENTITYCODE']
    end
  end
end
