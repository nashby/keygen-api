Rails.application.routes.draw do
  scope module: "api" do

    def json_request?(r)
      !(/json/ =~ r.content_type).nil?
    end

    namespace :v1, constraints: lambda { |r| json_request?(r) } do

      def resource(name, opts = {}, &block)
        resources(name, {
          path: name.to_s.dasherize
        }.merge(opts), &block)
      end

      def relationship(verb, resource, opts = {})
        case verb
        when :resource
          resources(resource.to_s.dasherize, {
            controller: "/api/v1/#{parent_resource.name}/relationships/#{resource}"
          }.merge(opts))
        else
          send(verb, resource.to_s.dasherize, {
            to: "/api/v1/#{parent_resource.name}/relationships/#{opts[:to]}"
          })
        end
      end

      def action(verb, action, opts = {})
        send(verb, action.to_s.dasherize, {
          to: "/api/v1/#{parent_resource.name}/actions/#{opts[:to]}"
        })
      end

      constraints lambda { |r| r.subdomain.empty? } do
        resource :stripe, only: [:create]
        resource :plans
        resource :accounts do
          namespace :relationships do
            relationship :resource, :plan, only: [:create]
          end
          namespace :actions do
            action :post, :activate, to: "activation#activate"
            action :post, :pause, to: "subscription#pause"
            action :post, :resume, to: "subscription#resume"
            action :post, :cancel, to: "subscription#cancel"
          end
        end
      end

      constraints lambda { |r| r.subdomain.present? } do
        get  :billing,   to: "billings#show"
        post :billing,   to: "billings#update"
        get  :tokens,    to: "tokens#request_tokens"
        post :tokens,    to: "tokens#reset_tokens"
        post :passwords, to: "passwords#reset_password"
        get  :profile,   to: "profiles#show"
        resource :users do
          namespace :actions do
            action :post, :update_password, to: "password#update_password"
            action :post, :reset_password, to: "password#reset_password"
          end
        end
        resource :policies do
          namespace :relationships do
            relationship :delete, :pool, to: "pool#pop"
          end
        end
        resource :keys
        resource :licenses do
          namespace :actions do
            action :get, :validate, to: "permits#validate"
            action :post, :revoke, to: "permits#revoke"
            action :post, :renew, to: "permits#renew"
          end
        end
        resource :machines
        resource :products do |r|
          namespace :relationships do
            relationship :resource, :users, only: [:create, :destroy]
          end
        end
        resource :webhook_endpoints
        resource :webhook_events, only: [:index, :show]
      end
    end
  end

  constraints lambda { |r| r.subdomain.present? || json_request?(r) } do
    %w[404 422 500].each do |code|
      match code, to: "errors#show", code: code, via: :all
    end
    root to: "errors#show", code: 404
  end

  constraints lambda { |r| r.subdomain.empty? && !json_request?(r) } do
    match "*all", to: "application#index", via: [:get]
    root to: "application#index"
  end
end
