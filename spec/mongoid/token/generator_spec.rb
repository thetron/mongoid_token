require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Mongoid::Token::Generator do
  describe "#generate" do
    it "generates lowercase characters" do
      100.times{ expect(Mongoid::Token::Generator.generate("%c")).to match(/[a-z]/) }
    end

    it "generates uppercase characters" do
      100.times{ expect(Mongoid::Token::Generator.generate("%C")).to match(/[A-Z]/) }
    end

    it "generates digits" do
      100.times{ expect(Mongoid::Token::Generator.generate("%d")).to match(/[0-9]/) }
    end

    it "generates non-zero digits" do
      100.times{ expect(Mongoid::Token::Generator.generate("%D")).to match(/[1-9]/) }
    end

    it "generates alphanumeric characters" do
      100.times{ expect(Mongoid::Token::Generator.generate("%s")).to match(/[A-Za-z0-9]/) }
    end

    it "generates upper and lowercase characters" do
      100.times{ expect(Mongoid::Token::Generator.generate("%w")).to match(/[A-Za-z]/) }
    end

    it "generates URL-safe punctuation" do
      100.times{ expect(Mongoid::Token::Generator.generate("%p")).to match(/[\.\-\_\=\+\$]/) }
    end

    it "generates patterns of a fixed length" do
      100.times{ expect(Mongoid::Token::Generator.generate("%s8")).to match(/[A-Za-z0-9]{8}/) }
    end

    it "generates patterns of a variable length" do
      100.times{ expect(Mongoid::Token::Generator.generate("%s1,5")).to match(/[A-Za-z0-9]{1,5}/) }
    end

    it "generates patterns with static prefixes/suffixes" do
      100.times { expect(Mongoid::Token::Generator.generate("prefix-%s4-suffix")).to match(/prefix\-[A-Za-z0-9]{4}\-suffix/) }
    end

    it "generates more complex patterns" do
      100.times { expect(Mongoid::Token::Generator.generate("pre-%d4-%C3-%d4")).to match(/pre\-[0-9]{4}\-[A-Z]{3}\-[0-9]{4}/) }
    end
  end
end
