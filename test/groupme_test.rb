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
      expected = expected_description.gsub!('master', 'feature/branch_name')
      assert_equal expected, body['text']
      [200, {}, '']
    end

    svc.receive_push
  end

  def expected_description
    'rtomayko pushed 3 commits to grit/master - http://github.com/mojombo/grit/compare/4c8124f...a47fd41'
  end

  def service(*args)
      super Service::GroupMe, *args
  end
end
