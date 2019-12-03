require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Mongoid::Token::Options do
  let(:options) do
    Mongoid::Token::Options.new(length: 9999,
                                retry_count: 8888,
                                contains: :nonsense,
                                field_name: :not_a_token)
  end

  it "should have a length" do
    expect(options.length).to eq(9999)
  end

  it "should default to a length of 4" do
    expect(Mongoid::Token::Options.new.length).to eq(4)
  end

  it "should have a retry count" do
    expect(options.retry_count).to eq(8888)
  end

  it "should default to a retry count of 3" do
    expect(Mongoid::Token::Options.new.retry_count).to eq(3)
  end

  it "should have a list of characters to contain" do
    expect(options.contains).to eq(:nonsense)
  end

  it "should default to an alphanumeric set of characters to contain" do
    expect(Mongoid::Token::Options.new.contains).to eq(:alphanumeric)
  end

  it "should have a field name" do
    expect(options.field_name).to eq(:not_a_token)
  end

  it "should default to a field name of 'token'" do
    expect(Mongoid::Token::Options.new.field_name).to eq(:token)
  end

  it "should create a pattern" do
    expect(Mongoid::Token::Options.new.pattern).to eq("%s4")
  end

  describe "override_to_param" do
    let(:options) { Mongoid::Token::Options.new(override_to_param: false) }

    it "should be an option" do
      expect(options.override_to_param?).to eq false
    end

    it "should default to true" do
      expect(Mongoid::Token::Options.new.override_to_param?).to eq true
    end
  end

  describe "skip_finder" do
    let(:options) { Mongoid::Token::Options.new(skip_finders: true) }
    it "should be an option" do
      expect(options.skip_finders?).to eq true
    end

    it "should default to false" do
      expect(Mongoid::Token::Options.new.skip_finders?).to eq false
    end
  end

  describe "id" do
    context "when true" do
      let(:options) do
        Mongoid::Token::Options.new(id: true, field_name: :a_token)
      end

      it "returns '_id' sa the field name" do
        expect(options.field_name).to eq :_id
      end
    end

    context "when false" do
      let(:options) do
        Mongoid::Token::Options.new(id: false, field_name: :a_token)
      end

      it "returns the field_name option as the field name" do
        expect(options.field_name).to eq :a_token
      end
    end
  end

  describe :generate_on_init do
    let(:options) { Mongoid::Token::Options.new(params) }
    let(:params) { {} }
    subject { options.generate_on_init }

    it { is_expected.to be(false) }

    context "when id option set" do
      let(:params) { { id: true } }

      it { is_expected.to be(true) }
    end

    context "when id option is not set" do
      let(:params) { { id: false } }

      it { is_expected.to be(false) }
    end
  end
end
