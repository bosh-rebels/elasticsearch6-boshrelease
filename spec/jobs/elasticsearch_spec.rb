require 'rspec'
require 'yaml'
require 'bosh/template/test'

describe 'elasticsearch job' do
  let(:release) { Bosh::Template::Test::ReleaseDir.new(File.join(File.dirname(__FILE__), '../..')) }
  let(:job) { release.job('elasticsearch') }

  describe 'elasticsearch.yml' do
    let(:template) { job.template('config/elasticsearch.yml') }
    let(:links) { [
        Bosh::Template::Test::Link.new(
          name: 'elasticsearch',
          instances: [Bosh::Template::Test::LinkInstance.new(address: '10.0.8.2')],
          properties: {
            'elasticsearch'=> {
              'cluster_name' => 'test'
            },
          }
        )
      ] }

    it 'configures defaults successfully' do
      config = YAML.safe_load(template.render({}, consumes: links))
      expect(config['node.name']).to eq('me/0')
      expect(config['node.master']).to eq(true)
      expect(config['node.data']).to eq(true)
      expect(config['node.ingest']).to eq(false)
      expect(config['node.attr.zone']).to eq('az1')
      expect(config['discovery.zen.ping.unicast.hosts']).to eq('10.0.8.2')
      expect(config['xpack.security.enabled']).to eq(false)
    end

    it 'disables xpack.security when some of elasticsearch.ssl properties are set' do
      config = YAML.safe_load(template.render({'elasticsearch' => {'ssl'=> {'ca' => 'certificate'}}}, consumes: links))
      expect(config['xpack.security.enabled']).to eq(false)
    end

    it 'makes elasticsearch.node.allow_data false' do
      config = YAML.safe_load(template.render({'elasticsearch' => {
        'node' => {
          'allow_data' => false
        }
      }}, consumes: links))
      expect(config['node.data']).to eq(false)
    end

    it 'configures elasticsearch.config_options' do
      config = YAML.safe_load(template.render({'elasticsearch' => {
        'config_options' => {
            'xpack' => {
              'monitoring' => {
                'enabled' => true
              },
              'security' => {
                'enabled' => true
              },
              'watcher' => {
                'enabled' => true
              }
          }
        }
      }}, consumes: links))
      expect(config['xpack']['monitoring']['enabled']).to eq(true)
      expect(config['xpack']['security']['enabled']).to eq(true)
      expect(config['xpack']['watcher']['enabled']).to eq(true)
    end

    it 'configures multi-clusters successfully' do
      config = YAML.safe_load(template.render({}, consumes: [
        Bosh::Template::Test::Link.new(
          name: 'elasticsearch',
          instances: [Bosh::Template::Test::LinkInstance.new(address: '10.0.8.2'),
            Bosh::Template::Test::LinkInstance.new(address: '10.0.8.3'),
            Bosh::Template::Test::LinkInstance.new(address: '10.0.8.4')],
          properties: {}
        ),
      ]))
      expect(config['node.name']).to eq('me/0')
      expect(config['node.master']).to eq(true)
      expect(config['node.data']).to eq(true)
      expect(config['node.ingest']).to eq(false)
      expect(config['node.attr.zone']).to eq('az1')
      expect(config['discovery.zen.ping.unicast.hosts']).to eq('10.0.8.2,10.0.8.3,10.0.8.4')
    end

    it 'configures multi-clusters on non-master successfully' do
      config = YAML.safe_load(template.render({'elasticsearch'=> {
              'node' => {
                'allow_master' => false
              }
            }}, consumes: [
        Bosh::Template::Test::Link.new(
          name: 'elasticsearch',
          instances: [Bosh::Template::Test::LinkInstance.new(address: '10.0.8.2'),
            Bosh::Template::Test::LinkInstance.new(address: '10.0.8.3'),
            Bosh::Template::Test::LinkInstance.new(address: '10.0.8.4')],
          properties: {}
        ),
      ]))
      expect(config['node.name']).to eq('me/0')
      expect(config['node.master']).to eq(false)
      expect(config['node.data']).to eq(true)
      expect(config['node.ingest']).to eq(false)
      expect(config['node.attr.zone']).to eq('az1')
      expect(config['discovery.zen.ping.unicast.hosts']).to eq('10.0.8.2,10.0.8.3,10.0.8.4')
    end

    it 'configures multi-clusters secondary master successfully' do
      config = YAML.safe_load(template.render({},
        spec: Bosh::Template::Test::LinkInstance.new(az: 'az1', address: '10.0.8.2', index: 1),
        consumes: [
        Bosh::Template::Test::Link.new(
          name: 'elasticsearch',
          instances: [Bosh::Template::Test::LinkInstance.new(address: '10.0.8.2'),
            Bosh::Template::Test::LinkInstance.new(address: '10.0.8.3'),
            Bosh::Template::Test::LinkInstance.new(address: '10.0.8.4')],
          properties: {}
        ),
      ]))
      expect(config['node.master']).to eq(true)
      expect(config['node.data']).to eq(true)
      expect(config['node.ingest']).to eq(false)
      expect(config['node.attr.zone']).to eq('az1')
      expect(config['discovery.zen.ping.unicast.hosts']).to eq('10.0.8.2,10.0.8.3,10.0.8.4')
    end

    it 'configures multi-clusters for migrate from 6 to 7 successfully' do
      config = YAML.safe_load(template.render({'elasticsearch'=> {
              'migrate_6_to_7' => true
            }}, consumes: [
        Bosh::Template::Test::Link.new(
          name: 'elasticsearch',
          instances: [Bosh::Template::Test::LinkInstance.new(address: '10.0.8.2'),
            Bosh::Template::Test::LinkInstance.new(address: '10.0.8.3'),
            Bosh::Template::Test::LinkInstance.new(address: '10.0.8.4')],
          properties: {}
        ),
      ]))
      expect(config['node.name']).to eq('me/0')
      expect(config['node.master']).to eq(true)
      expect(config['node.data']).to eq(true)
      expect(config['node.ingest']).to eq(false)
      expect(config['node.attr.zone']).to eq('az1')
      expect(config['discovery.zen.ping.unicast.hosts']).to eq('10.0.8.2,10.0.8.3,10.0.8.4')
    end

    it 'disables SMTP by default' do
      rendered_template = YAML.safe_load(template.render({}, consumes: links))

      expect(rendered_template).to_not include('xpack.notification.email')
    end

    it 'configures smtp accounts successfully' do
      rendered_template = YAML.safe_load(template.render({
        'elasticsearch' => {
          'smtp' => {
            'enabled' => true,
            'default_account'=> 'default',
            'accounts'=> [
              'name' => 'default',
              'profile' => 'standard',
              'auth' => false,
              'starttls.enable' => false,
              'host' => 'smtp.corp',
              'port' => 25,
              'user' =>  'some@example.corp'
            ]
          }
        }
      }, consumes: links))

      email_config = rendered_template.fetch('xpack.notification.email')

      expect(email_config.fetch('default_account')).to eq('default')
      expect(email_config.fetch('account')).to include('default')

      default_account = email_config.fetch('account').fetch('default')

      expect(default_account.fetch('profile')).to eq('standard')
      expect(default_account.fetch('email_defaults')).to eq({
        'from' => 'some@example.corp'
      })
      expect(default_account.fetch('smtp')).to eq({
        'auth' => false,
        'starttls.enable' => false,
        'host' => 'smtp.corp',
        'port' => 25,
        'user' => 'some@example.corp'
      })
    end


  end

  describe 'keystore-add.sh' do
    let(:template) { job.template('bin/keystore-add.sh') }
    let(:links) { [
        Bosh::Template::Test::Link.new(
          name: 'elasticsearch',
          instances: [Bosh::Template::Test::LinkInstance.new(address: '10.0.8.2')],
          properties: {
            'elasticsearch'=> {
              'cluster_name' => 'test'
            },
          }
        )
      ] }

    it 'default works' do
      keystore_add = template.render({}, consumes: links).strip
      expect(keystore_add).to starting_with('#!/bin/bash')
      expect(keystore_add).to ending_with('rm -f /var/vcap/packages/elasticsearch/config/elasticsearch.keystore')
    end

    it 'secure_settings works' do
      keystore_add = template.render({'elasticsearch' => {
        'secure_settings' => [
          {'command' => 'add', 'name' => 's3.client.default.access_key', 'value' => 'aaa'},
          {'command' => 'remove', 'name' => 's3.client.default.secret_key', 'value' => 'bbb'},
          {'command' => 'add-file', 'name' => 'gcs.client.default.credentials_file', 'value' => '/tmp/credentials'}
        ]
      }}, consumes: links).strip
      expect(keystore_add).to starting_with('#!/bin/bash')
      expect(keystore_add).to include('echo "aaa" | elasticsearch-keystore add -xf  s3.client.default.access_key')
      expect(keystore_add).to include('elasticsearch-keystore remove s3.client.default.secret_key || true')
      expect(keystore_add).to include('elasticsearch-keystore add-file -f gcs.client.default.credentials_file /tmp/credentials')
      expect(keystore_add).to ending_with('elasticsearch-keystore list || true')
    end
  end

  describe 'pre-start.sh' do
    let(:template) { job.template('bin/pre-start') }
    let(:links) { [
        Bosh::Template::Test::Link.new(
          name: 'elasticsearch',
          instances: [Bosh::Template::Test::LinkInstance.new(address: '10.0.8.2')],
          properties: {
            'elasticsearch'=> {
              'cluster_name' => 'test'
            },
          }
        )
      ] }

    it 'sets plugins properties' do
      prestart = template.render({'elasticsearch' => {
        'plugins' => [ { 'repository-gcs': 'repository-gcs' } ],
        'plugin_install_opts' => ['--batch']
      }}, consumes: links).strip
      expect(prestart).to include('elasticsearch-plugin install --batch "repository-gcs"')
    end
  end

  describe 'elasticsearch ssl ca' do
    let(:template) { job.template('config/certs/http/ca.pem') }

    it 'sets ca' do
      cert_file = template.render({
        'elasticsearch' => {
          'security' => {
            'ssl'=> {
              'http' => {
                'ca' => 'certificate'
              }
            }
          }
        }
      }).strip
      expect(cert_file).to include('certificate')
    end
  end

  describe 'elasticsearch ssl cert' do
    let(:template) { job.template('config/certs/http/cert.pem') }
    it 'sets cert' do
      cert_file = template.render({
        'elasticsearch' => {
          'security' => {
            'ssl'=> {
              'http' => {
                'certificate' => 'certificate'
              }
            }
          }
        }
      }).strip
      expect(cert_file).to include('certificate')
    end
  end

  describe 'elasticsearch ssl key' do
    let(:template) { job.template('config/certs/http/key.pem') }

    it 'sets key' do
      key_file = template.render({
        'elasticsearch' => {
          'security' => {
            'ssl'=> {
              'http' => {
                'private_key' => 'key'
              }
            }
          }
        }
      }).strip
      expect(key_file).to include('key')
    end
  end
end