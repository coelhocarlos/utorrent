Alternatively, you can open up a terminal window and run the following command to download it from the command line.

64 bits

wget http://download.ap.bittorrent.com/track/beta/endpoint/utserver/os/linux-x64-ubuntu-13-04 -O utserver.tar.gz
32 bits

wget http://download.ap.bittorrent.com/track/beta/endpoint/utserver/os/linux-i386-ubuntu-13-04 -O utserver.tar.gz
Once downloaded, change working directory to the directory where uTorrent server file is downloaded. Then run the following command to extract the tar.gz file to /opt/ directory.

sudo tar xvf utserver.tar.gz -C /opt/
Next, install required dependencies by executing the following command.

sudo apt install libssl1.0.0 libssl-dev
Note that if you are using Ubuntu 19.04, you need to download the libssl1.0.0 deb package from Ubuntu 18.04 repository and install it, because libssl1.0.0 isn’t included in Ubuntu 19.04 software repository.

wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0.0_1.0.2n-1ubuntu5.3_amd64.deb

sudo apt install ./libssl1.0.0_1.0.2n-1ubuntu5.3_amd64.deb
After the dependencies are installed, create a symbolic link.

sudo ln -s /opt/utorrent-server-alpha-v3_3/utserver /usr/bin/utserver
Use the following command to start uTorrent server. By default, uTorrent server listens on 0.0.0.0:8080. If there’s another service also listens on port 8080, you should temporarily stop that service. uTorrent will also use port 10000 and 6881. The -daemon option will make uTorrent server run in the background.

utserver -settingspath /opt/utorrent-server-alpha-v3_3/ -daemon
You can now visit the uTorrent web UI in your browser by typing in the following text in the web browser address bar.

your-server-ip:8080/gui
If you are installing uTorrent on your local computer, then replace your-server-ip with localhost.

localhost:8080/gui
If there’s a firewall on your Ubuntu server, then you need to allow access to port 8080 and 6881. For example, if you are using UFW, then run the following two commands to open port 8080 and 6881.

sudo ufw allow 8080/tcp
sudo ufw allow 6881/tcp
Please note that /gui is needed in the URL, otherwise you will encounter invalid request error. When asked for username and password, enter admin in username field and leave password filed empty.

uTorrent-ubuntu-18.04

Once you are logged in, you should change the admin password by clicking the gear icon, then selecting Web UI on the left menu. You can change both the username and password, which is more secure than using admin as the username.

utorrent-ubuntu-19.04

If you have other service listening on port 8080, then in the Connectivity section, you can change the uTorrent listening port to other port like 8081.  After changing the port, you must restart uTorrent server with the following commands.

sudo pkill utserver

utserver -settingspath /opt/utorrent-server-alpha-v3_3/ &
You can set default download directory in the Directories tab.

utorrent-server-ubuntu-18.04

Auto Start uTorrent Server on Ubuntu
To enable auto start, we can create a systemd service with the following command. (Nano is a command line text editor.)

sudo nano /etc/systemd/system/utserver.service
Put the following text into the file. Note that since we are going to use systemd to start uTorrent, we don’t need the -daemon option in the start command.

[Unit]
Description=uTorrent Server
After=network.target

[Service]
Type=simple
User=utorrent
Group=utorrent
ExecStart=/usr/bin/utserver -settingspath /opt/utorrent-server-alpha-v3_3/
ExecStop=/usr/bin/pkill utserver
Restart=always
SyslogIdentifier=uTorrent Server

[Install]
WantedBy=multi-user.target
Press Ctrl+O, then press Enter to save the file. Press Ctrl+X to exit. Then reload systemd.

sudo systemctl daemon-reload
It’s not recommended to run uTorrent server as root, so we’ve specified in the service file that uTorrent server should run as the utorrent user and group, which have no root privileges. Create the utorrent system user and group with the following command.

sudo adduser --system utorrent

sudo addgroup --system utorrent
Add the utorrent user to the utorrent group.

sudo adduser utorrent utorrent
Next, Stop the current uTorrent server.

sudo pkill utserver
Use the systemd service to start uTorrent server.

sudo systemctl start utserver
Enable auto start at boot time.

sudo systemctl enable utserver
Now check utserver status.

systemctl status utserver
auto-start-utorrent-server-ubuntu-18.04

