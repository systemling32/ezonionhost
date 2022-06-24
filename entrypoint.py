import os


hostsvar = str(os.getenv('HOSTS')) ## Reading onion hosts to be configured from env variable.
datadir = str(os.getenv('DATA_DIR'))
f = open(datadir + "/torrc", "w")
print(hostsvar)
if not hostsvar == "None":
	hosts = hostsvar.split(',') 	## Several hidden services can be seperated by a comma in the HOSTS var
	for host in hosts:
		## Extracting the information about the hosts from the env var.
		hostdesc = str(host.split("=")[0])
		hostname = str(host.split("=")[1]).split(":")[1]
		hostport = str(host.split("=")[1]).split(":")[2]
		serviceport = str(host.split("=")[1]).split(":")[0]

		print(host)
	## Writing the Hidden Service Config to torrc file.
		f.write("HiddenServiceDir " + datadir + "/services/" + hostdesc + "\n")
		f.write("HiddenServicePort " + serviceport + " " + hostname + ":" + hostport + "\n")

## Setup Socks Proxy if desired by the user.
#print(os.environ['PROXY'])
if os.getenv('PROXY') == "True":
	f.write("SocksPort 0.0.0.0:9050 \n")
	f.write("SocksPolicy accept 127.0.0.1,accept 10.0.0.0/8,accept 172.16.0.0/12,accept 192.168.0.0/16 \n")
	f.write("SocksPolicy reject *")
else:
	f.write("SocksPort 127.0.0.1:9050\n")
	f.write("SocksPolicy accept 127.0.0.1\n")
	f.write("SocksPolicy reject *")

f.close()

## Check if the 'services' folder exists. If not create it with non-root ownership
if not os.path.isfile(datadir + "/services"):
	os.system("mkdir "+ datadir +"/services/")
os.system("chown -R 1000:1000 " + datadir + "/services/")

## Start the Tor process as non-root with the generated torrc config.
os.system("su-exec 1000:1000 tor -f " + datadir + "/torrc")