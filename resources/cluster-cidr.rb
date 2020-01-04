#!/usr/bin/env ruby

file = ARGV.first
if file.nil?
  $stderr.puts "+ kubectl cluster-info dump"
  contents = `kubectl cluster-info dump --output yaml`
elsif file == "-"
  contents = STDIN.read
else
  contents = open(file).read
end
puts contents.scan(/cluster-cidr=([\w\d.]*)/).flatten.first
