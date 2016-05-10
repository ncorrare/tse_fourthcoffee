# Copyright
# ---------
#
# Copyright 2015 PuppetLabs, unless otherwise noted.
#
class tse_fourthcoffee (
 $websitename        = 'FourthCoffee',
  $zipname            = 'FourthCoffeeWebSiteContent.zip',
  $sourcerepo         = 'https://github.com/msutter/fourthcoffee/raw/master',
  $destinationpath    = 'C:\inetpub\FourthCoffee',
  $defaultwebsitepath = 'C:\inetpub\wwwroot',
  $zippath            = 'C:\tmp'
) {
  $zipuri  = "${sourcerepo}/${zipname}"
  $zipfile = "${zippath}\\${zipname}"

  reboot { 'afterpowershell':
    when    => pending,
    timeout => 15,
  }
  service { 'wuauserv':
    ensure => 'running',
    enable => 'true',
  } ->

  package { 'powershell':
    ensure   => latest,
    provider => 'chocolatey',
    install_options => ['-pre'],
    notify => Reboot['afterpowershell'],
  } ->

  dsc::lcm_config {'disable_lcm':
    refresh_mode => 'Disabled',
    require      => Package['powershell'],
  } ->

  # Install the IIS role
  dsc_windowsfeature {'IIS':
    dsc_ensure => 'present',
    dsc_name   => 'Web-Server',
  } ->

  # Install the ASP .NET 4.5 role
  dsc_windowsfeature {'AspNet45':
    dsc_ensure => 'present',
    dsc_name   => 'Web-Asp-Net45',
  } ->

  # Stop an existing website (set up in Sample_xWebsite_Default)
  dsc_xwebsite {'Stop DefaultSite':
    dsc_ensure       => 'present',
    dsc_name         => 'Default Web Site',
    dsc_state        => 'Stopped',
    dsc_physicalpath => $defaultwebsitepath,
  } ->

  # Create tmp folder
  dsc_file {'tmp folder':
    dsc_ensure          => 'present',
    dsc_type            => 'Directory',
    dsc_destinationpath => $zippath,
  } ->

  # Download the site content
  dsc_xremotefile {'Download WebContent Zip':
    dsc_destinationpath => $zipfile,
    dsc_uri             => $zipuri,
  } ->

  # Extract the website content 
  dsc_archive {'Unzip and Copy the WebContent':
    dsc_ensure      => 'present',
    dsc_path        => $zipfile,
    dsc_destination => $destinationpath,
  } ->

  # Create a new Website
  dsc_xwebsite {'BackeryWebSite':
    dsc_ensure       => 'present',
    dsc_name         => $websitename,
    dsc_state        => 'Started',
    dsc_physicalpath => $destinationpath,
  }
  dsc_xfirewall { 'Allow RDP':
    dsc_name      => "$name Allow RDP",
    dsc_ensure    => 'present',
    dsc_direction => 'Inbound',
    dsc_localport => '3389',
    dsc_protocol  => 'TCP',
    dsc_action    => 'Allow',
    require       => Dsc::Lcm_config['disable_lcm'],
  }

  dsc_xfirewall { 'Allow WinRM':
    dsc_name      => "$name Allow WinRM",
    dsc_ensure    => 'present',
    dsc_direction => 'Inbound',
    dsc_localport => '5985',
    dsc_protocol  => 'TCP',
    dsc_action    => 'Allow',
    require       => Dsc::Lcm_config['disable_lcm'],
  }

  dsc_xfirewall { 'Allow HTTP':
    dsc_name      => "$name Allow HTTP",
    dsc_ensure    => 'present',
    dsc_direction => 'Inbound',
    dsc_localport => '80',
    dsc_protocol  => 'TCP',
    dsc_action    => 'Allow',
    require       => Dsc::Lcm_config['disable_lcm'],
  }
}
