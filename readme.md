KUBERNETES USING MULTI CONTAINER PROJECT
========================================

1 Background
-------------

We are going to use the multi container project created in here https://github.com/testingtrail/Docker_multicontainers and we are going to use Kubernetes to scale that app, once we have it in our development environment then we will move it to a cloud service such as AWS or Google cloud every time there is a change in the CI/CD workflow using Github/Travis

![Image description](images/image1.png)

So we are going to clone the files in that repo and we are going to use them in another new repo that is going to be kubernetes focused rather than just containers.

2 Setting up the config files
----------------------------

1. clone the repo https://github.com/testingtrail/Docker_multicontainers

2. run 'docker-compose up --build' to rebuild the images. (just to make sure everything works, stop the containers and run 'docker-compose biuld' again) **we are going to run it ust to make sure it is running**

3. go to localhost:3050 and test the app 

4. Delete following files as we are going to depend upon Kubertenes for deployment
    - docker-compose.yaml
    = Dockerrun.aws.json
    - .travis.yml (we are going to creater a new one later)
    - nginx server (we are going to rely on other thin)

5. Create folder K8s which will have all we need regarding configuration files starting with **client files (react app)**
    - create 'client-deployment.yaml' (for the client image)
    - create 'client-cluster-ip-service.yaml' (cluster ip service for muilti-client pods)

6. Load up both config file just to make sure we are ok so far. **There is a shorcut to apply a group of config files:**
    - 'kubectl apply -f k8s' by just putting the folder
    - Run 'kubectl get deployments' you will see 3 as we are creating 3 replicas in the file

7. **Adding config files for server (the Express API)**
    - Add file 'server-deployment.yaml' for the multi-server image
    - create 'server-cluster-ip-service.yaml' (cluster ip service for muilti-server pods)

8. **Adding config files for worker (the one that calculates the fibonacci)**
    - Add file 'worker-deployment.yaml' for the multi-worker image
    - There is nothing in the worker that needs to be accesible for anything else in the cluster so there is no cluster ip service.
    - Run ' kubectl apply -f k8s' to apply all the config files to add the new ones. By now you will have something like this
    
    ![Image description](images/image2.png)

9. **Adding redis config files**
    - Add file 'redis-deployment.yaml' for the redis container
    - create 'redis-cluster-ip-service.yaml' (cluster ip service for redis pod)
    - Run ' kubectl apply -f k8s' to apply all the config files to add the new ones.

10. **Adding postgres config files**
    - Add file 'postgres-deployment.yaml' for the redis container
    - create 'postgres-cluster-ip-service.yaml' (cluster ip service for redis pod)
    - Run ' kubectl apply -f k8s' to apply all the config files to add the new ones.

3 Volumes and Databases
------------------------

We are going to see what Postgres PVC (persistent volume claim) is and why we need it. Postres container contains a file system where it writes data each time it receives a request to do it. But, if the POD crashes of course kubernetes is going to create a new pod with postgres but the data **is NOT going to be carried over** so we need a volume to store the data on host machine. **But in this case it will work fine with just 1 replica, as 2 or more replicas writing to the same volume is a recipe for disaster.**


![Image description](images/image3.png)

So we have to put a config file for this (a PVC adversites the possible options you may have for volumes)

1. Creater file 'database-persistent-volume-claim.yaml'

2. If you hit 'kubectl get storageclass' in terminal, it will let you know all the options kubernetes has to storage data in a persistent volume. For cloud there are many options for storage classes [here](https://kubernetes.io/docs/concepts/storage/storage-classes/)

3. Link the PVC with the template in the POD for postgres by updating 'postgres-deployment.yaml' in the template section. The volume section in spec allocates the space and the config inside the container section use it. 

4. Apply it: Run 'kubectl apply -f k8s'

3 Defining environment variables
--------------------------------

Remember we need to set environment variables for two of the containers. 

![Image description](images/image4.png)

1. We are going to set up all the environment variables (except PGPASSWORD)
    - Update 'worker-deployment.yaml' (env section)
    - Update 'server-deployment.yaml' (env section)

2. For the **PGPASSWORD** we are going to use a secret object. To create you do not use a config file but running an **imperative command** (to avoid typing a password in a config file)
    - Run 'kubectl create secret generic pgpassword --from-literal PGPASSWORD=12345pg'
    - Run 'kubectl get secrets' to see if that was created

3. Add the secret to our 'server-deployment.yaml' (using valueFrom to get it from the secrets object called pgpassword)

4. We need to update also 'postgres-deployment.yaml' so postgres know what is the password of the database, that is store in the secret object. As default the postgres container will use that variable called POSTGRES_PASSWORD to overwrite the password
    - Apply changes 'kubectl apply -f k8s'

4 using an ingress server
-------------------------

**we are going to be using ingress-ngix, a community led project** There is a separate project called kubernetes-ingress that is lead by Nginx company, **we are not going to use that one!** using a config file it will create an ingress controller to control the traffic to the outside world to your services for server and client (to your cluster-ip-services)

![Image description](images/image5.png)

1. Go to https://github.com/kubernetes/ingress-nginx and go to documentation https://kubernetes.github.io/ingress-nginx/

2. Look for the mandatory command for kubectl or minikube (depending on which you are working on) and run that mandatory command.

3.  Verify the service was enabled by running the following: 'kubectl get svc -n ingress-nginx'

4. Creating the ingress configutation (routing rules)
    - Create 'ingress-service.yaml' ('kubernetes.io/ingress.class: inginx' this will tell our ingress service will be bases on nginx kubernetes project and 'nginx.ingress.kubernetes.io/rewrite-target: /$1' tells that if it finds /api just convert it to /)
    - Apply it: 'kubectl apply -f k8s'

5. Testing it (if using minikube rune 'minikube ip' to get the ip). Go to https://localhost:80 (ingress creates in port 80 or 443 by default), **it has to be https**
    - APP should be working as expected!!!


4 Setting up Docker'desktop kubernetes dashboard
-----------------------------------------------

**Applies only for docker's desktop kubernetes version**

1. Go to https://github.com/kubernetes/dashboard

2. run the following in your directory curl -O https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml

3. Open up the downloaded file in your code editor and find line 116. Add the following two lines underneath --auto-generate-certificates
    - --enable-skip-login
    - --disable-settings-authorizer

4. Run the following command inside the directory where you downloaded the dashboard yaml file 'kubectl apply -f kubernetes-dashboard.yaml'

5. Start the server by running the following command: 'kubectl proxy'

6. Access the dashboard: http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/
    - You will be presented with a login screen
    - Click the "SKIP" link next to the SIGN IN button.
    - **if you are not entering click quickly on the + symbol and then you will be inside**