#!/usr/bin/ruby

require "open3"
require "getoptlong"

opts = GetoptLong.new(
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '--config', '-c', GetoptLong::OPTIONAL_ARGUMENT ]
)

opts.each do |opt, arg|
  case opt
    when '--help'
      puts <<-EOF
snapraid_run [OPTIONS]

-h, --help:
   show help

-c, --config /etc/snapraid.conf:
   Optional, default is to look for /etc/snapraid.conf
      EOF
	exit 1
    when '--config'
      if arg == ''
        configFile = "/etc/snapraid.conf"
      else
        name = arg
      end
  end
end

logFile = "/var/snapraid.log"
snapraid_bin = `which snapraid`

delThreshold = 500

config = Hash.new
# Read our variables from the config file
File.readlines('/etc/snapraid.conf').any? {|l| l.match /^content (.*)?$/} 
config["parity"] = $1
File.readlines('/etc/snapraid.conf').any? {|l| l.match /^parity (.*)?$/} 
config["content"] = $1

puts "Parity Config: #{config["parity"]}"
puts "Content Config: #{config["content"]}"

#stdin, stdout, stderr = Open3.popen3('snapraid -V')

#puts "stderr: " + stderr.read if stderr.read.length > 0
#puts "stdout: " + stdout.read

#stdout[/^\w+ (\w+ \d+) .+ (\d+)$/]
#puts "Today is: " + [$1, $2].join(' ')

#cmd = "ping google.com"
# cmd = "cat snapraid.diff"

stats = Array.new

@differences = false
cmd = "snapraid --force-empty diff 2>&1"

Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
  # stderr.each do |line|
  #   puts "#{line}"
  # end
	stdout.each do |line|
		if match = line.match(/^\s+(\d+) equal/)
			@equal = match.captures.first.to_i
    elsif match = line.match(/^\s+(\d+) moved/)
      @removed = match.captures.first.to_i
    elsif match = line.match(/^\s+(\d+) copied/)
      @copied = match.captures.first.to_i
    elsif match = line.match(/^\s+(\d+) restored/)
      @restored = match.captures.first.to_i
    elsif match = line.match(/^\s+(\d+) removed/)
      @removed = match.captures.first.to_i
  	elsif match = line.match(/^\s+(\d+) added/)
      @added = match.captures.first.to_i
    elsif match = line.match(/^There are differences/)
      @differences = true
    end
	end
  puts "====---------------------------------------===="
	puts "Summary - Equal: #{@equal}, Removed: #{@removed}, Added: #{@added}"
  puts "Differences: #{@differences}"
end

if @removed > delThreshold
	puts "#{@removed} is greater than #{delThreshold}"
elsif 
	puts "#{@removed} is less than #{delThreshold}"
end

if @differences 
  puts "Differences found. Syncing issued. snapraid is at: #{snapraid_bin}"
  cmd = "snapraid --force-empty sync -l snapraid.out 2>&1"
  Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
    stdout.each do |line|
      puts line
    end
  end  
end

#echo "SUMMARY of changes - Added [$ADD_COUNT] - Deleted [$DEL_COUNT] - Moved [$MOVE_COUNT] - Copied [$COPY_COUNT] - Updated [$UPDATE_COUNT]" >$

#  227246 equal
 #     45 moved
  #     0 copied
   #    0 restored
    #   0 updated
   #   14 removed
   #  292 added
#There are differences!
