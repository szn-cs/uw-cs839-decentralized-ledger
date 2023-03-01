from vyper.interfaces import ERC20

implements: ERC20

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)

# TODO add state that tracks proposals here

@external
def __init__():
    self.totalSupply = 0


# Shareholding: convert Ether into the token 
@external
@payable
@nonreentrant("lock")
def buyToken():
    # TODO implement
    pass

# convert token into Ether 
@external
@nonpayable
@nonreentrant("lock")
def sellToken(_value: uint256):
    # TODO implement
    pass

# TODO add other ERC20 methods here


# proposal: address, i amount of Ether to transfer
@external
@nonpayable
@nonreentrant("lock")
def createProposal(_uid: uint256, _recipient: address, _amount: uint256):

    # _uid: pick a random number
    # if _uid inuse or _amount == 0

    # TODO implement
    pass

# stakeholders need to approve proposal. 
# Successful proporal: Yes votes must represent majority.
@external
@nonpayable
@nonreentrant("lock")
def approveProposal(_uid: uint256):
    # if is stakeholders account.
    # If the entity calling the function is not a stakeholder, the transaction should be reverted.
    # Similarly, if the caller already voted the call should fail.

    pass
