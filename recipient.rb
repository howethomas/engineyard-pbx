require 'rubygems'
require 'xmpp4r'
include Jabber

adhearsion_jid = JID.new "adhearsion@jay-phillipss-mac-pro.local/Testing"

iq_handler = Client.new adhearsion_jid, true
iq_handler.connect
iq_handler.auth "foobar"

iq_handler.add_iq_callback do |iq_event|
  print iq_event.inspect
end

updater_jid = JID.new("agent-updater@jay-phillipss-mac-pro.local/DoesNotMatter")

iq_sending_client = Client.new(updater_jid, true)
iq_sending_client.connect
iq_sending_client.auth "foobar"

sent_iq_packet = Iq.new(:get, JID.new("adhearsion@jay-phillipss-mac-pro.local/Testing"))
iq_sending_client.send sent_iq_packet