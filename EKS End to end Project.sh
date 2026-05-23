# installing kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO https://dl.k8s.io/release/v1.36.0/bin/linux/amd64/kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
# installing Eksctl
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz"
tar -xzf eksctl_*.tar.gz
sudo mv eksctl /usr/local/bin
eksctl version
# installing Aws cli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
# configuring Aws cli
aws configure
# updating kube config file
aws eks update-kubeconfig --name sai-cluster --region us-east-1
# Creatting fargate profile
eksctl create fargateprofile     --cluster sai-cluster     --region us-east-1     --name alb-sample-app     --namespace game-2048
# creating namespace, deployment, service, Ingress resources
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/examples/2048/2048_full.yaml
# Creating Cluster
eksctl create cluster --name sai-cluster --region us-east-1 --fargate
# congiure OIDC provider for IAM connection ( identity provide) so ALB controller can interact with AWs resources 
eksctl utils associate-iam-oidc-provider --cluster sai_cluster --approve
#Download IAM policy
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.11.0/docs/install/iam_policy.json
#create Iam policy
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json
# Create Service Account for IAM role
eksctl create iamserviceaccount   --cluster=sai-cluster   --namespace=kube-system   --name=aws-load-balancer-controller   --role-name AmazonEKSLoadBalancerControllerRole   --attach-policy-arn=arn:aws:iam::673725944212:policy/AWSLoadBalancerControllerIAMPolicy   --approve
# Deploy ALB controller, add helm repo
helm repo add eks https://aws.github.io/eks-charts
# update the helm repo
helm repo update eks
# Install AWS Load balancer controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
  --set clusterName=<your-cluster-name> \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=<your-region> \
  --set vpcId=<your-vpc-id>
  # Verify that the deployments are running.
  kubectl get deployment -n kube-system aws-load-balancer-controller

  eksctl delete cluster --name sai-cluster --region us-east-1

