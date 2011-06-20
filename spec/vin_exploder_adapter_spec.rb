require 'spec_helper'
require 'net/http'
require 'vinquery/vin_exploder/adapter'

module VinExploder
module Decode
    
describe VinqueryAdapter do

  before(:each) do
    
    @query = Vinquery.new 'http://www.vinlookupservice.com', 'access_code', 'report_type_2'
    @adapter = VinqueryAdapter.new({})
    @test_xml_data ||= File.new("#{File.dirname(__FILE__)}/vinquery_test.xml", "r").read
    stub_request(:any, /.*vinlookupservice.*/).to_return(:body => @test_xml_data, :status => 200, :headers => { 'Content-Length' => @test_xml_data.length})
  end
  
  after(:each) do
    WebMock.reset!
  end
  
  it 'should make the call to VinQuery.com and return attributes on valid number' do      
    Vinquery.should_receive(:new){ @query }
    hash = @adapter.explode('1G1ND52F14M587843')
    hash[:make].should == 'Dodge'
    hash[:errors].empty?.should == true
  end
  
  it 'should include an errors hash with an invalid vin number' do
    res = '<?xml version="1.0" encoding="utf-8" standalone="yes"?>\r\n<VINquery Version="1.0.0" Report_Type="BASIC" Date="2/19/2011">\r\n    <VIN Number="ABCDEFGHIJKLMNOPQ" Status="FAILED">\r\n        <Message Key="5" Value="Invalid VIN number: This VIN number contains invalid letters: I,O or Q." />\r\n    </VIN>\r\n</VINquery>'
    stub_request(:any, /.*invalidvin.*/).to_return(:body => res, :status => 200, :headers => { 'Content-Length' => res.length})
    query = Vinquery.new('http://www.invalidvin.com', 'access_code', 'report_type_2')
    Vinquery.should_receive(:new){ query }
    hash = @adapter.explode('BAD_VIN')
    hash[:errors].size.should == 1
    hash[:errors].first['5'].should == 'Invalid VIN number: This VIN number contains invalid letters: I,O or Q.'
  end
  
end

end
end