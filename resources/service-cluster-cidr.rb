#!/usr/bin/env ruby

require 'json'
$stderr.puts "+ kubectl get services -n kube-system -ojson"
svc = JSON.parse(`kubectl get services -n kube-system -ojson`)
clusterIPService = svc["items"].find {|i| i["spec"]["type"] == "ClusterIP"}
ip = clusterIPService["spec"]["clusterIP"]

puts "#{ip[/^(\d+)\.(\d+)/]}.0.0"
