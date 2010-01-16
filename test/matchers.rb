module MatchyMatchers
  # Ported from an RSpec matcher
  # See https://rspec.lighthouseapp.com/projects/5645/tickets/896-lambda-should-query-matcher
  class ArQuery #:nodoc:
    cattr_accessor :executed

    @@recording_queries = false
    def self.recording_queries?
      @@recording_queries
    end

    def initialize(test_case, expected, &block)
      @test_case = test_case
      @expected = expected
      @block = block
    end

    def matches?(given_proc)
      @eval_block = false
      @eval_error = nil
      ArQuery.executed = []
      @@recording_queries = true

      given_proc.call

      if @expected.is_a?(Fixnum)
        @actual = ArQuery.executed.length
        @matched = @actual == @expected
      else
        @actual = ArQuery.executed.detect { |sql| @expected === sql }
        @matched = !@actual.nil?
      end

      eval_block if @block && @matched && !negative_expectation?

      @matched && @eval_error.nil?

    ensure
      #ArQuery.executed = nil
      @@recording_queries = false
    end
    
    # This is necessary for interoperability with Matchy
    def fail!(which)
      @test_case.flunk(which ? failure_message_for_should : failure_message_for_should_not)
    end

    # This is necessary for interoperability with Matchy
    def pass!(which)
      @test_case.assert true
    end

    def eval_block
      @eval_block = true
      begin
        @block[ArQuery.executed]
      rescue Exception => err
        @eval_error = err
      end
    end

    def failure_message_for_should
      if @eval_error
        @eval_error.message
      elsif @expected.is_a?(Fixnum)
        "expected #{@expected}, got #{@actual}"
      else
        # PATCH: better error message
        msg = "expected a query with pattern #{@expected.inspect} to be executed, but it wasn't.\n"
        msg << "Queries executed:\n"
        ArQuery.executed.each do |query|
          msg << " - #{query}\n"
        end
        msg
      end
    end

    def failure_message_for_should_not
      if @expected.is_a?(Fixnum)
        "did not expect #{@expected}"
      else
        # PATCH: better error message
        "did not expect a query with pattern #{@expected.inspect} to be executed, but it was executed"
      end
    end

    #def description
    #  if @expected.is_a?(Fixnum)
    #    @expected == 1 ? "execute 1 query" : "execute #{@expected} queries"
    #  else
    #    "execute query with pattern #{@expected.inspect}"
    #  end
    #end

    # Copied from raise_error
    def negative_expectation?
      @negative_expectation ||= !caller.first(3).find { |s| s =~ /should_not/ }.nil?
    end
  end

  # :call-seq:
  # response.should query
  # response.should query(expected)
  # response.should query(expected) { |sql| ... }
  # response.should_not query
  # response.should_not query(expected)
  #
  # Accepts a Fixnum or a Regexp as argument.
  #
  # With no args, matches if exactly 1 query is executed.
  # With a Fixnum arg, matches if the number of queries executed equals the given number.
  # With a Regexp arg, matches if any query is executed with the given pattern.
  #
  # Pass an optional block to perform extra verifications of the queries matched.
  # The argument of the block will receive an array of query strings that were executed.
  #
  # == Examples
  #
  # lambda { @object.posts }.should query
  # lambda { @object.valid? }.should query(0)
  # lambda { @object.save }.should query(3)
  # lambda { @object.line_items }.should query(/SELECT DISTINCT/)
  # lambda { @object.line_items }.should query(1) { |sql| sql[0].should =~ /SELECT DISTINCT/ }
  #
  # lambda { @object.posts }.should_not query
  # lambda { @object.valid? }.should_not query(0)
  # lambda { @object.save }.should_not query(3)
  # lambda { @object.line_items }.should_not query(/SELECT DISTINCT/)
  #
  def query(expected = 1, &block)
    ArQuery.new(self, expected, &block)
  end
  
  unless defined?(IGNORED_SQL)
    # From active_record/test/cases/helper.rb :
    ::ActiveRecord::Base.connection.class.class_eval do
      IGNORED_SQL = [/^PRAGMA/, /^SELECT currval/, /^SELECT CAST/, /^SELECT @@IDENTITY/, /^SELECT @@ROWCOUNT/, /^SAVEPOINT/, /^ROLLBACK TO SAVEPOINT/, /^RELEASE SAVEPOINT/, /SHOW FIELDS/]
      def execute_with_query_record(sql, name = nil, &block)
        if ArQuery.recording_queries?
          # PATCH: squeeze and strip
          ArQuery.executed << sql.squeeze(" ").strip unless IGNORED_SQL.any? { |ignore| sql =~ ignore }
        end
        execute_without_query_record(sql, name, &block)
      end
      alias_method_chain :execute, :query_record
    end
  end
end
Protest::TestCase.class_eval { include MatchyMatchers }