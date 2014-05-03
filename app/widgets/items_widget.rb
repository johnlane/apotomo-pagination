class ItemsWidget < Apotomo::Widget

  def display
    Item.all.paginate(page: params[:page], per_page: 10).each do |i|
      self << widget('items/item', i, item: i)
    end
    render
  end

end
