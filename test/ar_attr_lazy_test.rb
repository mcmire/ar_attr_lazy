require 'helper'

ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Schema.define do
    create_table :accounts, :force => true do |t|
      t.string :name, :null => false
    end
    
    create_table :users, :force => true do |t|
      t.integer :account_id, :null => false
      t.string :login, :null => false
      t.string :password, :null => false
      t.string :email, :null => false
      t.string :name, :null => false
      t.text :bio, :null => false
    end
    
    create_table :posts, :force => true do |t|
      t.integer :author_id, :null => false
      t.string :title, :null => false
      t.string :permalink, :null => false
      t.text :body, :null => false
      t.text :summary, :null => false
    end
    
    create_table :comments, :force => true do |t|
      t.integer :post_id, :null => false
      t.string :name, :null => false
      t.text :body, :null => false
    end
    
    create_table :tags, :force => true do |t|
      t.string :name, :null => false
      t.text :description
    end
    
    create_table :posts_tags, :id => false, :force => true do |t|
      t.integer :post_id, :null => false
      t.integer :tag_id, :null => false
    end
  end
end

class Account < ActiveRecord::Base
  has_one :user
end
class AccountWithDefaultScope < ActiveRecord::Base
  set_table_name :accounts
  default_scope :select => "name"
end

class User < ActiveRecord::Base
  has_many :posts, :foreign_key => "author_id"
  belongs_to :account
  attr_lazy :bio
end

class Post < ActiveRecord::Base
  has_many :comments
  has_many :comments_with_default_scope, :class_name => "CommentWithDefaultScope"
  belongs_to :author, :class_name => "User"
  has_and_belongs_to_many :tags
  has_and_belongs_to_many :tags_with_default_scope,
    :class_name => "TagWithDefaultScope",
    :join_table => "posts_tags",
    :association_foreign_key => "tag_id"
  attr_lazy :body, :summary
end
class PostWithDefaultScope < ActiveRecord::Base
  set_table_name :posts
  default_scope :select => "title"
end

class Comment < ActiveRecord::Base
  belongs_to :post
  attr_lazy :body
end
class CommentWithDefaultScope < ActiveRecord::Base
  set_table_name :comments
  belongs_to :post
  attr_lazy :body
  default_scope :select => "name"
end

class Tag < ActiveRecord::Base
  has_and_belongs_to_many :posts
  attr_lazy :description
end
class TagWithDefaultScope < ActiveRecord::Base
  set_table_name :tags
  has_and_belongs_to_many :posts
  attr_lazy :description
  default_scope :select => "name"
end


account = Account.create!(
  :name => "Joe's Account"
)
user = User.create!(
  :account => account,
  :name => "Joe Bloe",
  :login => "joe",
  :password => "secret",
  :email => "joe@bloe.com",
  :bio => "It's hip to be square!"
)
post = Post.create!(
  :author => user,
  :title => "The Best Post",
  :permalink => 'the-best-post',
  :body => "This is the best post, ya hear?? Word.",
  :summary => "T i t b p, y h?? W."
)
Comment.create!(
  :post => post,
  :name => "A douchebag",
  :body => "Your site suxx0rsss"
)
CommentWithDefaultScope.create!(
  :post => post,
  :name => "Some body",
  :body => "once told me the world is gonna roll me"
)
post.tags << Tag.new(:name => "foo", :description => "The description and stuff")

