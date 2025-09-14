# Nginx Configuration Documentation

## Overview
This document describes the Nginx reverse proxy configuration for the F4 microservices architecture.

## Services and Ports

| Service         | Internal Port | Health Check Endpoint              |
|----------------|---------------|-----------------------------------|
| API Gateway    | 8080          | /                                |
| msreel        | 8082          | /msreel/management/health       |
| MSUser         | 8081          | /msuser/management/health        |
| MSCommentLike  | 8085          | /mscommentlike/management/health |
| MSNotification | 8083          | /msnotification/management/health|
| MSFeed         | 8084          | /msfeed/management/health        |

## Configuration Features

### SSL/HTTPS
- All HTTP traffic (port 80) is automatically redirected to HTTPS (port 443)
- SSL certificates are managed through Let's Encrypt
- Certificate path: `/etc/letsencrypt/live/microservices.appf4s.io.vn/`

### Common Headers
All proxied requests include:
- Host header preservation
- Real IP forwarding
- X-Forwarded-For for client IP tracking
- X-Forwarded-Proto for protocol information

### Health Checks
Each microservice has a dedicated health check endpoint with:
- 5-second connection timeout
- 5-second read timeout
- No authorization requirement
- Separate routing from main API endpoints

### API Endpoints
Each service's API is accessible through:
- Pattern: `/services/{service-name}/api/*`
- Full HTTPS support
- Header forwarding
- Query string preservation

## URL Structure

### Health Check URLs
- msreel: `https://microservices.appf4s.io.vn/msreel/management/health`
- MSUser: `https://microservices.appf4s.io.vn/msuser/management/health`
- MSCommentLike: `https://microservices.appf4s.io.vn/mscommentlike/management/health`
- MSNotification: `https://microservices.appf4s.io.vn/msnotification/management/health`
- MSFeed: `https://microservices.appf4s.io.vn/msfeed/management/health`

### API URLs
- msreel: `https://microservices.appf4s.io.vn/services/msreel/api/*`
- MSUser: `https://microservices.appf4s.io.vn/services/msuser/api/*`
- MSCommentLike: `https://microservices.appf4s.io.vn/services/mscommentlike/api/*`
- MSNotification: `https://microservices.appf4s.io.vn/services/msnotification/api/*`
- MSFeed: `https://microservices.appf4s.io.vn/services/msfeed/api/*`

## Security Features
1. HTTPS enforcement
2. SSL certificate management
3. Health check endpoint protection
4. No authorization header forwarding for health checks

## Maintenance Notes
1. SSL certificates are managed by Let's Encrypt
2. Health check timeouts are set to 5 seconds
3. All services are expected to be running in Docker containers
4. API Gateway handles the default route ('/') 