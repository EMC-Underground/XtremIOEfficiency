require "rest_client"
require "json"
require "base64"

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

config = readSettings(settings.json)
config['xms'].each do |xms|
	auth = Base64.strict_encode64("#{xms['user']}:#{xms['password']}")
	cluster_list = rest_get("https://#{xms['xms_ip']}/api/json/v2/types/clusters", auth)
	cluster_list['clusters'].each do |cluster|
		logical_space = ''
		cluster_details = rest_get(cluster['href'], auth)
		physical_space = cluster_details['content']['ud-ssd-space-in-use']
		volume_list = rest_get("https://#{xms['xms_ip']}/api/json/v2/types/volumes", auth)
		volume_list['volumes'].each do |volume|
			logical_space += volume['content']['logical-space-in-use'] if volume['content']['sys-id'] == [cluster_details['content']['sys-id']
		end
		puts "#{cluster_details['content']['sys-id'][1]} Data Reducation Rate:" + logical_space/physcial_space/1024/1024/1024
	end
end
