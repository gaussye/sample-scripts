#!/bin/bash

# Set default variables
INSTANCE_NAME="CodeServerInstance"
INSTANCE_TYPE="t3.large"
AMI_ID="ami-0373b8387fcb94813" # Amazon Linux 2023 AMI (adjust for your region)
KEY_NAME="code-server-key"
TIMESTAMP=$(date +"%m%d%M%M") # Format: MMDDMIMI (Month, Day, Minutes, Minutes)
SECURITY_GROUP_NAME="code-server-sg-${TIMESTAMP}"
REGION=$(aws configure get region)
if [ -z "$REGION" ]; then
    REGION="us-east-1" # Default region
fi

# Default VPC and subnet settings
CREATE_NEW_VPC=true
VPC_ID=""
SUBNET_ID=""
VPC_CIDR="10.0.0.0/16"
SUBNET_CIDR="10.0.1.0/24"
VPC_NAME="code-server-vpc-${TIMESTAMP}"
SUBNET_NAME="code-server-subnet-${TIMESTAMP}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --vpc-id)
            VPC_ID="$2"
            CREATE_NEW_VPC=false
            shift 2
            ;;
        --subnet-id)
            SUBNET_ID="$2"
            CREATE_NEW_VPC=false
            shift 2
            ;;
        --instance-type)
            INSTANCE_TYPE="$2"
            shift 2
            ;;
        --instance-name)
            INSTANCE_NAME="$2"
            shift 2
            ;;
        --region)
            REGION="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --vpc-id VPC_ID         Use existing VPC"
            echo "  --subnet-id SUBNET_ID   Use existing subnet"
            echo "  --instance-type TYPE    EC2 instance type (default: t3.large)"
            echo "  --instance-name NAME    Name for the EC2 instance (default: CodeServerInstance)"
            echo "  --region REGION         AWS region (default: from AWS config or us-east-1)"
            echo "  --help                  Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "=== Creating EC2 instance with code-server ==="
echo "Region: $REGION"
echo "Instance type: $INSTANCE_TYPE"
echo "Instance name: $INSTANCE_NAME"
echo "Security group name: $SECURITY_GROUP_NAME"

# Create VPC and subnet if needed
if [ "$CREATE_NEW_VPC" = true ]; then
    echo "Creating new VPC and subnet..."
    
    # Create VPC
    VPC_ID=$(aws ec2 create-vpc \
        --cidr-block "$VPC_CIDR" \
        --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=$VPC_NAME}]" \
        --region "$REGION" \
        --query 'Vpc.VpcId' \
        --output text)
    
    if [ -z "$VPC_ID" ]; then
        echo "Failed to create VPC. Exiting."
        exit 1
    fi
    
    echo "Created VPC: $VPC_ID"
    
    # Enable DNS hostnames for the VPC
    aws ec2 modify-vpc-attribute \
        --vpc-id "$VPC_ID" \
        --enable-dns-hostnames "{\"Value\":true}" \
        --region "$REGION"
    
    # Create Internet Gateway
    IGW_ID=$(aws ec2 create-internet-gateway \
        --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=$VPC_NAME-igw}]" \
        --region "$REGION" \
        --query 'InternetGateway.InternetGatewayId' \
        --output text)
    
    # Attach Internet Gateway to VPC
    aws ec2 attach-internet-gateway \
        --internet-gateway-id "$IGW_ID" \
        --vpc-id "$VPC_ID" \
        --region "$REGION"
    
    # Create subnet
    SUBNET_ID=$(aws ec2 create-subnet \
        --vpc-id "$VPC_ID" \
        --cidr-block "$SUBNET_CIDR" \
        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$SUBNET_NAME}]" \
        --region "$REGION" \
        --query 'Subnet.SubnetId' \
        --output text)
    
    echo "Created subnet: $SUBNET_ID"
    
    # Enable auto-assign public IP on subnet
    aws ec2 modify-subnet-attribute \
        --subnet-id "$SUBNET_ID" \
        --map-public-ip-on-launch \
        --region "$REGION"
    
    # Create route table
    ROUTE_TABLE_ID=$(aws ec2 create-route-table \
        --vpc-id "$VPC_ID" \
        --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=$VPC_NAME-rtb}]" \
        --region "$REGION" \
        --query 'RouteTable.RouteTableId' \
        --output text)
    
    # Create route to Internet Gateway
    aws ec2 create-route \
        --route-table-id "$ROUTE_TABLE_ID" \
        --destination-cidr-block "0.0.0.0/0" \
        --gateway-id "$IGW_ID" \
        --region "$REGION"
    
    # Associate route table with subnet
    aws ec2 associate-route-table \
        --route-table-id "$ROUTE_TABLE_ID" \
        --subnet-id "$SUBNET_ID" \
        --region "$REGION"
