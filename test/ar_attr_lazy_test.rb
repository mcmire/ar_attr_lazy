require 'helper'

ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Schema.define do
    create_table :accounts do |t|
      t.string :name, :null => false
    end
    
    create_table :users do |t|
      t.integer :account_id, :null => false
      t.string :login, :null => false
      t.string :password, :null => false
      t.string :email, :null => false
      t.string :name, :null => false
      t.text :bio, :null => false
    end
    
    create_table :posts do |t|
      t.integer :author_id, :null => false
      t.string :title, :null => false
      t.string :permalink, :null => false
      t.text :body, :null => false
      t.text :summary, :null => false
    end
    
    create_table :comments do |t|
      t.integer :post_id, :null => false
      t.string :name, :null => false
      t.text :body, :null => false
    end
    
    create_table :tags do |t|
      t.string :name, :null => false
      t.text :description
    end
    
    create_table :posts_tags, :id => false do |t|
      t.integer :post_id, :null => false
      t.integer :tag_id, :null => false
    end
  end
end

class Account < ActiveRecord::Base
  has_one :user
end

class User < ActiveRecord::Base
  has_many :posts, :foreign_key => "author_id"
  belongs_to :account
  attr_lazy :bio
end

class Post < ActiveRecord::Base
  has_many :comments
  belongs_to :author, :class_name => "User"
  has_and_belongs_to_many :tags
  attr_lazy :body, :summary
end

class Comment < ActiveRecord::Base
  belongs_to :post
  attr_lazy :body
end

class Tag < ActiveRecord::Base
  has_and_belongs_to_many :posts
  attr_lazy :description
end

account = Account.create!(
  :name => "Joe's Account"
)
user = account.create_user(
  :name => "Joe Bloe",
  :login => "joe",
  :password => "secret",
  :email => "joe@bloe.com",
  :bio => "It's hip to be square!"
)
post = user.posts.create!(
  :title => "The Best Post",
  :permalink => 'the-best-post',
  :body => "This is the best post, ya hear?? Word.",
  :summary => "T i t b p, y h?? W."
)
post.comments.create!(
  :name => "A douchebag",
  :body => "Your site suxx0rsss"
)
post.tags << Tag.new(:name => "foo", :description => "The description and stuff")

