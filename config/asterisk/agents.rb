Employee.find(:all) do |employee|
  agent employee.id :name => employee.name
end

persistent_agents true
max_login_tries 5
log_off_after_duration 15
require_hash_to_acknowledge false
allow_star_to_hangup true
time_between_calls 5
hold_music_class :default
play_on_agent_goodbye "goodbye_file"
change_cdr_source false
groups 1,2
record_agent_calls true
recording_format :gsm
recording_prefix "http://localhost/calls/"
save_recordings_in "/var/calls"
play_for_waiting_keep_alive "beep"