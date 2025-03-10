'''
Mixtral_tpu_tutorial


This version is not using any of apples weird settings
'''


export PROJECT_ID=tpu-prod-env-one-vm

gcloud config set project $PROJECT_ID
export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format="value(projectNumber)") && \
export CLUSTER_NAME=remyw-mixtral-tpu && \
export ZONE=us-east5-b && \
export HF_TOKEN=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 && \
export CLUSTER_VERSION=1.31.5-gke.1023000 && \
export GSBUCKET=remyw-test1 && \
export KSA_NAME=630405687483-compute@developer.gserviceaccount.com && \
export NAMESPACE=default \
export IMAGE_NAME='docker.io/vllm/vllm-tpu:2e33fe419186c65a18da6668972d61d7bbc31564'


gcloud container clusters create-auto $CLUSTER_NAME \
    --cluster-version=$CLUSTER_VERSION

#config kubectl to communicate with cluster
gcloud container clusters get-credentials $CLUSTER_NAME --location=$ZONE

# create k8 secret
kubectl create secret generic hf-secret \
    --from-literal=hf_api_token=$HUGGING_FACE_TOKEN \
    --namespace NAMESPACE


#deploy the app 
kubectl apply -f deployment.yaml

kubectl logs -f -l app=vllm-tpu 