#!/usr/bin/env ruby
# Test that the gRPC app starts and can process a GetFoo RPC.

runfiles_dir = ENV["RUNFILES_DIR"]
if runfiles_dir
  main_root = File.join(runfiles_dir, "_main")
  $LOAD_PATH.unshift(main_root) if Dir.exist?(main_root) && !$LOAD_PATH.include?(main_root)
  proto_root = File.join(main_root, "proto")
  $LOAD_PATH.unshift(proto_root) if Dir.exist?(proto_root) && !$LOAD_PATH.include?(proto_root)
end

require "grpc"
require "proto/foo_pb"
require "proto/foo_services_pb"

class FooServer < Foo::FooService::Service
  def get_foo(_req, _call)
    Foo::GetFooResponse.new(name: "Hello from Bazel + Ruby gRPC server!")
  end
end

port = 50_052
server = GRPC::RpcServer.new
server.add_http2_port("0.0.0.0:#{port}", :this_port_is_insecure)
server.handle(FooServer.new)
server_thread = Thread.new { server.run }

# Wait for server to bind
sleep 1

begin
  stub = Foo::FooService::Stub.new("localhost:#{port}", :this_channel_is_insecure)
  req = Foo::GetFooRequest.new(empty: Google::Protobuf::Empty.new)
  resp = stub.get_foo(req)
  expected = "Hello from Bazel + Ruby gRPC server!"
  if resp.name != expected
    warn "expected name #{expected.inspect}, got #{resp.name.inspect}"
    exit 1
  end
  puts "OK: GetFoo RPC returned expected response"
ensure
  server.stop
  server_thread.join(timeout = 5)
end
