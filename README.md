# AndSon

AndSon is a simple Sanford client for Ruby.  It provides an API for calling services and handling responses.  It uses [Sanford::Protocol](https://github.com/redding/sanford-protocol) to communicate with Sanford servers.

## Usage

```ruby
# create a client
client = AndSon.new('127.0.0.1', 8000, 'v1')

# call a service and get its response data:
user_data = client.call('get_user', { :user_name => 'joetest' })
```

## Calling Services

To call a service, you first need a client to make the calls.  You define clients by specifying the host's ip address and port plus the version of the API to make calls against.

Once you have your client defined, make service calls using the `call` method.  It will return any response data and raise an exception if anything goes wrong.

### Exception Handling

AndSon raises exceptions when a call responds with a `4xx` or `5xx` response code (see [Sanford Status Codes](https://github.com/redding/sanford-protocol#status-codes) for more on response codes):

* `400`: `BadRequestError < ClientError`
* `404`: `NotFoundError < ClientError`
* `4xx`: `ClientError < RequestError`
* `5xx`: `ServerError < RequestError`

```ruby
client.call('some_unknown_service')   #=> NotFoundError...
```

Each exception knows about the response that raised it:

```ruby
begin
  client.call('some_unknown_service')
rescue AndSon::NotFoundError => err
  err.response              #=> AndSon::Response ...
  err.response.status.code  #=> 404
end
```

### Response Handling

If you call a service and pass it a block, no exceptions will be raised and the call will yield its response to the block.  The call will return the return value of the block.

```ruby
user = client.call('get_user', { :user_name => 'joetest' }) do |response|
  if response.status.code == 200
    User.new(response.data)
  else
    NullUser.new
  end
end
```

For more details about the response object, see [sanford-protocol](https://github.com/redding/sanford-protocol#response).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
