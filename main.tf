provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = var.data_center
}
data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_datastore" "datastore" {
  name          = var.workload_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = var.compute_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_host" "host" {
  name          = "10.10.10.68"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = "sddc-cgw-network-1"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_tag_category" "environment" {
  name        = "environment"
  cardinality = "SINGLE"

  associable_types = [
    "VirtualMachine"
  ]
}

resource "vsphere_tag_category" "region" {
  name        = "region"
  cardinality = "SINGLE"

  associable_types = [
    "VirtualMachine"
  ]
}

resource "vsphere_tag" "environment" {
  name        = "test-dev"
  category_id = vsphere_tag_category.environment.id
}

resource "vsphere_tag" "region" {
  name        = "UK"
  category_id = vsphere_tag_category.region.id
}


resource "vsphere_virtual_machine" "Red" {
  name                       = "Nico-VM"
  resource_pool_id           = data.vsphere_resource_pool.pool.id
  datastore_id               = data.vsphere_datastore.datastore.id
  datacenter_id              = data.vsphere_datacenter.dc.id
  host_system_id             = data.vsphere_host.host.id
  folder                     = "Workloads"
  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout  = 0

  ovf_deploy {
    remote_ovf_url    = "https://xxxxxx.s3-us-west-2.amazonaws.com/yyyy.ova"
    disk_provisioning = "thin"
    ovf_network_map = {
      "sddc-cgw-network-1" = data.vsphere_network.network.id
    }
  }

}


resource "vsphere_virtual_machine" "vmFromRemoteOvf" {
  name             = "vm-deployed-from-ova"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  datacenter_id    = data.vsphere_datacenter.dc.id
  host_system_id   = data.vsphere_host.host.id
  tags = [
    vsphere_tag.environment.id,
    vsphere_tag.region.id,
  ]
  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout  = 0

  ovf_deploy {
    // Url to remote ovf/ova file
    remote_ovf_url    = "https://download3.vmware.com/software/vmw-tools/nested-esxi/Nested_ESXi7.0_Appliance_Templat
e_v1.ova"
    disk_provisioning = "thin"
    ovf_network_map = {
      "VM Network" = data.vsphere_network.network.id
    }
  }

  vapp {
    properties = {
      "guestinfo.hostname"  = "tf-nested-esxi-1.primp-industries.com",
      "guestinfo.ipaddress" = "192.168.30.180",
      "guestinfo.netmask"   = "255.255.255.0",
      "guestinfo.gateway"   = "192.168.30.1",
      "guestinfo.dns"       = "192.168.30.1",
      "guestinfo.domain"    = "primp-industries.com",
      "guestinfo.ntp"       = "pool.ntp.org",
      "guestinfo.password"  = "VMware1!23",
      "guestinfo.ssh"       = "True"
    }
  }
}
