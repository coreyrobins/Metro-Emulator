#!/usr/local/bin/ruby -w

test_names= Array.new()
1.upto(12) { |num| test_names.push(sprintf("%02d", num)) }

# we use csh inside the call to system() to run the tests, because otherise
# system() uses sh to run commands, which causes the command to be echoed
# slightly differently (with a preceding "./")

puts("========================= display() tests =========================\n")
for n in test_names do
  cmd= "simulate.rb display public#{n}.input >! public#{n}-display.log"
  puts("Running \"#{cmd}\"")
  system("csh -c \"#{cmd}\"")
  system("diff public#{n}.output public#{n}-display.log > /dev/null")
  if ($? == 0) then
    puts("public#{n} (display) passed!")
  else
    puts("public#{n} (display) FAILED.")
  end
  puts("")
end

puts("\n========================= verify() tests =========================\n")
for n in test_names do
  cmd= "simulate.rb simulate public#{n}.input >! public#{n}-simulate.log"
  puts("Running \"#{cmd}\"")
  system("csh -c \"#{cmd}\"")
  system("./simulate.rb verify public#{n}-simulate.log")
  puts("")
end

