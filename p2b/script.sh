# t: time to wait before proposing a block
function runServer() {
  # terminal 1
  python3 server.py -p 5001 -n 5001 5002 5003 -t 10
  # terminal 2
  python3 server.py -p 5002 -n 5001 5002 5003 -t 10
  # terminal 3
  python3 server.py -p 5003 -n 5001 5002 5003 -t 10
}

function runClient() {
  PORT=5001

  #  new transation
  curl -X POST http://localhost:${PORT}/transactions/new -H 'Content-Type: application/json' -d '{"sender": "A", "recipient": "B", "amount": 10}'

  # node state
  curl http://localhost:${PORT}/dump

  # start experiment manually: create the first (genesis) block and kick-start the rest of the blockchain pipeline
  curl http://localhost:5001/startexp/
}

function submit() {
  # Copy your blockchain.py and server.py files to /p/course/cs639-kaimast/handin/p2b/*.py
}

function testAll() {
  python3 testp2b.py -v
  python3 testp2b.py -v Test1ChainTests
  python3 testp2b.py -v Test2TxnStateSimple
  python3 testp2b.py -v Tests3UpdateableState
  python3 testp2b.py -v Tests4SemanticValidations
  python3 testp2b.py -v Tests5History

  # run specific test
  python3 testp2b.py -v Tests3UpdateableState.test_e_check_transitive_validity_changes
}

# Propose a couple of transactions to different nodes.
# See if these transactions end up being included in proposed blocks.
# You can check it by dumping the state (as discussed above, and below in how-to-debug). Or just print stuff to the log.
function test_2() {

}
