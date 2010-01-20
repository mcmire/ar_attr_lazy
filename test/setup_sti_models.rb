# Have to have a separate file for these so that we can load them
# after we put attr_lazy in our models.

class SpecialPost < Post
end

class SpecialPostWithDefaultScope < PostWithDefaultScope
end

=begin
class Account < ActiveRecord::Base
  has_one :special_user
  has_one :special_avatar, :through => :user
end

class SpecialAvatar < Avatar
end

class SpecialUser < User
end

class Post < ActiveRecord::Base
  has_many :special_comments
  has_many :special_comments_with_default_scope, :class_name => "SpecialCommentWithDefaultScope"
  has_many :special_comments_with_select, :select => "name", :class_name => "SpecialComment"
  has_many :special_categories, :through => :post_categories
  has_many :special_categories_with_default_scope, :through => :post_categories,
    :class_name => "SpecialCategoryWithDefaultScope",
    :source => :post
  has_many :special_categories_with_select, :through => :post_categories,
    :select => "categories.name",
    :class_name => "SpecialCategory",
    :source => :post
  belongs_to :special_author, :class_name => "SpecialUser"
  has_and_belongs_to_many :special_tags, :join_table => 
  has_and_belongs_to_many :special_tags_with_default_scope,
    :class_name => "SpecialTagWithDefaultScope",
    :join_table => "posts_tags",
    :association_foreign_key => "tag_id"
  has_and_belongs_to_many :special_tags_with_select,
    :select => "tags.name",
    :class_name => "SpecialTag",
    :join_table => "posts_tags",
    :association_foreign_key => "tag_id"
end

class SpecialComment < Comment
end
class SpecialCommentWithDefaultScope < CommentWithDefaultScope
end

class SpecialTag < Tag
end
class SpecialTagWithDefaultScope < TagWithDefaultScope
end

class SpecialCategory < Category
end
class SpecialCategoryWithDefaultScope < CategoryWithDefaultScope
end
=end