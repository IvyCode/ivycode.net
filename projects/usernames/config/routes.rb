Username::Application.routes.draw do
	match "usernames" => "usernames#index", :via => :get
	match "usernames/search" => "usernames#search", :via => :get
	root :to => redirect('http://ivycode.net/projects')
end
