load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }
load 'config/deploy'

set :scm, :git
set :repository, File.expand_path('~/ey.git')
set :application, "pbx"
set :user, "jicksta"
set :deploy_to, "~/pbx"

# Adhearsion-related variables
set :ahn_repository, 'http://svn.adhearsion.com/trunk'
set :ahn_deploy_to, '/usr/local/adhearsion'


role :pbx, '10.0.1.195', :primary => true

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

namespace :gui do
  
end

namespace :asterisk do
  task :start do
    
  end
end
