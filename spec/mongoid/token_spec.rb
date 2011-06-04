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
end

class Video
  include Mongoid::Document
  include Mongoid::Token

  field :name
  token :length => 8, :contains => :alpha
end

describe Mongoid::Token do
  before :each do
    @account = Account.create(:name => "Involved Pty. Ltd.")
    @link = Link.create(:url => "http://involved.com.au")
    @video = Video.create(:name => "Nyan nyan")
  end

  it "should have a token field" do
    @account.attributes.include?('token').should == true
    @link.attributes.include?('token').should == true
    @video.attributes.include?('token').should == true
  end

  it "should have a token of correct length" do
    @account.token.length.should == 16
    @link.token.length.should == 3
    @video.token.length.should == 8
  end

  it "should only generate unique tokens" do
    1000.times do
      @link = Link.create(:url => "http://involved.com.au")
      Link.count(:conditions => {:token => @link.token}).should == 1
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

    50.times do
      @video = Video.create(:name => "A test video")
      @video.token.gsub(/[A-Za-z]/, "").length.should == 0
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
    @video.to_param.should == @video.token
  end


  it "should be finable by token" do
    50.times do |index|
      Account.create(:name => "A random company #{index}")
    end
    Account.find_by_token(@account.token).id.should == @account.id
    Account.find_by_token(Account.last.token).id.should == Account.last.id
  end

  it "should create a token, if the token is missing" do
    @account.token = nil
    @account.save!
    @account.token.should_not be_nil
  end
end
