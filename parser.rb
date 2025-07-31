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

  RESUME_LINK = 'https://hh.ru/applicant/resumes'.freeze
  COOKIES_PATH = 'cookies.json'.freeze
  LOCAL_STORAGE_PATH = 'local_storage.json'.freeze

  def initialize
    @browser = Ferrum::Browser.new(
      process_timeout: 20,
      headless: ARGV.include?("--headless"),
      # browser_path: "/usr/bin/chromium-browser",
      browser_options: { "no-sandbox": nil }
    )
  end

  def process
    load_cookies
    
    @browser.goto('https://hh.ru')
    sleep rand(3..5)
    stop_browser

    login_with_pass unless authorized?

    update_resume
    save_cookies
    puts 'Success'
  rescue => e
    puts e.message
  ensure
    @browser.quit
  end

  def update_resume(try = 3)
    puts 'Update resume...'

    @atempt_upd ||= 0

    if !@browser.url.include?(RESUME_LINK)
      resume_btn = @browser.at_css('a[data-qa="link"]')
      resume_btn.click
      sleep rand(1..3)
    end

    update_btn = @browser.at_css('button[data-qa="resume-update-button resume-update-button_actions"]')
    if update_btn
      @browser.execute("window.scrollBy(0, 400);")
      update_btn.click
      puts 'Resume has been updated successfully.'
    else
      time_left = @browser.at_css('div[data-qa="title-description"]')&.text
      puts "#{time_left}"
    end

  rescue => e
    if @atempt_upd <= try
      wait = rand(1..3)
      
      ####
      puts "Error in method #{__method__}: #{e.message}.\nAwait #{wait} s.\n#{e}"
      # TelegramNotify.call "Ошибка в методе #{__method__}: #{e.message}.\nЖдем #{wait} сек..."
      ######

      sleep wait
      stop_browser
      @atempt_upd += 1
      retry
    else
      raise e
    end
  end

  private

  def login_with_pass(try = 3)
    puts 'Authorizing with pass...'
    @atempt ||= 0

    sign_in_btn = @browser.at_css('a[data-qa="login"]')
    sign_in_btn.click if sign_in_btn
    sleep rand(1..3)
    
    in_btn = @browser.at_css('button[type="submit"] span')
    in_btn.click if in_btn
    sleep rand(1..3)
    
    mail_btn = @browser.at_css('input[value="EMAIL"] + div > div')
    mail_btn.click if mail_btn
    sleep rand(1..3)
    
    fill_email

    in_with_pass_btn = @browser.at_css('button[data-qa="expand-login-by-password"]')
    in_with_pass_btn.click
    sleep rand(1..3)

    pass_field = @browser.at_css('input[name="password"]')
    pass_field.focus
    pass_field.type(ENV.fetch('HH_PASS'))
    sleep rand(1..3)

    enter_btn = @browser.at_css('button[type="submit"]')
    enter_btn.click
    sleep rand(1..3)

    raise "Have captcha!" if @browser.at_css('div:not(.g-hidden) img[data-qa="account-captcha-picture"]')

    if authorized?
      save_cookies
      # save_local_storage
    else
      raise "Error authorize"
    end
  rescue => e
    if @atempt <= try && e.message != 'Have captcha!'
      wait = rand(5..7)
      
      ####
      puts "Error in method: #{__method__}: #{e.message}.\nAwait #{wait}s.\n#{e}"
      # TelegramNotify.call "Ошибка в методе #{__method__}: #{e.message}.\nAwait #{wait}.s"
      ######

      sleep wait
      stop_browser
      @atempt += 1
      retry
    else
      raise e
    end
  end

  def stop_browser
    @browser.execute("window.stop();")
  end

  def authorized?
    check_text = "//*[contains(text(), 'Мои резюме')]"
    return true if !!@browser.at_xpath(check_text)

    sleep rand(5..7)
    stop_browser
    !!@browser.at_xpath(check_text)
  end

  def fill_email
    login_field = @browser.at_css('input[name="username"]')
    return if login_field.value == ENV.fetch('MAIL')

    login_field.focus
    login_field.type(ENV.fetch('MAIL'))
  end

  def login_with_code
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
    sleep rand(0.3..0.9)

    submit_button = @browser.at_css('button[data-qa="otp-code-submit"]')
    submit_button.click
    sleep rand(0.3..0.9)
  end

  def connect_to(url, try=5)
    logo = @browser.at_css('a[data-sentry-component="Logo"]')
  end

  def save_local_storage
    local_storage = @browser.evaluate('Object.assign({}, window.localStorage)')
    File.write(LOCAL_STORAGE_PATH, local_storage.to_json)
  end

  def load_local_storage
    return unless File.exist?(LOCAL_STORAGE_PATH)

    local_storage = JSON.parse(File.read(LOCAL_STORAGE_PATH))
    local_storage.each do |k, v|
      @browser.execute("window.localStorage.setItem(#{k.to_json}, #{v.to_json})")
    end
  end

  def save_cookies
    cookies = @browser.cookies.all
    File.open(COOKIES_PATH, "w") do |f|
      result = {}
      cookies.each { |key, val| result[key] = val.send(:attributes) }
      f.write(JSON.pretty_generate(result))
    end
  end

  def load_cookies
    return unless File.exist?(COOKIES_PATH)

    cookie_file = File.read(COOKIES_PATH)
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
