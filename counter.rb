require "net/http"
require "logger"
require "uri"
require "ruby_spark"

def whoisonline()
    # Please put your mac address here!!!
    mac_addr_map = {
        "Shicheng" => 
        "Hanyue" => 
        "Xiaoxi" => 
        "Zhengyang" => 
        "Jiesi" => 
        "Sipei" => 
        "Jianhe" => 
    }

    # nethttp cheat sheet: http://www.rubyinside.com/nethttp-cheat-sheet-2940.html
    uri = URI.parse("http://192.168.8.1/LoginCheck")
    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data({
        "Username" => "5604pocusset",
        "Password" => "uOnP5C"
    })

    response = http.request(request)
    cookies = response.response['set-cookie']

    request = Net::HTTP::Get.new("http://192.168.8.1/wireless_state.asp")
    request['Cookie'] = cookies
    response = http.request(request)

    return_html = response.body
    mac_addresses = return_html.scan(/[0-9A-Z]{2}\:[0-9A-Z]{2}\:[0-9A-Z]{2}\:[0-9A-Z]{2}\:[0-9A-Z]{2}\:[0-9A-Z]{2}/)

    whoisonline = []
    mac_addr_map.each do |key, value|
        mac_addresses.each do |mac_address|
            if value == mac_address then
                whoisonline.push(key)
            end
        end
    end

    return whoisonline
end

def show_whoisonline(core, cnt_online)
    turnoff(core)
    n = 0
    while cnt_online > 1
        cnt_online = cnt_online - 2
        core.function("turnon", n)
        # print "#{n}\n"
        n = n + 1
    end
    if cnt_online == 1 then
        # print "#{n}\n"
        core.function("blink", n)
    end
end

def turnoff(core)
    n = 0
    while n <= 4
        core.function("turnoff", n)
        n = n + 1
    end
end

logfile = File.open('log', File::WRONLY | File::APPEND)
logger = Logger.new(logfile)

core = RubySpark::Core.new("53ff6a066667574823282067", "20133e127034cb73180469ec65dc4b86afa72bec")
print core.info.to_s + "\n"
logger.info core.info.to_s + "\n"

last_cnt_online = 0
cnt = 0
while true
    if (cnt % 5 == 0) then
        whoisonline = whoisonline()
    end
    cnt = (cnt + 1) % 5
    cnt_online = whoisonline.size
    now = Time.now
    if (cnt_online != last_cnt_online or now.hour > 16 or now.hour < 12) then
        if (cnt_online != last_cnt_online) then
          message = "#{now}: #{whoisonline.join(", ")}\n"
	  print message
	  logger.info message
        end
        whoisonline = whoisonline()
        cnt_online = whoisonline.size
        last_cnt_online = cnt_online
        show_whoisonline(core, cnt_online)
        sleep(10)
        turnoff(core)
    end
    if now.hour >= 9 and now.hour <= 18 then
        sleep(15*60)
    end
end
logfile.close()
