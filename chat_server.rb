#!/usr/bin/env ruby -w
require "socket"
require 'json'

class ChatServer
  def initialize( port, ip )
    @serverSocket = TCPServer.open( ip, port )
    # users to connection lookup
    @clients = Hash.new
    printf("Chat Server started on port %d\n", port)
    run
  end # end initialize

  def run
    loop {
      Thread.start(@serverSocket.accept) do | client |
        net_data = JSON.parse(client.gets)
        # exit if login/registration doesn't have 3 args
        puts sprintf("net_data: %s\n", net_data.inspect)
#        if net_data.length != 3 then
#          client.puts([0xFF].to_json)
#          Thread.kill self
#        end
        command = net_data[0].chomp
        client_ID = net_data[1].chomp
        password = net_data[2].chomp
        usercheck = check_client_ID(client_ID)
        # if user is registering, search user.csv for a client_ID match
        if command == 'REGISTER'
          if (usercheck[0]) then # client_ID in use, reject registration
            client.puts([0x02].to_json)
            Thread.kill self
          else # client_ID is unique, save the new entry, log user in
            new_entry = sprintf("%s,%s\n", client_ID, password)
            File.open('users.csv', "a+").write(new_entry)
            @clients[client_ID] = client
          end
        elsif command == 'LOGIN' # user sending LOGIN command
          # client_ID is registered, and password is correct
          if usercheck[0] && password == usercheck[1].chomp
            puts sprintf("user '%s' logged in\n", client_ID)
            @clients[client_ID] = client
          else # else send error code, and kill thread
            puts "login error. kill thread"
            client.puts([0x01].to_json)
            Thread.kill self
          end
        end
        # passed through register/login
        puts sprintf("'%s' connected\n", client_ID)
        @clients[client_ID] = client
        client.puts [0x00].to_json
        listen_user_messages( client_ID, client )
      end
    }.join
  end # end run

  # check if client_ID is in users.csv, returns tuple; if client_ID is found
  # [true, password], if not found returns [false, nil]
  def check_client_ID( client_ID )
    if File.file? './users.csv'
      File.open('./users.csv').each_line do | line |
        reg_user = line.split(",")
        if reg_user[0] == client_ID
          return [true, reg_user[1]]
        end
      end
    end
    return [false]
  end # end check_client_ID

# listen on client connnection for input messages
  def listen_user_messages( client_ID, client )
    puts "in listen_user_messages"
    loop {
      msg = JSON.parse(client.gets.chomp)
      puts sprintf("msg.inpect : %s\n", msg.inspect)
      command = msg[0]
      if command == 'MSG'
        @clients.each do |other_name, other_client|
          if other_name == client_ID
            client.puts [0x00, "Success"].to_json
          else
            other_client.puts ["#{client_ID.to_s}: #{msg[1]}"].to_json
          end
        end
      elsif command == 'DISCONNECT'
        puts sprintf("disconnecting user '%s'", client_ID)
        client.puts [0x00, "DISCONNECT"].to_json
        @clients.remove client
      elsif command == 'CLIST'
        client.puts [0x00, "CLIST", @clients.keys].to_json
      else # catchall for wrong format
        puts "unknown message format"
        client.puts [0xFF].to_json
      end
    }
    puts "outside listen loop"
  end # end listen_user_messages

end # end ChatServer

# launch server with supplied arguements, or display usage message
if ARGV.length != 2 then
  puts "Usage: chat_server <port_num> <ip_address>\n"
else
  ChatServer.new( ARGV[0].to_i, ARGV[1] )
end
