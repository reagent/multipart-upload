# Multipart Upload Demonstration

This example demonstrates a basic [Sinatra] application that can process HTTP
multipart file uploads along with a client that can upload content to the
exposed endpoint.

The goal of this example is to demonstrate how you might test a file upload to
an external service where you don't have much insight into what the server
received. In this case, we receive only a session ID after a successful upload
and no indication of what files were received. In situations such as these, we
may be able to inspect the body of the request to determine what was sent. See
the [uploader spec](./spec/uploader_spec.rb) for how this is done.

## Setup

Install dependencies and run the server:

```
bundle && ruby src/server.rb
```

## Usage

You can use [cURL] to test uploading a file:

```
echo content > upload.dat && curl -s -F upload.dat=@upload.dat http://localhost:4567/upload
```

If successful, you can see the file in the `uploads` directory under the session
ID returned in the response:

```json
{ "session_id": "88695b83-c2d4-4150-bf38-df6728431936" }
```

## Testing

You can run tests with RSpec:

```
bundle exec rspec
```

[Sinatra]: https://sinatrarb.com/
[cURL]: https://curl.se/
