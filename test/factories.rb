class FactoryMaker
  class << self
    attr_accessor :factories
  
    # make(klass)
    # make(klass, factory)
    # make(klass, factory, custom_attributes)
    def make(*args, &block)
      factorize(:new, args, &block)
    end
    
    # make!(klass)
    # make!(klass, factory)
    # make!(klass, factory, custom_attributes)
    def make!(*args, &block)
      factorize(:create!, args, &block)
    end
    
    def attributes(factory)
      attributes = FactoryMaker.factories[factory]
      raise "Couldn't find factory \"#{factory}\"" unless attributes
      attributes
    end
    
  private
    def factorize(method, args, &block)
      custom_attributes = args.extract_options!
      klass, factory = args
      factory ||= klass.to_s.underscore.to_sym
      attributes = self.attributes(factory)
      model = klass.send(method, attributes.merge(custom_attributes))
      yield(model) if block_given?
      model
    end
  end
end

class ActiveRecord::Base
  class << self
    # make
    # make(factory)
    # make(factory, custom_attributes)
    def make(*args, &block)
      factorize(:make, args, &block)
    end
  
    # make!
    # make!(factory)
    # make!(factory, custom_attributes)
    def make!(*args, &block)
      factorize(:make!, args, &block)
    end
    
  private
    def factorize(method, args, &block)
      custom_attributes = args.extract_options!
      factory = args.first
      FactoryMaker.send(method, self, factory, custom_attributes, &block)
    end
  end
end

FactoryMaker.factories = {
  :account => {
    :name => "Joe's Account"
  },
  :user => {
    :name => "Joe Bloe",
    :login => "joe",
    :password => "secret",
    :email => "joe@bloe.com",
    :bio => "It's hip to be square!"
  },
  :avatar => {
    :filename => "somefile.png",
    :data => "10101010010010001000101"
  },
  :post => {
    :title => "The Best Post",
    :permalink => 'the-best-post',
    :body => "This is the best post, ya hear?? Word.",
    :summary => "T i t b p, y h?? W."
  },
  :comment => {
    :name => "A douchebag",
    :body => "Your site suxx0rsss"
  },
  :tag => {
    :name => "Foo",
    :description => "The description and stuff"
  },
  :category => {
    :name => "zing",
    :description => "Hey hey hey hey I don't like your girlfriend"
  }
}