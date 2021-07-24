import json
from web3 import Web3, HTTPProvider
import socket

blockchain_address = 'http://127.0.0.1:7545'
web3 = Web3(HTTPProvider(blockchain_address))


def shipping_contracts(account_who_send, account_to_send, vaccine_type,amount_vaccine,proccesses, no_serie_container,date_expiry,shipping_date):
    web3.eth.defaultAccount = web3.eth.accounts[account_who_send]
    compiled_contract_path = 'build/contracts/Vaccine.json'
    deployed_contract_address = '0xD441b89325f430d877Ef8a1502C0925FC8E5b608'
    
    with open(compiled_contract_path) as file:
        contract_json = json.load(file) #Load contract info as JSON
        contract_abi = contract_json['abi']

    contract = web3.eth.contract(address=deployed_contract_address, abi=contract_abi)
    tx_hash = contract.functions.addEnvio(web3.eth.defaultAccount,web3.eth.accounts[account_to_send],vaccine_type,amount_vaccine,proccesses, no_serie_container,date_expiry,shipping_date).transact()
    #send_udp_message("Yahoo")
    #tx_receipt = web3.eth.waitForTransactionReceipt(tx_hash)
    #print('tx_hash: {}'.format(tx_hash.hex()))


def reception_contract(address_who_sent, address_who_received, No_serie_container, amount_vaccine, type_vaccine, state, date_reception):
    web3.eth.defaultAccount = web3.eth.accounts[address_who_sent]
    compiled_contract_path = 'build/contracts/Reception.json'
    deployed_contract_address = '0x2608912772dE1126a446C5d2Eeb04B0BA8a03AE2'

    with open(compiled_contract_path) as file:
        contract_json = json.load(file) #Load contract info as JSON
        contract_abi = contract_json['abi']

    contract = web3.eth.contract(address=deployed_contract_address, abi=contract_abi)
    tx_hash = contract.functions.addReceived(web3.eth.defaultAccount,web3.eth.accounts[address_who_received],No_serie_container, amount_vaccine, type_vaccine, state, date_reception).transact()
    #send_udp_message("Yahoo")
    #tx_receipt = web3.eth.waitForTransactionReceipt(tx_hash)
    #print('tx_hash: {}'.format(tx_hash.hex()))

def application_contract(date_application, age_people, morbidity):
    web3.eth.defaultAccount = web3.eth.accounts[0]
    compiled_contract_path = 'build/contracts/Application.json'
    deployed_contract_address = '0x46B205d8A3d8C73ED2EFe7C9BDaC12F235254Eb1'

    with open(compiled_contract_path) as file:
        contract_json = json.load(file) #Load contract info as JSON
        contract_abi = contract_json['abi']

    contract = web3.eth.contract(address=deployed_contract_address, abi=contract_abi)
    tx_hash = contract.functions.addApplication(date_application, age_people, morbidity).transact()
    send_udp_message2("Yahoo")
    #tx_receipt = web3.eth.waitForTransactionReceipt(tx_hash)
    #print('tx_hash: {}'.format(tx_hash.hex()))
    

def send_token(emis, recep, amount):
    web3.eth.defaultAccount = web3.eth.accounts[emis]
    compiled_contract_path = 'build/contracts/MetaCoin.json'
    deployed_contract_address = '0x7558c7d426806881b616069E140F402656705905'

    with open(compiled_contract_path) as file:
        contract_json = json.load(file) #Load contract info as JSON
        contract_abi = contract_json['abi']

    contract = web3.eth.contract(address=deployed_contract_address, abi=contract_abi)
    tx_hash = contract.functions.sendCoin(web3.eth.defaultAccount, web3.eth.accounts[recep], amount).transact()
    print(tx_hash)
    
