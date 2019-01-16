module OmnitradeArbitrage
  class ErrNoResponse < StandardError; end
  class ErrEmptyBids  < StandardError; end
  class ErrEmptyAsks  < StandardError; end

  class Orderbook
    attr_reader :market,
                :bid_orders,
                :ask_orders

    def initialize(market)
      @market = market

      @bid_orders = []
      @ask_orders = []
    end

    def update
      begin
        response = OMNITRADE_PUBLIC.get_public(
          '/api/v2/depth',
          market: @market.to_s,
          bids_limit: 20,
          asks_limit: 20
        )
        raise ErrNoResponse unless response

        @bid_orders = []
        @ask_orders = []

        response['bids'].each do |arr|
          @bid_orders << Order.build_from_array(arr, @market, Order::SIDE_BID)
        end

        response['asks'].each do |arr|
          @ask_orders << Order.build_from_array(arr, @market, Order::SIDE_ASK)
        end
        # /api/v2/depth API returns asks array in reversed order.
        @ask_orders.reverse!

        raise ErrEmptyBids if @bid_orders.empty?
        raise ErrEmptyAsks if @ask_orders.empty?

      rescue StandardError => error
        puts "error: failed to update #{market.symbol_pair} orderbook: #{error.to_s[0..120]}..."
        raise error
      end
    end

    def best_bid
      @bid_orders.first
    end

    def best_ask
      @ask_orders.first
    end

    def simulate_buy_total(total)
      amount = ZERO
      price  = best_ask.price

      @ask_orders.each do |order|
        price = order.price
        if total <= order.total
          amount += (total / order.price).truncate(@market.amount_scale)
          break
        else
          total  -= order.total
          amount += order.amount
        end
      end

      amount_gross = amount
      amount = amount_gross*(ONE - @market.bid_fee) if APPLY_FEES

      amount_gross = amount_gross.truncate(@market.amount_scale)
      amount = amount.truncate(@market.amount_scale)

      [amount, amount_gross, price]
    end

    def simulate_sell_amount(amount)
      total = ZERO
      price = best_bid.price

      @bid_orders.each do |order|
        price = order.price
        if amount <= order.amount
          total += amount * order.price
          break
        else
          amount -= order.amount
          total  += order.total
        end
      end

      total_gross = total
      total = total_gross*(ONE - @market.ask_fee) if APPLY_FEES

      total_gross = total_gross.truncate(@market.price_scale)
      total = total.truncate(@market.price_scale)

      [total, total_gross, price]
    end
  end
end
