require 'helper'

# what about STI? (do the lazy attributes carry over?)
# what about has_one :through?

Protest.context "for a model that has lazy attributes" do
  global_setup do
    load File.dirname(__FILE__) + '/setup_tables_for_not_using.rb'
    load File.dirname(__FILE__) + '/setup_tables_for_using.rb'
  end
  
  global_teardown do
    for model in [:Account, :AccountWithDefaultScope, :User, :Post, :PostWithDefaultScope, :Comment, :CommentWithDefaultScope, :Tag, :TagWithDefaultScope]
      Object.remove_class(model)
    end
  end
  
  def regex(str)
    Regexp.new(Regexp.escape(str))
  end
  
  context "with no associations involved" do
    test "find selects non-lazy attributes only by default" do
      lambda { Post.find(:first) }.should query(
        regex(%|SELECT "posts"."id","posts"."author_id","posts"."title","posts"."permalink" FROM "posts"|)
      )
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
      lambda { @post.comments.find(:first) }.should query(
        regex(%|SELECT "comments"."id","comments"."post_id","comments"."name" FROM "comments"|)
      )
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
    test "find still honors a select option in the association definition itself" do
      lambda { @post.comments_with_select.find(:first) }.should query(
        regex(%|SELECT name FROM "comments"|)
      )
    end
  end
  
  context "accessing a belongs_to association" do
    test "find selects non-lazy attributes by default" do
      post = Post.first
      lambda { post.author }.should query(
        regex(%|SELECT "users"."id","users"."account_id","users"."login","users"."password","users"."email","users"."name" FROM "users"|)
      )
    end
    # can't do a find on a belongs_to, so no testing needed for that
  end
  
  context "accessing a has_one association" do
    test "find selects non-lazy attributes by default" do
      account = Account.first
      lambda { account.user }.should query(
        regex(%|SELECT "users"."id","users"."account_id","users"."login","users"."password","users"."email","users"."name" FROM "users"|)
      )
    end
    # can't do a find on a has_one, so no testing needed for that
  end
  
  context "accessing a has_and_belongs_to_many association" do
    before do
      @post = Post.first
    end
    test "find selects non-lazy attributes by default" do
      lambda { @post.tags.find(:all) }.should query(
        regex(%|SELECT "tags"."id","tags"."name" FROM "tags" INNER JOIN "posts_tags" ON "tags".id = "posts_tags".tag_id|)
      )
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
    test "find still honors a select option in the association definition itself" do
      lambda {
        @post.tags_with_select.find(:all)
      }.should query(
        regex(%|SELECT tags.name FROM "tags"|)
      )
    end
  end
  
  context "accessing a has_many :through association" do
    before do
      @post = Post.first
    end
    test "find selects non-lazy attributes by default" do
      lambda { @post.categories.find(:all) }.should query(
        regex(%|SELECT "categories"."id","categories"."name" FROM "categories"|)
      )
    end
    test "find still honors an explicit select option" do
      lambda { @post.categories.find(:all, :select => "categories.name") }.should query(
        regex(%|SELECT categories.name FROM "categories"|)
      )
    end
    test "find still honors a select option in a parent scope" do
      pending "this fails on Rails 2.3.4"
      lambda {
        Category.send(:with_scope, :find => {:select => "categories.name"}) do
          @post.categories.find(:all)
        end
      }.should query(
        regex(%|SELECT categories.name FROM "categories"|)
      )
    end
    test "find still honors a select option in a default scope" do
      pending "this fails on Rails 2.3.4"
      lambda {
        @post.categories_with_default_scope.find(:all)
      }.should query(
        regex(%|SELECT categories.name FROM "categories"|)
      )
    end
    test "find still honors a select option in the association definition itself" do
      lambda {
        @post.categories_with_select.find(:all)
      }.should query(
        regex(%|SELECT categories.name FROM "categories"|)
      )
    end
  end
  
  context "accessing a has_one :through association" do
    test "find selects non-lazy attributes by default" do
      account = Account.first
      lambda { account.avatar }.should query(
        regex(%|SELECT "avatars"."id","avatars"."user_id","avatars"."filename" FROM "avatars"|)
      )
    end
    # can't do a find on a has_one, so no testing needed for that
  end
  
  context "eager loading a has_many association (association preloading)" do
    test "find selects non-lazy attributes by default" do
      lambda {
        Post.find(:first, :include => :comments)
      }.should query(
        regex(%|SELECT "comments"."id","comments"."post_id","comments"."name" FROM "comments"|)
      )
    end
    # can't test for an explicit select since that will force a table join
    # can't test for a scope select since association preloading doesn't honor those
  end
  context "eager loading a has_many association (table join)" do
    test "find selects non-lazy attributes by default" do
      lambda {
        Post.find(:first, :include => :comments, :conditions => "comments.name = 'A douchebag'")
      }.should query(
        regex(%|SELECT "posts"."id" AS t0_r0, "posts"."author_id" AS t0_r1, "posts"."title" AS t0_r2, "posts"."permalink" AS t0_r3, "comments"."id" AS t1_r0, "comments"."post_id" AS t1_r1, "comments"."name" AS t1_r2 FROM "posts"|)
      )
    end
    # can't test for an explicit select since that clashes with the table join anyway
    # can't test for a scope for the same reason
  end
  
  context "eager loading a has_one association (association preloading)" do
    test "find selects non-lazy attributes by default" do
      lambda { Account.find(:first, :include => :user) }.should query(
        regex(%|SELECT "users"."id","users"."account_id","users"."login","users"."password","users"."email","users"."name" FROM "users"|)
      )
    end
    # can't test for an explicit select since that will force a table join
    # can't test for a scope select since association preloading doesn't honor those
  end
  context "eager loading a has_one association (table join)" do
    test "find selects non-lazy attributes by default" do
      lambda {
        Account.find(:first, :include => :user, :conditions => "users.name = 'Joe Bloe'")
      }.should query(
        regex(%|SELECT "accounts"."id" AS t0_r0, "accounts"."name" AS t0_r1, "users"."id" AS t1_r0, "users"."account_id" AS t1_r1, "users"."login" AS t1_r2, "users"."password" AS t1_r3, "users"."email" AS t1_r4, "users"."name" AS t1_r5 FROM "accounts"|)
      )
    end
    # can't test for an explicit select since that clashes with the table join anyway
    # can't test for a scope for the same reason
  end
  
  context "eager loading a belongs_to association (association preloading)" do
    test "find selects non-lazy attributes by default" do
      lambda {
        Post.find(:first, :include => :author)
      }.should query(
        regex(%|SELECT "users"."id","users"."account_id","users"."login","users"."password","users"."email","users"."name" FROM "users"|)
      )
    end
    # can't test for an explicit select since that will force a table join
    # can't test for a scope select since association preloading doesn't honor those
  end
  context "eager loading a belongs_to association (table join)" do
    test "find selects non-lazy attributes by default" do
      lambda {
        Post.find(:first, :include => :author, :conditions => "users.name = 'Joe Bloe'")
      }.should query(
        regex(%|SELECT "posts"."id" AS t0_r0, "posts"."author_id" AS t0_r1, "posts"."title" AS t0_r2, "posts"."permalink" AS t0_r3, "users"."id" AS t1_r0, "users"."account_id" AS t1_r1, "users"."login" AS t1_r2, "users"."password" AS t1_r3, "users"."email" AS t1_r4, "users"."name" AS t1_r5 FROM "posts"|)
      )
    end
    # can't test for an explicit select since that clashes with the table join anyway
    # can't test for a scope for the same reason
  end
  
  context "eager loading a has_and_belongs_to_many association (association preloading)" do
    test "find selects non-lazy attributes by default" do
      lambda {
        Post.find(:first, :include => :tags)
      }.should query(
        regex(%|SELECT "tags"."id","tags"."name", t0.post_id as the_parent_record_id FROM "tags"|)
      )
    end
    # can't test for an explicit select since that will force a table join
    # can't test for a scope select since association preloading doesn't honor those
  end
  context "eager loading a has_and_belongs_to_many association (table join)" do
    test "find selects non-lazy attributes by default" do
      lambda {
        Post.find(:first, :include => :tags, :conditions => "tags.name = 'foo'")
      }.should query(
        regex(%|SELECT "posts"."id" AS t0_r0, "posts"."author_id" AS t0_r1, "posts"."title" AS t0_r2, "posts"."permalink" AS t0_r3, "tags"."id" AS t1_r0, "tags"."name" AS t1_r1 FROM "posts"|)
      )
    end
    # can't test for an explicit select since that clashes with the table join anyway
    # can't test for a scope for the same reason
  end
  
  # missing: has_many :through
  
  context "eager loading a has_one :through association (association preloading)" do
    test "find selects non-lazy attributes by default" do
      lambda { Account.find(:first, :include => :avatar) }.should query(
        regex(%|SELECT "avatars"."id","avatars"."user_id","avatars"."filename" FROM "avatars"|)
      )
    end
    # can't test for an explicit select since that will force a table join
    # can't test for a scope select since association preloading doesn't honor those
  end
  context "eager loading a has_one :through association (table join)" do
    test "find selects non-lazy attributes by default" do
      pending "this is failing for some reason!"
      lambda {
        Account.find(:first, :include => :avatar, :conditions => "avatars.filename = 'somefile.png'")
      }.should query(%|SELECT "accounts"."id" AS t0_r0, "accounts"."name" AS t0_r1, "avatars"."id" AS t1_r0, "avatars"."user_id" AS t1_r1, "avatars"."filename" AS t1_r2 FROM "accounts"|)
    end
    # can't test for an explicit select since that clashes with the table join anyway
    # can't test for a scope for the same reason
  end
  
end