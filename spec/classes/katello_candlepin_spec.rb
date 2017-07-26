require 'spec_helper'

describe 'katello::candlepin' do
  on_os_under_test.each do |os, facts|
    context "on #{os}" do
      let (:facts) { facts }

      let :pre_condition do
        'include ::katello'
      end

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('certs::candlepin').that_notifies('Service[tomcat]') }
    end
  end
end
