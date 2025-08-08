module Alerts
  class StatusUpdaterService
    Result = Struct.new(:success?, :alert, :errors, keyword_init: true)

    def initialize alert:, user:, new_status:
      @alert = alert
      @user = user
      @new_status = new_status
    end

    def call
      @alert.user = @user
      if @alert.update(status: @new_status)
        Result.new(success?: true, alert: @alert)
      else
        Result.new(success?: false, errors: @alert.errors.full_messages)
      end
    end
  end
end
