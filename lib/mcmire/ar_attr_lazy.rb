module Mcmire
  module ArAttrLazy
    class Version
      include Comparable
      
      def initialize(version_string)
        @major, @minor, @tiny = split(version_string)
      end
      
      def <=>(other_version_string)
        [@major, @minor, @tiny] <=> split(other_version_string)
      end
      
    private
      def split(version_string)
        pieces = version_string.to_s.split(".")
        (0..2).map {|i| pieces[i].to_i || 0 }
      end
    end
    
    def self.ar_version
      @ar_version ||= Version.new(ActiveRecord::VERSION)
    end
  end
end

require 'mcmire/ar_attr_lazy/base_ext'
require 'mcmire/ar_attr_lazy/association_preload_ext'
require 'mcmire/ar_attr_lazy/habtm_ext'
require 'mcmire/ar_attr_lazy/join_base_ext'
require 'mcmire/ar_attr_lazy/belongs_to_association_ext'
require 'mcmire/ar_attr_lazy/has_many_through_association_ext'