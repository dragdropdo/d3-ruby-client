require "spec_helper"
require "tempfile"
require "net/http"
require "uri"
require "webmock/rspec"

RSpec.describe D3RubyClient::Dragdropdo, :live do
  API_BASE = ENV.fetch("D3_BASE_URL", "https://api-dev.dragdropdo.com")
  API_KEY = ENV["D3_API_KEY"]
  RUN_LIVE = ENV["RUN_LIVE_TESTS"] == "1"

  before(:all) do
    unless RUN_LIVE && API_KEY
      skip "Skipping live API tests. Set RUN_LIVE_TESTS=1 and D3_API_KEY to run."
    end
    # Allow real HTTP connections for live tests
    WebMock.allow_net_connect!
  end

  after(:all) do
    # Re-enable WebMock restrictions after live tests
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) do
    D3RubyClient::Dragdropdo.new(
      api_key: API_KEY,
      base_url: API_BASE,
      timeout: 120_000
    )
  end

  describe "upload, convert, poll, download" do
    it "performs full workflow" do
      unless API_KEY
        raise "D3_API_KEY is required for live tests"
      end

      # Create temporary test file
      tmp_file = Tempfile.new(["d3-live-", ".txt"])
      tmp_file.write("hello world")
      tmp_file.close

      begin
        puts "[live-test] Uploading file..."
        upload = client.upload_file(
          file: tmp_file.path,
          file_name: "hello.txt",
          mime_type: "text/plain",
          parts: 1
        )
        puts "[live-test] Upload result: file_key=#{upload[:file_key]}, upload_id=#{upload[:upload_id]}"

        puts "[live-test] Starting convert..."
        operation = client.convert(
          file_keys: [upload[:file_key] || upload[:fileKey]],
          convert_to: "png"
        )
        puts "[live-test] Operation: main_task_id=#{operation[:main_task_id]}"

        puts "[live-test] Polling status..."
        status = client.poll_status(
          main_task_id: operation[:main_task_id] || operation[:mainTaskId],
          interval: 3000, # 3 seconds
          timeout: 60_000 # 60 seconds
        )
        puts "[live-test] Final status: operation_status=#{status[:operation_status]}"

        op_status = status[:operation_status] || status[:operationStatus]
        expect(op_status).to eq("completed")
        files_data = status[:files_data] || status[:filesData] || []
        expect(files_data).not_to be_empty

        link = files_data[0][:download_link] || files_data[0][:downloadLink]
        expect(link).to be_truthy

        if link
          puts "[live-test] Downloading output..."
          uri = URI(link)
          response = Net::HTTP.get_response(uri)
          expect(response.code).to eq("200")
          expect(response.body.length).to be > 0
          puts "[live-test] Downloaded bytes: #{response.body.length}"
        end
      ensure
        tmp_file.unlink if File.exist?(tmp_file.path)
      end
    end
  end
end

