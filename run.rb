require 'ferrum'
# require 'pry'
# require 'net/imap'
# require 'mail'
require 'telegram/bot'
require 'json'
require 'dotenv'
Dotenv.load

require_relative 'bot'
require_relative 'resume_updater'
require_relative 'telegram_notify'
require_relative 'response_vacancies'

# require_relative 'mailer'

if ARGV.include?("--vacancy")
  response_vacancies = ResponseVacancies.new
  response_vacancies.process
elsif ARGV.include?("--bot")
  bot = Bot.new
  bot.run
else
  resume_updater = ResumeUpdater.new
  resume_updater.process
end
