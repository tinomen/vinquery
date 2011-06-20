require 'vin_exploder/abstract_adapter'
require 'vin_exploder/explosion'
require 'vinquery'

module VinExploder
  
  module Decode
    
    class VinqueryAdapter < AbstractAdapter
      
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
        {:year => vq_hash.delete(:model_year)}.merge(vq_hash)
      end
      
    end
    
  end
  
end