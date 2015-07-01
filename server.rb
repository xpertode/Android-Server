require 'sinatra'

module Browsers
    SupportedBrowsers = ["chrome","firefox"]
end

class Server < Sinatra::Base

    get '/start' do
        device_id = params[:device_id]
        browser = params[:browser]
        url = params[:url]
        if device_id==nil or browser==nil or url ==nil
            return "Bad Request"
        end
        a = Activity.new(device_id,browser,url)
        a.start
    end

    get '/stop' do
        device_id = params[:device_id]
        browser = params[:browser] 
        if Activity.checkDevice(device_id)
            status = Activity.stop(device_id,browser)
            if status ==true
                return "#{browser} closed on #{device_id}"
            else 
                return status
            end
        else
            return "#{device_id} is not running any such activity "
        end
    end
end





class Activity
    @@activities = []
    include Browsers
    def initialize(device_id,browser,url)
        @device_id = device_id
        @browser = browser
        @url = url
        @@activities << device_id
    end

    def validateArgs
        if @url[/^www.[a-z0-9]*.com$/]!=@url
            return "Url should be similar to http://wwww.example.com"
        end
        if not Browsers::SupportedBrowsers.include?(@browser)
            return "Sorry, #{@browser} isn't available."
        end
        return "OK"
    end

    def start
        valid_status = validateArgs
        unless valid_status == "OK"
            return valid_status
        end

        if @browser == 'chrome'
           status = system("adb -s #{@device_id} shell am start -a android.intent.action.VIEW -n com.android.chrome/com.google.android.apps.chrome.Main -d http://#{@url}")
            respond(status)

        elsif @browser == 'firefox'
           status = system("adb -s #{@device_id} shell am start -a android.intent.action.VIEW -n org.mozilla.firefox/.App -d #{@url}")
           respond(status)
        end
    end

    def self.stop(device_id,browser)
        unless Browsers::SupportedBrowsers.include?(browser)
            return "Sorry,#{browser} isn't available."
        end
        if browser == 'chrome'
            status = system("adb -s #{device_id} shell am force-stop com.android.chrome")            
        elsif browser == 'firefox'
           status = system("adb -s #{device_id} shell am force-stop org.mozilla.firefox")
        end
        return status
    end

    def self.checkDevice(device_id)
        return @@activities.include?(device_id)
    end

    private
    def respond(status)
        if not status
            return "Device #{@device_id} not found."
        else
            return "#{@url} opened successfully in #{@browser} on #{@device_id}"
        end
    end
end

run Server.run!
