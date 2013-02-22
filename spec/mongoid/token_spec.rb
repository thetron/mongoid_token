require File.join(File.dirname(__FILE__), %w[.. spec_helper])

class Account
  include Mongoid::Document
  include Mongoid::Token
  field :name
  token :length => 16, :contains => :fixed_numeric
end

class Person
  include Mongoid::Document
  include Mongoid::Token
  field :email
  token :length => 6, :contains => :numeric
end

class Link
  include Mongoid::Document
  include Mongoid::Token

  field :url
  token :length => 3, :contains => :alphanumeric

  validates :url, :presence => true
end

class FailLink
  include Mongoid::Document
  include Mongoid::Token
  field :url
  token :length => 3, :contains => :alphanumeric, :retry => 0
end

class Video
  include Mongoid::Document
  include Mongoid::Token

  field :name
  token :length => 8, :contains => :alpha, :field_name => :vid
end

class Image
  include Mongoid::Document
  include Mongoid::Token

  field :url
  token :length => 8, :contains => :fixed_numeric_no_leading_zeros
end

class Event
  include Mongoid::Document
  include Mongoid::Token

  field :name
  token :length => 8, :contains => :alpha_lower
end

class Node
  include Mongoid::Document
  include Mongoid::Token

  field :name
  token :length => 8, :contains => :fixed_numeric

  embedded_in :cluster
end

class Cluster
  include Mongoid::Document

  field :name

  embeds_many :nodes
end

class Prefixed
  include Mongoid::Document
  include Mongoid::Token

  field :name

  token :length => 8, :contains => :alphanumeric, :prefix => 'TST-'
end

describe Mongoid::Token do
  before :each do
    @account = Account.create(:name => "Involved Pty. Ltd.")
    @link = Link.create(:url => "http://involved.com.au")
    @video = Video.create(:name => "Nyan nyan")
    @image = Image.create(:url => "http://involved.com.au/image.png")
    @event = Event.create(:name => "Super cool party!")
    @prefixed = Prefixed.create(:name => 'Test')

    Account.create_indexes
    Link.create_indexes
    FailLink.create_indexes
    Video.create_indexes
    Image.create_indexes
    Event.create_indexes
    Node.create_indexes
    Prefixed.create_indexes
  end

  it "should have a token field" do
    @account.attributes.include?('token').should == true
    @link.attributes.include?('token').should == true
    @video.attributes.include?('vid').should == true
    @prefixed.attributes.include?('token').should == true
  end

  it "should have a token of correct length" do
    @account.token.length.should == 16
    @link.token.length.should == 3
    @video.vid.length.should == 8
    @image.token.length.should == 8
  end

  it "should only generate unique tokens" do
    Link.create_indexes
    1000.times do
      @link = Link.create(:url => "http://involved.com.au")
      Link.where(:token => @link.token).count.should == 1
    end
  end

  it "should have a token containing only the specified characters" do
    50.times do
      @account = Account.create(:name => "Smith & Co. LLC")
      @person = Person.create(:email => "some_random_235@gmail.com")

      @account.token.gsub(/[0-9]/, "").length.should == 0
      @person.token.gsub(/[0-9]/, "").length.should == 0
    end

    50.times do
      @link = Link.create(:url => "http://involved.com.au")
      @link.token.gsub(/[A-Za-z0-9]/, "").length.should == 0
    end

    50.times do |index|
      @video = Video.create(:name => "A test video")
      @video.vid.gsub(/[A-Za-z]/, "").length.should == 0
    end
    
    50.times do |index|
      @event = Event.create(:name => "Super cool party!2")
      @event.token.gsub(/[a-z]/, "").length.should == 0
    end
  end

  it "should create the only after the first save" do
    @account = Account.new(:name => "Smith & Co. LLC")
    @account.token.should be_nil
    @account.save!
    @account.token.should_not be_nil
    initial_token = @account.token
    @account.save!
    initial_token.should == @account.token
  end

  it "should return the token as its parameter" do
    @account.to_param.should == @account.token
    @link.to_param.should == @link.token
    @video.to_param.should == @video.vid
  end


  it "should be findable by token" do
    50.times do |index|
      Account.create(:name => "A random company #{index}")
    end
    Account.find_by_token(@account.token).id.should == @account.id
    Account.find_by_token(Account.last.token).id.should == Account.last.id

    10.times do |index|
      Video.create(:name => "Lord of the Rings, Super Special Edition part #{index}")
    end
    Video.find_by_token(@video.vid).id.should == @video.id
    Video.find_by_token(Video.last.vid).id.should == Video.last.id
  end

  it "should create a token, if the token is missing" do
    @account.token = nil
    @account.save!
    @account.token.should_not be_nil
  end

  it "should fail with an exception after 3 retries" do
    Link.destroy_all
    Link.create_indexes

    @first_link = Link.create(:url => "http://involved.com.au")
    Link.any_instance.stub(:generate_token).and_return(@first_link.token)
    @link = Link.new(:url => "http://fail.com")

    expect { @link.save! }.to raise_error(Mongoid::Token::CollisionRetriesExceeded)

    Link.count.should == 1
    Link.where(:token => @first_link.token).count.should == 1
  end

  it "tries to resolve collisions when instantiated with create!" do
    link = Link.create!(url: "http://example.com/1")

    Link.any_instance.stub(:generate_token).and_return(link.token)

    expect { Link.create!(url: "http://example.com/2") }.to raise_error(Mongoid::Token::CollisionRetriesExceeded)
  end

  it "should not raise a custom error if an operation failure is thrown for another reason" do
    link = Link.new
    lambda{ link.save! }.should_not raise_error(Mongoid::Token::CollisionRetriesExceeded)
    link.valid?.should == false
  end

  it "should not raise a custom exception if retries are set to zero" do
    FailLink.destroy_all
    FailLink.create_indexes

    @first_link = FailLink.create(:url => "http://involved.com.au")
    Link.any_instance.stub(:generate_token).and_return(@first_link.token)
    @link = FailLink.new(:url => "http://fail.com")

    lambda{ @link.save! }.should_not raise_error(Mongoid::Token::CollisionRetriesExceeded)
  end

  it "should create unique indexes on embedded documents" do
    @cluster = Cluster.create(:name => "CLUSTER_001")
    5.times do |index|
      @cluster.nodes.create!(:name => "NODE_#{index.to_s.rjust(3, '0')}")
    end

    @cluster.nodes.each do |node|
      node.attributes.include?('token').should == true
      node.token.match(/[0-9]{8}/).should_not == nil
    end
  end

  describe "with :fixed_numeric_not_null" do
    it "should not start with 0" do
      1000.times do
        image = Image.create(:url => "http://something.com/image.png")
        image.token.should_not start_with "0"
      end
    end
  end

  describe "when using a prefix" do
    before {
      Prefixed.destroy_all
      Prefixed.create_indexes
    }

    it "should allow a prefix to be set" do
      prefixed = Prefixed.create!(name: "Test")
      Prefixed.count.should == 1
      prefixed.token.should =~ /^TST\-\w{8}$/
    end

    it "should be findable when using a prefix" do
      prefixed = Prefixed.create!(name: "Test")
      Prefixed.find_by_token(Prefixed.first.token).should == Prefixed.first
    end

    it "should use a prefix on retries" do
      first_prefix = Prefixed.create!(name: "Test")
      Prefixed.any_instance.stub(:generate_token).and_return(first_prefix.token, 'aaaaaaaa')
      next_prefixed = Prefixed.create!(name: "Test")

      next_prefixed.token.should == 'TST-aaaaaaaa'
    end
  end
end
