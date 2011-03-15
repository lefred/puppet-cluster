# Class: cluster
#
# This module manages cluster
#
# Parameters:
#
# Sample Usage:
#
# [Remember: No empty lines between comments and class definition]
class cluster {
    $tmp_nic = "ipaddress_${cluster_bind_interface}"
    $bindnetaddr = inline_template("<%= scope.lookupvar(tmp_nic) %>")

    yumrepo {
        "clusterlabs":
            descr => "High Availability/Clustering server technologies (epel-5)",
            baseurl => "http://www.clusterlabs.org/rpm/epel-5",
            enabled => 1,
            gpgcheck => 0,
    }

    package { "corosync.$hardwaremodel":
        ensure => "installed",
        alias => "corosync",
        require => Yumrepo["clusterlabs"];
    }

    package { "pacemaker.$hardwaremodel":
        ensure => "installed",
        alias => "pacemaker",
        require => Package["corosync"];
    }

    file { "/etc/corosync/authkey":
        ensure  => present,
        mode    => 0400,
        owner   => "root",
        group   => "root",
        source  => "puppet:///cluster/authkey",
        require => Package["corosync"];
    }


    file { "/etc/corosync/corosync.conf":
        ensure  => present,
        content => template("cluster/corosync.conf.erb"),
        require => Package["corosync"],
        notify  => [ Service["corosync"], Exec["load_crm_config"] ];
    }

    service { "corosync":
        enable     => true,
        ensure     => "running",
        hasrestart => true,
        hasstatus  => true,
        require    => Package["corosync"];
    }

    file { "/etc/corosync/crm.conf":
        ensure  => present,
        source  => [
            "puppet:///cluster/${hostname}/crm.conf",
            "puppet:///cluster/default/crm.conf",
            ],
        require => [ Package["pacemaker"], Service["corosync"] ];
    }
 
    file { "/usr/lib/ocf/resource.d/inuits/":
        source => "puppet:///cluster/inuits/",
        owner => "root",
        group => "root",
        mode  => 755,
        ensure => directory,
        recurse => true,
    }


    exec { "load_crm_config":
        command => "crm configure load update /etc/corosync/crm.conf",
        refreshonly => true,
        subscribe   => File["/etc/corosync/crm.conf"],
        require => File["/etc/corosync/crm.conf"] ;
    }

}
