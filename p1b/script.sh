python3 -m pytest .

# compile & check syntax
vyper ./battleship.vy

pytest --disable-warnings

pytest --disable-warnings -k test_initial_state
