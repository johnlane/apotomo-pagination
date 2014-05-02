require 'test_helper'

class ItemsWidgetTest < Apotomo::TestCase
  has_widgets do |root|
    root << widget(:items)
  end
  
  test "display" do
    render_widget :items
    assert_select "h1"
  end
end
