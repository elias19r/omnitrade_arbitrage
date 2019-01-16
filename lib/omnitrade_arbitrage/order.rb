module OmnitradeArbitrage
  class Order
    SIDE_BID = 'buy'
    SIDE_ASK = 'sell'

    TYPE_LIMIT  = 'limit'
    TYPE_MARKET = 'market'

    STATE_WAIT   = 'wait'
    STATE_DONE   = 'done'
    STATE_CANCEL = 'cancel'

    DEFAULT_PRICE_SCALE  = 8
    DEFAULT_AMOUNT_SCALE = 8

    attr_reader :market, # String, e.g.: xrpbtc
                :market_obj,
                :id,
                :side,
                :type,
                :price,
                :amount,
                :state

    def initialize(market, side, type, price, amount, state = STATE_WAIT, id = nil)
      if market.is_a?(Market)
        @market_obj = market
      end
      @market = market.to_s
      @side   = side
      @type   = type
      @price  = price.to_d
      @amount = amount.to_d
      @state  = state
      @id     = id
    end

    def total
      @price * @amount
    end

    def self.build_from_array(arr, market, side)
      Order.new(
        market,
        side,
        TYPE_LIMIT,
        arr[0].to_d,
        arr[1].to_d
      )
    end

    def price_scale
      if @market_obj
        market_obj.price_scale
      else
        DEFAULT_PRICE_SCALE
      end
    end

    def amount_scale
      if @market_obj
        market_obj.amount_scale
      else
        DEFAULT_AMOUNT_SCALE
      end
    end

    def price_to_s
      sprintf("%.#{price_scale}f", @price.truncate(price_scale))
    end

    def amount_to_s
      sprintf("%.#{amount_scale}f", @amount.truncate(amount_scale))
    end

    def to_s
      "#{@market.ljust(7)} | "\
      "#{@side.ljust(4)} | "\
      "price: #{price_to_s.rjust(10)} | "\
      "amount: #{amount_to_s.rjust(10)}"
    end

    def to_h
      {
        market:   @market,
        side:     @side,
        ord_type: @type,
        price:    @price.truncate(price_scale).to_s('F'),
        volume:   @amount.truncate(amount_scale).to_s('F')
      }
    end
  end
end