else
    # Validate provided VPC and subnet IDs
    if [ -n "$VPC_ID" ]; then
        # Check if VPC exists
        if ! aws ec2 describe-vpcs --vpc-ids "$VPC_ID" --region "$REGION" &> /dev/null; then
            echo "Error: VPC $VPC_ID does not exist in region $REGION"
            exit 1
        fi
        
        # If subnet not provided, use the first subnet in the VPC
        if [ -z "$SUBNET_ID" ]; then
            echo "No subnet ID provided, using the first subnet in VPC $VPC_ID"
            SUBNET_ID=$(aws ec2 describe-subnets \
                --filters "Name=vpc-id,Values=$VPC_ID" \
                --query 'Subnets[0].SubnetId' \
                --output text \
                --region "$REGION")
            
            if [ -z "$SUBNET_ID" ] || [ "$SUBNET_ID" == "None" ]; then
                echo "Error: No subnet found in VPC $VPC_ID"
                exit 1
            fi
        fi
    elif [ -n "$SUBNET_ID" ]; then
        # Check if subnet exists and get its VPC ID
        if ! aws ec2 describe-subnets --subnet-ids "$SUBNET_ID" --region "$REGION" &> /dev/null; then
            echo "Error: Subnet $SUBNET_ID does not exist in region $REGION"
            exit 1
        fi
        
        VPC_ID=$(aws ec2 describe-subnets \
            --subnet-ids "$SUBNET_ID" \
            --query 'Subnets[0].VpcId' \
            --output text \
            --region "$REGION")
    else
        echo "Error: Neither VPC ID nor subnet ID provided, but CREATE_NEW_VPC is false"
        exit 1
    fi
    
    echo "Using existing VPC: $VPC_ID"
    echo "Using existing subnet: $SUBNET_ID"
fi

# Get current public IP address
echo "Detecting your current IP address..."
MY_IP=$(curl -s https://checkip.amazonaws.com)
if [ -z "$MY_IP" ]; then
    echo "Warning: Could not detect your IP address. Using alternative method..."
    MY_IP=$(curl -s https://api.ipify.org)
    if [ -z "$MY_IP" ]; then
        echo "Warning: Could not detect your IP address. Defaulting to allow all IPs for port 8080."
        MY_IP="0.0.0.0/0"
    else
        MY_IP="${MY_IP}/32"
    fi
else
    MY_IP="${MY_IP}/32"
fi
echo "Your IP address: $MY_IP"

# Create a new security group with timestamp suffix
echo "Creating security group: $SECURITY_GROUP_NAME in VPC $VPC_ID"
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    --group-name "$SECURITY_GROUP_NAME" \
    --description "Security group for code-server created on $(date)" \
    --vpc-id "$VPC_ID" \
    --region "$REGION" \
    --query 'GroupId' \
    --output text)

# Add inbound rules
echo "Adding security group rules"
echo "Allowing port 8080 access only from your IP: $MY_IP"
aws ec2 authorize-security-group-ingress --group-id "$SECURITY_GROUP_ID" --protocol tcp --port 8080 --cidr "$MY_IP" --region "$REGION"
#aws ec2 authorize-security-group-ingress --group-id "$SECURITY_GROUP_ID" --protocol tcp --port 22 --cidr 0.0.0.0/0 --region "$REGION"

# Create key pair if it doesn't exist
if ! aws ec2 describe-key-pairs --key-names "$KEY_NAME" --region "$REGION" &> /dev/null; then
    echo "Creating key pair: $KEY_NAME"
    aws ec2 create-key-pair \
        --key-name "$KEY_NAME" \
        --query 'KeyMaterial' \
        --output text \
        --region "$REGION" > "$KEY_NAME.pem"
    chmod 400 "$KEY_NAME.pem"
else
    echo "Key pair $KEY_NAME already exists"
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
echo "Launching EC2 instance in subnet $SUBNET_ID..."
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --subnet-id "$SUBNET_ID" \
    --security-group-ids "$SECURITY_GROUP_ID" \
    --key-name "$KEY_NAME" \
    --user-data file://user-data.sh \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME-$TIMESTAMP}]" \
    --region "$REGION" \
    --query 'Instances[0].InstanceId' \
    --output text)

if [ -z "$INSTANCE_ID" ]; then
    echo "Failed to launch EC2 instance. Exiting."
    exit 1
fi

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
echo "Instance ID: $INSTANCE_ID"
echo "VPC ID: $VPC_ID"
echo "Subnet ID: $SUBNET_ID"
echo "Security Group ID: $SECURITY_GROUP_ID"
echo "Security Group Name: $SECURITY_GROUP_NAME"

echo "==================================================="
echo "EC2 instance with code-server is being set up!"
echo "It may take a few minutes for the installation to complete."
echo ""
echo "Once ready, you can access code-server at: http://$PUBLIC_IP:8080"
echo "Default password: changeme123!"
echo ""
echo "SSH access: ssh -i $KEY_NAME.pem ec2-user@$PUBLIC_IP"
echo "==================================================="
