# Migration to another host
---

##### 1. First you'd want to set up basic auth with ssh keys on new server

`sed -i 's/^#\?Port 22$/Port 56654/' /etc/ssh/sshd_config`
This will also change the ssh port.

##### 2. Add your and old server keys to ~/.ssh/authorized_keys on new server

`touch ~/.ssh/authorized_keys && chmod 0600 ~/.ssh/authorized_keys && echo "ssh-ed25519 <YOURDATA>" >> ~/.ssh/authorized_keys`
`echo "ssh-ed25519 <OLD_SERVER_PUB_KEY>" >> ~/.ssh/authorized_keys`

##### 3. Apply ssh changes

`systemctl daemon-reload && systemctl restart ssh.socket && systemctl restart ssh.service`

##### 4. Setup ufw and fail2ban on new server
For more information: https://www.bennetrichter.de/en/tutorials/ssh-server-fail2ban-linux/

`apt update && apt install ufw`

```
ufw status
ufw allow from <YOUR_IP> proto tcp to any port <NEW_SERVER_SSH_PORT> comment 'main admin ip sshd'
ufw allow from <OLD_PROD_IP> proto tcp to any port <NEW_SERVER_SSH_PORT> comment 'old prod server ip sshd'
ufw allow from <BASTION_SERVER_IP> proto tcp to any port <NEW_SERVER_SSH_PORT> comment 'bastion ip sshd'
ufw allow from <MAIN_DEV_IP> proto tcp to any port <NEW_SERVER_SSH_PORT> comment 'main dev ip sshd'
ufw allow 443 comment 'website https'
ufw allow 80 comment 'website http'
ufw allow 8085 comment 'WoW port 1'
ufw allow 3724 comment 'WoW port 2'
ufw allow from <ZABBIX_SERVER_IP> to any port 10050 comment 'zabbix agent'
ufw enable
```
`apt-get install fail2ban -y && systemctl enable --now fail2ban`

##### 5. Install dependencies on new server and disable swap
Disable swap firstly

```
cat /proc/swaps \
&& swapoff -a \
&& sed -i 's/\/swap\.img/\#swap\.img/' /etc/fstab \
&& cat /proc/swaps
```

(Not all of them are required for your server)
```apt-get install mariadb-server nginx git rsync proxychains4 npm mc libtbb-dev htop -y```


##### 6. VERY IMPORTANT, stop all services on old server! Stop databases on BOTH servers!

```
systemctl stop nginx.service
systemctl stop website_3005.service
systemctl stop discord_proxy.service
systemctl stop discord_bot.service
systemctl stop restart_realmd.service
systemctl stop mangosd.service
systemctl disable nginx.service
systemctl disable website_3005.service
systemctl disable discord_proxy.service
systemctl disable discord_bot.service
systemctl disable restart_realmd.service
systemctl disable mangosd.service
```

**ON BOTH SERVERS**
```
systemctl stop mariadb
```

##### 6. Do mysql backup before we start!

```
mysqldump -u root -p --all-databases > backup.sql
```

##### 7. Start data transfer from OLD to NEW server

```
rsync -avz /var/lib/mysql/* root@new-server:/var/lib/mysql/
rsync -avz /etc/mysql/* root@new-server:/etc/mysql/
rsync -avz /usr/lib/x86_64-linux-gnu/* root@new-server:/usr/lib/x86_64-linux-gnu/
rsync -avz /etc/proxychains4.conf root@new-server:/etc/proxychains4.conf
rsync -avz /home/* root@new-server:/home/
rsync -avz /etc/nginx/* root@new-server:/etc/nginx/
rsync -avz /etc/letsencrypt/* root@new-server:/etc/letsencrypt/
rsync -avz /var/www/website/* root@new-server:/var/www/website/
rsync -avz /etc/systemd/system/website_3005.service /etc/systemd/system/discord_bot.service /etc/systemd/system/restart_realmd.service /etc/systemd/system/mangosd.service root@new-server:/etc/systemd/system/
```

##### 8. Give permissions to the /var/lib/mysql on NEW server and start DB on NEW server

```
chown mysql:mysql -R /var/lib/mysql/ && systemctl start mariadb
```

##### 9. Create user
For the website systemd service.

```
useradd -s /usr/sbin/nologin -m website_user
passwd website_user
type <YOUR_PASSWORD>
groupadd website_group
usermod -aG website_group website_user
chown -R website_user:website_group /home/website
```

##### 10. Create user
For discord bot systemd service.
```
useradd -s /usr/sbin/nologin -m discord_bot
passwd discord_bot
type <YOUR_PASSWORD>
groupadd discord_group
usermod -aG discord_group discord_bot
chown -R discord_bot:discord_group /home/discordbot
touch /var/log/discordbot-out.log
touch /var/log/discordbot-err.log
chown -R discord_bot:discord_group /var/log/discordbot-out.log
chown -R discord_bot:discord_group /var/log/discordbot-err.log
```

##### 11. Setup user
For the realmd and mangosd systemd services
```
useradd -s /usr/sbin/nologin -m vmangos_user
passwd vmangos_user
type <YOUR_PASSWORD>
groupadd vmangos_group
usermod -aG vmangos_group vmangos_user
chown -R vmangos_user:vmangos_group /home/vmangos_server
chown -R vmangos_user:vmangos_group /home/vmangos_server/run/bin/logs
chmod 750 /home/vmangos_server/run/bin/logs
```


##### 12. You might need to rebuild your website
In our case


```
Download and install nvm:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
in lieu of restarting the shell
. "$HOME/.nvm/nvm.sh"
Download and install Node.js:
nvm install 20
Verify the Node.js version:
node -v # Should print "v20.19.6".
Verify npm version:
npm -v # Should print "10.8.2".
```

Go into website directory and do

```
npm install
npm run build
npm run start
```


##### 13. Run all systemd services
Check for any errors and fix em!

```systemctl daemon-reload
systemctl enable nginx.service
systemctl enable vmangos_website.service
systemctl enable discord_proxy.service
systemctl enable discord_bot.service
systemctl start nginx.service
systemctl start vmangos_website.service
systemctl start discord_proxy.service
systemctl start discord_bot.service
```

```
systemctl enable restart_realmd.service
systemctl enable mangosd.service
systemctl start restart_realmd.service
systemctl start mangosd.service
```

##### 14. Change your server IP in haproxy balancer config and restart the balancer


##### 15. Change your DNS name to new ip and voila!


## License

MIT
**Free Software, Hell Yeah!**
