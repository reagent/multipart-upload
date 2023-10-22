require 'bundler/setup'
require 'httparty'
require 'stringio'
require 'securerandom'

class Uploader
  UploadError = Class.new(RuntimeError)
  MissingUploadError = Class.new(UploadError)
  UnknownContentError = Class.new(UploadError)

  class UploadableIO
    def initialize(content)
      @content = content
      @data = StringIO.new(content)
      @filename = 'content.dat'
    end

    def path
      @filename.to_s
    end

    def bytesize
      @content.bytesize
    end

    def read
      @data.read
    end
  end

  def initialize(base_uri:)
    @base_uri = base_uri
    @uploads = {}
  end

  def add(content)
    key = SecureRandom.alphanumeric

    @uploads[key] =
      if content.is_a?(String)
        UploadableIO.new(content)
      elsif content.respond_to?(:open)
        content.open
      elsif content.respond_to?(:read) && content.respond_to?(:path)
        content
      else
        raise UnknownContentError
      end
  end

  def upload
    raise MissingUploadError unless @uploads.any?

    HTTParty.post(
      '/upload',
      multipart: true,
      body: @uploads,
      base_uri: @base_uri
    )
  end
end
