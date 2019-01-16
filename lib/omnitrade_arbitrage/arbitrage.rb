module OmnitradeArbitrage
  class Arbitrage
    def self.call
      new.search_for_arbitrage_and_execute!
    end

    def initialize
      @total_profit = {}

      TARGET_ASSETS.each do |asset|
        @total_profit[asset] = ZERO
      end

      @orders = []
    end

    def to_s
      s = []
      @orders.each do |order|
        s << order.to_s
      end
      s.join("\n")
    end

    def search_for_arbitrage_and_execute!
      loop do
        @markets = []
        @assets = []
        puts "Awake!"

        TARGET_ASSETS.each do |a|
          @assets[0] = a

          case ACTIONS[0]
          when :bid
            markets0 = MARKETS.select { |m| m.quote_asset == @assets[0] }
          when :ask
            markets0 = MARKETS.select { |m| m.base_asset  == @assets[0] }
          end

          markets0.each do |m|
            @markets[0] = m

            case ACTIONS[1]
            when :bid
              case ACTIONS[0]
              when :bid then @assets[1] = @markets[0].base_asset
              when :ask then @assets[1] = @markets[0].quote_asset
              end
              markets1 = MARKETS.select { |m| m.quote_asset == @assets[1] && m.base_asset != @assets[0] }
            when :ask
              case ACTIONS[0]
              when :bid then @assets[1] = @markets[0].base_asset
              when :ask then @assets[1] = @markets[0].quote_asset
              end
              markets1 = MARKETS.select { |m| m.base_asset == @assets[1] && m.quote_asset != @assets[0] }
            end

            markets1.each do |m|
              @markets[1] = m

              case ACTIONS[2]
              when :bid
                case ACTIONS[1]
                when :bid then @assets[2] = @markets[1].base_asset
                when :ask then @assets[2] = @markets[1].quote_asset
                end
                markets2 = MARKETS.select { |m| m.quote_asset == @assets[2] && m.base_asset == @assets[0] }
              when :ask
                case ACTIONS[1]
                when :bid then @assets[2] = @markets[1].base_asset
                when :ask then @assets[2] = @markets[1].quote_asset
                end
                markets2 = MARKETS.select { |m| m.base_asset == @assets[2] && m.quote_asset == @assets[0] }
              end

              markets2.each do |m|
                @markets[2] = m

                puts 'Search again!' while search!
              end
            end
          end
        end

        puts 'Sleeping...'
        sleep SLEEP_SECONDS
      end
    end

    private

    def push(order)
      @orders << order
    end

    def search!
      return false unless @assets.size == 3 && @markets.size == 3 && ACTIONS.size == 3

      puts log_arbitrage_path

      begin
        @markets.each { |m| m.orderbook.update }
      rescue
        sleep 0.5
        return false
      end

      @initial_amount = @assets[0].max_trade_amount

      loop do
        @orders = []

        trade_amount = @initial_amount
        break unless trade_amount > 0

        ACTIONS.each_with_index do |action, i|
          case action
          when :bid
            amount, amount_gross, price = @markets[i].simulate_buy_total(trade_amount)
            push Order.new(@markets[i], Order::SIDE_BID, Order::TYPE_LIMIT, price, amount_gross)
          when :ask
            amount, _, price = @markets[i].simulate_sell_amount(trade_amount)
            push Order.new(@markets[i], Order::SIDE_ASK, Order::TYPE_LIMIT, price, trade_amount)
          end
          trade_amount = amount
        end
        @final_amount = trade_amount

        @profit = @final_amount - @initial_amount

        if @profit >= @assets[0].min_profit_amount
          notify_found
          if execute!
            @total_profit[@assets[0]] += @profit
            notify_profit
          else
            notify_fail
          end
          return true
        end

        unless @initial_amount - @assets[0].min_unit >= @assets[0].min_trade_amount
          puts log_range_amount
          puts log_initial_amount
          puts log_final_amount
          puts log_profit
          break
        end

        @initial_amount -= @assets[0].min_unit
      end

      sleep 0.5
      return false
    end

    def execute!
      return false unless @orders.size == 3

      @orders.each_with_index do |order, i|
        attempts = 10

        begin
          puts "POST Order: #{order}"
          OMNITRADE_PRIVATE.post('/api/v2/orders', order.to_h) if POST_ORDERS
          sleep 2 unless i == 2
        rescue StandardError => error
          attempts -= 1
          if attempts >= 0
            puts "error: failed to POST order: #{order}: #{error}"
            puts "Trying again..."
            sleep 1.5
            retry
          else
            puts 'Arbitrage failed... TERMINATE'
            return false
          end
        end
      end

      return true
    end

    def notify_found
      cmd = 'datetime=$(date "+%Y-%m-%d %H:%M:%S"); '\
            'notify-send "[$datetime] Found Arbitrage '\
            "#{log_arbitrage_assets}\""
      system(cmd) if NOTIFY_SEND
      puts log_found_profit
    end

    def notify_profit
      cmd = 'datetime=$(date "+%Y-%m-%d %H:%M:%S"); '\
            'notify-send "[$datetime] Profit!"'
      system(cmd) if NOTIFY_SEND
      puts log_total_profit
    end

    def notify_fail
      cmd = 'datetime=$(date "+%Y-%m-%d %H:%M:%S"); '\
            'notify-send "[$datetime] FAILED to POST Arbitrage '\
            "#{log_arbitrage_assets}\""
      system(cmd) if NOTIFY_SEND
    end

    def log_arbitrage_assets
      "#{@assets.map(&:upcase).join('/')}/#{@assets[0].upcase}"
    end

    def log_arbitrage_path
      "Arbitrage: " + @assets.each_with_index.reduce('') do |str, (asset, i)|
        str += "#{asset.upcase.ljust(4)}#{ACTIONS[i] == :bid ? ' ==> ' : ' --> '}"
      end.concat(@assets[0].upcase)
    end

    def log_range_amount
      "Range:     "\
      "#{sprintf(@assets[0].number_format, @assets[0].max_trade_amount)}"\
      ".."\
      "#{sprintf(@assets[0].number_format, @assets[0].min_trade_amount)}"\
      " #{@assets[0].upcase}"
    end

    def log_initial_amount
      "Initial:   #{sprintf(@assets[0].number_format, @initial_amount).ljust(@assets[0].scale+4)} #{@assets[0].upcase}"
    end

    def log_final_amount
      "Final:     #{sprintf(@assets[0].number_format, @final_amount).ljust(@assets[0].scale+4)} #{@assets[0].upcase}"
    end

    def log_profit
      "Profit:    #{sprintf(@assets[0].number_format, @profit).ljust(@assets[0].scale+4)} #{@assets[0].upcase}"
    end

    def log_found_profit
      str =  "========================================================================\n"
      str += "#{log_arbitrage_path}\n"
      str += "#{log_range_amount}\n"
      str += "#{log_initial_amount}\n"
      str += "#{log_final_amount}\n"
      str += "#{log_profit}\n"
      str += "Orders:\n"
      str += "#{to_s}\n"
      str += "========================================================================\n"
    end

    def log_total_profit
      str =  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"
      @total_profit.each do |asset, value|
        str += "Total Profit (#{asset.upcase.ljust(4)}): #{sprintf(asset.number_format, value)}\n"
      end
      str += "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"
    end
  end
end
