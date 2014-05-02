class ItemsController < ApplicationController
  has_widgets do |root|
    root << widget('items', :items)
    root << widget('items/item', :item)
  end 
end  