Protest.context "ar_attr_lazy" do
  def regex(str)
    Regexp.new(Regexp.escape(str))
  end
  
  # what about :selects in default_scope?
  # what about :selects in the association definition itself?
  # what about STI? (do the lazy attributes carry over?)
  
  context "when model has lazy attributes" do
    context "with no associations involved" do
      test "find selects non-lazy attributes only by default" do
        lambda { Post.find(:first) }.should query(
          regex(%|SELECT "posts"."id","posts"."author_id","posts"."title","posts"."permalink" FROM "posts"|)
        )
      end
      test "accessing a lazy attribute selects that attribute only" do
        post = Post.find(:first)
        lambda { post.body }.should query(
          regex(%|SELECT "posts"."id","posts"."body" FROM "posts" WHERE ("posts"."id" = 1)|)
        )
      end
      test "find still honors an explicit select option" do
        lambda { Post.find(:first, :select => "title, permalink") }.should query(
          regex(%|SELECT title, permalink FROM "posts"|)
        )
      end
      test "find still honors a select option in a parent scope" do
        lambda { Post.scoped(:select => "title, permalink").find(:first) }.should query(
          regex(%|SELECT title, permalink FROM "posts"|)
        )
      end
    end
    
    context "accessing a has_many association" do
      test "find selects non-lazy attributes by default" do
        post = Post.first
        lambda { post.comments.find(:first) }.should query(
          regex(%|SELECT "comments"."id","comments"."post_id","comments"."name" FROM "comments" WHERE ("comments".post_id = 1)|)
        )
      end
      test "find still honors an explicit select option" do
        post = Post.first
        lambda { post.comments.find(:first, :select => "name") }.should query(
          regex(%|SELECT name FROM "comments" WHERE ("comments".post_id = 1)|)
        )
      end
    end
    
    context "accessing a belongs_to association" do
      test "find selects non-lazy attributes by default" do
        post = Post.first
        lambda { post.author }.should query(
          regex(%|SELECT "users"."id","users"."account_id","users"."login","users"."password","users"."email","users"."name" FROM "users" WHERE ("users"."id" = 1)|)
        )
      end
      #test "find still honors an explicit select option"
    end
    
    context "accessing a has_one association" do
      test "find selects non-lazy attributes by default" do
        account = Account.first
        lambda { account.user }.should query(
          regex(%|SELECT "users"."id","users"."account_id","users"."login","users"."password","users"."email","users"."name" FROM "users" WHERE ("users".account_id = 1)|)
        )
      end
      #test "find still honors an explicit select option"
    end
    
    context "accessing a has_and_belongs_to_many association" do
      test "find selects non-lazy attributes by default" do
        post = Post.first
        lambda { post.tags.find(:all) }.should query(
          regex(%|SELECT "tags"."id","tags"."name" FROM "tags" INNER JOIN "posts_tags" ON "tags".id = "posts_tags".tag_id WHERE ("posts_tags".post_id = 1 )|)
        )
      end
      #test "find still honors an explicit select option"
    end
    
    context "eager loading a has_many association (association preloading)" do
      test "find selects non-lazy attributes by default" do
        lambda { Post.find(:first, :include => :comments) }.should query(
          regex(%|SELECT "comments"."id","comments"."post_id","comments"."name" FROM "comments" WHERE ("comments".post_id = 1)|)
        )
      end
      #test "find still honors an explicit select option"
    end
    context "eager loading a has_many association (table join)" do
      test "find selects non-lazy attributes by default" do
        lambda { Post.find(:first, :include => :comments, :conditions => "comments.name = 'A douchebag'") }.should query(
          regex(%|SELECT "posts"."id" AS t0_r0, "posts"."author_id" AS t0_r1, "posts"."title" AS t0_r2, "posts"."permalink" AS t0_r3, "comments"."id" AS t1_r0, "comments"."post_id" AS t1_r1, "comments"."name" AS t1_r2 FROM "posts" LEFT OUTER JOIN "comments" ON comments.post_id = posts.id|)
        )
      end
      #test "find still honors an explicit select option"
    end
    
    context "eager loading a has_one association (association preloading)" do
      test "find selects non-lazy attributes by default" do
        lambda { Account.find(:first, :include => :user) }.should query(
           regex(%|SELECT "users"."id","users"."account_id","users"."login","users"."password","users"."email","users"."name" FROM "users" WHERE ("users".account_id = 1)|)
        )
      end
      #test "find still honors an explicit select option"
    end
    context "eager loading a has_one association (table join)" do
      test "find selects non-lazy attributes by default" do
        lambda { Account.find(:first, :include => :user, :conditions => "users.name = 'Joe Bloe'") }.should query(
          regex(%|SELECT "accounts"."id" AS t0_r0, "accounts"."name" AS t0_r1, "users"."id" AS t1_r0, "users"."account_id" AS t1_r1, "users"."login" AS t1_r2, "users"."password" AS t1_r3, "users"."email" AS t1_r4, "users"."name" AS t1_r5 FROM "accounts" LEFT OUTER JOIN "users" ON users.account_id = accounts.id WHERE (users.name = 'Joe Bloe')|)
        )
      end
      #test "find still honors an explicit select option"
    end
    
    context "eager loading a belongs_to association (association preloading)" do
      test "find selects non-lazy attributes by default" do
        lambda { Post.find(:first, :include => :author) }.should query(
          regex(%|SELECT "users"."id","users"."account_id","users"."login","users"."password","users"."email","users"."name" FROM "users" WHERE ("users"."id" = 1)|)
        )
      end
      #test "find still honors an explicit select option"
    end
    context "eager loading a belongs_to association (table join)" do
      test "find selects non-lazy attributes by default" do
        lambda { Post.find(:first, :include => :author, :conditions => "users.name = 'Joe Bloe'") }.should query(
          regex(%|SELECT "posts"."id" AS t0_r0, "posts"."author_id" AS t0_r1, "posts"."title" AS t0_r2, "posts"."permalink" AS t0_r3, "users"."id" AS t1_r0, "users"."account_id" AS t1_r1, "users"."login" AS t1_r2, "users"."password" AS t1_r3, "users"."email" AS t1_r4, "users"."name" AS t1_r5 FROM "posts" LEFT OUTER JOIN "users" ON "users".id = "posts".author_id WHERE (users.name = 'Joe Bloe')|)
        )
      end
      #test "find still honors an explicit select option"
    end
    
    context "eager loading a has_and_belongs_to_many association (association preloading)" do
      test "find selects non-lazy attributes by default" do
        lambda { Post.find(:first, :include => :tags) }.should query(
          regex(%|SELECT "tags"."id","tags"."name", t0.post_id as the_parent_record_id FROM "tags" INNER JOIN "posts_tags" t0 ON "tags".id = t0.tag_id WHERE (t0.post_id = 1)|)
        )
      end
      #test "find still honors an explicit select option"
    end
    context "eager loading a has_and_belongs_to_many association (table join)" do
      test "find selects non-lazy attributes by default" do
        lambda { Post.find(:first, :include => :tags, :conditions => "tags.name = 'foo'") }.should query(
          %|SELECT "posts"."id" AS t0_r0, "posts"."author_id" AS t0_r1, "posts"."title" AS t0_r2, "posts"."permalink" AS t0_r3, "tags"."id" AS t1_r0, "tags"."name" AS t1_r1 FROM "posts" LEFT OUTER JOIN "posts_tags" ON "posts_tags".post_id = "posts".id LEFT OUTER JOIN "tags" ON "tags".id = "posts_tags".tag_id WHERE (tags.name = 'foo') AND "posts".id IN (1)|
        )
      end
      #test "find still honors an explicit select option"
    end
  end
  context "when model doesn't have lazy attributes" do
    test "find select all attributes by default" do
      lambda { Account.find(:first) }.should query(
        regex(%|SELECT * FROM "accounts"|)
      )
    end
    it "accessing any one attribute doesn't do a query" do
      account = Account.first
      lambda { account.name }.should_not query
    end
    #test "find still honors an explicit select option" ?
  end
end