def view_Tokens(account):
    
    compiled_contract_path = 'build/contracts/MetaCoin.json'
    deployed_contract_address = '0x7558c7d426806881b616069E140F402656705905'

    with open(compiled_contract_path) as file:
        contract_json = json.load(file) #Load contract info as JSON
        contract_abi = contract_json['abi']

    contract = web3.eth.contract(address=deployed_contract_address, abi=contract_abi)
    
    for i in range(2):
        res = contract.functions.getBalance(web3.eth.accounts[account]).call()
        print(res)
        account += 1
        if res != 0:
            send_udp_message(str(res))
        

def view_Tokens_send(account):
   
    compiled_contract_path = 'build/contracts/MetaCoin.json'
    deployed_contract_address = '0x7558c7d426806881b616069E140F402656705905'

    with open(compiled_contract_path) as file:
        contract_json = json.load(file) #Load contract info as JSON
        contract_abi = contract_json['abi']

    contract = web3.eth.contract(address=deployed_contract_address, abi=contract_abi)
    #solo 2 porque solo necesitaremos el número de cuentas disponibles
    for i in range(4):
        res = contract.functions.getBalance(web3.eth.accounts[account]).call()
        print(res)
        sa = res
        account += 1
      
        if res != 0:
            send_token(account,0,sa)


def pre_registro(account_who_stores, name, curp, tel):
    web3.eth.defaultAccount = web3.eth.accounts[account_who_stores]
    compiled_contract_path = 'build/contracts/Pre_vaccination.json'
    deployed_contract_address = '0x7B39E7cCA3d1fF2291C8058Cc88534308D500824'

    with open(compiled_contract_path) as file:
        contract_json = json.load(file)  # Load contract info as JSON
        contract_abi = contract_json['abi']

    contract = web3.eth.contract(address=deployed_contract_address, abi=contract_abi)
    tx_hash = contract.functions.add_pre_vaccination(web3.eth.defaultAccount, name, curp, tel).transact()
    send_udp_message2("save")

def view_Pre_Registro(curp):
    compiled_contract_path = 'build/contracts/Pre_vaccination.json'
    deployed_contract_address = '0x7B39E7cCA3d1fF2291C8058Cc88534308D500824'

    with open(compiled_contract_path) as file:
        contract_json = json.load(file)  # Load contract info as JSON
        contract_abi = contract_json['abi']

    contract = web3.eth.contract(address=deployed_contract_address, abi=contract_abi)
    res = contract.functions.viewRegistration(curp).call()
    print(res)
    new_res = str(res)
    print(new_res)
    if "0x0000000000000000000000000000000000000000" in new_res:
        send_udp_message3("notregistered")
    else:
        send_udp_message3("registered")

def send_udp_message(msgFromClient):
    # msgFromClient = "Hello UDP Server"
    bytesToSend = str.encode(msgFromClient,"utf-8")
    serverAddressPort = ("127.0.0.1", 9876)
    bufferSize = 1024
    # Create a UDP socket at client side
    UDPClientSocket = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)
    # Send to server using created UDP socket
    UDPClientSocket.sendto(bytesToSend, serverAddressPort)

def send_udp_message2(msgFromClient):
    # msgFromClient = "Hello UDP Server"
    bytesToSend = str.encode(msgFromClient,"utf-8")
    serverAddressPort = ("127.0.0.1", 9875)
    bufferSize = 1024
    # Create a UDP socket at client side
    UDPClientSocket = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)
    # Send to server using created UDP socket
    UDPClientSocket.sendto(bytesToSend, serverAddressPort)

def send_udp_message3(msgFromClient):
    # msgFromClient = "Hello UDP Server"
    bytesToSend = str.encode(msgFromClient, "utf-8")
    serverAddressPort = ("127.0.0.1", 9878)
    bufferSize = 1024
    # Create a UDP socket at client side
    UDPClientSocket = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)
    # Send to server using created UDP socket
    UDPClientSocket.sendto(bytesToSend, serverAddressPort)

#pre_registro(3, 'choscar', '123ccc', '1234')
#view_Pre_Registro('people347curp')
