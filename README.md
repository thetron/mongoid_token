# Mongoid::Token - Short snappy tokens for Mongoid documents

This library is a quick and simple way to generate unique, random tokens
for your mongoid documents, in the cases where you can't, or don't want
to use slugs, or the default MongoDB IDs.

Mongoid::Token can help turn this:

    http://bestwebappever.com/video/4dcfbb3c6a4f1d4c4a000012/edit

Into something more like this:

    http://bestwebappever.com/video/83xQ3r/edit


## Getting started

In your gemfile, add:

    gem 'mongoid_token', '~> 0.9.1'

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


## Options

The `token` method takes two options: `length`, which determines the
length (or maximum length, in some cases) and `contains`, which tells
Mongoid::Token which characters to use when generating the token.

The options for `contains` are as follows:

* `:alphanumeric` - letters (upper and lowercase) and numbers
* `:alpha` - letters (upper and lowercase) only
* `:numeric` - numbers only, anything from 1 character long, up to and
  `length`
* `:fixed_numeric` - numbers only, but with the number of characters always the same as `length`

### Examples:

* `token :length => 8, :contains => :alphanumeric` generates something like `8Sdc98dQ`
* `token :length => 5, :contains => :alpha` gereates something like
  `ASlkj`
* `token :length => 4, :contains => :numeric` could generate anything
  from `0` upto `9999` - but in a random order
* `token :length => 4, :contains => :fixed_numeric` will generate
  anything from `0000` to `9999` in a random order


## Finders

The library also contains a finder method for looking up your documents
called `find_by_token`, e.g:

    Person.find_by_token('7dDn8q')


## Adding tokens to existing documents

If you've got an app with existing data that you would like to add
tokens to - all you need to do is save each of your models and they will
be assigned a token, if it's missing.


# Notes

If you find a problem, please [submit an issue](http://github.com/thetron/mongoid_token/issues) (and a failing test, if
you can). Pull requests and feature requests are always welcome.
