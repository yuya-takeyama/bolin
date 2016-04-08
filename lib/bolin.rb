require 'json'
require 'net/http'
require 'bolin/version'

module Bolin
  class Bot
    attr_reader :channel_id, :channel_secret, :channel_mid, :callback

    def initialize(channel_id, channel_secret, channel_mid)
      @channel_id     = channel_id
      @channel_secret = channel_secret
      @channel_mid    = channel_mid
      @callback       = Callback.new(self)
      @text_handlers  = []
    end

    def send_message(message)
      Net::HTTP.start('trialbot-api.line.me', 443, use_ssl: true) do |http|
        req = Net::HTTP::Post.new('/v1/events')
        req.add_field 'Content-Type', 'application/json; charser=UTF-8'
        req.add_field 'X-Line-ChannelID', @channel_id
        req.add_field 'X-Line-ChannelSecret', @channel_secret
        req.add_field 'X-Line-Trusted-User-With-ACL', @channel_mid
        req.body = message.to_json
        http.request req
      end
    end

    def text(matcher, &block)
      @text_handlers.push TextHandler.new(self, matcher, &block)
    end

    def process(message)
      if message.text?
        @text_handlers.each do |handler|
          match = handler.match message

          if match
            handler.handle message, match
            break
          end
        end
      end
    end
  end

  class BotWithMessage
    def initialize(bot, message)
      @bot = bot
      @message = message
    end

    def reply(message)
      message = if message.is_a? String
                  base_message['content'].merge({'message' => message})
                elsif message.is_a? Hash
                  base_message.merge(message)
                end

      @bot.send_message message
    end

    def base_message
      {
        'to'        => @message.to,
        'toChannel' => 1383378250,
        'eventType' => '138311608800106203',
        'content'   => {
          'contentType' => Message::TYPE_TEXT,
          'toType'      => 1,
        },
      }
    end
  end

  class Callback
    SUCCESS = [200, {'Content-Type' => 'text/plain'.freeze, 'Content-Length' => '2'.freeze}.freeze, 'OK'.freeze].freeze
    FAILURE = [470, {'Content-Type' => 'text/plain'.freeze, 'Content-Length' => '2'.freeze}.freeze, 'NG'.freeze].freeze

    def initialize(bot)
      @bot = bot
    end

    def call(env)
      req = Rack::Request.new(env)

      if req.post? && req.path_info = '/callback'
        begin
          @bot.process Message.new(JSON.parse(req.body.read))

          SUCCESS
        rescue
          FAILURE
        end
      else
        FAILURE
      end
    end
  end

  class Message
    attr_reader :id, :content_type, :from, :created_time, :to, :to_type, :content_metadata, :text, :location

    TYPE_TEXT     = 1
    TYPE_IMAGE    = 2
    TYPE_VIDEO    = 3
    TYPE_AUDIO    = 4
    TYPE_LOCATION = 7
    TYPE_STICKER  = 8
    TYPE_CONTACT  = 10

    def initialize(message)
      @id               = message['id']
      @content_type     = message['content_type']
      @from             = message['from']
      @created_time     = Time.at(message['created_time']).utc.to_datetime
      @to               = message['to']
      @to_type          = message['to_type']
      @content_metadata = message['content_metadata']
      @text             = message['text']
      @location         = message['location']
    end

    def text?
      @content_type == TYPE_TEXT
    end

    def image?
      @content_type == TYPE_IMAGE
    end

    def video?
      @content_type == TYPE_VIDEO
    end

    def audio?
      @content_type == TYPE_AUDIO
    end

    def location?
      @content_type == TYPE_LOCATION
    end

    def sticker?
      @content_type == TYPE_STICKER
    end

    def contact?
      @content_type == TYPE_CONTACT
    end
  end

  class BaseHandler
    attr_reader :bot, :handler

    def initialize(bot, &block)
      @bot     = bot
      @handler = handler
    end
  end

  class TextHandler < BaseHandler
    def initialize(bot, matcher, &block)
      super(bot, &block)

      @matcher = matcher
    end

    def match(message)
      @matcher.match message.text
    end

    def handle(message, match)
      handler.call(bot, message, match)
    end
  end
end
