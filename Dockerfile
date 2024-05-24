# Start with an appropriate base image
FROM redhat/ubi8:latest

LABEL org.opencontainers.image.source="https://github.com/lucifergene/gitea-installer-openshift"

# Set the maintainer label
LABEL maintainer="akundu@redhat.com"

WORKDIR /home/dev

ENV NAMESPACE="gitea" \
    USERNAME="dev" \
    PASSWORD="123456" \
    EMAIL="dev@openshift.com" \
    SAMPLE_REPOS_DIR="/home/dev/gitea-samples"

# Install required packages
RUN dnf update -y && \
    dnf install -y openssl wget git sudo && \
    dnf clean all && \
    git config --global user.name "dev" && \
    git config --global user.email "dev@openshift.com"

# Install Helm
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
    chmod 700 get_helm.sh && \
    ./get_helm.sh && \
    rm -f get_helm.sh

# Install Kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

# Install OpenShift CLI
RUN wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz && \
    tar -xvzf openshift-client-linux.tar.gz && \
    mv oc /usr/local/bin/ && \
    rm -f openshift-client-linux.tar.gz

# Install Tea CLI
RUN wget https://dl.gitea.com/tea/0.9.2/tea-0.9.2-linux-amd64 -O /usr/local/bin/tea && \
    chmod +x /usr/local/bin/tea

# Copy the bash script into the container
COPY gitea-install.sh /home/dev/gitea-install.sh

# Make the script executable
RUN chmod +x /home/dev/gitea-install.sh

# CMD to run the script
CMD ./gitea-install.sh
