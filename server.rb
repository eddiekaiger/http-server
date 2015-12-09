
require 'socket'
require 'uri'

# Files will be served from this directory
WEB_ROOT = './public'

# Map extensions to their content type
CONTENT_TYPES = {
    'html' => 'text/html',
    'txt' => 'text/plain',
    'png' => 'image/png',
    'jpeg' => 'image/jpeg',
    'json' => 'application/json'
}

# Treat as binary data if content type cannot be found
DEFAULT_CONTENT_TYPE = 'application/octet-stream'

# Parses the extension of the requested file and returns content type
def content_type(path)
    ext = File.extname(path).split(".").last
    CONTENT_TYPES.fetch(ext, DEFAULT_CONTENT_TYPE);
end

# Parses request line and generates a path to a file on the server
def requested_file(request_line)
    request_uri = request_line.split(" ")[1]
    path = URI.unescape(URI(request_uri).path)

    # Cleaning necessary so that only files inside of WEB_ROOT can be accessible
    clean = []

    # Perform clean by removing previous path component any time '..' is encountered
    parts = path.split("/")
    parts.each do |part|
        next if part.empty? || part == '.'
        part == '..' ? clean.pop : clean << part
    end

    # Return final file path
    File.join(WEB_ROOT, path)
end

def http_response(status, content_type, content_len)
    "HTTP/1.1 #{status}\r\n" +
    "Content-Type: #{content_type}\r\n" +
    "Content-Length: #{content_len}\r\n" +
    "Connection: close\r\n\r\n"
end

# Port number to use
port = 8888

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

    # Generate path to file
    path = requested_file(request);

    # Return index.html implicitly
    path = File.join(path, 'index.html') if File.directory?(path)

    # Make sure the file exists and is not a directory
    if File.exist?(path) && !File.directory?(path)
        File.open(path, "rb") do |file|
            socket.print http_response("200 OK", content_type(file), file.size)
            # Write contents of file to socket
            IO.copy_stream(file, socket)
        end
    else
        message = "File not found\n"

        # Respond with 404
        socket.print http_response("404 Not Found", CONTENT_TYPES["txt"], message.size)
        socket.print message
    end

    # Close connection
    socket.close

end
