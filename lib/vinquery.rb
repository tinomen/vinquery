require 'net/http'
require 'nokogiri'

class Vinquery
  attr_reader :attributes, :errors

  def self.get(vin, options={})
    request = Vinquery.new options[:url], options[:access_code], options[:report_type]
    doc = request.fetch vin
    result = request.parse doc
    request
  end

  def initialize(url, access_code, report_type)
    @url = url
    @access_code = access_code
    @report_type = report_type
  end
  
  def fetch(vin)
    # initialize http get with vin
    url_s = "#{@url}?accessCode=#{@access_code}&vin=#{vin}&reportType=#{@report_type}&reducable=FALSE"
    url = URI.parse(URI.escape(url_s))
    begin
      res = Net::HTTP.get url
    rescue Exception => e
      xml = Nokogiri::XML::Builder.new do |doc|
        doc.vin(:number => vin,:status => "FAILED") {
          doc.message(:Key => "VinQuery unavailable", :Value => "Oops, it looks like our VIN decoding database is down right now. Please try again later.")
        }
      end
      res = xml.to_xml
    end
    @doc = Nokogiri::HTML(res)
  end

  def parse(doc)
    set_attributes doc
    set_errors_hash doc
    attributes
  end

  def set_attributes(doc)
    attributes = {}
    doc.xpath('//vehicle[1]/item').each do |item|
      attributes[item.attributes['key'].value.downcase.gsub(/ /, '_').intern] = item.attributes['value'].value
    end

    @attributes = attributes
  end

  def set_errors_hash(doc)
    @errors = []
    @valid = doc.css('vin').first.attributes['status'].value == "SUCCESS"
    doc.css('message').each{|msg| @errors << {msg.attributes['key'].value => msg.attributes['value'].value} } unless @valid
  end

  def valid?
    @valid
  end

end