require 'rubygems'

exit 0 if ARGV.count == 0

nr_days = ARGV[0].to_i
message_prefix = ARGV[1] || ""

time_end = Time.now()
time_end -= 60*60*time_end.hour
time_end -= 60*time_end.min
time_end -= time_end.sec

time_start = time_end - (nr_days * 24*60*60)

#puts time_start
#puts time_end

#time_start = time_start.strftime("%Y-%m-%d %H:%M")
#time_end = time_end.strftime("%Y-%m-%d %H:%M")

cmd = "curl http://localhost:4567/report/?start=#{time_start.to_i}&end=#{time_end.to_i}"

puts `#{cmd}`


from="cmiranda@synopsys.com"
to="cmiranda@synopsys.com"

`echo "From: ${from}"; > /tmp/report_email`
`echo "To: ${to}"; >> /tmp/report_email`
`echo "Subject: #{message_prefix} Buildroot composed report"; >> /tmp/report_email`
`echo "Content-Type: text/html"; >> /tmp/report_email`
`echo "MIME-Version: 1.0"; >> /tmp/report_email`
`echo ""; >> /tmp/report_email`
`curl "http://localhost:9999/report/" >> /tmp/report_email`

`cat /tmp/report_email | sendmail -t`

