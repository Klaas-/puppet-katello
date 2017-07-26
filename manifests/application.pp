# Install and configure the katello application itself
class katello::application {
  include ::certs::pulp_client

  foreman_config_entry { 'pulp_client_cert':
    value          => $::certs::pulp_client::client_cert,
    ignore_missing => false,
    require        => [Class['::certs::pulp_client'], Exec['foreman-rake-db:seed']],
  }

  foreman_config_entry { 'pulp_client_key':
    value          => $::certs::pulp_client::client_key,
    ignore_missing => false,
    require        => [Class['::certs::pulp_client'], Exec['foreman-rake-db:seed']],
  }

  # We used to override permissions here so this matches it back to the packaging
  file { '/usr/share/foreman/bundler.d/katello.rb':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  include ::foreman
  include ::foreman::plugin::tasks

  # TODO: Test if it still correctly migrates and seeds
  foreman::plugin { 'katello':
    package     => $::katello::package_names,
    config_file => "${::foreman::plugin_config_dir}/katello.yaml",
    config      => template('katello/katello.yaml.erb'),
    notify      => Class['foreman::plugin::tasks'],
  }

  if $::katello::enable_ostree {
    package { $::katello::rubygem_katello_ostree:
      ensure => installed,
      notify => Class['foreman::plugin::tasks'],
    }
  }

  foreman::config::passenger::fragment{ 'katello':
    ssl_content => file('katello/katello-apache-ssl.conf'),
  }
}
