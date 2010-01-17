class User < ActiveRecord::Base
  attr_lazy :bio
end

class Post < ActiveRecord::Base
  attr_lazy :body, :summary
end
class PostWithDefaultScope < ActiveRecord::Base
  attr_lazy :body, :summary
end

class Comment < ActiveRecord::Base
  attr_lazy :body
end
class CommentWithDefaultScope < ActiveRecord::Base
  attr_lazy :body
end

class Tag < ActiveRecord::Base
  attr_lazy :description
end
class TagWithDefaultScope < ActiveRecord::Base
  attr_lazy :description
end

class Category < ActiveRecord::Base
  attr_lazy :description
end
class CategoryWithDefaultScope < ActiveRecord::Base
  attr_lazy :description
end