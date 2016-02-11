require "rest_client"
require "json"
require "base64"
require "pry-byebug"

########################
# Method: API GET Method
########################
def rest_get(api_url, auth, cert=nil)
	JSON.parse(RestClient::Request.execute(method: :get,
		url: api_url,
		verify_ssl: false,
		headers: {
			authorization: auth,
			accept: :json
		}
	))
end

#################################
# Method: Read settings.json file
#################################
def readSettings(file)
	settings = File.read(file)
	JSON.parse(settings)
end

config = readSettings('settings.json')
config['xms'].each do |xms|
	auth = "Basic #{Base64.strict_encode64("#{xms['user']}:#{xms['password']}")}"
	cluster_list = rest_get("https://#{xms['xms_ip']}/api/json/v2/types/clusters", auth)
	cluster_list['clusters'].each do |cluster|
		logical_space = 0
		physical_space = 0
		cluster_details = rest_get(cluster['href'], auth)
		physical_space = cluster_details['content']['ud-ssd-space-in-use'].to_f
		volume_list = rest_get("https://#{xms['xms_ip']}/api/json/v2/types/volumes", auth)
		volume_list['volumes'].each do |volume|
			volume_details = rest_get(volume['href'], auth)
			logical_space += volume_details['content']['logical-space-in-use'].to_f if volume_details['content']['sys-id'] == cluster_details['content']['sys-id']
		end
		puts "#{cluster_details['content']['sys-id'][1]} Logical Space Provisioned: #{(logical_space.to_f/1024/1024/1024).round(2)}"
		puts "#{cluster_details['content']['sys-id'][1]} Physical Space in Use: #{(physical_space.to_f/1024/1024/1024).round(2)}"
		puts "#{cluster_details['content']['sys-id'][1]} Data Reducation Rate: #{(logical_space/physical_space).round(2)} to 1"
	end
end
