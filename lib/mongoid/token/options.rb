class Mongoid::Token::Options
  def initialize(options = {})
    @options = merge_defaults validate_options(options)
  end

  def length
    @options[:length]
  end

  def retry_count
    @options[:retry_count]
  end

  def contains
    @options[:contains]
  end

  def field_name
    @options[:field_name]
  end

  def skip_finders?
    @options[:skip_finders]
  end

  def override_to_param?
    @options[:override_to_param]
  end

  def pattern
    @options[:pattern] ||= case @options[:contains].to_sym
    when :alphanumeric
      "%s#{@options[:length]}"
    when :alpha
      "%w#{@options[:length]}"
    when :alpha_upper
      "%C#{@options[:length]}"
    when :alpha_lower
      "%c#{@options[:length]}"
    when :numeric
      "%d1,#{@options[:length]}"
    when :fixed_numeric
      "%d#{@options[:length]}"
    when :fixed_numeric_no_leading_zeros
      "%D#{@options[:length]}"
    end
  end

  private
  def validate_options(options)
    if options.has_key?(:retry)
      STDERR.puts "Mongoid::Token Deprecation Warning: option `retry` has been renamed to `retry_count`. `:retry` will be removed in v2.1"
      options[:retry_count] = options[:retry]
    end
    options
  end

  def merge_defaults(options)
    {
      :length => 4,
      :retry_count => 3,
      :contains => :alphanumeric,
      :field_name => :token,
      :skip_finders => false,
      :override_to_param => true,
    }.merge(options)
  end
end
