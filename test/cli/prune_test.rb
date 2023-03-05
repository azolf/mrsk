require_relative "cli_test_case"

class PruneTest < CliTestCase
  test "prune images" do
    run_command('images').tap do |o|
      assert_match /docker image prune --all --force --filter label=service=app --filter until=168h on 1.1.1.2/, o
      assert_match /docker image prune --all --force --filter label=service=app --filter until=168h on 1.1.1.1/, o
    end
  end

  test "prune containers" do
    run_command('containers').tap do |o|
      assert_match /docker container prune --force --filter label=service=app --filter until=72h on 1.1.1.1/, o
      assert_match /docker container prune --force --filter label=service=app --filter until=72h on 1.1.1.2/, o
    end
  end

  test "prune all" do
    run_command('all').tap do |o|
      assert_match /docker container prune --force --filter label=service=app --filter until=72h on 1.1.1.1/, o
      assert_match /docker container prune --force --filter label=service=app --filter until=72h on 1.1.1.2/, o
      assert_match /docker image prune --all --force --filter label=service=app --filter until=168h on 1.1.1.2/, o
      assert_match /docker image prune --all --force --filter label=service=app --filter until=168h on 1.1.1.1/, o
    end
  end

  private

  def run_command(*command)
    stdouted { Mrsk::Cli::Prune.start([*command, "-c", "test/fixtures/deploy_with_accessories.yml"]) }
  end
end
