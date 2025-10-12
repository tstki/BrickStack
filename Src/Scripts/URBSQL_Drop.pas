unit URBSQL_Drop;

// Original Rebrickable tables

// Source:
// https://github.com/ojuuji/rb.db/blob/master/schema/rb_drop.sql

interface

uses
  USQLUpdate;

const
  RB_DropTablesIndexesAndTriggers: array[0..31] of TTableSQL = (
    (TableName: 'colors';                                  SQL: 'DROP TABLE IF EXISTS colors;'),
    (TableName: 'colors_name_idx';                         SQL: 'DROP INDEX IF EXISTS colors_name_idx;'),
    (TableName: 'themes';                                  SQL: 'DROP TABLE IF EXISTS themes;'),
    (TableName: 'themes_parent_id_idx';                    SQL: 'DROP INDEX IF EXISTS themes_parent_id_idx;'),
    (TableName: 'part_categories';                         SQL: 'DROP TABLE IF EXISTS part_categories;'),
    (TableName: 'parts';                                   SQL: 'DROP TABLE IF EXISTS parts;'),
    (TableName: 'parts_part_cat_id_idx';                   SQL: 'DROP INDEX IF EXISTS parts_part_cat_id_idx;'),
    (TableName: 'parts_part_material_idx';                 SQL: 'DROP INDEX IF EXISTS parts_part_material_idx;'),
    (TableName: 'part_relationships';                      SQL: 'DROP TABLE IF EXISTS part_relationships;'),
    (TableName: 'part_relationships_rel_type_idx';         SQL: 'DROP INDEX IF EXISTS part_relationships_rel_type_idx;'),
    (TableName: 'part_relationships_child_part_num_idx';   SQL: 'DROP INDEX IF EXISTS part_relationships_child_part_num_idx;'),
    (TableName: 'part_relationships_parent_part_num_idx';  SQL: 'DROP INDEX IF EXISTS part_relationships_parent_part_num_idx;'),
    (TableName: 'elements';                                SQL: 'DROP TABLE IF EXISTS elements;'),
    (TableName: 'elements_part_num_color_id_idx';          SQL: 'DROP INDEX IF EXISTS elements_part_num_color_id_idx;'),
    (TableName: 'minifigs';                                SQL: 'DROP TABLE IF EXISTS minifigs;'),
    (TableName: 'sets';                                    SQL: 'DROP TABLE IF EXISTS sets;'),
    (TableName: 'sets_year_idx';                           SQL: 'DROP INDEX IF EXISTS sets_year_idx;'),
    (TableName: 'sets_theme_id_idx';                       SQL: 'DROP INDEX IF EXISTS sets_theme_id_idx;'),
    (TableName: 'inventories';                             SQL: 'DROP TABLE IF EXISTS inventories;'),
    (TableName: 'inventories_set_num_version_idx';         SQL: 'DROP INDEX IF EXISTS inventories_set_num_version_idx;'),
    (TableName: 'inventory_minifigs';                      SQL: 'DROP TABLE IF EXISTS inventory_minifigs;'),
    (TableName: 'inventory_minifigs_inventory_id_idx';     SQL: 'DROP INDEX IF EXISTS inventory_minifigs_inventory_id_idx;'),
    (TableName: 'inventory_minifigs_fig_num_idx';          SQL: 'DROP INDEX IF EXISTS inventory_minifigs_fig_num_idx;'),
    (TableName: 'inventory_parts';                         SQL: 'DROP TABLE IF EXISTS inventory_parts;'),
    (TableName: 'inventory_parts_inventory_id_idx';        SQL: 'DROP TABLE IF EXISTS inventory_parts_inventory_id_idx;'),
    (TableName: 'inventory_parts_part_num_color_id_idx';   SQL: 'DROP INDEX IF EXISTS inventory_parts_part_num_color_id_idx;'),
    (TableName: 'inventory_sets';                          SQL: 'DROP TABLE IF EXISTS inventory_sets;'),
    (TableName: 'inventory_sets_inventory_id_idx';         SQL: 'DROP TABLE IF EXISTS inventory_sets_inventory_id_idx;'),
    (TableName: 'inventory_sets_set_num_idx';              SQL: 'DROP INDEX IF EXISTS inventory_sets_set_num_idx;'),
    (TableName: 'set_nums';                                SQL: 'DROP TABLE IF EXISTS set_nums;'),
    (TableName: 'insert_set_num';                          SQL: 'DROP TRIGGER IF EXISTS insert_set_num;'),
    (TableName: 'insert_fig_num';                          SQL: 'DROP TRIGGER IF EXISTS insert_fig_num;')
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