from bitcoin_rpc_class import RPCHost
import configparser
import mysql.connector
import json
import requests

debug = True

config = configparser.RawConfigParser()
config.read('liquid.conf')

rpcHost = config.get('LIQUID', 'host')
rpcPort = config.get('LIQUID', 'port')
rpcUser = config.get('LIQUID', 'username')
rpcPassword = config.get('LIQUID', 'password')
rpcPassphrase = config.get('LIQUID', 'passphrase')
serverURL = 'http://' + rpcUser + ':' + rpcPassword + '@'+rpcHost+':' + str(rpcPort)

myHost = config.get('MYSQL', 'host')
myUser = config.get('MYSQL', 'username')
myPasswd = config.get('MYSQL', 'password')
myDatabase = config.get('MYSQL', 'database')

host = RPCHost(serverURL)
if (len(rpcPassphrase) > 0):
    result = host.call('walletpassphrase', rpcPassphrase, 60)
    print(result)

def getBlock(i):
    mydb = mysql.connector.connect(host=myHost, user=myUser, passwd=myPasswd, database=myDatabase)
    mycursor = mydb.cursor()
    sql = "SELECT * FROM blocks WHERE Height = {}".format(i)
    mycursor.execute(sql)
    data = mycursor.fetchall()

    if (len(data) < 1):
        print("New block {}".format(i))
        blockHash = host.call('getblockhash', i)
        block = host.call('getblock', blockHash)

        sql = "INSERT IGNORE INTO blocks (  Height, \
                                            ID, \
                                            Size, \
                                            Weight, \
                                            Version, \
                                            Time, \
                                            MerkleRoot, \
                                            TxNum ) VALUES (%s, %s, %s, %s, %s, FROM_UNIXTIME('%s'), %s, %s)"
        val = (i, blockHash, block['size'], block['weight'], block['version'], block['time'], block['merkleroot'], block['nTx'])
        mycursor.execute(sql, val)
        mydb.commit()

        # process TX
        for txid in block['tx']:
            if (debug): print("\tNew transaction {}".format(txid))
            tx = host.call('getrawtransaction', txid, 1)

            IsCoinbase = False
            IsPegin = False
            IsPegout = False
            IsIssuance = False
            IsReissuance = False
            OpReturn = False

            for vin in tx['vin']:
                # check coinbase
                if 'coinbase' in vin:
                    if (debug): print("\t\t Coinbase")
                    IsCoinbase = True
                # check pegin
                if 'is_pegin' in vin:
                    if (debug): print("\t\t IsPegin? {}".format(vin['is_pegin']))
                    if vin['is_pegin'] == True:
                        IsPegin = True
                        amount = 0
                        for vout in tx['vout']:
                            if 'value' in vout:
                                amount = amount + vout['value'] * pow(10, 8)

                        sql = "INSERT IGNORE INTO pegin (     Transaction, \
                                                              Amount, \
                                                              Block ) VALUES (%s, %s, %s)"
                        val = (txid, amount , i)
                        mycursor.execute(sql, val)
                        mydb.commit()

                # check issuance
                if 'issuance' in vin:
                    if (debug): print("\t\t Issuance ".format(vin['issuance']['isreissuance']))
                    if vin['issuance']['isreissuance'] == False:
                        IsIssuance = True
                        AssetId = vin['issuance']['asset']
                        Blind = False
                        if 'assetamount' in vin['issuance'] :
                            AssetAmount = vin['issuance']['assetamount'] * pow(10, 8)
                        else :
                            AssetAmount = 0
                            Blind = True
                        TokenId = vin['issuance']['token']
                        if 'tokenamount' in vin['issuance'] :
                            TokenAmount = vin['issuance']['tokenamount'] * pow(10, 8)
                        else :
                            TokenAmount = 0
                            #Blind = True
                        sql = "INSERT IGNORE INTO issuances (   Transaction, \
                                                                Asset, \
                                                                AssetAmount, \
                                                                Token, \
                                                                TokenAmount, \
                                                                Block, \
                                                                Blind ) VALUES (%s, %s, %s, %s, %s, %s, %s)"
                        val = (txid, AssetId, AssetAmount, TokenId, TokenAmount, i, Blind)
                        mycursor.execute(sql, val)
                        mydb.commit()
                    # check reissuance
                    else:
                        IsReissuance = True
                        AssetId = vin['issuance']['asset']
                        Blind = False
                        if 'assetamount' in vin['issuance'] :
                            AssetAmount = vin['issuance']['assetamount'] * pow(10, 8)
                        else :
                            AssetAmount = 0
                            Blind = True
                        sql = "INSERT IGNORE INTO reissuances ( Transaction, \
                                                                Asset, \
                                                                AssetAmount, \
                                                                Block,\
                                                                Blind ) VALUES (%s, %s, %s, %s, %s)"
                        val = (txid, AssetId, AssetAmount, i, Blind)
                        mycursor.execute(sql, val)
                        mydb.commit()

            fees = 0
            for vout in tx['vout']:
                # check pegout
                if 'pegout_addresses' in vout['scriptPubKey'] :
                    if (debug): print("\t\t pegout")
                    IsPegout = True
                    sql = "INSERT IGNORE INTO pegout (    Transaction, \
                                                          Amount, \
                                                          Block ) VALUES (%s, %s, %s)"
                    val = (txid, vout['value'] * pow(10, 8), i)
                    mycursor.execute(sql, val)
                    mydb.commit()

                # check op_return
                tokens = vout['scriptPubKey']['asm'].split(' ')
                if not IsCoinbase and not IsPegin and not IsPegout and not IsIssuance and not IsReissuance:
                    if tokens[0] == 'OP_RETURN' and len(tokens) == 2:
                        if (debug): print("\t\t op return")
                        OpReturn = True
                        sql = "INSERT IGNORE INTO opreturn (    Transaction, \
                                                                Payload, \
                                                                Block ) VALUES (%s, %s, %s)"
                        val = (txid, vout['scriptPubKey']['asm'].split(' ')[1], i)
                        mycursor.execute(sql, val)
                        mydb.commit()

                # calculate fees
                if vout['scriptPubKey']['type'] == 'fee':
                    fees = round(vout['value'] * pow(10, 8))


            sql = "INSERT IGNORE INTO transactions( ID, \
                                        Size, \
                                        Weight, \
                                        IsCoinbase, \
                                        IsPegin, \
                                        IsPegout, \
                                        IsIssuance, \
                                        IsReissuance, \
                                        OpReturn, \
                                        Fees, \
                                        Block) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
            val = (txid, tx['size'], tx['weight'], IsCoinbase, IsPegin, IsPegout, IsIssuance, IsReissuance, OpReturn, fees, i)
            mycursor.execute(sql, val)
            mydb.commit()

        mydb.close()

lastBlock = host.call('getblockchaininfo')['blocks']
for i in range(0, lastBlock):
   getBlock(i)
