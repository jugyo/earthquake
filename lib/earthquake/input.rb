module Earthquake
  module Input
    def input(text)
      begin
        notify text
        if text == '/exit'
          stop
        end
      rescue => e
        notify "[ERROR] #{e}"
      end
    end
  end
end
