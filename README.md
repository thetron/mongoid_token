# Mongoid::Token - Short snappy tokens for Mongoid documents

[![Build Status](https://secure.travis-ci.org/thetron/mongoid_token.png)](http://travis-ci.org/thetron/mongoid_token)

This library is a quick and simple way to generate unique, random tokens
for your mongoid documents, in the cases where you can't, or don't want
to use slugs, or the default MongoDB IDs.

Mongoid::Token can help turn this:

    http://myawesomewebapp.com/video/4dcfbb3c6a4f1d4c4a000012/edit

Into something more like this:

    http://myawesomewebapp.com/video/83xQ3r/edit


## Mongoid 3.x Support

As of version 1.1.0, Mongoid::Token now supports Mongoid 3.x.

> If you still require __Mongoid 2.x__ support, please install
> Mongoid::Token 1.0.0.


## Getting started

In your gemfile, add:

    gem 'mongoid_token', '~> 1.1.0'

Then update your bundle

    $ bundle update

In your Mongoid documents, just add `include Mongoid::Token` and the
`token` method will take care of all the setup, like so:

````
class Person
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Token

  field :first_name
  field :last_name

  token :length => 8
end

````

Obviously, this will create tokens of 8 characters long - make them as
short or as long as you require.

__Note:__ Mongoid::Token leverages Mongoid's 'safe mode' by
automatically creating a unique index on your documents using the token
field. In order to take advantage of this feature (and ensure that your
documents always have unique tokens) remember to create your indexes.

See 'Token collision/duplicate prevention' below for more details.


## Options

The `token` method has a couple of key options: `length`, which determines the
length (or maximum length, in some cases) and `contains`, which tells
Mongoid::Token which characters to use when generating the token.

The options for `contains` are as follows:

* `:alphanumeric` - letters (upper and lowercase) and numbers
* `:alpha` - letters (upper and lowercase) only
* `:numeric` - numbers only, anything from 1 character long, up to and
  `length`
* `:fixed_numeric` - numbers only, but with the number of characters always the same as `length`
* :fixed_numeric_no_leading_zeros - as above, but will never start with
zeros

You can also rename the token field, if required, using the
`:field_name` option:

* `token :contains => :numeric, :field_name => :purchase_order_number`

### Examples:

* `token :length => 8, :contains => :alphanumeric` generates something like `8Sdc98dQ`
* `token :length => 5, :contains => :alpha` gereates something like
  `ASlkj`
* `token :length => 4, :contains => :numeric` could generate anything
  from `0` upto `9999` - but in a random order
* `token :length => 4, :contains => :fixed_numeric` will generate
  anything from `0000` to `9999` in a random order
* token :length => 4, :contains => :fixed_numeric_no_leading_zeros will
generate anything from 1000 to 9999 in a random order


## Finders

The library also contains a finder method for looking up your documents
called `find_by_token`, e.g:

    Person.find_by_token('7dDn8q')


## Adding tokens to existing documents

If you've got an app with existing data that you would like to add
tokens to - all you need to do is save each of your models and they will
be assigned a token, if it's missing.


## Token collision/duplicate prevention

Mongoid::Token leverages Mongoid's 'safe mode' by
automatically creating a unique index on your documents using the token
field. In order to take advantage of this feature (and ensure that your
documents always have unique tokens) remember to create your indexes.

You can read more about indexes in the [Mongoid docs](http://mongoid.org/docs/indexing.html).

Additionally, Mongoid::Token will attempt to create a token 3 times
before eventually giving up and raising a
`Mongoid::Token::CollisionRetriesExceeded` exception. To take advantage
of this, one must set `persist_in_safe_mode = true` in your Mongoid
configuration.

The number of retry attempts is adjustable in the `token` method using the
`:retry` options. Set it to zero to turn off retrying.

* `token :length => 6, :retry => 4` Will retry token generation 4
times before bailing out
* `token :length => 3, :retry => 0` Retrying disabled


# Notes

If you find a problem, please [submit an issue](http://github.com/thetron/mongoid_token/issues) (and a failing test, if
you can). Pull requests and feature requests are always welcome and
greatly appreciated.

Thanks to everyone that has contributed to this gem over the past year,
in particular [stephan778](https://github.com/stephan778), [eagleas](https://github.com/eagleas) and [jamesotron](https://github.com/jamesotron). Many, many thanks - you guys rawk.
