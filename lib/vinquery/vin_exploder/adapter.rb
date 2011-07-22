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
        unless vq_hash.empty?
          doors_match = vq_hash[:body_style].match(/(\d)-DR/)
          doors_match = (vq_hash[:body_style].match(/VAN/).nil? ? [0,0] : [5,5]) if doors_match.nil?
          vq_hash[:number_of_doors] = doors_match[1]
          vq_hash[:year] = vq_hash.delete(:model_year)
        end
        vq_hash
      end
      
    end
    
  end
  
end