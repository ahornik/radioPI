#!/usr/bin/python

import socket
import threading
import SocketServer
import sys
import re
from subprocess import call
import subprocess


class ThreadedTCPRequestHandler(SocketServer.BaseRequestHandler):
	def handle(self):
		while True:
			try:
				data = self.request.recv(1024)
				cur_thread = threading.current_thread()
				print >>sys.stderr, 'received "%s" from' % data, self.client_address[0]
				if data:
					playurl = playurl_reg.match(data)
					stopplay = kill_reg.match(data) 
					GetStation = GET_reg.match(data)
					OURL = playurl_reg.search(data)
					VlPlus = VolumeUp_reg.match(data)
					VlMoins = VolumeDown_reg.match(data)
					GetVol = GetVolume_reg.match(data)

					if stopplay:
						print('will kill Sound Player')
						call (["bin/play.ksh", "-kill"])
					if OURL:
						URL = OURL.group(1).rstrip('\r\n')
						print('will play %s' % URL)
						with open("Output.txt", "w") as text_file:
							text_file.write(URL)
							call (["bin/play.ksh", URL])
					if GetStation:
						with open("Output.txt","r") as text_file:
							data=text_file.readlines()[0]
						
					if VlPlus:
						res = subprocess.check_output (["bin/volu"])
						data=res.strip("\r\n")

					if VlMoins:
						res = subprocess.check_output (["bin/vold"])
						data=res.strip("\r\n")
					if GetVol:
						res = subprocess.check_output (["bin/volg"])
						data=res.strip("\r\n")

					print >>sys.stderr, 'sending',data,' to ',self.client_address[0]
					self.request.sendall(data)
				else:
					print >>sys.stderr, 'no more data from', client_address
			finally:
				print >> sys.stderr, 'End of request for thread ',cur_thread.name

class ThreadedTCPServer(SocketServer.ThreadingMixIn, SocketServer.TCPServer):
    pass

if __name__ == "__main__":
	HOST, PORT = '0.0.0.0', 10000
	server = ThreadedTCPServer((HOST, PORT), ThreadedTCPRequestHandler)
	ip, port = server.server_address

	# Start a thread with the server -- that thread will then start one
	# more thread for each request
	server_thread = threading.Thread(target=server.serve_forever)
	# Exit the server thread when the main thread terminates
	server_thread.daemon = True
	server_thread.start()
	print "Server loop running in thread:", server_thread.name

        playurl_reg = re.compile('mplayer (.*)$',re.IGNORECASE)
	kill_reg = re.compile('kill mplayer',re.IGNORECASE)
	GET_reg = re.compile('GET Station',re.IGNORECASE)
	VolumeUp_reg = re.compile('VolumeUp',re.IGNORECASE)
	GetVolume_reg = re.compile('GetVolume',re.IGNORECASE)
	VolumeDown_reg = re.compile('VolumeDown',re.IGNORECASE)
	server.serve_forever()

