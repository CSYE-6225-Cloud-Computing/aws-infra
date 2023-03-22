#! /bin/bash

cat << EOF >> home/ec2-user/webapp/app.env
DB_HOST=${db_host}
DB_USER=${db_user}
DB_PASS=${db_pwd}
DB_DATABASE=${db}
DB_DIALECT=${db_engine}
DB_PORT=${db_port}

AWS_BUCKET_NAME=${s3_bucket}
AWS_BUCKET_REGION=${s3_region}

EC2_IP_ADDRESS=${ec2_ip}

PORT="8080"

EOF

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
<<<<<<< HEAD
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s


sudo systemctl daemon-reload

# cloud watch agent service start
sudo systemctl enable amazon-cloudwatch-agent
sudo systemctl start amazon-cloudwatch-agent
sudo systemctl status amazon-cloudwatch-agent

=======
    -c file:/opt/cloudwatch-config.json \
    -s


sudo systemctl enable amazon-cloudwatch-agent.service # ***********************************

sudo systemctl daemon-reload

>>>>>>> 447c72daa31a047b935749e3389a492d03f4a4a1
# webapp service start
sudo systemctl enable webapp.service
sudo systemctl start webapp.service
sudo systemctl status webapp.service
<<<<<<< HEAD


=======

# cloud watch agent service start
sudo systemctl enable awslogsd # ********************************************
sudo systemctl start awslogsd
sudo systemctl status awslogsd
>>>>>>> 447c72daa31a047b935749e3389a492d03f4a4a1