We can see that auto start is enabled and uTorrent server is running. When creating the utorrent user, a home directory was also created at /home/utorrent/. It’s recommended that you set this home directory as your torrent download directory because the utorrent user has write permission. We also need to make utorrent as the owner of the /opt/utorrent-server-alpha-v3_3/ directory by executing the following command.

sudo chown utorrent:utorrent /opt/utorrent-server-alpha-v3_3/ -R
Note: The remaining content is for people who has basic knowledge about web server and DNS records. If you don’t know what Apache/Nginx or DNS A record is, you don’t have to follow the instructions below.
Setting up Nginx Reverse Proxy
To access your uTorrent server from a remote connection using a domain name, you can set up Nginx reverse proxy.

Sub-directory Configuration
If your Ubuntu server already have a website served by Nginx, then you can configure the existing Nginx server block so that you can access uTorrent Web UI from a sub-directory of your domain name.

sudo nano /etc/nginx/conf.d/your-website.conf
In the server block,  paste the following directives. If you changed the port before, then you need to change it here too.

location /gui {
              proxy_pass http://localhost:8080;
              proxy_set_header Host $http_host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
        }
Save and close the file. Then test Nginx configuration.

sudo nginx -t
If the test is successful, reload Nginx.

sudo systemctl reload nginx
Now you can access uTorrent Web UI via

your-domain.com/gui
Sub-domain Configuration
If you don’t have an existing website on the Ubuntu server, then you have to create a new server block file. Install Nginx on Ubuntu 18.04 or Ubuntu 19.04.

sudo apt install nginx
Start Nginx web server.

sudo systemctl start nginx
Then create a new server block file in /etc/nginx/conf.d/ directory.

sudo nano /etc/nginx/conf.d/utserver-proxy.conf
Paste the following text into the file. Replace utorrent.your-domain.com with your preferred sub-domain and don’t forget to create A record for it.

server {
       listen 80;
       server_name utorrent.your-domain.com;
       error_log /var/log/nginx/uttorrent.error;

       location /gui {
              proxy_pass http://localhost:8080;
              proxy_set_header Host $http_host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
        }
}
Save and close the file. Then test Nginx configuration.

sudo nginx -t
If the test is successful, reload Nginx.

sudo systemctl reload nginx
Now you can access uTorrent Web UI via

utorrent.your-domain.com/gui
Setting up Apache Reverse Proxy
If you use Apache web server rather than Nginx, then follow the instructions below to set up reverse proxy.

Install Apache web server.

sudo apt install apache2
To use Apache as a reverse proxy, we need to enable the proxy modules and we will also enable the rewrite module.

sudo a2enmod proxy proxy_http rewrite
Then create a virtual host file for uTorrent.

sudo nano /etc/apache2/sites-available/utorrent.conf
Put the following configurations into the file. Replace utorrent.your-domain.com with your actual domain name and don’t forget to set an A record for it.

<VirtualHost *:80>
    ServerName utorrent.your-domain.com

    RewriteEngine on
    RewriteRule ^/gui(/?)(.*)$ /$2 [PT]

    ProxyPreserveHost on
    ProxyPass / http://127.0.0.1:8080/gui/
    ProxyPassReverse / http://127.0.0.1:8080/gui/
</VirtualHost>
Save and close the file. Then enable this virtual host.

sudo a2ensite utorrent.conf
Restart Apache for the changes to take effect.

sudo systemctl restart apache2
Now you can remotely access uTorrent server by entering the subdomain (utorrent.your-domain.com ) in browser address bar. If uTorrent Web UI doesn’t load, then you may need to delete the default virtual host file and restart Apache web server.

Enabling HTTPS
To encrypt the HTTP traffic, we can enable HTTPS by installing a free TLS certificate issued from Let’s Encrypt. Run the following command to install Let’s Encrypt client (certbot) on Ubuntu 18.04 or Ubuntu 19.04 server.

sudo apt install certbot
If you use Nginx, then you also need to install the Certbot Nginx plugin.

sudo apt install python3-certbot-nginx
Next, run the following command to obtain and install TLS certificate.

sudo certbot --nginx --agree-tos --redirect --hsts --staple-ocsp --email you@example.com -d utorrent.your-domain.com
If you use Apache, install the Certbot Apache plugin.

