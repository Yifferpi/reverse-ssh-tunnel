

# Reverse SSH Tunnel

This repository contains everything you need to set up an SSH reverse tunnel, enabling remote access to a device from anywhere in the world. By installing it on a Raspberry Pi (or any similar device), you can seamlessly connect to the device via SSH without needing to configure the network it’s in. Simply drop the Raspberry Pi into any network, and it will automatically establish a secure, persistent connection, making it accessible remotely—perfect for managing IoT devices, remote servers, or any device on a dynamic network.

## How It Works

The SSH reverse tunnel establishes a secure and persistent connection from your Raspberry Pi (or any configured device) to a remote server. Here’s how it operates:

1. **Initiate the Reverse SSH Tunnel**: When started, the Raspberry Pi initiates an SSH connection to a remote server with a publicly accessible IP address.

2. **Binding a Local Port**: The SSH tunnel binds a specific port on the remote server to the Raspberry Pi’s SSH port, essentially creating a “tunnel” between the remote server and the Raspberry Pi.

3. **Access from Anywhere**: With the tunnel in place, you can connect to the Raspberry Pi from anywhere by SSHing into the remote server on the specified port. The connection is forwarded securely through the tunnel, directly accessing the Raspberry Pi.

4. **Automatic Reconnection**: The setup includes a script to ensure the tunnel remains active, automatically re-establishing the connection if interrupted (for example, by network changes or device reboots).

This approach allows you to remotely manage your device, bypassing firewalls or restrictive network configurations that would usually block inbound SSH access.

## Diagram

Below is a simplified diagram to illustrate the SSH reverse tunnel setup and connection flow:

```plaintext
                                  ┌───────────┐
                                  │ Raspberry │
           Private Network        │    Pi     │
                                  └───────────┘
                                       │
                  ──────────────────────────────
                        NAT / Firewall |
                  ──────────────────────────────
                                       │
                                  SSH Tunnel 
           Public Network       (Port Forwarding)
                                       │
                                       V
  ┌─────────────┐               ┌────────────────┐
  │ Your Device │   SSH Access  │  Rendezvous    │
  │  (Laptop)   │  ───────────> │  Server        │
  └─────────────┘   to RPi      │ (Public IP)    │
                                └────────────────┘
```



### Installation

#### Rendezvous Server

1. Install and configure SSH server on the rendezvous server
1. Add the following lines to the `sshd_config` file on the rendezvous server:
    ```
    GatewayPorts yes
    AllowTcpForwarding yes
    ```
1. It is recommended to also add the following lines to the `sshd_config` file on the rendezvous server:
    ```
    PublicKeyAuthentication yes
    PasswordAuthentication no
    ```
1. Restart the SSH server on the rendezvous server

#### RPi

Install and configure SSH server on the RPi

Generate an SSH key pair on the RPi

```bash
ssh-keygen -t rsa -b 4096 -f /home/pi/.ssh/id_rsa
```

- Do set a password for the private key and save it into a file only readable by root

```bash 
sudo su
echo "password" > /root/ssh.secret
chmod 600 /root/ssh.secret
```

Add the public key to the `authorized_keys` file on the Rendezvous server and restart the SSH server

Copy `rtunnel.sh` to the RPi and adapt the variables in the script

- set `SSH_PW_FILE` to the file containing the password for the private key
- set `SSH_PRIVATE_KEY` to the private key file

```bash
SSH_PW_FILE="/root/ssh.secret"
SSH_PRIVATE_KEY="/home/pi/.ssh/id_rsa"
```

- set `RDV_USER`, `RDV_DOMAIN`, and `RDV_PORT` to the user, domain, and port of the rendezvous server's SSH server

```bash
RDV_USER="ubuntu"
RDV_DOMAIN="rdv.example.com"
RDV_PORT=22
```

- set `AVAILABLE_PORT` to the port on the rendezvous server where the RPi's SSH server should be available

```bash
AVAILABLE_PORT=2022
```

Copy `rtunnel.service` to `/etc/system/systemd/` and adapt the path to the `rtunnel.sh` script.

```bash
ExecStart=/root/rtunnel.sh
```

Enable and start the service

```bash
systemctl daemon-reload
systemctl enable rtunnel
systemctl start rtunnel
```

Add your personal SSH key to the `authorized_keys` file on the RPi

Connect to the RPi via the rendezvous server

```bash
ssh -p 2022 pi@rdv.example.com
```

```plaintext
Private Network   |         Internet         |     Private Network
                  |                          |   
    +---------+   |       +------------+     |     +---------------+
    |  RPi    |   |       | RDV        |     |     |  Client       |
    |         |   |       |            |     |     |               |
    |     ssh | --|-----> |- 22  2022 -| <---|---- | ssh RDV:2022  |
    |- 22     |   |       |            |     |     |  pi@RPi$>     |
    |         |   |       |            |     |     |               |
    +---------+   |       +------------+     |     +---------------+

```

## FAQ

### Does this work if the RPi is behind a NAT?

Yes, the RPi can be behind a NAT. As long as the RPi and your personal machine can connect to the rendezvous server, the tunnel will work.

### Does this work if the Rendezvous server is behind a NAT?

Yes, the rendezvous server can be behind a NAT. In that case, a Port Forwarding rule has to be set up for the RPi to reach the rendezvous server. Configuring a dynamic DNS service is also recommended.


## Ethics and Responsibility Disclaimer

This tool is for **authorized** remote access only. Please make sure you have explicit permission before setting up this device in any network.

We don’t take responsibility for any misuse. Don’t be that person—use this tool responsibly and ethically.

---

