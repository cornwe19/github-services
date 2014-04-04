require File.expand_path('../helper', __FILE__)

class GroupMeTest < Service::TestCase

  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @data  = {'bot_id' => 'bot123'}
  end

  def test_push
    svc = service :push, @data

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

    svc.payload.merge!({'ref' => 'refs/heads/feature/branch_name'})

    @stubs.post "/v3/bots/post" do |env|
      body = JSON.parse(env[:body])
      assert_equal expected_description(branch: 'feature/branch_name'), body['text']
      [200, {}, '']
    end

    svc.receive_push
  end

  def expected_description(commits: 3, branch: 'master')
    'rtomayko pushed %d commits to grit/%s - http://git.io/RXtyug
 - stub git call for Grit#heads test f:15 Case#1
 - clean up heads test f:2hrs
 - add more comments throughout' % [ commits, branch ]
  end

  def service(*args)
      svc = super(Service::GroupMe, *args)

      class << svc
        def shorten_url(*args)
          'http://git.io/RXtyug'
        end
      end

      svc
  end
end
