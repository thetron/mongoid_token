require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Mongoid::Token::Collisions do
  let(:document) { Object.new }
  describe "#resolve_token_collisions" do
    context "when there is a duplicate token" do
      let(:resolver) { double("Mongoid::Token::CollisionResolver") }

      before(:each) do
        allow(resolver).to receive(:field_name).and_return(:token)
        allow(resolver).to receive(:create_new_token_for) { |doc| }
        document.class.send(:include, Mongoid::Token::Collisions)
        allow(document).to receive(:duplicate_token_error?).and_return(true)
        allow(document.class).to receive(:resolvers).and_return([resolver])
      end

      context "and there are zero retries" do
        it "should raise an error after the first try" do
          allow(resolver).to receive(:retry_count).and_return(0)
          attempts = 0
          expect do
            document.resolve_token_collisions do
              attempts += 1
              raise Mongo::Error::OperationFailure
            end
          end.to raise_error Mongoid::Token::CollisionRetriesExceeded
          expect(attempts).to eq 1
        end
      end

      context "and retries is set to 1" do
        it "should raise an error after retrying once" do
          allow(resolver).to receive(:retry_count).and_return(1)
          attempts = 0
          expect do
            document.resolve_token_collisions do
              attempts += 1
              raise Mongo::Error::OperationFailure
            end
          end.to raise_error Mongoid::Token::CollisionRetriesExceeded
          expect(attempts).to eq 2
        end
      end

      context "and retries is greater than 1" do
        it "should raise an error after retrying" do
          allow(resolver).to receive(:retry_count).and_return(3)
          attempts = 0
          expect do
            document.resolve_token_collisions do
              attempts += 1
              raise Mongo::Error::OperationFailure
            end
          end.to raise_error Mongoid::Token::CollisionRetriesExceeded
          expect(attempts).to eq 4
        end
      end

      context "and a different index is violated" do
        it "should bubble the operation failure" do
          allow(document).to(receive(:duplicate_token_error?).
                             and_return(false))
          allow(resolver).to receive(:retry_count).and_return(3)
          e = Mongo::Error::OperationFailure.new("nope")
          expect do
            document.resolve_token_collisions { raise e }
          end.to raise_error(e)
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
      allow(logger).to receive("warn") { |msg| message = msg }
      allow(Rails).to receive("logger").and_return(logger)

      begin
        document.raise_collision_retries_exceeded_error(:token, 3)
      rescue
      end
      expect(message).to_not be_nil
    end

    it "should raise an error" do
      expect { document.raise_collision_retries_exceeded_error(:token, 3) }.to(
        raise_error(Mongoid::Token::CollisionRetriesExceeded),
      )
    end
  end

  describe "#duplicate_token_error?" do
    before(:each) do
      document.class.send(:include, Mongoid::Token::Collisions)
    end
    context "when there is a duplicate key error" do
      before do
        allow(document).to receive("token").and_return("tokenvalue123")
        allow(err).to(receive("message").and_return(message))
      end
      let(:err) { double("Mongo::Error::OperationFailure", code: 11_000) }
      subject { document.duplicate_token_error?(err, document, :token) }

      context "mongodb version 2.6, 3.0" do
        let(:message) do
          "insertDocument :: caused by :: 11000 "\
          "E11000 duplicate key error index: "\
          "mongoid_token_test.documents.$token_1 "\
          "dup key: { : \"tokenvalue123\" } (11000) "\
          "(on localhost:27017, legacy retry, attempt 1) "\
          "(on localhost:27017, legacy retry, attempt 1)"
        end

        it { is_expected.to be(true) }
      end

      context "mongodb version 4" do
        let(:message) do
          "E11000 duplicate key error collection: "\
          "mongoid_token_test.docs index: token_1 "\
          "dup key: { : \"tokenvalue123\" } (11000) "\
          "(on localhost:27017, legacy retry, attempt 1) "\
          "(on localhost:27017, legacy retry, attempt 1)"
        end

        it { is_expected.to be(true) }
      end
    end
  end
end
