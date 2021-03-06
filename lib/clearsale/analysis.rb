 module Clearsale
  class Analysis
    def self.connector
      @connector ||= Clearsale::Connector.build
    end

    def self.send_order(order_hash, payment_hash, user_hash)
      order = Object.new(order_hash)
      payment = Object.new(payment_hash)
      user = Object.new(user_hash)

      order_xml = Clearsale::Order.to_xml(order, payment, user)
      request = {"xml" => order_xml}

      OrderResponse.build_from_send_order(connector.do_request('SendOrders', request), order_xml)
    end

    def self.clear_connector
      @connector = nil
    end

    def self.get_order_status(order_id)
      request = {'orderID' => order_id}
      OrderResponse.build_from_update(connector.do_request('GetOrderStatus', request))
    end
  end
end
