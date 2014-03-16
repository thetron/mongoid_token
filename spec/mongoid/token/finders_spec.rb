require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Mongoid::Token::Finders do
  before :each do
  end

  it "define a finder based on a field_name" do
    klass = Class.new
    field = :another_token
    Mongoid::Token::Finders.define_custom_token_finder_for(klass, field)
    klass.singleton_methods.should include(:"find_by_#{field}")
  end

  it "override the `find` method of the document" do
    klass = Class.new
    klass.define_singleton_method(:find) {|*args| :original_find }
    klass.define_singleton_method(:find_by) {|*args| :token_find }

    Mongoid::Token::Finders.define_custom_token_finder_for(klass)

    klass.find(BSON::ObjectId.new).should == :original_find
    klass.find(BSON::ObjectId.new, BSON::ObjectId.new).should == :original_find
    klass.find().should == :original_find
    klass.find(BSON::ObjectId.new, "token").should == :token_find
    klass.find("token").should == :token_find
  end

  it "retrieve a document using the dynamic finder" do
    class Document; include Mongoid::Document; field :token; end
    document = Document.create!(:token => "1234")
    Mongoid::Token::Finders.define_custom_token_finder_for(Document)
    Document.find_by_token("1234").should == document
  end

  it "retrieve a document using the `find` method" do
    class Document; include Mongoid::Document; field :token; end
    document = Document.create! :token => "1234"
    Mongoid::Token::Finders.define_custom_token_finder_for(Document)
    Document.find("1234").should == document
  end
end
