require 'spec_helper'

TELSTRA_API_KEY = ENV['TELSTRA_API']
TELSTRA_API_SECRET = ENV['TELSTRA_SECRET']
TELSTRA_TEST_NUMBER = ENV['TELSTRA_TEST_NUMBER'] || '0425616397'

describe Telstra::SMS do

  describe "Sending SMS" do
    let(:telstra_api){ Telstra::SMS.new(TELSTRA_API_KEY, TELSTRA_API_SECRET) }
    
    describe "#token_expired?" do
      it 'returns a boolean' do
        VCR.use_cassette('token') do
          expired = telstra_api.token_expired?
          expect(expired).to eq(true)

          telstra_api.token

          expired = telstra_api.token_expired?
          expect(expired).to eq(false)
        end
      end
    end

    describe "#token" do
      it 'returns token' do
        VCR.use_cassette('token') do
          response = telstra_api.token
          expect(response).kind_of?(String)
        end
      end
    end

    describe "#send_sms" do
      it 'returns a success' do
        VCR.use_cassette('send_sms') do
          response = telstra_api.send_sms(to: TELSTRA_TEST_NUMBER, body: 'Hello from Telstra!')
          expect(response).kind_of?(Hash)
          expect(response.has_key?('messageId')).to eq true
        end
      end
    end

    describe "get_message_status" do
      it 'returns message status' do
        VCR.use_cassette('get_message_status') do
          sms_response = telstra_api.send_sms(to: ENV['TELSTRA_TEST_NUMBER'], body: 'Hello from Telstra!')
          message_id = sms_response['messageId']
          response = telstra_api.get_message_status(message_id)

          expect(response).kind_of?(Hash)
          expect(response.has_key?('to')).to eq true
          expect(response.has_key?('receivedTimestamp')).to eq true
          expect(response.has_key?('sentTimestamp')).to eq true
          expect(response.has_key?('status')).to eq true
        end
      end
    end

    describe "#get_message_response" do
      ## Can a response be simulated?
      it 'returns message response' do
        VCR.use_cassette('get_message_response') do
          sms_response = telstra_api.send_sms(to: ENV['TELSTRA_TEST_NUMBER'], body: 'Hello from Telstra!')
          message_id = sms_response['messageId']
          response = telstra_api.get_message_response(message_id)

          expect(response).kind_of?(Array)

          expect(response[0].has_key?('from')).to eq true
          expect(response[0].has_key?('acknowledgedTimestamp')).to eq true
          expect(response[0].has_key?('content')).to eq true
        end
      end
    end

  end

end
