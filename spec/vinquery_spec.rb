require 'spec_helper'
require 'net/http'
require 'vinquery'

describe Vinquery do

  before(:each) do
    
    @query = Vinquery.new 'valid_vin', 'http://www.vinlookupservice.com', 'access_code', 'report_type_2'
    
    @test_xml_data ||= File.new("#{File.dirname(__FILE__)}/vinquery_test.xml", "r").read
    stub_request(:any, /.*vinlookupservice.*/).to_return(:body => @test_xml_data, :status => 200, :headers => { 'Content-Length' => @test_xml_data.length})
  end
  
  after(:each) do
    WebMock.reset!
  end

  describe '#valid?' do
    it 'should return true when the returned doc has a status of SUCCESS' do
      doc = Nokogiri::HTML(@test_xml_data)
      
      @query.instance_variable_set("@doc", doc)
      @query.valid?.should == true
    end

    it 'should return false when status is anything other than SUCCESS' do
      doc = Nokogiri::HTML(@test_xml_data.gsub(/SUCCESS/, 'FAILED'))
      
      @query.instance_variable_set("@doc", doc)
      @query.valid?.should == false
    end
  end

  describe '#create_exception' do
    it 'should return a VinqueryException with the vinquery error message' do
      doc = Nokogiri::HTML '<?xml version="1.0" encoding="utf-8" standalone="yes"?>\r\n<VINquery Version="1.0.0" Report_Type="BASIC" Date="2/19/2011">\r\n    <VIN Number="ABCDEFGHIJKLMNOPQ" Status="FAILED">\r\n        <Message Key="5" Value="Invalid VIN number: This VIN number contains invalid letters: I,O or Q." />\r\n    </VIN>\r\n</VINquery>'
      @query.instance_variable_set("@doc", doc)
      @query.valid?.should == false
      e = @query.create_exception
      e.class.should == VinqueryException
      e.message.should == "5: Invalid VIN number: This VIN number contains invalid letters: I,O or Q."
    end
  end

  describe '#parse' do
    it "should return a hash with all vin attributes" do
      doc = Nokogiri::HTML(@test_xml_data)
      
      @query.instance_variable_set("@doc", doc)
      @query.valid?.should == true
      h = @query.parse
      h.class.should == Hash
      h[:vin_key].should == '3D7LU38C3G'
    end

    it "should raise an VinException if request FAILED" do
      doc = Nokogiri::HTML '<?xml version="1.0" encoding="utf-8" standalone="yes"?>\r\n<VINquery Version="1.0.0" Report_Type="BASIC" Date="2/19/2011">\r\n    <VIN Number="ABCDEFGHIJKLMNOPQ" Status="FAILED">\r\n        <Message Key="5" Value="Invalid VIN number: This VIN number contains invalid letters: I,O or Q." />\r\n    </VIN>\r\n</VINquery>'
      @query.instance_variable_set("@doc", doc)
      @query.valid?.should == false
      expect { @query.parse }.to raise_error(VinqueryException, /Invalid VIN number/)
    end
  end

  describe '#get' do
    it 'should make the call to VinQuery.com and return attributes on valid vin' do      
      stub_request(:any, /.*fakeurl.*/).to_return(:body => @test_xml_data, :status => 200, :headers => { 'Content-Length' => @test_xml_data.length})
      query = Vinquery.get('1G1ND52F14M587843', {:url => 'http://www.fakeurl.com', :access_code => 'access_code', :report_type => 'report_type_2'})
      query.valid?.should == true
      query.errors.empty?.should == true
      query.attributes.class.should equal(Hash)
      query.attributes[:make].should == 'Dodge'
    end
    
    it 'should raise an exception with an invalid vin number' do
      res = '<?xml version="1.0" encoding="utf-8" standalone="yes"?>\r\n<VINquery Version="1.0.0" Report_Type="BASIC" Date="2/19/2011">\r\n    <VIN Number="ABCDEFGHIJKLMNOPQ" Status="FAILED">\r\n        <Message Key="5" Value="Invalid VIN number: This VIN number contains invalid letters: I,O or Q." />\r\n    </VIN>\r\n</VINquery>'
      stub_request(:any, /.*invalidvin.*/).to_return(:body => res, :status => 200, :headers => { 'Content-Length' => res.length})
      expect { Vinquery.get('BADVIN', {:url => 'http://www.invalidvin.com', :access_code => 'access_code', :report_type => 'report_type_2'}) }.to raise_error(VinqueryException)
    end
  end

end

