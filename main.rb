require 'time'
require 'net/http'
require 'sinatra'

warn('$BOT_VERIFIER is missing') unless ENV['BOT_VERIFIER']
begin
  text = 'reminder-lingrbot started'
  result = Net::HTTP.get(
    URI("http://lingr.com/api/room/say?room=clojure&text=#{text}&bot=reminder&bot_verifier=#{ENV['BOT_VERIFIER']}"))
  p result
rescue => e
  warn("#{e.backtrace[0]}: #{e.message} (#{e.class})")
end

META_INFO = {
  RUBY_DESCRIPTION: RUBY_DESCRIPTION,
  version: `git rev-parse HEAD`.chomp,
  started_at: Time.now.to_s,
}
MESSAGES_FOR_ROOM = {
  'vim' => 'https://vim-jp.org/docs/chat.html',
  'clojure' => 'Clojure',
  'mcujm' => ENV['MCUJM_MESSAGE'] || 'Moved! lingr mcujm room is obsolete.',
}

LAST_POST_TIMES = {}

get '/' do
  META_INFO.merge(last_post_time: LAST_POST_TIMES).to_json
end

post '/' do
=begin
{"status":"ok",
 "counter":208,
 "events":[
  {"event_id":208,
   "message":
    {"id":82,
     "room":"myroom",
     "public_session_id":"UBDH84",
     "icon_url":"http://example.com/myicon.png",
     "type":"user",
     "speaker_id":"kenn",
     "nickname":"Kenn Ejima",
     "text":"yay!",
     "timestamp":"2011-02-12T08:13:51Z",
     "local_id":"pending-UBDH84-1"}}]}
=end
  data = JSON.parse( request.body.read.to_s )
  room = data.dig('events', 0, 'message', 'room')
  message = data.dig('events', 0, 'message')

  if message && MESSAGES_FOR_ROOM.key?(room)
    LAST_POST_TIMES[room] ||= Time.now - 22*60*60 - 58*60 # assume there was a post 22h58min before restart
    last_post_time = LAST_POST_TIMES[room]
    if Time.parse(message['timestamp']) - last_post_time > 23 * 60 * 60 # every 23 hours
      LAST_POST_TIMES[room] = Time.now
      MESSAGES_FOR_ROOM[room]
    end
  end
end
