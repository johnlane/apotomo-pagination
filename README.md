This is a test application used to get will_paginate working with apotomo widgets.
https://groups.google.com/forum/#!topic/cells-and-apotomo/WN6VfgDgPWo

Imagine a widget called `Items` that displays a load of items. The `Items` widget has an `Item` child widget that it used to display each item. Here we create a test application to demonstrate.

    rails new apotomo-paginate
    cd apotomo-paginate
    echo "gem 'apotomo', '1.2.4'" >> Gemfile
    bundle install
    
Generate the `Item` model and seed it with some items:

    rails generate model Item title:string
    rake db:migrate
    echo '100.times { |i| Item.create(title:"Item #{i}") }' > db/seeds.rb
    rake db:seed
    
Create the new `Item` and `Items` Widgets:

    rails generate apotomo:widget Items display
    rails generate apotomo:widget Items::Item display
    
Create the `ItemsController` as `app/controllers/items_controller.rb`:

    class ItemsController < ApplicationController
      has_widgets do |root|
        root << widget('items', :items)
        root << widget('items/item', :item)
      end 
    end  
    
Set the default route to the `index` action, in `config/routes.rb`:

    root :to => 'items#index'

Have the `index` action's view `app/views/items/index.html.erb` render the items widget:

    mkdir -p app/views/items
    echo "<%= render_widget :items %>" > app/views/items/index.html.erb
    
This renders the `items` widget's default state, `display`, which is defined in `app/widgets/items_widget.rb` and creates an `item` widget for each item:

      def display
        Item.all.each do |i|   
          self << widget('items/item', i, item: i)
        end 
        render
      end
      
Here, `items/item` is the widget, `i.id` is the item id used as a unique widget id and `item` is the item's model-object.
    
The view, `app/widgets/items/display.html.erb`, then displays those widget items:

    <%= widget_div do %>
      <% for item in children do %>
        <%= render_widget item %>
      <% end %>
    <% end %>
    
using the `item` widget's view defined in `app/widgets/items/item/display.html.erb`:

    <%= widget_div do %>
      <p><strong>Title:</strong><%= @item.title %></p>
    <% end %>

The `item#show` actions's view `app/views/items/show.html.erb` renders the item widget to display a single item:

    <%= render_widget :item, :display, id: params[:id] %>
    
Here we pass in the item's id from the params hash.

The item widget's `display` state needs to work in two ways. First, if the widget was created with an item then the item will be in the `options` hash. If not, then look for an `id` in the `args` hash and fetch that item from the database. In `app/widgets/items/item_widget.rb`:

    def display(args = nil)
      if options and options[:item]
        @item = options[:item]
      elsif args and args.include? :id 
        @item = ::Item.find(args[:id])
      end 
      render
    end 

<small>The `::` scope resolution gets to the model because the model and widget are both called `Item`.</small>

Run the app (`rails s`) and go to `http://localhost:3000`. The 100 items should be displayed.

<small>commit to git</small>

Now, add pagination. First add the *will_paginate* gem

    echo "gem 'will_paginate', '~> 3.0'" >> Gemfile
    bundle install

Change `app/widgets/items_widget.rb` to paginate:

      def display
        Item.all.paginate.each do |i|   
          self << widget('items/item', i, item: i)
        end 
        render
      end
      
Change `app/widgets/items/display.html.erb` also:

    <%= widget_div do %>
      <% for item in children do %>
        <%= will_paginate render_widget(item) %>
      <% end %>
    <% end %>

Now, re-running the application gives an error:


    undefined method `total_pages' for #<ActiveSupport::SafeBuffer:0x007f644825b378>

This happens because the `will_paginate` helper used in the view expects a *paginated collection* and `render_widget item` doesn't return a paginated collection. 

The job of the `will_paginate` helper is to generate the HTML for the pagination links, so one solution is to do that manually and this makes sense if the HTML that `will_paginage` would produce isn't suitable, which would be the case if the output needs to consider other layout or styling (e.g. [Twitter Bootstrap](http://getbootstrap.com)).

What follows is one way to implement pagination of widgets using Twitter Bootstrap's [paginator](http://getbootstrap.com/components/#pagination-default).

The first thing to do is to pass the current page and the number of pages to the view. Amend `app/widgets/items_widget.rb`:

    def display
      items = Item.all.paginate(page: params[:page], per_page: 10)
      items.each { |i| self << widget('items/item', i.id, item: i) }
      render locals: { page: params[:page], pages: items.total_pages }
    end

Next, have the view, `app/widgets/items/display.html.erb`, use that information to invoke a new `paginate` helper beneath the widgets:

    <%= paginate page: page, pages: pages %>

And, finally, write the helper in `app/widgets/items_widget.rb`:

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

This example produces HTML that works with Twitter Bootstrap. Anything could be substituted - the key point is the output is based on the current page and the number of pages.

<small>commit to git again</small>

See https://github.com/johnlane/apotomo-pagination

<small>Final note: the `paginate` helper is a private method of the `Items` widget. In a real application with multiple widgets that may need to use pagination, it may be better to put this in an [`ApplicationWidget`](https://gist.github.com/ramontayag/1101138).</small>
