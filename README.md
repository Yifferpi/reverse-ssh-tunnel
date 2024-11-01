

# Reverse SSH Tunnel

This repository contains everything you need to set up an SSH reverse tunnel, enabling remote access to a device from anywhere in the world. By installing it on a Raspberry Pi (or any similar device), you can seamlessly connect to the device via SSH without needing to configure the network it’s in. Simply drop the Raspberry Pi into any network, and it will automatically establish a secure, persistent connection, making it accessible remotely—perfect for managing IoT devices, remote servers, or any device on a dynamic network.

## How It Works

The SSH reverse tunnel establishes a secure and persistent connection from your Raspberry Pi (or any configured device) to a remote server. Here’s how it operates:

1. **Initiate the Reverse SSH Tunnel**: When started, the Raspberry Pi initiates an SSH connection to a remote server with a publicly accessible IP address.

2. **Binding a Local Port**: The SSH tunnel binds a specific port on the remote server to the Raspberry Pi’s SSH port, essentially creating a “tunnel” between the remote server and the Raspberry Pi.

3. **Access from Anywhere**: With the tunnel in place, you can connect to the Raspberry Pi from anywhere by SSHing into the remote server on the specified port. The connection is forwarded securely through the tunnel, directly accessing the Raspberry Pi.

4. **Automatic Reconnection**: The setup includes a script to ensure the tunnel remains active, automatically re-establishing the connection if interrupted (for example, by network changes or device reboots).

This approach allows you to remotely manage your device, bypassing firewalls or restrictive network configurations that would usually block inbound SSH access.


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

Above is a simplified diagram to illustrate the SSH reverse tunnel setup and connection flow:

1. The Raspberry Pi is placed in a private network (e.g., behind a NAT or firewall) and initiates an SSH connection to a remote server with a publicly accessible IP address (the rendezvous server).
2. The Client (your device) connects to the rendezvous server, which forwards the connection to the Raspberry Pi through the established SSH tunnel.


## Setup

Throughout the setup, we refer to three main components:

- **Rendezvous Server**: This is the remote server with a public IP address that acts as a bridge for SSH connections. It allows secure access to devices located behind firewalls or NAT. The user account on this server is referred to as `RDV_USER`.

- **Raspberry Pi (RPi)**: This is the local device that you want to access remotely. It connects to the rendezvous server to establish the reverse SSH tunnel. The default user account on the Raspberry Pi is typically `pi`.

- **Client**: This is the device you use to connect to the Raspberry Pi remotely. It could be your laptop, desktop, or any device with an SSH client.


### Rendezvous Server

1. Install and configure the SSH server on the rendezvous server.
2. Add the following lines to the `sshd_config` file on the rendezvous server:
    ```bash
    GatewayPorts yes
    AllowTcpForwarding yes
    ```
3. It is recommended to also add the following lines to the `sshd_config` file on the rendezvous server for enhanced security:
    ```bash
    PublicKeyAuthentication yes
    PasswordAuthentication no
    ```
4. Restart the SSH server on the rendezvous server to apply the changes:
    ```bash
    sudo systemctl restart ssh
    ```

5. (Optional) You may want to point a domain (e.g. `rdv.example.com`) to the public IP address of the rendezvous server. If your rendezvous server has a dynamic IP address, consider using a dynamic DNS service to ensure you can always reach it.

### Raspberry Pi (RPi)

1. Install and configure the SSH server on the RPi if it’s not already installed:
    ```bash
    sudo apt update
    sudo apt install openssh-server
    ```

2. Generate an SSH key pair on the RPi:
    ```bash
    ssh-keygen -t rsa -b 4096 -f /home/pi/.ssh/id_rsa
    ```
    - Make sure to set a password for the private key and save it into a file that is only readable by root:
    ```bash
    sudo su
    echo "your_password" > /root/ssh.secret
    chmod 600 /root/ssh.secret
    ```

3. Add the public key to the `authorized_keys` file on the rendezvous server (this can be done by copying the public key contents from the RPi):
    ```bash
    ssh-copy-id -i /home/pi/.ssh/id_rsa.pub RDV_USER@RDV_DOMAIN
    ```
    - Restart the SSH server on the rendezvous server:
    ```bash
    sudo systemctl restart ssh
    ```

4. Copy `rtunnel.sh` to the RPi and adapt the variables in the script:
    - Set `SSH_PW_FILE` to the file containing the password for the private key:
    ```bash
    SSH_PW_FILE="/root/ssh.secret"
    SSH_PRIVATE_KEY="/home/pi/.ssh/id_rsa"
    ```
    - Set `RDV_USER`, `RDV_DOMAIN`, and `RDV_PORT` to the user, domain, and port of the rendezvous server's SSH server:
    ```bash
    RDV_USER="ubuntu"
    RDV_DOMAIN="rdv.example.com"
    RDV_PORT=22
    ```
    - Set `AVAILABLE_PORT` to the port on the rendezvous server where the RPi's SSH server should be available:
    ```bash
    AVAILABLE_PORT=2022
    ```

5. Copy `rtunnel.service` to `/etc/systemd/system/` and adapt the path to the `rtunnel.sh` script:
    ```bash
    ExecStart=/root/rtunnel.sh
    ```

6. Enable and start the service:
    ```bash
    sudo systemctl daemon-reload
    sudo systemctl enable rtunnel
    sudo systemctl start rtunnel
    ```

7. Add your personal SSH key to the `authorized_keys` file on the RPi.

8. Finally, connect to the RPi via the rendezvous server using:
    ```bash
    ssh -p 2022 pi@rdv.example.com
    ```

Below is a diagram illustrating the connection with the ports used in the above setup:

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

