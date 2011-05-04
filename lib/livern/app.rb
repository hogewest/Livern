module Livern
  class App < Sinatra::Base

    configure do
      set :root, File.expand_path('../../..', __FILE__)
      set :public, File.join(root, '/public')
      set :views, File.join(root, '/views')
    
      set :config, YAML.load(File.open("#{root}/config.yml"))
      set :consumer_token, ENV['TWITTER_CONSUMER_TOKEN'] ||= config['twitter']['consumer_token'] 
      set :consumer_secret, ENV['TWITTER_CONSUMER_SECRET'] ||= config['twitter']['consumer_secret'] 
      set :root_url, ENV['ROOT_URL'] ||= config['root_url']
      set :twitter_url, 'http://twitter.com'
      set :per_page, 10

      helpers Sinatra::ContentFor
      helpers Livern::Helpers
      use Rack::Session::Pool, :expire_after => 60 * 60 * 24 * 14

      Amazon::Ecs.configure do |options|
        options[:aWS_access_key_id] = ENV['AMAZON_ECS_ACCES_KEY'] ||= settings.config['amazon_ecs']['acces_key'] 
        options[:aWS_secret_key] = ENV['AMAZON_ECS_SECRET_ACCES_KEY'] ||= settings.config['amazon_ecs']['secret_acces_key']
      end

      DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite:///#{root}/livern.sqlite3")
    end                         

    configure :development do
      register Sinatra::Reloader
      also_reload File.join(settings.root, '/lib/*.rb')
      also_reload File.join(settings.root, '/lib/livern/*.rb')

      DataMapper::Logger.new($stdout, :debug)
      Amazon::Ecs.debug = true
    end

    before do
      session[:oauth] ||= {}
      session[:twitter] ||= {}
    end

    get '/' do
      redirect '/login' unless logged_in?

      page = params[:page] ||= 1
      page = page.to_i <= 0 ? 1 : page.to_i

      query = params.dup
      query[:screen_name] = session[:twitter][:screen_name]
      @items = Item.search(query, false).all(
        :order => [:title.asc, :asin.asc],
        :offset => (page.to_i - 1) * settings.per_page,
        :limit => settings.per_page
      )

      count = Item.search(query, false).count
      total_page = count / settings.per_page
      total_page = total_page + 1 if count % settings.per_page >= 1
      @page_info = {:current_page => page.to_i, :total_page => total_page}

      erb :index
    end

    get '/login' do
      redirect '/' if logged_in?
      erb :login, :layout => false
    end

    get '/logout' do
      request.session_options[:drop] = true
      redirect '/login'
    end

    get '/twitter' do
     request_token = oauth_consumer.get_request_token(:oauth_callback => "#{settings.root_url}/access_token")
     session[:oauth][:request_token] = request_token.token
     session[:oauth][:request_token_secret] = request_token.secret

     redirect request_token.authorize_url
    end

    get '/access_token' do
      request_token = OAuth::RequestToken.new(oauth_consumer, session[:oauth][:requet_token], session[:oauth][:request_token_secret])
      acces_token = request_token.get_access_token({}, :oauth_token => params[:oauth_token],  :oauth_verifier => params[:oauth_verifier])
      session[:oauth][:acces_token] = acces_token.token
      session[:oauth][:acces_token_secret] = acces_token.secret

      twitter
      session[:twitter][:profile_image] = Twitter::Client.new.profile_image(:size => 'bigger')
      session[:twitter][:screen_name] = Twitter.user.screen_name

      redirect '/'
    end

    get '/read' do
      redirect '/login' unless logged_in?

      page = params[:page] ||= 1
      query = params.dup
      query[:screen_name] = session[:twitter][:screen_name]
      @items = Item.search(query, true).all(
        :order => [:title.asc, :asin.asc],
        :offset => (page.to_i - 1) * settings.per_page,
        :limit => settings.per_page
      )

      count = Item.search(query, true).count
      total_page = count / settings.per_page
      total_page = total_page + 1 if count % settings.per_page >= 1
      @page_info = {:current_page => page.to_i, :total_page => total_page}

      erb :read
    end

    get '/entry' do
      redirect '/login' unless logged_in?

      page = params[:page] ||= 1
      @res = Amazon::Ecs.item_search(params[:q], :Author => params[:author], :country => 'jp', :response_group => 'Images,ItemAttributes' , :item_page => page)
      @page_info = {:current_page => page.to_i, :total_page => @res.total_pages}

      erb :entry
    end

    post '/bookentry' do
      return JSON.generate(:status_id => '2') unless logged_in?

      res = Amazon::Ecs.item_lookup(params[:asin], :country => 'jp', :response_group => 'Images,ItemAttributes') 

      return JSON.generate(:status_id => '2') if res.items.size <= 0
      return JSON.generate(:status_id => '1') if Item.get(session[:twitter][:screen_name], params[:asin])

      item = Item.create(
        :screen_name => session[:twitter][:screen_name],
        :asin => params[:asin],
        :title => res.items[0].get('itemattributes/title'),
        :author => res.items[0].get_array('itemattributes/author').join(','),
        :creator => res.items[0].get_array('itemattributes/creator').join(','),
        :manufacturer => res.items[0].get('itemattributes/manufacturer'),
        :release_date => release_date(res.items[0]),
        :image_url => image_url(res.items[0]),
        :detail_page_url => res.items[0].get('detailpageurl')
      ) 

      JSON.generate(:title => item.title, :status_id => '0')
    end

    post '/delete' do
      redirect '/login' unless logged_in?

      item = Item.get(session[:twitter][:screen_name], params[:asin])
      item.destroy if item
      redirect '/'
    end

    post '/read' do
      redirect '/login' unless logged_in?

      item = Item.get(session[:twitter][:screen_name], params[:asin])
      item.update(:read => true) if item
      redirect '/'
    end

    post '/unread' do
      redirect '/login' unless logged_in?

      item = Item.get(session[:twitter][:screen_name], params[:asin])
      item.update(:read => false) if item
      redirect '/'
    end

    not_found do
      erb :'404', :layout => false
    end

    error do
      'Error: ' + env['sinatra.error'].name
    end
  end
end
