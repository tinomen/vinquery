require 'net/http'
require 'nokogiri'
require 'Logger'

class Vinquery
  attr_reader :attributes, :errors, :result

  def self.get(vin, options={})
    request = Vinquery.new(options[:url], options[:access_code], options[:report_type], options[:logger])
    doc = request.fetch vin
    result = request.parse doc
    request
  end

  def initialize(url, access_code, report_type, log = Logger.new(nil))
    @url = url
    @access_code = access_code
    @report_type = report_type
    @log = log
  end
  
  def fetch(vin)
    # use reducable=FALSE to get additional fields like fuel_type
    # use vt=true to get vehicle_type
    # http://www.vinquery.com/ws_POQCXTYNO1D/xml_v100_QA7RTS8Y.aspx?accessCode=6958785b-ac0a-4303-8b28-40e14aa836ce&vin=YourVINToDecode&reportType=0&vt=true&gvwr=true
    @uri ||= "#{@url}?accessCode=#{@access_code}&reportType=#{@report_type}&reducable=FALSE&vt=TRUE&gvwr=TRUE"
    url_s = @uri + "&vin=#{vin}"
    @log.info{"Vinquery#fetch - uri: #{url_s}"}
    url = URI.parse(url_s)
    begin
      @result = Net::HTTP.get url
      @log.debug{"Vinquery#fetch - result: #{@result}"}
    rescue Exception => e
      @log.error{"ERROR - #{e.message}"}
      @log.error{"ERROR - #{e.backtrace[0]}"}
      xml = Nokogiri::XML::Builder.new do |doc|
        doc.vin(:number => vin,:status => "FAILED") {
          doc.message(:Key => "VinQuery unavailable", :Value => "Oops, it looks like our VIN decoder is unavailable at the moment. Please try again later.")
        }
      end
      @result = xml.to_xml
    end
    @doc = Nokogiri::HTML(@result)
  end

  def parse(doc)
    set_attributes doc
    set_errors_hash doc
    attributes
  end

  def set_attributes(doc)
    attributes = {}
    doc.xpath('//vehicle[1]/item').each do |item|
      attributes[item.attributes['key'].value.downcase.gsub('.', '').gsub(/ /, '_').to_sym] = item.attributes['value'].value
    end
    @log.info{"Vinquery#set_attributes - number of attributes parsed: #{attributes.size}"}
    if attributes.size > 0
      vin = doc.css('vin').first.attributes['number'].value
      attributes[:vin_key] = make_vin_key(vin)
      attributes[:vendor_result] = doc.to_xml 
    end
    @attributes = attributes
  end

  def set_errors_hash(doc)
    @errors = []
    @valid = doc.css('vin').first.attributes['status'].value == "SUCCESS"
    doc.css('message').each{|msg| @errors << {msg.attributes['key'].value => msg.attributes['value'].value} } unless valid?
    @errors.each{|msg| @log.error{"Vinquery#set_errors_hash - error: #{msg.to_s}"}} unless @errors.empty
  end

  def valid?
    @valid
  end
  
  def make_vin_key(vin)
    key = vin.slice(0,8)
    key << vin.slice(9,2)
  end

end