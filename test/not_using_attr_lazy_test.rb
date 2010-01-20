require 'helper'

# what about STI? (do the lazy attributes carry over?)

Protest.context "for a model that doesn't have lazy attributes" do
  global_setup do
    load File.dirname(__FILE__) + '/setup_migration.rb'
    load File.dirname(__FILE__) + '/setup_tables_for_not_using.rb'
    Account.make! do |account|
      User.make!(:account => account) do |user|
        Avatar.make!(:user => user)
        Post.make!(:author => user) do |post|
          Comment.make!(:post => post)
          post.tags << Tag.make
          post.categories << Category.make
        end
      end
    end
  end
  
  global_teardown do
    ObjectSpace.each_object(Class) do |klass|
      Object.remove_class(klass) if klass < ActiveRecord::Base
    end
  end
  
  def regex(str)
    Regexp.new(Regexp.escape(str))
  end
  
  context "with no associations involved" do
    test "find selects all attributes by default" do
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
  
  context "accessing a has_many association" do
    before do
      @post = Post.first
    end
    test "find selects all attributes by default" do
      lambda { @post.comments.find(:first) }.should query(regex(%|SELECT * FROM "comments"|))
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
    test "find selects all attributes by default" do
      post = Post.first
      lambda { post.author }.should query(regex(%|SELECT * FROM "users"|))
    end
    # can't do a find on a belongs_to, so no testing needed for that
  end
  
  context "accessing a has_one association" do
    test "find selects all attributes by default" do
      account = Account.first
      lambda { account.user }.should query(regex(%|SELECT * FROM "users"|))
    end
    # can't do a find on a has_one, so no testing needed for that
  end
  
  context "accessing a has_and_belongs_to_many association" do
    before do
      @post = Post.first
    end
    test "find selects all attributes by default" do
      lambda { @post.tags.find(:all) }.should query(regex(%|SELECT * FROM "tags"|))
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
    test "find selects all attributes by default" do
      lambda { @post.categories.find(:all) }.should query(
        regex(%|SELECT "categories".* FROM "categories"|)
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
    test "find selects all attributes by default" do
      account = Account.first
      lambda { account.avatar }.should query(
        regex(%|SELECT "avatars".* FROM "avatars"|)
      )
    end
    # can't do a find on a has_one, so no testing needed for that
  end
  
  context "eager loading a has_many association (association preloading)" do
    test "find selects all attributes by default" do
      lambda {
        Post.find(:first, :include => :comments)
      }.should query(regex(%|SELECT * FROM "posts"|), regex(%|SELECT "comments".* FROM "comments"|))
    end
    # can't test for an explicit select since that will force a table join
    # can't test for a scope select since association preloading doesn't honor those
  end
  context "eager loading a has_many association (table join)" do
    test "find selects all attributes by default" do
      lambda {
        Post.find(:first, :include => :comments, :order => "comments.id")
      }.should query(%r{"posts"\."body"}, %r{"comments"\."body"})
    end
    # can't test for an explicit select since that clashes with the table join anyway
    # can't test for a scope for the same reason
  end
  
  context "eager loading a has_one association (association preloading)" do
    test "find selects all attributes by default" do
      lambda { Account.find(:first, :include => :user) }.should query(regex(%|SELECT "users".* FROM "users"|))
    end
    # can't test for an explicit select since that will force a table join
    # can't test for a scope select since association preloading doesn't honor those
  end
  context "eager loading a has_one association (table join)" do
    test "find selects all attributes by default" do
      lambda {
        Account.find(:first, :include => :user, :order => "users.id")
      }.should query(%r{"users"\."bio"})
    end
    # can't test for an explicit select since that clashes with the table join anyway
    # can't test for a scope for the same reason
  end
  
  context "eager loading a belongs_to association (association preloading)" do
    test "find selects all attributes by default" do
      lambda {
        Post.find(:first, :include => :author)
      }.should query(regex(%|SELECT * FROM "posts"|))
    end
    # can't test for an explicit select since that will force a table join
    # can't test for a scope select since association preloading doesn't honor those
  end
  context "eager loading a belongs_to association (table join)" do
    test "find selects all attributes by default" do
      lambda {
        Post.find(:first, :include => :author, :order => "users.id")
      }.should query(%r{"posts"\."(body|summary)"}, %r{"users"\."bio"})
    end
    # can't test for an explicit select since that clashes with the table join anyway
    # can't test for a scope for the same reason
  end
  
  context "eager loading a has_and_belongs_to_many association (association preloading)" do
    test "find selects all attributes by default" do
      lambda {
        Post.find(:first, :include => :tags)
      }.should query(regex(%|SELECT * FROM "posts"|), regex(%|SELECT "tags".*, t0.post_id as the_parent_record_id FROM "tags"|))
    end
    # can't test for an explicit select since that will force a table join
    # can't test for a scope select since association preloading doesn't honor those
  end
  context "eager loading a has_and_belongs_to_many association (table join)" do
    test "find selects all attributes by default" do
      lambda {
        Post.find(:first, :include => :tags, :order => "tags.id")
      }.should query(%r{"posts"\."(body|summary)"}, %r{"tags"\."description"})
    end
    # can't test for an explicit select since that clashes with the table join anyway
    # can't test for a scope for the same reason
  end
  
  context "eager loading a has_many :through association (association preloading)" do
    test "find selects all attributes by default" do
      lambda {
        Post.find(:first, :include => :categories)
      }.should query(
        regex(%|SELECT * FROM "categories"|)
      )
    end
    # can't test for an explicit select since that will force a table join
    # can't test for a scope select since association preloading doesn't honor those
  end
  context "eager loading a has_many :through association (table join)" do
    test "find selects all attributes by default" do
      lambda {
        Post.find(:first, :include => :categories, :order => "categories.id")
      }.should query(
        regex(%|SELECT "posts"."id" AS t0_r0, "posts"."type" AS t0_r1, "posts"."author_id" AS t0_r2, "posts"."title" AS t0_r3, "posts"."permalink" AS t0_r4, "posts"."body" AS t0_r5, "posts"."summary" AS t0_r6, "categories"."id" AS t1_r0, "categories"."type" AS t1_r1, "categories"."name" AS t1_r2, "categories"."description" AS t1_r3 FROM "posts"|)
      )
    end
    # can't test for an explicit select since that clashes with the table join anyway
    # can't test for a scope for the same reason
  end
  
  context "eager loading a has_one :through association (association preloading)" do
    test "find selects all attributes by default" do
      lambda { Account.find(:first, :include => :avatar) }.should query(
        regex(%|SELECT "avatars".* FROM "avatars"|)
      )
    end
    # can't test for an explicit select since that will force a table join
    # can't test for a scope select since association preloading doesn't honor those
  end
  context "eager loading a has_one :through association (table join)" do
    test "find selects all attributes by default" do
      pending "this is failing for some reason!"
      lambda {
        Account.find(:first, :include => :avatar, :order => "avatars.filename")
      }.should query(%|SELECT "accounts"."id" AS t0_r0, "accounts"."name" AS t0_r1, "avatars"."id" AS t1_r0, "avatars"."user_id" AS t1_r1, "avatars"."filename" AS t1_r2, "avatars"."data" AS t1_r3 FROM "accounts"|)
    end
    # can't test for an explicit select since that clashes with the table join anyway
    # can't test for a scope for the same reason
  end
  
end