class ItemsWidget < Apotomo::Widget

  def display
    items = Item.all.paginate(page: params[:page], per_page: 10)
    items.each { |i| self << widget('items/item', i, item: i) }
    render locals: { page: params[:page], pages: items.total_pages }
  end

  private
  def paginate(args)
    page = args[:page] ? args[:page].to_i : 1
    pages = args[:pages] ? args[:pages].to_i : 1

    first_css = %{class="disabled"} if page == 1
    last_css  = %{class="disabled"} if page == pages

    links = %{<ul class="pagination">\n}
    links << %{  <li #{first_css}><a href="#{url_for}">&laquo;</a></li>\n}
    1.upto pages do |p|
      current_css = %{class="active"} if p == page
      links << %{  <li #{current_css}><a href="#{url_for(params.merge({page: p}))}">#{p}</a></li>\n}
    end
    links << %{  <li #{last_css}><a href="#{url_for}?page=#{pages}">&raquo;</a></li>\n}
    links << %{</ul>\n}

    links.html_safe

  end
  helper_method :paginate

end
