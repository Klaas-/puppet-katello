# == Class: katello
#
# Install and configure katello
#
# === Parameters:
#
# $enable_ostree::      Enable ostree plugin, this requires an ostree install
#
# $proxy_url::          URL of the proxy server
#
# $proxy_port::         Port the proxy is running on
#
# $proxy_username::     Proxy username for authentication
#
# $proxy_password::     Proxy password for authentication
#
# $pulp_max_speed::     The maximum download speed per second for a Pulp task, such as a sync. (e.g. "4 Kb" (Uses SI KB), 4MB, or 1GB" )
#
# $repo_export_dir::    Directory to create for repository exports
#
# === Advanced parameters:
#
# $user::               The Katello system user name
#
# $group::              The Katello system user group
#
# $user_groups::        Extra user groups the Katello user is a part of
#
# $oauth_key::          The OAuth key for talking to the candlepin API
#
# $oauth_secret::       The OAuth secret for talking to the candlepin API
#
# $post_sync_token::    The shared secret for pulp notifying katello about
#                       completed syncs
#
# $log_dir::            Location for Katello log files to be placed
#
# $config_dir::         Location for Katello config files
#
# $cdn_ssl_version::    SSL version used to communicate with the CDN
#
# $num_pulp_workers::   Number of pulp workers to use
#
# $max_tasks_per_pulp_worker:: Number of tasks after which the worker gets restarted
#
# $package_names::      Packages that this module ensures are present instead of the default
#
# $manage_repo::        Whether to manage the yum repository
#
# $repo_version::       Which yum repository to install. For example
#                       latest or 3.3.
#
# $repo_gpgcheck::      Whether to check the GPG signatures
#
# $repo_gpgkey::        The GPG key to use
#
# $enable_candlepin::   Whether to enable candlepin
#
# $enable_qpid::        Whether to enable qpid
#
# $enable_qpid_client:: Whether to enable qpid client
#
# $enable_pulp::        Whether to enable pulp
#
# $enable_application:: Whether to enable application (katello web ui)
#
class katello (
  String $user = $::katello::params::user,
  String $group = $::katello::params::group,
  Variant[Array[String], String] $user_groups = $::katello::params::user_groups,

  String $oauth_key = $::katello::params::oauth_key,
  String $oauth_secret = $::katello::params::oauth_secret,

  String $post_sync_token = $::katello::params::post_sync_token,
  Integer[1] $num_pulp_workers = $::katello::params::num_pulp_workers,
  Optional[Integer] $max_tasks_per_pulp_worker = $::katello::params::max_tasks_per_pulp_worker,
  Stdlib::Absolutepath $log_dir = $::katello::params::log_dir,
  Stdlib::Absolutepath $config_dir = $::katello::params::config_dir,
  Optional[Stdlib::HTTPUrl] $proxy_url = $::katello::params::proxy_url,
  Optional[Integer[0, 65535]] $proxy_port = $::katello::params::proxy_port,
  Optional[String] $proxy_username = $::katello::params::proxy_username,
  Optional[String] $proxy_password = $::katello::params::proxy_password,
  Optional[String] $pulp_max_speed = $::katello::params::pulp_max_speed,
  Optional[Enum['SSLv23', 'TLSv1']] $cdn_ssl_version = $::katello::params::cdn_ssl_version,

  Array[String] $package_names = $::katello::params::package_names,
  Boolean $enable_ostree = $::katello::params::enable_ostree,

  Stdlib::Absolutepath $repo_export_dir = $::katello::params::repo_export_dir,

  Boolean $manage_repo = $::katello::params::manage_repo,
  String $repo_version = $::katello::params::repo_version,
  Boolean $repo_gpgcheck = $::katello::params::repo_gpgcheck,
  Optional[String] $repo_gpgkey = $::katello::params::repo_gpgkey,
  Boolean $enable_candlepin = $::katello::params::enable_candlepin,
  Boolean $enable_qpid = $::katello::params::enable_qpid,
  Boolean $enable_qpid_client = $::katello::params::enable_qpid_client,
  Boolean $enable_pulp = $::katello::params::enable_pulp,
  Boolean $enable_application = $::katello::params::enable_application,
) inherits katello::params {
  include ::certs
  $candlepin_ca_cert = $::certs::ca_cert
  $pulp_ca_cert = $::certs::katello_server_ca_cert

  class { '::katello::repo': }

  if $enable_candlepin {
    Class['certs'] ~>
    class { '::katello::candlepin': }
  }

  if $enable_qpid {
    Class['certs'] ~>
    class { '::katello::qpid': }
  }


  if $enable_qpid_client {
    Class['certs'] ~>
    class { '::katello::qpid_client': }
  }

  if $enable_pulp {
    Class['certs'] ~>
    class { '::katello::pulp': }
    if defined(Class['::katello::candlepin']) {
      Class['::katello::candlepin'] ~> Class['::katello::pulp']
    }
  }

  if $enable_application {
    Class['certs'] ~>
    class { '::certs::apache': } ~>
    class { '::katello::application': }
    class { '::certs::foreman': }

    # TODO: Is this still needed with proper containment?
    if defined(Exec['cpinit']) {
      Exec['cpinit'] -> Exec['foreman-rake-db:seed']
    }
    Class['certs::ca'] ~> Service['httpd']
  }

  User<|title == apache|>{groups +> $user_groups}
}
