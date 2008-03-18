load 'deploy' if respond_to?(:namespace) # cap2 differentiator

PRODUCTION_SERVERS = %w[65.74.174.200 65.74.174.199]
VM_AHN_SERVERS = '192.168.2.223'

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
depend :remote, :command, "asterisk"
depend :remote, :directory, project_deploy_to_root
depend :remote, :gem, "rails", ">= 2.0.2"
depend :remote, :gem, "activerecord", ">= 2.0.2"
depend :remote, :gem, "activesupport", ">= 2.0.2"
depend :remote, :gem, "hoe", ">= 1.5.0"
depend :remote, :gem, "rubigen", ">= 1.1.1"
depend :remote, :gem, "log4r", ">= 1.0.5"

after 'deploy', :update_path_to_rails

task :vm do
  role :app, *VM_AHN_SERVERS
end

task :production do
  set :user, "root"
  set :use_sudo, "false"
  role :app, *PRODUCTION_SERVERS
end

task :update_path_to_rails do
  run "echo #{rails_deploy_to}/current > #{ahn_deploy_to}/current/.path_to_gui"
end

namespace :deploy do
  task :start do
    run "/etc/init.d/adhearsion start"
  end
  
  task :stop do
    run "/etc/init.d/adhearsion stop"
  end
  
  task :restart do
    stop
    start
  end
end

namespace :ahn do
  
  task :init do
    run "svn co #{ahn_repository} #{ahn_install_dir}"
  end
  
  task :update do
    run "svn update #{ahn_install_dir}"
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
  task :status do
    run "/etc/init.d/asterisk status"
  end
end

namespace :debian do
  
  task :update_packages do
    run "apt-get update"
  end
  
  namespace :monit do
    task :install do
      update_packages
      run "apt-get install -y monit"
    end
  end
  
  namespace :mysql do
    
    task :install do
      update_packages
      run "apt-get install -y mysql-server-5.0"
      run "apt-get install -y mysql-client-5.0"
    end
    
    task :status do
      run "/etc/init.d/mysql status"
    end
    
  end
end