#!/usr/bin/env ruby -w
require "socket"
require "json"
class Client
  def initialize( port_num, ip_address )
    server = TCPSocket.open( ip_address, port_num )
    puts "Client is not connected."
    request = [nil, nil, nil]
    loop do
      puts "to register a new account:\n\tREGISTER <username> <password>\nto login:\n\tLOGIN <username> <password>\n"
      msg = $stdin.gets.chomp.split
      if msg.length != 3 then
        msg[0] = "HELP"
      end
      request = [msg[0], msg[1], msg[2] ].to_json
      if (msg[0] == 'REGISTER' || msg[0] == 'LOGIN')
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
        msg = JSON.parse(@server.gets.chomp)
        if msg[0] == 'MSG'
          puts msg[1]
        elsif msg[0] == 'CLIST'
          list = msg[1].to_s.gsub /["\[\]]/,''
          puts list
        elsif msg[0] == "DISCONNECT"
          puts "disconnecting"
          exit(0)
        end
      }
    end
  end

  def send
    @request = Thread.new do
      loop {
        msg = $stdin.gets.chomp.split
        command = msg.first
        if command == 'MSG'
          msg = msg.slice(1, msg.length-1).join(' ')
        end
        request = [command, msg].to_json
        @server.puts( request )
      }
    end
  end
end



if ARGV.length != 2 then
  puts "Usage: chat_server <port_num> <ip_address>\n"
else
  Client.new( ARGV[0].to_i, ARGV[1] )
end
