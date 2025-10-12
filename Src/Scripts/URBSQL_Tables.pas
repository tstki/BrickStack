unit URBSQL_Tables;

// Original Rebrickable tables

// Source:
// https://github.com/ojuuji/rb.db/blob/master/schema/rb_tables.sql

interface

uses
  USQLUpdate;

const
   RB_CreateTablesAndTriggers: array[0..14] of TTableSQL = (
    (TableName: 'colors';
      SQL: 'CREATE TABLE colors(' +
      '  id INTEGER PRIMARY KEY,' + 
      '  name TEXT NOT NULL,' + 
      '  rgb TEXT NOT NULL CHECK(length(rgb) == 6 AND NOT rgb GLOB ''*[^0-9A-Fa-f]*''),' +
      '  is_trans TEXT NOT NULL,' +
      '  num_parts INTEGER NOT NULL,' + 
      '  num_sets INTEGER NOT NULL,' + 
      '  y1 TEXT,' + 
      '  y2 TEXT,' + 
      '  CHECK (y1 IS NULL AND y2 IS NULL OR y1 IS NOT NULL AND y2 IS NOT NULL AND y1 <= y2)' + 
      ') STRICT;'
    ),
    (TableName: 'themes';
      SQL: 'CREATE TABLE themes(' +
      '  id INTEGER PRIMARY KEY,' +
      '  name TEXT NOT NULL,' +
      '  parent_id TEXT' +
      ') STRICT;'
    ),
    (TableName: 'part_categories';
      SQL: 'CREATE TABLE part_categories(' +
      '  id INTEGER PRIMARY KEY,' +
      '  name TEXT NOT NULL' +
      ') STRICT;'
    ),
    (TableName: 'parts';
      SQL: 'CREATE TABLE parts(' +
      '  part_num TEXT PRIMARY KEY CHECK(NOT part_num GLOB ''*[^0-9A-Za-z.-]*''),' +
      '  name TEXT NOT NULL,' +
      '  part_cat_id INTEGER NOT NULL REFERENCES part_categories(id),' +
      '  part_material TEXT NOT NULL CHECK(part_material IN (''Cardboard/Paper'', ''Cloth'', ''Flexible Plastic'', ''Foam'', ''Metal'', ''Plastic'', ''Rubber''))' +
      ') STRICT;'
    ),
    (TableName: 'part_relationships';
      SQL: 'CREATE TABLE part_relationships(' +
      '  rel_type TEXT NOT NULL CHECK(rel_type IN (''A'', ''B'', ''M'', ''P'', ''R'', ''T'')),' + 
      '  child_part_num TEXT NOT NULL REFERENCES parts(part_num),' + 
      '  parent_part_num TEXT NOT NULL REFERENCES parts(part_num)' + 
      ') STRICT;'
    ),
    (TableName: 'elements';
      SQL: 'CREATE TABLE elements(' +
      '  element_id INTEGER PRIMARY KEY,' +
      '  part_num TEXT NOT NULL REFERENCES parts(part_num),' +
      '  color_id INTEGER NOT NULL REFERENCES colors(id),' +
      '  design_id TEXT' +
      ') STRICT;'
    ),
    (TableName: 'minifigs';
      SQL: 'CREATE TABLE minifigs(' +
      '  fig_num TEXT PRIMARY KEY CHECK(fig_num GLOB ''fig-[0-9][0-9][0-9][0-9][0-9][0-9]''),' +
      '  name TEXT NOT NULL,' +
      '  num_parts INTEGER NOT NULL,' +
      '  img_url TEXT NOT NULL,' +
      '  CHECK(img_url = ''https://cdn.rebrickable.com/media/sets/'' || fig_num || ''.jpg'')' +
      ') STRICT;'
    ),
    (TableName: 'sets';
      SQL: 'CREATE TABLE sets(' +
      '  set_num TEXT PRIMARY KEY CHECK(set_num NOT GLOB ''*[^0-9A-Za-z.-]*'' AND set_num NOT LIKE ''fig-%''),' +
      '  name TEXT NOT NULL,' +
      '  year INTEGER NOT NULL CHECK(year >= 1932 AND year <= 1 + CAST(strftime(''%Y'', CURRENT_TIMESTAMP) AS INTEGER)),' +
      '  theme_id INTEGER NOT NULL REFERENCES themes(id),' +
      '  num_parts INTEGER NOT NULL,' +
      '  img_url TEXT NOT NULL,' +
      '  CHECK(img_url = ''https://cdn.rebrickable.com/media/sets/'' || lower(set_num) || ''.jpg'')' +
      ') STRICT;'
    ),
    (TableName: 'inventories';
      SQL: 'CREATE TABLE inventories(' +
      '  id INTEGER PRIMARY KEY,' + 
      '  version INTEGER NOT NULL CHECK(version >= 1),' + 
      '  set_num TEXT NOT NULL REFERENCES set_nums(set_num),' + 
      '  CHECK (version = 1 OR set_num NOT LIKE ''fig-%'')' + 
      ') STRICT;'
    ),
    (TableName: 'inventory_minifigs';
      SQL: 'CREATE TABLE inventory_minifigs(' +
      '  inventory_id INTEGER NOT NULL REFERENCES inventories(id),' +
      '  fig_num TEXT NOT NULL REFERENCES minifigs(fig_num),' +
      '  quantity INTEGER NOT NULL' +
      ') STRICT;'
    ),
    (TableName: 'inventory_parts';
      SQL: 'CREATE TABLE inventory_parts(' +
      '  inventory_id INTEGER NOT NULL REFERENCES inventories(id),' +
      '  part_num TEXT NOT NULL REFERENCES parts(part_num),' +
      '  color_id INTEGER NOT NULL REFERENCES colors(id),' +
      '  quantity INTEGER NOT NULL,' +
      '  is_spare TEXT NOT NULL,' +
      '  img_url TEXT CHECK(instr(img_url, ''https://cdn.rebrickable.com/media/parts/'') == 1)' +
      ') STRICT;'
    ),
    (TableName: 'inventory_sets';
      SQL: 'CREATE TABLE inventory_sets(' +
      '  inventory_id INTEGER NOT NULL REFERENCES inventories(id),' + 
      '  set_num TEXT NOT NULL REFERENCES sets(set_num),' + 
      '  quantity INTEGER NOT NULL' + 
      ') STRICT;'
    ),
    (TableName: 'set_nums';
      SQL: 'CREATE TABLE set_nums(' +
      '  set_num TEXT PRIMARY KEY' +
      ') STRICT;'
    ),
    (TableName: 'insert_set_num';
      SQL: 'CREATE TRIGGER insert_set_num' +
      '  AFTER INSERT ON sets FOR EACH ROW' + 
      ' BEGIN' + 
      '  INSERT INTO set_nums (set_num) VALUES (new.set_num);' + 
      'END;'
    ),
    (TableName: 'insert_fig_num';
      SQL: 'CREATE TRIGGER insert_fig_num' +
      '  AFTER INSERT ON minifigs FOR EACH ROW' + 
      ' BEGIN' + 
      '  INSERT INTO set_nums (set_num) VALUES (new.fig_num);' + 
      'END;'
    )
  );

implementation

{
MIT License

Copyright (c) 2024 Mikalai Ananenka

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
}

end.