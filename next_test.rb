require 'minitest/autorun'

class NextVsReturnTest < Minitest::Test
  def setup
    @series = ['1','3','a','fdsf','d','DFDF','fg','43','3','1','Adf']
    @series_filtered = ['1','3','3','1']
  end

  def test_select_works_like_in_the_tapa
    result = @series.select { |x|
      next false if x.length > 1
      next true if x =~ /^\d+/
      next false if x=~ /^[A-Z]/
    }
    assert_equal(@series_filtered, result)
  end

  def test_it_does_not_matter_if_the_proc_is_passed_as_a_variable
    filter = proc { |x|
      next false if x.length > 1
      next true if x =~ /^\d+/
      next false if x=~ /^[A-Z]/
    }
    result = @series.select &filter
    assert_equal(@series_filtered, result)
  end
  
  def test_next_from_a_lambda_works
    filter = lambda { |x|
      next false if x.length > 1
      next true if x =~ /^\d+/
      next false if x=~ /^[A-Z]/
    }
    result = @series.select &filter
    assert_equal(@series_filtered, result)
  end
  
  def test_return_from_a_lambda_works
    filter = lambda { |x|
      return false if x.length > 1
      return true if x =~ /^\d+/
      return false if x=~ /^[A-Z]/
    }
    result = @series.select &filter
    assert_equal(@series_filtered, result)
  end

  def test_return_in_a_proc_is_a_delayed_return_for_its_parent_method
    filter = proc { |x|
      return false if x.length > 1
      return true if x =~ /^\d+/
      return false if x=~ /^[A-Z]/
    }
    assert "this line of code runs"
    result = @series.select &filter
    
    # this code never runs because the proc was executed, and the return returned out of this method
    refute "this line of code runs"
    assert false
  end
  
  def filter_with_proc(array, &proc)
    return array.select &proc
  end
    
  def test_return_in_a_proc_will_return_from_its_defining_method_even_if_another_method_executes_it
    assert "this code runs"
    code_to_filter = proc  { |x|
      return false if x.length > 1
      return true if x =~ /^\d+/
      return false if x=~ /^[A-Z]/
    }
    assert "this code also runs"
    result = @series.select &code_to_filter

    # this code never runs because the proc was executed, and the return returned out of this method
    refute "this code runs"
    refute true
  end

  class Tester
    def initialize
      @lambda = lambda { |x|
        return false if x.length > 1
        return true if x =~ /^\d+/
        return false if x=~ /^[A-Z]/
      }
      @proc = proc  { |x|
        return false if x.length > 1
        return true if x =~ /^\d+/
        return false if x=~ /^[A-Z]/
      }
    end
    
    def filter_with_lambda(array)
      array.select &@lambda
    end

    def filter_with_proc(array)
      array.select &@proc
    end

  end

  def test_return_in_a_lambda_in_another_class_works
    tester = Tester.new
    result = tester.filter_with_lambda(@series)
    assert_equal(@series_filtered, result)
  end

  def test_return_in_a_proc_in_another_class_is_a_problem
    tester = Tester.new
    assert_raises(LocalJumpError) { result = tester.filter_with_proc(@series)}
  end
end
