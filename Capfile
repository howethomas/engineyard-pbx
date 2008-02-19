load 'deploy' if respond_to?(:namespace) # cap2 differentiator

AHN_SERVERS = '192.168.2.3'

# Git/Github setup
set :scm, :git
set :repository, "git@github.com:jicksta/engineyard-pbx.git"

# Project-related variables
set :project_deploy_to_root, "/usr/local/engineyard"

# Rails-related variables
set :rails_deploy_to, project_deploy_to_root + "/pbx-gui"

# Adhearsion-related variables
set :ahn_repository, 'http://svn.adhearsion.com/trunk'
set :ahn_install_dir, "/usr/local/adhearsion"

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
  run "echo #{rails_deploy_to}/current > #{ahn_deploy_to}/current/.path_to_gui"
end

namespace :deploy do
  task :restart do
    # ahn.restart
  end
end

namespace :ahn do
  
  task :init do
    sudo "svn co #{ahn_repository} #{ahn_install_dir}"
  end
  
  task :update do
    sudo "svn update #{ahn_install_dir}"
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
