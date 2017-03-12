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
  end

  def run
    loop {
      Thread.start(@serverSocket.accept) do | client |
        net_data = JSON.parse(client.gets)
        # exit if login/registration doesn't have 3 args

        if net_data.length != 3 then
          client.puts([0xFF].to_json)
          Thread.kill self
        end
        command = net_data[0].chomp
        username = net_data[1].chomp
        password = net_data[2].chomp
        usercheck = check_username(username)
        # if user is registering, search user.csv for a username match
        if command == 'REGISTER' then
          if (usercheck[0]) then # username in use, reject registration
            client.puts([0x02].to_json)
            Thread.kill self
          else # username is unique, save the new entry, log user in
            new_entry = sprintf("%s,%s\n", username, password)
            File.open('users.csv', "a+").write(new_entry)
            @clients[username] = client
          end
        elsif command == 'LOGIN' then
          if !usercheck[0] || password != usercheck[1].chomp
            client.puts([0x01].to_json)
            Thread.kill self
          else
            @clients[username] = client
          end
        end
        @clients[username] = client
        client.puts [0x00].to_json
        listen_user_messages( username, client )
      end
    }.join
  end

  def check_username( username )
    puts "in check_username"
    if File.file? './users.csv'
      puts 'file found'
      File.open('./users.csv').each_line do | line |
        reg_user = line.split(",")
        if reg_user[0] == username
          return [true, reg_user[1]]
        end
      end
    end
    return [false]
  end

  def listen_user_messages( username, client )
    loop {
      msg = JSON.parse(client.gets.chomp)
      command = msg[0]
      if command == 'MSG' && msg.length <= 2
        @clients.each do |other_name, other_client|
          unless other_name == username
            other_client.puts ["MSG", "#{username.to_s}: #{msg[1]}"].to_json
          end
        end
        client.puts ["0x00"].to_json
      
      elsif command == 'DISCONNECT'
        @clients.remove client
      elsif command == 'CLIST'
        client.puts [0x00].to_json
        client.puts ["CLIST", @clients.keys].to_json
      else # catchall for wrong format
        client.puts [0xFF].to_json
      end

    }
  end

end

if ARGV.length != 2 then
  puts "Usage: chat_server <port_num> <ip_address>\n"
else
  ChatServer.new( ARGV[0].to_i, ARGV[1] )
end
