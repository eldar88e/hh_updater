class Bot
  def initialize
    @token = ENV.fetch('TELEGRAM_TOKEN')
  end

  def run(try=5)
    Telegram::Bot::Client.run(@token) do |bot|
      bot.listen do |message|
        case message
        when Telegram::Bot::Types::CallbackQuery
          
        when Telegram::Bot::Types::Message
          handle_message(bot, message)
        else
          bot.api.send_message(chat_id: message.from.id, text: "Не верные данные!")
        end
      end
    end
  rescue => e
    try -= 1
    puts e.message
    sleep 5
    retry if try > 0
  end

  private

  def handle_message(bot, message)
    case message.text
    when '/start'
      bot.api.send_message(chat_id: message.chat.id, text: 'Hello!')
      #send_keyboard(bot, message.chat.id)
    when '/upd_resume'
      bot.api.send_message(chat_id: message.chat.id, text: 'Updating resume...')
      parser = Parser.new
      parser.update_resume
    else
      bot.api.send_message(chat_id: message.chat.id, text: 'Не верный текст!')
    end
  end
end
