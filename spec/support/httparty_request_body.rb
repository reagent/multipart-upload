require 'rack'

class HTTPartyRequestBody
  class Part
    def initialize(name, attributes)
      @name = name
      @attributes = attributes
    end

    def content
      @attributes[:tempfile].read
    end
  end

  def self.decode(raw)
    new(raw).decoded
  end

  def initialize(raw)
    @raw = raw
  end

  def decoded
    options = {
      'CONTENT_TYPE' => %(multipart/form-data; boundary=#{boundary}),
      'CONTENT_LENGTH' => @raw.bytesize.to_s,
      :input => StringIO.new(@raw)
    }

    env = Rack::MockRequest.env_for('/', options)

    Rack::Multipart.parse_multipart(env).map do |name, attrs|
      Part.new(name, attrs)
    end
  end

  def boundary
    lines.first.sub(/^-{2}/, '')
  end

  def lines
    @raw.split("\r\n")
  end
end
