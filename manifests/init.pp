class redmine($database_password) {
  include ruby::onrails
  rails::application { 'redmine':
    rails_version => false
  }

  include subversion

  include ruby::dev::22
  include ruby::bundler::22

  include ruby::gem::rmagick::dependencies
  include ruby::gem::postgresql::dependencies

  include postgres

  postgres::user { 'redmine':
    ensure => present,
    password => $database_password
  }
  postgres::database { 'redmine':
    ensure => present,
    owner => 'redmine',
    require => Postgres::User['redmine']
  }

  file { '/etc/redmine/configuration.yml':
    source => 'puppet:///files/redmine/configuration.yml'
  }
  file { '/etc/redmine/secret_token.rb':
    source => 'puppet:///files/redmine/secret_token.rb'
  }

  file { '/var/lib/redmine':
    ensure => directory
  }

  file { ['/var/lib/redmine/files', '/var/lib/redmine/tmp', '/var/lib/redmine/plugin_assets']:
    owner => www-data,
    ensure => directory
  }

  file { '/var/lib/redmine/tmp/restart.txt':
    ensure => present,
    group => src,
    mode => 664
  }

  # Provides several customized files installed by deploy
  file { '/usr/local/share/redmine':
    ensure => directory,
    recurse => true,
    source => 'puppet:///files/redmine/local'
  }

  file { '/usr/local/share/redmine/plugins':
    ensure => directory
  }

  backup::model { redmine: }

  apache2::site { 'redmine':
    source => 'puppet:///files/redmine/apache.conf',
    require => [Package['libapache2-mod-passenger'], File['/etc/apache2/sites-available/redmine-definition']]
  }

  file { '/etc/apache2/sites-available/redmine-definition':
    source => 'puppet:///redmine/redmine-definition.conf'
  }
}
