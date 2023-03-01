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
AWS_ACCESS_KEY="AKIAYLWRNJ6YGDU5PZUX"
AWS_SECRET_KEY="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"

PORT="8080"
EOF

sudo systemctl daemon-reload

sudo systemctl enable webapp.service
sudo systemctl start webapp.service

sudo systemctl status webapp.service