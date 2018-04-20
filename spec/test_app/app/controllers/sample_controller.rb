class SampleController < ApplicationController
  include RailsLti2Provider::ControllerHelpers

  protect_from_forgery except: :launch
  before_action :lti2_authentication, only: :launch
  after_action :disable_xframe_header, only: :launch

  def launch

    render text: 'Hello World'
  end

end
