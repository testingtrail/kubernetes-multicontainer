docker build -t qaguy/multi-client:latest -t qaguy/multi-client:$SHA -f ./client/Dockerfile ./client
docker build -t qaguy/multi-server:latest -t qaguy/multi-server:$SHA -f ./server/Dockerfile ./server
docker build -t qaguy/multi-worker:latest -t qaguy/multi-worker:$SHA -f ./worker/Dockerfile ./worker

docker push qaguy/multi-client:latest
docker push qaguy/multi-server:latest
docker push qaguy/multi-worker:latest

docker push qaguy/multi-client:$SHA
docker push qaguy/multi-server:$SHA
docker push qaguy/multi-worker:$SHA

kubectl apply -f k8s
kubectl set image deployments/server-deployment server=qaguy/multi-server:$SHA
kubectl set image deployments/client-deployment client=qaguy/multi-client:$SHA
kubectl set image deployments/worker-deployment worker=qaguy/multi-worker:$SHA
