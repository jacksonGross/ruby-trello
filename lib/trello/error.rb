module Trello
  class Error < StandardError

    def initialize(name, uri, response_code)
      @name = name
      @uri = uri
      @response_code = response_code
    end

    alias :orig_to_s :to_s
    def to_s
      "#{orig_to_s} (#{@name} request to #{@uri} returned status #{@response_code})"
    end

  end
end