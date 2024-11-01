#! /bin/bash

# SSH Credentials
SSH_PW_FILE="/root/ssh.secret"
SSH_PRIVATE_KEY="/home/pi/.ssh/id_rsa"

# Rendezvous Server Connection
RDV_USER="ubuntu"
RDV_DOMAIN="rendezvous.example.com"
RDV_PORT=22
AVAILABLE_PORT=35722

# Dependencies
SSH_CMD="/usr/bin/ssh"
SSHPASS_CMD="/usr/bin/sshpass"
SSHPASS_PROMPT="id_rsa':"

# Run SSH Tunnel
$SSHPASS_CMD -v \
-f$SSHPASS_PW_FILE \
-P $SSHPASS_PROMPT \
$SSH_CMD -g -N -T \
-o VerifyHostKeyDNS=no \
-o "ServerAliveInterval 10" \
-o StrictHostKeyChecking=no \
-o "ExitOnForwardFailure yes" \
-p $RDV_PORT \
-R $AVAILABLE_PORT:localhost:22 \
-i $SSH_PRIVATE_KEY \
$RDV_USER@$RDV_DOMAIN
