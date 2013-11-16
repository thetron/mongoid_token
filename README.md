# Mongoid::Token - Short snappy tokens for Mongoid documents

[![Build Status](https://secure.travis-ci.org/thetron/mongoid_token.png)](http://travis-ci.org/thetron/mongoid_token)

This library is a quick and simple way to generate unique, random tokens
for your mongoid documents, in the cases where you can't, or don't want
to use slugs, or the default MongoDB ObjectIDs.

Mongoid::Token can help turn this:

    http://bestappever.com/video/4dcfbb3c6a4f1d4c4a000012

Into something more like this:

    http://bestappever.com/video/8tmQ9p


## Getting started

In your gemfile, add:

    gem 'mongoid_token', '~> 2.0.0'

Then update your bundle

    $ bundle update

In your Mongoid documents, just add `include Mongoid::Token` and the
`token` method will take care of all the setup, like so:

```ruby
class Person
  include Mongoid::Document
  include Mongoid::Token

  field :name

  token
end

```

And that's it! There's lots of configuration options too - which are all
listed [below](#configuration). By default, the `token` method will
create tokens 4 characters long, containing random alphanumeric characters.

__Note:__ Mongoid::Token leverages Mongoid's 'safe mode' by
automatically creating a unique index on your documents using the token
field. In order to take advantage of this feature (and ensure that your
documents always have unique tokens) remember to create your indexes.


## Finders

By default, the gem will override the existing `find` method in Mongoid,
in order to search for documents based on their token first (although
the default behaviour of ObjectIDs is also there). You can disable these
with the [`skip_finders` configuration option](#skip-finders-skip_finders).

```ruby
Video.find("x3v98")
Account.find("ACC-123456")
```


## Configuration

### Tokens

As of `Mongoid::Token` 2.0.0, you can now choose between two different
systems for managing how your tokens look. 

For simple setup, you can use
combination of the [`length`](#length-length) and [`contains`](#contains-contains), which modify the length and
types of characters to use.

For when you need to generate more complex tokens, you can use the
[`pattern`](#pattern-pattern) option, which allows for very low-level control of the precise
structure of your tokens, as well as allowing for static strings, like
prefixes, infixes or suffixes.

#### Length (`:length`)

This one is easy, it's just an integer. 

__Example:__

```ruby
token :length => 6 # Tokens are now of length 6
token :length => 12 # Whow, whow, whow. Slow down egghead.
```

You get the idea.

The only caveat here is that if used in combination with the 
`:contains => :numeric` option, tokens may vary in length _up to_ the
specified length.

#### Contains (`:contains`)

Contains has 7 different options:

* `:alphanumeric` - contains uppercase & lowercase characters, as well
as numbers
* `:alpha` - contains only uppercase & lowercase characters
* `:alpha_upper` - contains only uppercase letters
* `:alpha_lower` - contains only lowercase letters
* `:numeric` - integer, length may be shorter than `:length`
* `:fixed_numeric` - integer, but will always be of length `:length`
* `:fixed_numeric_no_leading_zeros` - same as `:fixed_numeric`, but will
never start with zeros

__Examples:__
```ruby
token :contains => :alpha_upper, :length => 8
token :contains => :fixed_numeric
```

#### Patterns (`:pattern`)

New in 2.0.0, patterns allow you fine-grained control over how your
tokens look. It's great for generating random data that has a
requirements to also have some basic structure. If you use the
`:pattern` option, it will override both the `:length` and `:contains`
options.

This was designed to operate in a similar way to something like `strftime`,
if the syntax offends you - please open an issue, I'd love to get some
feedback here and better refine how these are generated.

Any characters in the string are treated as static, except those that are
proceeded by a `%`. Those special characters represent a single, randomly
generated character, and are as follows:

* `%s` - any uppercase, lowercase, or numeric character
* `%w` - any uppercase, or lowercase character
* `%c` - any lowercase character
* `%C` - any uppercase character
* `%d` - any digit
* `%D` - any non-zero digit

__Example:__

```ruby
token :pattern => "PRE-%C%C-%d%d%d%d" # Generates something like: 'PRE-ND-3485'
```

You can also add a repetition modifier, which can help improve readability on
more complex patterns. You simply add any integer after the letter.

__Examples:__

```ruby
token :pattern => "APP-%d6" # Generates something like; "APP-638924"
```

### Field Name (`:field_name`)

This allows you to change the field name used by `Mongoid::Token`
(default is `:token`). This is particularly handy when you're wanting to
use multiple tokens one a single document.

__Examples:__
```ruby
token :length => 6
token :field_name => :sharing_token, :length => 12
token :field_name => :yet_another
```


### Skip Finders (`:skip_finders`)

This will prevent the gem from creating the customised finders and
overrides for the default `find` behaviour used by Mongoid.

__Example:__
```ruby
token :skip_finders => true
```


### Override to_param (`:override_to_param`)

By default, `Mongoid::Token` will override to_param, to make it an easy
drop-in replacement for the default ObjectIDs. If needed, you can turn
this behaviour off:

__Example:__
```ruby
token :override_to_param => false
```


### Retry Count (`:retry_count`)

In the event of a token collision, this gem will attempt to try three
more times before raising a `Mongoid::Token::CollisionRetriesExceeded`
error. If you're wanting it to try harder, or less hard, then this
option is for you.

__Examples:__
```ruby
token :retry_count => 9
token :retry_count => 0
```

# Notes

If you find a problem, please [submit an issue](http://github.com/thetron/mongoid_token/issues) (and a failing test, if
you can). Pull requests and feature requests are always welcome and
greatly appreciated.

Thanks to everyone that has contributed to this gem over the past year.
Many, many thanks - you guys rawk.


## Contributors:

Thanks to everyone who has provided support for this gem over the years.
In particular: [olliem](https://github.com/olliem),
[msolli](https://github.com/msolli),
[siong1987](https://github.com/siong1987),
[stephan778](https://github.com/stephan778),
[eagleas](https://github.com/eagleas), and
[jamesotron](https://github.com/jamesotron).
