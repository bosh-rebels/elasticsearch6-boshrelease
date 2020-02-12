require 'rspec'
require 'yaml'
require 'bosh/template/test'

describe "pre-upgrade job" do
  let(:release) { Bosh::Template::Test::ReleaseDir.new(File.join(File.dirname(__FILE__), '../..')) }
  let(:job) { release.job('pre-upgrade') }

  describe "bin/run template" do
    let(:template) { job.template('bin/run') }
    let(:default_properties) { {} }
    let(:properties_with_credentials) {
      {
        'elasticsearch'=> {
            'client' => {
              'username' => 'test',
              'password' => 'testpassword'
            }
        },
      }
    }
    let(:properties_with_port) {
      {
        'elasticsearch'=> {
            'client' => {
              'port' => '8888'
            }
        },
      }
    }
    let(:properties_with_protocol) {
      {
        'elasticsearch'=> {
            'client' => {
              'protocol' => 'https'
            }
        },
      }
    }
    def build_links(properties)
      [
        Bosh::Template::Test::Link.new(
        name: 'elasticsearch-master',
        instances: [Bosh::Template::Test::LinkInstance.new(address: '10.0.8.2')],
        properties: properties) 
      ]     
    end

    it "renders with defaults" do
      expect { template.render({}, consumes: build_links(default_properties)) }.not_to raise_error
      expect(template.render({}, consumes: build_links(default_properties))).to include("local url=http://10.0.8.2")
    end

    it "renders correctly when passing credentials" do
      expect( template.render({}, consumes: build_links(properties_with_credentials))).to include("local url=http://test:testpassword@10.0.8.2")
    end

    it "renders correctly when passing port" do
      expect( template.render({}, consumes: build_links(properties_with_port))).to include("local url=http://10.0.8.2:8888")
    end

    it "renders correctly when passing protocol" do
      expect( template.render({}, consumes: build_links(properties_with_protocol))).to include("local url=https://10.0.8.2")
    end
  end
end