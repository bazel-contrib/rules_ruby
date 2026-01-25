# TODO: is there a ruby runfiles helper?
runfiles_dir = ENV["RUNFILES_DIR"]
if runfiles_dir
  main_root = File.join(runfiles_dir, "_main")
  $LOAD_PATH.unshift(main_root) if Dir.exist?(main_root) && !$LOAD_PATH.include?(main_root)
end

require "grpc"
require "proto/foo_pb"
require "proto/foo_services_pb"

class FooServer < Foo::FooService::Service
  def get_foo(_req, _call)
    Foo::GetFooResponse.new(name: "Hello from Bazel + Ruby gRPC server!")
  end
end

server = GRPC::RpcServer.new
server.add_http2_port("0.0.0.0:50051", :this_port_is_insecure)
server.handle(FooServer.new)
puts "gRPC server listening on 0.0.0.0:50051"
server.run_till_terminated
