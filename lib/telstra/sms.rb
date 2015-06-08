require 'json'
require 'httparty'
require "telstra/sms/version"

module Telstra
  class SMS

    attr_accessor :api_key, :api_secret
    attr_reader :token_expires
    
    # Initialize API Keys
    def initialize(api_key, api_secret)
      @api_key = api_key
      @api_secret = api_secret
    end

    def token_expired?
      @token == nil || @token_expires == nil || @token_expires <= Time.now
    end

    # Returns the bearer token, authorises if required
    def token
      update_token if token_expired?
      @token
    end

    # Receipient number should be in the format of 04xxxxxxxx where x is a digit.
    # Authorization header value should be in the format of "Bearer xxx" where xxx
    # is the access token returned from a token request.
    def send_sms(to: sms_to, body: sms_body)
      [to, body]
      options = { body: {
                    body: body,
                    to: to
                  }.to_json,
                  headers: { "Content-Type" => "application/json", "Authorization" => "Bearer #{token}" }}
      response = HTTParty.post("https://api.telstra.com/v1/sms/messages", options)
      return JSON.parse(response.body)
    end

    # Get the status of a previously sent SMS message
    # May return:
    #
    # PEND -> The message is pending and has not yet been sent
    # SENT -> Message has been send, but not delivered
    # DELIVRD -> Message has been delivered
    # READ -> The message has been read by the intended recipeitn
    #
    # Note: Some responses are dependent on the phone network of the user. 
    # Obviously, more info can be grabbed from those on the Telstra network.
    def get_message_status(message_id)
      options = { body: {}, headers: { "Authorization" => "Bearer #{token}" } }
      response = HTTParty.get("https://api.telstra.com/v1/sms/messages/#{message_id}", options)
      return JSON.parse(response.body)
    end

    def get_message_response(message_id)
      options = { body: {}, headers: { "Authorization" => "Bearer #{token}" } }
      response = HTTParty.get("https://api.telstra.com/v1/sms/messages/#{message_id}/response", options)
      return JSON.parse(response.body)
    end

    private

    # Request OAuth 2.0 token from API
    # Returns the JSON response
    def authorize
      response = HTTParty.get("https://api.telstra.com/v1/oauth/token?client_id=#{@api_key}&client_secret=#{@api_secret}&grant_type=client_credentials&scope=SMS")
      return JSON.parse(response.body)
    end

    # Fetches the token from the API via the authorise method
    # Updates the instance variables: token and expires
    # Returns the access token
    def update_token
      auth_response = authorize
      
      access_token = auth_response['access_token']
      expires_in = auth_response['expires_in']

      @token = access_token

      @token_expires = if expires_in
        Time.now + expires_in.to_i
      else
        nil
      end

      return access_token
    end

  end
end
