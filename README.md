# 🚀 challenge-data-analysis-sql

## 📖 Description

This project provides a comprehensive pipeline for extracting, analyzing, and visualizing company data from a SQLite database. It includes:
- Automated database schema extraction to Markdown
- A suite of SQL queries for business analytics
- Python scripts for batch data visualization (interactive HTML & static PNG)
- Ready-to-use data and output folders for reproducible research

## ⚙️ Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/challenge-data-analysis-sql.git
   cd challenge-data-analysis-sql
   ```
2. **Set up a virtual environment (recommended):**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```
3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

## 🛠️ Usage

### 1. Database Schema Extraction
Extracts all tables, columns, indexes, and foreign keys from a SQLite database and outputs a Markdown report.

```bash
python scripts/database_schema_extractor.py path/to/your.db
# Output: docs/database_structure.md
```

### 2. Data Visualization
Reads all analysis result CSVs from `data/` and generates interactive HTML and static PNG charts in `plots/`.

```bash
python scripts/visualization.py
# Output: plots/*.html and plots/*.png
```

### 3. SQL Analysis
All main SQL queries are in `data_analysis/sql_queries/`. Run them in your DBMS to generate CSVs for visualization.

## 🗓️ Timeline

- **2025.07.24-2025.07.25**: Project initiated, repo structure and initial SQL queries,
                             Visualization pipeline, schema extraction, and documentation,
                             Data analysis, advanced SQL, and final report

## 🙋 Personal Situation

This project was developed as part of my personal data analysis challenge, combining SQL, Python, and visualization best practices. It reflects my journey in mastering data engineering and analytics workflows, and is intended as a robust template for similar business data projects.

---

> Feel free to fork, contribute, or reach out for collaboration! 😊