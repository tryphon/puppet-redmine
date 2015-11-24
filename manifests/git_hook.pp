define redmine::git_hook($hostname, $api_key) {
  file { "/srv/git/$name/hooks/post-receive.d/redmine":
    content => "#!/bin/sh\nwget --quiet -O /dev/null 'http://${hostname}/sys/fetch_changesets?key=${api}'\n",
    mode => 755,
    require => Git::Repository[$name]
  }
}
