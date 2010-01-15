= attr_lazy

== Summary

Rails plugin that provides the ability to specify attributes that will not be loaded
when the record is loaded from the database, until you explicitly refer to those
attributes. This is useful if the attributes are, say, text columns in the database
and you don't want the database to work as hard every time a record is loaded.

== Usage

Simply add an `attr_lazy` line to your model, like so:

  class Post < ActiveRecord::Base
    attr_lazy :body
  end
  
Now when you do a `find`, instead of doing a `SELECT *`, it does e.g. `SELECT id,
permalink, title, created_at, updated_at`, and only when you say `post.body` will
it pull the `body` column.

== Installation

  script/plugin install git://github.com/mcmire/attr_lazy.git
  
== Also See

http://refactormycode.com/codes/219-activerecord-lazy-attribute-loading-plugin-for-rails

== Author/License

(c) 2009 Elliot Winkler <elliot dot winkler at gmail dot com>. Released under the MIT license.