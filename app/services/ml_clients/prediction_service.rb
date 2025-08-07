module MlClients
  class PredictionService
    include HTTParty

    Result = Struct.new(:success?, :data, :error, keyword_init: true)
    HEADERS = {"Content-Type" => "application/json"}.freeze
    TIMEOUT = 10
    PREDICT_PATH = "/predict".freeze

    base_uri ENV.fetch("PYTHON_AI_SERVICE_URL")

    def call file_path:
      response = self.class.post(
        PREDICT_PATH,
        body: build_body(file_path),
          headers: HEADERS,
          timeout: TIMEOUT
      )
      handle_response(response)
    rescue Net::ReadTimeout, Net::OpenTimeout => e
      Result.new(success?: false,
                 error: I18n.t("services.ml_clients.timeout",
                               message: e.message))
    rescue StandardError => e
      Result.new(success?: false,
                 error: I18n.t("services.ml_clients.connection_error",
                               message: e.message))
    end

    private

    def build_body file_path
      {imageBase64: Base64.strict_encode64(File.read(file_path))}.to_json
    end

    def handle_response response
      if response.success? && response.parsed_response["success"]
        data = response.parsed_response["data"].deep_symbolize_keys
        Result.new(success?: true, data:)
      else
        parsed_message = response.parsed_response["message"]
        error_message = parsed_message || "HTTP Status #{response.code}"
        Result.new(success?: false, error: error_message)
      end
    end
  end
end
