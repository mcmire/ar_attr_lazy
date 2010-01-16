require 'rubygems'

require 'pp'

require 'activerecord'
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
Protest::Utils::BacktraceFilter::ESCAPE_PATHS << %r|test/unit| << %r|matchy| << %r|mocha-protest-integration|
Protest::TestWithErrors.class_eval do
  alias_method :backtrace, :raw_backtrace
end
Protest::TestCase.class_eval do
  def assert(condition, message="Expected condition to be satisfied")
    @report.add_assertion
    unless condition
      # In Ruby 1.9, the message is templated using a proc (see MiniTest::Assertions#message)
      # In Ruby 1.8, the message is templated using Test::Unit::Assertions::AssertionMessage
      message = (Proc === message ? message.call : message).to_s
      raise Protest::AssertionFailed, message
    end
  end
end

require 'matchers'

require 'init'