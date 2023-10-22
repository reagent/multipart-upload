require 'bundler/setup'
require 'sinatra'
require 'securerandom'

post '/upload' do
  session_id = SecureRandom.uuid

  upload_path = Pathname(__dir__).join('..', 'uploads', session_id).expand_path
  upload_path.mkpath

  params.values.each do |attributes|
    file = upload_path.join(attributes[:filename])
    file.write(attributes[:tempfile].read)
  end

  [
    200,
    { 'Content-Type': 'application/json' },
    JSON.generate({ session_id: })
  ]
end
