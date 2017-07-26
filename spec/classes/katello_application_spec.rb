require 'spec_helper'

describe 'katello::application' do
  on_os_under_test.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      context 'with enable_ostree => false' do
        let(:pre_condition) do
          <<-EOS
          class { 'katello':
            enable_ostree => false,
          }
          EOS
        end

        it { is_expected.not_to contain_package('tfm-rubygem-katello_ostree')}
      end

      context 'with enable_ostree => true' do
        let(:pre_condition) do
          <<-EOS
          class { 'katello':
            enable_ostree => true,
          }
          EOS
        end

        it do
          is_expected.to contain_package('tfm-rubygem-katello_ostree')
            .with_ensure('installed')
            .with_notify('Class[Foreman::Plugin::Tasks]')
        end
      end

      context 'default config settings' do
        let(:pre_condition) do
          <<-EOS
          class { 'katello':
            post_sync_token => test_token,
            oauth_secret    => secret,
          }
          EOS
        end

        it 'should generate correct katello.yaml' do
          verify_exact_contents(catalogue, '/etc/foreman/plugins/katello.yaml', [
            ':katello:',
            '  :rest_client_timeout: 3600',
            '  :post_sync_url: https://foo.example.com/katello/api/v2/repositories/sync_complete?token=test_token',
            '  :candlepin:',
            '    :url: https://foo.example.com:8443/candlepin',
            '    :oauth_key: katello',
            '    :oauth_secret: secret',
            '    :ca_cert_file: /etc/pki/katello/certs/katello-default-ca.crt',
            '  :pulp:',
            '    :url: https://foo.example.com/pulp/api/v2/',
            '    :oauth_key: katello',
            '    :oauth_secret: secret',
            '    :ca_cert_file: /etc/pki/katello/certs/katello-server-ca.crt',
            '  :qpid:',
            '    :url: amqp:ssl:localhost:5671',
            '    :subscriptions_queue_address: katello_event_queue'
          ])
        end
      end

      context 'when http proxy parameters are specified' do
        let(:pre_condition) do
          <<-EOS
          class {'katello':
            post_sync_token => 'test_token',
            oauth_secret    => 'secret',
            proxy_url       => 'http://myproxy.org',
            proxy_port      => 8888,
            proxy_username  => 'admin',
            proxy_password  => 'secret_password',
          }
          EOS
        end

        it 'should generate correct katello.yaml' do
          verify_exact_contents(catalogue, '/etc/foreman/plugins/katello.yaml', [
            ':katello:',
            '  :rest_client_timeout: 3600',
            '  :post_sync_url: https://foo.example.com/katello/api/v2/repositories/sync_complete?token=test_token',
            '  :candlepin:',
            '    :url: https://foo.example.com:8443/candlepin',
            '    :oauth_key: katello',
            '    :oauth_secret: secret',
            '    :ca_cert_file: /etc/pki/katello/certs/katello-default-ca.crt',
            '  :pulp:',
            '    :url: https://foo.example.com/pulp/api/v2/',
            '    :oauth_key: katello',
            '    :oauth_secret: secret',
            '    :ca_cert_file: /etc/pki/katello/certs/katello-server-ca.crt',
            '  :qpid:',
            '    :url: amqp:ssl:localhost:5671',
            '    :subscriptions_queue_address: katello_event_queue',
            '  :cdn_proxy:',
            '    :host: http://myproxy.org',
            '    :port: 8888',
            '    :user: admin',
            '    :password: secret_password'
          ])
        end
      end
    end
  end
end
