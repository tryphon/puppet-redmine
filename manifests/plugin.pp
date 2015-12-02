define redmine::plugin() {
  include unzip
  file { "/usr/local/share/redmine/plugins/${name}.zip":
    source => ["puppet:///files/redmine/plugins/${name}.zip", "puppet:///redmine/plugins/${name}.zip"],
  }
  exec { "install-redmine-plugin-$name":
    cwd => '/usr/local/share/redmine/plugins/',
    command => "rm -rf $name && unzip ${name}.zip",
    refreshonly => true,
    subscribe => File["/usr/local/share/redmine/plugins/${name}.zip"]
  }
}
