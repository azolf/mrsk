require_relative "cli_test_case"

class ServerTest < CliTestCase
  test "bootstrap" do
    run_command('bootstrap').tap do |o|
      assert_match /which docker \|\| \(apt\-get update \-y \&\& apt\-get install docker.io \-y/, o
      assert_match /on 1.1.1.1/, o
      assert_match /on 1.1.1.2/, o
      assert_match /on 1.1.1.3/, o
      assert_match /on 1.1.1.4/, o
    end
  end

  private

  def run_command(*command)
    stdouted { Mrsk::Cli::Server.start([*command, "-c", "test/fixtures/deploy_with_accessories.yml"]) }
  end
end
