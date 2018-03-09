require 'builder'
require 'ostruct'

module Clearsale
  class Order
    CARD_TYPE_MAP = {
      :visa       => 3,
      :mastercard => 2
    }
    def self.to_xml(order, payment, user)
      puts 'clearsale-chmatos 1.0.13b'
      builder = Builder::XmlMarkup.new(:indent => 2, :encoding => 'utf-8')
      xml = builder.tag!("ClearID_Input") do |b|
        builder.tag!('SessionID', order.session_id)
        b.tag!('Pedido') do |b|
          build_order(b, order, payment, user)
        end
      end
      puts '----------------------------------'
      puts xml.to_s
      puts '----------------------------------'
      xml.to_s
    end

    def self.build_order(builder, order, payment, user)
      builder.tag!('PedidoID', order[:id])
      builder.tag!('Data', order.created_at.strftime("%Y-%m-%dT%H:%M:%S"))
      builder.tag!('Email', user[:email])
      builder.tag!('CanalID', 'Badoda') #
      builder.tag!('B2B_B2C', 'B2C') #
      builder.tag!('ValorTotalItens', order.total_items)
      builder.tag!('ValorTotalPedido', order.total_order)
      builder.tag!('QtdParcelas', order.installments)
      builder.tag!('QtdItens', order.items_count)
      builder.tag!('IP', user.last_sign_in_ip)

      builder.tag!('DadosCobranca') do |b|
        build_user_data(b, user, order.billing_address)
      end

      if order.shipping_address.present?
        builder.tag!('DadosEntrega') do |b|
          build_user_data(b, user, order.shipping_address)
        end
      end

      builder.tag!('Pagamentos') do |b|
        build_payment_data(b, order, payment, user)
      end

      if order.order_items.present?
        builder.tag!('Itens') do |b|
          order.order_items.each do |order_item|
            build_item(b, order_item)
          end
        end
      end
    end

    def self.build_user_data(builder, user, billing_address)
      builder.tag!('UsuarioID', user.id)
      builder.tag!('TipoUsuario', 1) # Pessoa Física
      builder.tag!('DocumentoLegal1', user.cpf.present? ? user.cpf.gsub(/[\.\-]*/, '').strip : nil)
      builder.tag!('Nome', user.full_name)
      builder.tag!('Email', user.email)
      builder.tag!('Sexo', user.gender&.downcase)
      builder.tag!('Nascimento', user.birthdate.to_time.strftime("%Y-%m-%dT%H:%M:%S")) if user.birthdate.present?
      build_address(builder, billing_address) if billing_address.present?
      builder.tag!('Telefones') do |b|
        build_phone(b, user)
      end
    end

    def self.build_address(builder, address)
      builder.tag!('Endereco') do |b|
        builder.tag!('Logradouro', address[:street_name])
        builder.tag!('Complemento', address[:complement])
        builder.tag!('Numero', address[:number])
        builder.tag!('Bairro', address[:neighborhood])
        builder.tag!('Cidade', address[:city])
        builder.tag!('UF', address[:state])
        builder.tag!('CEP', address[:postal_code])
        builder.tag!('Pais', address[:country])
      end
    end

    def self.build_collection_address(builder, address)
      builder.tag!('EnderecoCobranca') do |b|
        builder.tag!('Logradouro', address[:street_name])
        builder.tag!('Complemento', address[:complement])
        builder.tag!('Numero', address[:number])
        builder.tag!('Bairro', address[:neighborhood])
        builder.tag!('Cidade', address[:city])
        builder.tag!('UF', address[:state])
        builder.tag!('CEP', address[:postal_code])
        builder.tag!('Pais', 'Brasil')
      end
    end

    def self.build_phone(builder, user)
      if user.phone.present?
        stripped_phone = user.phone.present? ? user.phone.gsub(/\(*\)*\s*\-*/, '') : nil
        builder.tag!('Telefone') do |b|
          b.tag!('Tipo', user.phone_type || 0) # 0=Undefined
          b.tag!('DDD', stripped_phone.present? ? stripped_phone[0..1] : nil)
          b.tag!('Numero', stripped_phone.present? ? stripped_phone[2..-1] : nil)
        end
      end
    end

    def self.build_payment_data(builder, order, payment, user)
      builder.tag!('Pagamento') do |b|
        paid_at = order.paid_at || Time.current
        b.tag!('Data', paid_at.strftime("%Y-%m-%dT%H:%M:%S"))
        b.tag!('Valor', payment.amount)
        b.tag!('TipoPagamentoID', 1) # 1=credit_card
        b.tag!('QtdParcelas', order.installments)
        b.tag!('HashNumeroCartao', payment.card_hash.present? ? Digest::SHA1.hexdigest(payment.card_hash) : '')
        b.tag!('BinCartao', payment.card_number.present? ? payment.card_number[0..5] : payment.card_bin)
        b.tag!('Cartao4Ultimos', payment.card_number.present? ? payment.card_number.reverse[0..3] : payment.card_final)
        b.tag!('TipoCartao', CARD_TYPE_MAP.fetch(payment.acquirer.to_sym, 4)) # Failover is 'outros'
        b.tag!('DataValidadeCartao', payment.card_expiration)
        b.tag!('NomeTitularCartao', payment.customer_name)
        b.tag!('DocumentoLegal1', user.cpf.present? ? user.cpf.gsub(/[\.\-]*/, '').strip : nil)
        build_collection_address(b, order.billing_addre if order.billing_address.present?
      end
    end

    def self.build_item(builder, order_item)
      builder.tag!('Item') do |b|
        # b.tag!('CodigoItem', order_item[:product][:product_id])
        b.tag!('NomeItem', order_item[:product][:name])
        # b.tag!('ValorItem', order_item[:price])
        # b.tag!('Quantidade', order_item[:quantity])
        # b.tag!('CodigoCategoria', order_item[:product][:category].category_id) if order_item[:product][:category].try(:category_id).present?
        # b.tag!('NomeCategoria', order_item[:product][:category].name) if order_item[:product][:category].try(:name).present?
      end
    end
  end
end
