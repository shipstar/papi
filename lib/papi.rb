require "papi/version"

require 'papi/aws'
require 'papi/locale'
require 'papi/version'
require 'papi/aws/cache'
require 'papi/aws/search'
require 'papi/aws/shopping_cart'

module Papi
  # A top-level exception container class.
  #
  class AmazonError < StandardError; end

  NAME = 'Ruby/Amazon'

  @@config = {}

  # Prints debugging messages and works like printf, except that it prints
  # only when Ruby is run with the -d switch.
  #
  def self.dprintf(format='', *args)
    $stderr.printf( format + "\n", *args ) if $DEBUG
  end


  # Encode a string, such that it is suitable for HTTP transmission.
  #
  def self.url_encode(string)

    # Shamelessly plagiarised from Wakou Aoyama's cgi.rb, but then altered
    # slightly to please AWS.
    #
    string.gsub( /([^a-zA-Z0-9_.~-]+)/ ) do
      '%' + $1.unpack( 'H2' * $1.bytesize ).join( '%' ).upcase
    end
  end


  # Convert a string from CamelCase to ruby_case.
  #
  def self.uncamelise(string)
    # Avoid modifying by reference.
    #
    string = string.dup

    # Don't mess with string if all caps.
    #
    if string =~ /[a-z]/
      string.gsub!( /(.+?)(([A-Z][a-z]|[A-Z]+$))/, "\\1_\\2" )
    end

    # Convert to lower case.
    #
    string.downcase
  end


  # A Class for dealing with configuration files, such as
  # <tt>/etc/amazonrc</tt> and <tt>~/.amazonrc</tt>.
  #
  class Config < Hash

    require 'stringio'

    # Exception class for configuration file errors.
    #
    class ConfigError < AmazonError; end

    # A configuration may be passed in as a string. Otherwise, the files
    # <tt>/etc/amazonrc</tt> and <tt>~/.amazonrc</tt> are read if they exist
    # and are readable.
    #
    def initialize(config_str=nil)
      locale = nil

      if config_str

	# We have been passed a config file as a string.
	#
        config_files = [ config_str ]
	config_class = StringIO

      else

	# Perform the usual search for the system and user config files.
	#
	config_files = [ File.join( '', 'etc', 'amazonrc' ) ]

	# Figure out where home is. The locations after HOME are for Windows.
	# [ruby-core:12347]
	#
	home = ENV['AMAZONRCDIR'] ||
	       ENV['HOME'] || ENV['HOMEDRIVE'] + ENV['HOMEPATH'] ||
	       ENV['USERPROFILE']
	user_rcfile = ENV['AMAZONRCFILE'] || '.amazonrc'

	if home
	  config_files << File.expand_path( File.join( home, user_rcfile ) )
	end

	config_class = File
      end

      config_files.each do |cf|

	if config_class == StringIO
	  readable = true
	else
	  # We must determine whether the file is readable.
	  #
	  readable = File.exists?( cf ) && File.readable?( cf )
	end

	if readable

	  Amazon.dprintf( 'Opening %s ...', cf ) if config_class == File

	  config_class.open( cf ) { |f| lines = f.readlines }.each do |line|
	    line.chomp!

	    # Skip comments and blank lines.
	    #
	    next if line =~ /^(#|$)/

	    Amazon.dprintf( 'Read: %s', line )

	    # Determine whether we're entering the subsection of a new locale.
	    #
	    if match = line.match( /^\[(\w+)\]$/ )
	      locale = match[1]
	      Amazon.dprintf( "Config locale is now '%s'.", locale )
	      next
	    end

	    # Store these, because we'll probably find a use for these later.
	    #
	    begin
      	      match = line.match( /^\s*(\S+)\s*=\s*(['"]?)([^'"]+)(['"]?)/ )
	      key, begin_quote, val, end_quote = match[1, 4]
	      raise ConfigError if begin_quote != end_quote

	    rescue NoMethodError, ConfigError
	      raise ConfigError, "bad config line: #{line}"
	    end

	    if locale && locale != 'global'
	      self[locale] ||= {}
	      self[locale][key] = val
	    else
	      self[key] = val
	    end

	  end
	end

      end

    end
  end
  
end
