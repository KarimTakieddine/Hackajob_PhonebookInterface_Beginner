##################################################################################

# Copyright (c) 2018 Karim Takieddine

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

#################################################################################

require 'json'
require 'net/http'
require 'optparse'

module ErrorCode

	NO_ERROR 				= 0
	SYSTEM_ERROR 			= 1
	INVALID_RESPONSE_ERROR 	= 2
	RESPONSE_PARSE_ERROR	= 3

end

Contact = Struct.new(
	:name,
	:phone_number,
	:address
)

class ContactList

	module SortType
	
		NAME 			= 0
		PHONE_NUMBER 	= 1
		ADDRESS 		= 2

	end

	SORT_TYPE_TO_ACCESSOR_MAP =
	{
		SortType::NAME 			=> :name,
		SortType::PHONE_NUMBER 	=> :phone_number,
		SortType::ADDRESS 		=> :address
	}.freeze

	include Enumerable

	def initialize
		@contacts = []
	end

	def each(&block)
		@contacts.each(&block)
	end

	def <<(contact)
		@contacts << contact
		self
	end

	def sort!(sort_type)
		@contacts.sort! do |lhs, rhs|
			accessor_name = SORT_TYPE_TO_ACCESSOR_MAP.key?(sort_type) ? SORT_TYPE_TO_ACCESSOR_MAP[sort_type] : :name
			lhs.public_send(accessor_name) <=> rhs.public_send(accessor_name)
		end
	end

	def filter!(regexp)
		@contacts.delete_if { |element| !(element.name =~ regexp) }
	end

	def to_s
		string = ''
		@contacts.each do |contact|
			string << " - Contact:\n\n"
			string << "\t\tName: #{contact.name}\n"
			string << "\t\tAddress: #{contact.address}\n"
			string << "\t\tPhone Number: #{contact.phone_number}\n"
			string << "\n"
		end
		string
	end

end

def convert_to_string(error_code)
	ErrorCode.constants.each { |symbol| return symbol.to_s if error_code == ErrorCode.const_get(symbol) }
	"NO_ERROR"
end

def exit_with_message(
	error_code,
	error_message
)
	puts("Application exiting with error code: #{convert_to_string(error_code)} and message: #{error_message}")
	exit(error_code)
end

PHONEBOOK_DATA_URI = URI.parse('http://www.mocky.io/v2/581335f71000004204abaf83')
HTTP_SUCCESS_CODE = 200

arguments =
{
	:filter => %r{.*},
	:sort 	=> :name
}

BANNER_TEXT = <<-BANNER_TEXT
Usage: ruby #{__FILE__} [options]

Where:

BANNER_TEXT

OptionParser.new(ARGV) do |instance|

	instance.banner = BANNER_TEXT

	instance.on(
		'-s [SORT_TYPE]',
		'--sort [SORT_TYPE]',
		*ContactList::SORT_TYPE_TO_ACCESSOR_MAP.values.map(&:to_s).inspect
	) { |sort| arguments[:sort] = sort.to_sym }

	instance.on(
		'-f [FILTER_STRING]',
		'--filter [FILTER_STRING]',
		'Filter contacts using string argument'
	) { |filter_string| arguments[:filter] = Regexp.new(filter_string) }

end.parse!

error_code = ErrorCode::NO_ERROR
error_message = ''

begin
	

	phonebook_client = Net::HTTP.new(PHONEBOOK_DATA_URI.host, PHONEBOOK_DATA_URI.port)
	contacts_request = Net::HTTP::Get.new(PHONEBOOK_DATA_URI.request_uri)
	contacts_response = phonebook_client.request(contacts_request)

	if contacts_response.code.to_i != HTTP_SUCCESS_CODE
		exit_with_message(
			ErrorCode::INVALID_RESPONSE_ERROR,
			"HTTP response from #{PHONEBOOK_DATA_URI} contains invalid code: #{contacts_response.code}"
		)
	end

	contacts_response_json = JSON.parse(contacts_response.read_body)

	unless contacts_response_json.key?('contacts')
		exit_with_message(
			ErrorCode::INVALID_RESPONSE_ERROR,
			"HTTP response JSON from #{PHONEBOOK_DATA_URI} does not list \"contacts\" field"
		)
	end

	contacts_map_list = contacts_response_json['contacts']
	contact_list = ContactList.new
	contacts_map_list.each do |contacts_map|
		contact_list << JSON.parse(JSON.pretty_generate(contacts_map), :object_class => Contact)
	end

	accessor_to_sort_type_map = ContactList::SORT_TYPE_TO_ACCESSOR_MAP.invert

	contact_list.sort!(
		accessor_to_sort_type_map.key?(arguments[:sort]) ?
			accessor_to_sort_type_map[arguments[:sort]] : ContactList::SortType::NAME
	)

	contact_list.filter!(arguments[:filter])

	puts "#{contact_list}\n"

	exit_with_message(
		ErrorCode::NO_ERROR,
		"Application terminated successfully"
	)

rescue SystemCallError, URI::InvalidURIError => system_error
	exit_with_message(
		ErrorCode::SYSTEM_ERROR,
		"A system error occurred with message: #{system_error} -- #{system_error.class}"
	)
rescue JSON::ParserError => parse_error
	exit_with_message(
		ErrorCode::RESPONSE_PARSE_ERROR,
		"Failed to parse incoming payload data from: #{PHONEBOOK_DATA_URI} as JSON: #{parse_error}"
	)
end