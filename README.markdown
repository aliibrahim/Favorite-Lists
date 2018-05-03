# Acts As Saveable (aka Favorite Lists)

Favorite Lists is a Ruby Gem specifically written for Rails/ActiveRecord models.
The main goals of this gem are:

- Allow any model to be saved on, like/dislike, upsaved/downsaved, for later reading and viewing etc.
- Allow any model to be saved under arbitrary scopes.
- Allow any model to saved.  In other words, saves do not have to come from a user,
  they can come from any model (such as a Group or Team).
- Provide an easy to write/read syntax.

## Installation

### Supported Ruby and Rails versions

* Ruby 1.8.7, 1.9.2, 1.9.3
* Ruby 2.0.0, 2.1.0
* Rails 3.0, 3.1, 3.2
* Rails 4.0, 4.1+

### Install

Just add the following to your Gemfile.

```ruby
gem 'acts_as_saveable', '~> 0.10.1'
```

And follow that up with a ``bundle install``.

### Database Migrations

Acts As Saveable uses a saves table to store all saving information.  To
generate and run the migration just use.

    rails generate acts_as_saveable:migration
    rake db:migrate

You will get a performance increase by adding in cached columns to your model's
tables.  You will have to do this manually through your own migrations.  See the
caching section of this document for more information.

## Usage

### Saveable Models

```ruby
class Post < ActiveRecord::Base
  acts_as_saveable
end

@post = Post.new(:name => 'my post!')
@post.save

@post.upsaved_by @user
@post.saves_for.size # => 1
```

### Like/Dislike Yes/No Up/Down

Here are some saving examples.  All of these calls are valid and acceptable.  The
more natural calls are the first few examples.

```ruby
@post.upsaved_by @user1
@post.downsave_from @user2
@post.save_by :saver => @user3
@post.save_by :saver => @user4, :saved => 'bad'
@post.save_by :saver => @user5, :saved => 'like'
```

By default all saves are positive, so `@user3` has cast a 'good' saved for `@post`.

`@user1`, `@user3`, and `@user5` all saved in favor of `@post`.

`@user2` and `@user4` on the other had has saved against `@post`.


Just about any word works for casting a saved in favor or against post.  Up/Down,
Like/Dislike, Positive/Negative... the list goes on-and-on.  Boolean flags `true` and
`false` are also applicable.

Revisiting the previous example of code.

```ruby
# positive saves
@post.upsaved_by @user1
@post.save_by :saver => @user3
@post.save_by :saver => @user5, :saved => 'like'

# negative saves
@post.downsave_from @user2
@post.save_by :saver => @user2, :saved => 'bad'

# tally them up!
@post.saves_for.size # => 5
@post.get_upsaves.size # => 3
@post.get_downsaves.size # => 2
```

Active Record scopes are provided to make life easier.

```ruby
@post.saves_for.up.by_type(User)
@post.saves_for.down
@user1.saves.up
@user1.saves.down
@user1.saves.up.by_type(Post)
```

Once scoping is complete, you can also trigger a get for the
saver/saveable

```ruby
@post.saves_for.up.by_type(User).savers
@post.saves_for.down.by_type(User).savers

@user.saves.up.for_type(Post).saveables
@user.saves.up.saveables
```

You can also 'unsaved' a model to remove a previous saved.

```ruby
@post.upsaved_by @user1
@post.unsaved_by @user1
```

Unsaving works for both positive and negative saves.

### Examples with scopes

You can add a scope to your saved

```ruby
# positive saves
@post.upsaved_by @user1, :save_scope => 'rank'
@post.save_by :saver => @user3, :save_scope => 'rank'
@post.save_by :saver => @user5, :saved => 'like', :save_scope => 'rank'

# negative saves
@post.downsave_from @user2, :save_scope => 'rank'
@post.save_by :saver => @user2, :saved => 'bad', :save_scope => 'rank'

# tally them up!
@post.find_saves_for(:save_scope => 'rank').size # => 5
@post.get_upsaves(:save_scope => 'rank').size # => 3
@post.get_downsaves(:save_scope => 'rank').size # => 2

# saveable model can be saved under different scopes
# by the same user
@post.save_by :saver => @user1, :save_scope => 'week'
@post.save_by :saver => @user1, :save_scope => 'month'

@post.saves_for.size # => 2
@post.find_saves_for(:save_scope => 'week').size # => 1
@post.find_saves_for(:save_scope => 'month').size # => 1
```
### Adding weights to your saves

You can add weight to your saved. The default value is 1.

```ruby
# positive saves
@post.upsaved_by @user1, :save_weight => 1
@post.save_by :saver => @user3, :save_weight => 2
@post.save_by :saver => @user5, :saved => 'like', :save_scope => 'rank', :save_weight => 3

# negative saves
@post.downsave_from @user2, :save_scope => 'rank', :save_weight => 1
@post.save_by :saver => @user2, :saved => 'bad', :save_scope => 'rank', :save_weight => 3

# tally them up!
@post.find_saves_for(:save_scope => 'rank').sum(:save_weight) # => 6
@post.get_upsaves(:save_scope => 'rank').sum(:save_weight) # => 6
@post.get_downsaves(:save_scope => 'rank').sum(:save_weight) # => 4
```

### The Saver

You can have your savers `acts_as_saver` to provide some reserve functionality.

```ruby
class User < ActiveRecord::Base
  acts_as_saver
end


@article.saves.size # => 1
```

