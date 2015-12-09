
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

STATUS = {
    200 => "200 OK",
    204 => "204 No Content",
    400 => "400 Method Not Allowed",
    404 => "404 Not Found",
    500 => "500 Internal Server Error"
}

# Treat as binary data if content type cannot be found
DEFAULT_CONTENT_TYPE = 'application/octet-stream'

# Parses the extension of the requested file and returns content type
def content_type(path)
    ext = File.extname(path).split(".").last
    CONTENT_TYPES.fetch(ext, DEFAULT_CONTENT_TYPE)
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

def http_response(status_code, content_type, content_len)

    # Retrieve actual status
    status = STATUS.fetch(status_code, "500 Internal Server Error")

    "HTTP/1.1 #{status}\r\n" +
    "Content-Type: #{content_type}\r\n" +
    "Content-Length: #{content_len}\r\n" +
    "Connection: close\r\n\r\n"
end

def handle_GET(request, socket)

    # Generate path to file
    path = requested_file(request)

    # Return index.html implicitly
    path = File.join(path, 'index.html') if File.directory?(path)

    # Make sure the file exists and is not a directory
    if File.exist?(path) && !File.directory?(path)
        begin
            File.open(path, "rb") do |file|
                socket.print http_response(200, content_type(file), file.size)
                # Write contents of file to socket
                IO.copy_stream(file, socket)
            end
        rescue Exception => msg
            STDERR.puts msg
            socket.print http_response(500, CONTENT_TYPES["txt"], 0)
        end
    else
        message = "File not found\n"

        # Respond with 404
        socket.print http_response(404, CONTENT_TYPES["txt"], message.size)
        socket.print message
    end
end


def handle_POST(request, socket)
    # TODO: Implement
end


def handle_DELETE(request, socket)

    # Generate path to file
    path = requested_file(request)

    # Make sure the file exists and is not a directory
    if File.exist?(path) && !File.directory?(path)
        begin
            File.delete(path)
            socket.print http_response(200, CONTENT_TYPES["txt"], 0)
        rescue Exception => msg
            STDERR.puts msg
            socket.print http_response(500, CONTENT_TYPES["txt"], 0)
        end
    else
        # Respond with 204, in accordance with HTTP protocol
        socket.print http_response(204, CONTENT_TYPES["txt"], 0)
    end

end


def handle_HEAD(request, socket)
    # TODO: Implement
end

def handle_PUT(request, socket)
    # TODO: Implement
end


def handle_request(request, socket)

    # Extract method (i.e. GET, POST, DELETE, etc)
    method = request.split(" ")[0]

    case method
    when "GET"
        handle_GET(request, socket)
    when "POST"
        handle_POST(request, socket)
    when "DELETE"
        handle_DELETE(request, socket)
    when "PUT"
        handle_PUT(request, socket)
    else
        socket.print http_response(400, CONTENT_TYPES["txt"], 0)
    end
end



# Port number to use
port = 8888

# Initialize server that listens for incoming connections
server = TCPServer.new('localhost', port)

print "Check out port #{port}!\n"

# Loop infinitely, processing one incoming connection at a time
loop do

    # Receive request from socket
    socket = server.accept
    request = socket.gets

    # Log the request to the console for debugging
    STDERR.puts request

    # Handle request
    handle_request(request, socket)

    # Close connection
    socket.close

end
