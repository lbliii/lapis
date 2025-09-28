module Lapis
  class InvalidURLError < Exception
    def initialize(message : String, cause : Exception? = nil)
      super(message, cause)
    end
  end

  class MalformedURLError < Exception
    def initialize(message : String, cause : Exception? = nil)
      super(message, cause)
    end
  end

  class URIParseError < Exception
    def initialize(message : String, cause : Exception? = nil)
      super(message, cause)
    end
  end
end
