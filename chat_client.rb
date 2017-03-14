#!/usr/bin/env ruby -w
require "socket"
require "json"
class Client
  @server = nil
  @request = nil
  @response = nil
  # initialize the connection; failure exits
  def initialize( port_num, ip_address )
    @server = TCPSocket.open( ip_address, port_num )
    puts "Client is not connected."
    @connected = false
# TODO check if server connected
    listen
    send
    @request.join
    @response.join
  end
  # prompt user to login or register
  def register_or_login
    request = [nil, nil, nil]
    loop {
      puts "to register a new account:\n\tREGISTER <client_ID> <password>\nto login:\n\tLOGIN <client_ID> <password>\n"
      msg = $stdin.gets.chomp.split
      if msg.length == 3 && (msg[0] == 'REGISTER' || msg[0] == 'LOGIN')
        request = [msg[0], msg[1], msg[2] ].to_json
        break
      end
    }
    request
  end # end register_or_login

# listen for messages from server
  def listen
    @response = Thread.new do
      loop {
        msg = JSON.parse(@server.gets.chomp)
        puts sprintf("msg in listen: %s\n", msg.inpect)
        if msg[0].string?
          puts msg[0]
        elsif msg[0] == 0x00
          if msg[1] == "CLIST"
            puts msg[1].to_s.gsub!(/["\[\]]/,'')
          elsif msg[1] == "DISCONNECT"
            puts "disconnecting"
            exit(0)
          end
        elsif msg[0] == 0x01
          puts "Access denied, wrong password or no such client_ID"
          exit(0)
        elsif msg[0] == 0x02
          puts "Duplicate client_ID"
          exit(0)
        end
      }
    end
  end # end listen

  # send messages to char server
  def send
    @request = Thread.new do
      request = nil
      msg = nil
      loop {
        if !@connected
          request = register_or_login
          puts sprintf("msg in send: %s\n", msg.inspect)
          @connected = true
        else
          msg = $stdin.gets.chomp.split
          command = msg.first
          if command == 'MSG'
            puts msg.inspect
            msg = msg.slice(1, msg.length-1).join(' ')
          else
            msg = nil
          end
          request = [command, msg].to_json
        end
        @server.puts( request )
      }
    end
  end #end send
end # end Client


# launch client with supplied arguements or print usage message
if ARGV.length != 2 then
  puts "Usage: chat_server <port_num> <ip_address>\n"
else
  Client.new( ARGV[0].to_i, ARGV[1] )
end
