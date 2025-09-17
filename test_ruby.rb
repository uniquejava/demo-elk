# test_ruby.rb
require 'json'

event = {
  "kubernetes" => {
    "namespace_labels" => { "kubernetes_io/metadata_name" => "default" },
    "namespace_uid" => "a3a96767-ec25-47dd-a712-c72e837d4969",
    "replicaset" => { "name" => "order-service-59678cc76" },
    "node" => {
      "labels" => { "kubernetes_io/arch" => "arm64" },
      "uid" => "9aeedfd8-05da-41dd-80c6-43529d6527b4",
      "hostname" => "kubeadm-worker02"
    },
    "namespace" => "default",
    "pod" => { "name" => "order-service-59678cc76-hzsb9", "ip" => "10.244.2.157" },
    "labels" => { "filebeat_enable" => "true", "io_kompose_service" => "order-service" }
  }
}

# 保留 kubernetes 顶层，但删除其内部冗余字段
%w[ namespace_labels namespace_uid replicaset node.labels node.uid node.hostname ].each do |path|
  # 按点分路径递归删除
  keys = path.split('.')
  obj = event['kubernetes']
  keys[0...-1].each { |k| obj = obj[k] if obj.is_a?(Hash) }
  if obj && obj.is_a?(Hash)
    obj.delete(keys.last)
  end
end

puts JSON.pretty_generate(event)