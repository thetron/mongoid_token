require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Mongoid::Token::Finders do
  after do
    if Object.constants.include?(:Document)
      Object.send(:remove_const, :Document)
    end

    if Object.constants.include?(:AnotherDocument)
      Object.send(:remove_const, :AnotherDocument)
    end
  end

  it "define a finder based on a field_name" do
    klass = Class.new
    field = :another_token
    Mongoid::Token::Finders.define_custom_token_finder_for(klass, field)
    expect(klass.singleton_methods).to include(:"find_by_#{field}")
  end

  it "retrieve a document using the dynamic finder" do
    class Document; include Mongoid::Document; field :token; end
    document = Document.create!(token: "1234")
    Mongoid::Token::Finders.define_custom_token_finder_for(Document)
    expect(Document.find_by_token("1234")).to eq(document)
  end

  it 'retrieves multiple documents using the dynamic finder' do
    class Document; include Mongoid::Document; field :token; end
    document = Document.create!(token: "1234")
    document2 = Document.create!(token: "5678")
    Mongoid::Token::Finders.define_custom_token_finder_for(Document)
    expect(Document.find_by_token(["1234", "5678"])).to(
      eq([document, document2])
    )
  end
end
