# AndSon

AndSon is a client gem for communicating with a Sanford server. It provides a generic interface for calling services and handles serializing the request and deserializing the response.

## Usage

AndSon is a very light client. To use it, create a client, pointing it at a Sanford server:

```ruby
client = AndSon.new('127.0.0.1', 8000, 'v1')
```

When creating a client, a version needs to be passed in addition to the Sanford server's host and port. This will have the client make requests against that version of the Sanford service host.

Once a client is created, a service can be called, using the `call` method:

```ruby
response = client.call('get_user', { :user_name => 'joe.test' })
```

This will make a request against `'v1'` of the Sanford service host, for the service `'get_user'`. We are also passing the user name `'joe.test'` in the parameters. This will call the service on the Sanford server and return the result, a `Sanford::Protocol::Response` object. A response contains a status and the result of the service (if it succeeded successfully):

```ruby
response.status.code    # => 200 (successful)
response.status.message # => optional message, usually set on non-200 results
response.result         # => the result of calling the service
```

For more details about the response object, see the `sanford-protocol` gem.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
