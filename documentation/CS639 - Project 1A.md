# Learnings
In this project, you will get your hands dirty by executing _custom transactions_.
You will also witness the fact that the transactions you submit are being validated, executed, and stored, by hundreds 
of other ethereum nodes -- making it a public and shared ledger.

## Step1: Setting up a lightweight client
To begin, install [MetaMask](https://metamask.io/download/) as an extension for your browser. As you proceed through the installation and first time setup, select the _"create new wallet"_ option. 

After you complete the setup, you should be able to switch from the Ethereum mainnet network to the **Goerli** test network. In order to do that, you will need to enable the "Show test networks" option in Advanced Settings.

Let's quickly explain some concepts you may/may not be aware of.
 - The _0x..._ value near your account is your wallet's address. When MetaMask creates a new wallet, it generates a public/private keypair. Your wallet's address is derived from your public key. You're able to use the funds in your wallet because you have the associated private key.
 - The MetaMask extension is just an app that connects to MetaMask's Ethereum instance. This chrome extension is not an Ethereum node, not even a [light node](https://www.alchemy.com/overviews/light-node). MetaMask (as a service) runs an Ethereum node -- your extension merely sends transactions/requests to that Ethereum node (backend), which are then further propogated to other Ethereum nodes.
 - **What is `goerli`?** Being a bit pedantic, Ethereum is a protocol, not a single chain. One can spin up a new chain with a new genesis (root) block. This is basically what consortium/enterprise blockchains do. To allow people to familiarize themselves with Ethereum, and to try their smart contracts before deploying them on the actual mainnet, Ethereum maintains some test networks (chains). `goerli` is one such test network. Think of it as a staging/testing environment while the Ethereum mainnet is your production server.

--- 

MetaMask's simple UI belies a pretty comprehensive API underneath. Navigate to [google.com](https://google.com) (or any hosted page, it doesn't really matter), and open [your browser's console](https://balsamiq.com/support/faqs/browserconsole/). Verify that `window.ethereum !== undefined` returns `true`.

Let's get started! (Try `console.log(Array(16).join('wat' - 1) + ' Batman');` to marvel at the [horror of JS' type-unsafety](https://www.destroyallsoftware.com/talks/wat)).




## Step2: Getting a wallet ready
Alas, to actually use the network you need money.

Sad, right? 

Fortunately, that's not the case when you are using a test network. There are ways to get funds to play around in the test network. To get it, execute 

```
var all_addr = await ethereum.request({ method: 'eth_requestAccounts' });
```

and finish the steps in the pop up. On the JS console, you'll see your address. As a running example, my wallet address is `0xfae17157d98473c7a7616f22a4cf2e338decfc20` . Be sure to use your own address though.

### Check wallet transactions
Theoretically, even a light node cannot easily see the list of trasactions -- this is because by definition, a light client does not download blocks/transactions. How do we check the transactions made into/from our wallet then?

Let's use the fact that blockchains/Ethereum are decentralized. We can use public blockchain explorers that index all transactions: [goerli.etherscan.io](https://goerli.etherscan.io/) is one such explorer. You can paste the public key of your wallet (`0xfae17157d98473c7a7616f22a4cf2e338decfc20`) to see the list of transactions associated with your wallet. Note that it will index the transactions that have been committed in a block. If your proposed transaction has not been committed, your transaction may not appear in such explorers. It usually takes 5-15 seconds to commit.

You can see the balance in your account on the top left corner of the page when you've searched for your wallet's address.

## Step 3: Seed funding round.
As we mentioned, there are services that deposit funds into your wallet for test networks. Such services are called `faucets`. Do a Google Search for `goerli faucets` to find potential ones. We have tried [this one](https://www.allthatnode.com/faucet/ethereum.dsrv) and can confirm that it works. Another one we have verified is [goerlifaucet.com](https://goerlifaucet.com/) even though it does require you to login with Google.

After you request for funds, check the etherscan website to see if the transaction has been committed.

## Step 4: Sending a transaction
Great, now we have money in our account, and are actually allowed to make transactions.

To confirm this, let's make a transaction. But we are stingy, and we had to work hard for our money, so let's send money from ourself, to ourself. Run 
```
var me = all_addr[0];
var sender = me;
var receiver = me;
var amount = 5 * 10**14; // We are sending 5 * 10**14 "wei" ETH. check the conversion rations: https://eth-converter.com/
var gas = 21000;
var params = { from: me, to: me, value: '0x' + amount.toString(16), gas: '0x' + gas.toString(16) };
var txHash = await ethereum.request({ method: 'eth_sendTransaction', params: [params] });
```
and accept the transaction in the pop up that appears.

This should return a transaction hash, say `0xbigtxnhash`. You can search for this hash on etherscan.io to see when it gets committed (included in a block). 

Aside: here we stop and consider the evidence of Ethereum being a decentralized P2P system. Our geth node did not directly contact the server running etherscan.io. It probably just posted our transaction to MetaMasks's servers. However since all blocks are gossiped, our transaction eventually reaches all participating nodes as soon as it is included in a proposed block.

---
### Gas in ethereum
Wait, all this sounds expensive! Our transaction has to be transferred, stored and executed across all these nodes. Why would they do all this for us? 

Introducing the concent of gas (Ethereum's fuel, geddit?).

If you look at the details of the transaction in etherscan, you'll see that 21000 gas was consumed. What does that mean? 

Let's check our wallet balance by searching for our address on etherscan. Waait a minute, why is that less than what we originally had!? 

Turns out we implicity had to pay gas fees for our transaction to go through. Aah, so we do have to pay to make some transactions. Less than ideal, but it makes sense. The nodes which are doing the heavy lifting for us need to get paid, right?

Two things to note here:
 - We need to pay gas proportional to the "complexity" of our transaction. Simple funds transfers have a fixed cost of 21000 (this number is specific to Ethereum!). But smart contracts allow us to execute arbitrary code by simply submitting a new transaction. The concept of gas means that a person will need to pay more gas if they want Ethereum to calculate `fibonacci(100)` than if they want to get the result of `fibonacci(5)`. 
 - 21000 gas consumed does not mean our fees is 21000 wei. Check the __Gas Fees__ in the details of the transaction on the explorer. Turns out our transaction told the miner that they could deduct anywhere between [0.000000008 Gwei, 1.500000011 Gwei] __per unit of gas__ to run our transaction. Ouch. We should have given a low offer to begin with. The miner of course charged us the highest fees we were willing to pay (1.5 Gwei per unit gas). Never mind, we'll fix it later. Question though: why did MetaMask propose such an exorbitant fee in the first place? The reason is that paying for more expensive gas typically leads to transactions being committed faster. As a miner, if I have to include transactions in my block, I will pick the ones which are willing to pay me more to do the same amount of work. Other transactions will thus face higher commit latency. Why does this notion of variable pricing exist, you ask? Because blockchains are built with financial incentives models. Miners run nodes to earn profit, and a financial solution is easier to design than a redesigned protocol which fixes high latency. (_I digress ..._)

# Turn-in
Amazing, we're all ready to go. Here is what you need to do to pass this assignment: give us money :)

Transfer 0.0005 eth from your public address to 0xc304b48cC18036942bc0d14Ce0408d208db8a0C5 **with your email ID in the data field**. We point 3 things here:
 - We are talking about goerli funds. We do not expect you to buy ETH tokens. Goerli funds are free, which you should have received from the faucet.
 - Your email ID should be in the form of abc@wisc.edu. You might need to convert it to hex to pass it as data. Use [this](https://docs.metamask.io/guide/sending-transactions.html) to figure out how to send data in a transaction.
 - This is a more complicated transaction than a simple funds transfer. You might need to allow more gas to be spent. Check out [the same link as above](https://docs.metamask.io/guide/sending-transactions.html) to figure out how to change the amount of gas you're willing to spend. Try increasing gas by ~100 till your transaction succeeds.
 
 # Verifying your submission:
 Search 0xc304b48cC18036942bc0d14Ce0408d208db8a0C5 in the chain explorer. Check that:
  - your transaction transfer 0.0005 eth
  - [decoding](https://www.convertstring.com/EncodeDecode/HexDecode) the data in your txn should result in your email (remove the beginning 0x). 

After your transaction commits, notice how much gas was consumed by your transaction and whether it was more than 21000.
  
## Testing.
Copy the tester-p1a.py file provided below. You can [copy the contents easily from here](https://gist.githubusercontent.com/darkryder/5867120aebc727acd36d20f2fd0e8858/raw/af8e8fd7de099b41039289c8588893476e97b1b5/tester-p1a.py). You need python3 to run this. If that is not installed on your local machine, you can run it on CSL machines. Run `python3 test-p1a.py email@id.com` with your wisc email id. You should see either `Result: test passed` or `Result: test failed`.