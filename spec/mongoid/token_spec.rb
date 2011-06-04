require File.join(File.dirname(__FILE__), %w[.. spec_helper])

class Post
  include Mongoid::Document
  include Mongoid::Publishable
  field :title
end

describe Mongoid::Publishable do
  before :each do
    @draft = Post.create(:published_at => nil)
    @published = Post.create(:published_at => Time.now - 5.minutes)
    @scheduled = Post.create(:published_at => Time.now + 12.hours)
  end

  it "should have a date and timestamp to represent publish state" do
    Post.should have_field(:published_at).of_type(DateTime).with_default_value_of(nil)
  end
  
  it "should be published if the published date is in the past" do
    @published.is_draft?.should equal false
    @published.is_published?.should equal true
    @published.is_scheduled?.should equal false
  end

  it "should be a draft if the published date is not set" do
    @draft.is_draft?.should == true
    @draft.is_published?.should == false
    @draft.is_scheduled?.should == false
  end

  it "should be scheduled if the published date is in the future" do
    @scheduled.is_draft?.should == false
    @scheduled.is_published?.should == false
    @scheduled.is_scheduled?.should == true
  end

  it "should be publishable" do
    @draft.should respond_to :publish!
    @draft.publish!
    @draft.is_published?.should equal true
    @draft.published_at.to_i.should <= Time.now.to_i
  end

  it "should be unpublishable" do
    @published.should respond_to :unpublish!
    @published.unpublish!
    @published.is_draft?.should equal true
    @published.published_at.should be nil
  end

  it "should be scheduleable" do
    @draft.should respond_to :schedule!
    future = (Time.now + 12.hours).to_datetime
    @draft.schedule!(future)
    @draft.is_scheduled?.should equal true
    @draft.published_at.to_i.should == future.to_i
  end

  it "should return all draft models" do
    Post.drafts.count.should equal 1
    Post.drafts.first.should == @draft
  end

  it "should return all published models" do
    Post.published.count.should equal 1
    Post.published.first.should == @published
  end

  it "should return all scheduled models" do
    Post.scheduled.count.should equal 1
    Post.scheduled.first.should == @scheduled
  end

  it "should return published posts in descending date order" do
    @draft.publish!
    @scheduled.publish!
    last_stamp = Time.now
    Post.published.each do |post|
      post.published_at.should <= last_stamp
      last_stamp = post.published_at
    end
  end

  it "should return scheduled posts in ascending date order" do
    @draft.schedule!(Time.now + 1.hour)
    @published.schedule!(Time.now + 5.days)
    last_stamp = Time.now
    Post.scheduled.each do |post|
      post.published_at.should > last_stamp
      last_stamp = post.published_at
    end
  end
end
