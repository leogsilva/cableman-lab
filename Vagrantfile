require 'ipaddr'

# to make sure the nodes are created in order, we
# have to force a --no-parallel execution.
ENV['VAGRANT_NO_PARALLEL'] = 'yes'

ubuntu_number_of_nodes      = 3
ubuntu_first_node_ip        = '192.168.53.101'
ubuntu_node_ip_address      = IPAddr.new ubuntu_first_node_ip
ubuntu_first_node_vpn_ip    = '10.2.0.101'
ubuntu_node_vpn_ip_address  = IPAddr.new ubuntu_first_node_vpn_ip

Vagrant.configure(2) do |config|
  config.vm.box = 'peru/ubuntu-20.04-server-amd64'

  config.vm.provider 'libvirt' do |lv, config|
    lv.cpus = 2
    lv.cpu_mode = 'host-passthrough'
    lv.nested = true
    lv.keymap = 'pt'
    config.vm.synced_folder '.', '/vagrant', type: 'nfs'
  end

  config.vm.provider 'virtualbox' do |vb|
    vb.linked_clone = true
    vb.cpus = 2
  end

  (1..ubuntu_number_of_nodes).each do |n|
    name = "u#{n}"
    fqdn = "#{name}.example.test"
    ip_address = ubuntu_node_ip_address.to_s; ubuntu_node_ip_address = ubuntu_node_ip_address.succ
    vpn_ip_address = ubuntu_node_vpn_ip_address.to_s; ubuntu_node_vpn_ip_address = ubuntu_node_vpn_ip_address.succ

    config.vm.define name do |config|
      config.vm.provider 'libvirt' do |lv, config|
        lv.memory = 2048
      end
      config.vm.provider 'virtualbox' do |vb|
        vb.memory = 512
      end
      config.vm.hostname = fqdn
      config.vm.network :private_network, ip: ip_address, libvirt__forward_mode: 'none', libvirt__dhcp_enabled: false
      config.vm.provision 'shell', path: 'provision-base.sh'
	  config.vm.provision "file", source: "./bin/subctl-syntropy", destination: "$HOME/"
	  config.vm.provision "file", source: "./bin/helm", destination: "$HOME/"
	  config.vm.provision "file", source: "./syntropy-agent/#{name}-values.yaml", destination: "$HOME/values.yaml"
	  config.vm.provision 'shell', path: 'provision-tools.sh'
	  config.vm.provision 'shell', path: "provision-k8s-#{name}.sh", args: [ip_address]
      # update all the machines wireguard configuration with all the other peers.
      config.trigger.after :up do |trigger|
        trigger.ruby do |env, machine|
          # see https://github.com/hashicorp/vagrant/blob/v2.2.7/lib/vagrant/plugin/v2/trigger.rb
          # see https://github.com/hashicorp/vagrant/blob/v2.2.7/lib/vagrant/environment.rb
          # see https://github.com/hashicorp/vagrant/blob/v2.2.7/lib/vagrant/machine.rb
          # see https://github.com/hashicorp/vagrant/blob/v2.2.7/lib/vagrant/machine_state.rb
          # see https://github.com/hashicorp/vagrant/blob/v2.2.7/lib/vagrant/plugin/v2/communicator.rb
          env.active_machines.each do |machine_name, machine_provider|
            m = env.machine(machine_name, machine_provider)
            if m.state.id == :running
              m.ui.info('Updating WireGuard peers...')
            end
          end
        end
      end
    end
  end
end
