require File.expand_path(File.dirname(__FILE__) + '/../install')
require 'test/unit'

class TestInstall < Test::Unit::TestCase
  def test_set_prefix
    install = CLabs::Install.new
    conf = install.get_conf({'prefix' => '/tmp/ruby'})
    assert_equal('/tmp/ruby', conf['prefix'])
    assert_equal('/tmp/ruby/lib/ruby/site_ruby', conf['sitedir'])
  end
end