# Hackajob_PhonebookInterface_Beginner

# Developer: Karim Takieddine (https://github.com/KarimTakieddine)

In order to execute this application, users must install the Ruby
programming language from one of the following locations (for Windows):

https://github.com/oneclick/rubyinstaller2/releases/download/rubyinstaller-2.5.3-1/rubyinstaller-2.5.3-1-x64.exe (64-bit) 
https://github.com/oneclick/rubyinstaller2/releases/download/rubyinstaller-2.5.3-1/rubyinstaller-2.5.3-1-x86.exe (32-bit)

For ease of invoking the Ruby interpreter without having to type C:\Ruby\$VERSION\bin\ruby.exe $script_name
each time, users may wish to check the "Add Ruby executables to system PATH" option during installation.

Once installed, navigate to this repository's root folder using a command-line terminal and execute:

			$PATH_TO_RUBY main.rb [options]
								
Where:

Examples:

			ruby main.rb -s name 			< - > Sort contacts by name.
			ruby main.rb -s name -f Adam	< - > Sort contacts by name and filter for "Adam".
			ruby main.rb -s phone_number	< - > Sort contact by phone number.
			ruby main.rb -h					< - > Prints help message.
									
The resulting list of contacts will be formatted and printed to the console window. Upon termination, the
application will print error status and a message, if any.

Thanks for reading!