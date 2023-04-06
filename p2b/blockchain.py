# forked from https://github.com/dvf/blockchain

import hashlib
import json
import time
import threading
import logging
from array import *

import requests
from flask import Flask, request


class Transaction(object):
    def __init__(self, sender, recipient, amount):
        self.sender = sender  # constraint: should exist in state
        self.recipient = recipient  # constraint: need not exist in state. Should exist in state if transaction is applied.
        self.amount = amount  # constraint: sender should have enough balance to send this amount

    def __str__(self) -> str:
        return "T(%s -> %s: %s)" % (self.sender, self.recipient, self.amount)

    def encode(self) -> str:
        return self.__dict__.copy()

    @staticmethod
    def decode(data):
        return Transaction(data['sender'], data['recipient'], data['amount'])

    def __lt__(self, other):
        if self.sender < other.sender:
            return True
        if self.sender > other.sender:
            return False
        if self.recipient < other.recipient:
            return True
        if self.recipient > other.recipient:
            return False
        if self.amount < other.amount:
            return True
        return False

    def __eq__(self, other) -> bool:
        return self.sender == other.sender and self.recipient == other.recipient and self.amount == other.amount


class Block(object):
    def __init__(self, number, transactions, previous_hash, miner):
        self.number = number  # constraint: should be 1 larger than the previous block
        self.transactions = transactions  # constraint: list of transactions. Ordering matters. They will be applied sequentlally.
        self.previous_hash = previous_hash  # constraint: Should match the previous mined block's hash
        self.miner = miner  # constraint: The node_identifier of the miner who mined this block
        self.hash = self._hash()

    def _hash(self):
        return hashlib.sha256(
            str(self.number).encode('utf-8') +
            str([str(txn) for txn in self.transactions]).encode('utf-8') +
            str(self.previous_hash).encode('utf-8') +
            str(self.miner).encode('utf-8')
        ).hexdigest()

    def __str__(self) -> str:
        return "B(#%s, %s, %s, %s, %s)" % (self.hash[:5], self.number, self.transactions, self.previous_hash, self.miner)

    def encode(self):
        encoded = self.__dict__.copy()
        encoded['transactions'] = [t.encode() for t in self.transactions]
        return encoded

    @staticmethod
    def decode(data):
        txns = [Transaction.decode(t) for t in data['transactions']]
        return Block(data['number'], txns, data['previous_hash'], data['miner'])


class State(object):
    def __init__(self):
        # You might want to think how you will store balance per person.
        self.account = {}  # {"account-id": <amount>}
        self.historyList = {}  # {"account": [(block #, amount)]}
        # You don't need to worry about persisting to disk. Storing in memory is fine.
        pass

    def encode(self):
        dumped = {}
        # Add all person -> balance pairs into `dumped`.
        dumped.update(self.account)
        return dumped

    def validate_txns(self, txns):
        result = []
        # returns a list of valid transactions.
        # You receive a list of transactions, and you try applying them to the state sequentially.
        # If a transaction can be applied, add it to result. (should be included)
        # note dependent tnx
        # do not commit to state
        stateCopy = self.account.copy()
        for txn in txns:
            if txn.sender not in stateCopy:
                continue
            if txn.recipient not in stateCopy:
                stateCopy[txn.recipient] = 0
            if stateCopy[txn.sender] < txn.amount:
                continue
            stateCopy[txn.sender] -= txn.amount
            stateCopy[txn.recipient] += txn.amount
            result.append(txn)

        return result

    def apply_block(self, block):
        # apply the block to the state.
        if (block.number == 1):
            self.account['A'] = 10000

        logging.info("Block (#%s) applied to state. %d transactions applied" % (block.hash, len(block.transactions)))
        accountInvolved = set()

        for tnx in block.transactions:
            accountInvolved.add(tnx.sender)
            accountInvolved.add(tnx.recipient)
            self.account[tnx.sender] -= tnx.amount
            if not tnx.recipient in self.account:
                self.account[tnx.recipient] = 0
            self.account[tnx.recipient] += tnx.amount

        for account in accountInvolved:
            if account not in self.historyList:
                self.historyList[account] = []
            self.historyList[account].append((block.number, self.account[account]))

    def history(self, account):
        # return a list of (blockNumber, value changes) that this account went through
        list = []  # [(blocknumber, amount),...]
        if not account in self.historyList:
            return list
        list.extend(self.historyList[account])
        return self.historyList[account]


