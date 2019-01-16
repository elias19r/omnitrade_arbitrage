module OmnitradeArbitrage
  class Asset
    attr_reader :symbol,
                :scale,
                :min_unit,
                :max_trade_amount,
                :min_trade_amount,
                :min_profit_amount

    def initialize(symbol,
                   scale,
                   min_unit,
                   max_trade_amount,
                   min_trade_amount,
                   min_profit_amount)
      @symbol   = symbol
      @scale    = scale
      @min_unit = min_unit
      @max_trade_amount  = max_trade_amount
      @min_trade_amount  = min_trade_amount
      @min_profit_amount = min_profit_amount
    end

    def to_s
      @symbol.to_s
    end

    def upcase
      to_s.upcase
    end

    def number_format
      "%.#{@scale}f"
    end

    def info
      "symbol=#{@symbol.ljust(4)}|"\
      "scale=#{@scale}|"\
      "min_unit=#{sprintf(number_format, @min_unit).ljust(10)}|"\
      "max_trade_amount=#{sprintf(number_format, @max_trade_amount).ljust(10)}|"\
      "min_trade_amount=#{sprintf(number_format, @min_trade_amount).ljust(10)}|"\
      "min_profit_amount=#{sprintf(number_format, @min_profit_amount).ljust(10)}"
    end
  end
end
