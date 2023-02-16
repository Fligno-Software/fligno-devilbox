#!/bin/sh

# Minio is a S3-compatible object storage service
# ngrok is a cross-platform application that enables developers to expose a local development server to the Internet with minimal effort

docker-compose up -d php php53 php54 php55 php56 php70 php71 php72 php73 php74 php80 php81 php82 httpd mysql redis minio ngrok
