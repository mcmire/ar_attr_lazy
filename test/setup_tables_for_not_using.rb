ActiveRecord::Base.establish_connection(
  "adapter" => "sqlite3",
  "database" => ":memory:"
)

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
end

class Post < ActiveRecord::Base
  has_many :comments
  has_many :comments_with_default_scope, :class_name => "CommentWithDefaultScope"
  has_many :comments_with_select, :select => "name", :class_name => "Comment"
  belongs_to :author, :class_name => "User"
  has_and_belongs_to_many :tags
  has_and_belongs_to_many :tags_with_default_scope,
    :class_name => "TagWithDefaultScope",
    :join_table => "posts_tags",
    :association_foreign_key => "tag_id"
  has_and_belongs_to_many :tags_with_select,
    :select => "tags.name",
    :class_name => "Tag",
    :join_table => "posts_tags",
    :association_foreign_key => "tag_id"
end
class PostWithDefaultScope < ActiveRecord::Base
  set_table_name :posts
  default_scope :select => "title"
end

class Comment < ActiveRecord::Base
  belongs_to :post
end
class CommentWithDefaultScope < ActiveRecord::Base
  set_table_name :comments
  belongs_to :post
  default_scope :select => "name"
end

class Tag < ActiveRecord::Base
  has_and_belongs_to_many :posts
end
class TagWithDefaultScope < ActiveRecord::Base
  set_table_name :tags
  has_and_belongs_to_many :posts
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
post.tags << Tag.new(:name => "foo", :description => "The description and stuff")