# == Class: dlrn
#
# Configures a DLRN instance
#
# === Parameters:
#
# [*sshd_port*]
#   (optional) Additional port where sshd should listen
#   Defaults to 3300
#
# [*server_type*]
#   (optional) server_type can be set to primary or passive. Primary server
#   check periodically for changes in repos and synchronize every build to a
#   passive server if rsync is enabled. Passive server receives builds from
#   primary and redirects current-passed-ci and current-tripleo to buildlogs.
#   Defaults to "Primary"
#
# [*enable_https*]
#   (optional) Enable ssl in apache configuration. Certificates are managed
#   using letsencrypt service. 
#   Defaults to false
#
# === Examples
#
#  class { 'dlrn': }
#
# === Authors
#
# Javier Peña <jpena@redhat.com>


class dlrn (
  $sshd_port    = 3300,
  $server_type  = 'primary',
  $enable_https = false
) {

  class { '::dlrn::common':
    sshd_port    => $sshd_port,
    enable_https => $enable_https
  }

  class { '::dlrn::rdoinfo': }
  class { '::dlrn::promoter': }
  if (versioncmp($::operatingsystemmajrelease, '7') > 0) {
    # RHEL 8 or later
    # FIXME(jpena): fail2ban is not available yet for RHEL 8
    class { '::dlrn::fail2ban':
      sshd_port => $sshd_port,
    }
  }
  class { '::dlrn::web':
    enable_https => $enable_https
  }

  $workers = hiera_hash('dlrn::workers')
  create_resources(dlrn::worker,$workers)

  Class['::dlrn::common'] -> Dlrn::Worker <||>
  Class['::dlrn::common'] -> Class['::dlrn::rdoinfo']
  Class['::dlrn::common'] -> Class['::dlrn::promoter']
}
