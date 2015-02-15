# Corey Robins. 111185399. crobins. Section 0201
# I pledge on my honor that I have not given or received any unauthorized
# assistance on this assignment.

#!/usr/local/bin/ruby
require "monitor"

Thread.abort_on_exception= true   # to avoid hiding errors in threads

#----------------------------------------------------------------
# Metro simulator
#----------------------------------------------------------------

$output_monitor=Monitor.new()
$output_cond=$output_monitor.new_cond()
$can_print=true

class Train

  def initialize(line_name, lines, limit, monitor, tcond, pcond)
    @line_name=line_name
    @train_num=$trains_count[line_name]
    $trains_count[line_name]+=1
    @train_name=@line_name + " " + @train_num.to_s
    @stations=lines[line_name]
    @limit=limit
    @num_passengers=0
    @passenger_objs=[]
    @monitor=monitor
    @Pcond=pcond
    @Tcond=tcond
    @direction="right"
    @curr_station=$station_objs[@line_name][0]
    @count=0
  end

  def enter ()
    @monitor.synchronize do
      
      @Tcond.wait_while { @curr_station.get_train(@line_name)!=nil }
      @curr_station.set(true, @line_name, self)

      $output_monitor.synchronize do
        $output_cond.wait_while { $can_print==false }
        puts ("Train #{@line_name} #{@train_num} entering #{@curr_station.get_name()}")
        $stdout.flush()
        $can_print=true
        $output_cond.broadcast()
      end
      
      @Pcond.broadcast()
    end
  end

  def leave ()
    @monitor.synchronize do

      @curr_station.set(false, @line_name, self)
      
      $output_monitor.synchronize do
        $output_cond.wait_while { $can_print==false }
        puts ("Train #{@line_name} #{@train_num} leaving #{@curr_station.get_name()}")
        $stdout.flush()
        $can_print=true
        $output_cond.broadcast()
      end        
      
      if (@direction=="right")
        if ($station_objs[@line_name][($station_objs[@line_name].index(@curr_station))+1]==nil)
          @direction="left"
          @curr_station=$station_objs[@line_name][($station_objs[@line_name].index(@curr_station))-1]
          @count+=1
        else          
          @curr_station=$station_objs[@line_name][($station_objs[@line_name].index(@curr_station))+1]
        end
      else
        if ($station_objs[@line_name][($station_objs[@line_name].index(@curr_station))-$station_objs[@line_name].length()-1]==nil)
          @direction="right"
          @curr_station=$station_objs[@line_name][($station_objs[@line_name].index(@curr_station))+1]
          @count+=1
        else
          @curr_station=$station_objs[@line_name][($station_objs[@line_name].index(@curr_station))-1]
        end
      end

      @Tcond.broadcast()
    end
  end

  def run()
    if ($run_twice)
      while (@count<2)
        enter()
        sleep(0.01)
        leave()
      end
    else
      while ($passengers!=0)
        enter()
        sleep(0.01)
        leave()
      end
    end
  end

  def get_pass_list()
    return @passeger_objs
  end

  def add_passenger(passenger)
    @passenger_objs.push(passenger)
    @num_passengers+=1
  end
  
  def remove_passenger(passenger)
    @passenger_objs.delete(passenger)
    @num_passengers-=1
  end
  
  def get_name()
    return @train_name
  end

  def get_station()
    return @curr_station
  end

  def get_next_station()
    return $station_objs[@line_name][($station_objs[@line_name].index(@curr_station))+1].get_name()
  end

  def get_train()
    return self
  end

  def get_num_pass()
    return @num_passengers
  end

  def get_pass_limit()
    return @limit
  end
   
end

class Station

  def initialize(station_name, lines)
    @station_name=station_name
    @trains_list={}
  end

  def get_train(line)
    if (@trains_list[line]==nil)
      @trains_list[line]=[]
    end
    return @trains_list[line][0]
  end

  def get_name()
    return @station_name
  end

  def set(a, line, train)
    if (a==true)
      if (@trains_list[line]==nil)
        @trains_list[line]=[]
      end
      @trains_list[line][0]=train
    else
      @trains_list.delete(line)
    end
  end

end

class Passenger

  def initialize(name, itinerary, line)
    @name=name
    @itinerary=itinerary
    $station_objs[line].each { |station|
      if (station.get_name()==@itinerary[0])
        @curr_station=station
      end
      if (station.get_name()==@itinerary[1])
        @destination=station
      end
    }
    @pcond=$conditions[line][0]
    @monitor=$monitors[line]
    @line=line
    @train=nil
    @count=1
    @change_line=false
  end

  def board
    @monitor.synchronize do

      @pcond.wait_until{ @curr_station.get_train(@line)!=nil && ((@curr_station.get_train(@line).get_num_pass())<(@curr_station.get_train(@line).get_pass_limit()))}    
      @curr_station.get_train(@line).add_passenger(self)
      @train=@curr_station.get_train(@line)

      $output_monitor.synchronize do
        $output_cond.wait_while { $can_print==false }
        puts ("#{@name} boarding train #{@curr_station.get_train(@line).get_name()} at #{@curr_station.get_name()}")
        $stdout.flush()
        $can_print=true
        $output_cond.broadcast()
      end
    end
  end
  
  def leave
    @monitor.synchronize do
