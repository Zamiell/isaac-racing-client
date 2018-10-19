import os
import xml.etree.ElementTree as ET

# This converts all of the room shapes from the STB XMLs to a Lua table

floor_name_mapping = {
    '01.basement':         'F1_0',
    '02.cellar':           'F1_1',
    '03.burning basement': 'F1_2',
    '04.caves':            'F2_0',
    '05.catacombs':        'F2_1',
    '06.flooded caves':    'F2_2',
    '07.depths':           'F3_0',
    '08.necropolis':       'F3_1',
    '09.dank depths':      'F3_2',
    '10.womb':             'F4_0',
    '11.utero':            'F4_1',
    '12.scarred womb':     'F4_2',
    '14.sheol':            'F5_0',
    '15.cathedral':        'F5_1',
    '16.dark room':        'F6_0',
    '17.chest':            'F6_1',
}

# Go through every file
for file_name in os.listdir(os.getcwd()):
    if not file_name.endswith(".xml"):
        continue

    print('  -- ' + file_name)
    print('  ' + floor_name_mapping[file_name[:-4]] + ' = {')

    rooms = ET.parse(file_name).getroot()
    for room in rooms:
        variant = room.attrib['variant'] # This is the room ID
        shape = room.attrib['shape']
        print('    [' + variant + '] = ' + shape + ',')

    print('  },\n')