sudo apt install python3-certbot-apache
And run this command to obtain and install TLS certificate.

sudo certbot --apache --agree-tos --redirect --hsts --staple-ocsp --email you@example.com -d utorrent.your-domain.com
Where

--nginx: Use the nginx plugin.
--apache: Use the Apache plugin.
--agree-tos: Agree to terms of service.
--redirect: Force HTTPS by 301 redirect.
--hsts: Add the Strict-Transport-Security header to every HTTP response. Forcing browser to always use TLS for the domain. Defends against SSL/TLS Stripping.
--staple-ocsp: Enables OCSP Stapling. A valid OCSP response is stapled to the certificate that the server offers during TLS.
The certificate should now be obtained and automatically installed.

utorrent server linux

Now you should be able to access uTorrent server via https://utorrent.your-domain.com/gui.

How to Uninstall uTorrent on Ubuntu
To remove uTorrent, first stop the current uTorrent process.

sudo pkill utserver
Then remove the installation directory.

sudo rm -r /opt/utorrent-server-alpha-v3_3/
And remove the symbolic link.

sudo rm /usr/bin/utserver


#!/bin/sh
### BEGIN INIT INFO
# Provides:          rtorrent_autostart
# Required-Start:    $local_fs $remote_fs $network $syslog $netdaemons
# Required-Stop:     $local_fs $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: rtorrent script using screen(1)
# Description:       rtorrent script using screen(1) to keep torrents working without the user logging in
### END INIT INFO
#
#
# Original source: http://forum.utorrent.com/viewtopic.php?id=88044
#
# uTorrent start stop service script
#
# copy to /etc/init.d
# run "update-rc.d utorrent defaults" to install
# run "update-rc.d utorrent remove" to remove
#
#
# version 2 improvments by:
# @author FanFan Huang (kaboom05+utorrentscript@gmail.com)
#
#
UTORRENT_PATH=/opt/utorrent-server-alpha-v3_3/ #where you extracted your utserver executable
LOGFILE=/opt/utorrent-server-alpha-v3_3/utorrent.log #must be a writable directory
USER=raj #any user account you can create the utorrent user if you like
GROUP=users
NICE=15
SCRIPTNAME=/etc/init.d/utorrent #must match this file name

DESC="uTorrent Server for Linux"
CHDIR=$UTORRENT_PATH
NAME=utserver
UT_SETTINGS=$UTORRENT_PATH
UT_LOG=$LOGFILE

DAEMON_ARGS="-settingspath ${UT_SETTINGS} -logfile ${UT_LOG}"
DAEMON=$CHDIR/$NAME
PIDFILE=/var/run/utorrent.pid
STOP_TIMEOUT=5
INIT_VERBOSE=yes

FAILURE=false

# Exit if the package is not installed
[ -x "$DAEMON" ] || exit 0

# Read configuration variable file if it is present
[ -r /etc/default/$NAME ] && . /etc/default/$NAME

# Load the VERBOSE setting and other rcS variables
. /lib/init/vars.sh

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.0-6) to ensure that this file is present.
. /lib/lsb/init-functions

#
# Function that starts the daemon/service
#
do_start()
{
FAILURE=false
# Return
# 0 if daemon has been started
# 1 if daemon was already running
# 2 if daemon could not be started
# 3 if port bind failed
start-stop-daemon --start --nicelevel $NICE --quiet --make-pidfile --pidfile $PIDFILE --chuid $USER:$GROUP --chdir $CHDIR --background --exec $DAEMON --test > /dev/null
if [ "$?" = "1" ]; then
return 1
fi
start-stop-daemon --start --nicelevel $NICE --quiet --make-pidfile --pidfile $PIDFILE --chuid $USER:$GROUP --chdir $CHDIR --background --exec $DAEMON -- $DAEMON_ARGS
if [ "$?" != "0" ]; then
return 2
fi
#bind validation
while [ ! -e $LOGFILE ]; do
sleep 1 #Wait for file to be generated
done

######################## DISABLED ENABLE THIS SECTION IF YOU HAVE IPv6 HANGS WITH NO IPv6 Support ################
# while [ ! -n "$(cat $LOGFILE|grep 'IPv6 is installed')" ]; do
# #wait until utorrent has finished bootup (IPv6 MESSAGE is the last message)#
# sleep 1
# done

RESULT=$(cat $LOGFILE|grep 'bind failed')
if [ -n "$RESULT" ]; then
return 3
fi
return 0
}

