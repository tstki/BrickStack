unit URBSQL_Indexes;

// Original Rebrickable tables

// Source:
// https://github.com/ojuuji/rb.db/blob/master/schema/rb_indexes.sql

interface

uses
  USQLUpdate;

const
  RB_CreateIndexes: array[0..16] of TTableSQL = (
    (TableName: 'colors_name_idx';                        SQL: 'CREATE UNIQUE INDEX colors_name_idx ON colors(name);'),
    (TableName: 'themes_parent_id_idx';                   SQL: 'CREATE INDEX themes_parent_id_idx ON themes(parent_id);'),
    (TableName: 'parts_part_cat_id_idx';                  SQL: 'CREATE INDEX parts_part_cat_id_idx ON parts(part_cat_id);'),
    (TableName: 'parts_part_material_idx';                SQL: 'CREATE INDEX parts_part_material_idx ON parts(part_material);'),
    (TableName: 'part_relationships_rel_type_idx';        SQL: 'CREATE INDEX part_relationships_rel_type_idx ON part_relationships(rel_type);'),
    (TableName: 'part_relationships_child_part_num_idx';  SQL: 'CREATE INDEX part_relationships_child_part_num_idx ON part_relationships(child_part_num);'),
    (TableName: 'part_relationships_parent_part_num_idx'; SQL: 'CREATE INDEX part_relationships_parent_part_num_idx ON part_relationships(parent_part_num);'),
    (TableName: 'elements_part_num_color_id_idx';         SQL: 'CREATE INDEX elements_part_num_color_id_idx ON elements(part_num, color_id);'),
    (TableName: 'sets_year_idx';                          SQL: 'CREATE INDEX sets_year_idx ON sets(year);'),
    (TableName: 'sets_theme_id_idx';                      SQL: 'CREATE INDEX sets_theme_id_idx ON sets(theme_id);'),
    (TableName: 'inventories_set_num_version_idx';        SQL: 'CREATE UNIQUE INDEX inventories_set_num_version_idx ON inventories(set_num, version);'),
    (TableName: 'inventory_minifigs_inventory_id_idx';    SQL: 'CREATE INDEX inventory_minifigs_inventory_id_idx ON inventory_minifigs(inventory_id);'),
    (TableName: 'inventory_minifigs_fig_num_idx';         SQL: 'CREATE INDEX inventory_minifigs_fig_num_idx ON inventory_minifigs(fig_num);'),
    (TableName: 'inventory_parts_inventory_id_idx';       SQL: 'CREATE INDEX inventory_parts_inventory_id_idx ON inventory_parts(inventory_id);'),
    (TableName: 'inventory_parts_part_num_color_id_idx';  SQL: 'CREATE INDEX inventory_parts_part_num_color_id_idx ON inventory_parts(part_num, color_id);'),
    (TableName: 'inventory_sets_inventory_id_idx';        SQL: 'CREATE INDEX inventory_sets_inventory_id_idx ON inventory_sets(inventory_id);'),
    (TableName: 'inventory_sets_set_num_idx';             SQL: 'CREATE INDEX inventory_sets_set_num_idx ON inventory_sets(set_num);')
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