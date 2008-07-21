

entry = <<-BEGIN
[xxx]
type=friend			; Friends place calls and receive calls
context=extension		; Context for incoming calls from this user
secret=engineyard
host=dynamic			; This peer register with us
dtmfmode=rfc2833		; Choices are inband, rfc2833, or info
username=xxx			; Username to use in INVITE until peer registers
				; Normally you do NOT need to set this parameter
disallow=all
allow=ulaw                     ; dtmfmode=inband only works with ulaw or alaw!
progressinband=no		; Polycom phones don't work properly with "never"
nat=yes
canreinvite=no
BEGIN

for i in 200..400 do
  puts entry.gsub('xxx', i.to_s)
  puts "\n"
end
