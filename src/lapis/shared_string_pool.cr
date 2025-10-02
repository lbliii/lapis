require "string_pool"

module Lapis
  # Global StringPool singleton for memory-efficient string caching across all processors
  # This eliminates the need for multiple StringPool instances and provides thread-safe access
  class SharedStringPool
    @@instance : SharedStringPool?
    @@lock = Mutex.new

    getter pool : StringPool
    @lock : Mutex

    def self.instance : SharedStringPool
      @@lock.synchronize do
        @@instance ||= new
      end
    end

    private def initialize
      @pool = StringPool.new(2048) # Larger capacity for shared use across all processors
      @lock = Mutex.new
    end

    # Thread-safe string caching
    def get(str : String) : String
      @lock.synchronize do
        @pool.get(str)
      end
    end

    # Get current pool size
    def size : Int32
      @pool.size
    end

    # Clear the pool (useful for testing)
    def clear
      @lock.synchronize do
        @pool.clear
      end
    end

    # Get pool statistics
    def stats : NamedTuple(size: Int32, capacity: Int32)
      @lock.synchronize do
        {size: @pool.size, capacity: 2048}
      end
    end

    # Memory usage estimation
    def memory_usage : Int32
      @lock.synchronize do
        # Rough estimation: 8 bytes per entry + string data
        @pool.size * 8
      end
    end
  end
end
