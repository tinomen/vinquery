require 'vin_exploder/abstract_adapter'
require 'vin_exploder/explosion'
require 'vinquery'

module VinExploder
  
  module Decode
    
    class VinqueryAdapter < AbstractAdapter
      
      # Create new vinquery adapter
      #
      # == Parameters
      # options:: access_code, report_type, url
      def initialize(options)
        super
      end
      
      def explode(vin)
        vq = fetch(vin)
        hash = normalize(vq.attributes)
        hash[:errors] = vq.errors
        hash
      end
      
      
      def fetch(vin)
        Vinquery.get(vin, @options)
      end
      
      def normalize(vq_hash)
        # fuel_type = vq_hash[:engine_type].match(/(GAS|DIESEL|HYBRID)/)[0]
        # driveline_type = vq_hash[:driveline].match(/(FWD|4WD|2WD)/)[0]
        door_number = vq_hash[:body_style].match(/(\d)-DR/)[1] unless vq_hash.empty?
        {:year => vq_hash.delete(:model_year), :number_of_doors => door_number}.merge(vq_hash)
      end
      
    end
    
  end
  
end