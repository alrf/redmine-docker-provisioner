# -*- mode: ruby -*-

Vagrant.configure("2") do |config|

  config.vm.box = "bento/ubuntu-16.04"
  config.vm.synced_folder ".", "/redmine", create: true
  config.vm.network "forwarded_port", guest: 3000, host: 3000

  config.vm.provision "docker" do |d|
    d.build_image "/redmine/docker/mysql"
    d.run "mysql:latest",
      args: "--name my-mysql -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=redmine -e MYSQL_USER=redmine -e MYSQL_PASSWORD=redmine"
  end

  config.vm.provision "docker", run: "always" do |d|
    d.build_image "--tag=redmine /redmine/docker/rails"
    d.run "redmine",
      args: "-p 3000:3000 --link my-mysql:mysql -v '/redmine:/home/redmine/src'"
  end

end
