module Napster
  # The Client class implements a client object that prepares
  # information such as api_key, api_secret, and :redirect_uri
  # needed to call Napster API.
  class Client
    AUTH_METHODS = [:password_grant, :oauth2].freeze

    attr_accessor :api_key,
                  :api_secret,
                  :redirect_uri,
                  :username,
                  :password,
                  :state,
                  :auth_code,
                  :access_token,
                  :refresh_token,
                  :expires_in,
                  :request

    def initialize(options)
      validate_initialize(options)

      options.each do |name, value|
        instance_variable_set("@#{name}", value)
      end

      request_hash = {
        api_key: @api_key,
        api_secret: @api_secret
      }
      @request = Napster::Request.new(request_hash)
    end

    def post(path, body = {}, options = {})
      validate_request(path, body, options)

      raw_response = @request.faraday.post(path, body, options)
      Oj.load(raw_response.body)
    end

    def authenticate(auth_method)
      validate_authenticate(auth_method)

      return auth_password_grant if auth_method == :password_grant
      return auth_oauth2 if auth_method == :oauth2
    end

    private

    def validate_initialize(options)
      api_key = options[:api_key]
      api_secret = options[:api_secret]
      raise 'The client is missing api_key' unless api_key
      raise 'The client is missing api_secret' unless api_secret
    end

    def validate_request(path, body, options)
      raise ArgumentError, 'path is missing' unless path
      raise ArgumentError, 'body should be a hash' unless body.is_a?(Hash)
      raise ArgumentError, 'options should be a hash' unless options.is_a?(Hash)
    end

    def validate_authenticate(auth_method)
      unless auth_method.is_a?(Symbol)
        err = 'Authentication method must be passed as a symbol'
        raise ArgumentError, err
      end

      unless AUTH_METHODS.include?(auth_method)
        err = "Wrong authentication method. Valid methods are #{AUTH_METHODS}"
        raise ArgumentError, err
      end
    end

    def auth_password_grant
      validate_auth_password_grant
      response_body = post('/oauth/token', auth_password_grant_post_body,
                           auth_password_grant_post_options)
      @access_token = response_body['access_token']
      @refresh_token = response_body['refresh_token']
      @expires_in = response_body['expires_in']
      response_body
    end

    def auth_password_grant_post_body
      {
        response_type: 'code',
        grant_type: 'password',
        username: @username,
        password: @password
      }
    end

    def auth_password_grant_post_options
      {
        api_key: @api_key,
        api_secret: @api_secret
      }
    end

    def validate_auth_password_grant
      raise 'The client is missing username' unless @username
      raise 'The client is missing password' unless @password
    end
  end
end
