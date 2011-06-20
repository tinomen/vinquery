require 'spec_helper'
require 'net/http'
require 'vinquery'

describe Vinquery do

  before(:each) do
    
    @query = Vinquery.new 'http://www.vinlookupservice.com', 'access_code', 'report_type_2'
    
    @test_xml_data ||= File.new("#{File.dirname(__FILE__)}/vinquery_test.xml", "r").read
    stub_request(:any, /.*vinlookupservice.*/).to_return(:body => @test_xml_data, :status => 200, :headers => { 'Content-Length' => @test_xml_data.length})
  end
  
  after(:each) do
    WebMock.reset!
  end

  describe 'set attributes' do
    it 'should return a set of vehicle attributes given a Nokogiri document' do
      doc = Nokogiri::HTML(@test_xml_data)
      @query.set_attributes(doc)
      # @query.attributes.each_pair{|k,v| puts "#{k} - #{v}"}
      @query.attributes[:body_style].should == "CREW CAB PICKUP 4-DR"
      @query.attributes.count.should == 169
    end

    it 'should recover from poorly or unexpected xml document' do
      xml_s = '<?xml version="1.0"?>\\n<blah status="FAILED" number="vin"\\n'
      doc = Nokogiri::HTML(xml_s)
      @query.set_attributes(doc).should == {}
    end
  end

  describe '#set_errors_hash' do
    it 'should give the reason for failure within an errors hash' do
      doc = Nokogiri::HTML '<?xml version="1.0" encoding="utf-8" standalone="yes"?>\r\n<VINquery Version="1.0.0" Report_Type="BASIC" Date="2/19/2011">\r\n    <VIN Number="ABCDEFGHIJKLMNOPQ" Status="FAILED">\r\n        <Message Key="5" Value="Invalid VIN number: This VIN number contains invalid letters: I,O or Q." />\r\n    </VIN>\r\n</VINquery>'
      @query.set_errors_hash(doc)
      @query.valid?.should == false
      @query.errors.should == [{"5" => "Invalid VIN number: This VIN number contains invalid letters: I,O or Q."}]
    end
  end

  describe 'get_doc' do
    it "should return valid xml parsed by nokogiri pulled from VinQuery.com" do
      n_xml = @query.fetch('abcdefghijklmnopq')

      n_xml.class.should equal(Nokogiri::HTML::Document)
      !!n_xml.css('vin').should == true
    end

    it "should rescue from error if the request misfires" do
      stub_request(:any, /.*bad\.service\.url.*/).to_timeout
      @query.instance_variable_set(:@url,"http://bad.service.url")
      doc = @query.fetch('')
      doc.css('vin').first.attributes['status'].value.should == "FAILED"
      doc.css('message').first.attributes['key'].value.should == "VinQuery unavailable"
      doc.css('message').first.attributes['value'].value.should == "Oops, it looks like our VIN decoding database is down right now. Please try again later."
    end
  end

  describe 'parse_doc' do
    it 'should take nokogiri document and separate to attributes and errors hash' do
      doc = Nokogiri::HTML(@test_xml_data)
      @query.should_receive(:set_attributes).with(an_instance_of(Nokogiri::HTML::Document))
      @query.parse(doc)
    end
  end

  describe 'request' do
    before(:each) do
      
    end
    
    it 'should make the call to VinQuery.com and return attributes on valid number' do      
      stub_request(:any, /.*fakeurl.*/).to_return(:body => @test_xml_data, :status => 200, :headers => { 'Content-Length' => @test_xml_data.length})
      query = Vinquery.get('1G1ND52F14M587843', {:url => 'http://www.fakeurl.com', :access_code => 'access_code', :report_type => 'report_type_2'})
      query.valid?.should == true
      query.errors.empty?.should == true
      query.attributes.class.should equal(Hash)
    end
    
    it 'should return an errors hash with an invalid vin number' do
      res = '<?xml version="1.0" encoding="utf-8" standalone="yes"?>\r\n<VINquery Version="1.0.0" Report_Type="BASIC" Date="2/19/2011">\r\n    <VIN Number="ABCDEFGHIJKLMNOPQ" Status="FAILED">\r\n        <Message Key="5" Value="Invalid VIN number: This VIN number contains invalid letters: I,O or Q." />\r\n    </VIN>\r\n</VINquery>'
      stub_request(:any, /.*invalidvin.*/).to_return(:body => res, :status => 200, :headers => { 'Content-Length' => res.length})
      results = Vinquery.get('BADVIN', {:url => 'http://www.invalidvin.com', :access_code => 'access_code', :report_type => 'report_type_2'})
      results.valid?.should == false
    end
  end

end

