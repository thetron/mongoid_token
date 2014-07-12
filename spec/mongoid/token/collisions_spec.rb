require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Mongoid::Token::Collisions do
  let(:document) { Object.new }
  describe "#resolve_token_collisions" do
    context "when there is a duplicate token" do
      let(:resolver) { double("Mongoid::Token::CollisionResolver") }

      before(:each) do
        resolver.stub(:field_name).and_return(:token)
        resolver.stub(:create_new_token_for){|doc|}
        document.class.send(:include, Mongoid::Token::Collisions)
        document.stub(:is_duplicate_token_error?).and_return(true)
      end

      context "and there are zero retries" do
        it "should raise an error after the first try" do
          resolver.stub(:retry_count).and_return(0)
          attempts = 0
          expect{document.resolve_token_collisions(resolver) { attempts += 1; raise Moped::Errors::OperationFailure.new("","") }}.to raise_error Mongoid::Token::CollisionRetriesExceeded
          expect(attempts).to eq 1
        end
      end

      context "and retries is set to 1" do
        it "should raise an error after retrying once" do
          resolver.stub(:retry_count).and_return(1)
          attempts = 0
          expect{document.resolve_token_collisions(resolver) { attempts += 1; raise Moped::Errors::OperationFailure.new("","") }}.to raise_error Mongoid::Token::CollisionRetriesExceeded
          expect(attempts).to eq 2
        end
      end

      context "and retries is greater than 1" do
        it "should raise an error after retrying" do
          resolver.stub(:retry_count).and_return(3)
          attempts = 0
          expect{document.resolve_token_collisions(resolver) { attempts += 1; raise Moped::Errors::OperationFailure.new("","") }}.to raise_error Mongoid::Token::CollisionRetriesExceeded
          expect(attempts).to eq 4
        end
      end

      context "and a different index is violated" do
        it "should bubble the operation failure" do
          document.stub(:is_duplicate_token_error?).and_return(false)
          resolver.stub(:retry_count).and_return(3)
          e = Moped::Errors::OperationFailure.new("command", {:details => "nope"})
          expect{document.resolve_token_collisions(resolver) { raise e }}.to raise_error(e)
        end
      end
    end
  end

  describe "#raise_collision_retries_exceeded_error" do
    before(:each) do
      document.class.send(:include, Mongoid::Token::Collisions)
    end

    it "should warn the rails logger" do
      message = nil

      stub_const("Rails", Class.new)

      logger = double("logger")
      logger.stub("warn"){ |msg| message = msg }
      Rails.stub("logger").and_return(logger)

      begin
        document.raise_collision_retries_exceeded_error(:token, 3)
      rescue
      end
      expect(message).to_not be_nil
    end

    it "should raise an error" do
      expect{ document.raise_collision_retries_exceeded_error(:token, 3) }.to raise_error(Mongoid::Token::CollisionRetriesExceeded)
    end
  end

  describe "#is_duplicate_token_error?" do
    before(:each) do
      document.class.send(:include, Mongoid::Token::Collisions)
    end
    context "when there is a duplicate key error" do
      it "should return true" do
        document.stub("token").and_return("tokenvalue123")
        err = double("Moped::Errors::OperationFailure")
        err.stub("details").and_return do
          {
            "err" => "E11000 duplicate key error index: mongoid_token_test.links.$token_1  dup key: { : \"tokenvalue123\" }",
            "code" => 11000,
            "n" => 0,
            "connectionId" => 130,
            "ok" => 1.0
          }
          document.is_duplicate_token_error?(err, document, :token)
        end
      end
    end
  end
end
