module Core
  class EventBus
    def self.publish(channel, payload)
      ActionCable.server.broadcast(channel, payload)
    end
  end
end

