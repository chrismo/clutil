require_relative '../cl/util/install'
require 'minitest/autorun'

class TestInstall < MiniTest::Test
  def test_set_prefix
    install = CLabs::Install.new
    conf = install.get_conf({'prefix' => '/tmp/ruby'})
    assert_equal('/tmp/ruby', conf['prefix'])
    assert_equal('/tmp/ruby/lib/ruby/site_ruby', conf['sitedir'])
  end
end