Protest.context "ar_attr_lazy" do
  def regex(str)
    Regexp.new(Regexp.escape(str))
  end
  
  # what about :selects in default_scope?
  # what about :selects in the association definition itself?
  # what about STI? (do the lazy attributes carry over?)
  # what about has_many :through or has_one :through?
  
  context "for a model that has lazy attributes" do
    
    context "with no associations involved" do
      test "find selects non-lazy attributes only by default" do
        lambda { Post.find(:first) }.should_not query(%r{"posts"\."(body|summary)"})
      end
      test "accessing a lazy attribute selects that attribute only" do
        post = Post.find(:first)
        lambda { post.body }.should query(
          regex(%|SELECT "posts"."id","posts"."body" FROM "posts"|)
        )
      end
      test "find still honors an explicit select option" do
        lambda { Post.find(:first, :select => "title, permalink") }.should query(
          regex(%|SELECT title, permalink FROM "posts"|)
        )
      end
      test "find still honors a select option in a parent scope" do
        lambda {
          Post.send(:with_scope, :find => {:select => "title, permalink"}) do
            Post.find(:first)
          end
        }.should query(
          regex(%|SELECT title, permalink FROM "posts"|)
        )
      end
      test "find still honors a select option in a default scope" do
        lambda { PostWithDefaultScope.find(:first) }.should query(
          regex(%|SELECT title FROM "posts"|)
        )
      end
    end
    
    context "accessing a has_many association" do
      before do
        @post = Post.first
      end
      test "find selects non-lazy attributes by default" do
        lambda { @post.comments.find(:first) }.should_not query(%r{"comments"\."body"})
      end
      test "find still honors an explicit select option" do
        lambda { @post.comments.find(:first, :select => "name") }.should query(
          regex(%|SELECT name FROM "comments"|)
        )
      end
      test "find still honors a select option in a parent scope" do
        lambda {
          Comment.send(:with_scope, :find => {:select => "name"}) do
            @post.comments.find(:first)
          end
        }.should query(
          regex(%|SELECT name FROM "comments"|)
        )
      end
      test "find still honors a select option in a default scope" do
        lambda { @post.comments_with_default_scope.find(:first) }.should query(
          regex(%|SELECT name FROM "comments"|)
        )
      end
    end
    
    context "accessing a belongs_to association" do
      test "find selects non-lazy attributes by default" do
        post = Post.first
        lambda { post.author }.should_not query(%r{"users"\."bio"})
      end
      # can't do a find on a belongs_to, so no testing needed for that
    end
    
    context "accessing a has_one association" do
      test "find selects non-lazy attributes by default" do
        account = Account.first
        lambda { account.user }.should_not query(%r{"users"\."bio"})
      end
      # can't do a find on a has_one, so no testing needed for that
    end
    
    context "accessing a has_and_belongs_to_many association" do
      before do
        @post = Post.first
      end
      test "find selects non-lazy attributes by default" do
        lambda { @post.tags.find(:all) }.should_not query(%r{"tags"\."description"})
      end
      test "find still honors an explicit select option" do
        lambda { @post.tags.find(:all, :select => "tags.name") }.should query(
          regex(%|SELECT tags.name FROM "tags"|)
        )
      end
      test "find still honors a select option in a parent scope" do
        pending "this fails on Rails 2.3.4"
        lambda {
          Tag.send(:with_scope, :find => {:select => "tags.name"}) do
            @post.tags.find(:all)
          end
        }.should query(
          regex(%|SELECT tags.name FROM "tags"|)
        )
      end
      test "find still honors a select option in a default scope" do
        pending "this fails on Rails 2.3.4"
        lambda {
          @post.tags_with_default_scope.find(:all)
        }.should query(
          regex(%|SELECT tags.name FROM "tags"|)
        )
      end
    end
    
    context "eager loading a has_many association (association preloading)" do
      test "find selects non-lazy attributes by default" do
        lambda {
          Post.find(:first, :include => :comments)
        }.should_not query(%r{"posts"\."body"|"comments"\."body"})
      end
      # can't test for an explicit select since that will force a table join
      # can't test for a scope select since association preloading doesn't honor those
    end
    context "eager loading a has_many association (table join)" do
      test "find selects non-lazy attributes by default" do
        lambda {
          Post.find(:first, :include => :comments, :conditions => "comments.name = 'A douchebag'")
        }.should_not query(%r{"posts"\."body"|"comments"\."body"})
      end
      # can't test for an explicit select since that clashes with the table join anyway
      # can't test for a scope for the same reason
    end
    
    context "eager loading a has_one association (association preloading)" do
      test "find selects non-lazy attributes by default" do
        lambda { Account.find(:first, :include => :user) }.should_not query(%r{"users"\."bio"})
      end
      # can't test for an explicit select since that will force a table join
      # can't test for a scope select since association preloading doesn't honor those
    end
    context "eager loading a has_one association (table join)" do
      test "find selects non-lazy attributes by default" do
        lambda {
          Account.find(:first, :include => :user, :conditions => "users.name = 'Joe Bloe'")
        }.should_not query(%r{"users"\."bio"})
      end
      # can't test for an explicit select since that clashes with the table join anyway
      # can't test for a scope for the same reason
    end
    
    context "eager loading a belongs_to association (association preloading)" do
      test "find selects non-lazy attributes by default" do
        lambda {
          Post.find(:first, :include => :author)
        }.should_not query(%r{"posts"\."(body|summary)"|"users"\."bio"})
      end
      # can't test for an explicit select since that will force a table join
      # can't test for a scope select since association preloading doesn't honor those
    end
    context "eager loading a belongs_to association (table join)" do
      test "find selects non-lazy attributes by default" do
        lambda {
          Post.find(:first, :include => :author, :conditions => "users.name = 'Joe Bloe'")
        }.should_not query(%r{"posts"\."(body|summary)"|"users"\."bio"})
      end
      # can't test for an explicit select since that clashes with the table join anyway
      # can't test for a scope for the same reason
    end
    
    context "eager loading a has_and_belongs_to_many association (association preloading)" do
      test "find selects non-lazy attributes by default" do
        lambda {
          Post.find(:first, :include => :tags)
        }.should_not query(%r{"posts"\."(body|summary)"|"tags"\."description"})
      end
      # can't test for an explicit select since that will force a table join
      # can't test for a scope select since association preloading doesn't honor those
    end
    context "eager loading a has_and_belongs_to_many association (table join)" do
      test "find selects non-lazy attributes by default" do
        lambda {
          Post.find(:first, :include => :tags, :conditions => "tags.name = 'foo'")
        }.should_not query(%r{"posts"\."(body|summary)"|"tags"\."description"})
      end
      # can't test for an explicit select since that clashes with the table join anyway
      # can't test for a scope for the same reason
    end
    
  end
  
  context "for a model that doesn't have lazy attributes" do
    
    context "with no associations involved" do
      test "find select all attributes by default" do
        lambda { Account.find(:first) }.should query(regex(%|SELECT * FROM "accounts"|))
      end
      test "accessing any one attribute doesn't do a query" do
        account = Account.first
        lambda { account.name }.should_not query
      end
      test "find still honors an explicit select option" do
        lambda { Account.find(:first, :select => "name") }.should query(regex(%|SELECT name FROM "accounts"|))
      end
      test "find still honors a select option in a parent scope" do
        lambda {
          Account.send(:with_scope, :find => {:select => "name"}) do
            Account.find(:first)
          end
        }.should query(regex(%|SELECT name FROM "accounts"|))
      end
      test "find still honors a select option in a default scope" do
        lambda { AccountWithDefaultScope.find(:first) }.should query(regex(%|SELECT name FROM "accounts"|))
      end
    end
    
    # TODO: accessing a has_many, belongs_to, has_one, etc. (association preloading, table join eager loading)
    
  end
end