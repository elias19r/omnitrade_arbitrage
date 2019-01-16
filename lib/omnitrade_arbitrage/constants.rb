module OmnitradeArbitrage
  OMNITRADE_PUBLIC  = OmniTradeAPI::Client.new(
    endpoint: ENV['ENDPOINT']
  )

  OMNITRADE_PRIVATE = OmniTradeAPI::Client.new(
    access_key: ENV['MEMBER_ACCESS_KEY'],
    secret_key: ENV['MEMBER_SECRET_KEY'],
    endpoint:   ENV['ENDPOINT']
  )

  ASSETS = ENV['ASSETS'].gsub(/[[:space:]]/, '').split(',').map do |str|
    fields = str.split('|')

    name     = fields[0].to_sym
    symbol   = fields[0].downcase
    scale    = fields[1].to_i
    min_unit = fields[2].to_d
    max_trade_amount  = fields[3].to_d
    min_trade_amount  = fields[4].to_d
    min_profit_amount = fields[5].to_d

    asset = Asset.new(symbol, scale, min_unit,
                      max_trade_amount, min_trade_amount, min_profit_amount)
    Object.const_set(name, asset)

    asset
  end

  MARKETS = ENV['MARKETS'].gsub(/[[:space:]]/, '').split(',').map do |str|
    fields = str.split('|')

    name = fields[0].sub('/', '').to_sym
    base_asset  = Object.const_get(fields[0].split('/')[0].to_sym)
    quote_asset = Object.const_get(fields[0].split('/')[1].to_sym)
    price_scale  = fields[1].to_i
    amount_scale = fields[2].to_i
    bid_fee = fields[3].to_d
    ask_fee = fields[4].to_d

    market = Market.new(base_asset, quote_asset, price_scale, amount_scale,
                        bid_fee, ask_fee)
    Object.const_set(name, market)

    market
  end

  TARGET_ASSETS = ENV['TARGET_ASSETS'].gsub(/[[:space:]]/, '').split(',').map do |str|
    Object.const_get(str.to_sym)
  end

  ACTIONS = ENV['ACTIONS'].gsub(/[[:space:]]/, '').split(',').map(&:to_sym)

  SLEEP_SECONDS = ENV['SLEEP_SECONDS'].to_i

  POST_ORDERS = ENV['POST_ORDERS'].to_s.match?(/true|yes/i)

  APPLY_FEES = ENV['APPLY_FEES'].to_s.match?(/true|yes/i)

  NOTIFY_SEND = ENV['NOTIFY_SEND'].to_s.match?(/true|yes/i)

  ZERO = '0.0'.to_d
  ONE  = '1.0'.to_d

  puts "APP_ENV:       #{$app_env_styled}"
  puts "TARGET_ASSETS: #{TARGET_ASSETS.map(&:upcase)}"
  puts "ACTIONS:       #{ACTIONS.map(&:to_s)}"
  puts "SLEEP_SECONDS: #{SLEEP_SECONDS}"
  puts "POST_ORDERS:   #{POST_ORDERS}"
  puts "APPLY_FEES:    #{APPLY_FEES}"
  puts "NOTIFY_SEND:   #{NOTIFY_SEND}"
  puts "ASSETS:"
  ASSETS.each do |a|
    puts a.info
  end
  puts "MARKETS:"
  MARKETS.each do |m|
    puts m.info
  end
end