class Blockchain(object):
    def __init__(self):
        self.nodes = []
        self.node_identifier = 0
        self.block_mine_time = 5

        # in memory datastructures.
        self.current_transactions = []  # A list of pending  `Transaction`
        self.chain = []  # A list of committed `Block`s
        self.state = State()

    # Determine if I should accept a new block. Does it pass all semantic checks? Search for "constraint" in this file.
    # :param block: A new proposed block
    # :return: True if valid, False if not
    # """
    def is_new_block_valid(self, block, received_blockhash):  # needs to check all constraints if a block is valid
        # if genesis block
        genesis = False
        genesisBlock = Block(1, [], '0xfeedcafe', block.miner)
        if (block.previous_hash == genesisBlock.hash and block.number == 1 or len(self.chain) == 0):
            genesis = True

        prevHash = '0xfeedcafe'
        prevNumber = 0
        if not genesis:
            lastBlock = self.chain[len(self.chain) - 1]
            prevHash = lastBlock.hash
            prevNumber = lastBlock.number

        # check if received block is valid
        # 1. Hash should match content
        if (block.hash != received_blockhash):
            return False
        # 2. Previous hash should match previous block
        if (block.previous_hash != prevHash):
            return False
        # 3. Transactions should be valid (all apply to block)
        validTnxs = self.state.validate_txns(block.transactions)
        if (len(validTnxs) != len(block.transactions)):
            return False
        # 4. Block number should be one higher than previous block
        if (block.number <= prevNumber):
            return False
        # 5. miner should be correct (next RR)
        if (not genesis):
            nodesNumber = len(self.nodes)
            previousMiner = self.chain[len(self.chain) - 1].miner
            previousMinerNodeIndex = self.nodes.index(previousMiner)
            nextMinerIndex = (previousMinerNodeIndex + 1) % nodesNumber
            nextMinerIdentifier = self.nodes[nextMinerIndex]
            if not (nextMinerIdentifier == block.miner):
                return False

        return True

    def trigger_new_block_mine(self, genesis=False):  # call this method when you want this node to create a block.
        thread = threading.Thread(target=self.__mine_new_block_in_thread, args=(genesis,))
        thread.start()

    # Create a new Block in the Blockchain
    # this is where you are supposed to create a new valid block.
    # A transaction that fails to get in should still be retried during next block.
    # This will also automatically inform its nodes about a new block!
    #
    # :return: New Block
    # Work on constructing a valid block when it's your turn.
    def __mine_new_block_in_thread(self, genesis=False):
        logging.info("[MINER] waiting for new transactions before mining new block...")
        time.sleep(self.block_mine_time)  # Wait for new transactions to come in
        miner = self.node_identifier
        txnsWorkingSet = []

        if genesis:
            block = Block(1, [], '0xfeedcafe', miner)
        else:
            self.current_transactions.sort()

            # create a new *valid* block with available transactions. Replace the arguments in the line below.
            previousBlock = self.chain[len(self.chain) - 1]
            txnsWorkingSet.extend(self.state.validate_txns(self.current_transactions))
            self.current_transactions = [i for i in self.current_transactions if i not in txnsWorkingSet]
            block = Block(previousBlock.number + 1, txnsWorkingSet, previousBlock._hash(), miner)

        # make changes to in-memory data structures to reflect the new block. Check Blockchain.__init__ method for in-memory datastructures
        self.state.apply_block(block)
        self.chain.append(block)
        if genesis:
            # at time of genesis, change state to have 'A': 10000 (person A has 10000)
            self.state.account['A'] = 10000

        logging.info("[MINER] constructed new block with %d transactions. Informing others about: #%s" % (len(block.transactions), block.hash[:5]))
        # broadcast the new block to all nodes.
        for node in self.nodes:
            if node == self.node_identifier:
                continue
            requests.post(f'http://localhost:{node}/inform/block', json=block.encode())

    # Add this transaction to the transaction mempool. We will try to include this transaction in the next block until it succeeds.
    def new_transaction(self, sender, recipient, amount):
        self.current_transactions.append(Transaction(sender, recipient, amount))
