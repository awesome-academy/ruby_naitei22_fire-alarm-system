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

      resources :users, only: %i(index show update)
      resources :invitations, only: %i(index create)
    end
  end
end
