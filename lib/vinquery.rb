require 'net/http'
require 'nokogiri'

class Vinquery
  attr_reader :attributes, :vq_attrs, :errors

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
    url_s = "#{@url}?accessCode=#{@access_code}&vin=#{vin}&reportType=#{@report_type}"
    url = URI.parse(URI.escape(url_s))
    begin
      res =  Net::HTTP.get url
    rescue Exception => e
      xml = Nokogiri::XML::Builder.new do |doc|
        doc.vin(:number => vin,:status => "FAILED") {
          doc.message(:Key => "VinQuery unavailable", :Value => "Oops, it looks like our partner database isn't responding right now. Please try again later.")
        }
      end
      res = xml.to_xml
    end
    @doc = Nokogiri::HTML(res)
  end

  def parse(doc)
    set_attributes doc
    set_errors_hash doc
    # VinResult.new(valid?,
    #                   @attributes[:make], 
    #                   @attributes[:model], 
    #                   @attributes[:year].to_i, 
    #                   @attributes[:body_style], 
    #                   @attributes[:driveline], 
    #                   @attributes[:engine_type],
    #                   @vin_errors.values.first,
    #                   @attributes)
  end

  def set_attributes(doc)
    attributes = {}
    doc.xpath('//vehicle[1]/item').each do |item|
      attributes[item.attributes['key'].value.downcase.gsub(/ /, '_').intern] = item.attributes['value'].value
    end

    @attributes = attributes
  end

  def set_errors_hash(doc)
    @errors = {}
    @valid = doc.css('vin').first.attributes['status'].value == "SUCCESS"

    @errors = {doc.css('message').first.attributes['key'].value => doc.css('message').first.attributes['value'].value} unless @valid
  end

  def valid?
    @valid
  end

end