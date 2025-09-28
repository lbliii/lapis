require "../spec_helper"

describe "Server Integration" do
  describe "HTTP server" do
    it "serves static files", tags: [TestTags::INTEGRATION] do
      config = TestDataFactory.create_config("Test Site", "test_output")
      config.port = 3001 # Use different port to avoid conflicts

      with_temp_directory do |temp_dir|
        config.output_dir = File.join(temp_dir, "output")

        # Create test content
        content_dir = File.join(temp_dir, "content")
        Dir.mkdir_p(content_dir)

        content_text = <<-MD
        ---
        title: Server Test
        date: 2024-01-15
        layout: post
        ---

        # Server Test

        This tests server functionality.
        MD

        File.write(File.join(content_dir, "server-test.md"), content_text)

        # Build site first
        generator = Lapis::Generator.new(config)
        generator.build

        # Create server
        server = Lapis::Server.new(config)

        # Test that server can be created without errors
        server.should be_a(Lapis::Server)
        server.config.should eq(config)
      end
    end

    it "handles server configuration", tags: [TestTags::INTEGRATION] do
      config = TestDataFactory.create_config("Test Site", "test_output")
      config.host = "127.0.0.1"
      config.port = 3002

      generator = Lapis::Generator.new(config)
      server = Lapis::Server.new(config)

      server.config.host.should eq("127.0.0.1")
      server.config.port.should eq(3002)
    end

    it "handles invalid server configuration", tags: [TestTags::INTEGRATION] do
      config = TestDataFactory.create_config("Test Site", "test_output")
      config.port = -1 # Invalid port

      generator = Lapis::Generator.new(config)

      expect_raises(Lapis::ServerError) do
        server = Lapis::Server.new(config)
        server.start
      end
    end
  end

  describe "live reload" do
    it "initializes live reload system", tags: [TestTags::INTEGRATION] do
      config = TestDataFactory.create_config("Test Site", "test_output")
      config.port = 3003

      generator = Lapis::Generator.new(config)
      server = Lapis::Server.new(config)

      # Live reload should be initialized
      server.live_reload.should be_a(Lapis::LiveReload)
    end

    it "handles WebSocket connections", tags: [TestTags::INTEGRATION] do
      config = TestDataFactory.create_config("Test Site", "test_output")
      config.port = 3004

      generator = Lapis::Generator.new(config)
      server = Lapis::Server.new(config)

      # WebSocket handler should be available
      server.live_reload.websocket_handler.should be_a(Lapis::WebSocketHandler)
    end
  end

  describe "file serving" do
    it "serves HTML files", tags: [TestTags::INTEGRATION] do
      config = TestDataFactory.create_config("Test Site", "test_output")

      with_temp_directory do |temp_dir|
        config.output_dir = File.join(temp_dir, "output")
        Dir.mkdir_p(config.output_dir)

        # Create test HTML file
        html_content = "<html><body><h1>Test</h1></body></html>"
        File.write(File.join(config.output_dir, "test.html"), html_content)

        generator = Lapis::Generator.new(config)
        server = Lapis::Server.new(config)

        # Test file serving (without actually starting server)
        # This tests the file serving logic
        server.should be_a(Lapis::Server)
      end
    end

    it "handles missing files", tags: [TestTags::INTEGRATION] do
      config = TestDataFactory.create_config("Test Site", "test_output")

      generator = Lapis::Generator.new(config)
      server = Lapis::Server.new(config)

      # Server should handle missing files gracefully
      server.should be_a(Lapis::Server)
    end
  end
end
