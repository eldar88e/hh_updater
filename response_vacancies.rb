require_relative 'head_hunter'

class ResponseVacancies < HeadHunter
  RESUME_LINK = "#{HOME_PATH}/search/vacancy".freeze
  SEARCH_WORD = 'Ruby'.freeze
  SEARCH_PARAMS = {
    off: ['Анапа', 'описании вакансии', 'названии компании'],
    on: ['Удалённо']
  }

  def initialize
    super
    @method_name = :response_vacancies
  end

  private

  def response_vacancies(try = 3)
    @atempt_upd ||= 0

    if !@browser.url.include?(RESUME_LINK)
      resume_btn = @browser.at_css('form[action="/search/vacancy"] button')
      resume_btn.click
      sleep rand(1..3)
    end

    fill_search_input

    search_params

    run_search

    click_vacancies
  rescue => e
    if @atempt_upd <= try
      wait = rand(1..3)
      puts "Error in method #{__method__}: #{e.message}.\nAwait #{wait} s.\n#{e}"
      sleep wait
      stop_browser
      @atempt_upd += 1
      retry
    else
      raise e
    end
  end

  private

  def click_vacancies
    count = 0
    vacancies = @browser.css('div[data-qa="vacancy-serp__vacancy"]')
    vacancies[1..5].each do |vacancy|
      scroll_to_node(vacancy)
      response_btn = vacancy.at_xpath('//a[@data-qa="vacancy-serp__vacancy_response" and contains(., "Откликнуться")]')
      return if response_btn.nil?

      response_btn.click
      count += 1
      sleep rand(5..7)
    end
    TelegramNotify.call "Click #{count} vacancies"
  end

  def fill_search_input
    search_input = @browser.at_css('input[data-qa="search-input"]')
    return if search_input.value == SEARCH_WORD

    search_input.focus
    search_input.type(SEARCH_WORD)
    sleep rand(1..3)
  end

  def run_search
    search_btn = @browser.at_css('button[data-qa="search-button"]')
    scroll_to_node(search_btn)
    search_btn.click
  end

  def search_params
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
  end
end
