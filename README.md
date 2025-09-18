
# ELK(Filebeat)

## Environment
1. Mac Studio (M2 Max)
2. Rancher Desktop
3. 本地 K8s 1.33 集群 (2 worker nodes)
4. 本地 Harbor 服务器 (harbor.local:80/library/order-service:latest)
5. Elastic Stack 8.17

## Plan
1. [x] 收集 非 json 格式的app日志，通过 Filebeat 收集，Logstash清洗, 并存储到 ES, 见 `plain_text` 分支
2. [x] 使用k8s代替docker compose
3. [x] 优化manifest组织结构和使用独立logging命名空间
4. [ ] json 格式的 app日志
5. [ ] 使用 sidecar 模式收集app日志
6. [ ] 收集worker node的日志
7. [ ] 收集中间件的日志
8. [ ] 使用kafka做日志缓冲

## 本地 Quick start
```shell
mvn clean package
docker compose up --build   
```

## 部署到 K8s

### 撰写 manifest
k8s的yaml manifest可以使用 `kompose` 辅助生成.

1. 针对 Filebeat, 需要删除生成的 deployment + pvc, 修改为 `daemonset`, 让 Filebeat 在每个 Node 上运行一个 Pod，读取 `/var/log/containers/*.log`（K8s 标准日志路径），并自动注入 Pod 元数据（namespace、pod name、labels）。
2. 给Filebeat准备service account, 让它可以读取Node 资源, 比如nodeName (add_kubernetes_metadata需要用到)


### 部署到k8s

```sh
$ k get nodes
NAME               STATUS   ROLES           AGE   VERSION
kubeadm-master     Ready    control-plane   74d   v1.33.4
kubeadm-worker01   Ready    <none>          66d   v1.33.4
kubeadm-worker02   Ready    <none>          66d   v1.33.4

kubectl apply -f k8s-manifest/logging -n logging
kubectl apply -f k8s-manifest/apps -n apps

$ k get po -o wide -n logging
NAME                             READY   STATUS    RESTARTS   AGE   IP             NODE               
elasticsearch-5599b96998-59fj4   1/1     Running   0          18s   10.244.1.220   kubeadm-worker01  
filebeat-2dmfz                   1/1     Running   0          18s   10.244.1.217   kubeadm-worker01 
filebeat-hjdf4                   1/1     Running   0          18s   10.244.2.164   kubeadm-worker02
kibana-d9c96cd58-xd75t           1/1     Running   0          18s   10.244.2.165   kubeadm-worker02 
logstash-757b57ff9b-dlrd4        1/1     Running   0          18s   10.244.1.218   kubeadm-worker01
```

$ k get po -o wide -n apps
NAME                            READY   STATUS    RESTARTS   AGE   IP             NODE             
order-service-59678cc76-629w5   1/1     Running   0          24s   10.244.2.166   kubeadm-worker02

### 测试

```sh
# 端口转发
kubectl port-forward svc/order-service 8081:8080 -n apps
kubectl port-forward svc/kibana 5601:5601 -n logging

# 造http请求
$ siege -c1 -d5 -t60M http://localhost:8081/order/2

# 调式 filebeat 和 logstash的配置文件 (修改cm后,删除pod才能生效)
# 不可以使用kubectl rollout restart, 因为cm的修改不会触发pod重启
$ kubectl apply -f k8s-manifest/logging
$ kubectl delete po -l k8s-pod=filebeat -n logging
$ kubectl delete po -l io.kompose.service=logstash -n logging
```