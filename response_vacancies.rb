# @browser.evaluate("navigator.userAgent") check user agent

require_relative 'head_hunter'

class ResponseVacancies < HeadHunter
  RESUME_LINK = "#{HOME_PATH}/search/vacancy".freeze
  RESPONSE_BTN = './/a[@data-qa="vacancy-serp__vacancy_response" and contains(., "Откликнуться")]'.freeze
  SEARCH_WORD = 'Ruby'.freeze
  SEARCH_PARAMS = {
    off: ['Анапа', 'описании вакансии', 'названии компании'],
    on: ['Удалённо']
  }
  SKIP_WORD = ['lead']
  MSG = <<~MSG
    Здравствуйте!

    Это автоматический отклик, отправленный моим собственным парсером для вакансий Ruby-разработчика.
    Я специально реализовал этот инструмент для автоматизации поиска интересных предложений.

    Если такой способ отклика для вас неудобен или неуместен, прошу прощения за беспокойство.

    Немного обо мне:
    — Ruby/Rails разработчик, коммерческий опыт более 5-ти лет
    — Postgres, Sidekiq, Redis, Grafana, S3, Docker-compose, интеграции API
    — React, TypeScript, Hotwire, Stimulus
    — Работаю с Git, CI, RSpec, Linux, опыт в распределённых командах

    Если заинтересовала моя кандидатура, буду рад пообщаться и обсудить детали.

    Спасибо за внимание!
  MSG

  def initialize
    super
    @method_name = :response_vacancies
  end

  private

  def response_vacancies
    if !@browser.url.include?(RESUME_LINK)
      resume_btn = @browser.at_css('form[action="/search/vacancy"] button')
      resume_btn.click
      sleep rand(1..3)
    end

    fill_search_input

    run_search

    search_params

    run_search

    click_vacancies
  end

  private

  def click_vacancies
    count   = 0
    skipped = 0
    error   = 0
    stop_browser
    vacancies     = @browser.css('div[data-qa="vacancy-serp__vacancy"]')
    new_vacancies = vacancies.select { |i| !i.at_xpath(RESPONSE_BTN).nil? }

    new_vacancies.each do |vacancy|
      response_btn = vacancy.at_xpath(RESPONSE_BTN)
      (skipped += 1) && next if SKIP_WORD.any? { |i| vacancy.at_css('h2').text.downcase.include?(i) }

      scroll_to_node(vacancy)
      response_btn.click
      sleep 3
      write_message(vacancy)
      count += 1
      sleep rand(5..7)
    rescue Ferrum::NodeNotFoundError
      # Вся карточка пропала, пропускаем
      error += 1
      next
    end
    msg = "Click #{count} of #{vacancies.size} vacancies."
    msg += "\nSkipped #{skipped} vacancies" if skipped.positive?
    msg += "\nError #{error} vacancies" if error.positive?
    TelegramNotify.call msg
  end

  def fill_search_input(try=3)
    @repeat ||=0
    search_input = @browser.at_css('input[data-qa="search-input"]')
    return if search_input.value == SEARCH_WORD

    search_input.focus
    sleep(0.5)
    search_input.type(SEARCH_WORD)
    sleep rand(3..5)
  rescue => e
    if @repeat <= try
      puts "Error in method: #{__method__}\n#{e.message}.\nAwait 6s."
      sleep 6
      @repeat += 1
      stop_browser
      retry
    else
      raise e
    end
  end

  def run_search
    search_btn = @browser.at_css('button[data-qa="search-button"]')
    scroll_to_node(search_btn)
    search_btn.click
    sleep rand(3..5)
  end

  def search_params(try=3)
    @serch_repit ||= 0
    SEARCH_PARAMS.each do |key, value|
      value.flatten.each do |param|
        node = @browser.at_xpath("//*[@data-qa='cell-left-side'][.//text()[contains(., '#{param}')]]")
        next unless node

        scroll_to_node(node)
        input_class = node.at_css('input[type="checkbox"]').attribute("class")
        if key == :off && input_class.include?('checked')
          node.click
        elsif key == :on && input_class.include?('unchecked')
          node.click
        end 
        sleep rand(3..5)
      end
    end
  rescue => e
    if @serch_repit <= try
      puts "Error in method: #{__method__}\n#{e.message}.\nAwait 6s."
      sleep 3
      @serch_repit += 1
      stop_browser
      fill_search_input
      sleep 3
      run_search
      sleep 5
      stop_browser
      retry
    else
      raise e
    end
  end

  def write_message(vacancy)
    chat_btn = vacancy.at_xpath('.//button[contains(., "Чат")]')
    return unless chat_btn

    chat_btn.click
    sleep 3
    iframe = @browser.at_css('iframe.chatik-integration-iframe_loaded')
    return unless iframe

    frame = iframe.frame
    msg_with_response = frame.at_css('span[data-qa="chatik-chat-message-applicant-action-text"]')
    msg_with_response.click if msg_with_response
    sleep 3
    textarea = frame.at_css('textarea[data-qa="chatik-new-message-text"]')
    textarea.focus
    MSG.each_char do |c|
      if c == "\n"
        textarea.type(:Shift, :Enter)
      else
        textarea.type(c)
      end
      sleep rand(0.05..0.07)
    end
    frame.at_css('button[data-qa="chatik-do-send-message"]').click
  end
end
