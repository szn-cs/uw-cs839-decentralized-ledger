python3 -m pytest .

# compile & check syntax
vyper ./dao.vy

pytest --disable-warnings

pytest --disable-warnings -k test_nothing
