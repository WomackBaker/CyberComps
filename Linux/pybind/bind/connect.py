#!/usr/bin/env python3
import socket
import ssl
import sys
from sys import exit
host = '0.0.0.0'
port = 9999


def socket_create():
    try:

        global ssls
        s = socket.socket()
        ssls = ssl.wrap_socket(s, ssl_version=ssl.PROTOCOL_TLSv1)
    except socket.error as msg:
        print("Socket creation error: " + str(msg))


# Connect to a remote socket
def socket_connect():
    try:
        global host
        global port
        ssls.connect((host, port))
    except socket.error as msg:
        print("Socket connection error: " + str(msg))
    else:
        login_prompt = str(ssls.recv(1024).decode())
        # print(client_response)
        if login_prompt == 'nope':
            pw = input('Password: ')
            ssls.send(str.encode(pw))
            client_response = ssls.recv(1024).decode()
            if client_response == 'bruh\n':
                print('Invalid password!')
                ssls.close()
                exit(1)
            print('Authenticated!')
            print(client_response, end='')

            while True:
                try:
                    cmd = input()
                    if len(str.encode(cmd)) > 0:
                        if cmd == '__quit__':
                            ssls.send(str.encode('quit'))
                            ssls.close()
                            sys.exit()
                        else:
                            ssls.send(str.encode(cmd))
                            client_response = str(ssls.recv(4096).decode())
                            print(client_response, end="")
                except KeyboardInterrupt:
                    print('Exiting shell...')
                    ssls.send(str.encode('__quit__'))
                    ssls.close()

def main():
    socket_create()
    socket_connect()


main()
