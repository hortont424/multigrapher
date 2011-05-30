# Copyright 2011 Tim Horton. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY TIM HORTON "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
# SHALL TIM HORTON OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import select
import pybonjour
import BaseHTTPServer
import SocketServer
import multiprocessing
import datetime

CACHE_TIMEOUT = datetime.timedelta(milliseconds=100)

class ServiceTypes(object):
    GRAPH = "graph"
    TEXT = "text"

def serve_data(short_name, long_name, type_name, data_function):
    port = 8000

    short_name = short_name.replace(",", "")
    long_name = long_name.replace(",", "")

    def update_cache():
        if ((not hasattr(update_cache, "cache_update_time")) or
            ((datetime.datetime.now() - update_cache.cache_update_time) > CACHE_TIMEOUT)):
            update_cache.cache_update_time = datetime.datetime.now()
            (color, data) = data_function()
            update_cache.current_content = "{0},{1},{2},{3}\n{4}".format(short_name, long_name, type_name, color, data)

        return update_cache.current_content

    class DataHandler(BaseHTTPServer.BaseHTTPRequestHandler):
        def do_HEAD(s):
            s.send_response(200)
            s.send_header("Content-type", "text/csv")
            s.end_headers()
        def do_GET(s):
            s.send_response(200)
            s.send_header("Content-type", "text/csv")
            s.end_headers()
            s.wfile.write(update_cache())

    while port < 10000:
        try:
            httpd = SocketServer.TCPServer(("", port), DataHandler)
            print "HTTP server started on port {0}.".format(port)
            bonjour_process = multiprocessing.Process(target=publish_service, args=(short_name, port))
            bonjour_process.start()
            httpd.serve_forever()
        except Exception as e:
            port += 1

# The following function is derived from examples contained
# within the pybonjour documentation.

def publish_service(name, port):
    regtype = "_multigrapher._tcp"

    def publish_callback(sdRef, flags, errorCode, name, regtype, domain):
        if errorCode == pybonjour.kDNSServiceErr_NoError:
            print "Bonjour service published ('{0}').".format(name)

    sdRef = pybonjour.DNSServiceRegister(name = name,
                                         regtype = regtype,
                                         port = port,
                                         callBack = publish_callback)

    try:
        try:
            while True:
                ready = select.select([sdRef], [], [])
                if sdRef in ready[0]:
                    pybonjour.DNSServiceProcessResult(sdRef)
        except KeyboardInterrupt:
            pass
    finally:
        sdRef.close()
