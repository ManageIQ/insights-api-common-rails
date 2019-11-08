describe Insights::API::Common::RBAC::Access do
  include_context "rbac_objects"

  let(:verb) { "read" }
  let(:rbac_access) { described_class.new(resource, verb) }
  let(:api_instance) { double }
  let(:rs_class) { class_double("Insights::API::Common::RBAC::Service").as_stubbed_const(:transfer_nested_constants => true) }
  let(:opts) { { :limit => described_class::DEFAULT_LIMIT } }

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::AccessApi).and_yield(api_instance)
  end

  it "fetches the array of plans" do
    stub_const("ENV", "APP_NAME" => app_name)
    allow(Insights::API::Common::RBAC::Service).to receive(:paginate).with(api_instance, :get_principal_access, opts, app_name).and_return([access1])
    svc_obj = rbac_access.process
    expect(svc_obj.acl.count).to eq(1)
    expect(svc_obj.accessible?).to be_truthy
    expect(svc_obj.id_list).to match_array([resource_id1])
  end

  it "* in id gives access to all instances" do
    stub_const("ENV", "APP_NAME" => app_name)
    allow(Insights::API::Common::RBAC::Service).to receive(:paginate).with(api_instance, :get_principal_access, opts, app_name).and_return([admin_access])
    svc_obj = rbac_access.process
    expect(svc_obj.acl.count).to eq(1)
    expect(svc_obj.accessible?).to be_truthy
    expect(svc_obj.id_list).to match_array([])
  end

  it "rbac is enabled by default" do
    expect(described_class.enabled?).to be_truthy
  end

  it "rbac is enabled by default" do
    stub_const("ENV", "BYPASS_RBAC" => "1")
    expect(described_class.enabled?).to be_falsey
  end
end
