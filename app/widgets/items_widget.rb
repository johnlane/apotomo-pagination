class ItemsWidget < Apotomo::Widget

  def display
    Item.all.each do |i|
      self << widget('items/item', i, item: i)
    end
    render
  end

end
