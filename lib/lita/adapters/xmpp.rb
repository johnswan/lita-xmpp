require "lita"
require "lita/adapters/xmpp/connector"

module Lita
  module Adapters
    class Xmpp < Adapter
      config :jid, type: String, required: true
      config :password, type: String, required: true
      config :debug, types: [TrueClass, FalseClass], default: false
      config :rooms, type: Array
      config :muc_domain, type: String
      config :connect_domain, type: String

      attr_reader :connector

      def initialize(robot)
        super

        @connector = Connector.new(
          robot,
          config.jid,
          config.password,
          debug: config.debug,
          connect_domain: config.connect_domain
        )
      end

      def join(room_id)
        connector.join(config.muc_domain, room_id)
        robot.trigger(:joined, room: room_id)
      end

      def mention_format(name)
        "@#{name}"
      end

      def part(room_id)
        robot.trigger(:parted, room: room_id)
        connector.part(config.muc_domain, room_id)
      end

      def run
        connector.connect
        connector.join_rooms(config.muc_domain, rooms)
        sleep
      rescue Interrupt
        shut_down
      end

      def send_messages(target, strings)
        if target.room
          connector.message_muc(target.room, strings)
        else
          connector.message_jid(target.user.id, strings)
        end
      end

      def send_raw_messages(target, strings)
        if target.room
          connector.message_muc(target.room, strings, true)
        else
          connector.message_jid(target.user.id, strings)
        end
      end

      def set_topic(target, topic)
        connector.set_topic(target.room, topic)
      end

      def shut_down
        connector.shut_down
      end

      private

      def config
        Lita.config.adapters.xmpp
      end

      def rooms
        if config.rooms == :all
          connector.list_rooms(config.muc_domain)
        else
          Array(config.rooms)
        end
      end
    end

    Lita.register_adapter(:xmpp, Xmpp)
  end
end
