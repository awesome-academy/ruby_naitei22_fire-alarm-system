module Authentication
  class RoleUpdaterService
    Result = Struct.new(:success?, :user, :errors, :status,
                        keyword_init: true)
    ADMIN_ROLE = "admin".freeze

    def initialize user_to_update:, current_user:, new_role:
      @user_to_update = user_to_update
      @current_user = current_user
      @new_role = new_role
    end

    def call
      validation_result = validate_inputs
      return validation_result if validation_result

      update_user_role
    end

    private

    def t key
      I18n.t(key, scope: "api.v1.authentication_controller.update_role")
    end

    def validate_inputs
      unless User.roles.key?(@new_role)
        return failure(t(".invalid_role"), :unprocessable_entity)
      end

      return failure(t(".cannot_demote_self"), :forbidden) if demoting_self?

      nil
    end

    def demoting_self?
      @user_to_update.id == @current_user.id && @new_role != ADMIN_ROLE
    end

    def update_user_role
      if @user_to_update.update(role: @new_role)
        success(@user_to_update)
      else
        error_messages = @user_to_update.errors.messages.values.flatten
        failure(error_messages, :unprocessable_entity)
      end
    end

    def success user
      Result.new(success?: true, user:, status: :ok)
    end

    def failure errors, status
      Result.new(success?: false, errors: Array(errors), status:)
    end
  end
end
