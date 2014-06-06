class UsernamesController < ApplicationController

	before_filter :dictionary, :only => [:search]

	def index

		if params[:s].blank?
			return
		end

		render :layout => false
	end

	def search
		@available = Hash.new
		min = params[:min].presence ? params[:min].to_i : 3
		max = params[:max].presence ? params[:max].to_i : 16
		combine = params[:q].presence
		q = params[:q][0..16].gsub(/\s+/, "").gsub(/[^0-9A-Za-z_]/, '') if params[:q].presence

		if combine
			@available[q] = available(q)
		end

		taken = Array.new

		require 'timeout'
		begin
			status = Timeout::timeout(1) {
				@dict.shuffle.each do |word|
					if combine
						if combine.length >= max
							break
						end
						word = params[:suffix].to_i == 1 ? word.capitalize + q : q + word.capitalize
					end

					if word.length < min || word.length > max
						next
					end

					if available(word)
						@available[word] = true
					else
						taken.push(word)
						next
					end


					if @available.size > 11
						break
					end
				end
			}
		rescue Timeout::Error
			render :text => "<div class='text-center'>Timeout Error</div>"
			return
		end

		taken.each do |w|
			@dict.delete(w)
		end
		Rails.cache.write "dict", @dict, :expires_in => 360.day, :raw => true

		render :layout => false
	end

	private

	def dictionary
		if Rails.cache.read("dict").presence
			@dict = Rails.cache.read("dict")
			return
		end

		@dict = Array.new
		File.open("#{Rails.root}/lib/dictionary.txt", "r").each_line do |line|
			line = line.gsub("\r\n", "").downcase
			@dict.push(line)
		end

		Rails.cache.write "dict", @dict, :expires_in => 360.day, :raw => true
	end

	def available name
		if name.length > 16 || name.length < 3
			return false
		end

		require 'json'
		require 'net/http'
		uri = URI.parse('https://api.mojang.com/profiles/page/1')
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true

		begin	
			request = Net::HTTP::Post.new(uri.path, {'Content-Type' =>'application/json'})
			request.body = {:name => name, :agent => "minecraft"}.to_json

			response = http.request(request)
			result = JSON.parse(response.body)

			result["size"] == 0
		rescue Exception => e
			false
		end
	end
end
