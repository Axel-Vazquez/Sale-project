# Sales Analysis — Portfolio Project (Python + SQL + Power BI)

An end-to-end data analysis project: cleaning raw data with **Python**,
modeling and querying it with **SQL**, and building an interactive
dashboard in **Power BI**. The dataset simulates sales for a retail company
operating across several Mexican states (structure inspired by the classic
"Superstore" dataset used in BI portfolios, but generated and localized to
Mexico).

## Business questions it answers

1. What are total sales and profit, and how do they break down by product
   category and region?
2. Are discounts actually helping sell more, or are they destroying margin?
3. Which products and customers are the most profitable?
4. How do sales evolve month over month, and what's the year-over-year
   growth?
5. How fast are orders being shipped, by shipping mode?

## Key insight

Discounts above 30% don't just reduce margin — they make it **negative**
(-12.6% on average), while sales with no discount keep a healthy 35.7%
margin. This kind of finding — found and verified in both Python and SQL —
is exactly the kind of analysis expected from a Data Analyst role: not just
showing numbers, but finding where the business is quietly losing money.

| Metric | Value |
|---|---|
| Total sales | $46,124,858 MXN |
| Total profit | $12,111,150 MXN |
| Overall margin | 26.3% |
| Orders processed | 2,200 |
| Leading category | Technology ($28.4M in sales) |
| Margin at >30% discount | -12.6% |

## Project structure

```
superstore_en/
├── data/
│   ├── raw/                  # Raw data, with intentional errors
│   └── clean/                # Clean star-schema tables + charts
├── python/
│   ├── 00_generate_raw_data.py
│   └── 01_cleaning_and_analysis.ipynb   # Cleaning + EDA + export
├── sql/
│   ├── 01_create_schema.sql             # Star schema DDL
│   ├── 02_load_data.py                  # Loads the clean CSVs into SQLite
│   ├── 03_analysis_queries.sql          # 12 queries, basic to advanced
│   └── superstore_mx.db                 # SQLite database, already loaded
├── powerbi/
│   ├── data_for_powerbi.xlsx            # Ready to import
│   └── POWER_BI_GUIDE.md                # Model, DAX measures and design
└── README.md
```

## Tech stack

- **Python**: pandas, numpy, matplotlib, seaborn — data cleaning and EDA.
- **SQL**: SQLite — star-schema model, aggregations, window functions
  (`RANK`, `ROW_NUMBER`, `LAG`), CTEs.
- **Power BI**: relational model, DAX measures (`CALCULATE`,
  `SAMEPERIODLASTYEAR`, `TOTALYTD`, `RANKX`), a 3-page dashboard.

## How to reproduce it

```bash
# 1. Generate the raw data (with intentional errors)
python python/00_generate_raw_data.py

# 2. Run the cleaning and analysis (produces the clean tables + charts)
jupyter nbconvert --to notebook --execute --inplace python/01_cleaning_and_analysis.ipynb

# 3. Load the clean data into SQLite
python sql/02_load_data.py

# 4. Run the analysis queries
sqlite3 sql/superstore_mx.db < sql/03_analysis_queries.sql

# 5. Power BI: open Power BI Desktop and import powerbi/data_for_powerbi.xlsx
#    Follow powerbi/POWER_BI_GUIDE.md for the model, measures, and design.
```

## Why this flow (and not just an Excel file)

This mirrors a real analyst's workflow: data almost never arrives clean, it
almost never lives in a single file, and the analysis almost never ends in
a single tool. Python handles data quality, SQL answers business questions
in a reproducible and auditable way, and Power BI communicates the result
to someone who isn't going to read a SQL query.

---

*Made by Axel Vazquez.*
