
# ELK(Filebeat)

## Environment
1. Mac Studio (M2 Max)
2. Rancher Desktop
3. 本地 K8s 1.33 集群 (2 worker nodes)
4. 本地 Harbor 服务器 (harbor.local:80/library/order-service:latest)
5. ES 8.x

## Plan
1. [x] 收集 非 json 格式的app日志，通过 Filebeat 收集，Logstash清洗, 并存储到 ES
2. [ ] json 格式的 app日志
3. [ ] 使用k8s代替docker compose
4. [ ] 使用 sidecar 模式收集app日志
5. [ ] 收集worker node的日志
6. [ ] 收集中间件的日志
7. [ ] 使用kafka做日志缓冲

## Quick start
```shell
mvn clean package
docker compose up --build   
```

## K8s
k8s的yaml manifest可以使用 `kompose` 辅助生成.

1. 针对 Filebeat, 需要删除生成的 deployment + pvc, 修改为 daemon-set, 让 Filebeat 在每个 Node 上运行一个 Pod，读取 `/var/log/containers/*.log`（K8s 标准日志路径），并自动注入 Pod 元数据（namespace、pod name、labels）。
2. 给它准备sa, 让它可以读取Node 资源, 比如nodeName (add_kubernetes_metadata需要用到)

在 filebeat 的配置文件中添加了 add_kubernetes_metadata 处理器后，Filebeat 将为每个日志事件添加以下元数据字段：

    kubernetes.container.name：容器名称。
    kubernetes.pod.name：Pod 名称。
    kubernetes.namespace：命名空间。
    kubernetes.labels：标签。


部署到k8s:

```sh
kubectl apply -f k8s-manifest
kubectl port-forward svc/order-service 8081:8080
kubectl port-forward svc/kibana 5601:5601
```

测试

```sh
$ k get po -o wide
NAME                             READY   STATUS    RESTARTS   AGE     IP             NODE              
elasticsearch-5599b96998-pg2ff   1/1     Running   0          5m29s   10.244.1.170   kubeadm-worker01 
filebeat-hhckt                   1/1     Running   0          5m29s   10.244.2.138   kubeadm-worker02
filebeat-tnlhn                   1/1     Running   0          5m29s   10.244.1.167   kubeadm-worker01
kibana-d9c96cd58-6ltbt           1/1     Running   0          5m29s   10.244.2.137   kubeadm-worker02
logstash-757b57ff9b-sw82n        1/1     Running   0          5m29s   10.244.1.168   kubeadm-worker01
order-service-59678cc76-7qlv9    1/1     Running   0          5m11s   10.244.2.139   kubeadm-worker02

$ siege -c1 -d5 -t60M http://localhost:8081/order/2

# 注意如果修改了cm,删除pod才会生效
$ kubectl apply -f k8s-manifest
$ kubectl delete po -l k8s-pod=filebeat
$ kubectl delete po -l  io.kompose.service=logstash
```