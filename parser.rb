class Parser
  LINKS_AFTER_LOGIN = [
    'https://hh.ru/applicant/negotiations',
    'https://hh.ru',
    'https://hh.ru/services?hhtmFrom=main&hhtmFromLabel=header',
    'https://hh.ru/applicant/favorite_vacancies?hhtmFrom=main&hhtmFromLabel=header'
  ]

  LINKS_BEFORE_LOGIN = [
    'https://hh.ru',
    'https://hh.ru/search/vacancy?text=ruby+on+rails&salary=&ored_clusters=true&area=1&hhtmFrom=vacancy_search_list&hhtmFromLabel=vacancy_search_line',
    'https://hh.ru/services?hhtmFrom=main',
    'https://hh.ru/search/vacancy?text=ruby&area=1&hhtmFrom=main&hhtmFromLabel=vacancy_search_line'
  ]

  def initialize
    @browser = Ferrum::Browser.new(
      process_timeout: 20,
      #headless: false
      #browser_path: "/snap/bin/chromium"
    )
  end

  def update_resume
    cookies = load_cookies("cookies.json")
    @browser.goto('https://hh.ru')
    (login_with_code || return) unless cookies # login_with_pass

    save_cookies("cookies.json")
    sleep rand(1...3)
    @browser.goto(LINKS_AFTER_LOGIN.sample)
    sleep rand(3...5)
    begin
      my_resume_link = @browser.at_css('a[data-qa="mainmenu_myResumes"]')
      if my_resume_link.nil?
        my_resume_link = @browser.at_css('a[data-qa="mainmenu_myResumes"]')
        sleep rand(5..7)
      end

      if my_resume_link.nil? && @browser.at_css('a[data-qa="mainmenu_applicantProfile"]').nil?
        binding.pry
        login_with_code
        save_cookies("cookies.json")
      end
      my_resume_link.click
    rescue => e
      @browser.goto(LINKS_AFTER_LOGIN.sample)
      wait = rand(1..3)
      TelegramNotify.call "Ошибка: #{e.message}.\nВечная загрузка...\nЖдем #{wait} сек..."
      sleep wait
      retry
    end
    sleep rand(1..3)

  try = 0
  begin
    resume_upd_btn = @browser.at_css('button[data-qa="resume-update-button_actions"]')
    sleep rand(0.3...0.9)
    @browser.evaluate("window.scrollBy(0, 800);")
    if resume_upd_btn.inner_text.match?(/автоматически/)
      TelegramNotify.call 'Еще не пришло время.'
    else
      sleep rand(5...8)
      resume_upd_btn.click
      sleep rand(1...3)
      title = @browser.at_css('h2[data-qa="title"]')&.inner_text
      if title&.match?(/подняли резюме/)
        TelegramNotify.call 'Успешное обновление резюме на hh.ru!'
      else
        raise 'Ошибка нажатия на кнопку!'
      end
    end
  rescue => e
    try += 1
    puts e.message
    TelegramNotify.call e.message
    retry if try < 4
  end

    # Ожидаем загрузки страницы
    #browser.wait_until { browser.title.include?('hh.ru') }
  rescue => e
    TelegramNotify.call "Произошла ошибка: #{e.message}"
  ensure
    # Закрываем браузер
    @browser.quit
  end

  private

  def login_with_pass
    begin
      @browser.goto('https://hh.ru/account/login?backurl=%2F&hhtmFrom=main')
      sleep rand(0.3..0.9)

      in_with_pass_link = @browser.at_css('a[data-qa="expand-login-by-password"]')
      in_with_pass_link.click
      login_field = @browser.at_css('input[data-qa="login-input-username"]')
      login_field.focus
      login_field.type(ENV.fetch('MAIL'))
      sleep rand(0.5...0.9)

      pass_field = @browser.at_css('input[data-qa="login-input-password"]')
      pass_field.focus
      pass_field.type(ENV.fetch('HH_PASS'))
    rescue => e
      @browser.goto(LINKS_BEFORE_LOGIN.sample)
      wait = rand(1..3)
      TelegramNotify.call "Ошибка в методе #{__method__}: #{e.message}.\nВечная загрузка...\nЖдем #{wait} сек..."
      retry
    end
    sleep rand(1..3)

    login_btn = @browser.at_css('button[data-qa="account-login-submit"]')
    login_btn.click
    sleep rand(7..10)

    captcha = @browser.at_css('img[data-qa="account-captcha-picture"]')
    if captcha
      return TelegramNotify.call "Требуется подтверждение каптчи!"
    end
  end

  def login_with_code
    begin
      @browser.goto('https://hh.ru/account/login?backurl=%2F&hhtmFrom=main')
      sleep rand(0.3..0.9)

      login_field = @browser.at_css('input[name="login"]')
      login_field.focus
      login_field.type(ENV.fetch('MAIL'))
    rescue => e
      @browser.goto(LINKS_BEFORE_LOGIN.sample)
      wait = rand(1..3)
      TelegramNotify.call "Ошибка в методе #{__method__}: #{e.message}.\nВечная загрузка...\nЖдем #{wait} сек..."
      retry
    end
    sleep rand(1..3)

    submit_button = @browser.at_css('button[data-qa="account-signup-submit"]')
    submit_button.click
    sleep rand(10..12)

    code_field = @browser.at_css('input[data-qa="otp-code-input"]')
    
    unless code_field
      captcha = @browser.at_css('img[data-qa="account-captcha-picture"]')
      if captcha
        return TelegramNotify.call "Требуется подтверждение каптчи!"
      end
    end  
    
    code = read_mail_code
    code_field.focus
    code_field.type(code)
    sleep rand(0.3...0.9)

    submit_button = @browser.at_css('button[data-qa="otp-code-submit"]')
    submit_button.click
    sleep rand(0.3...0.9)
  end

  def connect_to(url, try=5)
    logo = @browser.at_css('a[data-sentry-component="Logo"]')
  end

  def save_cookies(file_path)
    cookies = @browser.cookies.all
    File.open(file_path, "w") do |f|
      result = {}
      cookies.each { |key, val| result[key] = val.send(:attributes) }
      f.write(JSON.pretty_generate(result))
    end
  end

  # Загрузка cookies
  def load_cookies(file_path)
    cookie_file = File.read(file_path)
    return if cookie_file.nil? || cookie_file.strip == ''

    cookies = JSON.parse(cookie_file)
    cookies.each { |key, val| @browser.cookies.set val }
  end

  def read_mail_code
    code = Mailer.call
    return code if code

    TelegramNotify.call 'Код еще не пришел. Ждем еще 15 сек...'
    sleep 15
    Mailer.call
  end
end
