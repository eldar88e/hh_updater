require_relative 'head_hunter'

class ResumeUpdater < HeadHunter
  RESUME_LINK = 'https://hh.ru/applicant/resumes'.freeze

  def initialize
    super
    @method_name = :update_resume
  end

  private

  def update_resume(try = 3)
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
      puts msg = 'Resume has been updated successfully.'
      TelegramNotify.call msg
    else
      begin
        sleep rand(1..3)
        stop_browser
        time_left = @browser.at_css('div[data-qa="title-description"]')&.text
        puts "#{time_left}"
      rescue StandardError => e
        # no things
      end
    end
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
end
