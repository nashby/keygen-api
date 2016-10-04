require "httparty"

class WebhookWorker
  ACCEPTABLE_STATUSES = [200, 201, 202, 204].freeze

  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  sidekiq_options queue: :webhooks

  def perform(account_id, endpoint, payload)
    event = WebhookEvent.find_by jid: jid
    request = Request.post(endpoint, {
      headers: { "Content-Type" => "application/json" },
      body: payload
    })

    if !ACCEPTABLE_STATUSES.include?(request.code)
      raise FailedRequestError
    end
  end

  class FailedRequestError < StandardError; end
  class Request
    include HTTParty

    default_timeout 30
  end
end
