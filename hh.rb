require 'ferrum'
# require 'pry'
# require 'net/imap'
# require 'mail'
# require 'telegram/bot'
require 'json'
require 'dotenv'
Dotenv.load

# require_relative 'bot'
require_relative 'parser'
# require_relative 'telegram_notify'
# require_relative 'mailer'

# bot = Bot.new
# bot.run

parser = Parser.new
parser.process
