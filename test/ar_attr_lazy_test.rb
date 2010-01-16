require 'helper'

ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Schema.define do
    create_table :posts do |t|
      t.string :title, :null => false
      t.string :permalink, :null => false
      t.text :body
      t.text :summary
    end
    
    create_table :comments do |t|
      t.integer :post_id, :null => false
      t.string :name, :null => false
      t.text :body
    end
    
    create_table :users do |t|
      t.string :login, :null => false
      t.string :password, :null => false
      t.string :email, :null => false
    end
  end
end

class Post < ActiveRecord::Base
  has_many :comments
  attr_lazy :body, :summary
end

class Comment < ActiveRecord::Base
  belongs_to :post
  attr_lazy :body
end

class User < ActiveRecord::Base
end

post = Post.create!(
  :title => "The Best Post",
  :permalink => 'the-best-post',
  :body => "This is the best post, ya hear?? Word.",
  :summary => "T i t b p, y h?? W."
)
post.comments.create!(
  :name => "Joe Bloe",
  :body => "This here is what we call a comment"
)
User.create!(
  :login => "joe",
  :password => "secret",
  :email => "joe@bloe.com"
)

Protest.context "ar_attr_lazy" do
  def regex(str)
    Regexp.new(Regexp.escape(str))
  end
  
  # what about :selects in default_scope?
  # what about STI?
  
  context "when model has lazy attributes" do
    context "with no associations involved" do
      it "doing a regular find selects non-lazy attributes only" do
        lambda { Post.first }.should query(
          %|SELECT "posts"."id","posts"."title","posts"."permalink" FROM "posts" LIMIT 1|
        )
      end
      it "accessing a lazy attribute selects that attribute only" do
        post = Post.first
        lambda { post.body }.should query(
          %|SELECT "posts"."id","posts"."body" FROM "posts" WHERE ("posts"."id" = 1)|
        )
      end
      it "honors an explicit select option when doing a regular find" do
        lambda { Post.first(:select => "title, permalink") }.should query(
          %|SELECT title, permalink FROM "posts" LIMIT 1|
        )
      end
      it "honors a select option in a parent scope" do
        lambda { Post.scoped(:select => "title, permalink").first }.should query(
          %|SELECT title, permalink FROM "posts" LIMIT 1|
        )
      end
    end
    #context "accessing a has_many association"
    #context "accessing a belongs_to association"
    #context "accessing a has_one association"
    #context "accessing a has_and_belongs_to_many association"
    context "eager loading a has_many association (association preloading)" do
      it "doing a regular find selects non-lazy attributes only" do
        lambda { Post.first(:include => :comments).comments.first }.should query(
          %|SELECT "comments"."id","comments"."post_id","comments"."name" FROM "comments" WHERE ("comments".post_id = 1)|
        )
      end
      it "accessing a lazy attribute selects that attribute only" do
        lambda { Post.first(:include => :comments).comments.first.body }.should query(
          %|SELECT "comments"."id","comments"."body" FROM "comments" WHERE ("comments"."id" = 1)|
        )
      end
      it "honors an explicit select option when doing a regular find" do
        lambda { Post.first(:include => :comments).comments.first(:select => "name") }.should query(
          %|SELECT name FROM "comments" WHERE ("comments".post_id = 1) LIMIT 1|
        )
      end
    end
    context "eager loading a has_many association (table join)" do
      it "doing a regular find selects non-lazy attributes only" do
        lambda { Post.first(:include => :comments, :conditions => "comments.name = 'Joe Bloe'").comments.first }.should query(
          regex(%|SELECT "posts"."id" AS t0_r0, "posts"."title" AS t0_r1, "posts"."permalink" AS t0_r2, "comments"."id" AS t1_r0, "comments"."post_id" AS t1_r1, "comments"."name" AS t1_r2 FROM "posts" LEFT OUTER JOIN "comments" ON comments.post_id = posts.id|)
        )
      end
      it "accessing a lazy attribute selects that attribute only" do
        lambda { Post.first(:include => :comments, :conditions => "comments.name = 'Joe Bloe'").comments.first.body }.should query(
          regex(%|SELECT "comments"."id","comments"."body" FROM "comments" WHERE ("comments"."id" = 1)|)
        )
      end
      it "honors an explicit select option when doing a regular find" do
        lambda { Post.first(:include => :comments, :conditions => "comments.name = 'Joe Bloe'").comments.first(:select => "name") }.should query(
          %|SELECT name FROM "comments" WHERE ("comments".post_id = 1) LIMIT 1|
        )
      end
    end
    #context "eager loading a has_one association (association preloading)"
    #context "eager loading a has_one association (table join)"
    #context "eager loading a belongs_to association (association preloading)"
    #context "eager loading a belongs_to association (table join)"
    #context "eager loading a has_and_belongs_to_many association (association preloading)"
    #context "eager loading a has_and_belongs_to_many association (table join)"
  end
  context "when model doesn't have lazy attributes" do
    it "doing a regular find selects all attributes" do
      lambda { User.first }.should query(
        %|SELECT * FROM "users" LIMIT 1|
      )
    end
    it "accessing any one attribute doesn't do a query" do
      user = User.first
      lambda { user.login }.should_not query
    end
    #it "honors an explicit select option"
  end
end