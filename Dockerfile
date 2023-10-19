FROM alpine:latest

RUN apk --no-cache add curl

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

# Create a script to retrieve the replica count
RUN echo '#!/bin/sh' > /get_replica_count.sh
RUN echo 'replicas=$(kubectl get cloneset -n default)' >> /get_replica_count.sh
RUN echo 'echo "Replica Count: $replicas"' >> /get_replica_count.sh
RUN chmod +x /get_replica_count.sh