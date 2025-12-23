class Bot
  def initialize
    @token = ENV.fetch('TELEGRAM_TOKEN')
  end

  def run(try=5)
    Telegram::Bot::Client.run(@token) do |bot|
      bot.listen do |message|
        case message
        # when Telegram::Bot::Types::CallbackQuery
        when Telegram::Bot::Types::Message
          handle_message(bot, message) if message.from.id == ENV.fetch('CHAT_ID').to_i
        else
          bot.api.send_message(chat_id: message.from.id, text: 'Не верные данные!')
        end
      end
    end
  rescue => e
    try -= 1
    puts e.message
    sleep 5
    try > 0 ? retry : raise(e)
  end

  private

  def handle_message(bot, message)
    chat_id = ENV.fetch('CHAT_ID').to_i # message.from.id
    if !message.text
      bot.api.send_message(chat_id: chat_id, text: 'Не верные данные!')
      return
    end

    case message.text
    when '/start'
      bot.api.send_message(chat_id: chat_id, text: 'Hello!')
      #send_keyboard(bot, message.chat.id)
    when '/upd_resume'
      bot.api.send_message(chat_id: chat_id, text: 'Updating resume...')
      resume_updater = ResumeUpdater.new
      resume_updater.process
      bot.api.send_message(chat_id: chat_id, text: 'Updating process end.')
    when '/response_vacancy'
      bot.api.send_message(chat_id: chat_id, text: 'Click vacancies...')
      response_vacancies = ResponseVacancies.new
      response_vacancies.process
    else
      msg = 'Не верный текст!'
      msg += "\n\nВведите текст:\n/response_vacancy - Откликнуться на вакансии\n/upd_resume - Обновить резюме"
      bot.api.send_message(chat_id: chat_id, text: msg)
    end
  end
end
