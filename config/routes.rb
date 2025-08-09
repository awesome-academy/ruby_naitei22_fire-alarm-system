Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      scope :auth, controller: :authentication do
        post :signup
        post :login
        post :logout
        get :profile
        patch :update_role
        post :refresh
      end

      resources :sensors do
        collection do
          get :stats
          post :bulk
        end
      end

      resources :users, only: %i(index show update)
      resources :invitations, only: %i(index create)
      resources :cameras, only: %i(index show create update destroy) do
        collection do
          get :stats
        end
        post :capture_and_upload_snapshot, on: :member
      end
      resources :alerts, only: %i(index show create) do
        collection do
          get :stats
        end
        patch :status, on: :member, action: :update_status
      end
    end
  end
end
