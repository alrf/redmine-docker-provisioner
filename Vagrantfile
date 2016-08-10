# -*- mode: ruby -*-
# vi: set ft=ruby :
# Avoid having to pass --provider=docker

#ENV['VAGRANT_DEFAULT_PROVIDER'] = 'docker'
VAGRANT_ROOT = File.dirname(__FILE__)

Vagrant.configure("2") do |config|

  # for CentOS: https://github.com/docker/docker/issues/10450
  system("iptables -D FORWARD `iptables -nL FORWARD --line | grep REJECT | cut -d' ' -f1 | xargs` 2> /dev/null")


  config.vm.provision "docker" do |d|
    d.build_image "docker/mysql"
    d.run "docker/mysql",
      args: "-e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=redmine -e MYSQL_USER=redmine -e MYSQL_PASSWORD=redmine"
  end



#  config.vm.define "mysql" do |mysql|
#    mysql.vm.provision "docker" do |d|
#      d.build_image "docker/mysql"
#      d.run "docker/mysql",
#        args: "-e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=redmine -e MYSQL_USER=redmine -e MYSQL_PASSWORD=redmine"
#    end
#  end

#  config.vm.define "rails" do |rails|
#    rails.vm.synced_folder ".", "/home/redmine/src"
#    rails.vm.provider "docker" do |d|
#      d.build_dir = "docker/rails"
#      d.name = "redmine"
#      d.remains_running = true
#      d.ports = ["3000:3000"]
#      d.volumes = ["#{VAGRANT_ROOT}:/home/redmine/src"]
#      d.create_args = ["--link", "my-mysql:mysql"]
#    end
#  end

end
