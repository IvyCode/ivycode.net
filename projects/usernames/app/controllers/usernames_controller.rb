class UsernamesController < ApplicationController

	def index

		if params[:s].blank?
			return
		end

		render :layout => false
	end

	def search
		dictionary(params[:dictionary])

		@available = Hash.new
		min = params[:min].presence ? params[:min].to_i : 3
		max = params[:max].presence ? params[:max].to_i : 16
		combine = params[:q].presence
		q = params[:q][0..16].gsub(/\s+/, "").gsub(/[^0-9A-Za-z_]/, '') if params[:q].presence

		if combine
			@available[q] = available(q)
		end

		if max <= 3
			render :text => "Maximum must be at least 4."
			return
		end

		taken = Array.new

		prev = nil
		@dict.shuffle.each do |word|
			setPrev = word
			if combine
				if combine.length >= max
					break
				end
				word = params[:suffix].to_i == 1 ? word.capitalize + q : q + word.capitalize
			else
				if (0..1).to_a.sample == 1 && prev.presence
					word = word.capitalize + prev.capitalize
				end
			end

			prev = setPrev

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

		taken.each do |w|
			@dict.delete(w)
		end
		Rails.cache.write "dict", @dict, :expires_in => 360.day, :raw => true

		render :layout => false
	end

	private

	def dictionary dictName
		dictName.downcase!
		dictName = dictName.blank? || dictName == "all" ? "dictionary" : "dictionary." + dictName
		if Rails.cache.read(dictName).presence
			@dict = Rails.cache.read(dictName)
			return
		end

		@dict = Array.new
		File.open("#{Rails.root}/lib/#{dictName}.txt", "r").each_line do |line|
			line = line.gsub("\r\n", "").downcase
			@dict.push(line)
		end

		Rails.cache.write dictName, @dict, :expires_in => 360.day, :raw => true
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
