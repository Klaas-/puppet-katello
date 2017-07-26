# Katello configuration for pulp
class katello::candlepin {
  include ::certs::qpid
  include ::certs::candlepin

  class { '::candlepin':
    user_groups                  => $::katello::user_groups,
    oauth_key                    => $::katello::oauth_key,
    oauth_secret                 => $::katello::oauth_secret,
    deployment_url               => $::katello::deployment_url,
    ca_key                       => $::certs::ca_key,
    ca_cert                      => $::certs::ca_cert_stripped,
    keystore_password            => $::certs::candlepin::keystore_password,
    truststore_password          => $::certs::candlepin::keystore_password,
    enable_basic_auth            => false,
    consumer_system_name_pattern => '.+',
    adapter_module               => 'org.candlepin.katello.KatelloModule',
    amq_enable                   => true,
    amqp_keystore_password       => $::certs::candlepin::keystore_password,
    amqp_truststore_password     => $::certs::candlepin::keystore_password,
    amqp_keystore                => $::certs::candlepin::amqp_keystore,
    amqp_truststore              => $::certs::candlepin::amqp_truststore,
    qpid_ssl_cert                => $::certs::qpid::client_cert,
    qpid_ssl_key                 => $::certs::qpid::client_key,
    subscribe                    => Class['certs::qpid', 'certs::candlepin'],
  }

  # TODO: Is this still needed with proper containment?
  Class['certs::candlepin'] ~> Service['tomcat']
}
