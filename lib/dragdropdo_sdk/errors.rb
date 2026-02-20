module D3RubyClient
  # Base error class for D3 Client errors
  class D3ClientError < StandardError
    attr_reader :status_code, :code, :details

    def initialize(message, status_code = nil, code = nil, details = nil)
      super(message)
      @status_code = status_code
      @code = code
      @details = details
    end
  end

  # Error returned by the API
  class D3APIError < D3ClientError
    def initialize(message, status_code, code = nil, details = nil)
      super(message, status_code, code, details)
    end
  end

  # Client-side validation error
  class D3ValidationError < D3ClientError
    def initialize(message, details = nil)
      super(message, 400, nil, details)
    end
  end

  # Upload-specific error
  class D3UploadError < D3ClientError
    def initialize(message, details = nil)
      super(message, nil, nil, details)
    end
  end

  # Timeout error (from polling)
  class D3TimeoutError < D3ClientError
    def initialize(message = "Operation timed out")
      super(message)
    end
  end
end

