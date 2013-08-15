class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :servlet_context, :servlet_request, :servlet_response
  
  # Return servlet context.
  def servlet_context
    return $servlet_context
  end
  
  # Return servlet request.
  def servlet_request
    return request.env['java.servlet_request']
  end
  
  # Return servlet response.
  def servlet_response
    return request.env['java.servlet_response']
  end
  
end
