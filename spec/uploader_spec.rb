require 'debug'
require 'vcr'

require_relative '../src/uploader'
require_relative './support/httparty_request_body'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/cassettes'
  config.hook_into :webmock
end

UUID = /^[0-9a-fA-F]{8}\b(-[0-9a-fA-F]{4}\b){3}-[0-9a-fA-F]{12}$/

RSpec.describe Uploader do
  describe '#upload' do
    let(:base_uri) { 'http://localhost:4567'}
    subject { described_class.new(base_uri:)}

    it 'raises when trying to upload unknown content' do
      expect { subject.add(1) }.to raise_error(Uploader::UnknownContentError)
    end

    it 'raises when no uploads have been queued' do
      expect {subject.upload}.to raise_error(Uploader::MissingUploadError)
    end

    it 'can successfully upload string content' do
      VCR.use_cassette("string_content") do
        subject.add('string content')
        response = subject.upload

        request_parts = HTTPartyRequestBody.decode(response.request.raw_body)

        aggregate_failures do
          expect(request_parts.length).to eq(1)
          expect(request_parts.first.content).to eq('string content')

          expect(response.code).to eq(200)
          expect(response.parsed_response).to match({'session_id' => UUID})
        end
      end
    end

    it 'can successfully upload file content' do
      VCR.use_cassette('file_content') do
        file = create_file('file content')

        subject.add(file)
        response = subject.upload

        request_parts = HTTPartyRequestBody.decode(response.request.raw_body)

        aggregate_failures do
          expect(request_parts.length).to eq(1)
          expect(request_parts.first.content).to eq('file content')

          expect(response.code).to eq(200)
          expect(response.parsed_response).to match({'session_id' => UUID})
        end

        file.unlink
      end
    end

    it 'can successfully upload content from a path reference' do
      VCR.use_cassette('path_content') do
        file = create_file('file content from path')

        subject.add(Pathname(file.path))
        response = subject.upload

        request_parts = HTTPartyRequestBody.decode(response.request.raw_body)

        aggregate_failures do
          expect(request_parts.length).to eq(1)
          expect(request_parts.first.content).to eq('file content from path')

          expect(response.code).to eq(200)
          expect(response.parsed_response).to match({'session_id' => UUID})
        end

        file.unlink
      end
    end

    it 'can successfully upload multiple file sources' do
      VCR.use_cassette('all_content') do
        file_1 = create_file('file_1')
        file_2 = create_file('file_2')

        subject.add(file_1)
        subject.add(Pathname.new(file_2.path))
        subject.add('string')

        response = subject.upload

        request_parts = HTTPartyRequestBody.decode(response.request.raw_body)

        aggregate_failures do
          expect(request_parts.length).to eq(3)
          expect(request_parts[0].content).to eq('file_1')
          expect(request_parts[1].content).to eq('file_2')
          expect(request_parts[2].content).to eq('string')

          expect(response.code).to eq(200)
          expect(response.parsed_response).to \
            match('session_id' => UUID)
        end

        file_1.unlink
        file_2.unlink
      end
    end

  end

  private

  def create_file(content)
    Tempfile.new.tap do |file|
      file.write(content)
      file.close
    end
  end
end
