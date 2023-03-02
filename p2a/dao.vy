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

@external
def transfer(_to : address, _value : uint256) -> bool:
    """
    @dev Transfer token for a specified address
    @param _to The address to transfer to.
    @param _value The amount to be transferred.
    """
    # NOTE: vyper does not allow underflows
    #       so the following subtraction would revert on insufficient balance
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    log Transfer(msg.sender, _to, _value)
    return True

@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    """
     @dev Transfer tokens from one address to another.
     @param _from address The address which you want to send tokens from
     @param _to address The address which you want to transfer to
     @param _value uint256 the amount of tokens to be transferred
    """
    # NOTE: vyper does not allow underflows
    #       so the following subtraction would revert on insufficient balance
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    # NOTE: vyper does not allow underflows
    #      so the following subtraction would revert on insufficient allowance
    self.allowance[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    return True

@external
def approve(_spender : address, _value : uint256) -> bool:
    """
    @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
         Beware that changing an allowance with this method brings the risk that someone may use both the old
         and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
         race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
         https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param _spender The address which will spend the funds.
    @param _value The amount of tokens to be spent.
    """
    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True


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