#
# Function that stops the daemon/service
#
do_stop()
{
# Return
# 0 if daemon has been stopped
# 1 if daemon was already stopped
# 2 if daemon could not be stopped
# other if a failure occurred
start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile $PIDFILE --name $NAME
RETVAL="$?"
if [ "$RETVAL" = 2 ]; then
return 2
fi
start-stop-daemon --stop --quiet --oknodo --retry=0/30/KILL/5 --exec $DAEMON
RETVAL="$?"
if [ "$RETVAL" = 2 ]; then
return 2
fi
#block process until server is completed shutting down fully
while [ -n "$(pidof "$NAME")" ]; do
sleep 1
done
# Many daemons don't delete their pidfiles when they exit.
rm -f $PIDFILE
rm -f $LOGFILE #we don't want to keep our logfile
return "$RETVAL"
}

#
# Function that sends a SIGHUP to the daemon/service
#
do_reload() {
#
# If the daemon can reload its configuration without
# restarting (for example, when it is sent a SIGHUP),
# then implement that here.
#
start-stop-daemon --stop --signal 1 --quiet --pidfile $PIDFILE --name $NAME
return 0
}

msg_start() {
case "$1" in
0|1)
if [ "$VERBOSE" != no ]; then
log_end_msg 0
fi
;;
2)
if [ "$VERBOSE" != no ]; then
log_end_msg 1
fi
;;
3)
if [ "$VERBOSE" != no ]; then
log_daemon_msg "Port bind failure detected uTorrent may have limited functionality please change the bind port and restart uTorrent"
log_end_msg 1
fi
;;
esac
}

msg_stop() {
case "$1" in
0|1)
if [ "$VERBOSE" != no ]; then
log_end_msg 0
fi
;;
*)
if [ "$VERBOSE" != no ]; then
log_daemon_msg "Failed to stop service exit status $STATUS"
log_end_msg 1
fi
esac
}

case "$1" in
start)
if [ "$VERBOSE" != no ]; then
log_daemon_msg "Starting $DESC"
fi
do_start
msg_start "$?"
;;
stop)
if [ "$VERBOSE" != no ]; then
log_daemon_msg "Stopping $DESC"
fi
do_stop
msg_stop "$?"
;;
status)
if [ -e "$PIDFILE" ]; then
PID=" PID:($(cat $PIDFILE))"
else
PID=""
fi
status_of_proc "$DAEMON" "uTorrent$PID"
if [ "$?" != "0" ]; then
exit $?
fi
;;
restart|force-reload)
#
# If the "reload" option is implemented then remove the
# 'force-reload' alias
#
log_daemon_msg "Restarting $DESC"
do_stop
STATUS="$?"
if [ "$STATUS" -ne 0 ] && [ "$STATUS" -ne 1 ]; then
log_daemon_msg "Could not stop exit status $STATUS"
log_end_msg 1
exit 1
fi
do_start
STATUS="$?"
case "$STATUS" in
0)
log_end_msg 0
;;
*)
log_daemon_msg "Restart failed start exist status $STATUS"
log_end_msg 1
esac
;;
log)
if [ -e "$LOGFILE" ]; then
LOG=$(cat $LOGFILE)
echo "$LOG"
else
echo "uTorrent is not running no active log file"
fi
;;

*)
echo "Usage: $SCRIPTNAME {start|stop|status|restart|force-reload|log}" >&2
exit 3
;;
esac
Save and close the file.

Step 3: Mark this file as executable.

$ sudo chmod 755 utorrent
Step 4: Copy / Move the file to /etc/init.d/

sudo cp utorrent /etc/init.d/
Step 5: Goto the init script directory.

$ cd /etc/init.d/
Step 6: Run the following command to install a utorrent startup script file.

$ sudo update-rc.d utorrent defaults
Step 7: Start utorrent using the following command.

$ sudo service utorrent start
Extras
utorrent service can be stopped using the following command.

$ sudo service utorrent stop
You can also remove utorrent startup script file using the following command in the init script directory.

$ sudo update-rc.d utorrent remove
