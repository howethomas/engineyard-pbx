Adhearsion::Configuration.configure do |config|
  # Whether incoming calls be automatically answered. Defaults to true.
  # config.automatically_answer_incoming_calls = false
  
  # Whether the other end hanging up should end the call immediately. Defaults to true.
  # config.end_call_on_hangup = false
  
  # Whether to end the call immediately if an unrescued exception is caught. Defaults to true.
  # config.end_call_on_error = false
  
  # By default Asterisk is enabled with the default settings
  config.enable_asterisk
  # config.asterisk.enable_ami :host => "127.0.0.1", :username => "admin", :password => "password"
  
  # config.enable_drb 
  
  # config.asterisk.speech_engine = :cepstral
  
  # Configure FreeSwitch
  # config.enable_freeswitch :listening_port => 4572
  
  # Configure a database to use ActiveRecord-backed models.
  config.enable_database :adapter => "sqlite3", :dbfile => "gui/db/development.sqlite3"
end