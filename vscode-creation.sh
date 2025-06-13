#!/bin/bash

# Set variables
INSTANCE_NAME="CodeServerInstance"
INSTANCE_TYPE="t2.small"
AMI_ID="ami-0373b8387fcb94813" # Amazon Linux 2023 AMI (adjust for your region)
KEY_NAME="code-server-key"
SECURITY_GROUP_NAME="code-server-sg"
REGION=$(aws configure get region)
if [ -z "$REGION" ]; then
    REGION="us-east-1" # Default region
fi

echo "=== Creating EC2 instance with code-server ==="
echo "Region: $REGION"
echo "Instance type: $INSTANCE_TYPE"
echo "Instance name: $INSTANCE_NAME"


# Create security group if it doesn't exist
if ! aws ec2 describe-security-groups --group-names "$SECURITY_GROUP_NAME" --region "$REGION" &> /dev/null; then
    echo "Creating security group: $SECURITY_GROUP_NAME"
    SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name "$SECURITY_GROUP_NAME" --description "Security group for code-server" --region "$REGION" --query 'GroupId' --output text)
    
    # Add inbound rules
    echo "Adding security group rules"
    aws ec2 authorize-security-group-ingress --group-id "$SECURITY_GROUP_ID" --protocol tcp --port 8080 --cidr 0.0.0.0/0 --region "$REGION"
else
    echo "Security group $SECURITY_GROUP_NAME already exists"
    SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --group-names "$SECURITY_GROUP_NAME" --region "$REGION" --query 'SecurityGroups[0].GroupId' --output text)
fi

# Create user data script with embedded code-server setup
cat > user-data.sh << 'EOF'
#!/bin/bash

# Set HOME environment variable explicitly
export HOME=/root

# Update the system
yum update -y

# Install required dependencies
yum install -y curl

# Install code-server directly without using the install script
mkdir -p /tmp/code-server
cd /tmp/code-server
curl -L https://github.com/coder/code-server/releases/download/v4.14.1/code-server-4.14.1-amd64.rpm -o code-server.rpm
yum install -y ./code-server.rpm

# Create user directory and config
mkdir -p /home/ec2-user/.config/code-server
cat > /home/ec2-user/.config/code-server/config.yaml << EOFINNER
bind-addr: 0.0.0.0:8080
auth: password
password: changeme123!
cert: false
EOFINNER

# Fix permissions
chown -R ec2-user:ec2-user /home/ec2-user/.config

# Create systemd service file manually
cat > /etc/systemd/system/code-server@ec2-user.service << EOFSERVICE
[Unit]
Description=code-server for %i
After=network.target

[Service]
Type=simple
User=%i
WorkingDirectory=/home/%i
ExecStart=/usr/bin/code-server
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOFSERVICE

# Reload systemd and enable service
systemctl daemon-reload
systemctl enable --now code-server@ec2-user

# Get the public IP address
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Create a welcome file with instructions
cat > /home/ec2-user/WELCOME.txt << EOFWELCOME
=================================================
Code-server (VS Code) has been installed!
Access it at: http://$PUBLIC_IP:8080
Password: changeme123!
=================================================
IMPORTANT: For security, please change the password in:
~/.config/code-server/config.yaml
And restart the service with:
sudo systemctl restart code-server@ec2-user
=================================================
EOFWELCOME

chown ec2-user:ec2-user /home/ec2-user/WELCOME.txt

# Add a startup script to check if code-server is running
cat > /etc/rc.d/rc.local << EOFRCLOCAL
#!/bin/bash
# Check if code-server is running, if not start it
if ! systemctl is-active --quiet code-server@ec2-user; then
  systemctl start code-server@ec2-user
fi
exit 0
EOFRCLOCAL

chmod +x /etc/rc.d/rc.local
systemctl enable rc-local
EOF

# Launch EC2 instance
echo "Launching EC2 instance..."
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --security-group-ids "$SECURITY_GROUP_ID" \
    --user-data file://user-data.sh \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
    --region "$REGION" \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "Instance $INSTANCE_ID is being launched"
echo "Waiting for instance to be running..."
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --region "$REGION"

# Get public IP address
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text \
    --region "$REGION")

echo "Instance is now running!"
echo "Public IP: $PUBLIC_IP"

echo "==================================================="
echo "EC2 instance with code-server is being set up!"
echo "It may take a few minutes for the installation to complete."
echo ""
echo "Once ready, you can access code-server at: http://$PUBLIC_IP:8080"
echo "Default password: changeme123!"
echo ""
echo "==================================================="
