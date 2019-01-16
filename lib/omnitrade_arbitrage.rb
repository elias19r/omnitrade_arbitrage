require 'rubygems'
require 'bundler/setup'
require 'dotenv'

$app_env = ENV['APP_ENV'] || 'staging'

$app_env_styled = $app_env == 'production' ? "\e[41;1;97m" : "\e[42;1;97m"
$app_env_styled += " #{$app_env.upcase} \e[00m"

if $app_env == 'production'
  Dotenv.load('.env')
else
  Dotenv.load('.env.example')
end

require 'bigdecimal'
require 'bigdecimal/util'

require 'omnitrade_client'

require_relative 'omnitrade_arbitrage/asset'
require_relative 'omnitrade_arbitrage/order'
require_relative 'omnitrade_arbitrage/orderbook'
require_relative 'omnitrade_arbitrage/market'
require_relative 'omnitrade_arbitrage/arbitrage'

require_relative 'omnitrade_arbitrage/constants'