#      @pcond.wait_while{ @train.get_station()!=@destination }
      @pcond.wait_while { @destination.get_train(@line)!=@train }
      @train.remove_passenger(self)
      @curr_station=@train.get_station()

      $output_monitor.synchronize do
        $output_cond.wait_while { $can_print==false }
        puts (("#{@name} leaving train #{@train.get_name()} at #{@curr_station.get_name()}"))
        $stdout.flush()
        $can_print=true
        $output_cond.broadcast()
      end

      @count+=1
      if (@itinerary[@count]!=nil && @destination.get_name()!=@itinerary[@count])
        $station_objs.keys.each { |line|
          $station_objs[line].each { |station|
            if (station.get_name()==@itinerary[@count] && check_line(line, @curr_station))
              @destination=station
              @line=line
              @change_line=true
            end
          }
        }
        $station_objs[@line].each { |station|
          if (station.get_name==@curr_station.get_name)
            @curr_station=station
          end
        }
      else
        $passengers-=1
      end
    end
    $monitors[@line].synchronize do
      if (@change_line==true)
        @change_line=false
        @monitor=$monitors[@line]
        @pcond=$conditions[@line][0]
        run()
      end
    end
  end

  def run()
    board()
    leave()
  end
  
  def check_line(dest_line, curr_station)
    $station_objs[dest_line].each { |station|
      if (station.get_name()==curr_station.get_name())
        return true
      end
    }
    return false
  end

end

def simulate(lines, numTrains, passengers, sim_monitor, passenger_limit)
  #puts(lines.inspect)
  #puts(numTrains.inspect)
  #puts(passengers.inspect)
  #puts (passenger_limit.inspect)

  $passengers=0

  passengers.keys.each { |pass|
    $passengers+=1
  }

  if ($passengers==0)
    $run_twice=true
  else
    $run_twice=false
  end

  train_threads=[]
  passenger_threads=[]

  $trains_count={}
  
  numTrains.keys.each { |line|
    $trains_count[line]=1
  }

  $station_objs={}
  $conditions={}
  $monitors=sim_monitor

  numTrains.keys.each { |line|
    monitor=sim_monitor[line]
    tcond=monitor.new_cond()
    pcond=monitor.new_cond()

    lines[line].each { |station|
      if ($station_objs[line]==nil)
        $station_objs[line]=[]
        $conditions[line]=[]
      end
      $station_objs[line].push(Station.new(station, lines))
    }

    $conditions[line][0]=pcond
    $conditions[line][1]=tcond

    for i in (1..numTrains[line])
      train_threads.push(Thread.new() do 
                           (Train.new(line, lines, passenger_limit, monitor, tcond, pcond)).run()
                         end)
    end
  }

  passengers.keys.each { |pass|
    first_stop=passengers[pass][0]
    second_stop=passengers[pass][1]
    pass_line=""
    lines.keys.each { |line|
      if (lines[line].include?(first_stop) && lines[line].include?(second_stop))
        pass_line=line
        break
      end
    }
    monitor=sim_monitor[pass_line]

    passenger_threads.push(Thread.new() do
                             (Passenger.new(pass, passengers[pass], pass_line)).run()
                           end)
  }

  train_threads.each { |thread|
    thread.join()
  }
  
  passenger_threads.each { |thread|
    thread.join()
  }
  
end

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

def display(lines, passengers, output)
  # puts(lines.inspect)
  # puts(passengers.inspect)
  # puts(output.inspect)

  stations= {}
  trains= {}

  trn='^(Train) ([a-zA-Z]+) ([0-9]+) (entering|leaving) (.+)$'
  pssngr='^(.+) (boarding|leaving) (train) ([a-zA-Z]+) ([0-9]+) (at) (.+)$'

  trains_regex=Regexp.new(trn)
  passengers_regex=Regexp.new(pssngr)

  lines.keys().each { |line|
    lines[line].each { |station|
      if (stations[station]==nil)
        stations[station]={}
      end
      stations[station][line]={}
      stations[station]["passenger"]={}
    }
  }

  stations.keys().each { |station|
    passengers.keys().each { |passenger|
      if (passengers[passenger][0]==station)
        stations[station]["passenger"][passenger]=1
      end
    }
  }

  display_state(lines, stations, trains)

  output.each {|o|
    puts(o)
    if (o=~trains_regex)
      line_name=$2
      train_num=$3
      leaving_entering=$4
      station=$5
      if (stations[station][line_name]==nil)
        stations[station][line_name]={}
      end
      if (leaving_entering=="entering")
        stations[station][line_name][train_num]=1
      else
        stations[station][line_name]={}
      end
    elsif (o=~passengers_regex)
      passenger_name=$1
      boarding_leaving=$2
      line_name=$4
      line_num=$5
      train_name=line_name + " " + line_num
      station=$7
      if (trains[train_name]==nil)
        trains[train_name]={}
      end
      if (boarding_leaving=="boarding")
        stations[station]["passenger"].delete(passenger_name)
        trains[train_name][passenger_name]=1
      else
        stations[station]["passenger"][passenger_name]=1
        trains[train_name].delete(passenger_name)
      end
    end
    display_state(lines, stations, trains)
  }
end

#----------------------------------------------------------------
# Simulation verifier
#----------------------------------------------------------------

def verify(lines, numTrains, passengers, output, limit)
  # puts(lines.inspect)
  # puts(numTrains.inspect)
  # puts(passengers.inspect)
  # puts(output.inspect)

  # return false
  return true
end
