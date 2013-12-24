
class ShopifyConnector
	include Celluloid

	#def confirm_app_installed(shop)
	#	response = get_shop(shop).response.code
	#	return response == '200'
	#end
	#
	#def get_shop(shop)
	#	if shop
	#		begin
	#			tries ||= 3
	#			return HTTParty.get("https://#{shop.title}/admin/shop.json", {:headers => {'X-Shopify-Access-Token' => shop.token}})
	#		rescue => e
	#			puts e.inspect
	#			retry unless (tries -= 1).zero?
	#		end
	#	end
	#end
	#
	#def get_products(shop, page=1)
	#	if shop
	#		begin
	#			tries ||= 3
	#			return HTTParty.get("https://#{shop.title}/admin/products.json", {:body => {:limit => 250, :page => page}, :headers => {'X-Shopify-Access-Token' => shop.token}})['products']
	#		rescue => e
	#			puts e.inspect
	#			retry unless (tries -= 1).zero?
	#		end
	#	end
	#end
	#
	#def get_product_count(shop)
	#	begin
	#		tries ||= 3
	#		result = HTTParty.get("https://#{shop.title}/admin/products/count.json", {:headers => {'X-Shopify-Access-Token' => shop.token}})['count']
	#		if result
	#			return result
	#		else
	#			return 0
	#		end
	#	rescue => e
	#		puts e.inspect
	#		retry unless (tries -= 1).zero?
	#	end
	#end
	#
	#def create_webhook(shop, webhook)
	#	begin
	#		tries ||= 3
	#		return HTTParty.post("https://#{shop.title}/admin/webhooks.json", {:body => {:webhook => webhook}, :headers => {'X-Shopify-Access-Token' => shop.token}})
	#	rescue => e
	#		puts e.inspect
	#		retry unless (tries -= 1).zero?
	#	end
	#end
	#
	#def get_script_tags(shop, src)
	#	if shop
	#		begin
	#			tries ||= 3
	#			return HTTParty.get("https://#{shop.title}/admin/script_tags.json", {:body => {:src => src}, :headers => {'X-Shopify-Access-Token' => shop.token}})['script_tags']
	#		rescue => e
	#			puts e.inspect
	#			retry unless (tries -= 1).zero?
	#		end
	#	end
	#end
	#
	#def create_script_tag(shop, script_tag)
	#	begin
	#		tries ||= 3
	#		return HTTParty.post("https://#{shop.title}/admin/script_tags.json", {:body => {:script_tag => script_tag}, :headers => {'X-Shopify-Access-Token' => shop.token}})
	#	rescue => e
	#		puts e.inspect
	#		retry unless (tries -= 1).zero?
	#	end
	#end
	#
	#def get_recurring_application_charges(shop)
	#	begin
	#		tries ||= 3
	#		return HTTParty.get(
	#			"https://#{shop.title}/admin/recurring_application_charges.json",
	#			{
	#				:headers => {
	#					'X-Shopify-Access-Token' => shop.token
	#				}
	#			}
	#		)['recurring_application_charges']
	#	rescue => e
	#		puts e.inspect
	#		retry unless (tries -= 1).zero?
	#	end
	#end
	#
	#def create_recurring_application_charge(shop, price)
	#	begin
	#		tries ||= 3
	#		return HTTParty.post(
	#			"https://#{shop.title}/admin/recurring_application_charges.json",
	#			{
	#				:body => {
	#					:recurring_application_charge => {
	#						:name => 'Search Reactor',
	#						:price => price,
	#						:return_url => "#{Rails.configuration.app_domain}/activate",
	#						:trial_days => get_trial_days(shop),
	#						:test => Rails.env.development?,
	#					}
	#				},
	#				:headers => {
	#					'X-Shopify-Access-Token' => shop.token
	#				}
	#			}
	#		)
	#	rescue => e
	#		puts e.inspect
	#		retry unless (tries -= 1).zero?
	#	end
	#end
	#
	#def activate_recurring_application_charge(shop, charge_id)
	#	begin
	#		tries ||= 3
	#		return HTTParty.post(
	#			"https://#{shop.title}/admin/recurring_application_charges/#{charge_id}/activate.json",
	#			{
	#				:headers => {
	#					'X-Shopify-Access-Token' => shop.token
	#				}
	#			}
	#		)
	#	rescue => e
	#		puts e.inspect
	#		retry unless (tries -= 1).zero?
	#	end
	#end
	#
	#def delete_recurring_application_charge(shop, charge_id)
	#	begin
	#		tries ||= 3
	#		return HTTParty.post(
	#			"https://#{shop.title}/admin/recurring_application_charges/#{charge_id}.json",
	#			{
	#				:headers => {
	#					'X-Shopify-Access-Token' => shop.token
	#				}
	#			}
	#		)
	#	rescue => e
	#		puts e.inspect
	#		retry unless (tries -= 1).zero?
	#	end
	#end

end
Celluloid::Actor[:shopify_conn] = ShopifyConnector.pool(:size => 32)