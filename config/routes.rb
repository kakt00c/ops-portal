Rails.application.routes.draw do
  namespace :connector do
    post "webhook" => "webhooks#webhook"
    namespace :backoffice do
      post "webhook" => "webhooks#webhook"
    end
  end

  namespace :triage do
    namespace :webhooks do
      post :portal
      post :responsible_subject
      post :common
    end
  end

  namespace :cms do
    post "webhook" => "webhooks#webhook"
  end

  namespace "api", defaults: { format: :json } do
    namespace "v1" do
      resources :issues, only: [ :index, :show, :update ] do
        resources :activities, only: [ :show, :create ], controller: "issues/activities"
        collection do
          get :search
        end
      end
      resources :responsible_subjects, only: [ :index ] do
        get :search, on: :collection
      end
    end
  end

  resources :issues, path: "dopyty" do
    get :relevant, on: :collection, path: :r
    resource :issue_like, as: :like, only: [ :create, :destroy ]
    resource :issue_subscription, as: :subscription, only: [ :create, :destroy ]

    resources :issues_user_comments, path: "komentare", module: :issues
    resources :issues_user_private_comments, path: "komentare", module: :issues, controller: "issues_user_comments"
    resources :issues_responsible_subject_comments, path: "odpovede", module: :issues
    resources :issues_responsible_subject_changes, path: "odstupenie", module: :issues

    resources :issues_updates, path: "aktualizacie", module: :issues, controller: "issues_updates"
    get :geo, on: :collection
  end



  namespace :issues, path: "dopyty" do
    resources :drafts, path: "novy-dopyt", path_names: { new: "podnet" } do
      get :new_question, on: :collection, path: "otazka"
      delete :destroy_photo
      patch :rotate_photo
      patch :duplicates
      get :thanks, on: :collection, path: "dakujeme"
      scope module: :drafts do
        resource :suggestions do
          get :generate
        end
        resource :details
        resource :geo
        resource :checks do
          get :generate
          post :confirm
        end
        resource :summary
        resource :category
        resource :subcategory
        resource :subtype
      end
    end

    resources :activities do
      resource :activity_vote, as: :vote
    end
  end

  resources :global_subscriptions, only: [] do
    collection do
      get "unsubscribe/:token", action: :unsubscribe, as: :unsubscribe
      post "unsubscribe/:token", action: :unsubscribe_post
    end
  end

  resources :subscriptions, only: [] do
    collection do
      get "unsubscribe/:token", action: :unsubscribe, as: :unsubscribe
    end
  end

  resources :uploads do
    patch :rotate, on: :member
  end

  resources :praises, path: "pochvaly", path_names: { new: "nova" } do
    collection do
      get "podakovanie", action: :thanks, as: "thanks"
    end
  end

  resource :profile, path: "profil" do
    collection do
      get :please_create, path: "potrebne-zalozit"
      get :please_verify, path: "potrebne-overit"
      get :please_wait, path: "potrebne-pockat"
      get :watched_issues, path: "sledovane"
      get :verified_issues, path: "overene"
      get :settings, path: "nastavenia"
    end
    resource :avatar, module: :profiles
    resource :verification, module: :profiles do
      get :code
      post :check_code
    end
  end

  resources :users, path: "pouzivatelia"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest, defaults: { format: :json }
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get "email-auth-request", to: "rodauth#email_auth_request", as: :email_auth_request

  # legacy urls redirects
  get "r/login", to:  redirect("/login")
  get "r/vsetky-podnety", to: redirect("/dopyty")
  get "r/ludia/:legacy_id" => "legacy/redirects#show_user", constraints: { legacy_id: /\d+/ }
  get "r/:municipality_slug" => "legacy/redirects#index"
  get "r/:municipality_slug/vsetky-podnety" => "legacy/redirects#search_list"
  get "r/:municipality_slug/podnety/ulica/:legacy_id/*" => "legacy/redirects#search_street", constraints: { legacy_id: /\d+/ }
  get "r/:municipality_slug/statistiky" => "legacy/redirects#search_stats"
  get "r/:municipality_slug/mapa" => "legacy/redirects#search_map"
  get "r/:municipality_slug/vsetky-aktuality", to: redirect("/aktuality")
  get "r/:municipality_slug/podnety/:legacy_id/:slug" => "legacy/redirects#show_issue", constraints: { legacy_id: /\d+/ }
  get "r/:municipality_slug/podnety/:legacy_id/:slug/*" => "legacy/redirects#show_issue", constraints: { legacy_id: /\d+/ } # fix for bogus crawlers
  get "r/:municipality_slug/podnety/:municipality_district_slug" => "legacy/redirects#search_list"
  get "r/:municipality_slug/pridat-podnet" => "legacy/redirects#create_issue"

  # Widget routes - support both /widget and /legacy/widget
  get "/legacy/widget" => "legacy/widgets#index"

  # Redirect root with widget param to legacy widget endpoint
  get "/", to: redirect { |_, request| "/legacy/widget?#{request.query_string}" }, constraints: lambda { |req| req.params[:widget].present? }

  # Defines the root path route ("/")
  root "homepage#show"

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  class GoodJobAdmin
    def self.matches?(request)
      user = request.env["rodauth"].rails_account

      ENV["ADMIN_EMAILS"].to_s.split(",").include?(user&.email) || Rails.env.development?
    end
  end

  constraints(GoodJobAdmin) do
    mount GoodJob::Engine => "admin/good_job"
  end

  match "/404", to: "errors#render_404", via: :all
  match "/500", to: "errors#render_500", via: :all

  constraints lambda { |req| !req.xhr? && req.format.html? && (req.path =~ %r{^/(rails|assets)/}).nil? } do
    get "*path" => "cms/pages#index", as: :cms_page
  end
end
