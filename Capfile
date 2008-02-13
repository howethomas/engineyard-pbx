load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }
load 'config/deploy'

AHN_SERVERS = '10.0.1.195'

# Git/Github setup
set :scm, :git
set :repository, "git@github.com:jicksta/engineyard-pbx.git"

# Project-related variables
set :project_deploy_to_root, "/usr/local/engineyard"

# Rails-related variables
set :rails_deploy_to, project_deploy_to_root + "/pbx-gui"

# Adhearsion-related variables
set :ahn_repository, 'http://svn.adhearsion.com/trunk'
set :ahn_deploy_to, project_deploy_to_root + "/pbx"

# Capistrano setup
set :application, "pbx" # Why is this needed?
set :user, "jicksta"    # SHOULD BE 'deploy'!
set :deploy_to, ahn_deploy_to

depend :remote, :command, "git"
depend :remote, :directory, project_deploy_to_root
depend :remote, :gem, "activerecord", ">= 2.0.2"
depend :remote, :gem, "activesupport", ">= 2.0.2"
depend :remote, :gem, "hoe", ">= 1.5.0"
depend :remote, :gem, "rubigen", ">= 1.1.1"

role :app, AHN_SERVERS

after 'deploy', :update_path_to_rails

task :update_path_to_rails do
  run "echo #{rails_deploy_to} > #{ahn_deploy_to}/.path_to_gui"
end

namespace :deploy do
  task :restart do
    # ahn.restart
  end
end

namespace :ahn do
  
  task :init do
    sudo "svn co #{ahn_repository} #{ahn_deploy_to}"
  end
  
  task :update do
    sudo "svn update #{ahn_deploy_to}"
  end
end

namespace :pbx do
  
  task :deploy, :roles => :pbx do
    
  end
  
  task :start do
    asterisk.start
    start_ahn_app
  end
  
  task :stop do
    stop_ahn_app
  end
  
  task :restart do
    stop
    start
  end
  
end

namespace :asterisk do
  task :start do
    
  end
end
