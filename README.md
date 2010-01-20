# ar_attr_lazy

## Summary

A little gem for Rails that provides the ability to specify attributes that will not be loaded when the record is loaded from the database, until you explicitly refer to those attributes. This is useful when you have a lot of text columns in your table; in this case lazy-loading the text attributes is a good way to lend your server a hand and cut down on database access time.

## Installation/Usage

First:

1. Run `gem install ar_attr_lazy` (probably as root)
2. Add `config.gem 'ar_attr_lazy'` to environment.rb
3. Optionally run `rake gems:unpack` to vendor the gem

Then, simply add an `attr_lazy` line to your model, listing the attributes you want lazy-loaded. For instance:

    class Post < ActiveRecord::Base
      attr_lazy :body
    end
  
Now when you do a `find`, instead of doing a `SELECT *`, it does e.g. `SELECT id, permalink, title, created_at, updated_at`, and only when you say `post.body` will it pull the `body` column.

## Support

If you find a bug or have a feature request, I want to know about it! Feel free to file a [Github issue](http://github.com/mcmire/ar_attr_lazy/issues), or do one better and fork the [project on Github](http://github.com/mcmire/ar_attr_lazy) and send me a pull request or patch. Be sure to add tests if you do so, though.

You can also [email me](mailto:elliot.winkler@gmail.com), or [find me on Twitter](http://twitter.com/mcmire).

## Inspiration

<http://refactormycode.com/codes/219-activerecord-lazy-attribute-loading-plugin-for-rails>

## Author/License

(c) 2009-2010 Elliot Winkler. See LICENSE for details.