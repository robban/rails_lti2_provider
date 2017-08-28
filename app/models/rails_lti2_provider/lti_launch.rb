module RailsLti2Provider
  class LtiLaunch < ActiveRecord::Base
    validates_presence_of :tool_id, :nonce
    belongs_to :tool
    serialize :message

    def self.check_launch(lti_message)
      tool = Tool.find_by_uuid(lti_message.oauth_consumer_key)
      # Replicating logic from MessageAuthenticator class mergeing in oauth_params to get authentication to work
      params = lti_message.oauth_params.merge(lti_message.post_params)
      authenticator = IMS::LTI::Services::MessageAuthenticator.new(lti_message.launch_url, params, tool.shared_secret)
      raise Unauthorized.new(:invalid_signature) unless authenticator.valid_signature?
      raise Unauthorized.new(:invalid_nonce) if tool.lti_launches.where(nonce: lti_message.oauth_nonce).count > 0
      raise Unauthorized.new(:request_to_old) if  DateTime.strptime(lti_message.oauth_timestamp,'%s') < 5.minutes.ago
      tool.lti_launches.where('created_at > ?', 1.day.ago).delete_all
      tool.lti_launches.create(nonce: lti_message.oauth_nonce, message: lti_message.post_params)
    end

    def message
      IMS::LTI::Models::Messages::Message.generate(read_attribute(:message))
    end

    class Unauthorized < StandardError;
      attr_reader :error
      def initialize(error = :unknown)
        @error = error
      end
    end


  end
end
