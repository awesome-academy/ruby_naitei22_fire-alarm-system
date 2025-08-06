Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      scope :auth, controller: :authentication do
        post :signup
        post :login
        post :logout
        get :profile
        patch :update_role
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
      
    end
  end
end
