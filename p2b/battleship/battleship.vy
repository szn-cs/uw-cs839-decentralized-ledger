# @version ^0.3.0
''' A simple implementation of battleship in Vyper '''


NUM_PIECES: constant(uint32) = 5
BOARD_SIZE: constant(uint32) = 5

# What phase of the game are we in ?
# Start with SET and end with END
PHASE_SET: constant(int32) = 0
PHASE_SHOOT: constant(int32) = 1
PHASE_END: constant(int32) = 2

# Each player has a 5-by-5 board
# The field track where the player's boats are located and what fields were hit
# Player should not be allowed to shoot the same field twice, even if it is empty
FIELD_EMPTY: constant(uint32) = 0
FIELD_BOAT: constant(uint32) = 1
FIELD_HIT: constant(uint32) = 2

players: immutable(address[2])

# Which player has the next turn? Only used during the SHOOT phase
next_player: int32

# Which phase of the game is it?
phase: int32

matrix: uint32[2][BOARD_SIZE][BOARD_SIZE]
counter: uint32[2]

@external
def __init__(player1: address, player2: address):
    players = [player1, player2]
    self.next_player = 0
    self.phase = PHASE_SET

    self.next_player = -1
    self.matrix = empty(uint32[2][BOARD_SIZE][BOARD_SIZE])
    self.counter = empty(uint32[2])


@external
def set_field(pos_x: uint32, pos_y: uint32):
    '''
    Sets a ship at the specified coordinates
    This should only be allowed in the initial phase of the game

    Players are allowed to call this out of order, but at most NUM_PIECES times
    '''
    if self.phase != PHASE_SET:
        raise "Wrong phase"

    if pos_x >= BOARD_SIZE or pos_y >= BOARD_SIZE:
        raise "Position out of bounds"

    player: int32 = -1

    if players[0] == msg.sender :
      player = 0
    elif players[1] == msg.sender :
      player = 1
    else :
      raise "Unknown player"

    if self.counter[player] >= NUM_PIECES :
      raise "too many requests"

    if self.matrix[player][pos_x][pos_y] != FIELD_EMPTY :
      raise "duplicate entry"
    
    self.matrix[player][pos_x][pos_y] = FIELD_BOAT
    self.counter[player] += 1
    

@external
def shoot(pos_x: uint32, pos_y: uint32):
    '''
    Shoot a specific field on the other players board
    This should only be allowed if it is the calling player's turn and only during the SHOOT phase
    '''

    if pos_x >= BOARD_SIZE or pos_y >= BOARD_SIZE:
        raise "Position out of bounds"

    if self.phase != PHASE_SHOOT:
        raise "Wrong phase"

    # Add shooting logic and victory logic here
    player: int32 = -1
    adversary: int32 = -1
    if players[0] == msg.sender :
      player = 0
      adversary = 1
    elif players[1] == msg.sender :
      player = 1
      adversary = 0
    else :
      raise "Unknown player"

    if self.next_player == -1 :
      self.next_player = player
    elif (self.next_player != player) :
      raise "wrong turn"

    if self.counter[player] <= 0 or self.counter[player] <= 0 :
      raise "don't be sily"

    if self.matrix[adversary][pos_x][pos_y] == FIELD_HIT :
      raise "dupicate attempt"

    if self.matrix[adversary][pos_x][pos_y] == FIELD_BOAT :
      self.counter[player] -= 1

    self.matrix[adversary][pos_x][pos_y] = FIELD_HIT
    
    if self.counter[player] <= 0 :
      self.phase = PHASE_END


@external
@view
def has_winner() -> bool:
    return self.phase == PHASE_END

@external
@view
def get_winner() -> address:
    ''' Returns the address of the winner's account '''
    player1: uint32 = 0
    player2: uint32 = 1

    if self.counter[player1] <= 0 :
      return players[player1]
    
    elif self.counter[player2] <= 0 :
      return players[player2]

    # Raise an error if no one won yet
    raise "No one won yet"
