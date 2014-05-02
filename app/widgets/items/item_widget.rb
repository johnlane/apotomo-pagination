class Items::ItemWidget < Apotomo::Widget

  def display(args = nil)
    if options and options[:item]
      @item = options[:item]
    elsif args and args.include? :id 
      @item = ::Item.find(args[:id])
    end 
    render
  end 

  def new
    render
  end

end
