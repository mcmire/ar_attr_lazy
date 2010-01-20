require 'rubygems'
require 'rake'

require File.dirname(__FILE__) + "/lib/mcmire/ar_attr_lazy/version"

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.version = Mcmire::ArAttrLazy::VERSION
    gem.name = "ar_attr_lazy"
    gem.summary = %Q{Rails gem that provides lazy-loading for attributes.}
    gem.description = %Q{A little gem for Rails that provides the ability to specify attributes that will not be loaded when the record is loaded from the database, until you explicitly refer to those attributes. This is useful when you have a lot of text columns in your table; in this case lazy-loading the text attributes is a good way to lend your server a hand and cut down on database access time.}
    gem.email = "elliot.winkler@gmail.com"
    gem.homepage = "http://github.com/mcmire/ar_attr_lazy"
    gem.authors = ["Elliot Winkler"]
    unless ENV["AR_VERSION"]
      gem.add_dependency "activerecord", "< 3.0"
    end
    gem.add_development_dependency "mcmire-protest"
    gem.add_development_dependency "mcmire-matchy"
    gem.add_development_dependency "mcmire-mocha"
    gem.add_development_dependency "mocha-protest-integration"
    #gem.add_development_dependency "yard", ">= 0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => [:check_dependencies, :"check_dependencies:development"]

task :default => :test

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yardoc do
    abort "YARD is not available. In order to run yardoc, you must: sudo gem install yard"
  end
end