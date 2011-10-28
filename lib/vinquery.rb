require 'net/http'
require 'nokogiri'
require 'logger'
require 'vinquery/vinquery_exception'

class Vinquery
  attr_reader :attributes, :errors, :result
  
  def self.get(vin, options={})
    request = Vinquery.new(vin, options[:url], options[:access_code], options[:report_type], options[:logger])
    request.fetch
    request.parse
    request
  end

  def initialize(vin, url, access_code, report_type, log = nil)
    @vin = vin
    @url = url
    @errors = []
    @access_code = access_code
    @report_type = report_type
    log ||= Logger.new(nil)
    @log = log
  end
  
  def fetch
    # use reducable=FALSE to get additional fields like fuel_type
    # use vt=true to get vehicle_type
    # use gvwr=TRUE to get GVWR
    # http://www.vinquery.com/ws_POQCXTYNO1D/xml_v100_QA7RTS8Y.aspx?accessCode=6958785b-ac0a-4303-8b28-40e14aa836ce&vin=YourVINToDecode&reportType=0&vt=true&gvwr=true
    @uri ||= "#{@url}?accessCode=#{@access_code}&reportType=#{@report_type}&reducable=FALSE&vt=TRUE&gvwr=TRUE"
    url_s = @uri + "&vin=#{@vin}"
    @log.info{"Vinquery#fetch - uri: #{url_s}"}
    url = URI.parse(url_s)
    begin
      @result = Net::HTTP.get url
      @log.debug{"Vinquery#fetch - result: #{@result}"}
      @doc = Nokogiri::HTML(@result)
    rescue Exception => e
      raise VinqueryException.new(e.message, e)
    end
  end

  def parse
    raise create_exception unless valid?

    attributes = {}
    @doc.xpath('//vehicle[1]/item').each do |item|
      attributes[item.attributes['key'].value.downcase.gsub('.', '').gsub(/ /, '_').to_sym] = item.attributes['value'].value
    end
    @log.info{"Vinquery#set_attributes - number of attributes parsed: #{attributes.size}"}
    if attributes.size > 0
      vin = @doc.css('vin').first.attributes['number'].value
      attributes[:vin_key] = make_vin_key(vin)
      attributes[:vendor_result] = @doc.to_xml
      attributes[:number_of_cylinders] = attributes[:engine_type].upcase.match(/ [LV](\d{1,2}) /) ? $1 : nil
      attributes[:has_turbo] = attributes[:engine_type].upcase.match(/ ([TURBO|SUPERCHARGED]) /) ? true : false
    end
    @attributes = attributes
  end

  def create_exception
    @doc.css('message').each{|msg| @errors << {msg.attributes['key'].value => msg.attributes['value'].value} }
    VinqueryException.new(@errors.map{|msg| "#{msg.keys[0]}: #{msg.values[0]}"}.join("\n")) unless @errors.empty?
  end

  def valid?
    @valid ||= @doc.css('vin').first.attributes['status'].value == "SUCCESS" rescue false
  end
  
  def make_vin_key(vin)
    key = vin.slice(0,8)
    key << vin.slice(9,2)
  end

end