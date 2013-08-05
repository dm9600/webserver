require 'socket'

module Webserver

   class Server
      attr_accessor :port, :host, :servlets

      # args is an array passed in from run.rb
      def initialize(args)
         @command = args[0]
         @port = 3333
         @host = '127.0.0.1'
         @servlets = {}
         if args[0].is_a?(String)
            @host = args[1] if args[0].include? 'h'
            @port = args[1] if args[0].include? "p"
         end 
      end 

      def start
         @server = TCPServer.new(@host, @port)
         puts "Server created at #{@host} and port #{@port}"
         basepath = './app'   
         while (session = @server.accept)
            #parse the entire request into a key/val map
            parsed_request = Webserver::parseHTTPRequest(session)
            heading = parsed_request['Heading']

            #Get the method from the heading
            method = heading.split(' ')[0]

            #Remove everything except the path from the heading
            trimmedrequest = Webserver::trim_heading(heading, method)
            ct = Webserver::get_content_type(trimmedrequest)
            session.print "HTTP/1.1 200/OK\nContent-type:#{ct}\n\n"
            puts"HTTP/1.1 200/OK\nContent-type:#{ct}\n\n" 
            filename = trimmedrequest.chomp
            begin
               displayfile = Webserver::find_file(filename)
               content = displayfile.read()
               session.print content
            rescue Errno::ENOENT
               session.print "File not found"
            end
            session.close
         end
      end 
   end

   def mount(route, servlet)
      @servlet[route] = servlet   
   end 

   def self.trim_heading(heading, method)
      heading.gsub(/#{method}\ \//, '').gsub(/\ HTTP.*/, '')
   end 

   def self.find_file(path)
      basepath = "./app/"
      if path.empty?
         full_path = basepath + 'index.html'
      else
         full_path = basepath + path
      end 
      File.open full_path, 'rb'
   end 

   def self.get_content_type(path)
      ext = File.extname(path).downcase
      puts ext
      return "text/html"  if ext.include? ".html" or ext.include? ".htm"
      return "text/plain" if ext.include? ".txt"
      return "text/css"   if ext.include? ".css"
      return "image/jpeg" if ext.include? ".jpeg" or ext.include? ".jpg"
      return "image/gif"  if ext.include? ".gif"
      return "image/bmp"  if ext.include? ".bmp"
      return "image/png" if ext.include? ".png"
      return "text/plain" if ext.include? ".rb"
      return "text/xml"   if ext.include? ".xml"
      return "text/xml"   if ext.include? ".xsl"
      return "text/html"
   end

   #TODO: refactor this using chomp instead of slice
   def self.parseHTTPRequest(request)
      headers = {}

      #get the heading (first line)
      headers['Heading'] = request.gets.gsub /^"|"$/, ''.tap{|val|val.slice!('\r\n')}.strip
      method = headers['Heading'].split(' ')[0]

      #request is going to be a TCPsocket object 
      #parse the header
      while true
         #do inspect to get the escape characters as literals
         #also remove quotes
         line = request.gets.inspect.gsub /^"|"$/, ''

         puts line
         #if the line only contains a newline, then the body is about to start
         break if line.eql? '\r\n'

         label = line[0..line.index(':')-1]

         #get rid of the escape characters
         val = line[line.index(':')+1..line.length].tap{|val|val.slice!('\r\n')}.strip
         headers[label] = val
      end 

      #If it's a post, then we need to get the body
      headers['Body'] = request.read(headers['Content-Length'].to_i) if method.eql?('POST')
      puts headers['Body'] if headers.has_key?('Body')

      return headers
   end 

   def self.parsePostBody(post_body)

   end 
end 

