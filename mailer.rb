class Mailer
  def self.call
    new.read_mail
  end

  def read_mail
    imap     = Net::IMAP.new('imap.yandex.ru', port: 993, ssl: true)
    email    = ENV.fetch('MAIL')
    password = ENV.fetch('MAIL_PASS')
    imap.login(email, password)
    imap.select('INBOX')
    message_ids = imap.search(['UNSEEN'])

    code = nil

    message_ids.each do |message_id|
      # Получаем тело сообщения
      body = imap.fetch(message_id, "BODY[]")[0].attr["BODY[]"]

      mail = Mail.read_from_string(body)
      decoded_body = mail.body.decoded.force_encoding('UTF-8')

      # Проверяем, есть ли нужный текст в теле сообщения
      if decoded_body.match?(/ваш код для авторизации на hh.ru/) && decoded_body.match?(/<b>\d{4}<\/b>/)
        code = decoded_body.match(/<b>\d{4}<\/b>/).to_s.match(/\d+/).to_s
        break
      end
    end
    
    code  
  end
end
