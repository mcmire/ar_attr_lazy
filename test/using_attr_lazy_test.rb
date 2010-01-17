require 'helper'

# what about :selects in default_scope?
# what about :selects in the association definition itself?
# what about STI? (do the lazy attributes carry over?)
# what about has_many :through or has_one :through?

Protest.context "for a model that has lazy attributes" do
  global_setup do
    require 'setup_tables_for_using'
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