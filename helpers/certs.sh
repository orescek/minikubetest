
function configure_certificate() { # Configure template for certificate
    echo "Configuring certificate"
    cat << EOF > $CERTSPATH/san.cnf
[ req ]
default_bits       = 2048
distinguished_name = req_distinguished_name
req_extensions     = req_ext
x509_extensions    = v3_req
prompt             = no

[ req_distinguished_name ]
countryName                 = SI
stateOrProvinceName         = Slovenia
localityName               = Ljubljana
organizationName           = myservice.example.com
commonName                 = example.com

[ req_ext ]
subjectAltName = @alt_names

[ v3_req ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1   = myservice.example.com
DNS.2   = www.myservice.example.com
EOF
}

function create_certs() { # Create certificates
    if [ ! -d "$CERTSPATH" ]; then 
        echo "Start creating certs"
        mkdir $CERTSPATH
        configure_certificate
        echo "Creating root key"
        openssl genpkey -algorithm RSA -out $CERTSPATH/ca.key # root key
        echo "Creating root cert"
        openssl req -x509 -new -nodes -key $CERTSPATH/ca.key -sha256 -days $CERTEXPIRE -out $CERTSPATH/ca.crt -config $CERTSPATH/san.cnf
        sleep 1
        echo "Creating server private key"
        openssl genpkey -algorithm RSA -out $CERTSPATH/server.key
        echo "Create the CSR"
        openssl req -new -key $CERTSPATH/server.key -out $CERTSPATH/server.csr -subj "/CN=myservice.example.com"
        sleep 1
        echo "Sign server certificate"
        openssl x509 -req -in $CERTSPATH/server.csr -CA $CERTSPATH/ca.crt -CAkey $CERTSPATH/ca.key -CAcreateserial -out $CERTSPATH/server.crt -days 365 -sha256
        sleep 1
    fi
}