module Clearsale
  class OrderResponse
    STATUS_MAP = {
      "APA" => :approved,
      "PAV" => :approval_pending,
      "APQ" => :approved_by_survey,
      "RPQ" => :rejected_by_survey,
      "RPP" => :rejected_by_policy,
      "RPA" => :rejected
    }

    attr_reader :order_id, :status, :score, :transaction_id, :quiz_url, :status_code, :xml, :name

    def self.build_from_send_order(package, xml)
      new(package.fetch(:package_status, {}), xml)
    end

    def self.build_from_update(package)
      new(package.fetch(:clear_sale, {}))
    end

    def initialize(hash, xml = nil)
      @xml = xml
      @name = 'cleasale'
      response = hash.fetch(:orders, {}).fetch(:order, {})
      if response.blank?
          @status_code = hash[:status_code]
        if hash && hash[:status_code] == "05"
          @status = :order_already_exists
        else
          @status = :inexistent_order
        end
      else
        @order_id = response[:id].gsub(/[a-zA-Z]*/, '').to_i
        @score    = response[:score].to_f
        @quiz_url = response[:quiz_url]
        @status   = STATUS_MAP[response[:status]]
      end
    end

    def approved?
      @status == :approved || @status == :approved_by_survey
    end

    def rejected?
      @status == :rejected_by_survey || @status == :rejected_by_policy || @status == :rejected
    end

    def pending?
      @status == :approval_pending
    end
  end
end
