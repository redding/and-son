# AndSon

AndSon is a simple Sanford client for Ruby.  It provides an API for calling services and handling responses.  It uses [Sanford::Protocol](https://github.com/redding/sanford-protocol) to communicate with Sanford servers.

## Usage

Create a client instance, pointing it at a Sanford server:

```ruby
client = AndSon.new('127.0.0.1', 8000, 'v1')
```

To create a client, specify the host's ip address and port plus the version of the API to make calls against.

Call specific services using the `call` method:

```ruby
response = client.call('get_user', { :user_name => 'joe.test' })
```

This will make a request against `'v1'` of the service host and call the service `'get_user'` with any given data.

This will return a `Sanford::Protocol::Response` object:

```ruby
response.status.code    #=> 200
response.status.name    #=> OK
response.status.message #=> "Success."
response.data           #=> {:some => 'data'}
```

For more details about the response object, see [sanford-protocol](https://github.com/redding/sanford-protocol).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
