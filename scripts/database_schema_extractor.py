"""
This module extracts the complete schema (tables, columns, indexes, foreign keys)
from a SQLite database and writes it to a human-readable Markdown report.
"""

import sqlite3
import os
from datetime import datetime

def get_database_schema(db_path: str, output_dir: str = 'docs') -> str | None:
    """
    Extract every table-definition detail from a SQLite database and
    persist it to a Markdown file.

    Parameters
        db_path : str
            Absolute or relative path to the SQLite file.
        output_dir : str, optional
            Directory in which the report will be created (default: 'docs').

    Returns
        str | None
            Absolute path of the generated Markdown file on success, ``None`` on failure.
    """

    # -------------------------------------------------------------------------
    # 1. Prepare the output directory and file
    # -------------------------------------------------------------------------
    os.makedirs(output_dir, exist_ok=True)        # Create if it does not exist
    output_file = os.path.join(output_dir, 'database_structure.md')

    # -------------------------------------------------------------------------
    # 2. Connect to the database
    # -------------------------------------------------------------------------
    conn: sqlite3.Connection | None = None
    try:
        conn = sqlite3.connect(db_path)           # Open SQLite file
        conn.row_factory = sqlite3.Row           # Allow column-name access
        cursor = conn.cursor()

        # ---------------------------------------------------------------------
        # 3. Discover every table in the database
        # ---------------------------------------------------------------------
        cursor.execute(
            "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;"
        )
        tables: list[str] = [row[0] for row in cursor.fetchall()]

        # ---------------------------------------------------------------------
        # 4. Write the Markdown report
        # ---------------------------------------------------------------------
        with open(output_file, 'w', encoding='utf-8') as f:
            # 4.1 Document header
            f.write("# Database Structure Report\n\n")
            f.write(f"**Database**: `{os.path.basename(db_path)}`\n")
            f.write(f"**Generated on**: {datetime.now():%Y-%m-%d %H:%M:%S}\n")
            f.write(f"**Total Tables**: {len(tables)}\n\n")

            # 4.2 Table of contents
            f.write("## Table of Contents\n")
            for tbl in tables:
                # GitHub-compatible anchor
                anchor = tbl.lower().replace(' ', '-').replace('_', '-')
                f.write(f"- [`{tbl}`](#{anchor})\n")
            f.write("\n")

            # 4.3 Iterate over each table
            for table_name in tables:
                f.write(f"## Table: `{table_name}`\n\n")

                # --- Row count -------------------------------------------------
                cursor.execute(f"SELECT COUNT(*) FROM [{table_name}];")
                row_count: int = cursor.fetchone()[0]
                f.write(f"**Row Count**: {row_count:,}\n\n")

                # --- Column definitions ---------------------------------------
                cursor.execute(f"PRAGMA table_info([{table_name}]);")
                columns = cursor.fetchall()  # (cid, name, type, notnull, dflt_value, pk)

                f.write("| Column Name | Data Type | Not Null | Default | Primary Key |\n")
                f.write("|-------------|-----------|----------|---------|-------------|\n")
                for cid, name, dtype, notnull, dflt, pk in columns:
                    f.write(
                        f"| `{name}` | `{dtype}` | "
                        f"{'✓' if notnull else ''} | "
                        f"`{dflt or ''}` | "
                        f"{'✓' if pk else ''} |\n"
                    )

                # --- Indexes ---------------------------------------------------
                cursor.execute(f"PRAGMA index_list([{table_name}]);")
                # (seq, name, unique, origin, partial)
                indexes = cursor.fetchall()
                if indexes:
                    f.write("\n**Indexes**:\n")
                    for seq, idx_name, unique, origin, partial in indexes:
                        f.write(f"- {'UNIQUE' if unique else 'INDEX'} `{idx_name}`\n")

                        # Show the indexed columns
                        cursor.execute(f"PRAGMA index_info([{idx_name}]);")
                        # (seqno, cid, name)
                        index_cols = cursor.fetchall()
                        if index_cols:
                            col_names = [f"`{c[2]}`" for c in index_cols]
                            f.write(f"  - Columns: {', '.join(col_names)}\n")

                # --- Foreign keys ---------------------------------------------
                cursor.execute(f"PRAGMA foreign_key_list([{table_name}]);")
                # (id, seq, table, from, to, on_update, on_delete, match)
                foreign_keys = cursor.fetchall()
                if foreign_keys:
                    f.write("\n**Foreign Keys**:\n")
                    for fk_id, seq, ref_tbl, col, ref_col, on_upd, on_del, match in foreign_keys:
                        f.write(f"- `{col}` → `{ref_tbl}`.`{ref_col}`\n")

                f.write("\n---\n\n")

        print(f"✅ Database structure report generated: {output_file}")
        return output_file

    # -------------------------------------------------------------------------
    # 5. Handle errors and clean up
    # -------------------------------------------------------------------------
    except sqlite3.Error as e:
        print(f"❌ Database error: {e}")
        return None
    finally:
        if conn:
            conn.close()  # Always close the connection

# -----------------------------------------------------------------------------
# 6. Stand-alone usage
# -----------------------------------------------------------------------------
if __name__ == "__main__":
    # Path to the database file
    db_path = r"C:\Users\cloris\Desktop\kbo_database.db"

    # Proceed only if the file exists
    if os.path.exists(db_path):
        report_path = get_database_schema(db_path)
        if report_path:
            abs_path = os.path.abspath(report_path)
            print(f"Report saved to: {abs_path}")
            # Optionally open the file in the default browser
            # import webbrowser
            # webbrowser.open(f"file://{abs_path}")
    else:
        print(f"❌ Database file not found: {db_path}")
        print(f"Current directory: {os.getcwd()}")
        print(f"Files in directory: {os.listdir(os.path.dirname(db_path) or os.getcwd())}")