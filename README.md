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


    Started GET "/" for 127.0.0.1 at 2014-05-02 17:31:37 +0100
    ActiveRecord::SchemaMigration Load (0.1ms)  SELECT "schema_migrations".* FROM "schema_migrations"
    Processing by ItemsController#index as HTML
      Rendered items/index.html.erb within layouts/application (6.0ms)
    Completed 500 Internal Server Error in 14ms

    ActionView::Template::Error (wrong number of arguments (0 for 1)):
        1: <%= render_widget :items %>
      app/widgets/items_widget.rb:4:in `display'
      app/views/items/index.html.erb:1:in `_app_views_items_index_html_erb___911052419021587489_29390760'

<small>commit to git again</small>



