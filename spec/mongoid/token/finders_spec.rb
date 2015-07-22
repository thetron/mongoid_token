require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Mongoid::Token::Finders do
  after do
    Object.send(:remove_const, :Document) if Object.constants.include?(:Document)
    Object.send(:remove_const, :AnotherDocument) if Object.constants.include?(:AnotherDocument)
    Object.send(:remove_const, :EmbeddedDocument) if Object.constants.include?(:EmbeddedDocument)
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

  it 'retrieves multiple documents using the dynamic finder' do
    class Document; include Mongoid::Document; field :token; end
    document = Document.create!(:token => "1234")
    document2 = Document.create!(:token => "5678")
    Mongoid::Token::Finders.define_custom_token_finder_for(Document)
    Document.find_by_token(["1234", "5678"]).should == [document, document2]
  end

  it "retrieve a document using the `find` method" do
    class AnotherDocument; include Mongoid::Document; field :token; end
    document = AnotherDocument.create! :token => "1234"
    Mongoid::Token::Finders.define_custom_token_finder_for(AnotherDocument)
    AnotherDocument.find("1234").should == document
  end

  it 'retrieves multiple documents using the `find` method' do
    class AnotherDocument; include Mongoid::Document; field :token; end
    document = AnotherDocument.create! :token => "1234"
    document2 = AnotherDocument.create! :token => "5678"
    Mongoid::Token::Finders.define_custom_token_finder_for(AnotherDocument)
    AnotherDocument.find(["1234", "5678"]).should == [document, document2]
  end

  it 'retrieves embedded documents using the dynamic finder' do
    class Document; include Mongoid::Document; field :token; embeds_many :embedded_documents; end
    class EmbeddedDocument; include Mongoid::Document; field :token; embedded_in :document; end

    document = Document.create!(:token => "1234")
    embedded_document = EmbeddedDocument.create(token: "5678", document: document)

    Mongoid::Token::Finders.define_custom_token_finder_for(EmbeddedDocument)
    document.embedded_documents.find_by_token("5678").should == embedded_document
  end

  it "retrieve a document using the `find` method" do
    class Document; include Mongoid::Document; field :token; embeds_many :embedded_documents; end
    class EmbeddedDocument; include Mongoid::Document; field :token; embedded_in :document; end

    document = Document.create!(:token => "1234")
    embedded_document = EmbeddedDocument.create(token: "5678", document: document)

    Mongoid::Token::Finders.define_custom_token_finder_for(EmbeddedDocument)
    document.embedded_documents.find("5678").should == embedded_document
  end
end
