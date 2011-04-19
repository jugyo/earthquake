
module Earthquake
  module Update
    def update_filters
      @update_filters ||= []
    end
    
    def update_filter(&block)
      update_filters << block
    end
    
    def updates
      @updates ||= []
    end
    
    def update(text)
      update_filters.each { |f| text = f.call(text) }
      text
    end
  end
  
  init do
    update_filters.clear
  end
  
  extend Update
end
