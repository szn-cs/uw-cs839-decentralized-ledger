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
  curl -X POST http://localhost:${PORT}/transactions/new -H 'Content-Type: application/json' -d '{"sender": "A", "recipient": "B", "amount": 10}'
  curl http://localhost:${PORT}/dump
  # start experiment manually: create the first (genesis) block and kick-start the rest of the blockchain pipeline
  curl http://localhost:5001/startexp/
}

function submit() {
  Copy your blockchain.py and server.py files to /p/course/cs639-kaimast/handin/p2b/*.py
}

function test() {
  python3 testp2b.py -v
  python3 testp2b.py -v Tests3UpdateableState
  python3 testp2b.py -v Tests3UpdateableState.test_e_check_transitive_validity_changes

}