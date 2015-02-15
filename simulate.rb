#!/usr/bin/env ruby

require "./metro.rb"

Thread.abort_on_exception= true   # to avoid hiding errors in threads

# read command line and decide on display(), verify() or simulate()

$sim_file_headers= ["=== Lines ===", "=== Trains ===", "=== Passengers ===",
                    "=== Output ===", "=== Passenger Limit ===" ]

def read_params(fname, lines, num_trains, passengers, sim_out, limit)
  begin
    f= File.open(fname)
  rescue Exception => e
    puts(e)
    exit(-1)
  end

  header_lines= $sim_file_headers[0]
  header_trains= $sim_file_headers[1]
  header_passenger= $sim_file_headers[2]
  header_output= $sim_file_headers[3]
  header_passenger_limit= $sim_file_headers[4]

  section= nil
  line_number= 1
  f.each_line() { |line|

    line.chomp!().strip!()

    # skip blank lines and lines beginning with %
    if (line != "" && line !~ /^%/) then

      if (line == header_lines || line == header_trains ||
          line == header_passenger || line == header_output ||
          line == header_passenger_limit)
        section= line
      elsif (section == header_lines)
        parts= line.split(',')
        color= parts.shift().strip()
        stations= []
        parts.each() { |s| stations.push(s.strip!()) }
        lines[color]= stations
      elsif (section == header_trains)
        parts= line.split('=')
        color= parts.shift().strip()
        num_trains[color]= parts[0].to_i()
      elsif (section == header_passenger_limit)
        parts= line.split('=')
        limit << parts[1].to_i()
      elsif (section == header_passenger)
        parts= line.split(',')
        name= parts.shift().strip()
        stations= []
        parts.each() { |s| stations.push(s.strip!()) }
        passengers[name]= stations
      elsif (section == header_output)
        sim_out.push(line)
      else
        puts("Error: simulate file format error in line #{line_number}:\n" +
             "'#{line}'")
        exit(-1)
      end

      line_number += 1

    end  # if (line != "" && line =~ /^%/)
  }
end

def print_params(lines, num_trains, passengers, limit)
  header_lines= $sim_file_headers[0]
  header_trains= $sim_file_headers[1]
  header_passenger= $sim_file_headers[2]
  header_output= $sim_file_headers[3]
  header_passenger_limit= $sim_file_headers[4]

  puts(header_lines)
  lines.each() { |name,stations|
    s= ""
    s << name
    stations.each() { |st| s << ", " << st }
    puts(s)
  }

  puts(header_trains)
  num_trains.each() { |name,num| puts("#{name}=#{num}") }

  puts(header_passenger_limit)
  puts("limit=#{limit}")
  puts(header_passenger)
  passengers.each() { |name,stations|
    s= ""
    s << name
    stations.each() { |st| s << ", " << st }
    puts(s)
  }

  puts(header_output)
end

def run()
  if (ARGV.length() != 2)
    ARGV.each() { |x| puts(x)}
    puts("Usage: #{$0} (simulate|verify|display) simulate-filename")
    exit(-1)
  end

  # list command line parameters
  cmd= "% #{$0} "
  ARGV.each() { |a| cmd << a << " " }
  puts(cmd)

  lines= {}
  num_trains= {}
  passengers= {}
  sim_out= []
  limit= []
  read_params(ARGV[1],lines, num_trains, passengers, sim_out, limit)
  limit= limit.pop()

  if (ARGV[0] == "verify")

    result= verify(lines, num_trains, passengers, sim_out, limit)
    if (result)
      puts("VALID.")
    else
      puts("INVALID.")
      exit(1)
    end

  elsif (ARGV[0] == "simulate")

    print_params(lines, num_trains, passengers, limit)
    sim_monitor= {}
    lines.each_key() { |k| sim_monitor[k]= Monitor.new() }
    simulate(lines, num_trains, passengers, sim_monitor, limit)

  elsif (ARGV[0] == "display")

    display(lines, passengers, sim_out)

  else

    puts("Usage: #{$0} (simulate|verify|display) simulate-filename")
    exit(-1)

  end

  exit(0)
end

run()
