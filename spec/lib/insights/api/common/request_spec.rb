describe Insights::API::Common::Request do
  let(:request_object) do
    headers = ActionDispatch::Http::Headers.from_hash({})
    ActionDispatch::Request.new(headers)
  end

  let(:request_bad) do
    {
      :headers      => { 'blah' => 'blah' },
      :original_url => 'bad_url'
    }
  end

  let(:request_good) do
    {
      :headers      => forwardable_good.merge('x-some-header' => "some_value"),
      :original_url => 'https://example.com'
    }
  end

  let(:forwardable_good) do
    {
      'x-rh-identity'            => encoded_user_hash,
      'x-rh-insights-request-id' => "01234567-89ab-cdef-0123-456789abcde",
    }
  end

  context "with a good request" do
    around do |example|
      described_class.with_request(request_good) do |instance|
        @instance = instance
        example.call
      end
    end

    it "#original_url" do
      expect(@instance.original_url).to eq "https://example.com"
    end

    describe "#headers" do
      it "return a headers object" do
        expect(@instance.headers).to be_a(ActionDispatch::Http::Headers)
      end

      it "allows case-insensitive lookup" do
        expect(@instance.headers["X-Rh-Identity"]).to eq encoded_user_hash
      end
    end

    it "#user" do
      expect(@instance.user).to be_a(Insights::API::Common::User)
    end

    it "#tenant" do
      expect(@instance.tenant).to eq(default_account_number)
    end

    it "#system" do
      expect(@instance.system).to be_nil
    end

    it "#auth_type" do
      expect(@instance.auth_type).to eq("basic-auth")
    end

    it "#to_h" do
      expect(@instance.to_h).to eq(:headers => forwardable_good, :original_url => "https://example.com")
    end

    it "#user" do
      expect(@instance.user).to be_a(Insights::API::Common::User)
    end

    it "#request_id" do
      expect(@instance.request_id).to eq "01234567-89ab-cdef-0123-456789abcde"
    end

    it "#identity" do
      expect(@instance.identity).to eq default_user_hash
    end

    it "#to_h" do
      expect(@instance.to_h).to eq(:headers => forwardable_good, :original_url => "https://example.com")
    end
  end

  context "with a bad request" do
    around do |example|
      described_class.with_request(request_bad) do |instance|
        @instance = instance
        example.call
      end
    end

    it "#user" do
      expect { @instance.user }.to raise_exception(Insights::API::Common::IdentityError, 'x-rh-identity not found')
    end

    it "#identity" do
      expect { @instance.identity }.to raise_exception(Insights::API::Common::IdentityError, 'x-rh-identity not found')
    end

    it "#request_id" do
      expect(@instance.request_id).to be_nil
    end
  end


  context "with a good system request" do
    let(:system_request) do
      {
        :headers      => {
          'x-rh-identity'            => encoded_system_hash,
          'x-rh-insights-request-id' => "01234567-89ab-cdef-0123-456789abcde",
        },
        :original_url => 'https://example.com'
      }
    end

    around do |example|
      described_class.with_request(system_request) do |instance|
        @instance = instance
        example.call
      end
    end

    it "#original_url" do
      expect(@instance.original_url).to eq "https://example.com"
    end

    describe "#headers" do
      it "return a headers object" do
        expect(@instance.headers).to be_a(ActionDispatch::Http::Headers)
      end

      it "allows case-insensitive lookup" do
        expect(@instance.headers["X-Rh-Identity"]).to eq encoded_system_hash
      end
    end

    it "#user" do
      expect(@instance.user).to be_a(Insights::API::Common::User)
    end

    it "#tenant" do
      expect(@instance.tenant).to eq(default_account_number)
    end

    it "#system" do
      expect(@instance.system).to be_a(Insights::API::Common::System)
    end

    it "#auth_type" do
      expect(@instance.auth_type).to eq("cert-auth")
    end

    it "#request_id" do
      expect(@instance.request_id).to eq "01234567-89ab-cdef-0123-456789abcde"
    end

    it "#identity" do
      expect(@instance.identity).to eq default_system_hash
    end
  end

  describe ".with_request / .current=" do
    it 'with an ActionDispatch::Request' do
      described_class.with_request(request_object) do |instance|
        expect(described_class.current).to eq instance
        expect(instance).to be_a(described_class)
        expect(instance.headers).to be_a(ActionDispatch::Http::Headers)
      end
    end

    it 'with an Insights::API::Common::Request' do
      common_request = described_class.new(request_good)
      described_class.with_request(common_request) do |instance|
        expect(described_class.current).to eq instance
        expect(instance).to be_a(described_class)
        expect(instance.headers).to be_a(ActionDispatch::Http::Headers)
      end
    end

    it 'with a specific Hash' do
      described_class.with_request(request_good) do |instance|
        expect(described_class.current).to eq instance
        expect(instance).to be_a(described_class)
        expect(instance.headers).to be_a(ActionDispatch::Http::Headers)
      end
    end

    it 'with an invalid Hash' do
      expect do
        described_class.with_request({}) {}
      end.to raise_exception(ArgumentError)
    end

    it 'with invalid argument' do
      expect do
        described_class.with_request(rand(10_000).to_s) {}
      end.to raise_exception(ArgumentError)
    end

    it 'with nil' do
      described_class.with_request(nil) do |instance|
        expect(described_class.current).to eq instance
        expect(instance).to be_nil
      end
    end

    it "will clear .current after the block finishes" do
      expect(described_class.current).to be_nil
      described_class.with_request(request_good) do |_instance|
        expect(described_class.current).to_not be_nil
      end
      expect(described_class.current).to be_nil
    end
  end

  describe ".current" do
    it "when the request is set" do
      described_class.with_request(request_good) do |instance|
        expect(described_class.current).to eq instance
      end
    end

    it "when the request is not set" do
      expect(described_class.current).to be_nil
    end
  end

  describe ".current!" do
    it "when the request is set" do
      described_class.with_request(request_good) do |instance|
        expect(described_class.current!).to eq instance
      end
    end

    it "when the request is not set" do
      expect do
        described_class.current!
      end.to raise_exception(Insights::API::Common::RequestNotSet)
    end
  end

  describe ".current_forwardable" do
    it "only includes expected headers" do
      described_class.with_request(request_good) do
        hash = described_class.current_forwardable
        expect(hash).to eq forwardable_good
        expect(hash).to_not include("x-some-header")
      end
    end

    it "raises exception when headers not set" do
      expect do
        described_class.current_forwardable
      end.to raise_exception(Insights::API::Common::RequestNotSet)
    end
  end

  describe ".optional_auth? and .required_auth?" do
    it "handle fully qualified openapi.json path with major version" do
      described_class.with_request(request_good.merge(
                                     :original_url => "https://example.com/api/micro-service/v1/openapi.json"
                                   )) do
        expect(described_class.current.optional_auth?).to be_truthy
        expect(described_class.current.required_auth?).to be_falsy
      end
    end

    it "handle fully qualified openapi.json path with major and minor version" do
      described_class.with_request(request_good.merge(
                                     :original_url => "https://example.com/api/micro-service/v1.0/openapi.json"
                                   )) do
        expect(described_class.current.optional_auth?).to be_truthy
        expect(described_class.current.required_auth?).to be_falsy
      end
    end

    it "handle short openapi.json path with major version" do
      described_class.with_request(request_good.merge(
                                     :original_url => "https://example.com/api/v1/openapi.json"
                                   )) do
        expect(described_class.current.optional_auth?).to be_truthy
        expect(described_class.current.required_auth?).to be_falsy
      end
    end

    it "handle short openapi.json path with major and minor version" do
      described_class.with_request(request_good.merge(
                                     :original_url => "https://example.com/api/v1.0/openapi.json"
                                   )) do
        expect(described_class.current.optional_auth?).to be_truthy
        expect(described_class.current.required_auth?).to be_falsy
      end
    end

    it "handle normal authenticated paths" do
      described_class.with_request(request_good.merge(
                                     :original_url => "https://example.com/api/micro-service/v1.0/collection"
                                   )) do
        expect(described_class.current.optional_auth?).to be_falsy
        expect(described_class.current.required_auth?).to be_truthy
      end
    end
  end
end
