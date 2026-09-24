require "sequel/core"

class RodauthMain < Rodauth::Rails::Auth
  configure do
    # List of authentication features that are loaded.
    enable :create_account, :verify_account,
           :login, :logout, :remember,
           :reset_password, :change_password, :change_login, :verify_login_change,
           :close_account

    enable :email_auth

    # Omniauth
    enable :omniauth

    enable :i18n

    if ENV["FACEBOOK_APP_ID"].present?
      omniauth_provider :facebook,
                        ENV.fetch("FACEBOOK_APP_ID"),
                        ENV.fetch("FACEBOOK_APP_SECRET"),
                        scope: "email",
                        info_fields: "name,email,first_name,last_name"
    end

    # Make sure provider name is explicitly set as a string for database queries

    if ENV["GOOGLE_CLIENT_ID"].present?
      omniauth_provider :google_oauth2,
                        ENV.fetch("GOOGLE_CLIENT_ID"),
                        ENV.fetch("GOOGLE_CLIENT_SECRET"),
                        name: "google" # Using a string instead of symbol
    end

    use_multi_phase_login? false

    # See the Rodauth documentation for the list of available config options:
    # http://rodauth.jeremyevans.net/documentation.html

    # ==> General
    # Initialize Sequel and have it reuse Active Record's database connection.
    db Sequel.postgres(extensions: :activerecord_connection, keep_reference: false)
    # Avoid DB query that checks accounts table schema at boot time.
    convert_token_id_to_integer? { User.columns_hash["id"].type == :integer }

    # Change prefix of table and foreign key column names from default "account"
    accounts_table :users
    verify_account_table :user_verification_keys
    verify_login_change_table :user_login_change_keys
    reset_password_table :user_password_reset_keys
    remember_table :user_remember_keys
    omniauth_identities_table :user_identities
    omniauth_identities_account_id_column :user_id

    # The secret key used for hashing public-facing tokens for various features.
    # Defaults to Rails `secret_key_base`, but you can use your own secret key.
    # hmac_secret "5f28b1718d78025da4a781a5e64d0fe7dcf8b3f5a66dbae064472e2773e0058fb08c37145c2627780d7208792309b593e2d8967189131a723cf84cbcac65ed0f"

    # Use path prefix for all routes.
    # prefix "/auth"

    # Specify the controller used for view rendering, CSRF, and callbacks.
    rails_controller { RodauthController }

    # Make built-in page titles accessible in your views via an instance variable.
    title_instance_variable :@page_title

    # Store account status in an integer column without foreign key constraint.
    account_status_column :status

    # Store password hash in a column instead of a separate table.
    account_password_hash_column :password_hash

    # Set password when creating account instead of when verifying.
    verify_account_set_password? false

    # Change some default param keys.
    login_param "email"
    login_label "Email"
    login_confirm_param "email-confirm"
    # password_confirm_param "confirm_password"
    login_minimum_length 5

    # Redirect back to originally requested location after authentication.
    login_return_to_requested_location? true
    # two_factor_auth_return_to_requested_location? true # if using MFA

    # Autologin the user after they have reset their password.
    # reset_password_autologin? true

    # Delete the account record when the user has closed their account.
    # delete_account_on_close? true

    after_close_account do
      account = User.find(account_id)
      account.anonymize!
    end

    # Redirect to the app from login and registration pages if already logged in.
    # already_logged_in { redirect login_redirect }

    # ==> Emails
    send_email do |email|
      # queue email delivery on the mailer after the transaction commits
      db.after_commit { email.deliver_later }
    end

    email_from ENV["NOTIFICATION_SMTP_USERNAME"] # this is actually also the email

    create_verify_account_email do
      RodauthMailer.verify_account(self.class.configuration_name, account_id, verify_account_key_value)
    end
    create_reset_password_email do
      RodauthMailer.reset_password(self.class.configuration_name, account_id, reset_password_key_value)
    end
    create_verify_login_change_email do |_login|
      RodauthMailer.verify_login_change(self.class.configuration_name, account_id, verify_login_change_key_value)
    end

    # ==> Email Auth
    email_auth_table :user_email_auth_keys
    email_auth_deadline_interval Hash[minutes: 10]

    email_auth_session_key "email_auth_session_id"

    create_email_auth_email do
      RodauthMailer.email_auth(self.class.configuration_name, account_id, email_auth_key_value)
    end

    before_login_attempt do
      user = User.find_by(email: param(login_param))

      if user.is_a?(User::ResponsibleSubject)
        set_field_error(login_param, I18n.t("rodauth.login_error_requires_email_auth"))
        set_error_flash I18n.t("rodauth.login_error_requires_email_auth")
        response.status = 403

        throw_rodauth_error
      end
    end

    # ==> Flash
    # Match flash keys with ones already used in the Rails app.
    # flash_notice_key :success # default is :notice
    # flash_error_key :error # default is :alert

    # Override default flash messages.
    # create_account_notice_flash "Your account has been created. Please verify your account by visiting the confirmation link sent to your email address."
    # require_login_error_flash "Login is required for accessing this page"
    # login_notice_flash nil

    # ==> Validation
    # Override default validation error messages.
    # no_matching_login_message "user with this email address doesn't exist"
    # already_an_account_with_this_login_message "user with this email address already exists"
    # password_too_short_message { "needs to have at least #{password_minimum_length} characters" }
    # login_does_not_meet_requirements_message { "invalid email#{", #{login_requirement_message}" if login_requirement_message}" }

    # Passwords shorter than 8 characters are considered weak according to OWASP.
    password_minimum_length 8
    # bcrypt has a maximum input length of 72 bytes, truncating any extra bytes.
    password_maximum_bytes 72

    # Custom password complexity requirements (alternative to password_complexity feature).
    # password_meets_requirements? do |password|
    #   super(password) && password_complex_enough?(password)
    # end
    # auth_class_eval do
    #   def password_complex_enough?(password)
    #     return true if password.match?(/\d/) && password.match?(/[^a-zA-Z\d]/)
    #     set_password_requirement_error_message(:password_simple, "requires one number and one special character")
    #     false
    #   end
    # end

    # ==> Remember Feature
    # Remember all logged in users.
    after_login { remember_login }

    # Or only remember users that have ticked a "Remember Me" checkbox on login.
    # after_login { remember_login if param_or_nil("remember") }

    # Extend user's remember period when remembered via a cookie
    extend_remember_deadline? true

    # Process OmniAuth data before callback
    # omniauth_before_callback_phase {}

    # before_create_account_route {}

    # ==> Account Creation and OmniAuth Integration
    before_create_account {
      custom_params = build_custom_params

      account[:type] = "User::Citizen"
      account[:email_global_unsubscribe_token] = generate_unsubscribe_token

      if validate_custom_params(custom_params)
        populate_account(custom_params)
      else
        set_response_error_status(422)
        throw_rodauth_error
      end
    }

    before_omniauth_create_account {
      account[:type] = "User::Citizen"
      account[:firstname] = omniauth_info["first_name"]
      account[:lastname] = omniauth_info["last_name"]
      account[:email_global_unsubscribe_token] = generate_unsubscribe_token
    }

    # Add a handler for OmniAuth login failure
    omniauth_on_failure do
      flash[:error] = "Authentication failed. Please try again."
      redirect login_path
    end

    # Create OmniAuth identity after account creation if necessary
    # after_create_account {}

    # ==> Redirects
    # Redirect to home page after logout.
    logout_redirect "/"

    # Redirect to wherever login redirects to after account verification.
    verify_account_redirect { login_redirect }

    # Redirect to login page after password reset.
    reset_password_redirect { login_path }

    # ==> Deadlines
    # Change default deadlines for some actions.
    # verify_account_grace_period 3.days.to_i
    # reset_password_deadline_interval Hash[hours: 6]
    # verify_login_change_deadline_interval Hash[days: 2]
    # remember_deadline_interval Hash[days: 30]

    # ==> Helper methods and implementations
    auth_class_eval do
      def build_custom_params
        {
          name: param_or_nil("name")
        }
      end

      def validate_custom_params(custom_params)
        if custom_params[:name].blank?
          full_message = I18n.t("errors.format", attribute: I18n.t("activerecord.attributes.user.name"), message: I18n.t("errors.messages.blank"))
          set_field_error("name", full_message)

          return false
        end

        true
      end

      def populate_account(custom_params)
        account[:firstname] = custom_params[:name]
      end

      def generate_unsubscribe_token
        loop do
          candidate = SecureRandom.urlsafe_base64(32)
          return candidate unless User.exists?(email_global_unsubscribe_token: candidate)
        end
      end
    end
  end
end
