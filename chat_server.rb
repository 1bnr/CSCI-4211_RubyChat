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
          client.puts("Illegal input. exiting.\n")
          Thread.kill self
        end

        command = net_data[0]
        username = net_data[1]
        password = net_data[2]
        usercheck = check_username(username)
        # if user is registering, search user.csv for a username match
        if command == 'REGISTER' then
          if (usercheck[0]) then # username in use, reject registration
            client.puts("Username already in use. Registration rejected.\n")
            Thread.kill self
          else # username is unique, save the new entry, log user in
            new_entry = sprintf("%s,%s\n", username, password)
            File.write('users.csv', "a+").write(new_entry)
          end
        elsif command == 'LOGIN' then
          puts usercheck[1].eql? password
          if !usercheck[0] || password != usercheck[1].chomp
            client.puts("incorrect username or password\n")
            Thread.kill self
          end
        end
        @clients[username] = client
        client.puts "Connection established."
        listen_user_messages( username, client )
      end
    }.join
  end

  def check_username( username )
    File.open('users.csv').each_line do | line |
      reg_user = line.split(",")
      if reg_user[0] == username
        return [true, reg_user[1]]
      end
    end
    return [false]
  end

  def listen_user_messages( username, client )
    loop {
      msg = client.gets.chomp
      puts "#{username.to_s}: #{msg}"
      @clients.each do |other_name, other_client|
        unless other_name == username
          other_client.puts "#{username.to_s}: #{msg}"
        end
      end

    }
  end

end
ChatServer.new( 3000, "localhost" )
