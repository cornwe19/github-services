require File.expand_path('../helper', __FILE__)

class GroupMeTest < Service::TestCase

  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @data  = {'bot_id' => 'bot123'}
  end

  def test_push
    svc = service :push, @data

    stub_payload svc.payload

    @stubs.post "/v3/bots/post" do |env|
      assert_equal 'api.groupme.com', env[:url].host

      body = JSON.parse(env[:body])
      assert_equal expected_description, body['text']
      assert_equal 'bot123', body['bot_id']
      [200, {}, '']
    end

    svc.receive_push
  end

  # Limit commit summary to 3 messages
  def test_push_4_commits
    svc = service :push, @data

    stub_payload svc.payload

    svc.payload['commits'].push({'message' => 'one more commit'})

    @stubs.post "/v3/bots/post" do |env|
      body = JSON.parse(env[:body])
      assert_equal expected_description(commits: 4), body['text']
      [200, {}, '']
    end

    svc.receive_push
  end

  def test_push_no_bot_id
    svc = service :push, @data.except('bot_id')

    assert_raise Service::ConfigurationError do
      svc.receive_push
    end
  end

  # Assure branch name parsing works with branch hierarchies
  def test_push_branch_heirarchy
    svc = service :push, @data

    stub_payload svc.payload

    svc.payload['ref'] = 'refs/heads/feature/branch_name'

    @stubs.post "/v3/bots/post" do |env|
      body = JSON.parse(env[:body])
      assert_equal expected_description(branch: 'feature/branch_name'), body['text']
      [200, {}, '']
    end

    svc.receive_push
  end

  def expected_description(commits: 3, branch: 'master', first_commit: 'first')
    'user pushed %d commits to repo/%s - http://git.io/hash
 - %s
 - second
 - third' % [ commits, branch, first_commit ]
  end

  def stub_payload payload
    payload['commits'] = [
      {'message' => 'first'},
      {'message' => 'second'},
      {'message' => 'third'}
    ]
    payload['ref'] = 'refs/heads/master'
    payload['repository'] = {'name' => 'repo'}
    payload['pusher'] = {'name' => 'user'}
  end

  def service(*args)
      svc = super(Service::GroupMe, *args)

      class << svc
        def shorten_url(*args)
          'http://git.io/hash'
        end
      end

      svc
  end
end
