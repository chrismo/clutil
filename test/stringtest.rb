require_relative '../cl/util/string'
require 'minitest/autorun'

class TestUtilString < MiniTest::Test
  def test_here_ltrim
    test = <<-TEST
      This is a test of the here_ltrim function.
      Its purpose is to shift this whole paragraph to the left, removing
      the indention.
    TEST

    expected = <<-EXP
This is a test of the here_ltrim function.
Its purpose is to shift this whole paragraph to the left, removing
the indention.
    EXP
  
    assert_equal(expected, here_ltrim(test))
  end

  def test_here_ltrim_indent
    test = <<-TEST
      This is a test of the here_ltrim function.
      Its purpose is to shift this whole paragraph to the left, removing
      the indention.
    TEST

    expected = <<-EXP
  This is a test of the here_ltrim function.
  Its purpose is to shift this whole paragraph to the left, removing
  the indention.
    EXP
  
    assert_equal(expected, here_ltrim(test, 2))
  end
  
  def test_indent
    # NOTE: empty lines are not indented - they are ignored
  
    s = "hey\nhey\n\n"
    s = indent(s, 2)
    assert_equal("  hey\n  hey\n\n", s)
    s = indent(s, -1)
    assert_equal(" hey\n hey\n\n", s)
    s = indent(s, -3)
    assert_equal("hey\nhey\n\n", s)
  end

  def test_rbpath
    assert_equal('c:/temp/dir', "c:\\temp\\dir".rbpath)
  end

  def test_winpath
    assert_equal('c:\\temp\\dir', "c:/temp/dir".winpath)
  end
end
