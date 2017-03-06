#!/usr/bin/env ruby -w
require "socket"
require "json"
class Client
  def initialize( server )
    puts "Client is not connected."
    request = [nil, nil, nil]
    loop do
      puts "to register a new account:\n\tREGISTER <username> <password>\nto login:\n\tLOGIN <username> <password>\n"
      msg = $stdin.gets.chomp.split
      request = [msg[0], msg[1], msg[2] ].to_json
      if msg.length != 3 then
        msg[0] = "HELP"
      end
      if msg[0] != 'HELP' && (msg[0] != 'REGISTER' || msg[0] != 'LOGIN')
        break
      end
    end
    @server = server
    @request = nil
    @response = nil
    @server.puts(request)

    listen
    send
    @request.join
    @response.join
  end

  def listen
    @response = Thread.new do
      loop {
        msg = @server.gets.chomp
        puts "#{msg}"
      }
    end
  end

  def send
    @request = Thread.new do
      loop {
        msg = $stdin.gets.chomp.split
        request = [msg[0], msg[1], msg[2] ].to_json
        @server.puts( request )
      }
    end
  end
end



server = TCPSocket.open( "localhost", 3000 )
Client.new( server )
