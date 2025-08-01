class TelegramNotify
  def initialize(message)
    @message   = message
    @chat_id   = ENV.fetch('CHAT_ID')
    @bot_token = ENV.fetch('TELEGRAM_TOKEN')
  end

  def self.call(msg)
    return if @message.nil? || @message.strip.size == 0

    new(msg).tg_send
  end

  def tg_send
    [@chat_id.to_s.split(',')].flatten.each do |user_id|
      message_limit = 4000
      message_count = @message.size / message_limit + 1
      Telegram::Bot::Client.run(@bot_token) do |bot|
        message_count.times do
          text_part = @message.chars.shift(message_limit).join
          bot.api.send_message(chat_id: user_id, text: escape(text_part), parse_mode: 'MarkdownV2')
        end
      rescue => e
        puts e.message
        binding.pry
      end
    end

    nil
  end

  private

  def escape(text)
    text.gsub(/\[.*?m/, '').gsub(/([-_*\[\]()~`>#+=|{}.!])/, '\\\\\1')
  end
end
