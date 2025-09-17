
# ELK(Filebeat)

## Environments
1. Mac studio
2. Rancher Desktop
3. ES 8.x

## Plan
1. [x] 收集 非 json 格式的app日志，通过 Filebeat 收集，Logstash清洗, 并存储到 ES
2. [ ] json 格式的 app日志
3. [ ] 使用k8s代替docker compose
4. [ ] 收集worker node的日志
5. [ ] 收集中间件的日志
6. [ ] 加入kafka做日志缓冲

## Quick start
```shell
mvn clean package
docker compose up --build   
```
