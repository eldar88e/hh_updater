class HeadHunter
  COOKIES_PATH = 'cookies.json'.freeze
  HOME_PATH = 'https://hh.ru'.freeze

  def initialize
    @browser = Ferrum::Browser.new(
      process_timeout: 40,
      headless: ARGV.include?("--headless"),
      browser_path: "/usr/bin/chromium-browser",
      browser_options: {
        "no-sandbox": nil,
        "disable-gpu": nil,
        "disable-software-rasterizer": nil,
        "disable-dev-shm-usage": nil,
        "remote-debugging-port": 9222,
      }
    )
    user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36"
    @browser.headers.set({"User-Agent" => user_agent})
    @method_name = :empty_method
  end

  def process
    load_cookies
    
    @browser.goto(HOME_PATH)
    sleep rand(3..5)
    stop_browser

    # login_with_pass unless authorized?

    authorized?

    send @method_name
    save_cookies
    puts "Success #{@method_name}."
  rescue => e
    puts e.full_message
    TelegramNotify.call "Error: #{e.message}."
  ensure
    @browser.quit
  end

  private

  def login_with_pass(try = 3)
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
    else
      raise "Error authorize"
    end
  rescue => e
    if @atempt <= try && e.message != 'Have captcha!'
      wait = rand(5..7)
      puts "Error in method: #{__method__}: #{e.message}.\nAwait #{wait}s.\n#{e}"
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

  def authorized?(try = 3)
    @atempt_a ||= 0
    node = 'div[data-qa="mainmenu_profileAndResumes"]'
    return true if !!@browser.at_css(node)

    raise "Error authorize"
  rescue => e
    if @atempt_a <= try
      wait = rand(5..7)
      puts "Error in method: #{__method__}: #{e.message}.\nAwait #{wait}s."
      sleep wait
      stop_browser
      @atempt_a += 1
      retry
    else
      raise e
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

  def scroll_to_node(node)
    @browser.execute('arguments[0].scrollIntoView({behavior: "smooth", block: "center"});', node)
    sleep rand(0.7..0.9)
  end

  def empty_method
    puts 'Method not assigned!'
  end

  def fill_email
    login_field = @browser.at_css('input[name="username"]')
    return if login_field.value == ENV.fetch('MAIL')

    login_field.focus
    login_field.type(ENV.fetch('MAIL'))
  end
end
