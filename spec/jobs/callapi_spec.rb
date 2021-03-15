require 'rspec'
require 'yaml'
require 'json'
require 'bosh/template/test'

describe 'callapi job' do
  let(:release) { Bosh::Template::Test::ReleaseDir.new(File.join(File.dirname(__FILE__), '../..')) }
  let(:job) { release.job('callapi') }

  describe 'run.sh.erb' do
    let(:template) { job.template('bin/run') }
    let(:links) { [
        Bosh::Template::Test::Link.new(
          name: 'elasticsearch',
          instances: [Bosh::Template::Test::LinkInstance.new(address: '10.0.8.2')],
          properties: {
            'elasticsearch'=> {
              'cluster_name' => 'test',
              'client' => {
                'port' => '9200'
              }
            },
          }
        )
      ] }

    describe 'providing a call' do
      let(:valid_call) {
        YAML.load(%q(
        - endpoint: /_ilm/policy/datastream_policy
          action: PUT
          headers:
            - Content-Type: application/json
          payload: |
            {
              "policy": {
                "phases": {
                  "hot": {
                    "min_age": "0ms",
                    "actions": {
                      "rollover": {
                        "max_age": "1d"
                      }
                    }
                  },
                  "delete": {
                    "min_age": "7d",
                    "actions": {
                      "delete": {}
                    }
                  }
                }
              }
            }
        ))
      }

      let(:valid_rendered_request) {
        "curl -s -k -X  PUT -H 'Content-Type: application/json'  http://10.0.8.2:9200/_ilm/policy/datastream_policy"
      }

      it 'renders properly' do
        expect { template.render({"calls" => valid_call}, consumes: links) }.not_to raise_error
        rendered_template = template.render({"calls" => valid_call}, consumes: links)
        
        expect(rendered_template).to include(valid_rendered_request)
        puts rendered_template
      end
    end
  end
end