require 'rubygems'

require 'pp'

if ENV["AR_VERSION"]
  gem 'activerecord', "= #{ENV["AR_VERSION"]}"
end
require 'activerecord'
require 'active_record/version'
ActiveRecord::Base.establish_connection(
  "adapter" => "sqlite3",
  "database" => ":memory:"
)

gem 'mcmire-protest'
require 'protest'
gem 'mcmire-matchy'
require 'matchy'
gem 'mcmire-mocha'
require 'mocha'
require 'mocha-protest-integration'

Protest.report_with :documentation
#Protest::Utils::BacktraceFilter::ESCAPE_PATHS << %r|test/unit| << %r|matchy| << %r|mocha-protest-integration|
Protest::Utils::BacktraceFilter::ESCAPE_PATHS.clear

#------------------------

module Protest
  class TestCase
    def full_name
      self.class.description + " " + self.name
    end
    
    class TestWrapper #:nodoc:
      attr_reader :name

      def initialize(type, test_case)
        @type = type
        @test = test_case
        @name = "Global #{@type} for #{test_case.description}"
      end

      def run(report)
        @test.send("do_global_#{@type}")
      end
      
      def full_name
        @name
      end
    end
  end
  
  module TestWithErrors
    def file
      file_and_line[0]
    end
    
    def line
      file_and_line[1]
    end
    
    def file_and_line
      backtrace.find {|x| x =~ %r{^.*/test/(.*_test|test_.*)\.rb} }.split(":")[0..1]
    end
  end
  
  module Utils
    module Summaries
      def summarize_errors
        return if failures_and_errors.empty?

        puts "Failures:"
        puts

        pad_indexes = failures_and_errors.size.to_s.size
        failures_and_errors.each_with_index do |error, index|
          colorize_as = ErroredTest === error ? :errored : :failed
          # PATCH: test.full_name
          puts "  #{pad(index+1, pad_indexes)}) #{test_type(error)} in `#{error.test.full_name}' (on line #{error.line} of `#{error.file}')", colorize_as
          # If error message has line breaks, indent the message
          prefix = "with"
          unless error.error.is_a?(Protest::AssertionFailed) ||
          ((RUBY_VERSION =~ /^1\.9/) ? error.error.is_a?(MiniTest::Assertion) : error.error.is_a?(::Test::Unit::AssertionFailedError))
            prefix << " #{error.error.class}" 
          end
          if error.error_message =~ /\n/
            puts indent("#{prefix}: <<", 6 + pad_indexes), colorize_as
            puts indent(error.error_message, 6 + pad_indexes + 2), colorize_as
            puts indent(">>", 6 + pad_indexes), colorize_as
          else
            puts indent("#{prefix} `#{error.error_message}'", 6 + pad_indexes), colorize_as
          end
          indent(error.backtrace, 6 + pad_indexes).each {|backtrace| puts backtrace, colorize_as }
          puts
        end
      end
    end
  end
end

#------------------------

require 'matchers'
require 'factories'

require 'mcmire/ar_attr_lazy'