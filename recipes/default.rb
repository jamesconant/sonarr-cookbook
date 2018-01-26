package %w(dirmngr apt-transport-https)

user node['sonarr']['user'] do
  system true
  manage_home true
  home node['sonarr']['home']
  shell '/usr/sbin/nologin'
end

apt_repository 'sonarr' do
  uri node['sonarr']['apt']['uri']
  distribution 'master'
  components %w(main)
  keyserver 'keyserver.ubuntu.com'
  key 'FDA5DFFC'
end

apt_update

package 'nzbdrone' do
  action :upgrade
end

systemd_unit 'sonarr.service' do
  content(Unit: {
            Description: 'Sonarr Daemon',
            After: 'syslog.target network.target',
          },
          Service: {
            User: node['sonarr']['user'],
            Group: node['sonarr']['user'],
            Type: 'simple',
            ExecStart: '/usr/bin/mono /opt/NzbDrone/NzbDrone.exe -nobrowser',
            TimeoutStopSec: '20',
            KillMode: 'process',
            Restart: 'on-failure',
          },
          Install: {
            WantedBy: 'multi-user.target',
          })

  only_if 'which systemctl'
  action :create
end

template '/etc/init/sonarr.conf' do
  source 'init.conf.erb'
  variables user: node['sonarr']['user']
  not_if 'which systemctl'
end

directory ::File.join(node['sonarr']['home'], '.config/NzbDrone') do
  user node['sonarr']['user']
  group node['sonarr']['user']
  recursive true
end

template ::File.join(node['sonarr']['home'], '.config/NzbDrone/config.xml') do
  source 'config.xml.erb'
  user node['sonarr']['user']
  group node['sonarr']['user']
  mode 0600
  variables(settings: node['sonarr']['settings'])
end

service 'sonarr' do
  action [:enable, :start]
end
