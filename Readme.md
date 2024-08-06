## Introduction
Simple bash script that generates self signed certs and spin nginx in minikube environment.
I tried to do it as simple as possible to start, stop and delete your cluster.

Be aware that nginx itself is not configured and in that way returns: 502 Bad Gateway

After successful start command:
```minikube tunnel``` will need elevated credentials

Page is avaliable at: https://myservice.example.com/

## Requirements
- works on macos
- add this line to your /etc/hosts:

```127.0.0.1 myservice.example.com```
- needs minikube,openssl,docker and kubectl installed

## Usage
bash run.sh [start|stop|delete]
### Options
- `start`: Starts and if cluster is not configured it is do configuration - with certs preparation
- `stop`:  Stops minikube cluster
- `delete`:  Deletes minikube cluster and removes all created files

### Examples:
- bash run.sh start
- bash run.sh stop
- bash run.sh delete

# Details of the scripts

Scripts and included script with crucial function explanation 

## run.sh

Main script for starting, stopping and deleting minikube cluster. It uses preflight check for commands that are needed to execute this scripts

### function start()

- executes functions/commands:
    - preflight_checker 
    - create_certs
    - prepare_deployment 
    - prepare_ingress 
    - minikube start  
    - install_verify_ingress_controller 
    - add_cert_to_kube
    - apply_deployment
    - apply_ingress
    - minikube tunnel

## helpers/certs.sh

Script that generates certificates

### function configure_certificate()
Configure template for certificate

### function create_certs()
All commands that needed to generate cert

## helpers/kube.sh

Functions needed to spin all in minikube

### function prepare_deployment()
Template for deployment. Creates file ```nginx-service.yaml```

### function prepare_ingress()
Template for ingress. Creates file ```nginx-ingress.yaml```

### function install_verify_ingress_controller() 
Install Ingress Controller

### function add_cert_to_kube() 
Add cert to minikube 

### function apply_deployment() 
Apply deployment file

### function apply_ingress() 
Apply ingress file

## Troubleshooting
- **Issue**: Error from server (InternalError): error when creating "nginx-ingress.yaml": ...
  - **Solution**: If you get this error you need manually execute those commands:
  ```
  apply -f nginx-service.yaml -n default
  minikube tunnel
  ```
