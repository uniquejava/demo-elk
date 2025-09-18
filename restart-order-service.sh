#!/bin/zsh
echo "deleting ..."
pkill -f "kubectl.*port-forward.*order-service" 2>/dev/null

kubectl delete -f k8s-manifest/apps

while kubectl get po -n apps -o name | grep -q "order-service"; do sleep 1; done

echo "deploying ..."
kubectl apply -f k8s-manifest/apps

echo "waiting ..."
kubectl wait --for=condition=ready pod -l k8s-app=order-service -n apps --timeout=60s

kubectl get po -n apps

echo "forwarding ..."
kubectl port-forward svc/order-service 8081:80 -n apps &

echo "testing ..."
sleep 2
siege -c1 -d5 -t2M curl http://localhost:8081/order/1