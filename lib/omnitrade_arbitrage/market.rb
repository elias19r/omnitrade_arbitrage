module OmnitradeArbitrage
  class Market
    attr_reader :base_asset,
                :quote_asset,
                :price_scale,
                :amount_scale,
                :bid_fee,
                :ask_fee,
                :orderbook

    def initialize(base_asset,
                   quote_asset,
                   price_scale,
                   amount_scale,
                   bid_fee,
                   ask_fee)
      @base_asset   = base_asset
      @quote_asset  = quote_asset
      @price_scale  = price_scale
      @amount_scale = amount_scale
      @bid_fee = bid_fee
      @ask_fee = ask_fee

      @orderbook = Orderbook.new(self)
    end

    def info
      number_format = "%.#{@scale}f"

      "base_asset=#{@base_asset.to_s.ljust(4)}|"\
      "quote_asset=#{@quote_asset.to_s.ljust(4)}|"\
      "price_scale=#{@price_scale}|"\
      "amount_scale=#{@amount_scale}|"\
      "bid_fee=#{@bid_fee.to_s('F')}|"\
      "ask_fee=#{@ask_fee.to_s('F')}"
    end

    def to_s
      "#{@base_asset.to_s}#{@quote_asset.to_s}"
    end

    def symbol_pair
      "#{@base_asset.upcase}/#{@quote_asset.upcase}"
    end

    def best_bid
      @orderbook.best_bid
    end

    def best_ask
      @orderbook.best_ask
    end

    def simulate_buy_total(total)
      @orderbook.simulate_buy_total(total)
    end

    def simulate_sell_amount(amount)
      @orderbook.simulate_sell_amount(amount)
    end
  end
end
