
function prepare_deployment() { 
    echo "Prepare deployment"
    cat << EOF > nginx-service.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: https-daemon
  labels:
    app: https-daemon
spec:
  replicas: 1
  selector:
    matchLabels:
      app: https-daemon
  template:
    metadata:
      labels:
        app: https-daemon
    spec:
      containers:
      - name: https-daemon
        image: nginxdemos/hello:plain-text
        ports:
        - containerPort: 8443
        volumeMounts:
        - name: tls-secret
          mountPath: "/etc/nginx/certs"
          readOnly: true
      volumes:
      - name: tls-secret
        secret:
          secretName: myservice-tls
---
apiVersion: v1
kind: Service
metadata:
  name: https-service
spec:
  selector:
    app: https-daemon
  ports:
  - protocol: TCP
    port: 443
    targetPort: 8443
EOF
}

function prepare_ingress() {
    echo "Prepare ingress"
    cat << EOF > nginx-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myservice-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  namespace: default
spec:
  tls:
  - hosts:
    - '*.example.com'
    - myservice.example.com
    secretName: myservice-tls
  rules:
  - host: myservice.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: https-service
            port:
              number: 443

EOF

}

function check_pods_running() {
    while [ $RETRYPODCHECK -gt 0 ]; do
        POD_STATUSES=$(kubectl get pods -n ingress-nginx --no-headers | awk '{print $3}')
        NOT_RUNNING=$(echo "$POD_STATUSES" | grep -v "Running" | grep -v "Completed" | wc -l | awk '{print $1}')
        
        if [ "$NOT_RUNNING" -eq "0" ]; then
            echo "All pods are running."
            break
        else
            echo "Waiting for all pods to be in the Running state..."
            sleep 5
            RETRYPODCHECK=$((RETRYPODCHECK-1)) 
        fi
    done

    if [ $RETRYPODCHECK -eq 0 ]; then
        echo "Not all pods are in the Running state after the maximum retries."
        exit 1
    fi
}

function install_verify_ingress_controller() {
    echo "Install Ingress Controller"
    minikube addons enable ingress
    check_pods_running
}

function add_cert_to_kube() {
    echo "Add cert to kube"
    kubectl create secret tls myservice-tls --cert=certs/server.crt --key=certs/server.key -n default
    sleep 1
}

function apply_deployment() {
    echo "Apply deployment"
    kubectl apply -f nginx-service.yaml -n default
    kubectl rollout status deployment/https-daemon -n default
    kubectl wait --for=condition=available --timeout=600s deployment/https-daemon -n default
    sleep 5
}

function apply_ingress() {
    echo "Apply ingress"
    kubectl apply -f nginx-ingress.yaml -n default
    if [ $? -eq 0 ]; then
        echo "Successfully retrieved ingress details."
    else
        sleep 10
        kubectl apply -f nginx-ingress.yaml -n default
        if [ $? -ne 0 ]; then
            echo "Failed to apply ingress on retry. Exiting."
            return 1
        fi
    fi
    while true; do
        ADDRESS=$(kubectl get ingress myservice-ingress -n default -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        if [[ -n $ADDRESS ]]; then
            echo "Ingress is now available at IP: $ADDRESS"
            break
        else
            echo "Waiting for ingress to become available..."
            sleep 5
        fi
    done
}

function minicube_start() { 
    minikube start
}
