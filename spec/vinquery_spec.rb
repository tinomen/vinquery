require 'spec_helper'
require 'net/http'
require 'vinquery'

describe Vinquery do

  before(:each) do
    @query = Vinquery.new 'fake_url', 'access_code', 'report_type_2'
    
    @test_xml_data ||= File.new("#{File.dirname(__FILE__)}/vinquery_test.xml", "r").read
  end

  describe 'set attributes' do
    it 'should return a set of vehicle attributes given a Nokogiri document' do
      doc = Nokogiri::HTML(@test_xml_data)
      @query.set_attributes(doc)
      @query.attributes[:body_style].should == "EXTENDED CAB PICKUP 4-DR"
      @query.attributes.count.should == 168
    end

    it 'should recover from poorly or unexpected xml document' do
      xml_s = '<?xml version="1.0"?>\\n<blah status="FAILED" number="vin"\\n'
      doc = Nokogiri::HTML(xml_s)
      @query.set_attributes(doc).should == {}
    end
  end

  describe 'set errors hash' do
    it 'should give the reason for failure within an errors hash' do
      doc = Nokogiri::HTML '<?xml version="1.0" encoding="utf-8" standalone="yes"?>\r\n<VINquery Version="1.0.0" Report_Type="BASIC" Date="2/19/2011">\r\n    <VIN Number="ABCDEFGHIJKLMNOPQ" Status="FAILED">\r\n        <Message Key="5" Value="Invalid VIN number: This VIN number contains invalid letters: I,O or Q." />\r\n    </VIN>\r\n</VINquery>'
      @query.set_errors_hash(doc)
      @query.valid?.should == false
      @query.vin_errors.should == {"5" => "Invalid VIN number: This VIN number contains invalid letters: I,O or Q."}
    end
  end

  describe 'get_doc' do
    it "should return valid xml parsed by nokogiri pulled from VinQuery.com" do
      n_xml = @query.get_doc('abcdefghijklmnopq')

      n_xml.class.should equal(Nokogiri::HTML::Document)
      !!n_xml.css('vin').should == true
    end

    it "should rescue from error if the request misfires" do
      @query.instance_variable_set(:@vin_query_url,"http://bad.slkdfjlskdjf.url")
      doc = @query.get_doc('')
      doc.css('vin').first.attributes['status'].value.should == "FAILED"
      doc.css('message').first.attributes['key'].value.should == "VinQuery unavailable"
      doc.css('message').first.attributes['value'].value.should == "Oops, it looks like our partner database isn't responding right now. Please try again later."
    end
  end

  describe 'parse_doc' do
    it 'should take nokogiri document and separate to attributes and errors hash' do
      doc = Nokogiri::HTML(@test_xml_data)
      @query.should_receive(:set_attributes).with(an_instance_of(Nokogiri::HTML::Document))
      @query.should_receive(:set_errors_hash).with(an_instance_of(Nokogiri::HTML::Document))
      @query.parse_doc(doc)
    end
  end

  describe 'request' do
    # before(:each) do
    #       VCR.config{|c| c.ignore_localhost = false }
    #     end
    # 
    #     after(:each) do
    #       VCR.config{|c| c.ignore_localhost = true }
    #     end
    #       
    #     it 'should make the call to VinQuery.com and return attributes on valid number' do      
    #       VCR.use_cassette('vinquery') do
    #         query = Vinquery.get('1G1ND52F14M587843')
    #         query.valid?.should == true
    #         query.vin_errors.should == {}
    #         query.attributes.class.should equal(Hash)
    #       end
    #     end
    # 
    #     it 'should return an errors hash with an invalid vin number' do
    #       res = '<?xml version="1.0" encoding="utf-8" standalone="yes"?>\r\n<VINquery Version="1.0.0" Report_Type="BASIC" Date="2/19/2011">\r\n    <VIN Number="ABCDEFGHIJKLMNOPQ" Status="FAILED">\r\n        <Message Key="5" Value="Invalid VIN number: This VIN number contains invalid letters: I,O or Q." />\r\n    </VIN>\r\n</VINquery>'
    #       url_s = "http://127.0.0.1:3000/vinquery_test.xml?accessCode=abcdefg&vin=abcdefghijklmnopq&reportType=0"
    #       url = URI.parse(URI.escape(url_s))
    #       Net::HTTP.should_receive(:get).with(url).and_return(res)
    #       results = Vinquery.get('abcdefghijklmnopq')
    #       results.valid?.should == false
    #       HoptoadNotifier.expects(:notify).never
    #     end
  end

end

