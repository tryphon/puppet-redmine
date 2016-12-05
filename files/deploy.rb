load 'deploy'

set :application, "redmine"
set :scm, "subversion"

set :repository, "http://svn.redmine.org/redmine/branches/3.3-stable"
set :deploy_to, "/var/www/redmine"
set :deploy_via, :remote_cache

set :keep_releases, 3
after "deploy:update", "deploy:cleanup"
set :use_sudo, false

set :bundle_cmd, "/var/lib/gems/2.2.0/bin/bundle"
set :rake, "#{bundle_cmd} exec /var/lib/gems/2.2.0/bin/rake"

server redmine_server, :app, :web, :db, :primary => true

after "deploy:update_code", "deploy:symlink_shared", "deploy:gems"
after "deploy:migrate", "deploy:plugins"

namespace :deploy do
  # Prevent errors when chmod isn't allowed by server
  task :setup, :except => { :no_release => true } do
    dirs = [deploy_to, releases_path, shared_path]
    dirs += shared_children.map { |d| File.join(shared_path, d) }
    run "mkdir -p #{dirs.join(' ')} && (chmod g+w #{dirs.join(' ')} || true)"
  end

  def gem_file_content
    plugin_gemfile_content = File.read(File.expand_path('../Gemfile.local', __FILE__))
    local_gemfile_content = File.read("files/redmine/Gemfile.local") if File.exists?("files/redmine/Gemfile.local")
    [plugin_gemfile_content, local_gemfile_content].compact.join("\n")
  end

  desc "Install gems"
  task :gems, :roles => :app do
    run "mkdir -p #{shared_path}/bundle"
    put gem_file_content, "#{release_path}/Gemfile.local"
    run "cd #{release_path} && #{bundle_cmd} install --path=#{shared_path}/bundle --gemfile #{release_path}/Gemfile --quiet --without=test development"
  end

  desc "Install plugins"
  task :plugins, :roles => :app do
    run "cd #{release_path} && #{rake} redmine:plugins RAILS_ENV=production"
  end

  desc "Symlinks shared configs and folders on each release"
  task :symlink_shared, :except => { :no_release => true }  do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/"
    run "ln -nfs #{shared_path}/config/production.rb #{release_path}/config/environments/"
    run "ln -nfs #{shared_path}/config/configuration.yml #{release_path}/config/"
    run "ln -nfs #{shared_path}/config/secret_token.rb #{release_path}/config/initializers/"

    run "ln -nfs /usr/local/share/redmine/themes/* #{release_path}/public/themes"
    run "test -f /usr/local/share/redmine/favicon.ico && ln -nfs /usr/local/share/redmine/favicon.ico #{release_path}/public"
    # run "ln -nfs /usr/local/share/redmine/index.html.erb #{release_path}/app/views/welcome"

    run "rm -rf #{release_path}/plugins && ln -nfs /usr/local/share/redmine/plugins #{release_path}/plugins"

    run "mv #{release_path}/tmp #{release_path}/tmp.orig && ln -nfs /var/lib/redmine/tmp #{release_path}/tmp"
    run "mv #{release_path}/public/plugin_assets #{release_path}/public/plugin_assets.orig && ln -nfs /var/lib/redmine/plugin_assets #{release_path}/public/plugin_assets"
  end
end

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end
