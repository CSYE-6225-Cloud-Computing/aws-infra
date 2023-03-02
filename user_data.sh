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

PORT="8080"
EOF

sudo systemctl daemon-reload

sudo systemctl enable webapp.service
sudo systemctl start webapp.service

sudo systemctl status webapp.service