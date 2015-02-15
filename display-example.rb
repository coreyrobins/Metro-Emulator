#!/usr/local/bin/ruby -w

# Simulation display

#----------------------------------------------------------------
# Simulation display
#----------------------------------------------------------------

# line= hash of line names to array of stops
# stations= hash of station names =>
#                  hashes for each line => hash of trains at station
#               OR hash for "passenger" => hash of passengers at station
# trains= hash of train names => hash of passengers

def display_state(lines, stations, trains)
  lines.keys().sort().each() { |color|
    stops= lines[color]
    puts(color)
    stops.each() { |stop|
      p_str= ""
      t_str= ""

      stations[stop]["passenger"].keys().sort().each() { |passenger|
        p_str << passenger << " "
      }

      stations[stop][color].keys().sort().each() { |train_num|
        tr= color + " " + train_num
        t_str << "[" << tr
        if (trains[tr] != nil)
          trains[tr].keys().sort().each() { |p|
            t_str << " " << p
          }
        end
        t_str << "]"
      }

      printf("  %25s %10s %-10s\n", stop, p_str, t_str)
    }	
  }
  puts()
end

# example of how to use display_state
def display_example 
  lines= {}
  lines["Black"]= ["S1","S2"] 

  stations= {}
  stations["S1"]= {}
  stations["S2"]= {}
  stations["S1"]["Black"]= {} 
  stations["S2"]["Black"]= {} 
  stations["S1"]["passenger"]= {} 
  stations["S2"]["passenger"]= {} 
  stations["S1"]["passenger"]["Jack"]= 0
  stations["S2"]["passenger"]["John"]= 0

  trains= {}
  trains["Black 1"]= {}
  trains["Black 1"]["Jim"]= 0

  puts("Lines= " + lines.inspect())
  puts("Stations= " + stations.inspect())
  puts("Trains= " + trains.inspect())

  display_state(lines, stations, trains)

  stations["S2"]["Black"]["1"]= 0
  display_state(lines, stations, trains)

  trains["Black 1"].delete("Jim")
  stations["S2"]["passenger"]["Jim"]= 0
  display_state(lines, stations, trains)
end

display_example()

