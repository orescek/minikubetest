#!/bin/bash

# Define global variables if any
CERTSPATH="certs"
CERTEXPIRE=365
RETRYPODCHECK=40

#import scripts
source helpers/certs.sh
source helpers/kube.sh

function command_checkers() {
    if ! command -v openssl &> /dev/null; then
        echo "openssl command not found"
        exit 1
    fi
    if ! command -v docker &> /dev/null; then
        echo "docker command not found"
        exit 1
    fi
    if ! command -v minikube &> /dev/null; then
        echo "minikube command not found"
        exit 1
    fi
    if ! command -v kubectl &> /dev/null; then
        echo "kubectl command not found"
        exit 1
    fi
}

function preflight_checker() {
    echo "Start preflight checks"
    command_checkers
    sleep 1
    echo "Stop preflight checks"
}

function start() {
    preflight_checker # check if all required commands are available
    create_certs    # create certs
    sleep 1
    prepare_deployment # prepare deployment files
    prepare_ingress # prepare ingress files
    minikube start  # start minikube
    install_verify_ingress_controller # install and verify ingress controller
    add_cert_to_kube
    apply_deployment
    apply_ingress
    minikube tunnel # start tunnel
}

# Function to stop creating certs
function stop() {
    minikube stop  
}

function del() {
    stop
    echo "Env Cleanup"
    rm -rf $CERTSPATH
    rm -rf nginx-service.yaml
    rm -rf nginx-ingress.yaml
    minikube delete  
}

if [ $# -eq 0 ]; then
    echo "No arguments provided. Usage: $0 [start|stop|delete]"
    exit 1
fi

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    delete)
        del
        ;;
    *)
        echo "Invalid argument: $1. Usage: $0 [start|stop|delete]"
        exit 1
        ;;
esac