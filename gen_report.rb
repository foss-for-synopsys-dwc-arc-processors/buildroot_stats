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

cmd = "curl http://nl20droid2:9999/report/?start=#{time_start.to_i}&end=#{time_end.to_i}"

puts cmd

from="bla@bla.com"
to=[
	"bla@bla.com",
]

f = File.open("/tmp/report", "w")

html = `#{cmd}`

f.puts("From: #{from}")
to.each do |t|
	f.puts("To: #{t}")
end
f.puts("Subject: #{message_prefix} Buildroot composed report")
f.puts("Content-Type: text/html")
f.puts("MIME-Version: 1.0")
f.puts("")
f.puts(html)
f.close
`( cat /tmp/report ) | sendmail -t`

