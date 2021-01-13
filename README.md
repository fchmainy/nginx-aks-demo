# K8s-name-generator

https://github.com/nginxinc/kubernetes-ingress.git

$ helm repo list
NAME     	URL
$ helm repo add nginx-stable https://helm.nginx.com/stable
"nginx-stable" has been added to your repositories

$ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "nginx-stable" chart repository
...Successfully got an update from the "f5-stable" chart repository
Update Complete. ⎈ Happy Helming!⎈

$ helm repo list
NAME        	URL
nginx-stable	https://helm.nginx.com/stable

git clone https://github.com/nginxinc/kubernetes-ingress.git
cd kubernetes-ingress.git

kubectl create namespace ingress

kubectl create secret docker-registry regcred --docker-server=registry.gitlab.com --docker-username=fchmainy@yahoo.com --docker-password=****** -n ingress

cd deployments/helm-chart/

Edit the file values.yaml and modify the key imagePullSecrets so HELM can specify to Kubernetes which credentials to use to download the container from the private registry :

  serviceAccount:
    #imagePullSecrets: []
    imagePullSecrets:
       - name: regcred

helm install nginx-ingress -f values.yaml \
--namespace ingress  \
--set controller.kind=deployment \
--set controller.replicaCount=2 \
--set controller.nginxplus=true \
--set controller.appprotect.enable=true \
--set controller.image.repository=registry.gitlab.com/f.chmainy/nginx \
--set controller.image.tag=28Oct2020 \
--set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
--set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux .


In this install command, we specify the Ingress will be:
- deployed as a deployment with 2 replicas in the “ingress” namespace
- using the nginxplus version
- approtect is enable
- image will be get from the gitlab private registry using the “28Oct2020” tag
- the ingress controller is deployed on a linux node.

the Ingress is running in its own dedicated namespace BUT The Ingress rules, however, must reside in the namespace where the app resides.

$ kubectl get pods -n ingress-nginx -w
NAME                                           READY   STATUS              RESTARTS   AGE
nginx-ingress-nginx-ingress-84bc58c7cc-mdmzf   0/1     ContainerCreating   0          27s
nginx-ingress-nginx-ingress-84bc58c7cc-rwm7t   0/1     ContainerCreating   0          27s
nginx-ingress-nginx-ingress-84bc58c7cc-mdmzf   0/1     Running             0          35s
nginx-ingress-nginx-ingress-84bc58c7cc-rwm7t   0/1     Running             0          35s

$ kubectl -n ingress-nginx get svc
NAME                          TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)                      AGE
nginx-ingress-nginx-ingress   LoadBalancer   10.0.166.135   51.136.86.83   80:32191/TCP,443:31003/TCP   117s




