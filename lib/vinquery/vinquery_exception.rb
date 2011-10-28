class VinqueryException < StandardError 
  attr_accessor :original_exception
  def initialize(msg=nil, exception=nil)
    super(msg)
    original_exception = exception
  end
end