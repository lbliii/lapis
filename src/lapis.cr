require "./lapis/*"

module Lapis
  VERSION = "0.4.0"
  # Simplified build metadata to avoid macro issues
  BUILD_DATE   = "2025-09-29"
  BUILD_COMMIT = "198fab4"
  DESCRIPTION  = "Lapis #{VERSION} [#{BUILD_COMMIT}] (#{BUILD_DATE})"

  # Standard date formats used throughout the application
  DATE_FORMAT       = "%Y-%m-%d %H:%M:%S UTC"
  DATE_FORMAT_SHORT = "%Y-%m-%d"
  DATE_FORMAT_HUMAN = "%B %d, %Y"
end
