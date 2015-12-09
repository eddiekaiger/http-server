
require 'socket' #Provides TCPServer and TCPSocket classes

port=8888

# Initialize a TCPServer object that will listen on localhost:2345
# for incoming connections
server = TCPServer.new('localhost', port);

print "Check out port #{port}!\n"

# Loop infinitely, processing one incoming connection at a time
loop do

    # Wait until a client connects, then return a TCPSocket
    socket = server.accept

    # Read the first line of the request
    request = socket.gets

    # Log the request to the console for debugging
    STDERR.puts request

    # Return response
    response = "Hello World!\n"
    socket.print    "HTTP/1.1 200 OK\r\n" +
                    "Content-Type: text/plain\r\n" +
                    "Content-Length: #{response.bytesize}\r\n" +
                    "Connection: close\r\n\r\n" +
                    response

    # Close connection
    socket.close

end