To check if a saver has saved on a model, you can use ``saved_for?``.  You can
check how the saver saved by using ``saved_as_when_saved_for``.

```ruby
@user.up_saves @comment2
# user has not saved on @comment3

@user.saved_for? @comment1 # => true
@user.saved_for? @comment2 # => true
@user.saved_for? @comment3 # => false

@user.saved_as_when_saved_for @comment1 # => true, he liked it
@user.saved_as_when_saved_for @comment2 # => false, he didnt like it
@user.saved_as_when_saved_for @comment3 # => nil, he has yet to saved
```

You can also check whether the saver has saved up or down.

```ruby
@user.saves @comment1
# user has not saved on @comment3

@user.saved_up_on? @comment1 # => true
@user.saved_down_on? @comment1 # => false

@user.saved_down_on? @comment2 # => true
@user.saved_up_on? @comment2 # => false

@user.saved_up_on? @comment3 # => false
@user.saved_down_on? @comment3 # => false
```

Aliases for methods `saved_up_on?` and `saved_down_on?` are: `saved_up_for?`, `saved_down_for?`.

Also, you can obtain a list of all the objects a user has saved for.
This returns the actual objects instead of instances of the Vote model.
All objects are eager loaded

```ruby
@user.find_saved_items

@user.find_up_saved_items

@user.find_down_saved_items
```

Members of an individual model that a user has saved for can also be
displayed. The result is an ActiveRecord Relation.

```ruby
@user.get_saved Comment

@user.get_up_saved Comment

@user.get_down_saved Comment
```

### Registered Votes

Savers can only saved once per model.  In this example the 2nd saved does not count
because `@user` has already saved for `@shoe`.

```ruby
@user.save_up_for @shoe
@user.save_up_for @shoe

@shoe.saves # => 1
@shoe.save_up_for # => 1
```

To check if a saved counted, or registered, use `save_registered?` on your model
after saving.  For example:

```ruby
@hat.upsaved_by @user
@hat.save_registered? # => true

@hat.upsaved_by => @user
@hat.save_registered? # => false, because @user has already saved this way

@hat.dissaved_by @user
@hat.save_registered? # => true, because user changed their saved

@hat.saves.size # => 1
@hat.positives.size # => 0
@hat.negatives.size # => 1
```

To permit duplicates entries of a same saver, use option duplicate. Also notice that this
will limit some other methods that didn't deal with multiples saves, in this case, the last saved will be considered.

```ruby
@hat.save_by saver: @user, :duplicate => true
```

## Caching

To speed up perform you can add cache columns to your saveable model's table.  These
columns will automatically be updated after each saved.  For example, if we wanted
to speed up @post we would use the following migration:

```ruby
class AddCachedVotesToPosts < ActiveRecord::Migration
  def self.up
    add_column :posts, :cached_saves_total, :integer, :default => 0
    add_column :posts, :cached_saves_score, :integer, :default => 0
    add_column :posts, :cached_saves_up, :integer, :default => 0
    add_column :posts, :cached_saves_down, :integer, :default => 0
    add_column :posts, :cached_weighted_score, :integer, :default => 0
    add_column :posts, :cached_weighted_total, :integer, :default => 0
    add_column :posts, :cached_weighted_average, :float, :default => 0.0
    add_index  :posts, :cached_saves_total
    add_index  :posts, :cached_saves_score
    add_index  :posts, :cached_saves_up
    add_index  :posts, :cached_saves_down
    add_index  :posts, :cached_weighted_score
    add_index  :posts, :cached_weighted_total
    add_index  :posts, :cached_weighted_average

    # Uncomment this line to force caching of existing saves
    # Post.find_each(&:update_cached_saves)
  end

  def self.down
    remove_column :posts, :cached_saves_total
    remove_column :posts, :cached_saves_score
    remove_column :posts, :cached_saves_up
    remove_column :posts, :cached_saves_down
    remove_column :posts, :cached_weighted_score
    remove_column :posts, :cached_weighted_total
    remove_column :posts, :cached_weighted_average
  end
end
```

`cached_weighted_average` can be helpful for a rating system, e.g.:

Order by average rating:

```ruby
Post.order(:cached_weighted_average => :desc)
```

Display average rating:

```erb
<%= post.weighted_average.round(2) %> / 5
<!-- 3.5 / 5 -->
```

## Testing

All tests follow the RSpec format and are located in the spec directory.
They can be run with:

```
rake spec
```

## Changes  

### Fixes for saveable saver model  

In version 0.8.0, there are bugs for a model that is both saveable and saver.  
Some name-conflicting methods are renamed:
+ Renamed Saveable.saves to saves_for  
+ Renamed Saveable.saved to save_by,
+ Removed Saveable.save_by alias (was an alias for :save_up)
+ Renamed Saveable.unsave_for to unsave_by
+ Renamed Saveable.find_saves to find_saves_for
+ Renamed Saveable.up_saves to get_upsaves
  + and its aliases :get_true_saves, :get_ups, :get_upsaves, :get_for_saves
+ Renamed Saveable.down_saves to get_downsaves
  + and its aliases :get_false_saves, :get_downs, :get_downsaves


## License

Acts as saveable is released under the [MIT
License](http://www.opensource.org/licenses/MIT).

## TODO

- Pass in a block of options when creating acts_as.  Allow for things
  like disabling the aliasing

- The aliased methods are referred to by using the terms 'up/down' and/or
'true/false'.  Need to come up with guidelines for naming these methods.

- Create more aliases. Specifically for counting saves and finding saves.
