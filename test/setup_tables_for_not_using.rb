class Account < ActiveRecord::Base
  has_one :user
  has_one :avatar, :through => :user
end
class AccountWithDefaultScope < ActiveRecord::Base
  set_table_name :accounts
  default_scope :select => "name"
end

class Avatar < ActiveRecord::Base
  belongs_to :user
end

class User < ActiveRecord::Base
  has_one :avatar
  has_many :posts, :foreign_key => "author_id"
  belongs_to :account
end

class Post < ActiveRecord::Base
  has_many :comments
  has_many :comments_with_default_scope, :class_name => "CommentWithDefaultScope"
  has_many :comments_with_select, :select => "name", :class_name => "Comment"
  has_many :post_categories
  has_many :categories, :through => :post_categories
  has_many :categories_with_default_scope, :through => :post_categories,
    :class_name => "CategoryWithDefaultScope",
    :source => :post
  has_many :categories_with_select, :through => :post_categories,
    :select => "categories.name",
    :class_name => "Category",
    :source => :post
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

class PostCategory < ActiveRecord::Base
  belongs_to :post
  belongs_to :category
end
class Category < ActiveRecord::Base
  has_many :post_categories
  has_many :posts, :through => :post_categories
end
class CategoryWithDefaultScope < ActiveRecord::Base
  set_table_name :categories
  has_many :post_categories
  has_many :posts, :through => :post_categories
  default_scope :select => "categories.name"
end