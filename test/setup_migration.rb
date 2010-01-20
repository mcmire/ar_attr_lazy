ActiveRecord::Base.establish_connection(
  "adapter" => "sqlite3",
  "database" => ":memory:"
)

ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Schema.define do
    create_table :accounts, :force => true do |t|
      t.string :name, :null => false
    end
    
    create_table :avatars, :force => true do |t|
      t.string :type, :null => false, :default => "Account"
      t.integer :user_id, :null => false
      t.string :filename, :null => false
      t.text :data
    end

    create_table :users, :force => true do |t|
      t.string :type, :null => false, :default => "User"
      t.integer :account_id, :null => false
      t.string :login, :null => false
      t.string :password, :null => false
      t.string :email, :null => false
      t.string :name, :null => false
      t.text :bio, :null => false
    end

    create_table :posts, :force => true do |t|
      t.string :type, :null => false, :default => "Post"
      t.integer :author_id, :null => false
      t.string :title, :null => false
      t.string :permalink, :null => false
      t.text :body, :null => false
      t.text :summary, :null => false
    end

    create_table :comments, :force => true do |t|
      t.string :type, :null => false, :default => "Comment"
      t.integer :post_id, :null => false
      t.string :name, :null => false
      t.text :body, :null => false
    end

    create_table :tags, :force => true do |t|
      t.string :type, :null => false, :default => "Tag"
      t.string :name, :null => false
      t.text :description
    end

    create_table :posts_tags, :id => false, :force => true do |t|
      t.integer :post_id, :null => false
      t.integer :tag_id, :null => false
    end
    
    create_table :categories, :force => true do |t|
      t.string :type, :null => false, :default => "Category"
      t.string :name, :null => false
      t.text :description
    end
    
    create_table :post_categories, :force => true do |t|
      t.integer :post_id, :null => false
      t.integer :category_id, :null => false
    end
  end
end