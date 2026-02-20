# on a new server
# preparations

1. change ssh port, setup basic autorization with ssh keys
`sed -i 's/^#\?Port 22$/Port 56654/' /etc/ssh/sshd_config`

2. add your keys ~/.ssh/authorized_keys
`touch ~/.ssh/authorized_keys && chmod 0600 ~/.ssh/authorized_keys && echo "ssh-ed25519 <YOURDATA>" >> ~/.ssh/authorized_keys`

3. apply ssh changes
`systemctl daemon-reload && systemctl restart ssh.socket && systemctl restart ssh.service`

4. setup ufw and fail2ban
`apt update && apt install ufw`
`ufw status
ufw allow from <YOUR_IP> proto tcp to any port <SERVER_SSH_PORT> comment 'main admin ip sshd'
ufw allow from <BASTION_SERVER_IP> proto tcp to any port <SERVER_SSH_PORT> comment 'bastion ip sshd'
ufw allow from <MAIN_DEV_IP> proto tcp to any port <SERVER_SSH_PORT> comment 'main dev ip sshd'
ufw allow 443 comment 'website https'
ufw allow 80 comment 'website http'
ufw allow 8085 comment 'WoW port 1'
ufw allow 3724 comment 'WoW port 2'
ufw allow from <ZABBIX_SERVER_IP> to any port 10050 comment 'zabbix agent'
ufw enable`

`apt-get install fail2ban -y && systemctl enable --now fail2ban`
`https://www.bennetrichter.de/en/tutorials/ssh-server-fail2ban-linux/`
   
5. install dependencies (some of them are no need for your server)
`apt-get install mariadb-server nginx git rsync proxychains4 npm libtbb-dev htop -y`

6. create user for the website systemd service
`useradd -s /usr/sbin/nologin -m website_user
passwd website_user
type <YOUR_PASSWORD>
groupadd website_group
usermod -aG website_group website_user
chown -R website_user:website_group /home/website`

7. create user for discord bot systemd service
`useradd -s /usr/sbin/nologin -m discord_bot
passwd discord_bot
type <YOUR_PASSWORD>
groupadd discord_group
usermod -aG discord_group discord_bot
chown -R discord_bot:discord_group /home/discordbot
touch /var/log/discordbot-out.log
touch /var/log/discordbot-err.log
chown -R discord_bot:discord_group /var/log/discordbot-out.log
chown -R discord_bot:discord_group /var/log/discordbot-err.log`

8. setup user for the realmd and mangosd systemd services
`useradd -s /usr/sbin/nologin -m vmangos_user
passwd vmangos_user
type <YOUR_PASSWORD>
groupadd vmangos_group
usermod -aG vmangos_group vmangos_user
chown -R vmangos_user:vmangos_group /home/vmangos_server`

9. setup vmangos
`https://github.com/vmangos/core`
`https://github.com/vmangos/wiki/wiki/Compiling-on-Linux`
`https://github.com/vmangos/wiki/wiki/Getting-it-working`

10. setup mysql user for vmangos
`CREATE USER 'vmangos_db_user'@localhost IDENTIFIED BY 'YOUR_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO 'vmangos_db_user'@localhost IDENTIFIED BY 'YOUR_PASSWORD';
FLUSH PRIVILEGES;`

11. setup systemd services for realmd

```cd /etc/systemd/system/ && touch restart_realmd.service```

```
[Unit]
Description=Scheduled-Restart-realmd
After=default.target

[Service]
ExecStart=/home/vmangos_server/run/bin/realmd -c /home/vmangos_server/run/etc/realmd.conf
User=vmangos_user
StandardOutput=null
Restart=always
RuntimeMaxSec=3600

[Install]
WantedBy=default.target
```

12. setup systemd for mangosd

`cd /etc/systemd/system/ && touch mangosd.service`

```
[Unit]
Description=mangosd service
After=network.target mysql.service

[Service]
Type=simple
User=vmangos_ashen
ExecStart=/home/vmangos_server/run/bin/mangosd -c /home/vmangos_server/run/etc/mangosd.conf

StandardInput=tty
TTYPath=/dev/tty3
TTYReset=yes
TTYVHangup=yes

Restart=on-failure
RestartSec=30s

[Install]
WantedBy=default.target
```

13. setup systemd for discord_bot

`cd /etc/systemd/system/ && touch discord_bot.service`

```
[Unit]
Description=Run Discord Bot as a service

[Service]
Type=simple
User=discord_bot
Restart=always
WorkingDirectory=/home/discordbot
# To start with some proxy if discord is blocked in your country
#ExecStart=proxychains4 node /home/discordbot/index.js

# To start normally
ExecStart=node /home/discordbot/index.js

# The log file paths can be customised
StandardOutput=file:/var/log/vmangos-discordbot-out.log 
StandardError=file:/var/log/vmangos-discordbot-err.log
#StandardOutput=null
#StandardError=null

[Install]
WantedBy=multi-user.target
```

14. setup your discord bot

`https://discord.js.org/`
`https://github.com/discordjs/discord.js`

15. setup your proxychains4 if needs

`cd /etc/systemd/system && touch discord_proxy.service`

```
[Unit]
Description=Run Discord Proxy as a service

[Service]
Type=simple
Restart=always
ExecStart=ssh -N -D 1080 root@your-desired-server-to-bypass-cencorship

# The log file paths can be customised
StandardOutput=file:/var/log/proxychains4-out.log 
StandardError=file:/var/log/proxychains4-err.log 

[Install]
WantedBy=multi-user.target
```

16. setup nginx for your website and website port if needs

`an example`
`https://gist.github.com/alectrocute/8c7e16d3718ccc9373313959fa9d22c2`


16. setup your website

`whatever you like, no limitations for your fantasy, we run on npm`

`cd /etc/systemd/system && touch vmangos_website.service`

```
[Unit]
Description=Run Website as a service

[Service]
Type=simple
User=website_user
Restart=always
WorkingDirectory=/home/website/nuxt-app
ExecStart=npm run start -- --port <YOUR_DESIRED_PORT>

# The log file paths can be customised
StandardOutput=file:/var/log/website-out.log 
StandardError=file:/var/log/website-err.log 

[Install]
WantedBy=multi-user.target
```


17. run all systemd services and see if there's any errors and fix em!

```
systemctl daemon-reload
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