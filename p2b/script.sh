python3 -m pytest.

# compile & check syntax
vyper ./battleship/battleship.vy

cd ./battleship && pytest --disable-warnings
