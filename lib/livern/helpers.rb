module Livern
  module Helpers

    def logged_in?
      !session[:oauth].nil? && !session[:oauth].empty? && !session[:oauth][:acces_token].nil? && !session[:oauth][:acces_token].empty?
    end

    def pagination_links(page_params)
      current_page = page_params[:current_page] ||= 1
      total_page = page_params[:total_page]
      item_per_page = page_params[:per_page] ||= 10
      disp_page = 3

      prev_page_size = current_page - disp_page > 0 ? current_page - disp_page : 1
      next_page_size = current_page + disp_page <= total_page ? current_page + disp_page : total_page

      links = []
      (prev_page_size..next_page_size).each do |page|
        if(current_page == page) 
          links << "<span class='current'>#{page}</span>"
        elsif
          links << "<a href='#{search_url(page)}'>#{page}</a>"
        end
      end

      prev_link_url = search_url(current_page - 1) unless current_page <= 1 || current_page > total_page
      next_link_url = search_url(current_page + 1) unless current_page >= total_page || current_page <= 0

      html = '<div class="pagination">'
      html << "<a href='#{prev_link_url}' class='prev_page'>&laquo; Prev</a>" if prev_link_url
      html << links.join(' ')
      html << "<a href='#{next_link_url}' class='next_page'>Next &raquo;</a>" if next_link_url
      html << '</div>'
    end

    def search_url(page)
      "#{request.path}?q=#{params['q']}&author=#{params['author']}&page=#{page}"
    end

    def oauth_consumer
      OAuth::Consumer.new(settings.consumer_token, settings.consumer_secret, :site => settings.twitter_url)
    end

    def twitter
      Twitter.configure do |config|
        config.consumer_key = settings.consumer_token
        config.consumer_secret = settings.consumer_secret
        config.oauth_token = session[:oauth][:acces_token]
        config.oauth_token_secret = session[:oauth][:acces_token_secret] 
      end
    end

    def release_date(item)
      item.get('itemattributes/releasedate') ? item.get('itemattributes/releasedate') : item.get('itemattributes/publicationdate')
    end

    def image_url(item)
      item.get_hash('mediumimage') ? item.get_hash('mediumimage')[:url] : 'http://ec1.images-amazon.com/images/G/09/nav2/dp/no-image-no-ciu._SL160_.gif'
    end

    def search_not_found?(size, q, author)
      size <= 0 && (!q.nil? && !q.empty? || !author.nil? && !author.empty?)
    end
  end
end
