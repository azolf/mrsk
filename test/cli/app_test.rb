require_relative "cli_test_case"

class CliAppTest < CliTestCase
  test "boot" do
    # Stub current version fetch
    SSHKit::Backend::Abstract.any_instance.stubs(:capture)
      .returns("999") # new version
      .then
      .returns("123") # old version

    run_command("boot").tap do |output|
      assert_match "docker run --detach --restart unless-stopped", output
      assert_match "docker container ls --all --filter name=app-123 --quiet | xargs docker stop", output
    end
  end

  test "boot will reboot if same version is already running" do
    run_command("details") # Preheat MRSK const

    # Prevent expected failures from outputting to terminal
    Thread.report_on_exception = false

    MRSK.app.stubs(:run)
      .raises(SSHKit::Command::Failed.new("already in use"))
      .then
      .raises(SSHKit::Command::Failed.new("already in use"))
      .then
      .returns([ :docker, :run ])

    run_command("boot").tap do |output|
      assert_match "Rebooting container with same version 999 already deployed", output # Can't start what's already running
      assert_match "docker container ls --all --filter name=app-999 --quiet | xargs docker container rm", output # Stop old running
      assert_match "docker container ls --all --filter name=app-999 --quiet | xargs docker container rm", output # Remove old container
      assert_match "docker run", output # Start new container
    end
  ensure
    Thread.report_on_exception = true
  end

  test "start" do
    run_command("start").tap do |output|
      assert_match "docker start app-999", output
    end
  end

  test "stop" do
    run_command("stop").tap do |output|
      assert_match "docker ps --quiet --filter label=service=app | xargs docker stop", output
    end
  end

  test "details" do
    run_command("details").tap do |output|
      assert_match "docker ps --filter label=service=app", output
    end
  end

  test "exec" do
    run_command("exec", "ruby -v").tap do |output|
      assert_match "ruby -v", output
    end
  end

  test "exec with reuse" do
    run_command("exec", "--reuse", "ruby -v").tap do |output|
      assert_match "docker ps --filter label=service=app --format \"{{.Names}}\" | sed 's/-/\\n/g' | tail -n 1", output # Get current version
      assert_match "docker exec app-999 ruby -v", output
    end
  end

  test "containers" do
    run_command("containers").tap do |output|
      assert_match "docker container ls --all --filter label=service=app", output
    end
  end

  test "images" do
    run_command("images").tap do |output|
      assert_match "docker image ls dhh/app", output
    end
  end

  test "logs" do
    SSHKit::Backend::Abstract.any_instance.stubs(:exec)
      .with("ssh -t root@1.1.1.1 'docker ps --quiet --filter label=service=app | xargs docker logs --timestamps --tail 10 2>&1'")

    assert_match "docker ps --quiet --filter label=service=app | xargs docker logs --tail 100 2>&1", run_command("logs")
  end

  test "logs with follow" do
    SSHKit::Backend::Abstract.any_instance.stubs(:exec)
      .with("ssh -t root@1.1.1.1 'docker ps --quiet --filter label=service=app | xargs docker logs --timestamps --tail 10 --follow 2>&1'")

    assert_match "docker ps --quiet --filter label=service=app | xargs docker logs --timestamps --tail 10 --follow 2>&1", run_command("logs", "--follow")
  end

  test "remove" do
    Mrsk::Cli::App.any_instance.expects(:stop)
    Mrsk::Cli::App.any_instance.expects(:remove_containers)
    Mrsk::Cli::App.any_instance.expects(:remove_images)

    run_command("remove")
  end

  test "remove_container" do
    run_command("remove_container", "1234567").tap do |output|
      assert_match "docker container ls --all --filter name=app-1234567 --quiet | xargs docker container rm", output
    end
  end

  test "remove_containers" do
    run_command("remove_containers").tap do |output|
      assert_match "docker container prune --force --filter label=service=app", output
    end
  end

  test "remove_images" do
    run_command("remove_images").tap do |output|
      assert_match "docker image prune --all --force --filter label=service=app", output
    end
  end

  test "version" do
    run_command("version").tap do |output|
      assert_match "docker ps --filter label=service=app --format \"{{.Names}}\" | sed 's/-/\\n/g' | tail -n 1", output
    end
  end

  private
    def run_command(*command)
      stdouted { Mrsk::Cli::App.start([*command, "-c", "test/fixtures/deploy_with_accessories.yml"]) }
    end
end
