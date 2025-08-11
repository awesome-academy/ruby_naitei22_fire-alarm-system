# app/services/base_service.rb
# frozen_string_literal: true

class BaseService
  private

  def success(data = {})
    # SỬA LẠI Ở ĐÂY: `success?` phải có dấu chấm hỏi để khớp với Struct
    result_struct.new(success?: true, error: nil, **data)
  end

  def failure(error_message = "")
    # Sửa cả ở đây cho nhất quán
    result_struct.new(success?: false, error: error_message)
  end

  def result_struct
    Struct.new(:success?, :error, :user, :tokens, keyword_init: true)
  end
end
